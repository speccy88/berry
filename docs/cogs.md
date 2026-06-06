# Cogs and Multicog Execution

## Current backed features

- `p2.cog.id()` and `p2.cog.check(id)` expose basic cog state.
- `p2.cog.stop(id)` can stop a cog after validation.
- `rtos.newcog("function_name", ...int_args)` can launch explicitly loaded child-VM functions by name through the current worker backend.
- `rtos.process_info()` reports the current child-VM backend state.

## Closure-transfer policy

Captured closures are not safe to blindly share across cogs. The current implementation rejects unsafe closure transfer rather than passing VM pointers into another cog.

Future work must define capture serialization/copy rules, mutable capture behavior, return values, errors, cleanup, and resource ownership before `p2.cog.spawn(closure, ...args)` can be marked done.

## Memory model

Each future cog-hosted Berry VM needs a clear VM state, stack, heap, and GC model. Current `rtos` child-VM support is a stepping stone, not the final closure-spawn API.
