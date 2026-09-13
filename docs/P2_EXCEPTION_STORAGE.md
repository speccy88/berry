# P2 exception storage — implementation and evidence

## Problem

The native XMM image could evaluate arithmetic and run a short Berry function.
A traced list/range test reached its last iteration but never returned from the
loop. The SDK's `lib/p2/xmm/cx/setjmp.s` saves/restores jump-buffer words using
raw Hub `WRLONG`/`RDLONG`. Berry's `bexecptframe` embeds the jump buffer, and its
`exceptstack` was allocated through the ordinary PSRAM-backed VM allocator.
Those are incompatible memory spaces.

## Repair

- `BE_EXCEPTSTACK_REALLOC` optionally routes only `vm->exceptstack` storage to
  a target allocator. Other vectors retain their existing allocator.
- Catalina LARGE selects `be_p2_realloc_exceptstack`, backed by Hub RAM. It
  preserves VM byte accounting and raises `BE_MALLOC_FAIL` on Hub exhaustion.
- A shared Hub-heap service is initialized before VM creation. Its short
  `_locktry`/`_lockrel` critical section covers allocation only, never Berry
  execution or exception transfer. All direct Hub allocation calls in the P2
  port route through that service.
- Vector growth now increments the element count only after successful storage
  growth, preserving unwind state on OOM. Exception-chain relocation avoids
  computing member addresses through a null previous base.

## Verified so far

`python3 tools/test_exception_storage.py --cc gcc --sanitize` passes against
real host Berry VM code. It tests routing, forced moving growth, nested loop
unwind, allocation failure, recovery, release and VM destruction. A separate
host seam exercises the production Hub wrapper's lock sequencing, initialization,
overflow rejection, OOM preservation and free paths. Neither seam is hardware
emulation or proof of concurrent cogs.

The native Catalina build succeeds. In an isolated, source-hashed candidate,
the unchanged board collections test now returns and passes. Native math, JSON
and bytes cases also pass. The following import/path case still failed; later
cases were not silently counted as passed. The overall port remains under repair.

## Boundaries

Hub storage is finite and distinct from PSRAM. Exhaustion must be handled as an
allocation failure; active exception frames cannot simply be collected away.
The Hub lock is a shared-service lock, not proof that all native state or VM/cog
lifecycles are safe. Full-program VM locking has not been removed.

Private evidence and source manifests are under the stabilization control
workspace. Final release requires fresh-build, native library/timing/soak and
multicog acceptance gates, plus independent review of the integrated changes.
