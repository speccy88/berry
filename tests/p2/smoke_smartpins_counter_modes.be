print("P2_SMOKE_BEGIN smartpins_counter_modes")

var p2smart = run_file("/modules/p2smart.be")

assert(p2smart.smart.count_rises == 0x1c)
assert(p2smart.smart.count_highs == 0x1e)

def reset_pin(pin)
    p2smart.smart.clear(pin)
    p2smart.smart.wrpin(pin, 0)
    p2smart.smart.wxpin(pin, 0)
    p2smart.smart.wypin(pin, 0)
    p2smart.smart.akpin(pin)
    p2smart.pin.float(pin)
end

def reset_pair(a, b)
    reset_pin(a)
    reset_pin(b)
end

def counter_modes_loopback(out_pin, in_pin)
    reset_pair(out_pin, in_pin)
    var probe = p2smart.counter_variant_drive_modes_probe(out_pin, in_pin, nil, 1000, 100)
    print("P2_SMOKE_COUNTER_MODES " + str(out_pin) + "_" + str(in_pin) + " " + str(probe["ok"]) + " " + str(probe["ok_count"]) + " " + str(probe["failed_count"]))
    assert(probe["ok"])
    assert(probe["count"] == 1)
    assert(probe["ok_count"] == 1)
    assert(probe["failed_count"] == 0)
    assert(probe["modes"] == ["count_highs"])
    for item : probe["results"]
        assert(item["counter"]["delta"] > 0)
    end
    reset_pair(out_pin, in_pin)
end

for pair : p2smart.default_jumper_pairs()
    var a = pair[0]
    var b = pair[1]
    print("P2_SMOKE_PAIR " + str(a) + "_" + str(b))
    print("P2_SMOKE_CASE counter_modes_ab")
    counter_modes_loopback(a, b)
    print("P2_SMOKE_CASE counter_modes_ba")
    counter_modes_loopback(b, a)
end

for pair : p2smart.default_jumper_pairs()
    reset_pair(pair[0], pair[1])
end

print("P2_SMOKE_PASS smartpins_counter_modes")
