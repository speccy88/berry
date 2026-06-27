import p2

var led = p2.status_info()["build"]["led0_pin"]

p2.pin.dir_high(led)

var i = 0
while i < 6
    p2.pin.high(led)
    p2.clock.waitms(250)
    p2.pin.low(led)
    p2.clock.waitms(250)
    i += 1
end

p2.pin.float(led)
print("p2 blink done")
