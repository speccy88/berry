# Cogs and Multicog Execution

## Current backed features

- `p2.cog.id()` and `p2.cog.check(id)` expose basic cog state.
- `p2.cog.stop(id)` can stop a cog after validation.
- `p2.cog.spawn(fn, ...args)` accepts a Berry function entity and returns a native handle for supported cog-backed functions.
- `p2.cog.stop(handle)` stops a spawned native cog handle.
- `p2.cog.info(handle)` reports the active native cog model and diagnostics.

## Closure-transfer policy

Captured closures are not safe to blindly share across cogs. The current implementation rejects unsafe closure transfer rather than passing VM pointers into another cog.

The current supported shape is native-backed handle execution, such as LED blinkers. Future work must define full capture serialization/copy rules, mutable capture behavior, return values, errors, cleanup, and resource ownership before arbitrary Berry closure execution in an isolated cog can be marked done.

## Memory model

Each future cog-hosted Berry VM needs a clear VM state, stack, heap, and GC model. The current native-handle model is intentionally narrower than arbitrary shared-VM closure execution.
