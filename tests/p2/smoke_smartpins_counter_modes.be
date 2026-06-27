print("P2_SMOKE_BEGIN smartpins_counter_modes")

import p2

assert(p2.smart.count_rises == 0x1c)
assert(p2.smart.count_highs == 0x1e)
assert(p2.smart.state_ticks == 0x20)
assert(p2.smart.high_ticks == 0x22)
assert(p2.smart.events_ticks == 0x24)
assert(p2.smart.periods_ticks == 0x26)
assert(p2.smart.periods_highs == 0x28)
assert(p2.smart.counter_ticks == 0x2a)
assert(p2.smart.counter_highs == 0x2c)
assert(p2.smart.counter_periods == 0x2e)
assert(p2.smart.minus1_a == 0x70000000)

var pairs = [[0, 1], [2, 3], [4, 5], [6, 7]]

def reset_pin(pin)
    p2.smart.clear(pin)
    p2.smart.wrpin(pin, 0)
    p2.smart.wxpin(pin, 0)
    p2.smart.wypin(pin, 0)
    p2.smart.akpin(pin)
    p2.pin.float(pin)
end

def reset_pair(a, b)
    reset_pin(a)
    reset_pin(b)
end

def counter_modes_loopback(out_pin, in_pin)
    reset_pair(out_pin, in_pin)
    p2.pin.dir_high(out_pin)
    p2.pin.low(out_pin)
    p2.smart.start(in_pin, p2.smart.count_highs, 0, 0)
    var before = p2.smart.rdpin(in_pin)
    p2.pin.high(out_pin)
    p2.clock.waitus(1000)
    p2.pin.low(out_pin)
    p2.clock.waitus(100)
    var after = p2.smart.rdpin(in_pin)
    var delta = after - before
    print("P2_SMOKE_COUNTER_MODES " + str(out_pin) + "_" + str(in_pin) + " true 1 0 " + str(delta))
    assert(delta > 0)
    reset_pair(out_pin, in_pin)
end

def counter_rises_loopback(out_pin, in_pin)
    reset_pair(out_pin, in_pin)
    p2.pin.dir_high(out_pin)
    p2.pin.low(out_pin)
    p2.smart.start(in_pin, p2.smart.count_rises, 0, 0)
    var before = p2.smart.rdpin(in_pin)
    p2.pin.high(out_pin)
    p2.clock.waitus(1000)
    p2.pin.low(out_pin)
    p2.clock.waitus(100)
    var after = p2.smart.rdpin(in_pin)
    var delta = after - before
    print("P2_SMOKE_COUNTER_RISES " + str(out_pin) + "_" + str(in_pin) + " true 1 " + str(delta))
    assert(delta == 1)
    reset_pair(out_pin, in_pin)
end

def high_ticks_loopback(out_pin, in_pin)
    reset_pair(out_pin, in_pin)
    p2.pin.dir_high(out_pin)
    p2.pin.low(out_pin)
    p2.smart.start(in_pin, p2.smart.high_ticks, 0, 0)
    var before = p2.smart.rdpin(in_pin)
    p2.pin.high(out_pin)
    p2.clock.waitus(1000)
    p2.pin.low(out_pin)
    p2.clock.waitus(100)
    var after = p2.smart.rdpin(in_pin)
    var delta = after - before
    print("P2_SMOKE_COUNTER_HIGH_TICKS " + str(out_pin) + "_" + str(in_pin) + " " + str(delta))
    assert(delta > 0)
    reset_pair(out_pin, in_pin)
end

def pulse_train(out_pin, pulses, high_us, low_us)
    var i = 0
    while i < pulses
        p2.pin.high(out_pin)
        if high_us > 0
            p2.clock.waitus(high_us)
        end
        p2.pin.low(out_pin)
        if low_us > 0
            p2.clock.waitus(low_us)
        end
        i += 1
    end
end

def counter_variant_diag(name, mode, out_pin, in_pin)
    reset_pair(out_pin, in_pin)
    p2.pin.dir_high(out_pin)
    p2.pin.low(out_pin)
    p2.smart.start(in_pin, mode, 0, 0)
    var before = p2.smart.rdpin(in_pin)
    pulse_train(out_pin, 4, 200, 200)
    p2.clock.waitus(200)
    var after = p2.smart.rdpin(in_pin)
    var delta = after - before
    print("P2_SMOKE_COUNTER_VARIANT_DIAG " + name + " " + str(before) + " " + str(after) + " " + str(delta))
    reset_pair(out_pin, in_pin)
    return delta
end

def selected_counter_variant(name, mode, out_pin, in_pin, positive)
    reset_pair(out_pin, in_pin)
    p2.pin.dir_high(out_pin)
    p2.pin.low(out_pin)
    p2.smart.start(in_pin, mode + p2.smart.minus1_a, 4, 1)
    var before = p2.smart.rdpin(in_pin)
    pulse_train(out_pin, 4, 100, 100)
    p2.clock.waitus(300)
    var after = p2.smart.rdpin(in_pin)
    var delta = after - before
    print("P2_SMOKE_COUNTER_VARIANT_SELECTED " + name + " " + str(before) + " " + str(after) + " " + str(delta))
    if positive
        assert(after > 0)
    else
        assert(after != before)
    end
    reset_pair(out_pin, in_pin)
    return after
end

var pair_index = 0
while pair_index < pairs.size()
    var pair = pairs[pair_index]
    var a = pair[0]
    var b = pair[1]
    print("P2_SMOKE_PAIR " + str(a) + "_" + str(b))
    print("P2_SMOKE_CASE counter_modes_ab")
    counter_modes_loopback(a, b)
    print("P2_SMOKE_CASE counter_rises_ab")
    counter_rises_loopback(a, b)
    print("P2_SMOKE_CASE counter_modes_ba")
    counter_modes_loopback(b, a)
    print("P2_SMOKE_CASE counter_rises_ba")
    counter_rises_loopback(b, a)
    pair_index += 1
end

print("P2_SMOKE_CASE counter_high_ticks_ab")
high_ticks_loopback(0, 1)
print("P2_SMOKE_CASE counter_high_ticks_ba")
high_ticks_loopback(1, 0)

print("P2_SMOKE_CASE counter_variant_diag")
counter_variant_diag("state_ticks", p2.smart.state_ticks, 0, 1)
counter_variant_diag("events_ticks", p2.smart.events_ticks, 0, 1)
counter_variant_diag("periods_ticks", p2.smart.periods_ticks, 0, 1)
counter_variant_diag("periods_highs", p2.smart.periods_highs, 0, 1)
counter_variant_diag("counter_ticks", p2.smart.counter_ticks, 0, 1)
counter_variant_diag("counter_highs", p2.smart.counter_highs, 0, 1)
counter_variant_diag("counter_periods", p2.smart.counter_periods, 0, 1)

print("P2_SMOKE_CASE counter_variant_selected")
selected_counter_variant("state_ticks", p2.smart.state_ticks, 0, 1, false)
selected_counter_variant("events_ticks", p2.smart.events_ticks, 0, 1, true)
selected_counter_variant("periods_ticks", p2.smart.periods_ticks, 0, 1, true)
selected_counter_variant("periods_highs", p2.smart.periods_highs, 0, 1, true)
selected_counter_variant("counter_ticks", p2.smart.counter_ticks, 0, 1, true)
selected_counter_variant("counter_highs", p2.smart.counter_highs, 0, 1, true)
selected_counter_variant("counter_periods", p2.smart.counter_periods, 0, 1, true)

pair_index = 0
while pair_index < pairs.size()
    var pair = pairs[pair_index]
    reset_pair(pair[0], pair[1])
    pair_index += 1
end

print("P2_SMOKE_PASS smartpins_counter_modes")
