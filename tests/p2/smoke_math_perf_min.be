print("P2_SMOKE_BEGIN math_perf_min")

import math
import p2

def tick_delta(start, finish)
    if finish >= start
        return finish - start
    end
    return 0
end

def empty_loop(samples)
    var i = 0
    var acc = 0
    var start = p2.clock.cnt()
    while i < samples
        acc += i
        i += 1
    end
    var finish = p2.clock.cnt()
    return {
        "ticks": tick_delta(start, finish),
        "acc": acc
    }
end

def trig_loop(samples)
    var i = 0
    var acc = 0.0
    var start = p2.clock.cnt()
    while i < samples
        acc += math.sin(i * 0.01)
        acc += math.cos(i * 0.01)
        i += 1
    end
    var finish = p2.clock.cnt()
    return {
        "ticks": tick_delta(start, finish),
        "acc": acc
    }
end

def fallback_loop(samples)
    var i = 0
    var acc = 0.0
    var start = p2.clock.cnt()
    while i < samples
        acc += math.sqrt(i + 1)
        i += 1
    end
    var finish = p2.clock.cnt()
    return {
        "ticks": tick_delta(start, finish),
        "acc": acc
    }
end

var accel = math.accel_info()
assert(isinstance(accel, map))
assert(accel["backend"] == "p2_cordic")
assert(accel["cordic"])
assert(accel["sin"])
assert(accel["cos"])
assert(accel["sqrt"] == false)

var samples = 64
var empty = empty_loop(samples)
var trig = trig_loop(samples)
var fallback = fallback_loop(samples)

assert(empty["ticks"] >= 0)
assert(trig["ticks"] > 0)
assert(fallback["ticks"] > 0)

print("P2_MATH_PERF_MIN", accel["backend"], samples, empty["ticks"], trig["ticks"], fallback["ticks"])
print("P2_SMOKE_PASS math_perf_min")
