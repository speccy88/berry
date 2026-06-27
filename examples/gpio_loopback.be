import p2

var out_pin = 0
var in_pin = 1

print("GPIO loopback OUT", out_pin, "IN", in_pin)

p2.pin.float(out_pin)
p2.pin.float(in_pin)
p2.pin.dir_high(out_pin)
p2.pin.dir_low(in_pin)

var values = [0, 1, 0, 1]
var ok = true
var i = 0
while i < values.size()
    var value = values[i]
    p2.pin.write(out_pin, value)
    p2.waitus(10000)
    var read = p2.pin.read(in_pin)
    var match = read == value
    ok = ok && match
    print("write", value, "read", read, "match", match)
    i += 1
end

p2.pin.float(out_pin)
p2.pin.float(in_pin)
print("ok", ok, "count", values.size())
print("gpio loopback done")
