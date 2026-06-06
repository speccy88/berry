print("P2_SMOKE_BEGIN p2_api")

import p2

def expect_error(fn)
    var caught = false
    try
        fn()
    except .. as e, m
        caught = true
    end
    assert(caught)
end

var status = p2.status_info()
var led = status["build"]["led0_pin"]

assert(type(p2.clock) == "module")
assert(type(p2.cog) == "module")
assert(type(p2.lock) == "module")
assert(type(p2.pin) == "module")
assert(type(p2.cordic) == "module")
assert(type(p2.math) == "module")
assert(type(p2.rng) == "module")
assert(type(p2.smart) == "module")

assert(p2.clock.freq() == p2.clock_freq())
assert(p2.clock.mode() == p2.clock_mode())
assert(type(p2.clock.cnt()) == "int")
assert(type(p2.clock.cnth()) == "int")
p2.clock.waitx(1)
p2.clock.waitus(0)
p2.clock.waitms(0)
p2.clock.waitsec(0)
p2.clock.waitcnt(p2.clock.cnt() + 1)

var cog = p2.cog.id()
assert(cog == p2.cogid())
assert(cog >= 0 && cog < 8)
assert(p2.cog.check(cog) != 0)
assert(type(p2.cog.poll_attention()) == "int")

var lock = p2.lock.new()
if lock >= 0
    var got = p2.lock.try(lock)
    assert(type(got) == "int")
    if got != 0
        p2.lock.release(lock)
    end
    assert(type(p2.lock.check(lock)) == "int")
    p2.lock.ret(lock)
end

p2.pin.dir_high(led)
p2.pin.low(led)
assert(p2.pin.read(led) == 0)
p2.pin.high(led)
assert(p2.pin.read(led) == 1)
p2.pin.toggle(led)
p2.pin.float(led)

assert(type(p2.cordic.xypol(3, 4)) == "map")
assert(type(p2.cordic.polxy(1, 0)) == "map")
assert(type(p2.cordic.rotxy(1, 0, 0)) == "map")
assert(p2.math.isqrt(81) == 9)
assert(type(p2.math.muldiv64(6, 7, 3)) == "int")
assert(type(p2.math.rev(1)) == "int")
assert(type(p2.math.encod(8)) == "int")
assert(type(p2.rng.rnd()) == "int")

expect_error(def ()
    p2.clock.waitx(-1)
end)
expect_error(def ()
    p2.math.rev(-1)
end)
expect_error(def ()
    p2.cog.check(-1)
end)
expect_error(def ()
    p2.cog.check(8)
end)
expect_error(def ()
    p2.lock.check(-1)
end)
expect_error(def ()
    p2.lock.check(16)
end)
expect_error(def ()
    p2.pin.read(-1)
end)
expect_error(def ()
    p2.pin.read(64)
end)
expect_error(def ()
    p2.pin.read(58)
end)
expect_error(def ()
    p2.pin.read(62)
end)
if status["build"]["board_has_psram"] != 0
    expect_error(def ()
        p2.pin.read(57)
    end)
end

p2.smart.wrpin(led, 0)
p2.smart.wxpin(led, 0)
p2.smart.wypin(led, 0)
p2.smart.akpin(led)
assert(type(p2.smart.rdpin(led)) == "int")
assert(type(p2.smart.rqpin(led)) == "int")
p2.smart.clear(led)

print("P2_SMOKE_PASS p2_api")
