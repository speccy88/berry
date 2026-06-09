# P2 cog task handles

Berry on P2 exposes a small task-handle API under `p2.cog` for launching supported work on another cog from the main REPL cog.

## Blinker task syntax

The user-facing blinker pattern is:

```berry
import p2

def blinker(pin, ms)
    return p2.cog.blinker(pin, ms)
end

h38 = p2.cog.spawn(blinker, 38, 250)
h39 = p2.cog.spawn(blinker, 39, 700)

# Later:
p2.cog.stop(h38)
p2.cog.stop(h39)
```

In Berry, `blinker` is the function entity and `blinker(38, 250)` calls the
function immediately on the current cog. To hand the function entity to the cog
launcher, pass the function first and the primitive arguments after it:
`p2.cog.spawn(blinker, 38, 250)`. In the current supported blinker path,
`blinker` returns a native task descriptor and `spawn()` starts that task on a
new cog.

An explicit descriptor form is still available for native task backends:

```berry
def blinker(pin, ms)
    return p2.cog.task("blinker", pin, ms)
end
```

`p2.cog.blinker(pin, ms)` is shorthand for `p2.cog.task("blinker", pin, ms)`.

## Introspection

```berry
t = p2.cog.blinker(38, 250)
print(p2.cog.is_task(t))
print(p2.cog.task_kinds())
print(p2.cog.task_info(t))
```

Active handles can be inspected:

```berry
print(p2.cog.info(h38))
print(p2.cog.info())
```

Useful fields include:

- `handle`: the stop handle.
- `cog`: the cog id.
- `running`: whether the task is still running.
- `native_blink`: true for the current blinker backend.
- `descriptor_task`: false when launched with `p2.cog.spawn(blinker, pin, ms)`;
  true when launched from an explicit task descriptor.
- `setup_function`: true when the handle came from a passed Berry function
  entity such as `p2.cog.spawn(blinker, 38, 250)`.
- `setup_descriptor_return`: true when that setup function returned a native
  task descriptor such as `p2.cog.blinker(pin, ms)`.
- `task_kind`: currently `"blinker"` for this task kind.
- `native_pin`: pin used by the native blinker backend.
- `period_ms`: blink period in milliseconds.
- `calls`: backend heartbeat/toggle counter.

On the current XMM image, `p2.waitms` is exported at the top level. Hardware
counter-progression smokes can also use the host serial harness to wait between
REPL commands while the spawned cogs keep running.

## Descriptor arguments

Task descriptors can carry up to `8` primitive arguments:

- `int`
- `bool`
- `nil`
- `string`

The current native blinker backend uses the first two arguments as `pin` and `ms`. Extra descriptor arguments are preserved for descriptor metadata and future task backends. The current runtime reports this limit as `p2.cog.capabilities()["task_max_args"]`.

## Current limitation

This is not yet arbitrary Berry closure bytecode transfer. The supported
`p2.cog.spawn(blinker, pin, ms)` form accepts a Berry function entity and
primitive arguments, invokes the function during setup, accepts either a native
task descriptor return value or an integer return value as the native blink
period, and then runs the current native `blinker` backend on the spawned cog.
Explicit task descriptors are also supported for native task backends.

The source-backed isolated child VM bridge remains an internal investigation path, but it is not exposed as supported on the current Catalina XMM profile. The lower-level C child-cog entry starts a raw cog but does not execute the entry routine on XMM, and Catalina's documented thread support does not cover XMM. `p2.cog.capabilities()` therefore reports `spawn_source=false`, `isolated_child_vm_cog=false`, and `berry_closure=false` on this build.

The safe XMM-supported path today is native task descriptors. The eventual arbitrary-closure path still needs a bytecode/source transfer model plus a working isolated child execution runtime that recreates the closure in a child VM without sharing GC-owned closure objects between VMs or cogs.

## Smoke files

Useful hardware smoke scripts for this feature:

- `tests/p2/smoke_closure_blinker.be`: function-entity `p2.cog.spawn(blinker, 38, 250)` style.
- `tests/p2/smoke_closure_blinker_descriptor_return.be`: function-entity spawn where `blinker` returns `p2.cog.blinker(pin, ms)`.
- `tests/p2/smoke_closure_blinker_setup_return.be`: proves the function entity is invoked during setup and its integer return controls the blink period.
- `tests/p2/smoke_cog_descriptor_varargs.be`: descriptor vararg transport and metadata.
- `tests/p2/smoke_cog_spawn_task_blinker.be`: explicit `p2.cog.spawn_task(task)` alias.
- `tests/p2/smoke_cog_spawn_source_blinker.be`: source-backed isolated child VM bridge; expected to be unsupported on current XMM.
- `tests/p2/smoke_cog_task_source_blinker.be`: registry-backed `p2.cog.task("source", ...)` descriptor bridge; expected to be unsupported on current XMM.

## Source task descriptors

When supported by the runtime, `p2.cog.task("source", source, name, ...)` creates a registry-backed task descriptor. The descriptor is a small handle to source/name/args stored in a fixed P2-side task registry, so it should be spawned soon after creation:

```berry
t = p2.cog.task("source", source, "main", 38, 100)
h = p2.cog.spawn(t)
```

This uses the same isolated child VM bridge as `p2.cog.spawn_source(source, name, ...)`, but goes through the common task-value spawn surface.

If a registry-backed source task descriptor is created but not spawned, release it explicitly:

```berry
t = p2.cog.task("source", source, "main")
# decide not to spawn it
p2.cog.task_release(t)
```

`task_release()` returns `true` when it released a pending source task descriptor and `false` for non-registry descriptors or descriptors already consumed.
