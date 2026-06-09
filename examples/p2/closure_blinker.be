# P2 closure-style blinker example for P2 Edge LEDs on pins 38 and 39.
# Pass the function entity `blinker` to spawn(), then pass the closure args.
# Calling blinker(38, 250) would execute the function immediately on the
# current cog; using spawn(blinker, 38, 250) hands the function entity to the
# cog launcher and keeps a handle so the spawned cog can be stopped later.

import p2

def blinker(pin, ms)
    return p2.cog.blinker(pin, ms)
end

h38 = p2.cog.spawn(blinker, 38, 250)
h39 = p2.cog.spawn(blinker, 39, 700)

print("handles", h38, h39)
print("info", p2.cog.info())
print("stop later with:")
print("p2.cog.stop(h38); p2.cog.stop(h39)")
