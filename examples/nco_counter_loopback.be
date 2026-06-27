import p2

var out_pin = 0
var in_pin = 1
var bit_period = 16000
var increment = 0x20000000

def clear_pair(a, b)
    p2.smart.clear(a)
    p2.smart.clear(b)
    p2.pin.float(a)
    p2.pin.float(b)
end

def nco_count(label, out_pin, in_pin, bit_period, increment, settle_us)
    clear_pair(out_pin, in_pin)
    p2.smart.start(in_pin, p2.smart.count_rises, 0, 0)
    p2.smart.start(out_pin, p2.smart.oe + p2.smart.nco_freq, bit_period, increment)
    p2.waitus(1000)
    var before = p2.smart.rdpin(in_pin)
    p2.waitus(settle_us)
    var after = p2.smart.rdpin(in_pin)
    var delta = after - before
    print(label, "out", out_pin, "in", in_pin, "increment", increment, "before", before, "after", after, "delta", delta, "settle", settle_us)
    clear_pair(out_pin, in_pin)
    return delta
end

print("NCO counter loopback OUT", out_pin, "IN", in_pin)
nco_count("fast", out_pin, in_pin, bit_period, increment, 20000)
nco_count("slower", out_pin, in_pin, bit_period, 0x10000000, 20000)
print("nco counter loopback done")
