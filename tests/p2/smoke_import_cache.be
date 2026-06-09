print("P2_SMOKE_BEGIN import_cache")

import introspect
import libstore

var expected = [
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

for name : expected
    assert(libstore.exists(name))
    assert(libstore.source_path(name) != nil)
    var info = libstore.info(name)
    assert(info["repeated_import_smoke"] == "/tests/p2/smoke_import_cache.be")
    assert(info["cache_smoke"] == "/tests/p2/smoke_import_cache.be")
    assert(info["sd_import_smoke"] == "/tests/p2/smoke_import_all_libs.be")
    assert(info["low_memory_smoke"] == "/tests/p2/smoke_import_churn.be")
    if name == "wifi"
        assert(info["coverage_status"] == "hardware_deferred")
    else
        assert(info["coverage_status"] == "covered")
    end
    var stats = libstore.source_stats(name)
    assert(stats["exists"])
    assert(stats["size"] > 0)
    assert(type(stats["hash"]) == "int")
    assert(info["source_size"] == stats["size"])
    assert(info["source_hash"] == stats["hash"])
    assert(stats["hash"] == libstore.hash_text(open(stats["path"], "r").read()))
end

var math_stats = libstore.source_stats("math")
assert(math_stats["exists"])
assert(math_stats["size"] > 0)
assert(type(math_stats["hash"]) == "int")
assert(math_stats["hash"] == libstore.hash_text(open(math_stats["path"], "r").read()))

var libstore_ptr_1 = introspect.toptr(libstore)
import libstore
var libstore_ptr_2 = introspect.toptr(libstore)
assert(libstore_ptr_1 == libstore_ptr_2)

import math
var math_ptr_1 = introspect.toptr(math)
assert(math.sqrt(81) == 9)
import math
var math_ptr_2 = introspect.toptr(math)
assert(math_ptr_1 == math_ptr_2)

import binary_heap
var heap_ptr_1 = introspect.toptr(binary_heap)
var data = [9, 4, 7, 1]
binary_heap.sort(data, /a b -> a < b)
assert(data == [1, 4, 7, 9])
import binary_heap
var heap_ptr_2 = introspect.toptr(binary_heap)
assert(heap_ptr_1 == heap_ptr_2)

import configstore
var configstore_ptr_1 = introspect.toptr(configstore)
assert(configstore.path("demo") == "/berry/config/demo.json")
import configstore
var configstore_ptr_2 = introspect.toptr(configstore)
assert(configstore_ptr_1 == configstore_ptr_2)

import json
var json_ptr_1 = introspect.toptr(json)
assert(json.load('{"ok":true}')["ok"])
import json
var json_ptr_2 = introspect.toptr(json)
assert(json_ptr_1 == json_ptr_2)

import p2compat
var p2compat_ptr_1 = introspect.toptr(p2compat)
assert(p2compat.status("environment") == p2compat.UNSUPPORTED)
import p2compat
var p2compat_ptr_2 = introspect.toptr(p2compat)
assert(p2compat_ptr_1 == p2compat_ptr_2)

import p2ipc
var p2ipc_ptr_1 = introspect.toptr(p2ipc)
assert(type(p2ipc.Mutex) == "class")
import p2ipc
var p2ipc_ptr_2 = introspect.toptr(p2ipc)
assert(p2ipc_ptr_1 == p2ipc_ptr_2)

import p2mem
var p2mem_ptr_1 = introspect.toptr(p2mem)
assert(type(p2mem.stats()) == "map")
import p2mem
var p2mem_ptr_2 = introspect.toptr(p2mem)
assert(p2mem_ptr_1 == p2mem_ptr_2)


import task
var task_ptr_1 = introspect.toptr(task)
assert(task.info()["max_tasks"] == 16)
import task
var task_ptr_2 = introspect.toptr(task)
assert(task_ptr_1 == task_ptr_2)

import wifi
var wifi_ptr_1 = introspect.toptr(wifi)
assert(wifi.STATUS[255] == "no_shield")
import wifi
var wifi_ptr_2 = introspect.toptr(wifi)
assert(wifi_ptr_1 == wifi_ptr_2)

var policy = libstore.policy()
if policy["uses_psram_cache"] && policy["psram_cache_available"]
    libstore.cache_reset()
    for name : expected
        assert(libstore.info(name)["cache_hit_count"] == 0)
        assert(libstore.info(name)["cache_miss_count"] == 0)
        var cached = libstore.cache_source(name)
        var stats = libstore.source_stats(name)
        assert(cached != nil)
        assert(cached["name"] == name)
        assert(cached["path"] == libstore.source_path(name))
        assert(cached["source_hash"] == stats["hash"])
        assert(cached["size"] == stats["size"])
        assert(cached["size"] == size(open(cached["path"], "r").read()))
        assert(libstore.cached(name))
        assert(libstore.info(name)["cache_miss_count"] == 1)
        assert(libstore.info(name)["cache_hit_count"] == 0)
        assert(size(libstore.cached_source(name)) == cached["size"])
        assert(libstore.info(name)["cache_hit_count"] >= 1)
    end
    var report = libstore.cache_report()
    assert(size(report["items"]) >= size(expected))
    for item : report["items"]
        assert(item["cache_hit_count"] >= 1)
        assert(item["cache_miss_count"] == 1)
    end
end

print("P2_SMOKE_PASS import_cache")
