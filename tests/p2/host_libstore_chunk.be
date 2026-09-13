# Host-side regression for libstore's chunked PSRAM source cache.
#
# This runs under the desktop Berry binary with a fake p2 module so chunking can
# be tested without a P2 Edge board attached. It is not included by the on-target
# /tests/p2 smoke suite.

import introspect

var p2 = module("p2")
p2.mem = {}
p2.info = {
    "available": true,
    "bytes": 33554432,
    "access": "block",
    "max_transfer": 7,
    "heap": false,
    "reserved_pin_first": 40,
    "reserved_pin_last": 57
}
p2.raise_psram_info = false
p2.raise_status_info = false
p2.psram_info = def()
    if p2.raise_psram_info
        raise "value_error", "forced psram_info failure"
    end
    return p2.info
end
p2.heap_info = def()
    return {
        "main": 131072,
        "wrong_free_count": 0,
        "wrong_realloc_count": 0
    }
end
p2.status_info = def()
    if p2.raise_status_info
        raise "value_error", "forced status_info failure"
    end
    return {
        "profile": "host_fake",
        "board": "host_fake",
        "memory": p2.heap_info(),
        "psram": p2.psram_info()
    }
end
p2.psram_write = def(address, data)
    if p2.info.contains("block_base")
        assert(address >= p2.info["block_base"])
        assert(address + size(data) <= p2.info["block_base"] + p2.info["block_bytes"])
    end
    p2.mem[address] = data
    return {
        "ok": true,
        "size": size(data)
    }
end
p2.psram_read = def(address, n)
    return p2.mem[address]
end

introspect.setmodule("p2", p2)
var libstore = run_file("modules/libstore.be")
introspect.setmodule("libstore", libstore)
libstore.paths = ["modules"]
assert(libstore.module_name("MATH.BE") == "math")
assert(libstore.module_name("notes.txt") == nil)
assert(libstore.modules().size() >= 5)
var window = libstore.cache_reset()
assert(window["base"] == 32505856)
assert(libstore.status()["heap"] == "hub")
assert(libstore.status()["library_count"] >= 5)

var cached = libstore.cache_source("math")
assert(cached["chunk_count"] > 1)
assert(cached["address"] == 32505856)
assert(libstore.cached("math"))
assert(libstore.cached_source("math") == open("modules/math.be", "r").read())

var math = libstore.load("math")
assert(math.sqrt(81) == 9)
assert(math.abs(-42) == 42)

var report = libstore.cache_report()
assert(report["status"]["psram_cache_items"] == 1)
assert(report["items"][0]["chunks"] == cached["chunk_count"])

var all_cached = libstore.cache_all()
assert(all_cached.size() >= 5)
assert(libstore.status()["psram_cache_items"] >= 5)
assert(libstore.cached("binary_heap"))
assert(libstore.cached("wifi"))

p2.mem = {}
p2.info = {
    "available": true,
    "bytes": 33554432,
    "access": "xmm+block",
    "max_transfer": 5,
    "heap": true,
    "xmm_bytes": 16777216,
    "block_base": 16777216,
    "block_bytes": 16777216,
    "reserved_pin_first": 40,
    "reserved_pin_last": 57
}
window = libstore.cache_reset()
assert(window["block_base"] == 16777216)
assert(window["base"] >= window["block_base"])
assert(window["base"] == 32505856)
assert(libstore.strategy()["heap"] == "external")
assert(libstore.strategy()["object_heap"] == true)
assert(libstore.strategy()["psram_role"] == "xmm_heap_and_chunked_source_cache")
assert(libstore.status()["psram_block_base"] == 16777216)
assert(libstore.status()["psram_cache_free"] == libstore.status()["psram_cache_limit"])

cached = libstore.cache_source("math")
assert(cached["chunk_count"] > 1)
assert(cached["address"] >= 16777216)
assert(libstore.cached_source("math") == open("modules/math.be", "r").read())
all_cached = libstore.cache_all()
assert(all_cached.size() >= 5)
assert(libstore.status()["psram_cache_items"] >= 5)

p2.mem = {}
var p2mem = run_file("modules/p2mem.be")
var p2mem_caps = p2mem.capabilities()
assert(p2mem_caps["stats"])
assert(p2mem_caps["stats_result"])
assert(p2mem_caps["modules_result"])
assert(p2mem_caps["module_result"])
assert(p2mem_caps["cache_result"])
assert(p2mem_caps["gc_result"])
assert(p2mem_caps["memory_pressure_policy"])
assert(p2mem_caps["memory_pressure_result"])
assert(p2mem_caps["native_cache_result_wrappers"])
assert(p2mem_caps["native_cache_owner_helpers"])
assert(p2mem_caps["native_module_source_helpers"])
assert(p2mem_caps["invalid_module_name_diagnostics"])
assert(p2mem_caps["snapshot_diagnostics"])
assert(p2mem_caps["audit"])
assert(p2mem_caps["audit_policy"] == "metadata_and_name_validation_only_no_cache_mutation")
p2mem_caps["stats_result"] = false
assert(p2mem.capabilities()["stats_result"])
assert(type(p2mem.required_capability_keys) == "function")
var p2mem_required_caps = p2mem.required_capability_keys()
assert(p2mem_required_caps.find("stats_result") >= 0)
assert(p2mem_required_caps.find("memory_pressure_policy") >= 0)
assert(p2mem_required_caps.find("audit_policy") >= 0)
p2mem_required_caps.push("__host_p2mem_required_mutation_probe__")
assert(p2mem.required_capability_keys().find("__host_p2mem_required_mutation_probe__") == nil)
assert(p2mem.capability("stats_result"))
assert(p2mem.capability("missing") == nil)
assert(p2mem.capability(nil) == nil)
var p2mem_audit = p2mem.audit()
assert(p2mem_audit["ok"])
assert(p2mem_audit["problem_count"] == 0)
assert(p2mem_audit["problems"].size() == 0)
assert(p2mem_audit["missing_capability_keys"].size() == 0)
assert(p2mem_audit["audit_policy"] == "metadata_and_name_validation_only_no_cache_mutation")
assert(p2mem_audit["stats_result"])
assert(p2mem_audit["module_result"])
assert(p2mem_audit["cache_result"])
assert(p2mem_audit["gc_result"])
assert(p2mem_audit["memory_pressure_policy"])
assert(p2mem_audit["memory_pressure_result"])
assert(p2mem_audit["native_cache_result_wrappers"])
assert(p2mem_audit["invalid_module_name_diagnostics"])
assert(p2mem_audit["snapshot_diagnostics"])
p2mem_audit["problems"].push("__host_p2mem_audit_problem_mutation_probe__")
assert(p2mem.audit_problems().size() == 0)
assert(p2mem.audit_ok())
var stats = p2mem.stats()
assert(stats.contains("module_count"))
assert(stats["module_count"] >= 5)
var stats_result = p2mem.stats_result()
assert(stats_result["ok"])
assert(stats_result["stats"]["module_count"] == stats["module_count"])
assert(stats_result["error"] == nil)
assert(stats_result["message"] == nil)
var pressure = p2mem.memory_pressure_policy()
assert(pressure["model"] == "p2_memory_pressure_diagnostics")
assert(pressure["psram_available"])
assert(pressure["psram_heap"])
assert(pressure["psram_bytes"] == 33554432)
assert(pressure["psram_block_bytes"] == 16777216)
assert(pressure["source_cache_items"] >= 5)
assert(pressure["heap_high_water_tracking"] == false)
assert(pressure["heap_high_water_policy"] == "not_instrumented_yet")
assert(pressure["low_memory_churn_anchor"] == "tests/p2/smoke_import_churn.be")
assert(pressure["retry_policy"] == "stop_routine_priority_work_unless_native_high_water_or_allocator_changes")
assert(p2mem.memory_pressure_value("source_cache_items") >= 5)
assert(p2mem.memory_pressure_value("missing") == nil)
assert(p2mem.memory_pressure_value(nil) == nil)
var pressure_result = p2mem.memory_pressure_result()
assert(pressure_result["ok"])
assert(pressure_result["policy"]["model"] == pressure["model"])
assert(pressure_result["error"] == nil)
assert(pressure_result["message"] == nil)
p2.raise_status_info = true
var stats_error = p2mem.stats_result()
p2.raise_status_info = false
assert(!stats_error["ok"])
assert(stats_error["stats"] == nil)
assert(stats_error["error"] == "value_error")
assert(stats_error["message"] == "forced status_info failure")
stats["module_count"] = -1
stats["libstore"]["psram_cache_items"] = -1
stats["cache"]["psram_cache_items"] = -1
stats["strategy"]["psram_role"] = "caller_mutated"
var stats_fresh = p2mem.stats()
assert(stats_fresh["module_count"] >= 5)
assert(stats_fresh["libstore"]["psram_cache_items"] >= 5)
assert(stats_fresh["cache"]["psram_cache_items"] >= 5)
assert(stats_fresh["strategy"]["psram_role"] == "xmm_heap_and_chunked_source_cache")
var modules = p2mem.modules()
assert(modules.size() >= 5)
var modules_result = p2mem.modules_result()
assert(modules_result["ok"])
assert(modules_result["modules"].size() == modules.size())
assert(modules_result["error"] == nil)
assert(modules_result["message"] == nil)
var saw_math = false
for rec : modules
    if rec["module"] == "math"
        saw_math = true
        assert(rec["source_path"] == "modules/math.be")
        assert(rec.contains("compiled_path"))
        assert(rec.contains("compiled_manifest_path"))
        assert(rec.contains("compiled_manifest_exists"))
        assert(rec.contains("source_hash"))
        assert(rec.contains("compiled_hash"))
        assert(rec.contains("cache_hit_count"))
        assert(rec.contains("cache_miss_count"))
        assert(rec.contains("last_used"))
    end
end
assert(saw_math)
modules[0]["module"] = "caller_mutated"
modules[0]["cache_hit_count"] = -1
var modules_fresh = p2mem.modules()
assert(modules_fresh[0]["module"] != "caller_mutated")
assert(modules_fresh[0]["cache_hit_count"] >= 0)
var math_rec = p2mem.module("math")
assert(math_rec["module"] == "math")
assert(math_rec["source_path"] == "modules/math.be")
var math_result = p2mem.module_result("math")
assert(math_result["ok"])
assert(math_result["found"])
assert(math_result["module"]["module"] == "math")
math_rec["module"] = "caller_mutated"
math_rec["cache"]["name"] = "caller_mutated"
var math_fresh = p2mem.module("math")
assert(math_fresh["module"] == "math")
assert(math_fresh["cache"]["name"] == "math")
assert(p2mem.module("missing_module") == nil)
var missing_result = p2mem.module_result("missing_module")
assert(!missing_result["ok"])
assert(!missing_result["found"])
assert(missing_result["module"] == nil)
assert(missing_result["error"] == nil)
assert(p2mem.module("") == nil)
assert(p2mem.module(nil) == nil)
assert(p2mem.module("../escape_mod") == nil)
assert(p2mem.module("bad/cache_mod") == nil)
var invalid_result = p2mem.module_result("")
assert(!invalid_result["ok"])
assert(!invalid_result["found"])
assert(invalid_result["module"] == nil)
assert(invalid_result["error"] == "invalid_module_name")
assert(invalid_result["message"] == "module name must not be empty")
var nil_result = p2mem.module_result(nil)
assert(!nil_result["ok"])
assert(!nil_result["found"])
assert(nil_result["module"] == nil)
assert(nil_result["error"] == "invalid_module_name")
assert(nil_result["message"] == "module name must be a string")
var escape_result = p2mem.module_result("../escape_mod")
assert(!escape_result["ok"])
assert(!escape_result["found"])
assert(escape_result["module"] == nil)
assert(escape_result["error"] == "invalid_module_name")
assert(escape_result["message"] == "module name must not contain path separators or dot-dot segments")
var slash_result = p2mem.module_result("bad/cache_mod")
assert(!slash_result["ok"])
assert(!slash_result["found"])
assert(slash_result["module"] == nil)
assert(slash_result["error"] == "invalid_module_name")
assert(slash_result["message"] == "module name must not contain path separators or dot-dot segments")
var cache = p2mem.cache()
assert(size(cache["items"]) >= 0)
assert(cache["status"]["psram_cache_items"] >= 5)
assert(cache["items"][0]["chunk_count"] == cache["items"][0]["chunks"])
assert(cache["items"][0]["chunk_count"] >= 1)
var cache_result = p2mem.cache_result()
assert(cache_result["ok"])
assert(cache_result["cache"]["status"]["psram_cache_items"] == cache["status"]["psram_cache_items"])
assert(cache_result["error"] == nil)
assert(cache_result["message"] == nil)
cache["status"]["psram_cache_items"] = -1
cache["items"][0]["module"] = "caller_mutated"
cache["items"][0]["chunk_count"] = -1
var cache_fresh = p2mem.cache()
assert(cache_fresh["status"]["psram_cache_items"] >= 5)
assert(cache_fresh["items"][0]["module"] != "caller_mutated")
assert(cache_fresh["items"][0]["chunk_count"] >= 1)
assert(cache_fresh["items"][0]["chunk_count"] == cache_fresh["items"][0]["chunks"])
var gc_report = p2mem.gc()
assert(type(gc_report["before"]) == "int")
var gc_result = p2mem.gc_result()
assert(gc_result["ok"])
assert(type(gc_result["gc"]["before"]) == "int")
assert(type(gc_result["gc"]["after"]) == "int")
assert(type(gc_result["gc"]["freed"]) == "int")
assert(gc_result["error"] == nil)
assert(gc_result["message"] == nil)
var evicted = p2mem.evict()
assert(evicted["ok"])
assert(evicted["after"]["psram_cache_items"] == 0)
evicted["after"]["psram_cache_items"] = -1
var evicted_fresh = p2mem.evict()
assert(evicted_fresh["ok"])
assert(evicted_fresh["after"]["psram_cache_items"] == 0)

p2.raise_psram_info = true
var modules_error = p2mem.modules_result()
var module_error = p2mem.module_result("math")
var cache_error = p2mem.cache_result()
var evict_error = p2mem.evict()
p2.raise_psram_info = false
assert(!modules_error["ok"])
assert(modules_error["modules"] == nil)
assert(modules_error["error"] == "value_error")
assert(modules_error["message"] == "forced psram_info failure")
assert(!module_error["ok"])
assert(!module_error["found"])
assert(module_error["module"] == nil)
assert(module_error["error"] == "value_error")
assert(module_error["message"] == "forced psram_info failure")
assert(!cache_error["ok"])
assert(cache_error["cache"] == nil)
assert(cache_error["error"] == "value_error")
assert(cache_error["message"] == "forced psram_info failure")
assert(!evict_error["ok"])
assert(evict_error["error"] == "value_error")
assert(evict_error["message"] == "forced psram_info failure")
