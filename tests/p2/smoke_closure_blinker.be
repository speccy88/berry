# Hardware smoke proof for p2.cog.spawn(blinker, pin, delay_ms).
# Expected on the P2 Edge32 XMM profile: two handles, two cogs, descriptor
# metadata on each handle, then both handles stop cleanly. Counter progression
# is verified by the host-side serial smoke so this file does not depend on a
# sleep helper being present in the Berry image.

import p2

def blinker(pin, ms)
    return p2.cog.blinker(pin, ms)
end

h38 = p2.cog.spawn(blinker, 38, 250)
h39 = p2.cog.spawn(blinker, 39, 700)

print("handles", h38, h39)
info = p2.cog.info()
print("running", size(info), info[0]["descriptor_task"], info[0]["task_kind"], info[0]["native_pin"], info[0]["argc"], info[0]["cog"], info[0]["running"], info[1]["descriptor_task"], info[1]["task_kind"], info[1]["native_pin"], info[1]["argc"], info[1]["cog"], info[1]["running"])
print("calls0", p2.cog.info(h38)["calls"], p2.cog.info(h39)["calls"])

a = p2.cog.stop(h38)
b = p2.cog.stop(h39)
print("stopped", a["running"], a["raw_running"], b["running"], b["raw_running"])
print("remaining", p2.cog.info())
