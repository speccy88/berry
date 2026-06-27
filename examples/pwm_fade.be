import p2

var pin = 0
var frame = 200
var divisor = 1
var mode = p2.smart.oe + p2.smart.pwm_triangle

print("PWM fade on pin", pin)
p2.smart.start(pin, mode, frame * 65536 + divisor, 0)

var step = 0
while step <= 5
    var duty = step * 40
    p2.smart.wypin(pin, duty)
    p2.waitus(50000)
    print("duty", duty, "pin", pin, "frame", frame, "divisor", divisor)
    step += 1
end

step = 5
while step >= 0
    var duty = step * 40
    p2.smart.wypin(pin, duty)
    p2.waitus(50000)
    print("duty", duty, "pin", pin, "frame", frame, "divisor", divisor)
    step -= 1
end

p2.smart.clear(pin)
p2.pin.float(pin)
print("pwm fade done")
