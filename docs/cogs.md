# Cogs and Multicog Execution

## Current backed features

- `p2.cog.id()` and `p2.cog.check(id)` expose basic cog state.
- `p2.cog.id(handle)` returns the native cog id for a spawned native handle.
- `p2.cog.stop(id)` can stop a cog after validation.
- `p2.cog.spawn(fn, ...args)` accepts a Berry function entity and returns a native handle for supported cog-backed functions.
- `p2.cog.stop(handle)` stops a spawned native cog handle.
- `p2.cog.info(handle)` reports the active native cog model and diagnostics.
- `p2.cog.status(handle)` is a non-blocking alias for the handle info map.
- `p2.cog.join(handle)` returns a non-blocking status snapshot with `joined`, `blocking == false`, `join_policy`, `result`, `result_type_name`, and `error`; it does not wait for a long-running native blinker to finish.
- `p2.cog.result(handle)` returns the latest primitive result captured for that handle.
- `p2.cog.error(handle)` returns the latest error string for that handle, or `nil` when none is recorded.
- `p2.cog.kill(handle)` force-stops and cleans up a native handle using the same cleanup path as `stop(handle)`.
- `p2.cog.stop(handle)` / `kill(handle)` return cleanup diagnostics including `cleanup_attempted`, `cleanup_policy`, `slot_released`, and `handle_valid_after_stop == false`.
- `p2.cog.capabilities()` and `p2.cog.required_capability_keys()` report the current handle contract. The implemented model is `native_blink_info_stop_only`: handles support `id(handle)`, `info(handle)`, `status(handle)`, non-blocking `join(handle)`, `result(handle)`, `error(handle)`, `stop(handle)`, and `kill(handle)`, while blocking result waits and cross-cog exception propagation are still unsupported.
- `p2.cog.audit()`, `audit_problems()`, and `audit_ok()` provide metadata-only consistency diagnostics, including `missing_capability_keys`, without spawning or stopping cogs.

## Closure-transfer policy

Captured closures are not safe to blindly share across cogs. The current implementation rejects unsafe closure transfer rather than passing VM pointers into another cog.

The child-VM transfer boundary is intentionally narrow: nil, bool, int, and
bounded strings are copied by value in the guarded VM-call probes. A
non-captured parent closure can be used only as a validated function-name
selector when matching child source defines that function name. The closure
object itself is not copied. Captured closures, lists, maps, instances, native
pointers, file handles, and hardware-resource objects remain unsupported for
cross-VM transfer.

`p2compat.child_vm_transfer_policy()` exposes the same boundary as a structured
map for tooling: copyable primitive type names, staged closure-name selector
policy, rejected live-object categories, and ownership/resource-transfer flags.
Use `p2compat.child_vm_copyable_type(name)` and
`p2compat.child_vm_rejected_type(name)` for direct type-policy checks.
`p2compat.required_child_vm_policy_keys()` and
`p2compat.required_capability_names()` expose the required metadata surface, and
`p2compat.audit()` reports missing policy keys or capability records.

The current supported shape is native-backed handle execution, such as LED blinkers. Future work must define full capture serialization/copy rules, mutable capture behavior, return values, errors, cleanup, and resource ownership before arbitrary Berry closure execution in an isolated cog can be marked done.

## Memory model

Each future cog-hosted Berry VM needs a clear VM state, stack, heap, and GC model. The current native-handle model is intentionally narrower than arbitrary shared-VM closure execution.
