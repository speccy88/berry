# Smoke proof for variable-length p2.cog task descriptors.
# The native blinker uses the first two args as pin and delay, but the
# descriptor carries the extra primitive args and info reports argc=8.

import p2

def blinker(pin, ms, label, enabled, spare, note, phase, sentinel)
    return p2.cog.task("blinker", pin, ms, label, enabled, spare, note, phase, sentinel)
end

t = blinker(38, 250, "p38:fast", true, nil, "extra", 3, false)
print("cap", p2.cog.capabilities()["task_max_args"])
print("task", p2.cog.is_task(t), p2.cog.task_info(t)["kind"], p2.cog.task_info(t)["argc"])
h = p2.cog.spawn(t)
i = p2.cog.info(h)
print("running", i["native_pin"], i["period_ms"], i["argc"], i["descriptor_task"], i["task_kind"], i["running"])
print("calls", p2.cog.info(h)["calls"])
a = p2.cog.stop(h)
print("stopped", a["running"], a["raw_running"])
print("remaining", p2.cog.info())
