print("P2_SMOKE_BEGIN import_all_libs")

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
    assert(info["exists"])
    assert(info["selected_kind"] == "source")
    assert(info["sd_import_smoke"] == "/tests/p2/smoke_import_all_libs.be")
    assert(info["metadata_smoke"] == "/tests/p2/smoke_module_inventory.be")
    var stats = libstore.source_stats(name)
    assert(stats["exists"])
    assert(info["source_size"] == stats["size"])
    assert(info["source_hash"] == stats["hash"])
    assert(type(info["coverage_status"]) == "string")
    if name == "wifi"
        assert(info["coverage_status"] == "hardware_deferred")
        assert(info["behavior_smoke"] == nil)
    else
        assert(info["coverage_status"] == "covered")
        assert(type(info["behavior_smoke"]) == "string")
    end
end

import binary_heap
assert(type(binary_heap) == "module")
var data = [4, 1, 3]
binary_heap.sort(data, /a b -> a < b)
assert(data == [1, 3, 4])

import configstore
assert(type(configstore) == "module")
assert(configstore.path("demo") == "/berry/config/demo.json")

import math
assert(type(math) == "module")
assert(math.sqrt(49) == 7)

import p2compat
assert(type(p2compat) == "module")
assert(p2compat.status("environment") == p2compat.UNSUPPORTED)

import p2ipc
assert(type(p2ipc) == "module")
assert(type(p2ipc.Mutex) == "class")

import p2mem
assert(type(p2mem) == "module")
assert(type(p2mem.stats()) == "map")


import task
assert(type(task) == "module")
assert(task.info()["max_tasks"] == 16)

import wifi
assert(type(wifi) == "module")
assert(wifi.STATUS[255] == "no_shield")

print("P2_SMOKE_PASS import_all_libs")
