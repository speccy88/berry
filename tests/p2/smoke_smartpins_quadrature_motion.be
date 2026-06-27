print("P2_SMOKE_BEGIN smartpins_quadrature_motion")

import p2

var smart = p2.smart
var pin = p2.pin

def drive(out_a, out_b, a, b, settle_us)
    pin.write(out_a, a)
    pin.write(out_b, b)
    if settle_us > 0
        p2.clock.waitus(settle_us)
    end
end

def reset_pin(no)
    smart.clear(no)
    smart.wrpin(no, 0)
    smart.wxpin(no, 0)
    smart.wypin(no, 0)
    smart.akpin(no)
    pin.float(no)
end

def run_sequence(out_a, in_a, out_b, in_b, states, settle_us)
    reset_pin(in_a)
    reset_pin(in_b)
    reset_pin(out_a)
    reset_pin(out_b)
    pin.dir_high(out_a)
    pin.dir_high(out_b)
    drive(out_a, out_b, states[0][0], states[0][1], settle_us)

    smart.start(in_a, smart.quadrature + smart.plus2_b, 0, 0)
    smart.akpin(in_a)
    var before = smart.rdpin(in_a)
    var i = 0
    while i < states.size()
        var state = states[i]
        drive(out_a, out_b, state[0], state[1], settle_us)
        i += 1
    end
    var after = smart.rdpin(in_a)
    var delta = after - before
    reset_pin(out_a)
    reset_pin(out_b)
    reset_pin(in_a)
    reset_pin(in_b)
    return {
        "before": before,
        "after": after,
        "delta": delta,
        "moved": delta != 0,
        "direction": delta > 0 ? 1 : (delta < 0 ? -1 : 0)
    }
end

var forward = [[0, 0], [1, 0], [1, 1], [0, 1], [0, 0], [1, 0], [1, 1], [0, 1], [0, 0]]
var reverse = [[0, 0], [0, 1], [1, 1], [1, 0], [0, 0], [0, 1], [1, 1], [1, 0], [0, 0]]

var f = run_sequence(0, 1, 2, 3, forward, 1000)
print("P2_SMOKE_QUAD_FORWARD", f["before"], f["after"], f["delta"], f["direction"], f["moved"])
var r = run_sequence(0, 1, 2, 3, reverse, 1000)
print("P2_SMOKE_QUAD_REVERSE", r["before"], r["after"], r["delta"], r["direction"], r["moved"])

assert(f["moved"])
assert(r["moved"])
assert(f["direction"] != 0)
assert(r["direction"] != 0)
assert(f["direction"] != r["direction"])

print("P2_SMOKE_PASS smartpins_quadrature_motion")
