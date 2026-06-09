var task = run_file("modules/task.be")

task.reset()

var log = []

def step(name, limit)
    var n = task.task_info(task.current())["runs"]
    log.push(name + str(n))
    return n >= limit ? task.done : task.again
end

var a = task.start(step, "a", 2)
var b = task.start(step, "b", 3)
assert(a >= 0 && b >= 0 && a != b)
assert(task.status(a) == "ready")
assert(task.run(8) >= 5)
assert(task.status(a) == "free")
assert(task.status(b) == "free")
assert(log == ["a1", "b1", "a2", "b2", "b3"])

task.reset()
var woke = {"value": false}

def waiter(state)
    if task.woke_by_event("go")
        state["value"] = true
        return task.done
    end
    return task.wait("go", 1000)
end

var w = task.start(waiter, woke)
assert(task.next() == w)
assert(task.status(w) == "waiting")
assert(task.signal("go"))
assert(task.next() == w)
assert(woke["value"])
assert(task.status(w) == "free")

var sem = task.Semaphore(1)
assert(sem.take())
assert(!sem.take())
assert(sem.give())
assert(sem.value() == 1)
assert(sem.info()["kind"] == "Semaphore")

var mutex = task.Mutex()
assert(mutex.lock())
assert(mutex.owner() == -1)
assert(!mutex.lock())
assert(mutex.unlock())
assert(!mutex.is_locked())

var q = task.Queue(2)
assert(q.put("a"))
assert(q.put("b"))
assert(!q.put("c"))
assert(q.get() == "a")
assert(q.get() == "b")
assert(q.get() == nil)

var flags = task.EventFlags()
assert(flags.set(0x03) == 0x03)
assert(flags.ready(0x03, "all"))
assert(flags.clear(0x01) == 0x02)
assert(!flags.ready(0x03, "all"))

var timer = task.Timer(10, false)
assert(!timer.expired())
assert(timer.cancel())
assert(!timer.expired())
assert(timer.restart())

var info = task.info()
assert(info["max_tasks"] == 16)
assert(info["preemptive"] == false)
assert(info["stackful"] == false)
