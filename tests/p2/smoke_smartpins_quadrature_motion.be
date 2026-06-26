print("P2_SMOKE_BEGIN smartpins_quadrature_motion")

import p2smart

def drive(out_a, out_b, a, b, settle_us)
    p2smart.pin.write(out_a, a)
    p2smart.pin.write(out_b, b)
    if settle_us > 0
        p2smart.waitus(settle_us)
    end
end

def run_sequence(out_a, in_a, out_b, in_b, states, settle_us)
    p2smart.smart.clear(in_a)
    p2smart.smart.clear(in_b)
    p2smart.pin.float(in_a)
    p2smart.pin.float(in_b)
    p2smart.pin.dir_high(out_a)
    p2smart.pin.dir_high(out_b)
    drive(out_a, out_b, states[0][0], states[0][1], settle_us)

    var quad = p2smart.quadrature(in_a, in_b, p2smart.smart.plus2_b)
    quad.start()
    var before = quad.position()
    for state : states
        drive(out_a, out_b, state[0], state[1], settle_us)
    end
    var after = quad.position()
    var delta = after - before
    quad.clear()
    p2smart.pin.float(out_a)
    p2smart.pin.float(out_b)
    p2smart.pin.float(in_a)
    p2smart.pin.float(in_b)
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
