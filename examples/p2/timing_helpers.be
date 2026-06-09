import p2

var ticks_per_ms = p2.clock_freq() / 1000
var start = p2.ticks()

p2.delay_us(1000)
print(p2.ticks() - start)

start = p2.ticks()
p2.waitms(10)
print((p2.ticks() - start) / ticks_per_ms)

start = p2.ticks()
p2.waitms(1000)
print((p2.ticks() - start) / p2.clock_freq())
