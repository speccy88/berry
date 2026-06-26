import p2smart

var out_pin = 0
var in_pin = 1
var bit_period = 16000
var increment = 0x20000000

print("NCO counter loopback OUT", out_pin, "IN", in_pin)
var fast = p2smart.nco_counter_probe(out_pin, in_pin, bit_period, increment, 20000)
print("fast", "ok", fast["ok"], "out", fast["out_pin"], "in", fast["in_pin"], "increment", fast["nco"]["increment"], "before", fast["counter"]["before"], "after", fast["counter"]["after"], "delta", fast["counter"]["delta"], "settle", fast["settle_us"])
var slower = p2smart.nco_counter_probe(out_pin, in_pin, bit_period, 0x10000000, 20000)
print("slower", "ok", slower["ok"], "out", slower["out_pin"], "in", slower["in_pin"], "increment", slower["nco"]["increment"], "before", slower["counter"]["before"], "after", slower["counter"]["after"], "delta", slower["counter"]["delta"], "settle", slower["settle_us"])
print("nco counter loopback done")
