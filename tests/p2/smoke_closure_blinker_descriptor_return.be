# Hardware smoke proof that p2.cog.spawn(function, ...) can call a Berry
# function entity whose return value selects the native blinker task.

import p2

def blinker(pin, ms)
    return p2.cog.blinker(pin, ms)
end

h38 = p2.cog.spawn(blinker, 38, 250)
h39 = p2.cog.spawn(blinker, 39, 700)

print("handles", h38, h39)
info38 = p2.cog.info(h38)
info39 = p2.cog.info(h39)
print("running", info38["native_pin"], info38["period_ms"], info38["running"], info39["native_pin"], info39["period_ms"], info39["running"])
a = p2.cog.stop(h38)
b = p2.cog.stop(h39)
print("stopped", a["running"], a["raw_running"], b["running"], b["raw_running"])
