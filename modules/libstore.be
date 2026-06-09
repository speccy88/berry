# P2 SD library store helper.
#
# The current P2 firmware imports `.be` libraries lazily from SD module roots.
# On edge32, PSRAM is exposed only through block APIs, so source text is mirrored
# into PSRAM in bounded chunks and then materialized into active Hub RAM only when
# a program requests execution. This keeps the image small and moves most large
# library source text out of Hub RAM.

import os
import json
import p2
import string
import sys

var libstore = module("libstore")

libstore.POLICY_SD_LAZY = "sd_only"
libstore.POLICY_SD_CACHE_PSRAM = "sd_cache_psram"
libstore.POLICY_SD_PRELOAD_PSRAM = "sd_preload_psram"
libstore.MANIFEST_FORMAT = "berry-p2-bec-manifest-v1"

libstore.paths = ["/modules", "/berry/lib", "/berry/app"]
libstore.app_paths = ["/berry/app"]
libstore.example_paths = ["/berry/examples"]
libstore.pasm_paths = ["/berry/pasm"]
libstore.compiled_paths = ["/berry/cache", "/berry/lib", "/berry/app"]
libstore.compiled_supported = false
libstore.compiled_loader_supported = false
libstore.compiled_validator_supported = false
libstore.compiled_loader_reason = "bytecode_loader_unavailable"
libstore.compile_cache_supported = false
libstore.compile_cache_reason = "bytecode_emit_unavailable"
libstore.compile_cache_probe_path = "/berry/cache/.libstore_emit_probe.bec"
libstore.known = [
    "binary_heap",
    "configstore",
    "libstore",
    "math",
    "p2compat",
    "p2ipc",
    "p2mem",
    "task",
    "wifi"
]
libstore.coverage_table = {
    "binary_heap": {
        "status": "covered",
        "behavior_smoke": "/tests/p2/smoke_libraries.be",
        "sd_import_smoke": "/tests/p2/smoke_import_all_libs.be",
        "repeated_import_smoke": "/tests/p2/smoke_import_cache.be",
        "cache_smoke": "/tests/p2/smoke_import_cache.be",
        "low_memory_smoke": "/tests/p2/smoke_import_churn.be",
        "metadata_smoke": "/tests/p2/smoke_module_inventory.be",
        "reason": "binary heap behavior plus SD import/cache/churn coverage"
    },
    "configstore": {
        "status": "covered",
        "behavior_smoke": "/tests/p2/smoke_configstore.be",
        "sd_import_smoke": "/tests/p2/smoke_import_all_libs.be",
        "repeated_import_smoke": "/tests/p2/smoke_import_cache.be",
        "cache_smoke": "/tests/p2/smoke_import_cache.be",
        "low_memory_smoke": "/tests/p2/smoke_import_churn.be",
        "metadata_smoke": "/tests/p2/smoke_module_inventory.be",
        "reason": "JSON config behavior plus SD import/cache/churn coverage"
    },
    "libstore": {
        "status": "covered",
        "behavior_smoke": "/tests/p2/smoke_libstore_paths.be",
        "sd_import_smoke": "/tests/p2/smoke_import_all_libs.be",
        "repeated_import_smoke": "/tests/p2/smoke_import_cache.be",
        "cache_smoke": "/tests/p2/smoke_import_cache.be",
        "low_memory_smoke": "/tests/p2/smoke_import_churn.be",
        "metadata_smoke": "/tests/p2/smoke_module_inventory.be",
        "reason": "library path behavior plus SD import/cache/churn coverage"
    },
    "math": {
        "status": "covered",
        "behavior_smoke": "/tests/p2/smoke_math_parity.be",
        "sd_import_smoke": "/tests/p2/smoke_import_all_libs.be",
        "repeated_import_smoke": "/tests/p2/smoke_import_cache.be",
        "cache_smoke": "/tests/p2/smoke_import_cache.be",
        "low_memory_smoke": "/tests/p2/smoke_import_churn.be",
        "metadata_smoke": "/tests/p2/smoke_module_inventory.be",
        "reason": "math behavior plus SD import/cache/churn coverage"
    },
    "p2compat": {
        "status": "covered",
        "behavior_smoke": "/tests/p2/smoke_p2compat.be",
        "sd_import_smoke": "/tests/p2/smoke_import_all_libs.be",
        "repeated_import_smoke": "/tests/p2/smoke_import_cache.be",
        "cache_smoke": "/tests/p2/smoke_import_cache.be",
        "low_memory_smoke": "/tests/p2/smoke_import_churn.be",
        "metadata_smoke": "/tests/p2/smoke_module_inventory.be",
        "reason": "capability metadata plus SD import/cache/churn coverage"
    },
    "p2ipc": {
        "status": "covered",
        "behavior_smoke": "/tests/p2/smoke_module_inventory.be",
        "sd_import_smoke": "/tests/p2/smoke_import_all_libs.be",
        "repeated_import_smoke": "/tests/p2/smoke_import_cache.be",
        "cache_smoke": "/tests/p2/smoke_import_cache.be",
        "low_memory_smoke": "/tests/p2/smoke_import_churn.be",
        "metadata_smoke": "/tests/p2/smoke_module_inventory.be",
        "reason": "cooperative IPC facade plus SD import/cache/churn coverage"
    },
    "p2mem": {
        "status": "covered",
        "behavior_smoke": "/tests/p2/smoke_module_inventory.be",
        "sd_import_smoke": "/tests/p2/smoke_import_all_libs.be",
        "repeated_import_smoke": "/tests/p2/smoke_import_cache.be",
        "cache_smoke": "/tests/p2/smoke_import_cache.be",
        "low_memory_smoke": "/tests/p2/smoke_import_churn.be",
        "metadata_smoke": "/tests/p2/smoke_module_inventory.be",
        "reason": "p2mem module diagnostics plus SD import/cache/churn coverage"
    },
    "task": {
        "status": "covered",
        "behavior_smoke": "/tests/p2/smoke_task.be",
        "sd_import_smoke": "/tests/p2/smoke_import_all_libs.be",
        "repeated_import_smoke": "/tests/p2/smoke_import_cache.be",
        "cache_smoke": "/tests/p2/smoke_import_cache.be",
        "low_memory_smoke": "/tests/p2/smoke_import_churn.be",
        "metadata_smoke": "/tests/p2/smoke_module_inventory.be",
        "reason": "cooperative task scheduler plus SD import/cache/churn coverage"
    },
    "wifi": {
        "status": "hardware_deferred",
        "behavior_smoke": nil,
        "sd_import_smoke": "/tests/p2/smoke_import_all_libs.be",
        "repeated_import_smoke": "/tests/p2/smoke_import_cache.be",
        "cache_smoke": "/tests/p2/smoke_import_cache.be",
        "low_memory_smoke": "/tests/p2/smoke_import_churn.be",
        "metadata_smoke": "/tests/p2/smoke_module_inventory.be",
        "reason": "safe import/cache/churn coverage only; hardware detection remains deferred"
    }
}
libstore.examples = ["examples/binary_heap_sort"]
libstore.cache_limit_requested = 1024 * 1024
libstore.cache_base = 0
libstore.cache_limit = 0
libstore.cache = {}
libstore.cache_next = 0
libstore.cache_hits = {}
libstore.cache_misses = {}
libstore.cache_access = 0
libstore._policy = nil

libstore._policy_supported = def(policy)
    if policy == nil
        return false
    end
    if policy == libstore.POLICY_SD_LAZY
        return true
    end
    if policy == libstore.POLICY_SD_CACHE_PSRAM
        return true
    end
    if policy == libstore.POLICY_SD_PRELOAD_PSRAM
        return true
    end
    return false
end

libstore._normalize_policy = def(policy)
    if libstore._policy_supported(policy)
        return policy
    end
    return nil
end

libstore._psram_policy_cache_available = def()
    var info = p2.psram_info()
    var block_bytes = info.contains("block_bytes") ? info["block_bytes"] : info["bytes"]
    return info["available"] && info["bytes"] > 0 && block_bytes > 0
end

libstore._policy_default = def()
    if libstore._psram_policy_cache_available()
        return libstore.POLICY_SD_CACHE_PSRAM
    end
    return libstore.POLICY_SD_LAZY
end

libstore._policy_resolve = def()
    if libstore._policy == nil
        return libstore._policy_default()
    end
    return libstore._policy
end

libstore._policy_uses_psram_cache = def(policy)
    if policy == nil
        policy = libstore._policy_resolve()
    end
    return policy == libstore.POLICY_SD_CACHE_PSRAM || policy == libstore.POLICY_SD_PRELOAD_PSRAM
end

libstore._policy_supports_preload = def(policy)
    return libstore._policy_uses_psram_cache(policy)
end

libstore.module_name = def(entry)
    var lower = string.tolower(entry)
    if size(lower) <= 3 || !string.endswith(lower, ".be")
        return nil
    end
    return lower[0..(size(lower) - 4)]
end

libstore.module_file = def(name, ext)
    var out = str(name)
    out = string.replace(out, ".", "/")
    return out + ext
end

libstore.hash_text = def(text)
    var raw = bytes().fromstring(text)
    var h = 0
    var i = 0
    while i < raw.size()
        h = (h * 33 + raw[i]) % 2147483647
        i += 1
    end
    return h
end

libstore.source_stats = def(name)
    var path = libstore.source_path(name)
    if path == nil
        return {
            "path": nil,
            "exists": false,
            "size": 0,
            "hash": nil
        }
    end
    var source = open(path, "r").read()
    return {
        "path": path,
        "exists": true,
        "size": size(source),
        "hash": libstore.hash_text(source)
    }
end

libstore.compiled_stats = def(name)
    var path = libstore.compiled_path(name)
    if path == nil
        return {
            "path": nil,
            "exists": false,
            "size": 0,
            "hash": nil
        }
    end
    var bytecode = open(path, "r").read()
    return {
        "path": path,
        "exists": true,
        "size": size(bytecode),
        "hash": libstore.hash_text(bytecode)
    }
end

libstore.add_unique = def(out, seen, name)
    if name != nil && !seen.contains(name)
        seen[name] = true
        out.push(name)
    end
end

libstore.path_add = def(path)
    if path == nil || size(path) == 0
        raise "value_error", "module path is empty"
    end
    for base : libstore.paths
        if base == path
            return false
        end
    end
    libstore.paths.push(path)
    if type(sys.path_add) == "function" && !libstore._sys_path_contains(path)
        sys.path_add(path)
    end
    return true
end

libstore._sys_path_contains = def(path)
    for base : sys.path()
        if base == path
            return true
        end
    end
    return false
end

libstore.path_remove = def(path)
    var i = 0
    while i < libstore.paths.size()
        if libstore.paths[i] == path
            libstore.paths.remove(i)
            return true
        end
        i += 1
    end
    return false
end

libstore.path_list = def()
    var out = []
    for base : libstore.paths
        out.push(base)
    end
    return out
end

libstore.coverage = def(name)
    if libstore.coverage_table.contains(name)
        return libstore.coverage_table[name]
    end
    return {
        "status": "unknown",
        "behavior_smoke": nil,
        "sd_import_smoke": nil,
        "repeated_import_smoke": nil,
        "cache_smoke": nil,
        "low_memory_smoke": nil,
        "metadata_smoke": nil,
        "reason": "module is not in the curated P2 coverage table"
    }
end

libstore.app_path = def(name)
    var file = libstore.module_file(name, ".be")
    for base : libstore.app_paths
        var path = base + "/" + file
        if os.path.exists(path)
            return path
        end
    end
    return nil
end

libstore.app_exists = def(name)
    return libstore.app_path(name) != nil
end

libstore.run_app = def(name)
    var path = libstore.app_path(name)
    if path == nil
        return nil
    end
    return run_file(path)
end

libstore.example_path = def(name)
    var file = libstore.module_file(name, ".be")
    for base : libstore.example_paths
        var path = base + "/" + file
        if os.path.exists(path)
            return path
        end
    end
    return nil
end

libstore.example_exists = def(name)
    return libstore.example_path(name) != nil
end

libstore.run_example = def(name)
    var path = libstore.example_path(name)
    if path == nil
        return nil
    end
    return run_file(path)
end

libstore.pasm_path = def(name)
    var file = libstore.module_file(name, ".bin")
    for base : libstore.pasm_paths
        var path = base + "/" + file
        if os.path.exists(path)
            return path
        end
    end
    return nil
end

libstore.pasm_exists = def(name)
    return libstore.pasm_path(name) != nil
end

libstore.pasm_info = def(name)
    var path = libstore.pasm_path(name)
    if path == nil
        return {
            "name": name,
            "path": nil,
            "exists": false,
            "executable": false,
            "reason": "missing"
        }
    end
    return {
        "name": name,
        "path": path,
        "exists": true,
        "executable": false,
        "reason": "pasm_execution_deferred"
    }
end

libstore._bump_counter = def(table, name)
    if name == nil
        return 0
    end
    table[name] = table.contains(name) ? table[name] + 1 : 1
    libstore.cache_access += 1
    return table[name]
end

libstore.cache_hits_for = def(name)
    return libstore.cache_hits.contains(name) ? libstore.cache_hits[name] : 0
end

libstore.cache_misses_for = def(name)
    return libstore.cache_misses.contains(name) ? libstore.cache_misses[name] : 0
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

    if use_psram_cache && psram["available"]
        block_base = psram.contains("block_base") ? psram["block_base"] : 0
        if psram.contains("block_bytes")
            block_bytes = psram["block_bytes"]
        else
            block_bytes = psram["bytes"] - block_base
        end
        if block_bytes < 0
            block_bytes = 0
        end
    end

    var limit = libstore.cache_limit_requested
    if block_bytes < limit
        limit = block_bytes
    end
    var base = block_base
    if limit > 0
        base = block_base + block_bytes - limit
    end
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
    if libstore.cache.size() == 0 && libstore.cache_next == 0
        libstore.cache_base = window["base"]
        libstore.cache_limit = window["limit"]
        libstore.cache_next = libstore.cache_base
    end
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
    if preload == nil
        preload = false
    end
    var resolved = libstore._normalize_policy(policy)
    if resolved == nil
        raise "value_error", "unsupported libstore policy"
    end

    var previous = libstore._policy_resolve()
    if previous != resolved
        libstore._policy = resolved
        libstore.cache_reset()
    end
    var loaded = 0
    if preload && libstore._policy_supports_preload(resolved) && p2.psram_info()["available"]
        var all = libstore.cache_all()
        loaded = all.size()
    end

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
    if psram["available"]
        psram_role = use_psram_cache
            ? (psram["heap"] ? "xmm_heap_and_chunked_source_cache" : "chunked_source_cache")
            : "not_used"
    end
    return {
        "library_home": "sd",
        "module_path": libstore.path_list(),
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
    var file = libstore.module_file(name, ".be")
    for base : libstore.paths
        var path = base + "/" + file
        if os.path.exists(path)
            return path
        end
    end
    return nil
end

libstore.compiled_path = def(name)
    var file = libstore.module_file(name, ".bec")
    for base : libstore.compiled_paths
        var path = base + "/" + file
        if os.path.exists(path)
            return path
        end
    end
    return nil
end

libstore.compiled_exists = def(name)
    return libstore.compiled_path(name) != nil
end

libstore.compiled_candidate_path = def(name)
    return libstore.compiled_paths[0] + "/" + libstore.module_file(name, ".bec")
end

libstore.compiled_manifest_candidate_path = def(name)
    return libstore.compiled_candidate_path(name) + ".json"
end

libstore.compiled_manifest_path = def(name)
    var cpath = libstore.compiled_path(name)
    if cpath != nil
        var path = cpath + ".json"
        if os.path.exists(path)
            return path
        end
    end
    var candidate = libstore.compiled_manifest_candidate_path(name)
    if os.path.exists(candidate)
        return candidate
    end
    return nil
end

libstore.compiled_manifest = def(name)
    var path = libstore.compiled_manifest_path(name)
    if path == nil
        return {
            "path": nil,
            "exists": false,
            "valid": false,
            "reason": "missing",
            "data": nil
        }
    end
    var text = open(path, "r").read()
    var data = json.load(text)
    var valid = type(data) == "map"
    var reason = valid ? "ok" : "invalid_manifest"
    if valid
        if !data.contains("format") || data["format"] != libstore.MANIFEST_FORMAT
            valid = false
            reason = "invalid_manifest_format"
        elif data.contains("module") && data["module"] != name
            valid = false
            reason = "manifest_module_mismatch"
        elif !data.contains("source_hash") || !data.contains("compiled_hash")
            valid = false
            reason = "manifest_hash_missing"
        end
    end
    return {
        "path": path,
        "exists": true,
        "valid": valid,
        "reason": reason,
        "data": data
    }
end

libstore.compiled_manifest_template = def(name)
    var stats = libstore.source_stats(name)
    var cstats = libstore.compiled_stats(name)
    var reason = "ok"
    if !stats["exists"]
        reason = "source_missing"
    elif !cstats["exists"]
        reason = "compiled_missing"
    end
    if reason != "ok"
        return {
            "available": false,
            "reason": reason,
            "format": libstore.MANIFEST_FORMAT,
            "path": libstore.compiled_manifest_candidate_path(name),
            "data": nil
        }
    end
    return {
        "available": true,
        "reason": "ok",
        "format": libstore.MANIFEST_FORMAT,
        "path": libstore.compiled_manifest_candidate_path(name),
        "data": {
            "format": libstore.MANIFEST_FORMAT,
            "module": name,
            "source_size": stats["size"],
            "source_hash": stats["hash"],
            "compiled_size": cstats["size"],
            "compiled_hash": cstats["hash"]
        }
    }
end

libstore.compiled_manifest_text = def(name)
    var template = libstore.compiled_manifest_template(name)
    if !template["available"]
        return nil
    end
    return json.dump(template["data"])
end

libstore.build_features = def()
    try
        var status = p2.status_info()
        if type(status) == "map" && status.contains("build") && type(status["build"]) == "map"
            return status["build"]
        end
    except .. as e, m
    end
    return {}
end

libstore.compiled_execution_probe = def()
    var build = libstore.build_features()
    var loader_supported = build.contains("bytecode_loader") && build["bytecode_loader"]
    var validator_supported = build.contains("bytecode_execution") && build["bytecode_execution"]
    var supported = loader_supported && validator_supported
    libstore.compiled_loader_supported = loader_supported
    libstore.compiled_validator_supported = validator_supported
    libstore.compiled_supported = supported
    libstore.compiled_loader_reason = supported ? "ok" : (loader_supported ? "bytecode_validator_unavailable" : "bytecode_loader_unavailable")
    return {
        "supported": supported,
        "reason": libstore.compiled_loader_reason,
        "loader_supported": loader_supported,
        "validator_supported": validator_supported,
        "build_flag": loader_supported,
        "execution_flag": validator_supported
    }
end

libstore._ensure_dir = def(path)
    if path == nil || path == "" || path == "/"
        return true
    end
    if os.path.isdir(path)
        return true
    end
    var parent = os.path.dirname(path)
    if parent != path && parent != ""
        libstore._ensure_dir(parent)
    end
    try
        os.mkdir(path)
    except .. as e, m
    end
    if !os.path.isdir(path)
        raise "io_error", "cannot create directory " + path
    end
    return true
end

libstore._ensure_parent_dir = def(path)
    return libstore._ensure_dir(os.path.dirname(path))
end

libstore.compile_cache_probe = def()
    if libstore.compile_cache_supported
        return {
            "supported": true,
            "reason": "ok"
        }
    end
    libstore._ensure_parent_dir(libstore.compile_cache_probe_path)
    var f = open(libstore.compile_cache_probe_path, "w")
    var supported = type(f.savecode) == "function"
    f.close()
    try
        os.remove(libstore.compile_cache_probe_path)
    except .. as e, m
    end
    libstore.compile_cache_supported = supported
    libstore.compile_cache_reason = supported ? "ok" : "bytecode_emit_unavailable"
    return {
        "supported": supported,
        "reason": libstore.compile_cache_reason
    }
end

libstore.compile_cache_plan = def(name, probe)
    if probe
        libstore.compile_cache_probe()
    end
    var stats = libstore.source_stats(name)
    var cstats = libstore.compiled_stats(name)
    var manifest = libstore.compiled_manifest(name)
    var manifest_template = libstore.compiled_manifest_template(name)
    var resolved = libstore.resolve(name)
    var reason = libstore.compile_cache_reason
    if !stats["exists"]
        reason = "source_missing"
    end
    var can_emit = libstore.compile_cache_supported && stats["exists"]
    return {
        "name": name,
        "supported": libstore.compile_cache_supported,
        "can_emit": can_emit,
        "reason": reason,
        "emit_blocked_reason": can_emit ? nil : reason,
        "manifest_format": libstore.MANIFEST_FORMAT,
        "manifest_required": true,
        "validator_required": true,
        "execution_required": true,
        "manifest_template_available": manifest_template["available"],
        "manifest_template_reason": manifest_template["reason"],
        "manifest_template": manifest_template["data"],
        "target_path": libstore.compiled_candidate_path(name),
        "manifest_target_path": libstore.compiled_manifest_candidate_path(name),
        "source_path": stats["path"],
        "source_exists": stats["exists"],
        "source_size": stats["size"],
        "source_hash": stats["hash"],
        "compiled_path": cstats["path"],
        "compiled_exists": cstats["exists"],
        "compiled_size": cstats["size"],
        "compiled_hash": cstats["hash"],
        "manifest_path": manifest["path"],
        "manifest_exists": manifest["exists"],
        "manifest_valid": manifest["valid"],
        "manifest_reason": manifest["reason"],
        "selected_path": resolved["selected_path"],
        "selected_kind": resolved["selected_kind"],
        "resolve_reason": resolved["reason"]
    }
end

libstore.compile_cache_emit = def(name)
    var plan = libstore.compile_cache_plan(name, true)
    if !plan["source_exists"]
        raise "value_error", "source module is missing"
    end
    if !plan["can_emit"]
        raise "unsupported_error", plan["emit_blocked_reason"]
    end

    libstore._ensure_parent_dir(plan["target_path"])
    libstore._ensure_parent_dir(plan["manifest_target_path"])

    var source = open(plan["source_path"], "r").read()
    var fn = compile(source)
    var out = open(plan["target_path"], "w")
    if type(out.savecode) != "function"
        out.close()
        try
            os.remove(plan["target_path"])
        except .. as e, m
        end
        libstore.compile_cache_supported = false
        libstore.compile_cache_reason = "bytecode_emit_unavailable"
        raise "unsupported_error", "bytecode_emit_unavailable"
    end
    out.savecode(fn)
    out.close()

    var manifest_text = libstore.compiled_manifest_text(name)
    if manifest_text == nil
        raise "io_error", "cannot create bytecode manifest"
    end
    var mf = open(plan["manifest_target_path"], "w")
    mf.write(manifest_text)
    mf.close()

    var fresh = libstore.compiled_freshness(name)
    return {
        "name": name,
        "ok": true,
        "compiled_path": plan["target_path"],
        "manifest_path": plan["manifest_target_path"],
        "compiled_size": fresh["compiled_size"],
        "compiled_hash": fresh["compiled_hash"],
        "manifest_valid": fresh["manifest_valid"],
        "fresh": fresh["fresh"],
        "usable": fresh["usable"],
        "reason": fresh["reason"]
    }
end

libstore.compile_cache_plan_many = def(names, probe)
    var items = []
    var can_emit = 0
    var blocked = 0
    var reasons = {}
    for name : names
        var plan = libstore.compile_cache_plan(name, probe)
        items.push(plan)
        if plan["can_emit"]
            can_emit += 1
        else
            blocked += 1
        end
        var reason = plan["emit_blocked_reason"] == nil ? "ok" : plan["emit_blocked_reason"]
        if !reasons.contains(reason)
            reasons[reason] = 0
        end
        reasons[reason] += 1
    end
    return {
        "requested": size(names),
        "can_emit": can_emit,
        "blocked": blocked,
        "reasons": reasons,
        "items": items
    }
end

libstore.compile_cache_plan_many_text = def(names, probe)
    return json.dump(libstore.compile_cache_plan_many(names, probe))
end

libstore.compile_cache_plan_all = def(probe)
    return libstore.compile_cache_plan_many(libstore.modules(), probe)
end

libstore.compile_cache_plan_all_text = def(probe)
    return json.dump(libstore.compile_cache_plan_all(probe))
end

libstore.compile_cache_provision_plan = def(names, probe)
    var plan = libstore.compile_cache_plan_many(names, probe)
    var recommendation = plan["can_emit"] > 0 ? "emit_cache_candidates" : "source_fallback"
    return {
        "ok": true,
        "recommendation": recommendation,
        "requested": plan["requested"],
        "can_emit": plan["can_emit"],
        "blocked": plan["blocked"],
        "items": plan["items"],
        "default_source_fallback": plan["can_emit"] == 0
    }
end

libstore.compile_cache_provision_plan_text = def(names, probe)
    return json.dump(libstore.compile_cache_provision_plan(names, probe))
end

libstore.compile_cache_provision_plan_all = def(probe)
    return libstore.compile_cache_provision_plan(libstore.modules(), probe)
end

libstore.compile_cache_provision_plan_all_text = def(probe)
    return json.dump(libstore.compile_cache_provision_plan_all(probe))
end

libstore.compile_cache_emittable = def(names, probe)
    var out = []
    var plan = libstore.compile_cache_plan_many(names, probe)
    for item : plan["items"]
        if item["can_emit"]
            out.push(item)
        end
    end
    return out
end

libstore.compile_cache_emittable_text = def(names, probe)
    return json.dump(libstore.compile_cache_emittable(names, probe))
end

libstore.compile_cache_blocked = def(names, probe)
    var out = []
    var plan = libstore.compile_cache_plan_many(names, probe)
    for item : plan["items"]
        if !item["can_emit"]
            out.push(item)
        end
    end
    return out
end

libstore.compile_cache_blocked_text = def(names, probe)
    return json.dump(libstore.compile_cache_blocked(names, probe))
end

libstore.compile_cache_emittable_all = def(probe)
    return libstore.compile_cache_emittable(libstore.modules(), probe)
end

libstore.compile_cache_emittable_all_text = def(probe)
    return json.dump(libstore.compile_cache_emittable_all(probe))
end

libstore.compile_cache_blocked_all = def(probe)
    return libstore.compile_cache_blocked(libstore.modules(), probe)
end

libstore.compile_cache_blocked_all_text = def(probe)
    return json.dump(libstore.compile_cache_blocked_all(probe))
end

libstore.compile_cache_emit_many = def(names)
    var items = []
    var ok_count = 0
    var fail_count = 0
    for name : names
        try
            var emitted = libstore.compile_cache_emit(name)
            emitted["module"] = name
            items.push(emitted)
            ok_count += 1
        except .. as e, m
            var plan = libstore.compile_cache_plan(name)
            items.push({
                "module": name,
                "name": name,
                "ok": false,
                "error": e,
                "message": m,
                "reason": plan["emit_blocked_reason"],
                "target_path": plan["target_path"],
                "manifest_target_path": plan["manifest_target_path"]
            })
            fail_count += 1
        end
    end
    return {
        "requested": size(names),
        "ok_count": ok_count,
        "fail_count": fail_count,
        "items": items
    }
end

libstore.compile_cache_emit_all = def()
    return libstore.compile_cache_emit_many(libstore.modules())
end

libstore.compiled_validation = def(name)
    var stats = libstore.source_stats(name)
    var cstats = libstore.compiled_stats(name)
    var manifest = libstore.compiled_manifest(name)
    var execution = libstore.compiled_execution_probe()
    var reason = "missing"
    var comparable = false
    var fresh = false
    var valid = false
    if stats["exists"] && cstats["exists"]
        if !manifest["exists"]
            reason = "bytecode_freshness_manifest_unavailable"
        elif !manifest["valid"]
            reason = manifest["reason"]
        else
            comparable = true
            var data = manifest["data"]
            var source_ok = data.contains("source_hash") && data["source_hash"] == stats["hash"]
            var compiled_ok = data.contains("compiled_hash") && data["compiled_hash"] == cstats["hash"]
            if data.contains("source_size")
                source_ok = source_ok && data["source_size"] == stats["size"]
            end
            if data.contains("compiled_size")
                compiled_ok = compiled_ok && data["compiled_size"] == cstats["size"]
            end
            fresh = source_ok && compiled_ok
            if fresh
                if execution["validator_supported"]
                    valid = true
                    reason = "ok"
                else
                    reason = "bytecode_validator_unavailable"
                end
            else
                reason = "stale_manifest"
            end
        end
    elif cstats["exists"]
        reason = "compiled_without_source"
    elif stats["exists"]
        reason = "compiled_missing"
    end
    return {
        "name": name,
        "supported": execution["validator_supported"],
        "valid": valid,
        "fresh": fresh,
        "comparable": comparable,
        "reason": reason,
        "loader_supported": execution["loader_supported"],
        "execution_supported": execution["supported"],
        "source_path": stats["path"],
        "compiled_path": cstats["path"],
        "manifest_path": manifest["path"]
    }
end

libstore.compiled_load_plan = def(name)
    var fresh = libstore.compiled_freshness(name)
    var validation = libstore.compiled_validation(name)
    var reason = fresh["reason"]
    if fresh["compiled_exists"] && fresh["fresh"] && !validation["valid"]
        reason = validation["reason"]
    end
    var can_load = fresh["usable"] && validation["valid"]
    return {
        "name": name,
        "can_load": can_load,
        "reason": can_load ? "ok" : reason,
        "path": fresh["compiled_path"],
        "compiled_exists": fresh["compiled_exists"],
        "fresh": fresh["fresh"],
        "usable": fresh["usable"],
        "validation_valid": validation["valid"],
        "validation_reason": validation["reason"],
        "loader_supported": validation["loader_supported"],
        "validator_supported": validation["supported"],
        "execution_supported": validation["execution_supported"]
    }
end

libstore.load_compiled = def(name)
    var plan = libstore.compiled_load_plan(name)
    if !plan["can_load"]
        raise "unsupported_error", plan["reason"]
    end
    return run_file(plan["path"])
end

libstore.compiled_status = def(name)
    var fresh = libstore.compiled_freshness(name)
    var validation = libstore.compiled_validation(name)
    var load_plan = libstore.compiled_load_plan(name)
    var emit_plan = libstore.compile_cache_plan(name)
    return {
        "name": name,
        "source_exists": fresh["source_exists"],
        "source_path": fresh["source_path"],
        "compiled_exists": fresh["compiled_exists"],
        "compiled_path": fresh["compiled_path"],
        "manifest_exists": fresh["manifest_exists"],
        "manifest_path": fresh["manifest_path"],
        "manifest_valid": fresh["manifest_valid"],
        "fresh": fresh["fresh"],
        "comparable": fresh["comparable"],
        "usable": fresh["usable"],
        "freshness_reason": fresh["reason"],
        "validator_supported": validation["supported"],
        "validation_valid": validation["valid"],
        "validation_reason": validation["reason"],
        "can_load": load_plan["can_load"],
        "load_reason": load_plan["reason"],
        "can_emit": emit_plan["can_emit"],
        "emit_reason": emit_plan["emit_blocked_reason"] == nil ? "ok" : emit_plan["emit_blocked_reason"],
        "load_plan": load_plan,
        "emit_plan": emit_plan,
        "validation": validation
    }
end

libstore.compiled_status_text = def(name)
    return json.dump(libstore.compiled_status(name))
end

libstore.compiled_inventory = def()
    var out = []
    for name : libstore.modules()
        out.push(libstore.compiled_status(name))
    end
    return out
end

libstore.compiled_inventory_text = def()
    return json.dump(libstore.compiled_inventory())
end

libstore.compiled_summary = def()
    var items = libstore.compiled_inventory()
    var out = {
        "modules": size(items),
        "source_exists": 0,
        "compiled_exists": 0,
        "manifest_exists": 0,
        "manifest_valid": 0,
        "fresh": 0,
        "usable": 0,
        "can_load": 0,
        "can_emit": 0,
        "blocked_load": 0,
        "blocked_emit": 0,
        "load_reasons": {},
        "emit_reasons": {}
    }
    for item : items
        if item["source_exists"]
            out["source_exists"] += 1
        end
        if item["compiled_exists"]
            out["compiled_exists"] += 1
        end
        if item["manifest_exists"]
            out["manifest_exists"] += 1
        end
        if item["manifest_valid"]
            out["manifest_valid"] += 1
        end
        if item["fresh"]
            out["fresh"] += 1
        end
        if item["usable"]
            out["usable"] += 1
        end
        if item["can_load"]
            out["can_load"] += 1
        else
            out["blocked_load"] += 1
        end
        var load_reason = item["load_reason"]
        if !out["load_reasons"].contains(load_reason)
            out["load_reasons"][load_reason] = 0
        end
        out["load_reasons"][load_reason] += 1
        if item["can_emit"]
            out["can_emit"] += 1
        else
            out["blocked_emit"] += 1
        end
        var emit_reason = item["emit_reason"]
        if !out["emit_reasons"].contains(emit_reason)
            out["emit_reasons"][emit_reason] = 0
        end
        out["emit_reasons"][emit_reason] += 1
    end
    return out
end

libstore.compiled_summary_text = def()
    return json.dump(libstore.compiled_summary())
end

libstore.compiled_loadable = def()
    var out = []
    for item : libstore.compiled_inventory()
        if item["can_load"]
            out.push(item)
        end
    end
    return out
end

libstore.compiled_loadable_text = def()
    return json.dump(libstore.compiled_loadable())
end

libstore.compiled_emittable = def()
    var out = []
    for item : libstore.compiled_inventory()
        if item["can_emit"]
            out.push(item)
        end
    end
    return out
end

libstore.compiled_emittable_text = def()
    return json.dump(libstore.compiled_emittable())
end

libstore.compiled_blocked = def()
    var out = []
    for item : libstore.compiled_inventory()
        if !item["can_load"] || !item["can_emit"]
            out.push(item)
        end
    end
    return out
end

libstore.compiled_blocked_text = def()
    return json.dump(libstore.compiled_blocked())
end

libstore.compiled_provision_plan = def()
    var summary = libstore.compiled_summary()
    var loadable = libstore.compiled_loadable()
    var emittable = libstore.compiled_emittable()
    var blocked = libstore.compiled_blocked()
    var recommendation = "source_fallback"
    if summary["can_load"] > 0
        recommendation = "load_fresh_compiled"
    elif summary["can_emit"] > 0
        recommendation = "emit_cache_candidates"
    end
    return {
        "ok": true,
        "recommendation": recommendation,
        "summary": summary,
        "loadable": loadable,
        "emittable": emittable,
        "blocked": blocked,
        "loadable_count": size(loadable),
        "emittable_count": size(emittable),
        "blocked_count": size(blocked),
        "default_source_fallback": summary["can_load"] == 0
    }
end

libstore.compiled_provision_plan_text = def()
    return json.dump(libstore.compiled_provision_plan())
end

libstore.compiled_freshness = def(name)
    libstore.compiled_execution_probe()
    var stats = libstore.source_stats(name)
    var cstats = libstore.compiled_stats(name)
    var manifest = libstore.compiled_manifest(name)
    var reason = "missing"
    var comparable = false
    var fresh = false
    var usable = false
    if stats["exists"] && cstats["exists"]
        if !manifest["exists"]
            reason = "bytecode_freshness_manifest_unavailable"
        elif !manifest["valid"]
            reason = manifest["reason"]
        else
            comparable = true
            var data = manifest["data"]
            var source_ok = data.contains("source_hash") && data["source_hash"] == stats["hash"]
            var compiled_ok = data.contains("compiled_hash") && data["compiled_hash"] == cstats["hash"]
            if data.contains("source_size")
                source_ok = source_ok && data["source_size"] == stats["size"]
            end
            if data.contains("compiled_size")
                compiled_ok = compiled_ok && data["compiled_size"] == cstats["size"]
            end
            fresh = source_ok && compiled_ok
            usable = fresh && libstore.compiled_supported
            reason = fresh ? (usable ? "fresh" : "compiled_execution_unavailable") : "stale_manifest"
        end
    elif cstats["exists"]
        reason = "compiled_without_source"
    elif stats["exists"]
        reason = "compiled_missing"
    end
    return {
        "name": name,
        "source_path": stats["path"],
        "source_exists": stats["exists"],
        "source_size": stats["size"],
        "source_hash": stats["hash"],
        "compiled_path": cstats["path"],
        "compiled_exists": cstats["exists"],
        "compiled_size": cstats["size"],
        "compiled_hash": cstats["hash"],
        "manifest_path": manifest["path"],
        "manifest_exists": manifest["exists"],
        "manifest_valid": manifest["valid"],
        "manifest_reason": manifest["reason"],
        "fresh": fresh,
        "usable": usable,
        "comparable": comparable,
        "reason": reason
    }
end

libstore.exists = def(name)
    return libstore.source_path(name) != nil
end

libstore.resolve = def(name)
    var path = libstore.source_path(name)
    var cpath = libstore.compiled_path(name)
    var stats = libstore.source_stats(name)
    var cstats = libstore.compiled_stats(name)
    var freshness = libstore.compiled_freshness(name)
    var selected_path = nil
    var selected_kind = nil
    var reason = "missing"
    var compiled_preferred = cpath != nil && freshness["fresh"]
    var compiled_blocked_reason = cpath == nil ? "compiled_missing" : nil

    if libstore.compiled_supported && freshness["usable"]
        selected_path = cpath
        selected_kind = "compiled"
        reason = "compiled_supported"
        compiled_blocked_reason = nil
    elif path != nil
        selected_path = path
        selected_kind = "source"
        reason = cpath != nil ? "compiled_unsupported_source_fallback" : "source"
        compiled_blocked_reason = cpath != nil ? freshness["reason"] : "compiled_missing"
    elif cpath != nil
        reason = "compiled_unsupported_no_source"
        compiled_blocked_reason = freshness["reason"]
    end

    return {
        "name": name,
        "source_path": path,
        "source_exists": path != nil,
        "source_size": stats["size"],
        "source_hash": stats["hash"],
        "compiled_path": cpath,
        "compiled_exists": cpath != nil,
        "compiled_size": cstats["size"],
        "compiled_hash": cstats["hash"],
        "compiled_manifest_path": freshness["manifest_path"],
        "compiled_manifest_exists": freshness["manifest_exists"],
        "compiled_manifest_valid": freshness["manifest_valid"],
        "compiled_manifest_reason": freshness["manifest_reason"],
        "compiled_fresh": freshness["fresh"],
        "compiled_usable": freshness["usable"],
        "compiled_freshness_reason": freshness["reason"],
        "compiled_supported": libstore.compiled_supported,
        "compiled_preferred": compiled_preferred,
        "compiled_blocked_reason": compiled_blocked_reason,
        "selected_path": selected_path,
        "selected_kind": selected_kind,
        "reason": reason,
        "source_fallback": selected_kind == "source" && cpath != nil
    }
end

libstore.info = def(name)
    var execution_probe = libstore.compiled_execution_probe()
    var path = libstore.source_path(name)
    var cpath = libstore.compiled_path(name)
    var resolved = libstore.resolve(name)
    var stats = libstore.source_stats(name)
    var cstats = libstore.compiled_stats(name)
    var freshness = libstore.compiled_freshness(name)
    var psram = p2.psram_info()
    var window = libstore.cache_ensure()
    var heap = psram["heap"] ? "external" : "hub"
    var policy = libstore._policy_resolve()
    var use_psram_cache = libstore._policy_uses_psram_cache(policy)
    var load = use_psram_cache ? "lazy_source_or_psram_cache" : "lazy_source"
    if !psram["available"]
        load = "lazy_source"
    end
    var cached = libstore.cache.contains(name) ? libstore.cache[name] : nil
    var coverage = libstore.coverage(name)
    var cache_plan = libstore.compile_cache_plan(name)
    var validation = libstore.compiled_validation(name)
    var load_plan = libstore.compiled_load_plan(name)
    var compiled_status = libstore.compiled_status(name)
    return {
        "name": name,
        "path": path,
        "exists": path != nil,
        "source_size": stats["size"],
        "source_hash": stats["hash"],
        "compiled_path": cpath,
        "compiled_exists": cpath != nil,
        "compiled_size": cstats["size"],
        "compiled_hash": cstats["hash"],
        "compiled_manifest_path": freshness["manifest_path"],
        "compiled_manifest_exists": freshness["manifest_exists"],
        "compiled_manifest_valid": freshness["manifest_valid"],
        "compiled_manifest_reason": freshness["manifest_reason"],
        "compiled_fresh": freshness["fresh"],
        "compiled_usable": freshness["usable"],
        "compiled_freshness_reason": freshness["reason"],
        "compiled_supported": libstore.compiled_supported,
        "compiled_loader_supported": execution_probe["loader_supported"],
        "compiled_bytecode_loader": execution_probe["loader_supported"],
        "compiled_validator_supported": execution_probe["validator_supported"],
        "compiled_loader_reason": execution_probe["reason"],
        "compiled_validation_supported": validation["supported"],
        "compiled_validation_valid": validation["valid"],
        "compiled_validation_reason": validation["reason"],
        "compiled_load_can": load_plan["can_load"],
        "compiled_load_reason": load_plan["reason"],
        "compiled_status_can_load": compiled_status["can_load"],
        "compiled_status_can_emit": compiled_status["can_emit"],
        "compiled_status_reason": compiled_status["load_reason"],
        "compiled_preferred": resolved["compiled_preferred"],
        "compiled_blocked_reason": resolved["compiled_blocked_reason"],
        "compile_cache_supported": cache_plan["supported"],
        "compile_cache_can_emit": cache_plan["can_emit"],
        "compile_cache_reason": cache_plan["reason"],
        "compile_cache_blocked_reason": cache_plan["emit_blocked_reason"],
        "compile_cache_target_path": cache_plan["target_path"],
        "compile_cache_manifest_target_path": cache_plan["manifest_target_path"],
        "compile_cache_manifest_format": cache_plan["manifest_format"],
        "compile_cache_manifest_template_available": cache_plan["manifest_template_available"],
        "compile_cache_manifest_template_reason": cache_plan["manifest_template_reason"],
        "selected_path": resolved["selected_path"],
        "selected_kind": resolved["selected_kind"],
        "resolve_reason": resolved["reason"],
        "source_fallback": resolved["source_fallback"],
        "source": "sd",
        "load": load,
        "heap": heap,
        "policy": policy,
        "psram_cache": window["available"],
        "psram_cache_base": libstore.cache_base,
        "psram_cache_limit": libstore.cache_limit,
        "cache_hit_count": libstore.cache_hits_for(name),
        "cache_miss_count": libstore.cache_misses_for(name),
        "last_used": cached == nil ? nil : cached["last_used"],
        "cached": cached != nil,
        "cache": cached,
        "coverage": coverage,
        "coverage_status": coverage["status"],
        "behavior_smoke": coverage["behavior_smoke"],
        "sd_import_smoke": coverage["sd_import_smoke"],
        "repeated_import_smoke": coverage["repeated_import_smoke"],
        "cache_smoke": coverage["cache_smoke"],
        "low_memory_smoke": coverage["low_memory_smoke"],
        "metadata_smoke": coverage["metadata_smoke"],
        "coverage_reason": coverage["reason"]
    }
end

libstore.inventory = def()
    var out = []
    for name : libstore.modules()
        out.push(libstore.info(name))
    end
    return out
end

libstore.cache_reset = def()
    var window = libstore.cache_window()
    libstore.cache_base = window["base"]
    libstore.cache_limit = window["limit"]
    libstore.cache = {}
    libstore.cache_next = libstore.cache_base
    libstore.cache_hits = {}
    libstore.cache_misses = {}
    libstore.cache_access = 0
    return window
end

libstore.cached = def(name)
    return libstore.cache.contains(name)
end

libstore.cache_source = def(name)
    var policy = libstore._policy_resolve()
    var use_psram_cache = libstore._policy_uses_psram_cache(policy)
    if !use_psram_cache
        return nil
    end
    var psram = p2.psram_info()
    var window = libstore.cache_ensure()
    if !window["available"] || !psram["available"]
        return nil
    end
    var path = libstore.source_path(name)
    if path == nil
        libstore._bump_counter(libstore.cache_misses, name)
        return nil
    end
    if libstore.cache.contains(name)
        var hit = libstore.cache[name]
        libstore._bump_counter(libstore.cache_hits, name)
        hit["cache_hit_count"] = libstore.cache_hits_for(name)
        hit["last_used"] = libstore.cache_access
        return hit
    end
    libstore._bump_counter(libstore.cache_misses, name)

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
        "source_hash": libstore.hash_text(source),
        "chunks": chunks,
        "chunk_count": chunks.size(),
        "max_transfer": max_transfer,
        "cache_hit_count": libstore.cache_hits_for(name),
        "cache_miss_count": libstore.cache_misses_for(name),
        "last_used": libstore.cache_access
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
    libstore._bump_counter(libstore.cache_hits, name)
    item["cache_hit_count"] = libstore.cache_hits_for(name)
    item["last_used"] = libstore.cache_access
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
    # Compiled bytecode files are detected by info()/compiled_path(), but this
    # P2 port does not execute .bec yet. Keep the active load path as source
    # fallback until bytecode validation/freshness is implemented.
    var policy = libstore._policy_resolve()
    if libstore._policy_uses_psram_cache(policy)
        var source = libstore.cached_source(name)
        if source != nil
            return compile(source)()
        end
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
    for name : libstore.modules()
        if libstore.exists(name)
            out.push(libstore.cache_source(name))
        end
    end
    return out
end

libstore.cache_report = def()
    var items = []
    for name : libstore.modules()
        if libstore.cache.contains(name)
            var item = libstore.cache[name]
            items.push({
                "name": name,
                "path": item["path"],
                "address": item["address"],
                "size": item["size"],
                "source_hash": item["source_hash"],
                "chunks": item["chunk_count"],
                "cache_hit_count": libstore.cache_hits_for(name),
                "cache_miss_count": libstore.cache_misses_for(name),
                "last_used": item["last_used"]
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
