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
import introspect

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
    "p2smart",
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
    "p2smart": {
        "status": "covered",
        "behavior_smoke": "/tests/p2/smoke_smartpins_loopback.be",
        "sd_import_smoke": "/tests/p2/smoke_import_all_libs.be",
        "repeated_import_smoke": "/tests/p2/smoke_import_cache.be",
        "cache_smoke": "/tests/p2/smoke_import_cache.be",
        "low_memory_smoke": "/tests/p2/smoke_import_churn.be",
        "metadata_smoke": "/tests/p2/smoke_module_inventory.be",
        "reason": "smart-pin wrapper behavior plus SD import/cache/churn coverage"
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

libstore.valid_module_name = def(name)
    if type(name) != "string" || size(name) == 0
        return false
    end
    if string.find(name, "/") >= 0 || string.find(name, "\\") >= 0
        return false
    end
    if string.startswith(name, ".") || string.endswith(name, ".")
        return false
    end
    if string.find(name, "..") >= 0
        return false
    end
    return true
end

libstore.module_file = def(name, ext)
    if !libstore.valid_module_name(name)
        raise "value_error", "invalid module name"
    end
    var out = str(name)
    out = string.replace(out, ".", "/")
    return out + ext
end

libstore.module_file_or_nil = def(name, ext)
    if !libstore.valid_module_name(name)
        return nil
    end
    return libstore.module_file(name, ext)
end

libstore._hash_mod_add = def(a, b)
    var mod = 2147483647
    if a >= mod - b
        return a - (mod - b)
    end
    return a + b
end

libstore.hash_bytes = def(raw)
    var h = 0
    var i = 0
    while i < raw.size()
        var old = h
        h = raw[i]
        var j = 0
        while j < 33
            h = libstore._hash_mod_add(h, old)
            j += 1
        end
        i += 1
    end
    return h
end

libstore.hash_text = def(text)
    return libstore.hash_bytes(bytes().fromstring(text))
end

libstore.compiled_expected_sizeinfo = def()
    var status = p2.status_info()
    if status.contains("build")
        var build = status["build"]
        if build.contains("bytecode_sizeinfo")
            return build["bytecode_sizeinfo"]
        end
        if build.contains("profile")
            # P2 Catalina uses 32-bit bint plus single-precision breal.
            return 0
        end
    end
    return nil
end

libstore.compiled_expected_builtin_count = def()
    var status = p2.status_info()
    if status.contains("build")
        var build = status["build"]
        if build.contains("builtin_count")
            return build["builtin_count"]
        end
    end
    return nil
end

libstore._le_u32 = def(raw, offset)
    if raw.size() < offset + 4
        return nil
    end
    return raw[offset] +
        raw[offset + 1] * 256 +
        raw[offset + 2] * 65536 +
        raw[offset + 3] * 16777216
end

libstore._read_file_bytes = def(path)
    var f = open(path, "r")
    try
        var raw = f.readbytes()
        f.close()
        return raw
    except .. as e, m
        f.close()
    end
    f = open(path, "r")
    var text = f.read()
    f.close()
    return bytes().fromstring(text)
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
    var f = open(path, "r")
    var source = f.read()
    f.close()
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
    var bytecode = libstore._read_file_bytes(path)
    return {
        "path": path,
        "exists": true,
        "size": bytecode.size(),
        "hash": libstore.hash_bytes(bytecode)
    }
end

libstore.compiled_header = def(name)
    var path = libstore.compiled_path(name)
    if path == nil
        return {
            "path": nil,
            "valid": false,
            "reason": "compiled_missing"
        }
    end
    var bytecode = libstore._read_file_bytes(path)
    var magic_valid = bytecode.size() >= 8 &&
        bytecode[0] == 0xbe &&
        bytecode[1] == 0xcd &&
        bytecode[2] == 0xfe &&
        bytecode[3] == 0x04
    var expected_sizeinfo = nil
    var sizeinfo = nil
    var sizeinfo_valid = true
    var expected_builtin_count = nil
    var builtin_count = nil
    var builtin_count_valid = true
    if magic_valid
        sizeinfo = bytecode[4]
        expected_sizeinfo = libstore.compiled_expected_sizeinfo()
        sizeinfo_valid = expected_sizeinfo == nil || sizeinfo == expected_sizeinfo
        builtin_count = libstore._le_u32(bytecode, 8)
        expected_builtin_count = libstore.compiled_expected_builtin_count()
        builtin_count_valid = expected_builtin_count == nil || builtin_count == expected_builtin_count
    end
    var valid = magic_valid && sizeinfo_valid && builtin_count_valid
    var reason = "invalid_bytecode_header"
    if valid
        reason = "ok"
    elif magic_valid && !sizeinfo_valid
        reason = "incompatible_bytecode_vm"
    elif magic_valid && !builtin_count_valid
        reason = "incompatible_bytecode_builtins"
    end
    return {
        "path": path,
        "valid": valid,
        "reason": reason,
        "version": magic_valid ? bytecode[3] : nil,
        "sizeinfo": sizeinfo,
        "expected_sizeinfo": expected_sizeinfo,
        "builtin_count": builtin_count,
        "expected_builtin_count": expected_builtin_count
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
    var i = 0
    while i < libstore.paths.size()
        var base = libstore.paths[i]
        if base == path
            return false
        end
        i += 1
    end
    libstore.paths.push(path)
    return true
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
    var i = 0
    while i < libstore.paths.size()
        out.push(libstore.paths[i])
        i += 1
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

libstore._coverage_snapshot = def(item)
    return {
        "status": item["status"],
        "behavior_smoke": item["behavior_smoke"],
        "sd_import_smoke": item["sd_import_smoke"],
        "repeated_import_smoke": item["repeated_import_smoke"],
        "cache_smoke": item["cache_smoke"],
        "low_memory_smoke": item["low_memory_smoke"],
        "metadata_smoke": item["metadata_smoke"],
        "reason": item["reason"]
    }
end

libstore.capabilities = def()
    return {
        "lazy_sd_source": true,
        "path_list": true,
        "path_add_remove": true,
        "coverage_metadata": true,
        "inventory": true,
        "info": true,
        "source_stats": true,
        "compiled_stats": true,
        "compiled_manifest": true,
        "compiled_fallback": true,
        "compile_cache_planning": true,
        "psram_source_cache": true,
        "policy_diagnostics": true,
        "status_diagnostics": true,
        "app_paths": true,
        "example_paths": true,
        "pasm_paths": true,
        "pasm_storage_policy": true,
        "valid_module_name": true,
        "audit": true,
        "audit_policy": "metadata_only_no_sd_scan_or_cache_mutation"
    }
end

libstore.capability = def(name)
    if type(name) != "string"
        return nil
    end
    var caps = libstore.capabilities()
    if caps.contains(name)
        return caps[name]
    end
    return nil
end

libstore.required_capability_keys = def()
    return [
        "lazy_sd_source",
        "path_list",
        "path_add_remove",
        "coverage_metadata",
        "inventory",
        "info",
        "source_stats",
        "compiled_stats",
        "compiled_manifest",
        "compiled_fallback",
        "compile_cache_planning",
        "psram_source_cache",
        "policy_diagnostics",
        "status_diagnostics",
        "app_paths",
        "example_paths",
        "pasm_paths",
        "pasm_storage_policy",
        "valid_module_name",
        "audit",
        "audit_policy"
    ]
end

libstore.audit = def()
    var caps = libstore.capabilities()
    var problems = []
    var missing_capability_keys = []
    var seen = {}
    var covered = 0
    var hardware_deferred = 0
    var unknown = 0

    for name : libstore.required_capability_keys()
        if !caps.contains(name)
            missing_capability_keys.push(name)
        elif name != "audit_policy" && !caps[name]
            problems.push(name + "_capability_disabled")
        end
    end
    if missing_capability_keys.size() != 0
        problems.push("missing_capability_keys")
    end
    if caps["audit_policy"] != "metadata_only_no_sd_scan_or_cache_mutation"
        problems.push("audit_policy_mismatch")
    end
    if libstore.capability("coverage_metadata") != caps["coverage_metadata"]
        problems.push("coverage_metadata_lookup_mismatch")
    end
    if libstore.capability("missing") != nil
        problems.push("missing_lookup_not_nil")
    end
    if libstore.capability(nil) != nil
        problems.push("nil_lookup_not_nil")
    end
    if libstore.POLICY_SD_LAZY != "sd_only"
        problems.push("sd_lazy_policy_mismatch")
    end
    if libstore.POLICY_SD_CACHE_PSRAM != "sd_cache_psram"
        problems.push("sd_cache_policy_mismatch")
    end
    if libstore.POLICY_SD_PRELOAD_PSRAM != "sd_preload_psram"
        problems.push("sd_preload_policy_mismatch")
    end
    if !libstore._policy_supported(libstore.POLICY_SD_LAZY) ||
            !libstore._policy_supported(libstore.POLICY_SD_CACHE_PSRAM) ||
            !libstore._policy_supported(libstore.POLICY_SD_PRELOAD_PSRAM)
        problems.push("policy_support_mismatch")
    end
    if libstore._normalize_policy("missing") != nil
        problems.push("unknown_policy_normalized")
    end
    if libstore.MANIFEST_FORMAT != "berry-p2-bec-manifest-v1"
        problems.push("manifest_format_mismatch")
    end
    if libstore.paths.size() == 0 || libstore.paths[0] != "/modules"
        problems.push("module_path_root_mismatch")
    end
    if libstore.compiled_paths.size() == 0 || libstore.compiled_paths[0] != "/berry/cache"
        problems.push("compiled_path_root_mismatch")
    end
    if libstore.app_paths.size() == 0 || libstore.app_paths[0] != "/berry/app"
        problems.push("app_path_root_mismatch")
    end
    if libstore.example_paths.size() == 0 || libstore.example_paths[0] != "/berry/examples"
        problems.push("example_path_root_mismatch")
    end
    if libstore.pasm_paths.size() == 0 || libstore.pasm_paths[0] != "/berry/pasm"
        problems.push("pasm_path_root_mismatch")
    end
    var pasm_policy = libstore.pasm_policy()
    if pasm_policy["storage_root"] != "/berry/pasm"
        problems.push("pasm_policy_root_mismatch")
    end
    if pasm_policy["execution_supported"] || pasm_policy["executable"]
        problems.push("pasm_policy_execution_mismatch")
    end
    if pasm_policy["reason"] != "pasm_execution_deferred"
        problems.push("pasm_policy_reason_mismatch")
    end
    if !libstore.valid_module_name("pkg.mod")
        problems.push("valid_dotted_module_rejected")
    end
    if libstore.valid_module_name("") || libstore.valid_module_name(nil) ||
            libstore.valid_module_name("../escape") ||
            libstore.valid_module_name("bad/name") ||
            libstore.valid_module_name(".hidden") ||
            libstore.valid_module_name("trailing.")
        problems.push("invalid_module_name_accepted")
    end
    if libstore.module_file_or_nil("pkg.mod", ".be") != "pkg/mod.be"
        problems.push("module_file_mapping_mismatch")
    end
    if libstore.module_file_or_nil("../escape", ".be") != nil
        problems.push("invalid_module_file_not_nil")
    end

    for name : libstore.known
        if seen.contains(name)
            problems.push("duplicate_known_module:" + name)
        end
        seen[name] = true
        if !libstore.valid_module_name(name)
            problems.push("invalid_known_module:" + name)
        end
        if !libstore.coverage_table.contains(name)
            problems.push("missing_coverage:" + name)
        else
            var cov = libstore.coverage_table[name]
            if !cov.contains("status") || !cov.contains("sd_import_smoke") ||
                    !cov.contains("repeated_import_smoke") ||
                    !cov.contains("cache_smoke") ||
                    !cov.contains("low_memory_smoke") ||
                    !cov.contains("metadata_smoke") ||
                    !cov.contains("reason")
                problems.push("coverage_shape_mismatch:" + name)
            else
                if cov["status"] == "covered"
                    covered += 1
                    if cov["behavior_smoke"] == nil
                        problems.push("covered_behavior_missing:" + name)
                    end
                elif cov["status"] == "hardware_deferred"
                    hardware_deferred += 1
                    if cov["behavior_smoke"] != nil
                        problems.push("hardware_deferred_behavior_present:" + name)
                    end
                else
                    unknown += 1
                    problems.push("unknown_coverage_status:" + name)
                end
                if cov["sd_import_smoke"] != "/tests/p2/smoke_import_all_libs.be"
                    problems.push("sd_import_smoke_mismatch:" + name)
                end
                if cov["metadata_smoke"] != "/tests/p2/smoke_module_inventory.be"
                    problems.push("metadata_smoke_mismatch:" + name)
                end
            end
        end
    end

    return {
        "ok": problems.size() == 0,
        "problem_count": problems.size(),
        "problems": problems,
        "missing_capability_keys": missing_capability_keys,
        "audit_policy": caps["audit_policy"],
        "known_count": libstore.known.size(),
        "coverage_count": size(libstore.coverage_table),
        "covered_count": covered,
        "hardware_deferred_count": hardware_deferred,
        "unknown_coverage_count": unknown,
        "pasm_policy": pasm_policy,
        "lazy_sd_source": caps["lazy_sd_source"],
        "coverage_metadata": caps["coverage_metadata"],
        "compiled_fallback": caps["compiled_fallback"],
        "psram_source_cache": caps["psram_source_cache"]
    }
end

libstore.audit_problems = def()
    return libstore.audit()["problems"]
end

libstore.audit_ok = def()
    return libstore.audit()["ok"]
end

libstore.app_path = def(name)
    var file = libstore.module_file_or_nil(name, ".be")
    if file == nil
        return nil
    end
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
    var file = libstore.module_file_or_nil(name, ".be")
    if file == nil
        return nil
    end
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
    var file = libstore.module_file_or_nil(name, ".bin")
    if file == nil
        return nil
    end
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

libstore.pasm_policy = def()
    return {
        "ok": true,
        "storage_supported": true,
        "storage_root": "/berry/pasm",
        "path_pattern": "/berry/pasm/*.bin",
        "nested_module_names": true,
        "load_supported": true,
        "load_result_helper": true,
        "executable": false,
        "execution_supported": false,
        "execution_policy": "deferred_to_p2_asm_marker_fixture",
        "reason": "pasm_execution_deferred",
        "native_launch_policy": "p2.asm exact marker fixture only"
    }
end

libstore.pasm_info = def(name)
    var path = libstore.pasm_path(name)
    if path == nil
        return {
            "name": name,
            "path": nil,
            "exists": false,
            "size": 0,
            "hash": nil,
            "executable": false,
            "reason": "missing"
        }
    end
    var f = open(path, "r")
    var data = f.read()
    f.close()
    return {
        "name": name,
        "path": path,
        "exists": true,
        "size": size(data),
        "hash": libstore.hash_text(data),
        "executable": false,
        "reason": "pasm_execution_deferred"
    }
end

libstore.pasm_load = def(name)
    var path = libstore.pasm_path(name)
    if path == nil
        return nil
    end
    var f = open(path, "r")
    var data = f.read()
    f.close()
    return data
end

libstore.pasm_load_result = def(name)
    var path = libstore.pasm_path(name)
    if path == nil
        return {
            "ok": false,
            "found": false,
            "name": name,
            "path": nil,
            "data": nil,
            "size": 0,
            "hash": nil,
            "executable": false,
            "reason": libstore.valid_module_name(name) ? "missing" : "invalid_module_name"
        }
    end
    var f = open(path, "r")
    var data = f.read()
    f.close()
    return {
        "ok": true,
        "found": true,
        "name": name,
        "path": path,
        "data": data,
        "size": size(data),
        "hash": libstore.hash_text(data),
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
        "paths": libstore.path_list(),
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
        "library_count": libstore.known_source_count(),
        "psram_max_transfer": psram["max_transfer"],
        "heap": heap
    }
end

libstore.known_source_count = def()
    var count = 0
    var i = 0
    while i < libstore.known.size()
        var name = libstore.known[i]
        if libstore.source_path(name) != nil
            count += 1
        end
        i += 1
    end
    return count
end

libstore.modules = def()
    return libstore.scan()
end

libstore.source_path = def(name)
    var file = libstore.module_file_or_nil(name, ".be")
    if file == nil
        return nil
    end
    var i = 0
    while i < libstore.paths.size()
        var base = libstore.paths[i]
        var path = base + "/" + file
        if os.path.exists(path)
            return path
        end
        i += 1
    end
    return nil
end

libstore.compiled_path = def(name)
    var file = libstore.module_file_or_nil(name, ".bec")
    if file == nil
        return nil
    end
    var i = 0
    while i < libstore.compiled_paths.size()
        var base = libstore.compiled_paths[i]
        var path = base + "/" + file
        if os.path.exists(path)
            return path
        end
        i += 1
    end
    return nil
end

libstore.compiled_exists = def(name)
    return libstore.compiled_path(name) != nil
end

libstore.compiled_candidate_path = def(name)
    var file = libstore.module_file_or_nil(name, ".bec")
    if file == nil
        return nil
    end
    return libstore.compiled_paths[0] + "/" + file
end

libstore.compiled_manifest_candidate_path = def(name)
    var path = libstore.compiled_candidate_path(name)
    if path == nil
        return nil
    end
    if string.endswith(path, ".bec")
        return path[0..(size(path) - 5)] + ".jsn"
    end
    return path + ".jsn"
end

libstore.compiled_manifest_path = def(name)
    var candidate = libstore.compiled_manifest_candidate_path(name)
    if os.path.exists(candidate)
        return candidate
    end
    return nil
end

libstore.compiled_manifest = def(name)
    if !libstore.valid_module_name(name)
        return {
            "path": nil,
            "exists": false,
            "valid": false,
            "reason": "invalid_module_name",
            "data": nil
        }
    end
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
    var f = open(path, "r")
    var text = f.read()
    f.close()
    if !string.startswith(text, "{")
        return {
            "path": path,
            "exists": true,
            "valid": false,
            "reason": "invalid_manifest",
            "data": nil
        }
    end
    var data = json.load(text)
    var data_type = type(data)
    var valid = data_type == "map" || data_type == "instance"
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
    if !libstore.valid_module_name(name)
        return {
            "available": false,
            "reason": "invalid_module_name",
            "format": libstore.MANIFEST_FORMAT,
            "path": libstore.compiled_manifest_candidate_path(name),
            "data": nil
        }
    end
    var stats = libstore.source_stats(name)
    if !stats["exists"]
        return {
            "available": false,
            "reason": "source_missing",
            "format": libstore.MANIFEST_FORMAT,
            "path": libstore.compiled_manifest_candidate_path(name),
            "data": nil
        }
    end
    var cstats = libstore.compiled_stats(name)
    var reason = "ok"
    if !cstats["exists"]
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
    if !introspect.contains(p2, "status_info")
        return {}
    end
    var status = p2.status_info()
    if type(status) == "map" && status.contains("build") && type(status["build"]) == "map"
        return status["build"]
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
    var saver = nil
    try
        saver = f.savecode
    except .. as e, m
    end
    var supported = type(saver) == "function"
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
    var valid_name = libstore.valid_module_name(name)
    var stats = libstore.source_stats(name)
    var cstats = libstore.compiled_stats(name)
    var manifest = libstore.compiled_manifest(name)
    var reason = libstore.compile_cache_reason
    if !valid_name
        reason = "invalid_module_name"
    elif !stats["exists"]
        reason = "source_missing"
    end
    var can_emit = valid_name && libstore.compile_cache_supported && stats["exists"]
    var manifest_template_available = false
    var manifest_template_reason = valid_name ? (stats["exists"] ? (cstats["exists"] ? "ok" : "compiled_missing") : "source_missing") : "invalid_module_name"
    var manifest_template_data = nil
    if valid_name && stats["exists"] && cstats["exists"]
        var manifest_template = libstore.compiled_manifest_template(name)
        manifest_template_available = manifest_template["available"]
        manifest_template_reason = manifest_template["reason"]
        manifest_template_data = manifest_template["data"]
    end
    var selected_path = nil
    var selected_kind = nil
    var resolve_reason = "missing"
    if !valid_name
        resolve_reason = "invalid_module_name"
    elif stats["exists"]
        selected_path = stats["path"]
        selected_kind = "source"
        resolve_reason = cstats["exists"] ? "compiled_unsupported_source_fallback" : "source"
    elif cstats["exists"]
        resolve_reason = "compiled_unsupported_no_source"
    else
        resolve_reason = reason
    end
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
        "manifest_template_available": manifest_template_available,
        "manifest_template_reason": manifest_template_reason,
        "manifest_template": manifest_template_data,
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
        "selected_path": selected_path,
        "selected_kind": selected_kind,
        "resolve_reason": resolve_reason
    }
end

libstore.compile_cache_emit = def(name)
    if !libstore.valid_module_name(name)
        raise "value_error", "invalid module name"
    end
    var plan = libstore.compile_cache_plan(name, true)
    if !plan["source_exists"]
        raise "value_error", "source module is missing"
    end
    if !plan["can_emit"]
        raise "unsupported_error", plan["emit_blocked_reason"]
    end

    libstore._ensure_parent_dir(plan["target_path"])
    libstore._ensure_parent_dir(plan["manifest_target_path"])

    var source_file = open(plan["source_path"], "r")
    var source = source_file.read()
    source_file.close()
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
    if !libstore.valid_module_name(name)
        reason = "invalid_module_name"
    elif stats["exists"] && cstats["exists"]
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
                    var header = libstore.compiled_header(name)
                    valid = header["valid"]
                    reason = valid ? "ok" : header["reason"]
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
    var reason = fresh["reason"]
    var validation = {
        "valid": false,
        "reason": reason,
        "loader_supported": libstore.compiled_loader_supported,
        "supported": libstore.compiled_validator_supported,
        "execution_supported": libstore.compiled_supported
    }
    if fresh["compiled_exists"] && fresh["fresh"]
        validation = libstore.compiled_validation(name)
    end
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
    var validation = {
        "supported": libstore.compiled_validator_supported,
        "valid": false,
        "fresh": fresh["fresh"],
        "comparable": fresh["comparable"],
        "reason": fresh["reason"],
        "loader_supported": libstore.compiled_loader_supported,
        "execution_supported": libstore.compiled_supported,
        "source_path": fresh["source_path"],
        "compiled_path": fresh["compiled_path"],
        "manifest_path": fresh["manifest_path"]
    }
    if fresh["compiled_exists"] && fresh["fresh"]
        validation = libstore.compiled_validation(name)
    end
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
    if !libstore.valid_module_name(name)
        reason = "invalid_module_name"
    elif stats["exists"] && cstats["exists"]
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
                if libstore.compiled_supported
                    var header = libstore.compiled_header(name)
                    usable = header["valid"]
                    reason = usable ? "fresh" : header["reason"]
                else
                    reason = "compiled_execution_unavailable"
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

    if !libstore.valid_module_name(name)
        reason = "invalid_module_name"
        compiled_blocked_reason = "invalid_module_name"
    elif libstore.compiled_supported && freshness["usable"]
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
    var stats = libstore.source_stats(name)
    var cstats = libstore.compiled_stats(name)
    var freshness = nil
    var validation = nil
    var load_plan = nil
    if cstats["exists"]
        freshness = libstore.compiled_freshness(name)
        validation = libstore.compiled_validation(name)
        load_plan = libstore.compiled_load_plan(name)
    else
        var valid_name_for_freshness = libstore.valid_module_name(name)
        var missing_reason = valid_name_for_freshness ? (stats["exists"] ? "compiled_missing" : "missing") : "invalid_module_name"
        freshness = {
            "name": name,
            "source_path": stats["path"],
            "source_exists": stats["exists"],
            "source_size": stats["size"],
            "source_hash": stats["hash"],
            "compiled_path": cstats["path"],
            "compiled_exists": false,
            "compiled_size": cstats["size"],
            "compiled_hash": cstats["hash"],
            "manifest_path": nil,
            "manifest_exists": false,
            "manifest_valid": false,
            "manifest_reason": "missing",
            "fresh": false,
            "usable": false,
            "comparable": false,
            "reason": missing_reason
        }
        validation = {
            "valid": false,
            "fresh": false,
            "comparable": false,
            "reason": missing_reason,
            "loader_supported": execution_probe["loader_supported"],
            "supported": execution_probe["validator_supported"],
            "execution_supported": execution_probe["supported"],
            "source_path": stats["path"],
            "compiled_path": cstats["path"],
            "manifest_path": nil
        }
        load_plan = {
            "name": name,
            "can_load": false,
            "reason": missing_reason,
            "path": cstats["path"],
            "compiled_exists": false,
            "fresh": false,
            "usable": false,
            "validation_valid": false,
            "validation_reason": missing_reason,
            "loader_supported": execution_probe["loader_supported"],
            "validator_supported": execution_probe["validator_supported"],
            "execution_supported": execution_probe["supported"]
        }
    end
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
    var coverage = libstore._coverage_snapshot(libstore.coverage(name))
    var valid_name = libstore.valid_module_name(name)
    var compile_cache_reason = valid_name ? (path != nil ? libstore.compile_cache_reason : "source_missing") : "invalid_module_name"
    var compile_cache_can_emit = valid_name && libstore.compile_cache_supported && path != nil
    var template_available = valid_name && path != nil && cpath != nil
    var template_reason = template_available ? "ok" : (valid_name ? (path == nil ? "source_missing" : "compiled_missing") : "invalid_module_name")
    var selected_path = nil
    var selected_kind = nil
    var resolve_reason = "missing"
    var compiled_preferred = cpath != nil && freshness["fresh"]
    var compiled_blocked_reason = cpath == nil ? "compiled_missing" : nil
    if !valid_name
        resolve_reason = "invalid_module_name"
        compiled_blocked_reason = "invalid_module_name"
    elif libstore.compiled_supported && freshness["usable"]
        selected_path = cpath
        selected_kind = "compiled"
        resolve_reason = "compiled_supported"
        compiled_blocked_reason = nil
    elif path != nil
        selected_path = path
        selected_kind = "source"
        resolve_reason = cpath != nil ? "compiled_unsupported_source_fallback" : "source"
        compiled_blocked_reason = cpath != nil ? freshness["reason"] : "compiled_missing"
    elif cpath != nil
        resolve_reason = "compiled_unsupported_no_source"
        compiled_blocked_reason = freshness["reason"]
    end
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
        "compiled_validation_supported": execution_probe["validator_supported"],
        "compiled_validation_valid": validation["valid"],
        "compiled_validation_reason": validation["reason"],
        "compiled_load_can": load_plan["can_load"],
        "compiled_load_reason": load_plan["reason"],
        "compiled_status_can_load": load_plan["can_load"],
        "compiled_status_can_emit": compile_cache_can_emit,
        "compiled_status_reason": load_plan["reason"],
        "compiled_preferred": compiled_preferred,
        "compiled_blocked_reason": compiled_blocked_reason,
        "compile_cache_supported": libstore.compile_cache_supported,
        "compile_cache_can_emit": compile_cache_can_emit,
        "compile_cache_reason": compile_cache_reason,
        "compile_cache_blocked_reason": compile_cache_can_emit ? nil : compile_cache_reason,
        "compile_cache_target_path": libstore.compiled_candidate_path(name),
        "compile_cache_manifest_target_path": libstore.compiled_manifest_candidate_path(name),
        "compile_cache_manifest_format": libstore.MANIFEST_FORMAT,
        "compile_cache_manifest_template_available": template_available,
        "compile_cache_manifest_template_reason": template_reason,
        "selected_path": selected_path,
        "selected_kind": selected_kind,
        "resolve_reason": resolve_reason,
        "source_fallback": selected_kind == "source" && cpath != nil,
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
        "cache": cached == nil ? nil : libstore._cache_item_snapshot(cached),
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
    if !libstore.valid_module_name(name)
        return nil
    end
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

    var source_file = open(path, "r")
    var source = source_file.read()
    source_file.close()
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
        var part = p2.psram_read(chunk["address"], chunk["size"])
        if type(part) != "string" || size(part) != chunk["size"]
            raise "io_error", "PSRAM cache read failed"
        end
        out += part
    end
    if item.contains("source_hash") && item["source_hash"] != nil && libstore.hash_text(out) != item["source_hash"]
        libstore.cache.remove(name)
        return nil
    end
    return out
end

libstore.cached_source_execution_supported = def()
    try
        var status = p2.status_info()
        if status.contains("build")
            var build = status["build"]
            if build.contains("cached_source_execution")
                return build["cached_source_execution"]
            end
            if build.contains("profile")
                return false
            end
        end
    except .. as e, m
    end
    return true
end

libstore.run_cached = def(name)
    if !libstore.cached_source_execution_supported()
        return nil
    end
    var source = libstore.cached_source(name)
    if source == nil
        return nil
    end
    return compile(source)()
end

libstore.load = def(name)
    if !libstore.cached_source_execution_supported()
        var source_path = libstore.source_path(name)
        if source_path != nil
            return run_file(source_path)
        end
    end
    var resolved = libstore.resolve(name)
    if resolved["selected_path"] == nil
        return nil
    end
    if resolved["selected_kind"] == "compiled"
        return libstore.load_compiled(name)
    end
    var path = resolved["selected_path"]
    if !libstore.cached_source_execution_supported()
        return run_file(path)
    end
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

libstore._cache_item_snapshot = def(item)
    var chunks = []
    for chunk : item["chunks"]
        chunks.push({
            "address": chunk["address"],
            "size": chunk["size"]
        })
    end
    return {
        "name": item["name"],
        "path": item["path"],
        "address": item["address"],
        "size": item["size"],
        "source_hash": item["source_hash"],
        "chunks": chunks,
        "chunk_count": item["chunk_count"],
        "max_transfer": item["max_transfer"],
        "cache_hit_count": item["cache_hit_count"],
        "cache_miss_count": item["cache_miss_count"],
        "last_used": item["last_used"]
    }
end

libstore.cache_many_report = def(*names)
    var items = []
    var skipped = []
    for name : names
        if !libstore.valid_module_name(name)
            skipped.push({
                "module": name,
                "error": "invalid_module_name",
                "message": "invalid module name"
            })
        elif libstore.source_path(name) == nil
            skipped.push({
                "module": name,
                "error": "source_missing",
                "message": "source missing"
            })
        else
            try
                var item = libstore.cache_source(name)
                if item != nil
                    items.push(libstore._cache_item_snapshot(item))
                else
                    skipped.push({
                        "module": name,
                        "error": nil,
                        "message": "cache unavailable"
                    })
                end
            except .. as e, m
                skipped.push({
                    "module": name,
                    "error": e,
                    "message": m
                })
            end
        end
    end
    return {
        "ok": skipped.size() == 0,
        "items": items,
        "skipped": skipped,
        "cached_count": items.size(),
        "skipped_count": skipped.size()
    }
end

libstore.cache_all_report = def()
    var items = []
    var skipped = []
    for name : libstore.modules()
        if libstore.exists(name)
            try
                var item = libstore.cache_source(name)
                if item != nil
                    items.push(libstore._cache_item_snapshot(item))
                else
                    skipped.push({
                        "module": name,
                        "error": nil,
                        "message": "cache unavailable"
                    })
                end
            except .. as e, m
                skipped.push({
                    "module": name,
                    "error": e,
                    "message": m
                })
            end
        end
    end
    return {
        "ok": skipped.size() == 0,
        "items": items,
        "skipped": skipped,
        "cached_count": items.size(),
        "skipped_count": skipped.size()
    }
end

libstore.cache_all = def()
    return libstore.cache_all_report()["items"]
end

libstore.cache_report = def()
    var items = []
    var names = libstore.cache.keys()
    var i = 0
    while i < names.size()
        var name = names[i]
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
        i += 1
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
