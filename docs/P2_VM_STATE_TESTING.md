# P2 VM-owned native state: bounded F3 candidate

This is a C ownership/lifetime foundation, not a concurrent-P2-VM proof, a
stable-port claim, or release delivery. Branch: `fix/p2-stability`. Parent owns
architecture, hardware and final release. No board, GPIO, serial, flash, SDK,
queue/publishing API, commit or push was used. Full-program runtime locking and
experimental/shared-VM cog policy remain unchanged. `be_p2lib_p2.c` is untouched.

## Ownership and lifetime

- `src/be_vm.h` appends only `native_context` and `native_context_delete` at the
  end of `bvm`, after conditional fields. Existing field offsets are preserved;
  `sizeof(bvm)` changes. These are private core/port implementation fields, not
  a new public Berry API. All objects using `bvm` must be rebuilt together.
- `be_vm_new()` already zeroes the entire VM. Ordinary non-P2 VMs retain null
  fields and need no port registration or allocation.
- Actual deletion ordering was inspected, not assumed: `be_gc_deleteall()` in
  `src/be_gc.c:53` first invokes instance destructors, then frees GC objects.
  The common-object branch invokes native finalizers via `be_commonobj_delete()`
  (`src/be_object.c:61`) during this second phase, then releases open upvalues.
  `be_vm_delete()` invokes the private callback immediately after that returns,
  before strings, stacks, global structures, memory pools and the VM are freed.
  The context therefore remains available to both collection-time and
  deletion-time native finalizers, including first use during finalization.
- `port/p2/runtime/p2_vm_state.c` owns one lazily allocated `p2_vm_state` directly
  through `bvm`. It never indexes by `_cogid()`: two VMs may execute on the same
  cog through the parent VM-entry path. Scheduler and RNG feature allocations
  are independently lazy and VM-accounted using real `be_malloc`/`be_free`.
- Before invoking cleanup, core detaches and clears both fields. Cleanup only
  frees the scheduler, RNG and context with their exact allocation sizes. It
  neither inspects Berry objects nor allocates, throws or executes scripts.
  Task closures/arguments/wait objects remain GC-owned; cleanup must not free
  them again. Pool storage is subsequently released by the ordinary VM teardown.
- Allocation uses Berry's real failure/GC/retry/`BE_MALLOC_FAIL` machinery, so
  helper callers must be in a protected VM path. No fallible operation follows
  allocation before the initialized pointer is published. A context allocation
  failure leaves null fields; feature failure leaves a valid empty context (or
  the other existing feature unchanged), not an orphaned C allocation.
- Failed allocation can run a native GC finalizer which itself initializes the
  requested state. Each allocator checks the published pointer again after
  `be_malloc` returns; it retains the finalizer's state and releases any redundant
  retry allocation. Tests exercise this for context, scheduler and RNG.

### Scheduler

`p2_task_state` contains the fixed slots, current task, round-robin cursor and
pending event names. Helpers receive `bvm *` or explicit state; there is no
singleton-alias macro and no per-cog mutable scheduler table. Initial current
and cursor are `-1`; slot/event arrays are cleared. Hidden `__p2_task_refs`
continues to be a per-VM Berry global containing closures, args and wait objects.

Handles are reusable VM-local slot indices, not cross-VM capabilities, unique
process-wide IDs or generation-checked tokens. Both VMs can have handle 0;
`stop(0)` in B affects only B. Returning `task.done` releases the slot and roots
and yields status `free`, not a retained `done` slot. Existing task behavior and
fixed clock/deadline arithmetic are retained. Physical time sampling remains a
shared service; `p2_clock.c/h` algorithms were not changed for this work.

### RNG sequence change

The global signed `+7919` counter is replaced by xorshift32 `(13,17,5)` with
`uint32_t` state. Output is the updated state masked with `0x7fffffff`, hence a
nonnegative 31-bit Berry integer. This intentionally changes prior sequences.
It is deterministic and non-cryptographic: no entropy or security claim.

- Integer seeds convert modulo 2^32, without signed negation (including
  `INT32_MIN` and `INT64_MIN`). Negative seeds no longer mean absolute values.
- A resulting zero seed maps to fixed nonzero `0x6d2b79f5`.
- The initial seed, and the missing/non-integer `srand` default, are `1357911`.
  Extra arguments remain ignored; `srand` returns nil; API names are unchanged.
- Seed 1 returns `270369, 67634689, 499951813, 307599695, 251205585`.
- Zero returns `1085196063, 299895833, 470802728, 1701901981, 265159372`.
- The same seed restarts the same sequence independently in each VM. Interleaving
  calls, resetting a scheduler, or deleting/recreating another VM cannot share
  the RNG state.

## Reproduction commands

From `/opt/data/propeller2/berry`, the unchanged independent acceptance commands
use Python stdlib and local GCC; Docker is **not** a hidden default:

```sh
/opt/hermes/.venv/bin/python tools/test_p2_vm_state.py --cc gcc
/opt/hermes/.venv/bin/python tools/test_p2_clock.py --cc gcc
```

`python3` also works. The runner snapshots core, port helpers, overrides, test,
config and COC generator under a unique ignored `build/p2-vm-state-*/snapshot`.
It generates headers there, never in shared host/P2 source locations. It compiles
and executes every named case, verifies reported ABI/bint widths and failures,
checks source hashes after execution, and writes exact commands, return codes,
stdout/stderr, source/binary SHA-256 and results to that build directory.
Missing source/compiler, compiler/linker failures, runtime failures or missing
case receipts are failures, not skips counted as passes. No runtime PRNG/clock
success outputs are fabricated.

Optional real libc/multilib/sanitizer builder, explicitly selected:

```sh
docker inspect propeller2 --format '{{json .Mounts}}'
# Observed daemon source: /DATA/AppData/hopeful_renaud/propeller2
# The repo is its berry child; /opt/data is NOT the daemon mount path.
/opt/hermes/.venv/bin/python tools/test_p2_vm_state.py --cc gcc --sanitize \
  --builder local/berry-p2-dev:cat8.8.9 \
  --docker-host-root /DATA/AppData/hopeful_renaud/propeller2/berry
/opt/hermes/.venv/bin/python tools/test_p2_vm_state.py --cc gcc --sanitize --abi 32 --bint 32 \
  --builder local/berry-p2-dev:cat8.8.9 \
  --docker-host-root /DATA/AppData/hopeful_renaud/propeller2/berry
/opt/hermes/.venv/bin/python tools/test_p2_vm_state.py --cc gcc --sanitize --abi 32 \
  --builder local/berry-p2-dev:cat8.8.9 \
  --docker-host-root /DATA/AppData/hopeful_renaud/propeller2/berry
/opt/hermes/.venv/bin/python tools/test_p2_clock.py --cc gcc --sanitize --abi 32 \
  --builder local/berry-p2-dev:cat8.8.9 \
  --docker-host-root /DATA/AppData/hopeful_renaud/propeller2/berry
```

Builder image ID:
`sha256:d5c75a1f7388fa90a312d5b1779408fb04339dde035da6c87277b42d75d443bc`.
Runs are foreground, network-disabled, unprivileged, capabilities dropped,
no-new-privileges, with no physical devices passed through. Only isolated
ignored evidence is writable through workspace mounts. `--abi 32` means actual
`gcc -m32` compilation/execution with libc and sanitizer runtimes, not a typedef
simulation. `--bint 32` additionally selects Berry's integer configuration; the
native/default runner uses 64-bit bint. No Catalina/P2 build was performed.

## Tests and real results

The C fixture executes real Berry VMs, parser, native callbacks, GC, allocator,
production task/math code and production state/clock helpers. A labelled
host-only seam fixes one simulated cog ID and clock sample. Unexercised wait
and CORDIC instructions abort if reached. The fixture neither implements nor
proves physical clock, CORDIC, GPIO or `be_p2lib` VM entry. P2 task/math modules
are installed in real per-VM caches; the host string module is retained for
core formatting. No Berry APIs are replaced by success stubs. Allocation faults
use the supported `BE_EXPLICIT_*` OS-allocation hooks, retaining real VM
allocation accounting, forced GC, retry and protected longjmp semantics.

Nine case groups (exact native-ABI C CHECK counts in parentheses):

1. `scheduler_reset` (174): original two-VM task/event/reset interference RED.
2. `rng_isolation` (124): original independent-seed/interleaving regression.
3. `rng_sequence` (71): original five fixed known-answer counter rejection.
4. `scheduler_isolation` (426): distinct pointers, same handle in both VMs,
   event/wait isolation, pause/resume/stop/clear/reset isolation, other-VM
   deletion and replacement, independent cursors, nested native entry into B
   while A's current task remains active on the same simulated cog.
5. `scheduler_gc` (150): closure captured data and args survive collection solely
   through task roots; a wait-only semaphore survives another collection and
   wakes the task; completion releases the hidden root.
6. `rng_boundaries` (1313): default/argument policies, zero/negative/INT_MIN
   vectors, 64-bit truncation where configured, nonnegative output, 128-value
   independent deterministic interleaving and deletion/recreation.
7. `lifecycle` (188): ordinary null-context VM, empty/scheduler/RNG/both states,
   exact usage deltas, collection retention, actual native finalizers at GC and
   delete, first initialization during delete, production cleanup exactly once,
   cleared fields and final VM usage equal to `sizeof(bvm)` before OS free.
8. `allocation_failures` (309): exhausted real small pools and OS faults,
   absent-context and feature failures, existing sibling preservation, newly
   published empty context after feature failure, actual math/task callbacks
   returning `BE_MALLOC_FAIL` through `be_pcall`, recovery and leak-free deletion.
9. `allocation_reentry` (76): real forced-GC finalizer publishes each requested
   allocation during retry; identity/data retained, redundant allocation freed,
   exact accounting and final teardown verified.

Counts are C CHECK evaluations (including allocator free checks and successful
script-call assertions), not a claim that every Berry assertion is a separate
case. ABI/pool layout changes legitimately change the number of allocator free
checks. Every case additionally requires zero remaining OS allocation blocks.

Recorded GREEN receipts, all with `source_unchanged=true` and zero failures:

- `build/p2-vm-state-8qniixxt/results.json`: local acceptance, 9/9,
  2831 checks, pointer/bint 64/64.
- `build/p2-vm-state-jkr35zl1/results.json`: final repeated unchanged VM-state
  acceptance after this report was created, 9/9, 2831 checks, pointer/bint 64/64.
- `build/p2-vm-state-acevgdpw/results.json`: ASan/UBSan, 9/9,
  2831 checks, pointer/bint 64/64.
- `build/p2-vm-state-oia8va5h/results.json`: ASan/UBSan, 9/9,
  2523 checks, pointer/bint 32/32.
- `build/p2-vm-state-tgvit4uf/results.json`: ASan/UBSan, 9/9,
  2527 checks, pointer/bint 32/64.
- `build/p2-clock-2o5zue1y/results.json`: local clock acceptance, 2/2 binaries.
- `build/p2-clock-y2afpix8/results.json`: final repeated unchanged clock
  acceptance after this report was created, 2/2 binaries, pointer/long 64/64.
- `build/p2-clock-4ss6iixz/results.json`: real ABI32 ASan/UBSan clock, 2/2 binaries.
  Both clock runs retain **17344 exact tick pairs and 8815 deadlines per binary**;
  scheduler also retains **3 sampler and 67 scheduler scenario groups**.
  Exact C checks are 158049 portable and 158478 scheduler. This repair did not
  edit either clock test or runner, and retained every semantic assertion.
  The earlier clock receipt predates a comment-only state-header edit; use the
  later ABI32 receipt or final independent gate for current header hashes.

Sanitizer options are `detect_leaks=1:halt_on_error=1` and
`halt_on_error=1:print_stacktrace=1`; successful runs had no sanitizer findings.
Compile logs retain existing unused `p2_math_nil`/`baselib_trace` warnings and
ABI32 `be_solidifylib.c:221` pointer-width warning; they were not hidden or fixed.

### RED and failed configurations are retained, not rewritten

Original pre-production command:
`/opt/hermes/.venv/bin/python tools/test_p2_vm_state.py --cc gcc`.
`build/p2-vm-state-88falret/results.json` records successful generation/compile,
then exit 1 for all three original cases: other VM reset removed A's task,
other VM RNG calls changed A's next value, and all five xorshift answers failed
against the old global `+7919` counter. All original snapshot input hashes were
rechecked against those saved files during this repair. Earlier fixture
link/root problems in `2o1pru7h` and `6t5qzvoh` are not claimed as production RED.
The retained original executable was also re-executed for all three cases:
each returned 1 with the same 1/1/5 failure counts. Commands and raw outputs are
in `build/f3-state-repair/red-recheck-*.log` and `red-recheck.json`.

`build/p2-vm-state-atr88qx3/` retains the first extended-test run (7/9). Two new
fixtures incorrectly expected a retained `done` status. Inspection of existing
`p2_task_interpret_result`/`p2_task_free_slot` established that `task.done` frees
slots. Assertions were corrected to require `free`, `!chk`, released roots and
stop returning false, not removed; production behavior was not changed to fit
tests. Original RED cases remain intact.

**Concrete out-of-scope blocker for parent:**

```sh
/opt/hermes/.venv/bin/python tools/test_p2_vm_state.py --cc gcc --sanitize \
  --abi 32 --bint 32 --no-small-pools \
  --builder local/berry-p2-dev:cat8.8.9 \
  --docker-host-root /DATA/AppData/hopeful_renaud/propeller2/berry
```

This intentionally remains failing: `build/p2-vm-state-8q5hgcts/results.json`,
5/9 passed, runner exit 1. Four script-parsing groups report ASan heap-buffer
writes immediately beyond an 8-byte allocation in `be_vector_push`.
`src/be_mem.c:215-222` still returns the old pointer for a same-pool-size-class
resize, while its `BE_P2_NO_SMALL_POOLS=1` allocator (`:279-286`) allocates exact
sizes instead of rounded slots. That shortcut is invalid with pools disabled.
The implicated allocator code is identical to repair-start source and is outside
this task's owned core edits. No allocator patch, padding shim, sanitizer
suppression, case removal or success substitution was applied. The same complete
suite is green with the ordinary small-pool configuration; that is not proof of
the failing configuration. Parent must resolve this separately before relying
on that build profile. The runner keeps `--no-small-pools` as an explicit,
fail-closed diagnostic option, never a default or a passing skip.

## Source hashes and preservation

Candidate SHA-256 (full compile inputs also in each `results.json`):

```text
885623809593c17cf8abc6ac0a65eeeaf8b5a7435dd3c1808a5e600fc9a1bc5c  src/be_vm.h
daab41a36e0f2ba2a82b2a33a9e274f1adfb723882997eefdc38607402150061  src/be_vm.c
e1ac0f271f23633a452f0198c11f5d3257ec9224ee63aef2254a900fbbe5eb68  port/p2/include/p2_vm_state.h
5e3e5412ca9792deb85eab249e83fd791cca7c8d176ee70321e9a33efbc4e9d1  port/p2/runtime/p2_vm_state.c
3d5c7ffcd7fe020110f731a68b23007a0e656447f3f81d8c0d0084bbc8883295  port/p2/overrides/be_tasklib_p2.c
1a327ed14bb0fa1c093e4b270cd95629407325b4dc2c6be5ad97682c30446eca  port/p2/overrides/be_math_stringlib_p2.c
5159f9d216910edd39fefa6933c67c4e14c7c5f6a40001029e7fd4ff7dbc15df  mk/p2.mk
9d4329f8c7fe3d0a8415df3d3d5f7d455d4974cf7a6957ef2ff6d0d318e6f108  tests/native/test_p2_vm_state.c
6f6c34f15285f50fbd74c93eb9b7108e80ddcd3ddf3f2555fae8a8472fa9a575  tools/test_p2_vm_state.py
59a6eed3fe03e9e26c79282eedc7d5fe8c9fbce0bc307ecd7a06ba1a5e14047d  tests/native/test_p2_clock.c
09cca4ba906e8a0020e1c1ffc14a4c5177e32d75d0de9fb92a7343a645f9b8b9  tools/test_p2_clock.py
```

Selected genuine RED snapshot hashes:

```text
d2f62e40f2148d2bd3deaaf69bdf1089d7943bb80593c19812db8a79bf2d2850  port/p2/overrides/be_tasklib_p2.c
e5322d91fc2dbddc963493531cd9defb7a3b75a8aa0f93792467c6ebafa57375  port/p2/overrides/be_math_stringlib_p2.c
ba82f471ade3435bce7fdc88a7ee91247cb6600050e8f488966f4a159ac78af8  tests/native/test_p2_vm_state.c
663acd87cb55b3add973aa83a447b74d32f7f9425e9b21560c6ddadd8c1a08f1  tools/test_p2_vm_state.py
```

`build/f3-state-repair/initial-hashes.json` and `initial-parent.diff` retain the
repair-start state. This repair changes only the native-state header comment,
state C tests, state Python runner, this newly created report, and CHECKPOINT.md.
Existing implementation files are retained: the minimal tail/callback changes,
explicit scheduler state, xorshift integration and `p2_vm_state.c` runtime-list
entry. Parent's OP_IMPORT fix and every unrelated source change are preserved.
No full-program lock, physical service or `be_p2lib_p2.c` edit was made.

Final supplemental verification: `build/f3-state-repair/verification.json`
records seven GREEN receipts checked against current source hashes, ELF64/x86-64
and ELF32/i386 binaries, required-artifact existence, and 582 protected initial
files unchanged. Missing compiler `/nonexistent/f3-gcc` correctly exits 2 at
argparse prerequisite validation; `/bin/false` correctly exits 1 with 0/9 cases
and `success=False`. Logs stay under the same ignored evidence directory. An
initial supplemental wrapper incorrectly expected missing-compiler exit 1;
the runner itself was already correctly failing with exit 2 and was not changed.
Repository HEAD moved concurrently to parent commit `4c5241c` during verification;
source hashes remained unchanged outside the three allowed repair edits. This
worker made no commit or index changes.

## Remaining F3/F6 and limitations

- Actual P2/Catalina integration, Hub/PSRAM footprint, target OOM behavior,
  hardware lifetime and all release gates remain for parent. Host GCC results
  are neither a Catalina build receipt nor a board execution receipt.
- Resolve the no-small-pools realloc blocker above if that profile is needed.
- Shared physical services, registry/PSRAM cache/SD/constructor diagnostic globals
  and locks in `be_p2lib_p2.c` are not solved by this context foundation.
- LARGE VM launch still uses an even worker cog and its paired cache cog. This
  does not establish one VM on each of all eight cogs.
- Independent state is not thread safety. Full-program runtime locking remains
  required; same-VM concurrent entry and experimental shared-VM cog execution
  were not enabled or tested. No parallel P2 execution proof is claimed.
- F6 hardware/transport/release verification is outside this bounded candidate.
  Parent must independently execute the unchanged command gates and review
  these qualifications before deciding whether to integrate.
