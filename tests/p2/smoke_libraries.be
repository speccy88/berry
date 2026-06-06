print("P2_SMOKE_BEGIN libraries")

import binary_heap

var data = [3, 1, 4, 1, 5]
binary_heap.sort(data, /a b -> a < b)
assert(data == [1, 1, 3, 4, 5])

import libstore

var status = libstore.status()
assert(status["lazy"] == true)
assert(status["source"] == "sd")
assert(status["heap"] == "hub")
assert(status["psram_cache"] == status["psram_available"])
assert(status["psram_cache_used"] == 0)
assert(status["psram_max_transfer"] >= 0)
assert(libstore.strategy()["library_home"] == "sd")
assert(libstore.strategy()["object_heap"] == false)
assert(libstore.strategy()["direct_execute_from_psram"] == false)
assert(libstore.modules().size() >= 4)
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

var ta = taskspin.TASKSPIN(-1, step_a, a)
var tb = taskspin.TASKSPIN(-1, step_b, b)
assert(ta >= 0 && tb >= 0 && ta != tb)
assert(taskspin.TASKCHK(ta) == taskspin.RUNNING)
assert(taskspin.TASKCHK(tb) == taskspin.RUNNING)

assert(taskspin.TASKHALT(ta))
assert(taskspin.TASKCHK(ta) == taskspin.HALTED)
assert(taskspin.TASKNEXT() == tb)
assert(a["n"] == 0 && b["n"] == 1)
assert(taskspin.TASKCONT(ta))

while taskspin.TASKCHK(ta) != taskspin.FREE || taskspin.TASKCHK(tb) != taskspin.FREE
    assert(taskspin.TASKNEXT() >= 0)
end

assert(a["n"] == 2)
assert(b["n"] == 3)
assert(log == ["b1", "a1", "b2", "a2", "b3"])
assert(taskspin.TASKNEXT() == -1)

var info2 = taskspin.info()
assert(info2["max_tasks"] == 32)
assert(info2["tasks"] == 0)
assert(info2["storage"] == "sd")

print("P2_SMOKE_PASS libraries")
