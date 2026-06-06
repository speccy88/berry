var task = run_file("modules/task.be")

task.reset()

var log = []
var a = {"n": 0}
var b = {"n": 0}

def step_a(state)
    state["n"] += 1
    log.push("a" + str(state["n"]))
    return state["n"] >= 2 ? task.STOP : task.RUN
end

def step_b(state, label)
    state["n"] += 1
    log.push(label + str(state["n"]))
    return state["n"] >= 3 ? task.STOP : task.RUN
end

var ta = task.spin(-1, step_a, a, {"stack": 287})
var tb = task.spin(-1, step_b, b, "b", {"stack": 286})
assert(ta == 0)
assert(tb == 1)
assert(task.chk(ta) == task.RUNNING)
assert(task.chk(tb) == task.RUNNING)
assert(task.task_info(ta)["stack_address"] == 287)
assert(task.task_info(tb)["stack_address"] == 286)
assert(task.tasks().size() == 2)

assert(task.halt(ta))
assert(task.chk(ta) == task.HALTED)
assert(task.hlt() != 0)
assert(task.next() == tb)
assert(a["n"] == 0 && b["n"] == 1)
assert(task.cont(ta))

while task.chk(ta) != task.FREE || task.chk(tb) != task.FREE
    assert(task.next() >= 0)
end
assert(log == ["b1", "a1", "b2", "a2", "b3"])
assert(task.next() == -1)

var stopped = {"n": 0}
def nil_return_step(state)
    state["n"] += 1
end
var tn = task.spin(-1, nil_return_step, stopped)
assert(task.next() == tn)
assert(stopped["n"] == 1)
assert(task.chk(tn) == task.FREE)

var h1 = task.spin(-1, def () return task.HALT end)
var h2 = task.spin(-1, def () return task.HALT end)
assert(task.next() == h1)
assert(task.next() == h2)
assert(task.info()["all_halted"] == true)
assert(task.hlt() != 0)
assert(task.stop(h1))
assert(task.stop(h2))

var sem = task.Semaphore(1)
assert(sem.take())
assert(!sem.take())
assert(sem.value() == 0)
assert(sem.give())
assert(sem.value() == 1)

var mutex = task.Mutex()
assert(mutex.lock())
assert(!mutex.lock())
assert(mutex.is_locked())
assert(mutex.unlock())
assert(!mutex.is_locked())

var queue = task.Queue(2)
assert(queue.put("a"))
assert(queue.put("b"))
assert(!queue.put("c"))
assert(queue.size() == 2)
assert(queue.get() == "a")
assert(queue.get() == "b")
assert(queue.get() == nil)

var flags = task.EventFlags()
assert(flags.set(0x03) == 0x03)
assert(flags.wait(0x01))
assert(flags.clear(0x01) == 0x02)
assert(!flags.wait(0x01))

var timer = task.Timer(10, false)
assert(!timer.expired())
assert(timer.cancel())
assert(!timer.expired())
assert(timer.restart())
