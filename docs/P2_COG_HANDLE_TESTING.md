# P2 managed cog handles: bounded host-test and review record

This document records the bounded managed-cog identity candidate only. It is
not a hardware lifecycle, physical-concurrency, stable-port, or release claim.
The existing full-program runtime lock remains the synchronization policy; this
work does not claim that the registry lock proves physical concurrent cog
execution.

## Handle and ownership contract

`port/p2/runtime/p2_cog_registry.c` supplies a fixed four-slot,
caller-serialized identity registry. A successful reservation assigns a
monotonically increasing token strictly above `P2_COG_HANDLE_BASE` (100), marks
the slot `RESERVED`, and makes it invisible to handle lookup. Only publication
of that exact reserved slot/token produces a `LIVE` handle.

Every handle-facing operation first validates both the calling VM's owner
cookie and the full signed handle range. Lookup rejects a missing owner,
`handle <= 100`, and `handle > INT32_MAX` before narrowing; it then requires a
`LIVE` slot with the same owner and token. Thus stale, foreign, reserved, and
out-of-range values fail as `value_error` and do not invoke the physical stop
seam. Owner cookies are assigned under the registry lock into `p2_vm_state`;
they are never derived from a `bvm *` address.

Cleanup first claims `LIVE -> RESERVED`, hiding the slot from lookup, reaping,
and reentrant work while physical resources are released. It then releases only
the matching reserved token. Repeated cleanup is therefore idempotent: a second
attempt cannot claim the no-longer-live handle. Start failures likewise clean a
reserved slot only after physical cleanup and do not roll back `last_token`.
A failed reservation/start permanently burns its token, preventing a stale
handle from becoming valid again when the fixed slot is reused.

Tokens are finite: reservations fail with `P2_COG_TOKEN_EXHAUSTED` once
`last_token == INT32_MAX`; owner allocation fails with
`P2_COG_OWNER_EXHAUSTED` once `last_owner == UINT32_MAX`. Neither counter is
reset by normal startup or cleanup. A full registry instead returns
`P2_COG_FULL` until a reserved slot is released.

## VM deletion boundary

The `p2_vm_state` deletion callback invalidates the owner cookie under the
registry lock without allocating, running scripts, or stopping hardware.
This rejects old handles even if a subsequent VM reuses the same address. It
intentionally does **not** stop an orphaned running physical cog or free its
resources. Orphan-running liveness/shutdown is the separate unfinished F3 gate;
it is not closed by these tests or this documentation.

## Required host gate: executed

From `/opt/data/propeller2/berry`:

```sh
python3 tools/test_p2_cog_handles.py --cc gcc
```

Result: exit code `0`; `Managed cog host gates: success=True`.

The gate compiled and ran the production registry plus verbatim managed-consumer
slices against real host Berry in all three configured cases:

| Case | Result |
| --- | --- |
| production registry | pass |
| `bint32`, unsafe shared VM cog disabled, non-large layout | pass |
| `bint64`, unsafe shared VM cog disabled, large/Hub-pointer layout | pass |
| `bint32`, unsafe shared VM cog enabled, large/Hub-pointer layout | pass |

The run exercised foreign/stale/bounds token rejection, failed-start token
burning, allocator-failure cleanup, rejected PASM start, missing PASM ack,
setup and GC-finalizer reentry, stopped-source ownership reaping, snapshot
safety across allocation-triggered slot reuse, and VM deletion/address reuse.
The independent registry test also forces the signed-token and owner-exhaustion
boundaries.

Exact retained evidence:

- `/opt/data/propeller2/berry-stabilization/evidence/cog-review/test_p2_cog_handles_gcc.stdout.log`
- `/opt/data/propeller2/berry-stabilization/evidence/cog-review/test_p2_cog_handles_gcc.receipt.txt`
- `/opt/data/propeller2/berry-stabilization/evidence/cog-review/test_p2_cog_handles_gcc.results.json`
- `/opt/data/propeller2/berry-stabilization/evidence/cog-review/REVIEW.md`

The JSON receipt records eleven successful subprocesses: registry compile/run,
then prebuild/compile/run for each of the three configurations. It also records
SHA-256 hashes of the snapshotted sources used for the gate.

## Limits of this evidence

The host harness uses real Berry VM/API/GC/allocation logic and compiles
verbatim source slices, but its P2 intrinsics, PASM acknowledgement/stop, Hub
allocation, and registry lock are host seams. It does not execute a physical
P2 cog, prove lock behavior under physical concurrent cogs, use a board/serial
connection, or validate a Catalina SDK image. Its source-cog scenario provides
completed-job metadata; it deliberately does not simulate child-VM execution.

No sanitizer invocation was run for this record. The runner supports
`--sanitize`, but sanitizer execution may require the glibc container and was
not substituted with a claim of sanitizer coverage.

## Bounded review finding

No blocking defect was found in the inspected candidate paths:
`p2_cog_registry.h`, `p2_cog_registry.c`, `p2_vm_state.c` and its lifetime
hook, managed handle reservation/validation/cleanup in `be_p2lib_p2.c`, and
the two native tests plus runner. This finding is bounded by the host evidence
and the limits above. In particular, F3 orphan-running liveness remains
unfinished and requires separate design, implementation, and hardware-aware
validation before any completion claim.
