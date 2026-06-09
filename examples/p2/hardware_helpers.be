import p2

print("clock")
print(p2.clock_freq())
print(p2.clock_mode())

print("counter")
var start = p2.ticks()
p2.wait_ticks(p2.clock_freq() / 10)
print(p2.ticks() - start)
print(p2.ticks64())

print("math")
print(p2.random())
print(p2.reverse_bits(1))
print(p2.encode(0x10))
print(p2.isqrt(10000))
print(p2.muldiv64(1000, 2000, 25))
print(p2.rotxy(1000, 0, 0))
print(p2.xypol(1000, 0))
print(p2.polxy(1000, 0))

print("cogs")
print(p2.cogid())
print(p2.cog_id())
print(p2.cog_states())
print(p2.cog_check(p2.cogid()))
print(p2.cog_stack_bytes(p2.cogid()))

print("attention")
p2.attention_signal(1 << p2.cogid())
print(p2.attention_poll())
