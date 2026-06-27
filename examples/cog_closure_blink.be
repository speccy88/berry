import p2

var caps = p2.cog.capabilities()
print("closure cog handle policy:", caps["handle_model"])
print("closure cog native blink:", caps["native_blink"], "stack", caps["native_blink_stack"])

def blinker(pin, rate_ms)
    p2.pin.dir_high(pin)
    p2.pin.toggle(pin)
    return rate_ms
end

var led38 = p2.cog.spawn(blinker, 38, 250)
var led39 = p2.cog.spawn(blinker, 39, 700)

print("closure cog handles:", led38, led39)
print("closure cog ids:", p2.cog.id(led38), p2.cog.id(led39))
print("The pin 38 / pin 39 blinker shape uses the native_blink cog fast path.")

p2.clock.waitms(750)

var stopped = p2.cog.stop(led38)
var killed = p2.cog.kill(led39)
print("stop led38 running:", stopped["running"])
print("kill led39 running:", killed["running"])
p2.pin.float(38)
p2.pin.float(39)
print("cog closure blink done")
