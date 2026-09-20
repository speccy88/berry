# VM-owned special storage on P2

This is a bounded ownership primitive, not authorization for public cog concurrency.
The existing full-program lock, capability gates and resource quarantine remain.

## VM API

Zero-initialize `bvm_options`. Its independent `special_allocator` and
`special_allocator_context` fields follow the `bvm_allocator` realloc contract:
NULL input allocates; size zero frees; failure preserves the old block. The VM
copies both fields before initialization, retains them through deletion, and uses
them only for its exception-frame vector. Ordinary objects and small pools retain
their original allocator. A context without a callback is rejected.

The callback must supply suitably aligned storage accessible to the platform's
native setjmp/longjmp. On Catalina LARGE that means Hub, not PSRAM. It must not
throw, re-enter that VM, allocate through the SDK as a worker, or silently fall
back to another allocator. Both contexts outlive the VM and its finalizers.
Explicit special storage includes byte accounting and atomic failed growth;
existing exception-chain relocation fixes still run after moving growth.

No supplied special callback preserves the legacy default constructor and its
assertion/OOM behavior. On Catalina LARGE a custom ordinary allocator without an
explicit special allocator fails construction rather than calling the shared
SDK Hub heap. Special-only custom options also receive protected construction
and nullable OOM. Rebuild callers when changing the options struct.

## P2 bootstrap contract

Only bootstrap/main reserves SDK Hub backing. `p2_partition_reserve_hub` accepts
that separately allocated backing and a zeroed, aligned Hub control descriptor.
It rejects arithmetic overflow, non-Hub target ranges, control/backing overlap,
invalid alignment and invalid locks. The caller owns the backing and guarantees
it is exclusively assigned; there is no registry or hidden SDK allocation.

Offer passes the descriptor through coherent Hub bootstrap data. The designated
cog alone claims it, initializes checked arena headers, and allocates, grows and
frees exception storage. Exhaustion returns NULL without SDK/global fallback.
The coherent source job carries independent ordinary and special ticket
generations; special admission is required to identify a Hub reservation.
No ordinary PSRAM ticket can be used in its place.

Cancellation before admission cancels BOTH tickets. A running VM keeps both
allocators valid through cooperative unwind and deletion. Both tickets retire
only after allocations are gone and their free bytes are restored. Failure,
refused admission and diagnostic stopping do not authorize reclaiming backing or
cache resources. This increment quarantines them until reset.

## Evidence and limits

`tools/test_exception_storage.py --sanitize` runs real Berry VMs against the
production P2 exception routing bridge with tracked host-only allocation domains.
It traps global Hub allocation on explicit paths, exercises nested constructors,
separate contexts, moving/failed growth, accounting, parser/call exceptions,
constructor OOM sweeps and deletion. Host fixtures are not Hub/coherence proof.
The existing VM-state, cog-handle, heap and partition suites remain required.

The companion diagnostic uses the verbatim production override prefix plus a
bounded harness: four reentrant constructors, two special-domain exception
stress/recovery sequences, a live legacy main VM, and the unchanged fourteen
source jobs on one persistent worker/cache. A diagnostic fail-stop precedes any
SDK Hub allocator-state access outside cog 0. Source/image/loader hashes and
exact received UART bytes, not loader exit status, determine acceptance.

The measured native frame/jump sizes and Hub break-to-stack gap are recorded in
the external `berry-stabilization/special-storage` evidence. The gap is address
clearance, NOT a promise that all of it can safely be allocated. Diagnostic
backing budgets are workload-specific, not production sizing guarantees.
Public parallel VMs, the complete service-state audit, safe cache lifecycle,
release/stdlib coverage and maximum worker capacity remain open.
