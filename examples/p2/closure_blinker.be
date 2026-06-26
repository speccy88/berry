# P2 closure-style blinker example for P2 Edge LEDs on pins 38 and 39.
# Pass the function entity `blinker` to spawn(), then pass the closure args.
# Calling blinker(38, 250) would execute the function immediately on the
# current cog; using spawn(blinker, 38, 250) hands the function entity to the
# cog launcher and keeps a handle so the spawned cog can be stopped later.

import p2

def blinker(pin, ms)
    p2.pin.dir_high(pin)
    p2.pin.toggle(pin)
    return ms
end

var h38 = p2.cog.spawn(blinker, 38, 250)
var h39 = p2.cog.spawn(blinker, 39, 700)

print("handles", h38, h39)
print("ids", p2.cog.id(h38), p2.cog.id(h39))

p2.clock.waitms(750)

var stopped = p2.cog.stop(h38)
var killed = p2.cog.kill(h39)
print("stop h38 running", stopped["running"])
print("kill h39 running", killed["running"])
p2.pin.float(38)
p2.pin.float(39)
print("p2 closure blinker done")
