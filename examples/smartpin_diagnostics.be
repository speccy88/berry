import p2

var pairs = [[0, 1], [2, 3], [4, 5], [6, 7]]
var bit_ticks = p2.clock.freq() / 115200
var serial_x = bit_ticks * 65536 + 8 - 1
var tx_mode = p2.smart.oe + p2.smart.async_tx
var rx_mode = p2.smart.async_rx

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

def gpio_check(out_pin, in_pin)
    reset_pair(out_pin, in_pin)
    p2.pin.dir_high(out_pin)
    p2.pin.low(out_pin)
    p2.clock.waitus(200)
    var low = p2.pin.read(in_pin)
    p2.pin.high(out_pin)
    p2.clock.waitus(200)
    var high = p2.pin.read(in_pin)
    var ok = low == 0 && high != 0
    print(" gpio", ok, "low", low, "high", high)
    reset_pair(out_pin, in_pin)
    return ok
end

def count_rise_check(out_pin, in_pin)
    reset_pair(out_pin, in_pin)
    p2.pin.dir_high(out_pin)
    p2.pin.low(out_pin)
    p2.smart.start(in_pin, p2.smart.count_rises, 0, 0)
    var before = p2.smart.rdpin(in_pin)
    p2.pin.high(out_pin)
    p2.clock.waitus(300)
    p2.pin.low(out_pin)
    p2.clock.waitus(300)
    var after = p2.smart.rdpin(in_pin)
    var delta = after - before
    print(" rises", delta, "ok", delta == 1)
    reset_pair(out_pin, in_pin)
    return delta == 1
end

def high_ticks_check(out_pin, in_pin)
    reset_pair(out_pin, in_pin)
    p2.pin.dir_high(out_pin)
    p2.pin.low(out_pin)
    p2.smart.start(in_pin, p2.smart.high_ticks, 0, 0)
    var before = p2.smart.rdpin(in_pin)
    p2.pin.high(out_pin)
    p2.clock.waitus(1000)
    p2.pin.low(out_pin)
    p2.clock.waitus(300)
    var after = p2.smart.rdpin(in_pin)
    var delta = after - before
    print(" high_ticks", delta, "ok", delta > 0)
    reset_pair(out_pin, in_pin)
    return delta > 0
end

def async_check(tx_pin, rx_pin, value)
    reset_pair(tx_pin, rx_pin)
    p2.smart.start(tx_pin, tx_mode, serial_x, 0)
    p2.smart.start(rx_pin, rx_mode, serial_x, 0)
    p2.clock.waitus(1000)
    p2.smart.wypin(tx_pin, value)
    p2.clock.waitus(2000)
    var read = (p2.smart.rdpin(rx_pin) >> 24) & 255
    var ok = read == value
    print(" async", ok, "sent", value, "read", read)
    reset_pair(tx_pin, rx_pin)
    return ok
end

def pair_check(out_pin, in_pin, value)
    print("pair", out_pin, in_pin)
    var ok = gpio_check(out_pin, in_pin)
    ok = count_rise_check(out_pin, in_pin) && ok
    ok = high_ticks_check(out_pin, in_pin) && ok
    ok = async_check(out_pin, in_pin, value) && ok
    print("pair", out_pin, in_pin, "ok", ok)
    return ok
end

print("Smartpin diagnostics default jumpers")

var all_ok = true
var index = 0
while index < pairs.size()
    var pair = pairs[index]
    var value = 0x40 + index
    all_ok = pair_check(pair[0], pair[1], value) && all_ok
    index += 1
end

index = 0
while index < pairs.size()
    var pair = pairs[index]
    reset_pair(pair[0], pair[1])
    index += 1
end

print("smartpin diagnostics ok", all_ok)
print("smartpin diagnostics done")
