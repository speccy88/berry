import p2

var led = p2.status_info()["build"]["led0_pin"]

print("Blinking P2 board LED on pin", led)

p2.pin.dir_high(led)
for i : 0..9
    p2.pin.toggle(led)
    p2.clock.waitms(250)
end
p2.pin.float(led)

print("blink done")
