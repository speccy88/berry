# Friendly cooperative task scheduler for the P2 Berry port.
#
# V1 is cooperative and current-VM: task functions run one step at a time and
# return scheduler instructions such as task.sleep(ms), task.wait(event),
# task.again, task.done, or task.paused. Timing and attention wakeups use the
# native P2 hardware module when it is available, with an optional time.clock()
# fallback for host tests.

var task = module("task")

task.MAX_TASKS = 32
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

task._bounded_attention_available = def()
    if !task._has_p2
        return false
    end
    var cog = nil
    try
        cog = task._p2.cog
    except .. as e, m
        return false
    end
    if type(cog) != "module"
        return false
    end
    try
        return type(cog.wait_attention_result) == "function"
    except .. as e, m
        return false
    end
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

task.reset_result = def()
    var before = task.info()
    task.reset()
    var after = task.info()
    return {
        "ok": true,
        "reset": true,
        "released_tasks": before["active"],
        "released_events": before["events"],
        "active_before": before["active"],
        "events_before": before["events"],
        "active_after": after["active"],
        "events_after": after["events"],
        "max_tasks": after["max_tasks"],
        "error": nil,
        "message": nil
    }
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

task._activate_slot = def(id, fn, args)
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

task._object_wait_deadline = def(a, b)
    if b == nil && type(a) == "int"
        return task._deadline(a)
    end
    return task._deadline(b)
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
    return task._activate_slot(id, fn, args)
end

task.start_result = def(fn, *args)
    if type(fn) != "function"
        return {
            "ok": false,
            "handle": -1,
            "error": "invalid_function",
            "message": "task function must be a function"
        }
    end
    if args.size() > 8
        return {
            "ok": false,
            "handle": -1,
            "error": "too_many_args",
            "message": "task functions support at most 8 startup arguments"
        }
    end
    var id = task._first_free()
    if id < 0
        return {
            "ok": false,
            "handle": -1,
            "error": "no_free_slot",
            "message": "no free task slots"
        }
    end
    task._activate_slot(id, fn, args)
    return {
        "ok": true,
        "handle": id,
        "error": nil,
        "message": nil
    }
end

task.spin = def(id, fn, *args)
    if id == -1
        if type(fn) != "function"
            return -1
        end
        var free = task._first_free()
        if free < 0
            return -1
        end
        return task._activate_slot(free, fn, args)
    end
    if !task._valid(id) || type(fn) != "function"
        return -1
    end
    var slot = task._tasks[id]
    if slot["status"] != task._FREE
        return -1
    end
    return task._activate_slot(id, fn, args)
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
            "deadline": task._object_wait_deadline(a, b)
        }
    elif k == "p2ipc_channel"
        return {
            "_task_wait": a == "send" || a == "put" ? "p2ipc_channel_send" : "p2ipc_channel_recv",
            "object": target,
            "deadline": task._object_wait_deadline(a, b)
        }
    elif k == "p2ipc_mailbox"
        return {
            "_task_wait": a == "put" || a == "send" ? "p2ipc_mailbox_put" : "p2ipc_mailbox_get",
            "object": target,
            "deadline": task._object_wait_deadline(a, b)
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

task.ready_result = def(target, a, b)
    var k = task._kind(target)
    if type(target) == "string"
        var ready = task._event_ready(target)
        return {
            "ok": ready,
            "ready": ready,
            "kind": "event",
            "wait": "event",
            "event": target,
            "mode": "event",
            "error": ready ? nil : "not_ready",
            "message": ready ? nil : "event is not signaled"
        }
    elif k == "flags"
        var mode = b == nil ? "any" : b
        var res = target.ready_result(a, mode)
        res["kind"] = "flags"
        res["wait"] = "flags"
        return res
    elif k == "queue"
        var mode = a == "put" ? "put" : "get"
        var can_get = target.size() > 0
        var can_put = target.free() > 0
        var ready = mode == "put" ? can_put : can_get
        return {
            "ok": ready,
            "ready": ready,
            "kind": "queue",
            "wait": mode == "put" ? "queue_put" : "queue_get",
            "mode": mode,
            "can_get": can_get,
            "can_put": can_put,
            "size": target.size(),
            "free": target.free(),
            "error": ready ? nil : "not_ready",
            "message": ready ? nil : "queue is not ready for the requested operation"
        }
    elif k == "p2ipc_channel"
        var channel_mode = a == "send" || a == "put" ? "send" : "recv"
        var ch = target.ready_result(channel_mode)
        ch["kind"] = "p2ipc_channel"
        ch["wait"] = channel_mode == "send" ? "p2ipc_channel_send" : "p2ipc_channel_recv"
        return ch
    elif k == "p2ipc_mailbox"
        var mailbox_mode = a == "put" || a == "send" ? "put" : "get"
        var mb = target.ready_result(mailbox_mode)
        mb["kind"] = "p2ipc_mailbox"
        mb["wait"] = mailbox_mode == "put" ? "p2ipc_mailbox_put" : "p2ipc_mailbox_get"
        return mb
    elif k == "sem"
        var sem_ready = target.value() > 0
        return {
            "ok": sem_ready,
            "ready": sem_ready,
            "kind": "semaphore",
            "wait": "sem",
            "mode": "take",
            "count": target.value(),
            "error": sem_ready ? nil : "not_ready",
            "message": sem_ready ? nil : "semaphore count is zero"
        }
    elif k == "mutex"
        var mutex_ready = !target.is_locked()
        return {
            "ok": mutex_ready,
            "ready": mutex_ready,
            "kind": "mutex",
            "wait": "mutex",
            "mode": "lock",
            "locked": target.is_locked(),
            "owner": target.owner(),
            "error": mutex_ready ? nil : "not_ready",
            "message": mutex_ready ? nil : "mutex is locked"
        }
    elif k == "timer"
        var timer_ready = target._ready()
        return {
            "ok": timer_ready,
            "ready": timer_ready,
            "kind": "timer",
            "wait": "timer",
            "mode": "expired",
            "active": target.info()["active"],
            "remaining_ms": target.remaining(),
            "error": timer_ready ? nil : "not_ready",
            "message": timer_ready ? nil : "timer has not expired"
        }
    end
    var event = str(target)
    var fallback_ready = task._event_ready(event)
    return {
        "ok": fallback_ready,
        "ready": fallback_ready,
        "kind": "event",
        "wait": "event",
        "event": event,
        "mode": "event",
        "error": fallback_ready ? nil : "not_ready",
        "message": fallback_ready ? nil : "event is not signaled"
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

task.clear_all = def()
    task._events = {}
    return true
end

task.events = def()
    var out = []
    for key : task._events.keys()
        if task._events[key]
            out.push(key)
        end
    end
    return out
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

task._p2ipc_wait_ready = def(obj, mode)
    var res = obj.ready_result(mode)
    if res["ok"]
        return res["ready"]
    end
    return res["error"] == "closed"
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
    elif wait == "p2ipc_channel_recv"
        return task._p2ipc_wait_ready(slot["wait_object"], "recv")
    elif wait == "p2ipc_channel_send"
        return task._p2ipc_wait_ready(slot["wait_object"], "send")
    elif wait == "p2ipc_mailbox_get"
        return task._p2ipc_wait_ready(slot["wait_object"], "get")
    elif wait == "p2ipc_mailbox_put"
        return task._p2ipc_wait_ready(slot["wait_object"], "put")
    elif wait == "sem"
        return slot["wait_object"].value() > 0
    elif wait == "mutex"
        return !slot["wait_object"].is_locked()
    elif wait == "timer"
        return slot["wait_object"]._ready()
    end
    return false
end

task._error_slot = def(slot, message)
    slot["status"] = task._ERROR
    slot["wait"] = ""
    slot["wait_event"] = nil
    slot["wait_object"] = nil
    slot["wait_mode"] = nil
    slot["wait_value"] = nil
    slot["deadline"] = nil
    slot["woke_timeout"] = false
    slot["woke_event"] = nil
    slot["last_error"] = message
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
            else
                try
                    if task._wait_ready(slot)
                        woke = true
                    end
                except .. as e, m
                    task._error_slot(slot, str(e) + ":" + str(m))
                end
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
    if wait != "sleep" && wait != "event" && wait != "flags" && wait != "queue_get" && wait != "queue_put" && wait != "p2ipc_channel_recv" && wait != "p2ipc_channel_send" && wait != "p2ipc_mailbox_get" && wait != "p2ipc_mailbox_put" && wait != "sem" && wait != "mutex" && wait != "timer"
        return task._error_slot(slot, "value_error:invalid task wait descriptor")
    end
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
        if !desc.contains("event")
            return task._error_slot(slot, "value_error:task event wait is missing event")
        end
        slot["wait_event"] = desc["event"]
    elif wait == "flags"
        if !desc.contains("object") || !desc.contains("mask")
            return task._error_slot(slot, "value_error:task flags wait is missing object or mask")
        end
        slot["wait_object"] = desc["object"]
        slot["wait_mode"] = desc["mode"]
        slot["wait_value"] = desc["mask"]
    elif wait == "queue_get" || wait == "queue_put" || wait == "p2ipc_channel_recv" || wait == "p2ipc_channel_send" || wait == "p2ipc_mailbox_get" || wait == "p2ipc_mailbox_put" || wait == "sem" || wait == "mutex" || wait == "timer"
        if !desc.contains("object")
            return task._error_slot(slot, "value_error:task object wait is missing object")
        end
        slot["wait_object"] = desc["object"]
    end
    return true
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

task.next_result = def()
    var live_before = task._live()
    var ran = task.next()
    var live_after = task._live()
    if ran < 0
        return {
            "ok": false,
            "ran": false,
            "handle": -1,
            "status": "idle",
            "live_before": live_before,
            "live_after": live_after,
            "ready_after": task.info()["ready"],
            "waiting_after": task.info()["waiting"],
            "error": "no_ready_task",
            "message": "no ready cooperative task was available"
        }
    end
    var slot = task._slot(ran)
    var status = slot == nil ? "invalid" : task._status_name(slot["status"])
    return {
        "ok": true,
        "ran": true,
        "handle": ran,
        "status": status,
        "live_before": live_before,
        "live_after": live_after,
        "ready_after": task.info()["ready"],
        "waiting_after": task.info()["waiting"],
        "runs": slot == nil ? 0 : slot["runs"],
        "last_error": slot == nil ? "" : slot["last_error"],
        "last_result": slot == nil ? nil : slot["last_result"],
        "error": nil,
        "message": nil
    }
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

task.run_result = def(max_steps, idle_ms)
    var live_before = task._live()
    var steps = task.run(max_steps, idle_ms)
    var live_after = task._live()
    var info = task.info()
    return {
        "ok": true,
        "steps": steps,
        "max_steps": max_steps,
        "idle_ms": idle_ms == nil ? 1 : idle_ms,
        "live_before": live_before,
        "live_after": live_after,
        "ready_after": info["ready"],
        "waiting_after": info["waiting"],
        "paused_after": info["paused"],
        "errors_after": info["errors"],
        "complete": live_after == 0
    }
end

task.stop = def(handle)
    var id = task._resolve(handle)
    var slot = task._slot(id)
    if slot == nil || slot["status"] == task._FREE
        return false
    end
    return task._free(slot)
end

task.stop_result = def(handle)
    var id = task._resolve(handle)
    var slot = task._slot(id)
    if slot == nil
        return {
            "ok": false,
            "handle": id,
            "error": "invalid_handle",
            "message": "invalid task handle"
        }
    end
    var status = task._status_name(slot["status"])
    if slot["status"] == task._FREE
        return {
            "ok": false,
            "handle": id,
            "status": status,
            "error": "free",
            "message": "task slot is already free"
        }
    end
    task._free(slot)
    return {
        "ok": true,
        "handle": id,
        "previous_status": status,
        "status": "free",
        "error": nil,
        "message": nil
    }
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

task.pause_result = def(handle)
    var id = task._resolve(handle)
    var slot = task._slot(id)
    if slot == nil
        return {
            "ok": false,
            "handle": id,
            "error": "invalid_handle",
            "message": "invalid task handle"
        }
    end
    var status = task._status_name(slot["status"])
    if slot["status"] == task._FREE
        return {
            "ok": false,
            "handle": id,
            "status": status,
            "error": "free",
            "message": "task slot is free"
        }
    end
    if slot["status"] == task._PAUSED
        return {
            "ok": true,
            "handle": id,
            "previous_status": status,
            "status": status,
            "error": nil,
            "message": nil
        }
    end
    slot["status"] = task._PAUSED
    return {
        "ok": true,
        "handle": id,
        "previous_status": status,
        "status": "paused",
        "error": nil,
        "message": nil
    }
end

task.resume = def(handle)
    var slot = task._slot(handle)
    if slot == nil || slot["status"] != task._PAUSED
        return false
    end
    slot["status"] = task._READY
    return true
end

task.resume_result = def(handle)
    var slot = task._slot(handle)
    if slot == nil
        return {
            "ok": false,
            "handle": handle,
            "error": "invalid_handle",
            "message": "invalid task handle"
        }
    end
    var status = task._status_name(slot["status"])
    if slot["status"] != task._PAUSED
        return {
            "ok": false,
            "handle": handle,
            "status": status,
            "error": "not_paused",
            "message": "task is not paused"
        }
    end
    slot["status"] = task._READY
    return {
        "ok": true,
        "handle": handle,
        "previous_status": status,
        "status": "ready",
        "error": nil,
        "message": nil
    }
end

task.halt = def(handle)
    return task.pause(handle)
end

task.hlt = def(handle)
    return task.halt(handle)
end

task.cont = def(handle)
    return task.resume(handle)
end

task.chk = def(handle)
    var slot = task._slot(handle)
    return slot != nil && slot["status"] != task._FREE
end

task.id = def()
    return task._current
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

task._wait_target_kind = def(obj)
    if obj == nil
        return nil
    end
    var k = task._kind(obj)
    if k != nil
        return k
    end
    return type(obj)
end

task._wait_lifecycle = def(slot)
    var deadline = slot["deadline"]
    return {
        "wait": slot["wait"],
        "waiting": slot["status"] == task._WAITING,
        "wait_event": slot["wait_event"],
        "wait_mode": slot["wait_mode"],
        "wait_value": slot["wait_value"],
        "wait_target_kind": task._wait_target_kind(slot["wait_object"]),
        "has_deadline": deadline != nil,
        "deadline": deadline,
        "remaining_ms": deadline == nil ? nil : (deadline - task.millis()),
        "woke_timeout": slot["woke_timeout"],
        "woke_event": slot["woke_event"]
    }
end

task.lifecycle_result = def(handle)
    var id = task._resolve(handle)
    var slot = task._slot(id)
    if slot == nil
        return {
            "ok": false,
            "handle": id,
            "allocated": false,
            "status": "invalid",
            "current_vm": true,
            "current": false,
            "error": "invalid_handle",
            "message": "invalid task handle"
        }
    end
    var status = task._status_name(slot["status"])
    var allocated = slot["status"] != task._FREE
    var wait = task._wait_lifecycle(slot)
    return {
        "ok": true,
        "handle": id,
        "allocated": allocated,
        "status": status,
        "current_vm": true,
        "current": id == task._current,
        "running": slot["status"] == task._READY,
        "waiting": slot["status"] == task._WAITING,
        "paused": slot["status"] == task._PAUSED,
        "error_state": slot["status"] == task._ERROR,
        "runs": slot["runs"],
        "wakeups": slot["wakeups"],
        "last_error": slot["last_error"],
        "last_result": slot["last_result"],
        "wait": wait["wait"],
        "wait_event": wait["wait_event"],
        "wait_mode": wait["wait_mode"],
        "wait_value": wait["wait_value"],
        "wait_target_kind": wait["wait_target_kind"],
        "has_deadline": wait["has_deadline"],
        "deadline": wait["deadline"],
        "remaining_ms": wait["remaining_ms"],
        "woke_timeout": wait["woke_timeout"],
        "woke_event": wait["woke_event"],
        "error": allocated ? nil : "free",
        "message": allocated ? nil : "task slot is free"
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

task.tasks = def()
    return task.list()
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

task.capabilities = def()
    var bounded_attention = task._bounded_attention_available()
    return {
        "cooperative": true,
        "scheduler_policy": "current_vm_callback_step",
        "unsupported_reason": "independent stacks, preemption, and true Spin2/PASM task switching are not implemented",
        "self_test_result": true,
        "self_test_policy": "bounded_current_vm_cleanup_diagnostic",
        "preemptive": false,
        "stackful": false,
        "current_vm": true,
        "independent_stacks": false,
        "events": true,
        "event_diagnostics": true,
        "clear_all_events": true,
        "reset_result": true,
        "result_diagnostics": true,
        "task_lifecycle_result": true,
        "scheduler_step_result": true,
        "scheduler_run_result": true,
        "wait_readiness_result": true,
        "wait_descriptors": true,
        "contract": true,
        "audit": true,
        "spin": true,
        "spin2_lifecycle_names": true,
        "semaphore": true,
        "mutex": true,
        "queue": true,
        "event_flags": true,
        "timer": true,
        "max_tasks": task.MAX_TASKS,
        "p2_counter": task._has_p2,
        "p2_attention": task._has_p2,
        "attention_policy": "native_attention_event_current_vm_only",
        "bounded_attention_wait": bounded_attention,
        "cross_cog_attention_wakeup": false
    }
end

task.attention_policy = def()
    return {
        "policy": "native_attention_event_current_vm_only",
        "event": "attention",
        "signal_uses_cog_attention": task._has_p2,
        "poll_uses_cog_attention": task._has_p2,
        "bounded_attention_wait": task._bounded_attention_available(),
        "wait_helper": "p2.cog.wait_attention_result",
        "cross_cog_wakeup": false,
        "current_vm_only": true,
        "reason": "task.wait(\"attention\") is a current-VM cooperative event that polls native cog attention when p2 is available; it is not a cross-cog task wakeup contract"
    }
end

task.attention_policy_value = def(name)
    if type(name) != "string"
        return nil
    end
    var policy = task.attention_policy()
    if policy.contains(name)
        return policy[name]
    end
    return nil
end

task.required_attention_policy_keys = def()
    return [
        "policy",
        "event",
        "signal_uses_cog_attention",
        "poll_uses_cog_attention",
        "bounded_attention_wait",
        "wait_helper",
        "cross_cog_wakeup",
        "current_vm_only",
        "reason"
    ]
end

task.capability = def(name)
    if type(name) != "string"
        return nil
    end
    var caps = task.capabilities()
    if caps.contains(name)
        return caps[name]
    end
    return nil
end

task.required_capability_keys = def()
    return [
        "cooperative",
        "scheduler_policy",
        "unsupported_reason",
        "self_test_result",
        "self_test_policy",
        "preemptive",
        "stackful",
        "current_vm",
        "independent_stacks",
        "events",
        "event_diagnostics",
        "clear_all_events",
        "reset_result",
        "result_diagnostics",
        "task_lifecycle_result",
        "scheduler_step_result",
        "scheduler_run_result",
        "wait_readiness_result",
        "wait_descriptors",
        "contract",
        "audit",
        "spin",
        "spin2_lifecycle_names",
        "semaphore",
        "mutex",
        "queue",
        "event_flags",
        "timer",
        "max_tasks",
        "p2_counter",
        "p2_attention",
        "attention_policy",
        "bounded_attention_wait",
        "cross_cog_attention_wakeup"
    ]
end

task.contract = def()
    var attention = task.attention_policy()
    return {
        "ok": true,
        "model": "cooperative_step",
        "scheduler_policy": "current_vm_callback_step",
        "current_vm": true,
        "cooperative": true,
        "callback_step_scheduler": true,
        "preemptive": false,
        "stackful": false,
        "independent_stacks": false,
        "independent_vm_per_task": false,
        "true_spin2_task_switching": false,
        "max_tasks": task.MAX_TASKS,
        "spin2_compatible_names": true,
        "primitive_families": ["Semaphore", "Mutex", "Queue", "EventFlags", "Timer"],
        "wait_descriptors": true,
        "reset_result": true,
        "result_diagnostics": true,
        "task_lifecycle_result": true,
        "scheduler_step_result": true,
        "scheduler_run_result": true,
        "wait_readiness_result": true,
        "unsupported_reason": "independent stacks, preemption, and true Spin2/PASM task switching are not implemented",
        "sharing_policy": "current_vm_objects_only",
        "cross_vm_serialization": false,
        "cross_cog_wakeup": false,
        "attention_policy": attention["policy"],
        "bounded_attention_wait": attention["bounded_attention_wait"],
        "cross_cog_attention_wakeup": attention["cross_cog_wakeup"]
    }
end

task.contract_value = def(name)
    if type(name) != "string"
        return nil
    end
    var contract = task.contract()
    if contract.contains(name)
        return contract[name]
    end
    return nil
end

task.required_contract_keys = def()
    return [
        "ok",
        "model",
        "scheduler_policy",
        "current_vm",
        "cooperative",
        "callback_step_scheduler",
        "preemptive",
        "stackful",
        "independent_stacks",
        "independent_vm_per_task",
        "true_spin2_task_switching",
        "max_tasks",
        "spin2_compatible_names",
        "primitive_families",
        "wait_descriptors",
        "reset_result",
        "result_diagnostics",
        "task_lifecycle_result",
        "scheduler_step_result",
        "scheduler_run_result",
        "wait_readiness_result",
        "unsupported_reason",
        "sharing_policy",
        "cross_vm_serialization",
        "cross_cog_wakeup",
        "attention_policy",
        "bounded_attention_wait",
        "cross_cog_attention_wakeup"
    ]
end

task.execution_model = def()
    var attention = task.attention_policy()
    return {
        "model": "cooperative_step",
        "backend": task._has_p2 ? "p2_native_cooperative" : "host_cooperative",
        "current_vm": true,
        "cooperative": true,
        "callback_step_scheduler": true,
        "scheduler_policy": "current_vm_callback_step",
        "unsupported_reason": "independent stacks, preemption, and true Spin2/PASM task switching are not implemented",
        "preemptive": false,
        "stackful": false,
        "independent_stacks": false,
        "independent_vm_per_task": false,
        "spin2_compatible_names": true,
        "true_spin2_task_switching": false,
        "max_tasks": task.MAX_TASKS,
        "uses_p2_counter": task._has_p2,
        "uses_cog_attention": task._has_p2,
        "bounded_attention_wait": attention["bounded_attention_wait"],
        "cross_cog_attention_wakeup": attention["cross_cog_wakeup"]
    }
end

task.execution_model_value = def(name)
    if type(name) != "string"
        return nil
    end
    var model = task.execution_model()
    if model.contains(name)
        return model[name]
    end
    return nil
end

task.primitive_capabilities = def()
    return {
        "semaphore": true,
        "semaphore_take_result": true,
        "semaphore_give_result": true,
        "mutex": true,
        "mutex_lock_result": true,
        "mutex_unlock_result": true,
        "queue": true,
        "queue_put_result": true,
        "queue_get_result": true,
        "p2ipc_channel_wait": true,
        "p2ipc_mailbox_wait": true,
        "p2ipc_closed_wait_wakeup": true,
        "event_flags": true,
        "event_flags_set_result": true,
        "event_flags_clear_result": true,
        "event_flags_ready_result": true,
        "timer": true,
        "timer_expired_result": true,
        "timer_cancel_result": true,
        "timer_restart_result": true,
        "timer_remaining_result": true
    }
end

task.required_primitive_capability_keys = def()
    return [
        "semaphore",
        "semaphore_take_result",
        "semaphore_give_result",
        "mutex",
        "mutex_lock_result",
        "mutex_unlock_result",
        "queue",
        "queue_put_result",
        "queue_get_result",
        "p2ipc_channel_wait",
        "p2ipc_mailbox_wait",
        "p2ipc_closed_wait_wakeup",
        "event_flags",
        "event_flags_set_result",
        "event_flags_clear_result",
        "event_flags_ready_result",
        "timer",
        "timer_expired_result",
        "timer_cancel_result",
        "timer_restart_result",
        "timer_remaining_result"
    ]
end

task.primitive_capability = def(name)
    if type(name) != "string"
        return nil
    end
    var caps = task.primitive_capabilities()
    if caps.contains(name)
        return caps[name]
    end
    return nil
end

task.audit = def()
    var caps = task.capabilities()
    var attention = task.attention_policy()
    var primitive_caps = task.primitive_capabilities()
    var model = task.execution_model()
    var contract = task.contract()
    var problems = []
    var missing_capability_keys = []
    var missing_attention_policy_keys = []
    var missing_primitive_capability_keys = []
    var missing_contract_keys = []

    for key : task.required_capability_keys()
        if !caps.contains(key)
            missing_capability_keys.push(key)
        end
    end
    for key : task.required_attention_policy_keys()
        if !attention.contains(key)
            missing_attention_policy_keys.push(key)
        end
    end
    for key : task.required_primitive_capability_keys()
        if !primitive_caps.contains(key)
            missing_primitive_capability_keys.push(key)
        end
    end
    for key : task.required_contract_keys()
        if !contract.contains(key)
            missing_contract_keys.push(key)
        end
    end

    if missing_capability_keys.size() > 0
        problems.push("missing_capability_keys")
    end
    if missing_attention_policy_keys.size() > 0
        problems.push("missing_attention_policy_keys")
    end
    if missing_primitive_capability_keys.size() > 0
        problems.push("missing_primitive_capability_keys")
    end
    if missing_contract_keys.size() > 0
        problems.push("missing_contract_keys")
    end

    if !caps["cooperative"] || !model["cooperative"]
        problems.push("cooperative_not_enabled")
    end
    if !caps["contract"] || !contract["ok"]
        problems.push("contract_not_enabled")
    end
    if caps["scheduler_policy"] != model["scheduler_policy"]
        problems.push("scheduler_policy_mismatch")
    end
    if contract["scheduler_policy"] != model["scheduler_policy"]
        problems.push("contract_scheduler_policy_mismatch")
    end
    if caps["scheduler_policy"] != "current_vm_callback_step"
        problems.push("scheduler_policy_unexpected")
    end
    if contract["model"] != model["model"]
        problems.push("contract_model_mismatch")
    end
    if !model["callback_step_scheduler"]
        problems.push("callback_step_scheduler_not_enabled")
    end
    if !contract["callback_step_scheduler"]
        problems.push("contract_callback_step_scheduler_not_enabled")
    end
    if caps["unsupported_reason"] != model["unsupported_reason"]
        problems.push("unsupported_reason_mismatch")
    end
    if contract["unsupported_reason"] != model["unsupported_reason"]
        problems.push("contract_unsupported_reason_mismatch")
    end
    if caps["preemptive"] || model["preemptive"]
        problems.push("preemptive_enabled")
    end
    if contract["preemptive"]
        problems.push("contract_preemptive_enabled")
    end
    if caps["stackful"] || model["stackful"]
        problems.push("stackful_enabled")
    end
    if contract["stackful"]
        problems.push("contract_stackful_enabled")
    end
    if caps["independent_stacks"] || model["independent_stacks"]
        problems.push("independent_stacks_enabled")
    end
    if contract["independent_stacks"]
        problems.push("contract_independent_stacks_enabled")
    end
    if model["independent_vm_per_task"]
        problems.push("independent_vm_per_task_enabled")
    end
    if contract["independent_vm_per_task"]
        problems.push("contract_independent_vm_per_task_enabled")
    end
    if model["true_spin2_task_switching"]
        problems.push("true_spin2_task_switching_enabled")
    end
    if contract["true_spin2_task_switching"]
        problems.push("contract_true_spin2_task_switching_enabled")
    end
    if caps["max_tasks"] != task.MAX_TASKS || model["max_tasks"] != task.MAX_TASKS
        problems.push("max_tasks_mismatch")
    end
    if contract["max_tasks"] != task.MAX_TASKS
        problems.push("contract_max_tasks_mismatch")
    end
    if caps["spin"] != model["spin2_compatible_names"] || !caps["spin2_lifecycle_names"]
        problems.push("spin2_lifecycle_mismatch")
    end
    if contract["cross_vm_serialization"] || contract["cross_cog_wakeup"]
        problems.push("contract_cross_vm_or_cog_enabled")
    end
    if contract["cross_cog_attention_wakeup"]
        problems.push("cross_cog_attention_wakeup_enabled")
    end
    if caps["attention_policy"] != contract["attention_policy"]
        problems.push("attention_policy_mismatch")
    end
    if caps["attention_policy"] != attention["policy"] || contract["attention_policy"] != attention["policy"]
        problems.push("attention_policy_name_mismatch")
    end
    if attention["cross_cog_wakeup"]
        problems.push("attention_cross_cog_wakeup_enabled")
    end
    if caps["bounded_attention_wait"] != model["bounded_attention_wait"] || caps["bounded_attention_wait"] != contract["bounded_attention_wait"]
        problems.push("bounded_attention_wait_mismatch")
    end
    if caps["bounded_attention_wait"] != attention["bounded_attention_wait"]
        problems.push("attention_bounded_wait_mismatch")
    end
    if caps["cross_cog_attention_wakeup"] != model["cross_cog_attention_wakeup"] || caps["cross_cog_attention_wakeup"] != contract["cross_cog_attention_wakeup"]
        problems.push("cross_cog_attention_wakeup_mismatch")
    end
    if caps["cross_cog_attention_wakeup"] != attention["cross_cog_wakeup"]
        problems.push("attention_cross_cog_wakeup_mismatch")
    end
    if caps["semaphore"] != primitive_caps["semaphore"]
        problems.push("semaphore_capability_mismatch")
    end
    if caps["mutex"] != primitive_caps["mutex"]
        problems.push("mutex_capability_mismatch")
    end
    if caps["queue"] != primitive_caps["queue"]
        problems.push("queue_capability_mismatch")
    end
    if caps["event_flags"] != primitive_caps["event_flags"]
        problems.push("event_flags_capability_mismatch")
    end
    if caps["timer"] != primitive_caps["timer"]
        problems.push("timer_capability_mismatch")
    end
    if !primitive_caps["queue_get_result"] || !primitive_caps["timer_remaining_result"]
        problems.push("primitive_result_helpers_missing")
    end
    if !caps["reset_result"] || !contract["reset_result"]
        problems.push("reset_result_missing")
    end
    if !primitive_caps["p2ipc_closed_wait_wakeup"]
        problems.push("p2ipc_closed_wait_wakeup_missing")
    end
    if !caps["scheduler_step_result"] || !caps["scheduler_run_result"] || !contract["scheduler_step_result"] || !contract["scheduler_run_result"]
        problems.push("scheduler_result_helpers_missing")
    end
    if !caps["task_lifecycle_result"] || !contract["task_lifecycle_result"]
        problems.push("task_lifecycle_result_missing")
    end
    if !caps["wait_readiness_result"] || !contract["wait_readiness_result"]
        problems.push("wait_readiness_result_missing")
    end

    return {
        "ok": problems.size() == 0,
        "problem_count": problems.size(),
        "problems": problems,
        "model": model["model"],
        "scheduler_policy": model["scheduler_policy"],
        "cooperative": model["cooperative"],
        "preemptive": model["preemptive"],
        "stackful": model["stackful"],
        "bounded_attention_wait": model["bounded_attention_wait"],
        "cross_cog_attention_wakeup": model["cross_cog_attention_wakeup"],
        "task_lifecycle_result": contract["task_lifecycle_result"],
        "attention_policy": attention,
        "contract": contract,
        "missing_capability_keys": missing_capability_keys,
        "missing_attention_policy_keys": missing_attention_policy_keys,
        "missing_primitive_capability_keys": missing_primitive_capability_keys,
        "missing_contract_keys": missing_contract_keys,
        "max_tasks": model["max_tasks"],
        "primitive_families": caps["semaphore"] && caps["mutex"] && caps["queue"] && caps["event_flags"] && caps["timer"]
    }
end

task.audit_problems = def()
    var out = []
    for problem : task.audit()["problems"]
        out.push(problem)
    end
    return out
end

task.audit_ok = def()
    return task.audit_problems().size() == 0
end

task.self_test_result = def(iterations)
    if iterations == nil
        iterations = 1
    end
    if type(iterations) != "int" || iterations < 0
        return {
            "ok": false,
            "error": "invalid_iterations",
            "message": "iterations must be a non-negative integer",
            "iterations": 0,
            "checks": 0,
            "failures": [],
            "failure_count": 0,
            "policy": "bounded_current_vm_cleanup_diagnostic",
            "cleanup_reset": false,
            "active_after": task.info()["active"],
            "events_after": task.info()["events"]
        }
    end
    if iterations > 32
        iterations = 32
    end

    var failures = []
    var checks = 0

    def expect(cond, label)
        checks += 1
        if !cond
            failures.push(label)
        end
    end

    def self_step(state, limit)
        state["runs"] += 1
        if state["runs"] >= limit
            return task.done
        end
        return task.again
    end

    var i = 0
    while i < iterations
        var label = "iter_" + str(i) + "_"
        task.reset()

        var state = {"runs": 0}
        var started = task.start_result(self_step, state, 2)
        expect(started["ok"], label + "task_start")
        if started["ok"]
            expect(task.run(4, 0) >= 2, label + "task_run")
            expect(state["runs"] == 2, label + "task_runs")
            expect(task.status(started["handle"]) == "free", label + "task_cleanup")
        end

        var q = task.Queue(1)
        expect(q.put_result(i)["ok"], label + "queue_put")
        var q_get = q.get_result()
        expect(q_get["ok"] && q_get["value"] == i, label + "queue_get")
        expect(q.get_result()["error"] == "empty", label + "queue_empty")

        var sem = task.Semaphore(1)
        expect(sem.take_result()["ok"], label + "sem_take")
        expect(sem.take_result()["error"] == "unavailable", label + "sem_unavailable")
        expect(sem.give_result()["ok"], label + "sem_give")

        var mx = task.Mutex()
        expect(mx.lock_result()["ok"], label + "mutex_lock")
        expect(mx.lock_result()["error"] == "busy", label + "mutex_busy")
        expect(mx.unlock_result()["ok"], label + "mutex_unlock")

        var flags = task.EventFlags()
        expect(flags.set_result(1)["ok"], label + "flags_set")
        expect(flags.ready_result(1, "all")["ready"], label + "flags_ready")
        expect(flags.clear_result(1)["ok"], label + "flags_clear")

        var timer = task.Timer(0, false)
        var expired = timer.expired_result()
        expect(expired["ok"] && expired["expired"] && !expired["active"], label + "timer_expired")
        var remaining = timer.remaining_result()
        expect(!remaining["ok"] && remaining["error"] == "inactive", label + "timer_inactive")

        task.signal("self_test_event")
        expect(task.events().size() == 1, label + "event_signal")
        expect(task.clear_all(), label + "event_clear_all")
        expect(task.events().size() == 0, label + "event_cleared")

        i += 1
    end

    task.reset()
    var after = task.info()
    if after["active"] != 0
        failures.push("cleanup_active_after")
    end
    if after["events"] != 0
        failures.push("cleanup_events_after")
    end

    return {
        "ok": failures.size() == 0,
        "error": failures.size() == 0 ? nil : "self_test_failed",
        "message": failures.size() == 0 ? nil : "one or more cooperative task cleanup checks failed",
        "iterations": iterations,
        "checks": checks,
        "failures": failures,
        "failure_count": failures.size(),
        "policy": "bounded_current_vm_cleanup_diagnostic",
        "cleanup_reset": true,
        "active_after": after["active"],
        "events_after": after["events"]
    }
end

class Semaphore
    var _task_kind
    var count
    def init(count)
        self._task_kind = "sem"
        if count == nil
            self.count = 1
        elif type(count) != "int" || count < 0
            self.count = 0
        else
            self.count = count
        end
    end
    def take(timeout_ms)
        if self.count > 0
            self.count -= 1
            return true
        end
        return false
    end
    def take_result(timeout_ms)
        if self.count > 0
            self.count -= 1
            return { "ok": true, "count": self.count, "error": nil, "message": nil }
        end
        return { "ok": false, "count": self.count, "error": "unavailable", "message": "semaphore count is zero" }
    end
    def give()
        self.count += 1
        return true
    end
    def give_result()
        self.count += 1
        return { "ok": true, "count": self.count, "error": nil, "message": nil }
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
    def lock_result()
        if self.locked
            return { "ok": false, "locked": self.locked, "owner": self.owner_id, "error": "busy", "message": "mutex is already locked" }
        end
        self.locked = true
        self.owner_id = task.current()
        return { "ok": true, "locked": self.locked, "owner": self.owner_id, "error": nil, "message": nil }
    end
    def unlock()
        if !self.locked
            return false
        end
        self.locked = false
        self.owner_id = -1
        return true
    end
    def unlock_result()
        if !self.locked
            return { "ok": false, "locked": self.locked, "owner": self.owner_id, "error": "not_locked", "message": "mutex is not locked" }
        end
        var previous_owner = self.owner_id
        self.locked = false
        self.owner_id = -1
        return { "ok": true, "locked": self.locked, "owner": self.owner_id, "previous_owner": previous_owner, "error": nil, "message": nil }
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
        if depth == nil
            self.depth = task.MAX_QUEUE_DEPTH
        elif type(depth) != "int" || depth < 0
            self.depth = 0
        else
            self.depth = depth
        end
        self.items = []
    end
    def put(value)
        if self.items.size() >= self.depth
            return false
        end
        self.items.push(value)
        return true
    end
    def put_result(value)
        if self.items.size() >= self.depth
            return { "ok": false, "value": value, "size": self.items.size(), "free": self.free(), "error": "full", "message": "queue is full" }
        end
        self.items.push(value)
        return { "ok": true, "value": value, "size": self.items.size(), "free": self.free(), "error": nil, "message": nil }
    end
    def get(timeout_ms)
        if self.items.size() <= 0
            return nil
        end
        return self.items.pop(0)
    end
    def get_result(timeout_ms)
        if self.items.size() <= 0
            return { "ok": false, "value": nil, "size": 0, "free": self.free(), "error": "empty", "message": "queue is empty" }
        end
        var value = self.items.pop(0)
        return { "ok": true, "value": value, "size": self.items.size(), "free": self.free(), "error": nil, "message": nil }
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
        self.flags = type(initial) == "int" ? initial : 0
        self._last_mask = 0
    end
    def set(mask)
        if type(mask) != "int"
            return self.flags
        end
        self.flags |= mask
        return self.flags
    end
    def set_result(mask)
        if type(mask) != "int"
            return { "ok": false, "value": self.flags, "mask": mask, "error": "invalid_mask", "message": "event flag mask must be an int" }
        end
        self.flags |= mask
        return { "ok": true, "value": self.flags, "mask": mask, "error": nil, "message": nil }
    end
    def clear(mask)
        if type(mask) != "int"
            return self.flags
        end
        self.flags &= ~mask
        return self.flags
    end
    def clear_result(mask)
        if type(mask) != "int"
            return { "ok": false, "value": self.flags, "mask": mask, "error": "invalid_mask", "message": "event flag mask must be an int" }
        end
        self.flags &= ~mask
        return { "ok": true, "value": self.flags, "mask": mask, "error": nil, "message": nil }
    end
    def value()
        return self.flags
    end
    def ready(mask, mode)
        if type(mask) != "int"
            return false
        end
        self._last_mask = mask
        if mode == "all"
            return (self.flags & mask) == mask
        end
        return (self.flags & mask) != 0
    end
    def ready_result(mask, mode)
        if type(mask) != "int"
            return { "ok": false, "ready": false, "value": self.flags, "mask": mask, "mode": mode, "error": "invalid_mask", "message": "event flag mask must be an int" }
        end
        var want_all = mode == "all"
        var is_ready = want_all ? ((self.flags & mask) == mask) : ((self.flags & mask) != 0)
        self._last_mask = mask
        return { "ok": is_ready, "ready": is_ready, "value": self.flags, "mask": mask, "mode": want_all ? "all" : "any", "error": is_ready ? nil : "not_ready", "message": is_ready ? nil : "event flags are not ready" }
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
        if period_ms == nil
            self.period_ms = 10
        elif type(period_ms) != "int" || period_ms < 0
            self.period_ms = 0
        else
            self.period_ms = period_ms
        end
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
    def expired_result()
        if !self._ready()
            return { "ok": false, "expired": false, "active": self.active, "repeat": self.repeat, "deadline": self.deadline, "error": "not_expired", "message": "timer has not expired" }
        end
        var previous_deadline = self.deadline
        if self.repeat
            self.deadline = task.millis() + self.period_ms
        else
            self.active = false
        end
        return { "ok": true, "expired": true, "active": self.active, "repeat": self.repeat, "deadline": self.deadline, "previous_deadline": previous_deadline, "error": nil, "message": nil }
    end
    def remaining()
        if !self.active
            return 0
        end
        var left = self.deadline - task.millis()
        return left > 0 ? left : 0
    end
    def remaining_result()
        var left = self.remaining()
        if !self.active
            return { "ok": false, "active": false, "remaining_ms": 0, "deadline": self.deadline, "period_ms": self.period_ms, "error": "inactive", "message": "timer is not active" }
        end
        return { "ok": true, "active": true, "remaining_ms": left, "deadline": self.deadline, "period_ms": self.period_ms, "error": nil, "message": nil }
    end
    def cancel()
        self.active = false
        return true
    end
    def cancel_result()
        var was_active = self.active
        self.active = false
        return { "ok": true, "active": self.active, "was_active": was_active, "deadline": self.deadline, "error": nil, "message": nil }
    end
    def restart()
        self.deadline = task.millis() + self.period_ms
        self.active = true
        return true
    end
    def restart_result()
        self.deadline = task.millis() + self.period_ms
        self.active = true
        return { "ok": true, "active": self.active, "deadline": self.deadline, "period_ms": self.period_ms, "error": nil, "message": nil }
    end
    def info()
        return { "kind": "Timer", "period_ms": self.period_ms, "repeat": self.repeat, "active": self.active, "deadline": self.deadline, "remaining_ms": self.remaining() }
    end
end

task.Semaphore = Semaphore
task.Mutex = Mutex
task.Queue = Queue
task.EventFlags = EventFlags
task.Timer = Timer

task.reset()

return task
