import p2

var tx = 0
var rx = 1
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

def start_serial()
    reset_pair(tx, rx)
    p2.smart.start(tx, tx_mode, serial_x, 0)
    p2.smart.start(rx, rx_mode, serial_x, 0)
    p2.clock.waitus(1000)
end

def read_value()
    return (p2.smart.rdpin(rx) >> 24) & 255
end

def send_and_sample(value)
    p2.smart.wypin(tx, value)
    p2.clock.waitus(2000)
    return read_value()
end

print("Async serial loopback TX", tx, "RX", rx)

start_serial()
var values = [65, 66, 67]
var index = 0
while index < values.size()
    var sent = values[index]
    var sampled = send_and_sample(sent)
    print("sent", sent, "sampled", sampled, "matched", sampled == sent)
    index += 1
end
reset_pair(tx, rx)

start_serial()
p2.smart.wypin(tx, 0x12)
p2.smart.wypin(tx, 0x34)
p2.clock.waitus(5000)
var burst = read_value()
print("burst latest", burst == 0x34, "sampled", burst, "fifo", false)
reset_pair(tx, rx)

start_serial()
p2.smart.wypin(tx, 68)
p2.clock.waitus(2000)
var ready = p2.smart.rqpin(rx) != 0
var drained = read_value()
p2.smart.akpin(rx)
print("drain ready", ready, "matched", drained == 68, "value", drained)
reset_pair(tx, rx)

print("uart loopback done")
