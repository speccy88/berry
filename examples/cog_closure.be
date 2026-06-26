import p2

def blinker(pin, rate_ms)
    p2.pin.dir_high(pin)
    p2.pin.toggle(pin)
    return rate_ms
end

var caps = p2.cog.capabilities()
print("closure cog handle policy:", caps["handle_model"])
print("closure cog native blink:", caps["native_blink"], "stack", caps["native_blink_stack"])

var fast = p2.cog.spawn(blinker, 38, 150)
var slow = p2.cog.spawn(blinker, 39, 450)

print("closure cog handles:", fast, slow)
print("closure cog ids:", p2.cog.id(fast), p2.cog.id(slow))
var fast_info = p2.cog.info(fast)
var slow_info = p2.cog.info(slow)
print("fast info:", fast_info["model"], "pin", fast_info["native_pin"], "period", fast_info["period_ms"], "calls", fast_info["calls"])
print("slow info:", slow_info["model"], "pin", slow_info["native_pin"], "period", slow_info["period_ms"], "calls", slow_info["calls"])
var fast_status = p2.cog.status(fast)
var slow_status = p2.cog.status(slow)
print("fast status:", fast_status["running"], fast_status["native_blink"], "pin", fast_status["native_pin"], "period", fast_status["period_ms"])
print("slow status:", slow_status["running"], slow_status["native_blink"], "pin", slow_status["native_pin"], "period", slow_status["period_ms"])
var fast_join = p2.cog.join(fast)
var slow_join = p2.cog.join(slow)
print("fast join:", fast_join)
print("slow join:", slow_join)
print("fast result/error:", p2.cog.result(fast), p2.cog.error(fast))
print("slow result/error:", p2.cog.result(slow), p2.cog.error(slow))

p2.clock.waitms(1500)

var stopped = p2.cog.stop(fast)
var killed = p2.cog.kill(slow)
print("stop fast running:", stopped["running"])
print("kill slow running:", killed["running"])

p2.pin.float(38)
p2.pin.float(39)
print("cog closure example done")
