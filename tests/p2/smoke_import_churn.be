print("P2_SMOKE_BEGIN import_churn")

import introspect
import p2

import binary_heap
import configstore
import json
import libstore
import math
import p2compat
import p2ipc
import p2mem
import p2smart
import task
import wifi

var heap_ptr = introspect.toptr(binary_heap)
var configstore_ptr = introspect.toptr(configstore)
var json_ptr = introspect.toptr(json)
var libstore_ptr = introspect.toptr(libstore)
var math_ptr = introspect.toptr(math)
var p2compat_ptr = introspect.toptr(p2compat)
var p2ipc_ptr = introspect.toptr(p2ipc)
var p2mem_ptr = introspect.toptr(p2mem)
var p2smart_ptr = introspect.toptr(p2smart)
var task_ptr = introspect.toptr(task)
var wifi_ptr = introspect.toptr(wifi)
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
    var info = libstore.info(name)
    assert(info["low_memory_smoke"] == "/tests/p2/smoke_import_churn.be")
    assert(info["repeated_import_smoke"] == "/tests/p2/smoke_import_cache.be")
    assert(info["cache_smoke"] == "/tests/p2/smoke_import_cache.be")
    assert(info["sd_import_smoke"] == "/tests/p2/smoke_import_all_libs.be")
    if name == "wifi"
        assert(info["coverage_status"] == "hardware_deferred")
    else
        assert(info["coverage_status"] == "covered")
    end
    var stats = libstore.source_stats(name)
    assert(stats["exists"])
    assert(info["source_size"] == stats["size"])
    assert(info["source_hash"] == stats["hash"])
end
var before = p2.heap_info()
var baseline = before["main"]

var batch = []
var i = 0
while i < 96
    batch.push({
        "index": i,
        "text": "module-churn-" + str(i) + ":" + ("x" * (64 + (i % 7) * 8)),
        "values": [i, i + 1, i + 2]
    })
    i += 1
end

assert(size(batch) == 96)
assert(p2.heap_info()["main"] < baseline)

batch = nil
var gc_report = p2.gc()
assert(isinstance(gc_report, map))
assert(gc_report["freed"] >= 0)

import binary_heap
import configstore
import json
import libstore
import math
import p2compat
import p2ipc
import p2mem
import p2smart
import task
import wifi

assert(introspect.toptr(binary_heap) == heap_ptr)
assert(introspect.toptr(configstore) == configstore_ptr)
assert(introspect.toptr(json) == json_ptr)
assert(introspect.toptr(libstore) == libstore_ptr)
assert(introspect.toptr(math) == math_ptr)
assert(introspect.toptr(p2compat) == p2compat_ptr)
assert(introspect.toptr(p2ipc) == p2ipc_ptr)
assert(introspect.toptr(p2mem) == p2mem_ptr)
assert(introspect.toptr(p2smart) == p2smart_ptr)
assert(introspect.toptr(task) == task_ptr)
assert(introspect.toptr(wifi) == wifi_ptr)

assert(math.sqrt(81) == 9)
assert(json.load('{"ok":true}')["ok"])
assert(configstore.path("demo") == "/berry/config/demo.json")
assert(libstore.info("math")["exists"])
assert(p2compat.status("environment") == p2compat.UNSUPPORTED)
assert(type(p2ipc.Mutex) == "class")
assert(isinstance(p2mem.stats(), map))
assert(type(p2smart.GPIOInput) == "class")
assert(type(p2smart.GPIOOutput) == "class")
assert(type(p2smart.PWM) == "class")
assert(type(p2smart.Quadrature) == "class")
assert(type(p2smart.Repository) == "class")
assert(type(p2smart.Transition) == "class")
assert(type(p2smart.AsyncSerialPair) == "class")
assert(type(p2smart.SyncSerialPair) == "class")
assert(type(p2smart.ADC) == "class")
assert(type(p2smart.DAC) == "class")
var task_max = task.info()["max_tasks"]
assert(task_max == 16 || task_max == 32)
assert(task.capability("max_tasks") == task_max)
assert(wifi.STATUS[255] == "no_shield")

var data = [5, 2, 8, 1]
binary_heap.sort(data, /a b -> a < b)
assert(data == [1, 2, 5, 8])

var after = p2.heap_info()
assert(after["main"] > 0)
assert(after["main_crosses_block_window"] == false || !after.contains("main_crosses_block_window"))

print("P2_SMOKE_PASS import_churn")
