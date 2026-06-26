import p2smart

def drive(out_a, out_b, a, b, settle_us)
    p2smart.pin.write(out_a, a)
    p2smart.pin.write(out_b, b)
    if settle_us > 0
        p2smart.waitus(settle_us)
    end
end

def run_sequence(label, out_a, in_a, out_b, in_b, states, settle_us)
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
    var direction = delta > 0 ? 1 : (delta < 0 ? -1 : 0)
    quad.clear()
    p2smart.pin.float(out_a)
    p2smart.pin.float(out_b)
    p2smart.pin.float(in_a)
    p2smart.pin.float(in_b)

    print(label, "before", before, "after", after, "delta", delta, "moved", delta != 0, "direction", direction)
    return direction
end

var out_a = 0
var in_a = 1
var out_b = 2
var in_b = 3
var settle_us = 1000
var forward = [[0, 0], [1, 0], [1, 1], [0, 1], [0, 0], [1, 0], [1, 1], [0, 1], [0, 0]]
var reverse = [[0, 0], [0, 1], [1, 1], [1, 0], [0, 0], [0, 1], [1, 1], [1, 0], [0, 0]]

print("Quadrature counter A", in_a, "B", in_b, "driven by", out_a, "and", out_b)
var forward_direction = run_sequence("forward", out_a, in_a, out_b, in_b, forward, settle_us)
var reverse_direction = run_sequence("reverse", out_a, in_a, out_b, in_b, reverse, settle_us)
print("directions", forward_direction, reverse_direction)
print("quadrature counter done")
