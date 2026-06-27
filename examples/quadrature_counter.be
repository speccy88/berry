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

def run_sequence(label, out_a, in_a, out_b, in_b, states, settle_us)
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
    var direction = delta > 0 ? 1 : (delta < 0 ? -1 : 0)
    reset_pin(out_a)
    reset_pin(out_b)
    reset_pin(in_a)
    reset_pin(in_b)

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
