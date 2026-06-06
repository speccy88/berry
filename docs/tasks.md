# Cooperative Tasks

## Current modules

- `modules/taskspin.be`: Spin2-shaped uppercase `TASK*` API.
- `modules/task.be`: lower-case roadmap-shaped facade over `taskspin`.

## Current execution model

Tasks are cooperative step closures in the current Berry VM. Each call to `task.next()` runs one runnable task step. This is useful and testable, but it is not independent stackful execution and not preemptive multitasking.

## Lower-case API

`task.spin(task_id, closure, *args)` schedules a closure. Use `task_id == -1` for first-free slot behavior. A trailing options map such as `{ "stack": 287 }` records stack metadata for diagnostics.

Other backed helpers: `task.next`, `task.stop`, `task.halt`, `task.cont`, `task.chk`, `task.id`, `task.hlt`, `task.info`, `task.tasks`, and `task.task_info`.

## Cooperative primitives

The source-level primitives are `task.Semaphore`, `task.Mutex`, `task.Queue`, `task.EventFlags`, and `task.Timer`.

## Open work

Independent Berry call stacks, proven coroutine/continuation support, true Spin2/PASM switching, and non-callback stackful execution remain open.
