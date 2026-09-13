# Host-only collection identity regression. No native P2 module or hardware.
import introspect

def expect_error(fn, kind, message)
    var caught = false
    try
        fn()
    except .. as e, m
        caught = true
        assert(e == kind)
        assert(m == message)
    end
    assert(caught)
end

def expect_empty_map(value)
    assert(isinstance(value, map))
    assert(value.size() == 0)
end

# Shadow names only in this scope; neither class derives from a collection.
def named_noncollections()
    class list
        def size() raise "assert_failed", "not a collection" end
        def item(key) raise "assert_failed", "not a collection" end
    end
    class map
        def contains(key) raise "assert_failed", "not a collection" end
        def item(key) raise "assert_failed", "not a collection" end
    end
    return [list(), map()]
end

class ListSub : list end
class MapSub : map end
class Payload end

var impostors = named_noncollections()
assert(classname(impostors[0]) == "list")
assert(classname(impostors[1]) == "map")
var noncollections = [nil, false, 42, "list", Payload(), impostors[0], impostors[1], list, map]
for value : noncollections
    assert(!isinstance(value, list))
    assert(!isinstance(value, map))
end

# Explicit cache registration is required by standard Berry import lookup.
var p2 = module("p2")
var status = {}
var gc_report = {}
var polar = {}
p2.status_info = def() return status end
p2.heap_info = def() return {"used": 7} end
p2.gc = def() return gc_report end
p2.polxy = def(r, t) return polar end
p2.smart = module("host.smart")
p2.pin = module("host.pin")
p2.clock = module("host.clock")
introspect.setmodule("p2", p2)
var libstore = run_file("modules/libstore.be")
introspect.setmodule("libstore", libstore)
var p2mem = run_file("modules/p2mem.be")
var p2compat = run_file("modules/p2compat.be")
var p2smart = run_file("modules/p2smart.be")
var p2ipc = run_file("modules/p2ipc.be")

# Real collections and derived collections have value kind instance.
for value : [[], ListSub()]
    assert(type(value) == "instance")
    assert(isinstance(value, list))
    assert(!isinstance(value, map))
    value.push("math")
    assert(p2mem._native_module_names_error(value) == nil)
    value.push(42)
    assert(p2mem._native_module_names_invalid(value)["requested"] == 2)
end
for value : [{}, MapSub()]
    assert(type(value) == "instance")
    assert(isinstance(value, map))
    assert(!isinstance(value, list))
    value["answer"] = 42
    assert(p2mem._map_value(value, "answer", -1) == 42)
    assert(p2compat._heap_value(value, "answer", -1) == 42)
    assert(p2mem._map_value(value, "missing", -1) == -1)
    status = {"build": value, "runtime": value}
    assert(p2compat.build() == value)
    assert(p2compat.runtime() == value)
    assert(libstore.build_features() == value)
    var outer = MapSub()
    outer["build"] = value
    outer["runtime"] = value
    status = outer
    assert(p2compat.build() == value)
    assert(p2compat.runtime() == value)
    assert(libstore.build_features() == value)
    assert(p2mem._gc_collect()["reason"] == "p2_gc_collect_deferred")
    status = {}
    value["before"] = 9
    value["after"] = 7
    value["freed"] = 2
    gc_report = value
    assert(p2mem._gc_collect()["freed"] == 2)
    assert(p2mem._gc_collect()["collected"])
    polar = value
    var math = run_file("modules/math.be")
    assert(math.accel_info()["cordic"])
end

# Maps are not lists, lists are not maps, and names do not grant either API.
for value : noncollections + [[], {}]
    if !isinstance(value, map)
        assert(p2mem._map_value(value, "answer", -1) == -1)
        assert(p2compat._heap_value(value, "answer", -1) == -1)
        status = value
        expect_empty_map(p2compat.build())
        expect_empty_map(p2compat.runtime())
        expect_empty_map(libstore.build_features())
        status = {"build": value, "runtime": value}
        expect_empty_map(p2compat.build())
        expect_empty_map(p2compat.runtime())
        expect_empty_map(libstore.build_features())
        status = {}
        gc_report = value
        assert(p2mem._gc_collect()["reason"] == "gc_report_unavailable")
        polar = value
        var math = run_file("modules/math.be")
        assert(!math.accel_info()["cordic"])
    end
    if !isinstance(value, list)
        var invalid = p2mem._native_module_names_invalid(value)
        assert(!invalid["ok"])
        assert(invalid["requested"] == 0)
        assert(invalid["message"] == "module names must be a list")
    end
end

# Policy getters copy collection values, not arbitrary instance payloads.
var policy_list = ListSub()
policy_list.push("test")
var policy = {"items": policy_list, "custom": impostors[0], "scalar": 42}
p2compat.board_profile_policy = def() return policy end
p2compat.child_vm_transfer_policy = def() return policy end
p2compat.child_vm_partition_policy = def() return policy end
for getter : [p2compat.board_profile_value, p2compat.child_vm_policy, p2compat.child_vm_partition_value]
    var copied = getter("items")
    assert(isinstance(copied, list))
    assert(copied == ["test"])
    copied.push("changed")
    assert(policy_list == ["test"])
    assert(getter("custom") == impostors[0])
    assert(getter("scalar") == 42)
end

# In-VM IPC intentionally accepts arbitrary user objects without copying.
for value : [Payload(), impostors[0], impostors[1], [], {}]
    var payload = p2ipc.payload_result(value)
    assert(payload["value"] == value)
    assert(payload["payload_type"] == "instance")
    assert(payload["current_vm_reference"])
    assert(!payload["serialized"])
    assert(!payload["ownership_transfer"])
end

# Only the leaf probe is a host seam; production aggregate guards still run.
var failed_checks = ListSub()
failed_checks.push("host-only-check")
p2smart.jumper_pair_probe = def(a, b)
    return {"ok": false, "ok_count": 0, "failed_count": 1, "failed_checks": failed_checks}
end
var pair = ListSub()
pair.push(0)
pair.push(1)
var pairs = ListSub()
pairs.push(pair)
var aggregate = p2smart.jumper_pairs_probe(pairs)
assert(isinstance(aggregate, map))
assert(aggregate["pairs"] == [[0, 1]])
assert(aggregate["failures"][0]["failed_checks"] == ["host-only-check"])
assert(p2smart.jumper_pairs_bidirectional_probe(pairs)["direction_count"] == 2)
failed_checks = impostors[0]
assert(p2smart.jumper_pairs_probe([[0, 1]])["failures"][0]["failed_checks"] == [])

for value : [42, "list", {}, Payload(), impostors[0], impostors[1]]
    expect_error(def() p2smart.gpio_loopback_probe(0, 1, value, 0) end,
        "type_error", "values must be a list")
    expect_error(def() p2smart.counter_variant_drive_modes_probe(0, 1, value) end,
        "type_error", "modes must be a list")
    for probe : [p2smart.jumper_pairs_probe, p2smart.jumper_pairs_bidirectional_probe]
        expect_error(def() probe(value) end, "type_error", "pairs must be a list")
        expect_error(def() probe([value]) end, "value_error", "each pair must contain exactly two pins")
    end
    for probe : [p2smart.async_serial_probe, p2smart.async_serial_burst_probe, p2smart.sync_serial_probe]
        expect_error(def() probe(0, 1, value) end, "type_error", "values must be a list")
    end
    for probe : [p2smart.sync_serial_clocked_jumper_probes, p2smart.sync_serial_clocked_jumper_variant_probes]
        expect_error(def() probe(value, [0]) end, "type_error", "groups must be a list")
        expect_error(def() probe([value], [0]) end, "value_error", "each sync serial group must contain four pins")
    end
    expect_error(def() p2smart.sync_serial_clocked_jumper_variant_probes([[0, 1, 2, 3]], value) end,
        "type_error", "values must be a list")
end
print("P2_HOST_PASS collection_types (host-only)")
