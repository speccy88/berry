print("P2_SMOKE_BEGIN import_churn")

import p2
import libstore

print("P2_SMOKE_STEP import_churn import binary_heap")
import binary_heap
print("P2_SMOKE_STEP import_churn import configstore")
import configstore
print("P2_SMOKE_STEP import_churn import json")
import json
print("P2_SMOKE_STEP import_churn import math")
import math
print("P2_SMOKE_STEP import_churn import p2compat")
import p2compat
print("P2_SMOKE_STEP import_churn import p2ipc")
import p2ipc
print("P2_SMOKE_STEP import_churn import p2mem")
import p2mem
print("P2_SMOKE_STEP import_churn import p2smart")
import p2smart
print("P2_SMOKE_STEP import_churn import task")
import task
print("P2_SMOKE_STEP import_churn import wifi")
import wifi

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
    print("P2_SMOKE_STEP import_churn metadata", name)
    var coverage = libstore.coverage(name)
    assert(coverage["low_memory_smoke"] == "/tests/p2/smoke_import_churn.be")
    assert(coverage["repeated_import_smoke"] == "/tests/p2/smoke_import_cache.be")
    assert(coverage["cache_smoke"] == "/tests/p2/smoke_import_cache.be")
    assert(coverage["sd_import_smoke"] == "/tests/p2/smoke_import_all_libs.be")
    if name == "wifi"
        assert(coverage["status"] == "hardware_deferred")
    else
        assert(coverage["status"] == "covered")
    end
    assert(libstore.source_path(name) != nil)
end
print("P2_SMOKE_STEP import_churn metadata_done")

var before = p2.heap_info()
var baseline = before["main"]

var batch = []
var i = 0
print("P2_SMOKE_STEP import_churn allocate")
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
var gc_report_type = type(gc_report)
assert(gc_report_type == "map" || gc_report_type == "instance")
assert(gc_report["freed"] >= 0)
print("P2_SMOKE_STEP import_churn gc", gc_report)

print("P2_SMOKE_STEP import_churn repeat binary_heap")
import binary_heap
print("P2_SMOKE_STEP import_churn repeat configstore")
import configstore
print("P2_SMOKE_STEP import_churn repeat json")
import json
print("P2_SMOKE_STEP import_churn repeat libstore")
import libstore
print("P2_SMOKE_STEP import_churn repeat math")
import math
print("P2_SMOKE_STEP import_churn repeat p2compat")
import p2compat
print("P2_SMOKE_STEP import_churn repeat p2ipc")
import p2ipc
print("P2_SMOKE_STEP import_churn repeat p2mem")
import p2mem
print("P2_SMOKE_STEP import_churn repeat p2smart")
import p2smart
print("P2_SMOKE_STEP import_churn repeat task")
import task
print("P2_SMOKE_STEP import_churn repeat wifi")
import wifi

assert(math.sqrt(81) == 9)
assert(json.load('{"ok":true}')["ok"])
assert(configstore.path("demo") == "/berry/config/demo.json")
assert(libstore.info("math")["exists"])
assert(p2compat.status("environment") == p2compat.UNSUPPORTED)
assert(type(p2ipc.mutex.Mutex) == "class")
var p2mem_stats_type = type(p2mem.stats())
assert(p2mem_stats_type == "map" || p2mem_stats_type == "instance")
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
