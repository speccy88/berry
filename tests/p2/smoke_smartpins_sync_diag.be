print("P2_SMOKE_BEGIN smartpins_sync_diag")

import p2

var smart = p2.smart
var pin = p2.pin

var STATUS_UNVERIFIED = "unverified"
var STATUS_VERIFIED = "verified"
var POLICY = "verified_clocked_jumper_receive"
var GROUPS = [[0, 1, 2, 3], [4, 5, 6, 7]]
var VARIANT_NAMES = ["normal_clock", "inverted_rx_clock", "inverted_clock_output", "inverted_output_and_rx_clock"]

def serial_x(baud, bits)
    assert(baud > 0)
    return (bits - 1) | 0x20
end

def pulse_x(high_ticks, low_ticks)
    return high_ticks * 65536 + high_ticks + low_ticks
end

def relative_b_mode(pin_a, pin_b)
    if pin_b == pin_a + 1
        return smart.plus1_b
    end
    if pin_b == pin_a + 2
        return smart.plus2_b
    end
    if pin_b == pin_a + 3
        return smart.plus3_b
    end
    if pin_b == pin_a - 1
        return smart.minus1_b
    end
    if pin_b == pin_a - 2
        return smart.minus2_b
    end
    if pin_b == pin_a - 3
        return smart.minus3_b
    end
    assert(false)
end

def reset_pin(no)
    smart.clear(no)
    smart.wrpin(no, 0)
    smart.wxpin(no, 0)
    smart.wypin(no, 0)
    smart.akpin(no)
    pin.float(no)
end

def reset_range()
    var i = 0
    while i < 8
        reset_pin(i)
        i += 1
    end
end

def sync_value(raw, bits)
    return (raw >> (32 - bits)) & ((1 << bits) - 1)
end

def read_sync_result(rx_pin, bits)
    var event = smart.rqpin(rx_pin)
    if event == 0
        return {
            "ok": false,
            "ready": false,
            "event": event,
            "raw": nil,
            "value": nil,
            "error": "not_ready"
        }
    end
    var raw = smart.rdpin(rx_pin)
    return {
        "ok": true,
        "ready": true,
        "event": event,
        "raw": raw,
        "value": sync_value(raw, bits),
        "error": nil
    }
end

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

def sync_variants(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin)
    var tx_clock = relative_b_mode(data_tx_pin, clock_tx_pin)
    var rx_clock = relative_b_mode(data_rx_pin, clock_rx_pin)
    return [
        {
            "name": "normal_clock",
            "tx_mode": smart.oe + smart.sync_io + tx_clock + smart.sync_tx,
            "rx_mode": smart.sync_io + rx_clock + smart.sync_rx,
            "clock_mode": smart.oe + smart.pulse
        },
        {
            "name": "inverted_rx_clock",
            "tx_mode": smart.oe + smart.sync_io + tx_clock + smart.sync_tx,
            "rx_mode": smart.sync_io + smart.invert_b + rx_clock + smart.sync_rx,
            "clock_mode": smart.oe + smart.pulse
        },
        {
            "name": "inverted_clock_output",
            "tx_mode": smart.oe + smart.sync_io + tx_clock + smart.sync_tx,
            "rx_mode": smart.sync_io + rx_clock + smart.sync_rx,
            "clock_mode": smart.oe + smart.invert_output + smart.pulse
        },
        {
            "name": "inverted_output_and_rx_clock",
            "tx_mode": smart.oe + smart.sync_io + tx_clock + smart.sync_tx,
            "rx_mode": smart.sync_io + smart.invert_b + rx_clock + smart.sync_rx,
            "clock_mode": smart.oe + smart.invert_output + smart.pulse
        }
    ]
end

def deferred_variant_probe(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin, values, wait_us)
    var variants = sync_variants(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin)
    var results = []
    var i = 0
    while i < variants.size()
        var variant = variants[i]
        results.push({
            "ok": false,
            "data_tx_pin": data_tx_pin,
            "data_rx_pin": data_rx_pin,
            "clock_tx_pin": clock_tx_pin,
            "clock_rx_pin": clock_rx_pin,
            "variant": variant["name"],
            "tx_mode": variant["tx_mode"],
            "rx_mode": variant["rx_mode"],
            "clock_mode": variant["clock_mode"],
            "values": values,
            "results": [],
            "count": values.size(),
            "ready_count": 0,
            "matched_count": 0,
            "matched_receive_words": false,
            "receive_status": STATUS_UNVERIFIED,
            "receive_policy": POLICY,
            "wait_us": wait_us,
            "executed": false,
            "execution_supported": false,
            "error": "execution_deferred"
        })
        i += 1
    end
    return {
        "ok": false,
        "data_tx_pin": data_tx_pin,
        "data_rx_pin": data_rx_pin,
        "clock_tx_pin": clock_tx_pin,
        "clock_rx_pin": clock_rx_pin,
        "values": values,
        "results": results,
        "count": values.size(),
        "ready_count": 0,
        "matched_count": 0,
        "matched_receive_words": false,
        "receive_status": STATUS_UNVERIFIED,
        "receive_policy": POLICY,
        "wait_us": wait_us,
        "variant_count": results.size(),
        "executed_variant_count": 0,
        "deferred_variant_count": results.size(),
        "selected_variant": nil,
        "selected": nil,
        "execution_supported": false,
        "error": "execution_deferred"
    }
end

def check_group_result(result)
    assert(type(result["ok"]) == "bool")
    assert(type(result["data_tx_pin"]) == "int")
    assert(type(result["data_rx_pin"]) == "int")
    assert(type(result["clock_tx_pin"]) == "int")
    assert(type(result["clock_rx_pin"]) == "int")
    assert(type(result["tx_mode"]) == "int")
    assert(type(result["rx_mode"]) == "int")
    assert(type(result["clock_mode"]) == "int")
    assert(type(result["ready_count"]) == "int")
    assert(type(result["matched_count"]) == "int")
    assert(type(result["matched_receive_words"]) == "bool")
    if result["execution_supported"]
        assert(result["receive_status"] == STATUS_VERIFIED)
    else
        assert(result["receive_status"] == STATUS_UNVERIFIED)
    end
    assert(result["receive_policy"] == POLICY)
    assert(type(result["execution_supported"]) == "bool")
    assert(isinstance(result["results"], list))
    var i = 0
    while i < result["results"].size()
        var item = result["results"][i]
        check_result(item)
        assert(type(item["sent"]) == "int")
        assert(type(item["matched"]) == "bool")
        assert(item["clocked"])
        i += 1
    end
end

def check_variant_probe(result)
    assert(type(result["ok"]) == "bool")
    assert(!result["execution_supported"])
    assert(result["variant_count"] == 4)
    assert(result["executed_variant_count"] == 0)
    assert(result["deferred_variant_count"] == 4)
    assert(type(result["ready_count"]) == "int")
    assert(type(result["matched_count"]) == "int")
    assert(isinstance(result["results"], list))
    assert(result["results"].size() == 4)
    var i = 0
    while i < result["results"].size()
        var item = result["results"][i]
        check_group_result(item)
        assert(item["variant"] == VARIANT_NAMES[i])
        assert(!item["executed"])
        assert(item["error"] == "execution_deferred")
        i += 1
    end
    assert(!result["ok"])
    assert(result["selected"] == nil)
    assert(result["selected_variant"] == nil)
    assert(result["error"] == "execution_deferred")
end

def clocked_probe(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin, values, wait_us, baud, bits)
    var variants = sync_variants(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin)
    var normal = variants[0]
    var x = serial_x(baud, bits)
    var clock_x = pulse_x(1000, 1000)
    reset_pin(data_tx_pin)
    reset_pin(data_rx_pin)
    reset_pin(clock_tx_pin)
    reset_pin(clock_rx_pin)
    pin.float(clock_rx_pin)
    smart.start(clock_tx_pin, normal["clock_mode"], clock_x, 0)
    smart.wypin(clock_tx_pin, 0)
    smart.start(data_tx_pin, normal["tx_mode"], x, 0)
    smart.start(data_rx_pin, normal["rx_mode"], x, 0)
    var results = []
    var ready_count = 0
    var matched_count = 0
    var i = 0
    while i < values.size()
        var sent = values[i]
        smart.akpin(data_rx_pin)
        smart.wypin(data_tx_pin, sent)
        smart.wypin(clock_tx_pin, bits)
        p2.waitus(wait_us)
        var result = read_sync_result(data_rx_pin, bits)
        result["sent"] = sent
        result["matched"] = result["ok"] && result["value"] == sent
        result["clocked"] = true
        if result["ready"]
            ready_count += 1
        end
        if result["matched"]
            matched_count += 1
        end
        results.push(result)
        i += 1
    end
    reset_pin(data_tx_pin)
    reset_pin(data_rx_pin)
    reset_pin(clock_tx_pin)
    reset_pin(clock_rx_pin)
    return {
        "ok": matched_count == values.size(),
        "data_tx_pin": data_tx_pin,
        "data_rx_pin": data_rx_pin,
        "clock_tx_pin": clock_tx_pin,
        "clock_rx_pin": clock_rx_pin,
        "tx_mode": normal["tx_mode"],
        "rx_mode": normal["rx_mode"],
        "clock_mode": normal["clock_mode"],
        "values": values,
        "results": results,
        "count": results.size(),
        "ready_count": ready_count,
        "matched_count": matched_count,
        "matched_receive_words": matched_count == values.size(),
        "receive_status": STATUS_VERIFIED,
        "receive_policy": POLICY,
        "execution_supported": true,
        "wait_us": wait_us
    }
end

def clocked_variant_observation(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin, variant, sent, wait_us, baud, bits)
    var x = serial_x(baud, bits)
    var clock_x = pulse_x(1000, 1000)
    reset_pin(data_tx_pin)
    reset_pin(data_rx_pin)
    reset_pin(clock_tx_pin)
    reset_pin(clock_rx_pin)
    pin.float(clock_rx_pin)
    smart.start(clock_tx_pin, variant["clock_mode"], clock_x, 0)
    smart.wypin(clock_tx_pin, 0)
    smart.start(data_rx_pin, variant["rx_mode"], x, 0)
    smart.akpin(data_rx_pin)
    smart.start(data_tx_pin, variant["tx_mode"], x, 0)
    smart.wypin(data_tx_pin, sent)
    smart.wypin(clock_tx_pin, bits)
    p2.waitus(wait_us)
    var event = smart.rqpin(data_rx_pin)
    var raw = event != 0 ? smart.rdpin(data_rx_pin) : -1
    var value = event != 0 ? sync_value(raw, bits) : nil
    var matched = event != 0 && value == sent
    reset_pin(data_tx_pin)
    reset_pin(data_rx_pin)
    reset_pin(clock_tx_pin)
    reset_pin(clock_rx_pin)
    return {
        "ok": matched,
        "variant": variant["name"],
        "sent": sent,
        "event": event,
        "raw": raw,
        "value": value,
        "ready": event != 0,
        "matched": matched,
        "tx_mode": variant["tx_mode"],
        "rx_mode": variant["rx_mode"],
        "clock_mode": variant["clock_mode"],
        "wait_us": wait_us,
        "execution_supported": true,
        "receive_status": STATUS_VERIFIED,
        "receive_policy": POLICY
    }
end

reset_range()

assert(type(smart.sync_io) == "int")
assert(type(smart.sync_tx) == "int")
assert(type(smart.sync_rx) == "int")
assert(type(smart.pulse) == "int")
assert(type(smart.invert_b) == "int")
assert(type(smart.invert_output) == "int")
assert(GROUPS == [[0, 1, 2, 3], [4, 5, 6, 7]])

var unclocked_x = serial_x(115200, 8)
smart.start(0, smart.oe + smart.sync_io + smart.sync_tx, unclocked_x, 0)
smart.start(1, smart.sync_io + smart.sync_rx, unclocked_x, 0)
check_result(read_sync_result(1, 8))
reset_pin(0)
reset_pin(1)

var single = clocked_probe(0, 1, 2, 3, [0x12], 1000, 100000, 8)
check_group_result(single)
assert(single["count"] == 1)
assert(single["values"] == [0x12])
assert(single["ready_count"] >= 0)
assert(single["matched_count"] >= 0)
assert(single["ready_count"] == 1)
assert(single["matched_count"] == 1)
assert(single["matched_receive_words"])
print("P2_SMOKE_SYNC_CLOCKED", single["ready_count"], single["matched_count"], single["matched_receive_words"])

var variant_probe = deferred_variant_probe(0, 1, 2, 3, [0x12], 1000)
check_variant_probe(variant_probe)

var observed_variants = sync_variants(0, 1, 2, 3)
var observed_index = 0
var observed_matched = 0
while observed_index < observed_variants.size()
    var observed = clocked_variant_observation(0, 1, 2, 3, observed_variants[observed_index], 0x12, 2000, 100000, 8)
    assert(type(observed["event"]) == "int")
    assert(type(observed["raw"]) == "int")
    assert(type(observed["matched"]) == "bool")
    assert(observed["receive_status"] == STATUS_VERIFIED)
    assert(observed["receive_policy"] == POLICY)
    if observed["matched"]
        observed_matched += 1
    end
    print("P2_SMOKE_SYNC_VARIANT", observed["variant"], observed["event"], observed["raw"], observed["value"], observed["matched"])
    observed_index += 1
end
print("P2_SMOKE_SYNC_VARIANTS_MATCHED", observed_matched)

var group_index = 0
while group_index < GROUPS.size()
    var group = GROUPS[group_index]
    var variants = sync_variants(group[0], group[1], group[2], group[3])
    assert(variants.size() == 4)
    var variant_index = 0
    while variant_index < variants.size()
        assert(variants[variant_index]["name"] == VARIANT_NAMES[variant_index])
        assert(type(variants[variant_index]["tx_mode"]) == "int")
        assert(type(variants[variant_index]["rx_mode"]) == "int")
        assert(type(variants[variant_index]["clock_mode"]) == "int")
        variant_index += 1
    end
    group_index += 1
end

var default_results = []
group_index = 0
while group_index < GROUPS.size()
    var group = GROUPS[group_index]
    var item = deferred_variant_probe(group[0], group[1], group[2], group[3], [0x12], 1000)
    default_results.push(item)
    group_index += 1
end
assert(default_results.size() == GROUPS.size())
group_index = 0
while group_index < default_results.size()
    assert(!default_results[group_index]["ok"])
    assert(!default_results[group_index]["execution_supported"])
    assert(default_results[group_index]["variant_count"] == 4)
    assert(default_results[group_index]["error"] == "execution_deferred")
    group_index += 1
end

reset_range()

print("P2_SMOKE_PASS smartpins_sync_diag")
