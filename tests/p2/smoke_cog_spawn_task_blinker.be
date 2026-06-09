# Hardware smoke proof for explicit task-value spawning.
# This is equivalent to p2.cog.spawn(blinker(...)), but uses the clearer
# p2.cog.spawn_task(task) alias for descriptor/task values.

import p2

def blinker(pin, ms)
    return p2.cog.task("blinker", pin, ms)
end

t38 = blinker(38, 250)
t39 = blinker(39, 700)
print("tasks", p2.cog.is_task(t38), p2.cog.is_task(t39))
print("task_info", p2.cog.task_info(t38)["kind"], p2.cog.task_info(t39)["kind"])

h38 = p2.cog.spawn_task(t38)
h39 = p2.cog.spawn_task(t39)
print("handles", h38, h39)
i = p2.cog.info()
print("running", size(i), i[0]["descriptor_task"], i[0]["task_kind"], i[0]["native_pin"], i[0]["running"], i[1]["descriptor_task"], i[1]["task_kind"], i[1]["native_pin"], i[1]["running"])
print("calls0", p2.cog.info(h38)["calls"], p2.cog.info(h39)["calls"])
p2.waitms(2000)
print("calls1", p2.cog.info(h38)["calls"], p2.cog.info(h39)["calls"])

a = p2.cog.stop(h38)
b = p2.cog.stop(h39)
print("stopped", a["running"], a["raw_running"], b["running"], b["raw_running"])
print("remaining", p2.cog.info())
