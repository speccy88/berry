print("P2_SMOKE_BEGIN smartpins_async_buffer_boundary")

import p2

var smart = p2.smart
var pin = p2.pin
var tx_pin = 0
var rx_pin = 1
var bit_ticks = p2.clock.freq() / 115200
var serial_x = bit_ticks * 65536 + 8 - 1
var tx_mode = smart.oe + smart.async_tx
var rx_mode = smart.async_rx

def reset_pin(no)
    smart.clear(no)
    smart.wrpin(no, 0)
    smart.wxpin(no, 0)
    smart.wypin(no, 0)
    smart.akpin(no)
    pin.float(no)
end

def reset_pair()
    reset_pin(tx_pin)
    reset_pin(rx_pin)
end

def start_serial()
    reset_pair()
    smart.start(tx_pin, tx_mode, serial_x, 0)
    smart.start(rx_pin, rx_mode, serial_x, 0)
    p2.clock.waitus(1000)
end

def read_value()
    return (smart.rdpin(rx_pin) >> 24) & 255
end

def drain_ready(max_count)
    var count = 0
    var first = nil
    var last = nil
    while count < max_count
        if smart.rqpin(rx_pin) == 0
            break
        end
        var value = read_value()
        if first == nil
            first = value
        end
        last = value
        smart.akpin(rx_pin)
        p2.clock.waitus(100)
        count += 1
    end
    return { "count": count, "first": first, "last": last }
end

var values = [0x11, 0x22, 0x33, 0x44]
start_serial()
var i = 0
while i < values.size()
    var value = values[i]
    smart.wypin(tx_pin, value)
    p2.clock.waitus(2500)
    assert(smart.rqpin(rx_pin) != 0)
    var read = read_value()
    assert(read == value)
    smart.akpin(rx_pin)
    print("P2_SMOKE_ASYNC_BUFFER_PACED", value, read)
    i += 1
end
reset_pair()

start_serial()
i = 0
while i < values.size()
    smart.wypin(tx_pin, values[i])
    i += 1
end
p2.clock.waitus(8000)
var sampled = read_value()
assert(sampled == 0x44)
var drained = drain_ready(4)
print("P2_SMOKE_ASYNC_BUFFER_BURST", sampled, drained["count"], drained["first"], drained["last"])
reset_pair()

print("P2_SMOKE_PASS smartpins_async_buffer_boundary")
