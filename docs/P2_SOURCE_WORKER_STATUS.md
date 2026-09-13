# Source-worker execution safety — scoped increment

Production independent-cog execution remains unsupported. The full-program VM
lock and source-runtime capability gates are unchanged. This increment does not
close F3/F6 or qualify public spawn/join/reap, orphan reclamation or cache reuse.

## Repairs

- A named source function may grow/relocate its Berry value stack. The result
  location is now retained as an offset and resolved against the current stack
  after `be_pcall`, not held as a dangling `bvalue *` across user execution.
- Preparation, source execution, argument copying and result extraction run
  inside a protected boundary. An allocation failure while copying a string
  argument cannot bypass child-VM deletion and the runtime-lock release path.
- A cancellation already present at worker dispatch acknowledges completion
  without acquiring the VM execution lock, allocating a partition or creating
  a VM. This does not solve cancellation while waiting on that lock.

## Reproduction and verification

Run `python3 tools/test_p2_cog_handles.py --cc gcc --sanitize`.
The runner snapshots and hashes inputs, compiles verbatim production consumers
and the source-worker entry, and uses real Berry allocation, parser, VM, GC and
exception behavior. It covers recursive stack growth, copied scalar/string
results surviving VM deletion, source exceptions, an allocation-failure sweep,
pre-start cancellation, and existing owner/stale-handle/cleanup cases.

The source-worker entry runs synchronously in the host test. Cog startup,
partition admission/accounting and terminal acknowledgement are explicit
platform seams: this proves neither P2 heap routing nor physical cog execution.
The terminal acknowledgement is the production protocol's value **4**, not 3.
Constructor allocations are excluded from the source-execution failure sweep;
constructor OOM and global constructor diagnostics remain separate open gates.

Red controls reproduced an ASan use-after-free after recursive stack growth,
and process abort during post-constructor OOM before the protective boundary.
Each run's `build/p2-cog-handles-*/results.json` binds outcomes to exact source
hashes. Compiler and runtime timeouts are recorded as failures, not passes.

## Why production concurrency is still blocked

A bounded board trace reproduced failed partition admission: the worker read
`ready=0`, `raw=0`, `bytes=0` after successful producer creation. The launcher
creates a separate XMM cache per worker. Catalina's cache driver marks writes
dirty and writes a line back on eviction; a hardware lock does not publish or
invalidate those private cached copies. Adding diagnostic reads can change
cache eviction and mask the failure.

Shared descriptors/selectors, mutable allocator control, registry/service
state and constructor controls require a coherent design before enabling
parallel production execution. A Hub allocation does not solve publication if
its only published pointer is itself held in an unflushed XMM global. Hub
mailboxes passed through the supported startup argument avoid that specific
pointer-publication problem; a complete control-plane integration remains open.

Hardware diagnostic drivers must distinguish reuse of VMs in one persistent
worker/cache from public stop/join/restart and reclamation. Stack fill-pattern
write extent is a measured watermark, not proof of maximum supported workload
or maximum worker capacity. Release, flash/restore/cold boot and exhaustive
library conformance remain unqualified.
