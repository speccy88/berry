import p2
import p2mem

print("P2 debug snapshot:")
var snapshot = p2.debug.snapshot()
var heap = p2.debug.heap()
var gc = p2.debug.gc()
var cogs = p2.debug.cogs()
var memory = p2.debug.memory_map()
print("profile:", snapshot["build"]["profile"])
print("led pin:", snapshot["build"]["led0_pin"])
print("cog count:", cogs.size())
print("heap current:", heap["current"])
print("gc after:", gc["after"])
print("hub total:", memory["hub_total"])

print("P2 memory policy:")
print("audit:", p2mem.audit_ok(), p2mem.audit_problems().size())
print("capabilities:", p2mem.capability("stats_result"), p2mem.capability("gc_result"), p2mem.capability("native_cache"))
print("debug report done")
