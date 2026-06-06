# Lower-case cooperative task facade for the P2 Berry port.
#
# This module is backed by taskspin's 32-slot scheduler. It provides the API
# shape requested by the P2 roadmap while staying honest about the current
# model: closures are cooperative step functions in the current VM, not
# independent stackful Berry VMs and not preemptive RTOS tasks.

import taskspin
import time

var task = module("task")

task.MAX_TASKS = taskspin.MAX_TASKS

task.FREE = taskspin.FREE
task.RUNNING = taskspin.RUNNING
task.HALTED = taskspin.HALTED

task.STOP = taskspin.STOP
task.RUN = taskspin.RUN
task.HALT = taskspin.HALT

task.reset = def()
    return taskspin.reset()
end

task._extract_stack = def(args)
    if args.size() <= 0
        return nil
    end
    var last = args[args.size() - 1]
    if type(last) == "map" && last.contains("stack")
        args.pop()
        return last["stack"]
    end
    return nil
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
    # Keep the v1 API bounded and deterministic. Larger argument packs are
    # still usable by passing a single list/map object.
    return task.STOP
end

task._step = def(id, state)
    var result = task._call(state["closure"], state["args"])
    if result == nil
        return task.STOP
    end
    return result
end

task.spin = def(task_id, closure, *args)
    var stack = task._extract_stack(args)
    return taskspin.taskspin(task_id, task._step, {
        "closure": closure,
        "args": args
    }, stack)
end

task.next = def()
    return taskspin.tasknext()
end

task.stop = def(task_id)
    return taskspin.taskstop(task_id)
end

task.halt = def(task_id)
    return taskspin.taskhalt(task_id, true)
end

task.cont = def(task_id)
    return taskspin.taskcont(task_id)
end

task.chk = def(task_id)
    return taskspin.taskchk(task_id)
end

task.id = def()
    return taskspin.taskid()
end

task.hlt = def()
    return taskspin.taskhlt()
end

task.halt_mask = task.hlt

task.info = def()
    var info = taskspin.info()
    info["module"] = "task"
    info["backend"] = "taskspin"
    info["all_halted"] = info["tasks"] > 0 && info["running"] == 0
    info["closure_model"] = "cooperative_step_closures"
    return info
end

task.tasks = def()
    return taskspin.tasks()
end

task.task_info = def(task_id)
    return taskspin.task_info(task_id)
end

class Semaphore
    var count
    def init(count)
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
end

class Mutex
    var locked
    def init()
        self.locked = false
    end
    def lock()
        if self.locked
            return false
        end
        self.locked = true
        return true
    end
    def unlock()
        if !self.locked
            return false
        end
        self.locked = false
        return true
    end
    def is_locked()
        return self.locked
    end
end

class Queue
    var depth
    var items
    def init(depth)
        self.depth = depth == nil ? 8 : depth
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
end

class EventFlags
    var flags
    def init()
        self.flags = 0
    end
    def set(mask)
        self.flags |= mask
        return self.flags
    end
    def clear(mask)
        self.flags &= ~mask
        return self.flags
    end
    def wait(mask, timeout_ms)
        return (self.flags & mask) == mask
    end
    def value()
        return self.flags
    end
end

class Timer
    var period_ms
    var repeat
    var deadline
    var active
    def init(period_ms, repeat)
        self.period_ms = period_ms == nil ? 10 : period_ms
        self.repeat = repeat == nil ? true : repeat
        self.deadline = time.clock() + real(self.period_ms) / 1000.0
        self.active = true
    end
    def expired()
        if !self.active
            return false
        end
        if time.clock() >= self.deadline
            if self.repeat
                self.deadline = time.clock() + real(self.period_ms) / 1000.0
            else
                self.active = false
            end
            return true
        end
        return false
    end
    def cancel()
        self.active = false
        return true
    end
    def restart()
        self.deadline = time.clock() + real(self.period_ms) / 1000.0
        self.active = true
        return true
    end
end

task.Semaphore = Semaphore
task.Mutex = Mutex
task.Queue = Queue
task.EventFlags = EventFlags
task.Timer = Timer

return task
