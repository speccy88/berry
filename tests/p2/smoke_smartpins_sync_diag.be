print("P2_SMOKE_BEGIN smartpins_sync_diag")

import p2smart

var policy = p2smart.sync_serial_receive_policy()
assert(policy["ok"])
assert(!policy["supported"])
assert(policy["status"] == "unverified")
assert(policy["diagnostic_status"] == "diagnostic")
assert(policy["bounded_clocked_probe"])
assert(policy["unclocked_constant_raw_observed"])
assert(!policy["clocked_ready_observed"])
assert(!policy["matched_receive_words"])
assert(policy["default_clocked_jumper_groups"] == [[0, 1, 2, 3], [4, 5, 6, 7]])

def check_result(result)
    assert(type(result["ready"]) == "bool")
    assert(type(result["event"]) == "int")
    if result["ready"]
        assert(result["ok"])
        assert(type(result["raw"]) == "int")
        assert(type(result["value"]) == "int")
        assert(result["error"] == nil)
    else
        assert(!result["ok"])
        assert(result["raw"] == nil)
        assert(result["value"] == nil)
        assert(result["error"] == "not_ready")
    end
end

def check_group_result(result)
    assert(type(result["ok"]) == "bool")
    assert(type(result["data_tx_pin"]) == "int")
    assert(type(result["data_rx_pin"]) == "int")
    assert(type(result["clock_tx_pin"]) == "int")
    assert(type(result["clock_rx_pin"]) == "int")
    assert(type(result["ready_count"]) == "int")
    assert(type(result["matched_count"]) == "int")
    assert(type(result["results"]) == "list")
    for item : result["results"]
        check_result(item)
        assert(type(item["sent"]) == "int")
        assert(type(item["matched"]) == "bool")
        assert(item["clocked"])
    end
end

def reset_pin(pin)
    p2smart.smart.clear(pin)
    p2smart.smart.wrpin(pin, 0)
    p2smart.smart.wxpin(pin, 0)
    p2smart.smart.wypin(pin, 0)
    p2smart.smart.akpin(pin)
    p2smart.pin.float(pin)
end

reset_pin(0)
reset_pin(1)
reset_pin(2)
reset_pin(3)
reset_pin(4)
reset_pin(5)
reset_pin(6)
reset_pin(7)

var sync = p2smart.sync_serial_pair(0, 1, 115200, 8, nil, nil)
sync.start()
check_result(sync.read_result())
sync.ack()
sync.clear()
reset_pin(0)
reset_pin(1)

var groups = p2smart.default_clocked_jumper_groups()
assert(groups == [[0, 1, 2, 3], [4, 5, 6, 7]])
var single = p2smart.sync_serial_clocked_probe(0, 1, 2, 3, [0x12], 1000, 100000, 8)
check_group_result(single)
assert(single["count"] == 1)
assert(single["values"] == [0x12])
assert(single["ready_count"] >= 0)
assert(single["matched_count"] >= 0)

for group : groups
    var variants = p2smart.sync_serial_clocked_variants(group[0], group[1], group[2], group[3])
    assert(variants.size() == 4)
    assert(variants[0]["name"] == "normal_clock")
    assert(variants[1]["name"] == "inverted_rx_clock")
    assert(variants[2]["name"] == "inverted_clock_output")
    assert(variants[3]["name"] == "inverted_output_and_rx_clock")
    for item : variants
        assert(type(item["tx_mode"]) == "int")
        assert(type(item["rx_mode"]) == "int")
        assert(type(item["clock_mode"]) == "int")
    end
end

reset_pin(0)
reset_pin(1)
reset_pin(2)
reset_pin(3)
reset_pin(4)
reset_pin(5)
reset_pin(6)
reset_pin(7)

print("P2_SMOKE_PASS smartpins_sync_diag")
