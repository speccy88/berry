print("P2_SMOKE_BEGIN smartpins_counter_timer_matrix")

import p2

var smart = p2.smart
var pin = p2.pin

assert(smart.state_ticks == 0x20)
assert(smart.events_ticks == 0x24)
assert(smart.periods_ticks == 0x26)
assert(smart.periods_highs == 0x28)
assert(smart.counter_ticks == 0x2a)
assert(smart.counter_highs == 0x2c)
assert(smart.counter_periods == 0x2e)
assert(smart.minus1_a == 0x70000000)

def reset_pin(no)
    smart.clear(no)
    smart.wrpin(no, 0)
    smart.wxpin(no, 0)
    smart.wypin(no, 0)
    smart.akpin(no)
    pin.float(no)
end

def reset_pair(out_pin, in_pin)
    reset_pin(out_pin)
    reset_pin(in_pin)
end

def pulse_train(out_pin, pulses, high_us, low_us)
    var i = 0
    while i < pulses
        pin.high(out_pin)
        if high_us > 0
            p2.clock.waitus(high_us)
        end
        pin.low(out_pin)
        if low_us > 0
            p2.clock.waitus(low_us)
        end
        i += 1
    end
end

def selected_case(name, mode, high_us, low_us, pulses, positive)
    reset_pair(0, 1)
    pin.dir_high(0)
    pin.low(0)
    smart.start(1, mode + smart.minus1_a, pulses, 1)
    var before = smart.rdpin(1)
    pulse_train(0, pulses, high_us, low_us)
    p2.clock.waitus(300)
    var after = smart.rdpin(1)
    var delta = after - before
    print("P2_SMOKE_COUNTER_TIMER_MATRIX", name, high_us, low_us, pulses, before, after, delta)
    if positive
        assert(after > 0)
    else
        assert(after != before)
    end
    reset_pair(0, 1)
    return after
end

def selected_group(label, high_us, low_us)
    print("P2_SMOKE_COUNTER_TIMER_GROUP", label, high_us, low_us)
    selected_case("state_ticks", smart.state_ticks, high_us, low_us, 4, false)
    selected_case("events_ticks", smart.events_ticks, high_us, low_us, 4, true)
    selected_case("periods_ticks", smart.periods_ticks, high_us, low_us, 4, true)
    selected_case("periods_highs", smart.periods_highs, high_us, low_us, 4, true)
    selected_case("counter_ticks", smart.counter_ticks, high_us, low_us, 4, true)
    selected_case("counter_highs", smart.counter_highs, high_us, low_us, 4, true)
    selected_case("counter_periods", smart.counter_periods, high_us, low_us, 4, true)
end

selected_group("short", 50, 50)
selected_group("medium", 100, 100)
selected_group("long", 200, 200)

print("P2_SMOKE_PASS smartpins_counter_timer_matrix")
