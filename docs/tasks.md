# Cooperative Tasks

`modules/task.be` provides the friendly cooperative scheduler API tracked as
Priority 4 backlog work. The source module exposes `task.MAX_TASKS == 32`;
the older native P2 compatibility `import task` path can still report its
native 16-slot limit. In either backend, `task.info()["max_tasks"]` and
`task.capability("max_tasks")` are the authoritative values. Tasks are Berry
step functions in the current VM: each scheduler turn calls one task function,
and the function returns what should happen next.

This is cooperative, not preemptive. It does not provide independent Berry call
stacks. On P2, timing and attention wakeups use the native `p2` module; on host
it falls back to `time.clock()` for source-level tests.

## Basic API

```berry
import task

h = task.start(fn, ...)
fixed = task.spin(-1, fn, ...)
task.run()
task.stop(h)
```

Core helpers:

- `task.start(fn, *args)`: start in the first free slot and return a handle.
- `task.start_result(fn, *args)`: start a task with `ok`, `handle`, `error`, and `message` diagnostics for invalid functions, over-wide argument lists, and slot exhaustion.
- `task.spin(id, fn, *args)`: Spin2-style lifecycle name; `-1` starts in the
  first free slot, otherwise a free fixed slot in the current backend's
  `0..max_tasks-1` range is required.
- `task.next()`: run one ready task step, returning its handle or `-1`.
- `task.run(max_steps=nil, idle_ms=1)`: run scheduler steps in a loop.
- `task.stop(handle=-1)`, `task.pause(handle=-1)`, `task.resume(handle)`.
- `task.halt(handle)`, `task.hlt(handle)`, and `task.cont(handle)`: compatibility
  lifecycle names over `pause`/`resume`.
- `task.chk(handle)`: true when a handle is valid and currently allocated.
- `task.stop_result(handle=-1)`, `task.pause_result(handle=-1)`, and `task.resume_result(handle)`: result-shaped lifecycle diagnostics around the simple boolean helpers.
- `task.status(handle)`: `free`, `ready`, `waiting`, `paused`, or `error`.
- `task.current()` and `task.id()`: current task handle or `-1`.
- `task.list()`, `task.tasks()`, `task.task_info(handle)`, `task.info()`.
- `task.capabilities()` returns an isolated capability map for the current
  cooperative scheduler contract.
- `task.capability(name)` returns one scheduler capability value or `nil` for
  an unknown name.
- `task.attention_policy()` returns the scheduler's current attention-event
  contract, including whether bounded native P2 cog-attention wait support is
  available in the active image and the explicit lack of cross-cog task wakeup
  semantics.
- `task.attention_policy_value(name)` returns one attention-policy value or
  `nil` for an unknown name.
- `task.required_capability_keys()`, `task.required_attention_policy_keys()`,
  `task.required_contract_keys()`, and
  `task.required_primitive_capability_keys()` return the required metadata
  surfaces that `task.audit()` checks for drift.
- `task.execution_model()` returns an isolated map that explicitly identifies
  the current scheduler as cooperative, current-VM, callback-step based, not
  preemptive, and not stackful. The map also reports
  `scheduler_policy == "current_vm_callback_step"` and an `unsupported_reason`
  naming the missing independent stacks, preemption, and true Spin2/PASM task
  switching.
- `task.execution_model_value(name)` returns one execution-model value or
  `nil` for an unknown name.
- `task.contract()` returns the same current-VM cooperative boundary as a
  compact contract map for tools and examples, including the no preemption, no
  independent stacks, no per-task VM, no cross-VM serialization, and no
  cross-cog wakeup claims.
- `task.contract_value(name)` returns one contract value or `nil` for an
  unknown name.
- `task.primitive_capabilities()` returns an isolated capability map for the
  cooperative primitive families and result-shaped helper methods.
- `task.primitive_capability(name)` returns one primitive capability value or
  `nil` for an unknown name.
- `task.audit()`, `task.audit_problems()`, and `task.audit_ok()` self-check that
  the scheduler capability map, attention policy, execution model, contract
  map, and primitive capability map still agree on the cooperative/current-VM
  contract and that required metadata keys are present.
- `task.self_test_result(iterations=1)` runs a bounded current-VM cleanup
  diagnostic over a tiny task lifecycle, queue, semaphore, mutex, event flags,
  timer, and event cleanup path. It resets the cooperative scheduler before and
  after the diagnostic and reports `ok`, `checks`, `failures`, and cleanup
  counters.
- `task.events()` returns an isolated list of currently signaled event names.
- `task.clear_all()` clears all signaled events.

## Task return values

```berry
return task.again        # run again later
return task.done         # finish/free task
return task.paused       # pause current task
return task.sleep(250)   # wake after 250 ms
return task.wait("button", 1000)
```

`nil`, `false`, and `task.done` stop the task. `task.sleep()` uses the P2
counter when available. `task.wait("attention")` is backed by P2 cog attention
when the native `p2` module is available, and current P2 images expose bounded
wait capability through `p2.cog.wait_attention_result()`. The task attention
event is still a current-VM cooperative event; it does not claim cross-cog task
wakeup, serialization, or independent VM scheduling semantics.

Queue and imported `p2ipc` object waits accept either a default receive/get
timeout form such as `task.wait(queue, 1000)` / `task.wait(channel, 1000)` /
`task.wait(mailbox, 1000)`, or an explicit readiness mode such as
`task.wait(queue, "put", 1000)`, `task.wait(channel, "send", 1000)`, and
`task.wait(mailbox, "put", 1000)`. This is cooperative polling of the same
current-VM objects, not a cross-cog IPC wakeup mechanism.

## Example

```berry
import p2
import task

def blink(pin, ms)
    p2.pin.dir_high(pin)
    p2.pin.toggle(pin)
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

- `task.Semaphore(count=1)`: `take`, `take_result`, `give`, `give_result`, `value`, `info`.
- `task.Mutex()`: `lock`, `lock_result`, `unlock`, `unlock_result`, `owner`, `is_locked`, `info`.
- `task.Queue(depth=8)`: `put`, `put_result`, `get`, `get_result`, `size`, `free`, `info`.
- `task.EventFlags(initial=0)`: `set`, `set_result`, `clear`, `clear_result`, `value`, `ready`, `ready_result`, `wait`, `info`.
- `task.Timer(period_ms, repeat=true)`: `expired`, `expired_result`, `remaining`, `remaining_result`, `restart`, `restart_result`, `cancel`, `cancel_result`, `info`.

Invalid numeric constructor inputs are clamped to an inert zero value: empty
queues, zero-count semaphores, zero flags, or immediate zero-period timers.
Invalid event-flag masks leave the current value unchanged or report not ready.
Use `Queue.get_result()` when callers must distinguish an empty queue from a
queued `nil` payload.
Imported `p2ipc` channels and mailboxes also expose scheduler-readable task
kinds so `task.wait()` can wait for receive/send or get/put readiness.

Open work remains for preemptive scheduling, independent Berry stacks, and
running Berry callbacks directly from P2 interrupts.
