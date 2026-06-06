var taskspin = run_file("modules/taskspin.be")

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
assert(ta == 0)
assert(tb == 1)
assert(taskspin.task_info(ta)["stack_address"] == 287)
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

var info = taskspin.info()
assert(info["max_tasks"] == 32)
assert(info["tasks"] == 0)
assert(info["halt_mask"] == 0)
assert(info["task_pointer_registers"] == "$11F..$100")
assert(info["storage"] == "sd")
