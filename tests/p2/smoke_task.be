print("P2_SMOKE_BEGIN task")

import task

task.reset()

log = []

def step(name, limit)
    n = task.task_info(task.current())["runs"]
    log.push(name + str(n))
    if n >= limit
        return task.done
    end
    return task.again
end

a = task.start(step, "a", 2)
b = task.start(step, "b", 3)
assert(a >= 0 && b >= 0 && a != b)
assert(task.status(a) == "ready")
assert(task.run(8) >= 5)
assert(task.status(a) == "free")
assert(task.status(b) == "free")
assert(log == ["a1", "b1", "a2", "b2", "b3"])

task.reset()
woke = {"event": false, "timeout": false}

def waiter(state)
    if task.woke_by_event("go")
        state["event"] = true
        return task.done
    end
    return task.wait("go", 1000)
end

w = task.start(waiter, woke)
assert(task.next() == w)
assert(task.status(w) == "waiting")
assert(task.signal("go"))
assert(task.next() == w)
assert(woke["event"])
assert(task.status(w) == "free")

task.reset()

def sleepy(state)
    if task.woke_by_timeout()
        state["timeout"] = true
        return task.done
    end
    return task.sleep(1)
end

s = task.start(sleepy, woke)
assert(task.next() == s)
assert(task.status(s) == "waiting")
task.run(10, 1)
assert(woke["timeout"])
assert(task.status(s) == "free")

sem = task.Semaphore(1)
assert(sem.take())
assert(!sem.take())
assert(sem.give())
assert(sem.value() == 1)
assert(sem.info()["kind"] == "Semaphore")

mutex = task.Mutex()
assert(mutex.lock())
assert(mutex.owner() == -1)
assert(!mutex.lock())
assert(mutex.unlock())
assert(!mutex.is_locked())

q = task.Queue(2)
assert(q.put("a"))
assert(q.put("b"))
assert(!q.put("c"))
assert(q.get() == "a")
assert(q.get() == "b")
assert(q.get() == nil)

flags = task.EventFlags()
assert(flags.set(0x03) == 0x03)
assert(flags.ready(0x03, "all"))
assert(flags.clear(0x01) == 0x02)
assert(!flags.ready(0x03, "all"))

timer = task.Timer(1, false)
assert(timer.cancel())
assert(!timer.expired())
assert(timer.restart())

info = task.info()
assert(info["max_tasks"] == 16)
assert(info["preemptive"] == false)
assert(info["stackful"] == false)
print(info["backend"], info["uses_p2_counter"], info["uses_cog_attention"])

print("P2_SMOKE_PASS task")
