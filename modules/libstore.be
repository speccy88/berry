# P2 SD library store helper.
#
# The current P2 firmware imports `.be` libraries lazily from `/modules` on SD.
# On edge32, PSRAM is exposed only through block APIs, so source text is mirrored
# into PSRAM in bounded chunks and then materialized into active Hub RAM only when
# a program requests execution. This keeps the image small and moves most large
# library source text out of Hub RAM.

import os
import p2
import string

var libstore = module("libstore")

libstore.POLICY_SD_LAZY = "sd_only"
libstore.POLICY_SD_CACHE_PSRAM = "sd_cache_psram"
libstore.POLICY_SD_PRELOAD_PSRAM = "sd_preload_psram"

libstore.paths = ["/modules"]
libstore.known = ["binary_heap", "libstore", "math", "taskspin", "wifi"]
libstore.examples = ["examples/binary_heap_sort"]
libstore.cache_limit_requested = 1024 * 1024
libstore.cache_base = 0
libstore.cache_limit = 0
libstore.cache = {}
libstore.cache_next = 0
libstore._policy = nil

libstore._policy_supported = def(policy)
    if policy == nil {
        return false
    }
    return policy == libstore.POLICY_SD_LAZY
        || policy == libstore.POLICY_SD_CACHE_PSRAM
        || policy == libstore.POLICY_SD_PRELOAD_PSRAM
end

libstore._normalize_policy = def(policy)
    if libstore._policy_supported(policy) {
        return policy
    }
    return nil
end

libstore._psram_policy_cache_available = def()
    var info = p2.psram_info()
    return info["available"] && info["bytes"] > 0 && info["block_bytes"] > 0
end

libstore._policy_default = def()
    if libstore._psram_policy_cache_available() {
        return libstore.POLICY_SD_CACHE_PSRAM
    }
    return libstore.POLICY_SD_LAZY
end

libstore._policy_resolve = def()
    if libstore._policy == nil {
        return libstore._policy_default()
    }
    return libstore._policy
end

libstore._policy_uses_psram_cache = def(policy)
    if policy == nil {
        policy = libstore._policy_resolve()
    }
    return policy == libstore.POLICY_SD_CACHE_PSRAM || policy == libstore.POLICY_SD_PRELOAD_PSRAM
end

libstore._policy_supports_preload = def(policy)
    return libstore._policy_uses_psram_cache(policy)
end

libstore.module_name = def(entry)
    var lower = string.tolower(entry)
    if size(lower) <= 3 || !string.endswith(lower, ".be") {
        return nil
    }
    return lower[0..(size(lower) - 4)]
end

libstore.add_unique = def(out, seen, name)
    if name != nil && !seen.contains(name) {
        seen[name] = true
        out.push(name)
    }
end

libstore.scan = def()
    var out = []
    var seen = {}
    for name : libstore.known
        if libstore.exists(name)
            libstore.add_unique(out, seen, name)
        end
    end
    for base : libstore.paths
        try
            for entry : os.listdir(base)
                libstore.add_unique(out, seen, libstore.module_name(entry))
            end
        except .. as e, m
        end
    end
    return out
end

libstore.psram = def()
    return p2.psram_info()
end

libstore.cache_window = def()
    var psram = p2.psram_info()
    var block_base = 0
    var block_bytes = 0
    var policy = libstore._policy_resolve()
    var use_psram_cache = libstore._policy_uses_psram_cache(policy)

    if use_psram_cache && psram["available"] {
        block_base = psram.contains("block_base") ? psram["block_base"] : 0
        if psram.contains("block_bytes") {
            block_bytes = psram["block_bytes"]
        } else {
            block_bytes = psram["bytes"] - block_base
        }
        if block_bytes < 0 {
            block_bytes = 0
        }
    }

    var limit = libstore.cache_limit_requested
    if block_bytes < limit {
        limit = block_bytes
    }
    var base = block_base
    if limit > 0 {
        base = block_base + block_bytes - limit
    }
    return {
        "available": psram["available"] && use_psram_cache && limit > 0,
        "base": base,
        "limit": limit,
        "block_base": block_base,
        "block_bytes": block_bytes,
        "end": block_base + block_bytes,
        "requested": libstore.cache_limit_requested
    }
end

libstore.cache_ensure = def()
    var window = libstore.cache_window()
    if libstore.cache.size() == 0 && libstore.cache_next == 0 {
        libstore.cache_base = window["base"]
        libstore.cache_limit = window["limit"]
        libstore.cache_next = libstore.cache_base
    }
    return window
end

libstore.policy = def()
    var policy = libstore._policy_resolve()
    var window = libstore.cache_window()
    var psram = p2.psram_info()
    return {
        "name": policy,
        "default": libstore._policy_default(),
        "uses_psram_cache": libstore._policy_uses_psram_cache(policy),
        "preload_supported": libstore._policy_supports_preload(policy),
        "psram_cache_available": window["available"],
        "psram_bytes": psram["bytes"],
        "psram_block_bytes": window["block_bytes"]
    }
end

libstore.set_policy = def(policy, preload)
    if preload == nil {
        preload = false
    }
    var resolved = libstore._normalize_policy(policy)
    if resolved == nil {
        raise "value_error", "unsupported libstore policy"
    }

    var previous = libstore._policy_resolve()
    if previous != resolved {
        libstore._policy = resolved
        libstore.cache_reset()
    }
    var loaded = 0
    if preload && libstore._policy_supports_preload(resolved) && p2.psram_info()["available"] {
        var all = libstore.cache_all()
        loaded = all.size()
    }

    return {
        "previous": previous,
        "policy": resolved,
        "preloaded": preload && libstore._policy_supports_preload(resolved),
        "count": loaded
    }
end

libstore.strategy = def()
    var psram = p2.psram_info()
    var heap = psram["heap"] ? "external" : "hub"
    var policy = libstore._policy_resolve()
    var use_psram_cache = libstore._policy_uses_psram_cache(policy)
    var load = use_psram_cache ? "lazy_source_or_psram_cache" : "lazy_source"
    var psram_role = "not_used"
    if psram["available"] {
        psram_role = use_psram_cache
            ? (psram["heap"] ? "xmm_heap_and_chunked_source_cache" : "chunked_source_cache")
            : "not_used"
    }
    return {
        "library_home": "sd",
        "module_path": libstore.paths,
        "load": load,
        "heap": heap,
        "object_heap": psram["heap"],
        "policy": policy,
        "direct_execute_from_psram": false,
        "preload_supported": libstore._policy_supports_preload(policy),
        "psram_role": psram["available"] ? psram_role : "unavailable",
        "psram_access": psram["access"],
        "psram_max_transfer": psram["max_transfer"]
    }
end

libstore.status = def()
    var psram = p2.psram_info()
    var policy = libstore._policy_resolve()
    var window = libstore.cache_ensure()
    var heap = psram["heap"] ? "external" : "hub"
    return {
        "paths": libstore.paths,
        "lazy": true,
        "source": "sd",
        "policy": policy,
        "psram_policy_cache": libstore._policy_uses_psram_cache(policy),
        "psram_available": psram["available"],
        "psram_bytes": psram["bytes"],
        "psram_block_base": window["block_base"],
        "psram_block_bytes": window["block_bytes"],
        "psram_cache": window["available"],
        "psram_cache_base": libstore.cache_base,
        "psram_cache_limit": libstore.cache_limit,
        "psram_cache_requested": libstore.cache_limit_requested,
        "psram_cache_used": libstore.cache_next - libstore.cache_base,
        "psram_cache_free": libstore.cache_base + libstore.cache_limit - libstore.cache_next,
        "psram_cache_items": libstore.cache.size(),
        "library_count": libstore.modules().size(),
        "psram_max_transfer": psram["max_transfer"],
        "heap": heap
    }
end

libstore.modules = def()
    return libstore.scan()
end

libstore.source_path = def(name)
    for base : libstore.paths
        var path = base + "/" + name + ".be"
        if os.path.exists(path) {
            return path
        }
    end
    return nil
end

libstore.exists = def(name)
    return libstore.source_path(name) != nil
end

libstore.info = def(name)
    var path = libstore.source_path(name)
    var psram = p2.psram_info()
    var window = libstore.cache_ensure()
    var heap = psram["heap"] ? "external" : "hub"
    var policy = libstore._policy_resolve()
    var use_psram_cache = libstore._policy_uses_psram_cache(policy)
    var load = use_psram_cache ? "lazy_source_or_psram_cache" : "lazy_source"
    if !psram["available"] {
        load = "lazy_source"
    }
    var cached = libstore.cache.contains(name) ? libstore.cache[name] : nil
    return {
        "name": name,
        "path": path,
        "exists": path != nil,
        "source": "sd",
        "load": load,
        "heap": heap,
        "policy": policy,
        "psram_cache": window["available"],
        "psram_cache_base": libstore.cache_base,
        "psram_cache_limit": libstore.cache_limit,
        "cached": cached != nil,
        "cache": cached
    }
end

libstore.cache_reset = def()
    var window = libstore.cache_window()
    libstore.cache_base = window["base"]
    libstore.cache_limit = window["limit"]
    libstore.cache = {}
    libstore.cache_next = libstore.cache_base
    return window
end

libstore.cached = def(name)
    return libstore.cache.contains(name)
end

libstore.cache_source = def(name)
    var policy = libstore._policy_resolve()
    var use_psram_cache = libstore._policy_uses_psram_cache(policy)
    if !use_psram_cache {
        return nil
    }
    var psram = p2.psram_info()
    var window = libstore.cache_ensure()
    if !window["available"] || !psram["available"] {
        return nil
    }
    var path = libstore.source_path(name)
    if path == nil {
        return nil
    }
    if libstore.cache.contains(name) {
        return libstore.cache[name]
    }

    var source = open(path, "r").read()
    var total = size(source)
    var max_transfer = psram["max_transfer"]
    if max_transfer <= 0 {
        raise "value_error", "PSRAM transfer size is not available"
    }
    if libstore.cache_next + total > libstore.cache_base + libstore.cache_limit {
        raise "memory_error", "libstore PSRAM cache area is full"
    }

    var address = libstore.cache_next
    var chunks = []
    var offset = 0
    while offset < total
        var n = total - offset
        if n > max_transfer {
            n = max_transfer
        }
        var chunk = source[offset..(offset + n - 1)]
        var written = p2.psram_write(address + offset, chunk)
        if !written["ok"] || written["size"] != n {
            raise "io_error", "PSRAM cache write failed"
        }
        chunks.push({
            "address": address + offset,
            "size": n
        })
        offset += n
    end

    var item = {
        "name": name,
        "path": path,
        "address": address,
        "size": total,
        "chunks": chunks,
        "chunk_count": chunks.size(),
        "max_transfer": max_transfer
    }
    libstore.cache[name] = item
    libstore.cache_next += total
    return item
end

libstore.cached_source = def(name)
    var item = libstore.cache.contains(name) ? libstore.cache[name] : nil
    if item == nil {
        item = libstore.cache_source(name)
    }
    if item == nil {
        return nil
    }
    var out = ""
    for chunk : item["chunks"]
        out += p2.psram_read(chunk["address"], chunk["size"])
    end
    return out
end

libstore.run_cached = def(name)
    var source = libstore.cached_source(name)
    if source == nil {
        return nil
    }
    return compile(source)()
end

libstore.load = def(name)
    var path = libstore.source_path(name)
    if path == nil {
        return nil
    }
    var policy = libstore._policy_resolve()
    if libstore._policy_uses_psram_cache(policy) {
        var source = libstore.cached_source(name)
        if source != nil {
            return compile(source)()
        }
    }
    return run_file(path)
end

libstore.cache_many = def(*names)
    var out = []
    for name : names
        out.push(libstore.cache_source(name))
    end
    return out
end

libstore.cache_all = def()
    var out = []
    for name : libstore.modules()
        if libstore.exists(name) {
            out.push(libstore.cache_source(name))
        }
    end
    return out
end

libstore.cache_report = def()
    var items = []
    for name : libstore.modules()
        if libstore.cache.contains(name) {
            var item = libstore.cache[name]
            items.push({
                "name": name,
                "path": item["path"],
                "address": item["address"],
                "size": item["size"],
                "chunks": item["chunk_count"]
            })
        }
    end
    return {
        "status": libstore.status(),
        "items": items
    }
end

libstore.run = def(path)
    return run_file(path)
end

return libstore
