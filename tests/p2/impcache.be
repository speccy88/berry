print("P2_SMOKE_BEGIN import_cache")

import libstore

def check(cond, label)
    if !cond
        print("P2_SMOKE_FAIL import_cache", label)
    end
    assert(cond)
end

var expected = [
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

for name : expected
    print("P2_SMOKE_STEP import_cache source", name)
    var path = libstore.source_path(name)
    assert(path != nil)
end

for name : expected
    print("P2_SMOKE_STEP import_cache metadata", name)
    var coverage = libstore.coverage(name)
    assert(coverage["repeated_import_smoke"] == "/tests/p2/smoke_import_cache.be")
    assert(coverage["cache_smoke"] == "/tests/p2/smoke_import_cache.be")
    assert(coverage["sd_import_smoke"] == "/tests/p2/smoke_import_all_libs.be")
    assert(coverage["low_memory_smoke"] == "/tests/p2/smoke_import_churn.be")
    if name == "wifi"
        assert(coverage["status"] == "hardware_deferred")
    else
        assert(coverage["status"] == "covered")
    end
end

var heap_info = libstore.info("binary_heap")
var heap_stats = libstore.source_stats("binary_heap")
assert(heap_stats["exists"])
assert(heap_stats["size"] > 0)
assert(type(heap_stats["hash"]) == "int")
assert(heap_info["source_size"] == heap_stats["size"])
assert(heap_info["source_hash"] == heap_stats["hash"])

var math_info = libstore.info("math")
var math_stats = libstore.source_stats("math")
assert(math_stats["exists"])
assert(math_stats["size"] > 0)
assert(type(math_stats["hash"]) == "int")
assert(math_info["source_size"] == math_stats["size"])
assert(math_info["source_hash"] == math_stats["hash"])

if libstore.source_path("libstore") != nil
    var info = libstore.info("libstore")
    var stats = libstore.source_stats("libstore")
    assert(stats["exists"])
    assert(info["source_size"] == stats["size"])
    assert(info["source_hash"] == stats["hash"])
end
print("P2_SMOKE_STEP import_cache metadata_done")
import p2
print("P2_SMOKE_STEP import_cache gc", p2.gc())

import libstore
assert(libstore.info("libstore")["exists"])
print("P2_SMOKE_STEP import_cache libstore_repeat")

import math
assert(math.sqrt(81) == 9)
import math
assert(math.sqrt(81) == 9)
print("P2_SMOKE_STEP import_cache math_repeat")

import binary_heap
var data = [9, 4, 7, 1]
binary_heap.sort(data, /a b -> a < b)
assert(data == [1, 4, 7, 9])
import binary_heap
data = [3, 2, 1]
binary_heap.sort(data, /a b -> a < b)
assert(data == [1, 2, 3])
print("P2_SMOKE_STEP import_cache binary_heap_repeat")

import configstore
assert(configstore.path("demo") == "/berry/config/demo.json")
import configstore
assert(configstore.path("demo") == "/berry/config/demo.json")
print("P2_SMOKE_STEP import_cache configstore_repeat")

import json
assert(json.load('{"ok":true}')["ok"])
import json
assert(json.load('{"ok":true}')["ok"])
print("P2_SMOKE_STEP import_cache json_repeat")

import p2compat
assert(p2compat.status("environment") == p2compat.UNSUPPORTED)
import p2compat
assert(p2compat.status("environment") == p2compat.UNSUPPORTED)
print("P2_SMOKE_STEP import_cache p2compat_repeat")

import p2ipc
assert(type(p2ipc.mutex.Mutex) == "class")
import p2ipc
assert(type(p2ipc.mutex.Mutex) == "class")
print("P2_SMOKE_STEP import_cache p2ipc_repeat")

import p2mem
assert(isinstance(p2mem.stats(), map))
import p2mem
assert(isinstance(p2mem.stats(), map))
print("P2_SMOKE_STEP import_cache p2mem_repeat")

import p2smart
assert(type(p2smart.GPIOInput) == "class")
assert(type(p2smart.GPIOOutput) == "class")
assert(type(p2smart.PWM) == "class")
assert(type(p2smart.Quadrature) == "class")
assert(type(p2smart.Repository) == "class")
assert(type(p2smart.Pulse) == "class")
assert(type(p2smart.AsyncSerialPair) == "class")
assert(type(p2smart.SyncSerialPair) == "class")
assert(type(p2smart.ADC) == "class")
assert(type(p2smart.DAC) == "class")
import p2smart
assert(type(p2smart.GPIOInput) == "class")
print("P2_SMOKE_STEP import_cache p2smart_repeat")

import task
var task_max = task.info()["max_tasks"]
assert(task_max == 16 || task_max == 32)
assert(task.capability("max_tasks") == task_max)
import task
assert(task.info()["max_tasks"] == task_max)
print("P2_SMOKE_STEP import_cache task_repeat")

import wifi
assert(wifi.STATUS[255] == "no_shield")
import wifi
assert(wifi.STATUS[255] == "no_shield")
print("P2_SMOKE_STEP import_cache wifi_repeat")

var policy = libstore.policy()
if policy["uses_psram_cache"] && policy["psram_cache_available"]
    print("P2_SMOKE_STEP import_cache cache_begin")
    print("P2_SMOKE_STEP import_cache cache_gc", p2.gc())
    libstore.cache_reset()
    var cache_expected = ["binary_heap"]
    for name : cache_expected
        print("P2_SMOKE_STEP import_cache cache", name)
        check(libstore.info(name)["cache_hit_count"] == 0, name + "_hit_count_before")
        check(libstore.info(name)["cache_miss_count"] == 0, name + "_miss_count_before")
        var stats = libstore.source_stats(name)
        var source_path = stats["path"]
        var cached = libstore.cache_source(name)
        check(cached != nil, name + "_cached_not_nil")
        check(cached["name"] == name, name + "_cached_name")
        check(cached["path"] == source_path, name + "_cached_path")
        check(cached["source_hash"] == stats["hash"], name + "_cached_hash")
        check(cached["size"] == stats["size"], name + "_cached_size")
        check(libstore.cached(name), name + "_cached_flag")
        check(libstore.info(name)["cache_miss_count"] == 1, name + "_miss_count_after_put")
        check(libstore.info(name)["cache_hit_count"] == 0, name + "_hit_count_after_put")
        var cached_source = libstore.cached_source(name)
        if cached_source != nil
            check(size(cached_source) == cached["size"], name + "_cached_source_size")
            check(libstore.hash_text(cached_source) == stats["hash"], name + "_cached_source_hash")
            check(libstore.info(name)["cache_hit_count"] >= 1, name + "_hit_count_after_read")
        else
            print("P2_SMOKE_STEP import_cache cache_rejected", name)
            check(!libstore.cached(name), name + "_cache_rejected_evicted")
        end
    end
    print("P2_SMOKE_STEP import_cache cache_done")
    var report = libstore.cache_report()
    for item : report["items"]
        assert(item["cache_hit_count"] >= 1)
        assert(item["cache_miss_count"] == 1)
    end
    print("P2_SMOKE_STEP import_cache cache_cleanup")
    libstore.cache_reset()
    print("P2_SMOKE_STEP import_cache cleanup_gc", p2.gc())
end

print("P2_SMOKE_PASS import_cache")
