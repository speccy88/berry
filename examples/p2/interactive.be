# Read-only interactive foundation. Paste one line at a time into the XMM REPL,
# or run as a Berry script. No pin writes, bus opens or SD access in this file.
import p2
import introspect

print("clock Hz", p2.clock.freq())
print("current cog", p2.cog.id())
print("memory profile", p2.debug.snapshot()["runtime"]["memory_profile"])
print("groups", p2.help()["groups"])
print("pin members", p2.help("pin")["members"])
assert(introspect.contains(p2.pin, "read"))
print("production source cogs", p2.cog.capabilities()["spawn_source"])

def twice(value)
    return value * 2
end
var total = 0
for i: 1..3
    total += twice(i)
end
assert(total == 12)
print("total", total)
print("interactive example passed")
