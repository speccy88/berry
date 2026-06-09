import p2

print("closure cog capabilities:", p2.cog.capabilities())

def blinker(pin, rate_ms)
    p2.pin.dir_high(pin)
    p2.pin.toggle(pin)
    return rate_ms
end

led38 = p2.cog.spawn(blinker, 38, 250)
led39 = p2.cog.spawn(blinker, 39, 700)

print("closure cog handles:", led38, led39)
print("The p38/p39 blinker shape uses the native_blink cog fast path.")
print("Stop later from the REPL with:")
print("p2.cog.stop(", led38, ")")
print("p2.cog.stop(", led39, ")")
