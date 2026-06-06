# Spin2-style cooperative task scheduler for Berry.
#
# This is intentionally a source module under /modules. It gives P2 programs a
# TASK* vocabulary without permanently spending Hub image space. Tasks are
# step closures in the current Berry VM; each TASKNEXT() calls one runnable
# task. This is cooperative callback scheduling, not stackful frame switching.

var taskspin = module("taskspin")

taskspin.MAX_TASKS = 32

taskspin.FREE = 0
taskspin.RUNNING = 1
taskspin.HALTED = 2

taskspin.STOP = 0
taskspin.RUN = 1
taskspin.HALT = 2

taskspin._tasks = []
taskspin._current = -1
taskspin._count = 0

taskspin.reset = def()
    taskspin._tasks.clear()
    for i : 0..taskspin.MAX_TASKS - 1
        taskspin._tasks.push(nil)
    end
    taskspin._current = -1
    taskspin._count = 0
end

taskspin._valid = def(task)
    return task >= 0 && task < taskspin.MAX_TASKS
end

taskspin._resolve = def(task)
    if task == -1
        return taskspin._current
    end
    return task
end

taskspin._first_free = def()
    for i : 0..taskspin.MAX_TASKS - 1
        if taskspin._tasks[i] == nil
            return i
        end
    end
    return -1
end

taskspin.taskspin = def(task, step, state, stack_address)
    if type(step) != "function"
        return -1
    end
    var slot = task
    if slot == -1
        slot = taskspin._first_free()
    elif !taskspin._valid(slot) || taskspin._tasks[slot] != nil
        return -1
    end
    if slot < 0
        return -1
    end
    taskspin._tasks[slot] = {
        "step": step,
        "state": state,
        "stack_address": stack_address,
        "status": taskspin.RUNNING
    }
    taskspin._count += 1
    return slot
end

taskspin.tasknext = def()
    if taskspin._count <= 0
        return -1
    end
    for i : 0..taskspin.MAX_TASKS - 1
        taskspin._current = (taskspin._current + 1) % taskspin.MAX_TASKS
        var task = taskspin._tasks[taskspin._current]
        if task != nil && task["status"] == taskspin.RUNNING
            var id = taskspin._current
            var result = task["step"](taskspin._current, task["state"])
            if taskspin._tasks[id] != nil && (result == taskspin.STOP || result == false)
                taskspin.taskstop(id)
            elif taskspin._tasks[id] != nil && result == taskspin.HALT
                taskspin.taskhalt(id, false)
            end
            if taskspin._tasks[id] == nil
                return id
            elif taskspin._tasks[id]["status"] == taskspin.HALTED
                return id
            else
                return taskspin._current
            end
        end
    end
    return -1
end

taskspin.taskhlt = def()
    var mask = 0
    for i : 0..taskspin.MAX_TASKS - 1
        var task = taskspin._tasks[i]
        if task != nil && task["status"] == taskspin.HALTED
            mask |= taskspin.halt_bit(i)
        end
    end
    return mask
end

taskspin.halt_bit = def(task)
    if !taskspin._valid(task)
        return 0
    end
    return 1 << (taskspin.MAX_TASKS - 1 - task)
end

taskspin.task_info = def(task)
    if !taskspin._valid(task) || taskspin._tasks[task] == nil
        return {
            "id": task,
            "status": taskspin.FREE
        }
    end
    var item = taskspin._tasks[task]
    return {
        "id": task,
        "status": item["status"],
        "halted": item["status"] == taskspin.HALTED,
        "running": item["status"] == taskspin.RUNNING,
        "stack_address": item["stack_address"],
        "current": task == taskspin._current
    }
end

taskspin.tasks = def()
    var out = []
    for i : 0..taskspin.MAX_TASKS - 1
        var item = taskspin.task_info(i)
        if item["status"] != taskspin.FREE
            out.push(item)
        end
    end
    return out
end

taskspin.taskstop = def(task)
    var slot = taskspin._resolve(task)
    if !taskspin._valid(slot) || taskspin._tasks[slot] == nil
        return false
    end
    taskspin._tasks[slot] = nil
    taskspin._count -= 1
    if taskspin._count <= 0
        taskspin._current = -1
    end
    return true
end

taskspin.taskhalt = def(task, switch_now)
    var slot = taskspin._resolve(task)
    if !taskspin._valid(slot) || taskspin._tasks[slot] == nil
        return false
    end
    taskspin._tasks[slot]["status"] = taskspin.HALTED
    if slot == taskspin._current && switch_now != false && taskspin._count > 1
        taskspin.tasknext()
    end
    return true
end

taskspin.taskcont = def(task)
    var slot = taskspin._resolve(task)
    if !taskspin._valid(slot) || taskspin._tasks[slot] == nil
        return false
    end
    taskspin._tasks[slot]["status"] = taskspin.RUNNING
    return true
end

taskspin.taskchk = def(task)
    if !taskspin._valid(task) || taskspin._tasks[task] == nil
        return taskspin.FREE
    end
    return taskspin._tasks[task]["status"]
end

taskspin.taskid = def()
    return taskspin._current
end

taskspin.info = def()
    var running = 0, halted = 0
    for i : 0..taskspin.MAX_TASKS - 1
        var task = taskspin._tasks[i]
        if task != nil
            if task["status"] == taskspin.RUNNING
                running += 1
            elif task["status"] == taskspin.HALTED
                halted += 1
            end
        end
    end
    return {
        "max_tasks": taskspin.MAX_TASKS,
        "tasks": taskspin._count,
        "running": running,
        "halted": halted,
        "halt_mask": taskspin.taskhlt(),
        "current": taskspin._current,
        "model": "cooperative_step_closures",
        "task_pointer_registers": "$11F..$100",
        "storage": "sd"
    }
end

taskspin.TASKSPIN = taskspin.taskspin
taskspin.TASKNEXT = taskspin.tasknext
taskspin.TASKSTOP = taskspin.taskstop
taskspin.TASKHALT = taskspin.taskhalt
taskspin.TASKCONT = taskspin.taskcont
taskspin.TASKCHK = taskspin.taskchk
taskspin.TASKID = taskspin.taskid
taskspin.TASKHLT = taskspin.taskhlt

taskspin.reset()

return taskspin
