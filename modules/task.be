# Friendly cooperative task scheduler for the P2 Berry port.
#
# V1 is cooperative and current-VM: task functions run one step at a time and
# return scheduler instructions such as task.sleep(ms), task.wait(event),
# task.again, task.done, or task.paused. Timing and attention wakeups use the
# native P2 hardware module when it is available, with an optional time.clock()
# fallback for host tests.

var task = module("task")

task.MAX_TASKS = 16
task.MAX_EVENTS = 16
task.MAX_TIMERS = 16
task.MAX_QUEUE_DEPTH = 8

task.again = "__task_again__"
task.done = "__task_done__"
task.paused = "__task_paused__"
task.timeout = "timeout"
task.EVENT_ATN = 14

task._FREE = 0
task._READY = 1
task._PAUSED = 2
task._WAITING = 3
task._DONE = 4
task._ERROR = 5

task._p2 = nil
task._has_p2 = false
task._time = nil
task._has_time = false
task._tasks = []
task._current = -1
task._next = -1
task._events = {}

try
    import p2
    task._p2 = p2
    task._has_p2 = true
except .. as e, m
    task._p2 = nil
    task._has_p2 = false
end

try
    import time
    task._time = time
    task._has_time = true
except .. as e, m
    task._time = nil
    task._has_time = false
end

task._new_slot = def(id)
    return {
        "handle": id,
        "status": task._FREE,
        "fn": nil,
        "args": [],
        "wait": "",
        "wait_event": nil,
        "wait_object": nil,
        "wait_mode": nil,
        "wait_value": nil,
        "deadline": nil,
        "runs": 0,
        "wakeups": 0,
        "last_error": "",
        "last_result": nil,
        "woke_timeout": false,
        "woke_event": nil
    }
end

task.reset = def()
    task._tasks.clear()
    var i = 0
    while i < task.MAX_TASKS
        task._tasks.push(task._new_slot(i))
        i += 1
    end
    task._current = -1
    task._next = -1
    task._events = {}
    return true
end

task._valid = def(handle)
    return type(handle) == "int" && handle >= 0 && handle < task.MAX_TASKS
end

task._slot = def(handle)
    if !task._valid(handle)
        return nil
    end
    return task._tasks[handle]
end

task._resolve = def(handle)
    if handle == nil || handle == -1
        return task._current
    end
    return handle
end

task._first_free = def()
    var i = 0
    while i < task.MAX_TASKS
        if task._tasks[i]["status"] == task._FREE
            return i
        end
        i += 1
    end
    return -1
end

task._call = def(fn, args)
    var n = args.size()
    if n == 0
        return fn()
    elif n == 1
        return fn(args[0])
    elif n == 2
        return fn(args[0], args[1])
    elif n == 3
        return fn(args[0], args[1], args[2])
    elif n == 4
        return fn(args[0], args[1], args[2], args[3])
    elif n == 5
        return fn(args[0], args[1], args[2], args[3], args[4])
    elif n == 6
        return fn(args[0], args[1], args[2], args[3], args[4], args[5])
    elif n == 7
        return fn(args[0], args[1], args[2], args[3], args[4], args[5], args[6])
    elif n == 8
        return fn(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7])
    end
    return task.done
end

task.millis = def()
    if task._has_p2
        var hz = task._p2.clock_freq()
        if hz <= 0
            return 0
        end
        return int(task._p2.ticks() / (hz / 1000))
    end
    if task._has_time
        return int(task._time.clock() * 1000.0)
    end
    return 0
end

task._idle = def(ms)
    if ms == nil || ms <= 0
        return nil
    end
    if task._has_p2
        task._p2.clock.waitms(ms)
    end
    return nil
end

task._status_name = def(status)
    if status == task._FREE
        return "free"
    elif status == task._READY
        return "ready"
    elif status == task._WAITING
        return "waiting"
    elif status == task._PAUSED
        return "paused"
    elif status == task._DONE
        return "done"
    elif status == task._ERROR
        return "error"
    end
    return "unknown"
end

task._kind = def(obj)
    var k = nil
    try
        k = obj._task_kind
    except .. as e, m
        k = nil
    end
    return k
end

task._is_wait = def(obj)
    var ok = false
    try
        ok = obj.contains("_task_wait")
    except .. as e, m
        ok = false
    end
    return ok
end

task._deadline = def(timeout_ms)
    if timeout_ms == nil
        return nil
    end
    if timeout_ms < 0
        timeout_ms = 0
    end
    return task.millis() + timeout_ms
end

task._free = def(slot)
    slot["status"] = task._FREE
    slot["fn"] = nil
    slot["args"] = []
    slot["wait"] = ""
    slot["wait_event"] = nil
    slot["wait_object"] = nil
    slot["wait_mode"] = nil
    slot["wait_value"] = nil
    slot["deadline"] = nil
    slot["woke_timeout"] = false
    slot["woke_event"] = nil
    return true
end

task.start = def(fn, *args)
    if type(fn) != "function"
        return -1
    end
    var id = task._first_free()
    if id < 0
        return -1
    end
    var slot = task._tasks[id]
    slot["status"] = task._READY
    slot["fn"] = fn
    slot["args"] = args
    slot["wait"] = ""
    slot["runs"] = 0
    slot["wakeups"] = 0
    slot["last_error"] = ""
    slot["last_result"] = nil
    slot["woke_timeout"] = false
    slot["woke_event"] = nil
    return id
end

task.sleep = def(ms)
    if ms == nil || ms < 0
        ms = 0
    end
    return {
        "_task_wait": "sleep",
        "deadline": task.millis() + ms,
        "ms": ms
    }
end

task.wait = def(target, a, b)
    var k = task._kind(target)
    if type(target) == "string"
        return {
            "_task_wait": "event",
            "event": target,
            "deadline": task._deadline(a)
        }
    elif k == "flags"
        return {
            "_task_wait": "flags",
            "object": target,
            "mode": a == nil ? "any" : a,
            "mask": target._last_mask,
            "deadline": task._deadline(b)
        }
    elif k == "queue"
        return {
            "_task_wait": a == "put" ? "queue_put" : "queue_get",
            "object": target,
            "deadline": task._deadline(b)
        }
    elif k == "sem"
        return {
            "_task_wait": "sem",
            "object": target,
            "deadline": task._deadline(a)
        }
    elif k == "mutex"
        return {
            "_task_wait": "mutex",
            "object": target,
            "deadline": task._deadline(a)
        }
    elif k == "timer"
        return {
            "_task_wait": "timer",
            "object": target,
            "deadline": task._deadline(a)
        }
    end
    return {
        "_task_wait": "event",
        "event": str(target),
        "deadline": task._deadline(a)
    }
end

task.signal = def(event)
    if type(event) != "string"
        return false
    end
    task._events[event] = true
    if task._has_p2 && event == "attention"
        task._p2.cog.attention(1 << task._p2.cog.id())
    end
    return true
end

task.clear = def(event)
    if type(event) != "string"
        return false
    end
    if task._events.contains(event)
        task._events[event] = false
    end
    return true
end

task._poll_attention = def()
    if task._has_p2 && task._p2.cog.poll_attention() != 0
        task._events["attention"] = true
    end
end

task._event_ready = def(event)
    task._poll_attention()
    return task._events.contains(event) && task._events[event]
end

task._wait_ready = def(slot)
    var wait = slot["wait"]
    if wait == "sleep"
        return task.millis() >= slot["deadline"]
    elif wait == "event"
        return task._event_ready(slot["wait_event"])
    elif wait == "flags"
        return slot["wait_object"].ready(slot["wait_value"], slot["wait_mode"])
    elif wait == "queue_get"
        return slot["wait_object"].size() > 0
    elif wait == "queue_put"
        return slot["wait_object"].free() > 0
    elif wait == "sem"
        return slot["wait_object"].value() > 0
    elif wait == "mutex"
        return !slot["wait_object"].is_locked()
    elif wait == "timer"
        return slot["wait_object"]._ready()
    end
    return false
end

task._wake_waiting = def()
    var now = task.millis()
    for slot : task._tasks
        if slot["status"] == task._WAITING
            var woke = false
            var timeout = false
            if slot["deadline"] != nil && now >= slot["deadline"]
                woke = true
                timeout = true
            elif task._wait_ready(slot)
                woke = true
            end
            if woke
                slot["status"] = task._READY
                slot["wakeups"] += 1
                slot["woke_timeout"] = timeout
                slot["woke_event"] = timeout ? nil : slot["wait_event"]
                slot["wait"] = ""
                slot["wait_event"] = nil
                slot["wait_object"] = nil
                slot["wait_mode"] = nil
                slot["wait_value"] = nil
                slot["deadline"] = nil
            end
        end
    end
end

task._apply_wait = def(slot, desc)
    var wait = desc["_task_wait"]
    slot["status"] = task._WAITING
    slot["wait"] = wait
    slot["wait_event"] = nil
    slot["wait_object"] = nil
    slot["wait_mode"] = nil
    slot["wait_value"] = nil
    slot["deadline"] = desc.contains("deadline") ? desc["deadline"] : nil
    slot["woke_timeout"] = false
    slot["woke_event"] = nil
    if wait == "event"
        slot["wait_event"] = desc["event"]
    elif wait == "flags"
        slot["wait_object"] = desc["object"]
        slot["wait_mode"] = desc["mode"]
        slot["wait_value"] = desc["mask"]
    elif wait == "queue_get" || wait == "queue_put" || wait == "sem" || wait == "mutex" || wait == "timer"
        slot["wait_object"] = desc["object"]
    end
end

task._interpret = def(slot, result)
    slot["last_result"] = result
    if result == nil || result == false || result == task.done
        task._free(slot)
    elif result == task.paused || result == task.pause
        slot["status"] = task._PAUSED
    elif task._is_wait(result)
        task._apply_wait(slot, result)
    else
        slot["status"] = task._READY
    end
end

task._run_slot = def(id)
    var slot = task._tasks[id]
    var result = nil
    task._current = id
    slot["runs"] += 1
    try
        result = task._call(slot["fn"], slot["args"])
    except .. as e, m
        slot["status"] = task._ERROR
        slot["last_error"] = str(e) + ":" + str(m)
        task._current = -1
        return id
    end
    task._current = -1
    if slot["status"] == task._READY
        task._interpret(slot, result)
    end
    return id
end

task.next = def()
    task._wake_waiting()
    var i = 0
    while i < task.MAX_TASKS
        task._next = (task._next + 1) % task.MAX_TASKS
        var slot = task._tasks[task._next]
        if slot["status"] == task._READY
            return task._run_slot(task._next)
        end
        i += 1
    end
    return -1
end

task._live = def()
    var count = 0
    for slot : task._tasks
        if slot["status"] == task._READY || slot["status"] == task._WAITING
            count += 1
        end
    end
    return count
end

task.run = def(max_steps, idle_ms)
    var steps = 0
    var idle = idle_ms == nil ? 1 : idle_ms
    while max_steps == nil || steps < max_steps
        if task._live() <= 0
            break
        end
        var ran = task.next()
        steps += 1
        if ran < 0
            task._idle(idle)
        end
    end
    return steps
end

task.stop = def(handle)
    var id = task._resolve(handle)
    var slot = task._slot(id)
    if slot == nil || slot["status"] == task._FREE
        return false
    end
    return task._free(slot)
end

task.pause = def(handle)
    var id = task._resolve(handle)
    var slot = task._slot(id)
    if slot == nil || slot["status"] == task._FREE
        return false
    end
    slot["status"] = task._PAUSED
    return true
end

task.resume = def(handle)
    var slot = task._slot(handle)
    if slot == nil || slot["status"] != task._PAUSED
        return false
    end
    slot["status"] = task._READY
    return true
end

task.status = def(handle)
    var slot = task._slot(handle)
    if slot == nil
        return "free"
    end
    return task._status_name(slot["status"])
end

task.current = def()
    return task._current
end

task.woke_by_timeout = def()
    var slot = task._slot(task._current)
    return slot != nil && slot["woke_timeout"]
end

task.woke_by_event = def(event)
    var slot = task._slot(task._current)
    if slot == nil || slot["woke_event"] == nil
        return false
    end
    return event == nil || slot["woke_event"] == event
end

task.task_info = def(handle)
    var slot = task._slot(handle)
    if slot == nil
        return { "handle": handle, "status": "free" }
    end
    return {
        "handle": handle,
        "status": task._status_name(slot["status"]),
        "wait": slot["wait"],
        "running": slot["status"] == task._READY,
        "waiting": slot["status"] == task._WAITING,
        "paused": slot["status"] == task._PAUSED,
        "current": handle == task._current,
        "runs": slot["runs"],
        "wakeups": slot["wakeups"],
        "last_error": slot["last_error"]
    }
end

task.list = def()
    var out = []
    var i = 0
    while i < task.MAX_TASKS
        if task._tasks[i]["status"] != task._FREE
            out.push(task.task_info(i))
        end
        i += 1
    end
    return out
end

task.info = def()
    var active = 0, ready = 0, waiting = 0, paused = 0, errors = 0, events = 0
    for slot : task._tasks
        if slot["status"] != task._FREE
            active += 1
        end
        if slot["status"] == task._READY
            ready += 1
        elif slot["status"] == task._WAITING
            waiting += 1
        elif slot["status"] == task._PAUSED
            paused += 1
        elif slot["status"] == task._ERROR
            errors += 1
        end
    end
    for key : task._events.keys()
        if task._events[key]
            events += 1
        end
    end
    return {
        "backend": task._has_p2 ? "p2_native_cooperative" : "host_cooperative",
        "max_tasks": task.MAX_TASKS,
        "max_events": task.MAX_EVENTS,
        "max_timers": task.MAX_TIMERS,
        "max_queue_depth": task.MAX_QUEUE_DEPTH,
        "active": active,
        "ready": ready,
        "waiting": waiting,
        "paused": paused,
        "errors": errors,
        "events": events,
        "current": task._current,
        "uses_p2_counter": task._has_p2,
        "uses_cog_attention": task._has_p2,
        "preemptive": false,
        "stackful": false
    }
end

class Semaphore
    var _task_kind
    var count
    def init(count)
        self._task_kind = "sem"
        self.count = count == nil ? 1 : count
    end
    def take(timeout_ms)
        if self.count > 0
            self.count -= 1
            return true
        end
        return false
    end
    def give()
        self.count += 1
        return true
    end
    def value()
        return self.count
    end
    def info()
        return { "kind": "Semaphore", "count": self.count }
    end
end

class Mutex
    var _task_kind
    var locked
    var owner_id
    def init()
        self._task_kind = "mutex"
        self.locked = false
        self.owner_id = -1
    end
    def lock()
        if self.locked
            return false
        end
        self.locked = true
        self.owner_id = task.current()
        return true
    end
    def unlock()
        if !self.locked
            return false
        end
        self.locked = false
        self.owner_id = -1
        return true
    end
    def owner()
        return self.owner_id
    end
    def is_locked()
        return self.locked
    end
    def info()
        return { "kind": "Mutex", "locked": self.locked, "owner": self.owner_id }
    end
end

class Queue
    var _task_kind
    var depth
    var items
    def init(depth)
        self._task_kind = "queue"
        self.depth = depth == nil ? task.MAX_QUEUE_DEPTH : depth
        self.items = []
    end
    def put(value)
        if self.items.size() >= self.depth
            return false
        end
        self.items.push(value)
        return true
    end
    def get(timeout_ms)
        if self.items.size() <= 0
            return nil
        end
        return self.items.pop(0)
    end
    def size()
        return self.items.size()
    end
    def free()
        return self.depth - self.items.size()
    end
    def info()
        return { "kind": "Queue", "depth": self.depth, "size": self.items.size(), "free": self.free() }
    end
end

class EventFlags
    var _task_kind
    var flags
    var _last_mask
    def init(initial)
        self._task_kind = "flags"
        self.flags = initial == nil ? 0 : initial
        self._last_mask = 0
    end
    def set(mask)
        self.flags |= mask
        return self.flags
    end
    def clear(mask)
        self.flags &= ~mask
        return self.flags
    end
    def value()
        return self.flags
    end
    def ready(mask, mode)
        self._last_mask = mask
        if mode == "all"
            return (self.flags & mask) == mask
        end
        return (self.flags & mask) != 0
    end
    def wait(mask, timeout_ms)
        return self.ready(mask, "any")
    end
    def info()
        return { "kind": "EventFlags", "value": self.flags }
    end
end

class Timer
    var _task_kind
    var period_ms
    var repeat
    var deadline
    var active
    def init(period_ms, repeat)
        self._task_kind = "timer"
        self.period_ms = period_ms == nil ? 10 : period_ms
        self.repeat = repeat == nil ? true : repeat
        self.deadline = task.millis() + self.period_ms
        self.active = true
    end
    def _ready()
        return self.active && task.millis() >= self.deadline
    end
    def expired()
        if !self._ready()
            return false
        end
        if self.repeat
            self.deadline = task.millis() + self.period_ms
        else
            self.active = false
        end
        return true
    end
    def cancel()
        self.active = false
        return true
    end
    def restart()
        self.deadline = task.millis() + self.period_ms
        self.active = true
        return true
    end
    def info()
        return { "kind": "Timer", "period_ms": self.period_ms, "repeat": self.repeat, "active": self.active, "deadline": self.deadline }
    end
end

task.Semaphore = Semaphore
task.Mutex = Mutex
task.Queue = Queue
task.EventFlags = EventFlags
task.Timer = Timer

task.reset()

return task
