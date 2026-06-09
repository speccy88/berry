# Cooperative Tasks

`modules/task.be` provides the P5 friendly cooperative scheduler API. Tasks are
Berry step functions in the current VM: each scheduler turn calls one task
function, and the function returns what should happen next.

This is cooperative, not preemptive. It does not provide independent Berry call
stacks. On P2, timing and attention wakeups use the native `p2` module; on host
it falls back to `time.clock()` for source-level tests.

## Basic API

```berry
import task

h = task.start(fn, ...)
task.run()
task.stop(h)
```

Core helpers:

- `task.start(fn, *args)`: start in the first free slot and return a handle.
- `task.next()`: run one ready task step, returning its handle or `-1`.
- `task.run(max_steps=nil, idle_ms=1)`: run scheduler steps in a loop.
- `task.stop(handle=-1)`, `task.pause(handle=-1)`, `task.resume(handle)`.
- `task.status(handle)`: `free`, `ready`, `waiting`, `paused`, or `error`.
- `task.current()`: current task handle or `-1`.
- `task.list()`, `task.task_info(handle)`, `task.info()`.

## Task return values

```berry
return task.again        # run again later
return task.done         # finish/free task
return task.paused       # pause current task
return task.sleep(250)   # wake after 250 ms
return task.wait("button", 1000)
```

`nil`, `false`, and `task.done` stop the task. `task.sleep()` uses the P2
counter when available. `task.wait("attention")` is backed by P2 cog attention.

## Example

```berry
import p2
import task

def blink(pin, ms)
    p2.toggle(pin)
    return task.sleep(ms)
end

h38 = task.start(blink, 38, 250)
h39 = task.start(blink, 39, 700)

task.run()
```

## Events and wake reason

```berry
def wait_button()
    if task.woke_by_timeout()
        print("timeout")
        return task.done
    end
    if task.woke_by_event("button")
        print("button")
        return task.done
    end
    return task.wait("button", 3000)
end

task.start(wait_button)
task.signal("button")
task.run(20)
```

## Cooperative primitives

The module includes source-level primitives that cooperate with the scheduler:

- `task.Semaphore(count=1)`: `take`, `give`, `value`, `info`.
- `task.Mutex()`: `lock`, `unlock`, `owner`, `is_locked`, `info`.
- `task.Queue(depth=8)`: `put`, `get`, `size`, `free`, `info`.
- `task.EventFlags(initial=0)`: `set`, `clear`, `value`, `ready`, `wait`, `info`.
- `task.Timer(period_ms, repeat=true)`: `expired`, `restart`, `cancel`, `info`.

Open work remains for preemptive scheduling, independent Berry stacks, and
running Berry callbacks directly from P2 interrupts.
