import p2

var led = 56

p2.pin_output(led)
p2.pin_write(led, 1)
p2.waitms(250)

p2.pin_low(led)
p2.waitms(250)

p2.pin_high(led)
p2.waitms(250)

p2.pin_toggle(led)
print(p2.pin_read(led))
p2.waitms(250)

p2.pin_randomize(led)
print(p2.pin_read(led))
p2.waitms(250)

p2.pin_float(led)
