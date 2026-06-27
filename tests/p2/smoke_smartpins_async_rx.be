print("P2_SMOKE_BEGIN smartpins_async_rx")

import p2

var values = [0x00, 0x55, 0xa5, 0xff]
var pairs = [
    [0, 1],
    [2, 3],
    [4, 5],
    [6, 7]
]
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

def start_serial(tx_pin, rx_pin)
    reset_pair(tx_pin, rx_pin)
    p2.smart.start(tx_pin, tx_mode, serial_x, 0)
    p2.smart.start(rx_pin, rx_mode, serial_x, 0)
    p2.clock.waitus(1000)
end

def read_value(rx_pin)
    return (p2.smart.rdpin(rx_pin) >> 24) & 255
end

def read_ready_value(rx_pin)
    assert(p2.smart.rqpin(rx_pin) != 0)
    return read_value(rx_pin)
end

def send_and_read(tx_pin, rx_pin, value)
    start_serial(tx_pin, rx_pin)
    p2.smart.wypin(tx_pin, value)
    if value == 0
        p2.clock.waitus(2000)
        var zero = read_value(rx_pin)
        print("P2_SMOKE_ASYNC_RX result " + str(tx_pin) + "_" + str(rx_pin) + " true " + str(zero))
        assert(zero == value)
    else
        p2.clock.waitus(2000)
        var read = read_ready_value(rx_pin)
        assert(read == value)
        assert(read_value(rx_pin) == value)
    end
    print("P2_SMOKE_ASYNC_RX read " + str(tx_pin) + "_" + str(rx_pin) + " " + str(value))
    reset_pair(tx_pin, rx_pin)
    p2.clock.waitus(1000)
end

var pair_index = 0
while pair_index < pairs.size()
    var pair = pairs[pair_index]
    var a = pair[0]
    var b = pair[1]
    print("P2_SMOKE_PAIR " + str(a) + "_" + str(b))

    var value_index = 0
    while value_index < values.size()
        var value = values[value_index]
        print("P2_SMOKE_ASYNC_RX start " + str(a) + "_" + str(b) + " " + str(value))
        send_and_read(a, b, value)
        print("P2_SMOKE_ASYNC_RX start " + str(b) + "_" + str(a) + " " + str(value))
        send_and_read(b, a, value)
        value_index += 1
    end

    if a == 0
        print("P2_SMOKE_ASYNC_RX exchange " + str(a) + "_" + str(b))
        start_serial(a, b)
        value_index = 0
        while value_index < values.size()
            var value = values[value_index]
            p2.smart.wypin(a, value)
            p2.clock.waitus(2000)
            assert(read_value(b) == value)
            value_index += 1
        end
        reset_pair(a, b)
        p2.clock.waitus(1000)

        print("P2_SMOKE_ASYNC_RX burst " + str(a) + "_" + str(b))
        start_serial(a, b)
        p2.smart.wypin(a, 0x12)
        p2.smart.wypin(a, 0x34)
        p2.clock.waitus(5000)
        assert(read_value(b) == 0x34)
        print("P2_SMOKE_ASYNC_RX_BURST " + str(a) + "_" + str(b) + " 18 52")
        reset_pair(a, b)
        p2.clock.waitus(1000)

        print("P2_SMOKE_ASYNC_RX drain " + str(a) + "_" + str(b))
        start_serial(a, b)
        p2.smart.wypin(a, 0x33)
        p2.clock.waitus(2000)
        assert(p2.smart.rqpin(b) != 0)
        assert(read_value(b) == 0x33)
        p2.smart.akpin(b)
        p2.clock.waitus(100)
        reset_pair(a, b)
        p2.clock.waitus(1000)
    end

    pair_index += 1
end

print("P2_SMOKE_PASS smartpins_async_rx")
