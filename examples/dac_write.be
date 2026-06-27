import p2

var pin = 0
var frame = 256
var mode = p2.smart.oe + p2.smart.dac_990r_3v + p2.smart.dac_dither_pwm

print("DAC stepped output on pin", pin)
p2.smart.start(pin, mode, frame, 0)

var values = [0, 64, 128, 192, 255, 0]
var i = 0
while i < values.size()
    var value = values[i]
    p2.smart.wypin(pin, value)
    p2.waitus(60000)
    print("dac", "pin", pin, "value", value, "frame", frame)
    i += 1
end

p2.smart.clear(pin)
p2.pin.float(pin)
print("dac done")
