# P2 cancellation and concurrent-VM status

This is a verified repair increment, **not completion of the P2 stabilization contract**.
The production full-program execution lock and unsafe capability gates remain in place.
Do not remove them based on the diagnostic result below.

## Implemented ownership boundary

- Interrupt cadence is `bvm.native_poll_ticks`, not a process-global counter.
- `p2_vm_poll_due()` polls every 1024 VM opcodes. Normal polling does not allocate.
- A P2 cancellation flag is a native scalar in coherent Hub memory. It must outlive
  the VM or be detached before its storage is freed. It is never a Berry object pointer.
- `p2_vm_set_cancel_flag()` can allocate the VM-owned native context. Attach it in
  a protected Berry call; detaching with `NULL` does not allocate.
- Cancellation exits through `BE_EXIT`; a Berry `except ..` does not swallow it.
  Blocking native calls must return or explicitly poll before cancellation can finish.
- Managed source-worker preparation (including function-name registration) is
  protected, so allocation failure follows the normal child cleanup path.
- Source workers alone publish completion, after VM deletion, allocator deselection
  and release of the broad execution lock.
- Stopping an unfinished source worker requests cancellation and raises
  `runtime_error`: retry after completion. It does not forcibly stop its physical
  cog or free its stack, mailbox or arena while Berry may still be executing.
- `p2.cog.cleanup()` retains unfinished source workers and reports `ok=false`,
  nonzero `active_after`, and `registry_empty=false`. These are not successful cleanup.
- Owner deletion signals its live source workers before invalidating owner cookies;
  it performs no scripts, allocation or physical stopping during native teardown.
  **Automatic reclamation of running-orphan resources is still unfinished.**

## Regression commands

Run host builds in separate source snapshots from P2 builds:

```sh
python3 tools/test_p2_vm_state.py --cc gcc --sanitize --abi native
python3 tools/test_p2_vm_state.py --cc clang-19 --sanitize --abi 32 --bint 32
python3 tools/test_p2_vm_state.py --cc gcc --sanitize --abi 32 --bint 32 --no-small-pools
python3 tools/test_p2_cog_handles.py --cc gcc --sanitize
python3 -m unittest discover -s tools/tests -p test_catalina_flash_program.py
```

The VM tests use the real interpreter opcode hook, allocator, exception mechanism
and GC. They check independent cadence and an uncatchable cancellation while further
OS allocations are denied. Cog-handle tests use real Berry execution with explicit
platform seams; simulated cog status is **not hardware lifecycle evidence**.

The native-context allocation-failure fixture distinguishes exhausted small-pool
slots from a larger directly allocated context. This matters on a 64-bit host:
adding a native pointer can move the context beyond the small-pool size classes.

## What the isolated board diagnostic proved

A diagnostic-only image executed two distinct Berry workloads on main cog 0 and
worker cog 6. Both reached a readiness barrier, retained objects across GC,
returned separate identity-dependent sums, exhausted their private allocators and
successfully executed Berry again after OOM. This was real Berry, not a synthetic
C substitute. Each arena was configured for 262144 bytes and the worker stack
reservation was 32768 bytes; reservations are **not measured stack high-water marks**.

This does not establish production concurrency or copy-based messaging. An earlier
untraced image failed partition admission, while a visibility-traced image passed.
The traced shared heap descriptors/selectors reside in cached PSRAM. Cache visibility
and shared-service ownership still require a production repair and repeated exact-image
verification. The broad lock is not a substitute for that repair and has not been removed.

The board admitted one additional execution/cache pair; attempting two additional
pairs failed. Do not advertise eight usable Berry worker cogs.

## Serial and flash safety

The flash wrapper now refuses conflicting or indeterminate serial ownership. It does
not terminate arbitrary port users. Its cooperative lock coordinates participating
wrappers; `lsof` is a prerequisite, and unavailable/erroring ownership checks fail closed.
Cleanup targets only the wrapper's own child. Seeing a Berry prompt proves neither the
flashed image identity nor persistence.

The original flash has a separately verified private two-pass backup. No flash writes
were part of this increment. Recovery execution, deployment readback and actual cold
power-cycle behavior remain release gates. A serial reset is not a cold power cycle.
