print("P2_SMOKE_BEGIN libraries")

import binary_heap
import p2

var data = [3, 1, 4, 1, 5]
binary_heap.sort(data, /a b -> a < b)
assert(data == [1, 1, 3, 4, 5])

import libstore

var psram = p2.psram_info()
var expected_policy = psram["available"] ? libstore.POLICY_SD_CACHE_PSRAM : libstore.POLICY_SD_LAZY
var status = libstore.status()
var policy = libstore.policy()
assert(status["lazy"] == true)
assert(status["source"] == "sd")
assert(status["heap"] == "hub")
assert(policy["name"] == expected_policy)
assert(status["psram_cache"] == status["psram_available"])
assert(status["psram_cache_used"] == 0)
assert(status["psram_cache_free"] == status["psram_cache_limit"])
assert(status["psram_cache_items"] == 0)
assert(status["library_count"] >= 5)
assert(status["psram_max_transfer"] >= 0)
assert(libstore.strategy()["library_home"] == "sd")
assert(libstore.strategy()["object_heap"] == false)
assert(libstore.strategy()["direct_execute_from_psram"] == false)
if psram["available"] {
    assert(libstore.strategy()["load"] == "lazy_source_or_psram_cache")
} else {
    assert(libstore.strategy()["load"] == "lazy_source")
}
assert(libstore.modules().size() >= 4)
assert(libstore.module_name("MATH.BE") == "math")
assert(libstore.module_name("README.TXT") == nil)
assert(libstore.exists("binary_heap"))
assert(libstore.source_path("binary_heap") == "/modules/binary_heap.be")
assert(libstore.info("binary_heap")["exists"] == true)
assert(libstore.info("binary_heap")["source"] == "sd")
assert(libstore.exists("taskspin"))
assert(libstore.source_path("taskspin") == "/modules/taskspin.be")

import taskspin

taskspin.reset()

var a = {"n": 0}
var b = {"n": 0}
var log = []

def step_a(id, state)
    assert(id == taskspin.TASKID())
    state["n"] += 1
    log.push("a" + str(state["n"]))
    return state["n"] >= 2 ? taskspin.STOP : taskspin.RUN
end

def step_b(id, state)
    assert(id == taskspin.TASKID())
    state["n"] += 1
    log.push("b" + str(state["n"]))
    return state["n"] >= 3 ? taskspin.STOP : taskspin.RUN
end

var ta = taskspin.TASKSPIN(-1, step_a, a, 287)
var tb = taskspin.TASKSPIN(-1, step_b, b, 286)
assert(ta >= 0 && tb >= 0 && ta != tb)
assert(taskspin.TASKCHK(ta) == taskspin.RUNNING)
assert(taskspin.TASKCHK(tb) == taskspin.RUNNING)
assert(taskspin.task_info(ta)["stack_address"] == 287)
assert(taskspin.task_info(tb)["stack_address"] == 286)
assert(taskspin.tasks().size() == 2)

assert(taskspin.TASKHALT(ta))
assert(taskspin.TASKCHK(ta) == taskspin.HALTED)
assert(taskspin.TASKHLT() == taskspin.halt_bit(ta))
assert(taskspin.info()["halt_mask"] == taskspin.halt_bit(ta))
assert(taskspin.TASKNEXT() == tb)
assert(a["n"] == 0 && b["n"] == 1)
assert(taskspin.TASKCONT(ta))
assert(taskspin.TASKHLT() == 0)

while taskspin.TASKCHK(ta) != taskspin.FREE || taskspin.TASKCHK(tb) != taskspin.FREE
    assert(taskspin.TASKNEXT() >= 0)
end

assert(a["n"] == 2)
assert(b["n"] == 3)
assert(log == ["b1", "a1", "b2", "a2", "b3"])
assert(taskspin.TASKNEXT() == -1)

var self = {"n": 0}
var other = {"n": 0}

def self_halt_step(id, state)
    state["n"] += 1
    assert(taskspin.TASKHALT(-1))
    return taskspin.RUN
end

def other_step(id, state)
    state["n"] += 1
    return taskspin.RUN
end

var th = taskspin.TASKSPIN(-1, self_halt_step, self, 285)
var tr = taskspin.TASKSPIN(-1, other_step, other, 284)
assert(taskspin.TASKNEXT() == th)
assert(self["n"] == 1)
assert(other["n"] == 1)
assert(taskspin.TASKCHK(th) == taskspin.HALTED)
assert(taskspin.TASKCHK(tr) == taskspin.RUNNING)
assert(taskspin.TASKHLT() == taskspin.halt_bit(th))
assert(taskspin.task_info(th)["stack_address"] == 285)
assert(taskspin.task_info(tr)["current"] == true)
assert(taskspin.TASKSTOP(th))
assert(taskspin.TASKSTOP(tr))

var info2 = taskspin.info()
assert(info2["max_tasks"] == 32)
assert(info2["tasks"] == 0)
assert(info2["halt_mask"] == 0)
assert(info2["task_pointer_registers"] == "$11F..$100")
assert(info2["storage"] == "sd")

print("P2_SMOKE_PASS libraries")
