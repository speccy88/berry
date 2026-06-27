# Cooperative Tasks

`import task` is the practical P2 cooperative scheduler path. The native P2
backend exposes a compact current-VM scheduler with 16 slots, Spin2-style
lifecycle aliases, native event helpers, compact native `Semaphore`, `Mutex`,
`Queue`, `EventFlags`, and `Timer` primitives, and queryable capability/contract metadata without loading
the large source module from SD. `modules/task.be` remains the richer
source-level scheduler used by host tests and non-default regression coverage;
it exposes
`task.MAX_TASKS == 32` plus Queue/Semaphore/Mutex/EventFlags/Timer helpers, but
it is not the routine hardware path. In either backend,
`task.info()["max_tasks"]` and `task.capability("max_tasks")` are the
authoritative values. Tasks are Berry step functions in the current VM: each
scheduler turn calls one task function, and the function returns what should
happen next.

This is cooperative, not preemptive. It does not provide independent Berry call
stacks. The native P2 backend uses the hardware counter for timing. The source
module can also use native P2 attention helpers when available, while host
source-level tests fall back to `time.clock()`.

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
- `task.start_result(fn, *args)`: start a task with `ok`, `handle`, `error`, and `message` diagnostics for invalid functions and slot exhaustion.
- `task.spin(id, fn, *args)`: Spin2-style lifecycle name; `-1` starts in the
  first free slot, otherwise a free fixed slot in the current backend's
  `0..max_tasks-1` range is required.
- `task.next()`: run one ready task step, returning its handle or `-1`.
- `task.next_result()`: run one ready task step and return `ok`, `ran`,
  `handle`, post-step status, live/ready/waiting counts, and error diagnostics
  when no task is ready.
- `task.run(max_steps=nil, idle_ms=1)`: run scheduler steps in a loop.
- `task.run_result(max_steps=nil, idle_ms=1)`: run scheduler steps and return a
  summary with step count, live counts before/after, ready/waiting/paused/error
  counts, and whether the current live set completed.
- `task.lifecycle_result(handle=-1)`: non-mutating lifecycle and wait-state
  diagnostic for one task slot. It reports allocated/free/invalid state,
  status, run/wakeup counters, last result/error, current-VM status, wait kind,
  wait target kind, wait mode/value/event, deadline, and remaining time.
- `task.ready_result(target, mode=nil, extra=nil)`: non-mutating readiness
  diagnostic. The native P2 backend covers signaled string events, event wait
  descriptors, and native Semaphore/Mutex/Queue/EventFlags/Timer primitive
  objects, and delegates current-VM `p2ipc` channel/mailbox objects to their
  source readiness maps. Both the native P2 backend and source module cover
  cooperative scheduler waits over current-VM `p2ipc` channels/mailboxes.
- `task.stop(handle=-1)`, `task.pause(handle=-1)`, `task.resume(handle)`.
- `task.halt(handle)`, `task.hlt(handle)`, and `task.cont(handle)`: compatibility
  lifecycle names over `pause`/`resume`.
- `task.chk(handle)`: true when a handle is valid and currently allocated.
- `task.stop_result(handle=-1)`, `task.pause_result(handle=-1)`, and `task.resume_result(handle)`: result-shaped lifecycle diagnostics around the simple boolean helpers.
- `task.reset_result()`: reset the cooperative scheduler and return cleanup
  diagnostics, including released task/event counts and active/event counts
  before and after reset.
- `task.status(handle)`: `free`, `ready`, `waiting`, `paused`, or `error`.
- `task.current()` and `task.id()`: current task handle or `-1`.
- `task.list()` and `task.info()`. The source module also exposes
  `task.tasks()` and `task.task_info(handle)`.
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
- `task.required_capability_keys()` returns required capability metadata keys
  for the active backend. The source module also exposes
  `task.required_attention_policy_keys()`, `task.required_contract_keys()`, and
  `task.required_primitive_capability_keys()`; those return the required metadata
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
- `task.primitive_capabilities()` is a source-module helper that returns an isolated capability map for the
  cooperative primitive families and result-shaped helper methods.
- `task.primitive_capability(name)` is a source-module helper that returns one primitive capability value or
  `nil` for an unknown name.
- `task.audit_ok()` self-checks the compact native metadata surface. The source
  module also exposes `task.audit()` and `task.audit_problems()` to check that
  the scheduler capability map, attention policy, execution model, contract
  map, and primitive capability map still agree on the cooperative/current-VM
  contract and that required metadata keys are present.
- `task.self_test_result(iterations=1)` is a source-module helper that runs a bounded current-VM cleanup
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
counter in the native backend. In the source module, `task.wait("attention")`
can poll P2 cog attention when the native `p2` module is available, and current
P2 images expose bounded wait capability through `p2.cog.wait_attention_result()`.
The task attention event is still a current-VM cooperative event; it does not
claim cross-cog task wakeup, serialization, or independent VM scheduling
semantics.

Queue and imported `p2ipc` object waits accept either a default receive/get
timeout form such as `task.wait(queue, 1000)` / `task.wait(channel, 1000)` /
`task.wait(mailbox, 1000)`, or an explicit readiness mode such as
`task.wait(queue, "put", 1000)`, `task.wait(channel, "send", 1000)`, and
`task.wait(mailbox, "put", 1000)`. This is cooperative polling of the same
current-VM objects, not a cross-cog IPC wakeup mechanism.
For imported `p2ipc` channels and mailboxes, closing the object also wakes
current-VM receive/send/get/put waits so the task can observe the result-shaped
`closed` error and clean up without waiting for its timeout.

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

The native P2 backend includes:

- `task.Semaphore(count=1)`: `take`, `take_result`, `give`, `give_result`,
  `value`, `info`.
- `task.Mutex()`: `lock`, `lock_result`, `unlock`, `unlock_result`, `owner`,
  `is_locked`, `info`.
- `task.Queue(depth=8)`: `put`, `put_result`, `get`, `get_result`, `size`,
  `free`, `info`, including result diagnostics that distinguish an empty queue
  from a queued `nil` payload.
- `task.EventFlags(initial=0)`: `set`, `set_result`, `clear`, `clear_result`,
  `value`, `ready`, `ready_result`, `wait`, `info`.
- `task.Timer(period_ms=10, repeat=true)`: `expired`, `expired_result`,
  `remaining`, `remaining_result`, `restart`, `restart_result`, `cancel`,
  `cancel_result`, `info`.

The source module includes the same primitive families with additional host
coverage and richer cooperative wait integration:

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
They remain current-VM cooperative objects: `p2ipc.cross_cog_channel_policy()`
reports the unsupported cross-cog channel boundary, and
`p2ipc.cross_cog_channel(depth)` validates the requested depth before raising
`unsupported_error`.

Open work remains for preemptive scheduling, independent Berry stacks, and
running Berry callbacks directly from P2 interrupts, cross-cog IPC wakeups, and
broader timing stress coverage.
