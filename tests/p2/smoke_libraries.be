print("P2_SMOKE_BEGIN libraries")

import binary_heap
import p2

var data = [3, 1, 4, 1, 5]
binary_heap.sort(data, /a b -> a < b)
assert(data == [1, 1, 3, 4, 5])

import libstore

var psram = p2.psram_info()
var expected_policy = psram["available"] ? libstore.POLICY_SD_CACHE_PSRAM : libstore.POLICY_SD_LAZY
var status = libstore.status()
var policy = libstore.policy()
assert(status["lazy"] == true)
assert(status["source"] == "sd")
assert(status["heap"] == "hub")
assert(policy["name"] == expected_policy)
policy["name"] = "__libstore_policy_mutation_probe__"
assert(libstore.policy()["name"] == expected_policy)
assert(status["psram_cache"] == status["psram_available"])
assert(status["psram_cache_used"] == 0)
assert(status["psram_cache_free"] == status["psram_cache_limit"])
var status_snapshot = libstore.status()
status_snapshot["source"] = "__libstore_status_mutation_probe__"
status_snapshot["psram_cache_items"] = -1
var status_isolation = libstore.status()
assert(status_isolation["source"] == "sd")
assert(status_isolation["psram_cache_items"] == 0)
assert(status["psram_cache_items"] == 0)
assert(status["library_count"] >= 5)
assert(status["psram_max_transfer"] >= 0)
assert(libstore.strategy()["library_home"] == "sd")
assert(libstore.strategy()["object_heap"] == false)
assert(libstore.strategy()["direct_execute_from_psram"] == false)
status["lazy"] = false
status["psram_cache_items"] = 99
var status_again = libstore.status()
assert(status_again["lazy"] == true)
assert(status_again["psram_cache_items"] == 0)
var strategy_snapshot = libstore.strategy()
var strategy_path_count = strategy_snapshot["module_path"].size()
var strategy_first_path = strategy_snapshot["module_path"][0]
strategy_snapshot["module_path"].push("__libstore_strategy_path_mutation_probe__")
strategy_snapshot["module_path"][0] = "__libstore_strategy_path_replace_probe__"
strategy_snapshot["library_home"] = "hub"
strategy_snapshot["direct_execute_from_psram"] = true
var strategy_again = libstore.strategy()
assert(strategy_again["library_home"] == "sd")
assert(strategy_again["direct_execute_from_psram"] == false)
assert(strategy_again["module_path"].size() == strategy_path_count)
assert(strategy_again["module_path"][0] == strategy_first_path)
var expected_strategy_load = "lazy_source"
if psram["available"] {
    expected_strategy_load = "lazy_source_or_psram_cache"
}
assert(libstore.strategy()["load"] == expected_strategy_load)
var libstore_modules = libstore.modules()
var libstore_module_count = libstore_modules.size()
assert(libstore_module_count >= 4)
libstore_modules.push("__libstore_modules_mutation_probe__")
assert(libstore.modules().size() == libstore_module_count)
assert(libstore.module_name("MATH.BE") == "math")
assert(libstore.module_name("README.TXT") == nil)
assert(libstore.exists("binary_heap"))
assert(libstore.source_path("binary_heap") == "/modules/binary_heap.be")
assert(libstore.info("binary_heap")["exists"] == true)
assert(libstore.info("binary_heap")["source"] == "sd")
assert(libstore.info("binary_heap")["compiled_supported"] == false)
assert(libstore.info("binary_heap")["source_fallback"] == libstore.info("binary_heap")["compiled_exists"])
assert(libstore.info("binary_heap")["source_size"] > 0)
assert(type(libstore.info("binary_heap")["source_hash"]) == "int")
var binary_info = libstore.info("binary_heap")
var binary_info_source_size = binary_info["source_size"]
binary_info["source_size"] = -1
binary_info["path"] = "__libstore_info_mutation_probe__"
var binary_info_again = libstore.info("binary_heap")
assert(binary_info_again["source_size"] == binary_info_source_size)
assert(binary_info_again["path"] == "/modules/binary_heap.be")
var binary_stats = libstore.source_stats("binary_heap")
var binary_stats_size = binary_stats["size"]
binary_stats["size"] = -1
binary_stats["path"] = "__libstore_source_stats_mutation_probe__"
var binary_stats_again = libstore.source_stats("binary_heap")
assert(binary_stats_again["size"] == binary_stats_size)
assert(binary_stats_again["path"] == "/modules/binary_heap.be")
var binary_compiled_stats = libstore.compiled_stats("binary_heap")
var binary_compiled_stats_exists = binary_compiled_stats["exists"]
var binary_compiled_stats_size = binary_compiled_stats["size"]
binary_compiled_stats["exists"] = !binary_compiled_stats_exists
binary_compiled_stats["size"] = -1
var binary_compiled_stats_again = libstore.compiled_stats("binary_heap")
assert(binary_compiled_stats_again["exists"] == binary_compiled_stats_exists)
assert(binary_compiled_stats_again["size"] == binary_compiled_stats_size)
assert(type(libstore.info("binary_heap")["compiled_size"]) == "int")
assert(libstore.info("binary_heap")["compiled_fresh"] == false)
assert(libstore.info("binary_heap")["compiled_usable"] == false)
assert(type(libstore.info("binary_heap")["compiled_freshness_reason"]) == "string")
import p2mem

var mem_stats = p2mem.stats()
assert(type(mem_stats) == "map")
assert(type(mem_stats["heap"]) == "map")
assert(type(mem_stats["psram"]) == "map")
assert(type(mem_stats["libstore"]) == "map")
assert(mem_stats["module_count"] >= 5)
var mem_stats_module_count = mem_stats["module_count"]
mem_stats["module_count"] = -1
mem_stats["libstore"]["lazy"] = false
var mem_stats_again = p2mem.stats()
assert(mem_stats_again["module_count"] == mem_stats_module_count)
assert(mem_stats_again["libstore"]["lazy"] == true)

var mem_modules = p2mem.modules()
assert(type(mem_modules) == "list")
assert(mem_modules.size() >= 5)
var saw_math = false
for rec : mem_modules
    assert(type(rec) == "map")
    assert(rec.contains("module"))
    assert(rec.contains("source_path"))
    assert(rec.contains("compiled_path"))
    assert(rec.contains("compiled_exists"))
    assert(rec.contains("compiled_size"))
    assert(rec.contains("compiled_supported"))
    assert(rec.contains("compiled_fresh"))
    assert(rec.contains("compiled_usable"))
    assert(rec.contains("compiled_freshness_reason"))
    assert(rec.contains("selected_path"))
    assert(rec.contains("selected_kind"))
    assert(rec.contains("resolve_reason"))
    assert(rec.contains("source_fallback"))
    assert(rec.contains("storage_tier"))
    assert(rec.contains("source_size"))
    assert(rec.contains("source_hash"))
    assert(rec.contains("compiled_hash"))
    assert(rec.contains("hub_bytes_used"))
    assert(rec.contains("psram_bytes_used"))
    assert(rec.contains("cache_hit_count"))
    assert(rec.contains("cache_miss_count"))
    assert(rec.contains("pinned"))
    assert(rec.contains("last_used"))
    if rec["module"] == "math"
        saw_math = true
        assert(rec["source_path"] == "/modules/math.be")
        assert(rec["compiled_fresh"] == false)
        assert(rec["compiled_usable"] == false)
    end
end
assert(saw_math)
var first_mem_module = mem_modules[0]["module"]
mem_modules[0]["module"] = "__p2mem_mutated_module__"
mem_modules[0]["source_path"] = "__p2mem_mutated_path__"
var mem_modules_again = p2mem.modules()
assert(mem_modules_again[0]["module"] == first_mem_module)
assert(mem_modules_again[0]["module"] != mem_modules[0]["module"])
assert(mem_modules_again[0]["source_path"] != "__p2mem_mutated_path__")
var math_module = p2mem.module("math")
assert(math_module != nil)
var math_module_source_path = math_module["source_path"]
math_module["source_path"] = "__p2mem_module_mutated_path__"
assert(p2mem.module("math")["source_path"] == math_module_source_path)

var mem_cache = p2mem.cache()
assert(type(mem_cache) == "map")
assert(type(mem_cache["status"]) == "map")
assert(type(mem_cache["items"]) == "list")
var mem_cache_items = mem_cache["status"]["psram_cache_items"]
mem_cache["status"]["psram_cache_items"] = mem_cache_items + 99
var mem_cache_item_count = mem_cache["items"].size()
mem_cache["items"].push({"module": "__p2mem_cache_item_mutation_probe__"})
var mem_cache_again = p2mem.cache()
assert(mem_cache_again["status"]["psram_cache_items"] == mem_cache_items)
assert(mem_cache_again["items"].size() == mem_cache_item_count)
for item : mem_cache_again["items"]
    assert(item.contains("cache_hit_count"))
    assert(item.contains("cache_miss_count"))
    assert(item.contains("last_used"))
end

var gc_report = p2mem.gc()
assert(type(gc_report) == "map")
assert(type(gc_report["before"]) == "int")
assert(type(gc_report["after"]) == "int")
gc_report["before"] = -1
gc_report["after"] = -1
var gc_report_again = p2mem.gc()
assert(gc_report_again["before"] >= 0)
assert(gc_report_again["after"] >= 0)

var evict_report = p2mem.evict()
assert(type(evict_report) == "map")
assert(evict_report["after"]["psram_cache_items"] == 0)
var evict_after_items = evict_report["after"]["psram_cache_items"]
evict_report["after"]["psram_cache_items"] = 99
var evict_report_again = p2mem.evict()
assert(evict_report_again["after"]["psram_cache_items"] == evict_after_items)

print("P2_SMOKE_PASS libraries")
