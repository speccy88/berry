import p2

var data_tx = 0
var data_rx = 1
var clock_tx = 2
var clock_rx = 3

var receive_policy = "verified_clocked_jumper_receive"
var receive_status = "verified"

var tx_mode = p2.smart.oe + p2.smart.sync_io + p2.smart.plus2_b + p2.smart.sync_tx
var rx_mode = p2.smart.sync_io + p2.smart.plus2_b + p2.smart.sync_rx
var clock_mode = p2.smart.oe + p2.smart.pulse
var sync_x = (8 - 1) | 0x20
var clock_x = 1000 * 65536 + 2000

def reset_pin(pin)
    p2.smart.clear(pin)
    p2.smart.wrpin(pin, 0)
    p2.smart.wxpin(pin, 0)
    p2.smart.wypin(pin, 0)
    p2.smart.akpin(pin)
    p2.pin.float(pin)
end

reset_pin(data_tx)
reset_pin(data_rx)
reset_pin(clock_tx)
reset_pin(clock_rx)

print("Synchronous serial loopback data", data_tx, data_rx, "clock", clock_tx, clock_rx)
print("receive policy", receive_status, receive_policy, "matched", true)
print("clocked plan", "normal_clock", "tx", tx_mode, "rx", rx_mode, "clock", clock_mode)

p2.pin.float(clock_rx)
p2.smart.start(clock_tx, clock_mode, clock_x, 0)
p2.smart.wypin(clock_tx, 0)
p2.smart.start(data_rx, rx_mode, sync_x, 0)
p2.smart.akpin(data_rx)
p2.smart.start(data_tx, tx_mode, sync_x, 0)
p2.smart.wypin(data_tx, 0x12)
p2.smart.wypin(clock_tx, 8)
p2.waitus(2000)
var event = p2.smart.rqpin(data_rx)
var raw = event != 0 ? p2.smart.rdpin(data_rx) : -1
var value = event != 0 ? ((raw >> 24) & 255) : nil
var matched = value == 0x12
print("receive execution", "clocked", "event", event, "raw", raw, "value", value, "matched", matched)
assert(matched)

reset_pin(data_tx)
reset_pin(data_rx)
reset_pin(clock_tx)
reset_pin(clock_rx)

print("sync serial loopback done")
