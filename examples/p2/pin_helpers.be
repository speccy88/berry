import p2

var led = p2.status_info()["build"]["led0_pin"]

p2.pin.dir_high(led)
p2.pin.write(led, 1)
p2.clock.waitms(250)

p2.pin.low(led)
p2.clock.waitms(250)

p2.pin.high(led)
p2.clock.waitms(250)

p2.pin.toggle(led)
print(p2.pin.read(led))
p2.clock.waitms(250)

p2.pin.float(led)
print(p2.pin.read(led))
p2.clock.waitms(250)

p2.pin.float(led)
print("p2 pin helpers done")
