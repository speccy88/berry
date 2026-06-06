# P2 SD library store helper.
#
# The current P2 firmware imports .be libraries lazily from /modules on the SD
# card. On edge32, PSRAM is a block device today, so source text can be cached
# there in chunks and materialized into Hub RAM only when a program asks to load
# it. Berry objects and bytecode still execute from Hub RAM.

import os
import p2

var libstore = module("libstore")

libstore.paths = ["/modules"]
libstore.known = ["binary_heap", "libstore", "math", "taskspin", "wifi"]
libstore.examples = ["examples/binary_heap_sort"]
libstore.cache_base = 30 * 1024 * 1024
libstore.cache_limit = 1024 * 1024
libstore.cache = {}
libstore.cache_next = libstore.cache_base

libstore.psram = def()
    return p2.psram_info()
end

libstore.strategy = def()
    var psram = p2.psram_info()
    return {
        "library_home": "sd",
        "module_path": libstore.paths,
        "load": "lazy_source_or_psram_cache",
        "heap": "hub",
        "object_heap": false,
        "direct_execute_from_psram": false,
        "psram_role": psram["available"] ? "chunked_source_cache" : "unavailable",
        "psram_access": psram["access"],
        "psram_max_transfer": psram["max_transfer"]
    }
end

libstore.status = def()
    var psram = p2.psram_info()
    return {
        "paths": libstore.paths,
        "lazy": true,
        "source": "sd",
        "psram_available": psram["available"],
        "psram_bytes": psram["bytes"],
        "psram_cache": psram["available"],
        "psram_cache_base": libstore.cache_base,
        "psram_cache_limit": libstore.cache_limit,
        "psram_cache_used": libstore.cache_next - libstore.cache_base,
        "psram_cache_free": libstore.cache_base + libstore.cache_limit - libstore.cache_next,
        "psram_cache_items": libstore.cache.size(),
        "psram_max_transfer": psram["max_transfer"],
        "heap": "hub"
    }
end

libstore.modules = def()
    var out = []
    for name : libstore.known
        out.push(name)
    end
    return out
end

libstore.source_path = def(name)
    for base : libstore.paths
        var path = base + "/" + name + ".be"
        if os.path.exists(path)
            return path
        end
    end
    return nil
end

libstore.exists = def(name)
    return libstore.source_path(name) != nil
end

libstore.info = def(name)
    var path = libstore.source_path(name)
    var psram = p2.psram_info()
    var cached = libstore.cache.contains(name) ? libstore.cache[name] : nil
    return {
        "name": name,
        "path": path,
        "exists": path != nil,
        "source": "sd",
        "load": "lazy_source_or_psram_cache",
        "heap": "hub",
        "psram_cache": psram["available"],
        "cached": cached != nil,
        "cache": cached
    }
end

libstore.cache_reset = def()
    libstore.cache = {}
    libstore.cache_next = libstore.cache_base
end

libstore.cached = def(name)
    return libstore.cache.contains(name)
end

libstore.cache_source = def(name)
    var psram = p2.psram_info()
    if !psram["available"]
        return nil
    end
    var path = libstore.source_path(name)
    if path == nil
        return nil
    end
    if libstore.cache.contains(name)
        return libstore.cache[name]
    end

    var source = open(path, "r").read()
    var total = size(source)
    var max_transfer = psram["max_transfer"]
    if max_transfer <= 0
        raise "value_error", "PSRAM transfer size is not available"
    end
    if libstore.cache_next + total > libstore.cache_base + libstore.cache_limit
        raise "memory_error", "libstore PSRAM cache area is full"
    end

    var address = libstore.cache_next
    var chunks = []
    var offset = 0
    while offset < total
        var n = total - offset
        if n > max_transfer
            n = max_transfer
        end
        var chunk = source[offset..(offset + n - 1)]
        var written = p2.psram_write(address + offset, chunk)
        if !written["ok"] || written["size"] != n
            raise "io_error", "PSRAM cache write failed"
        end
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
    if item == nil
        item = libstore.cache_source(name)
    end
    if item == nil
        return nil
    end
    var out = ""
    for chunk : item["chunks"]
        out += p2.psram_read(chunk["address"], chunk["size"])
    end
    return out
end

libstore.run_cached = def(name)
    var source = libstore.cached_source(name)
    if source == nil
        return nil
    end
    return compile(source)()
end

libstore.load = def(name)
    var path = libstore.source_path(name)
    if path == nil
        return nil
    end
    if p2.psram_info()["available"]
        return libstore.run_cached(name)
    end
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
    for name : libstore.known
        if libstore.exists(name)
            out.push(libstore.cache_source(name))
        end
    end
    return out
end

libstore.cache_report = def()
    var items = []
    for name : libstore.known
        if libstore.cache.contains(name)
            var item = libstore.cache[name]
            items.push({
                "name": name,
                "path": item["path"],
                "address": item["address"],
                "size": item["size"],
                "chunks": item["chunk_count"]
            })
        end
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
