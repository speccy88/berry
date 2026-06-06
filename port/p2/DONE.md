# P2 Edge32 SD/XMM DONE

Date created: 2026-06-06

Source documents:

- `port/p2/docs/P2_EDGE32_SD_XMM_HANDOFF.md`
- `port/p2/goal.md`

Maintenance rule:

- Update this file and `port/p2/TODO.md` in the same change whenever a feature is added, verified, or intentionally declared unsupported.
- Record only implemented or verified facts here.
- Keep broader goals, partial work, and unverified claims in `TODO.md`.

## Verified hardware baseline

- [x] Verified work is targeting a P2 Edge 32 MB board.
- [x] Verified board path in the handoff is `/dev/cu.usbserial-P97cvdxp`.
- [x] Verified Catalina/lcc through Docker cache at `.third_party_cache/catalina-v8.8.9-build`.
- [x] Verified Catalina remains the working toolchain path for this P2 work.

## Edge32 flash path

- [x] `make p2-edge32-flash PORT=/dev/cu.usbserial-P97cvdxp TOOLCHAIN=catalina CATALINA_USE_DOCKER=1 CATALINA_DIR=.third_party_cache/catalina-v8.8.9-build` is the verified Edge32 flash command from the handoff.
- [x] Edge32 image boots from SPI flash.
- [x] Current Edge32 image size in the handoff is `499008` bytes.
- [x] Basic REPL arithmetic check passes: `print(6*7)` returns `42`.
- [x] Basic REPL string check passes: `s="abc"; print(s+"def")` returns `abcdef`.
- [x] Basic REPL map check passes: `m={"a":2,"b":5}; print(m["a"]+m["b"])` returns `7`.
- [x] SD-backed `import math; print(math.sqrt(81))` prints `9` on the Edge32 path covered by the handoff.

## Standalone XMM flash path

- [x] `make p2-xmm-flash PORT=/dev/cu.usbserial-P97cvdxp TOOLCHAIN=catalina CATALINA_USE_DOCKER=1 CATALINA_DIR=.third_party_cache/catalina-v8.8.9-build` is the verified standalone XMM flash command from the handoff.
- [x] Standalone XMM flash boots from SPI flash after the expected roughly 25-30 second copy delay.
- [x] Current standalone XMM flash image size in the handoff is `1225376` bytes.
- [x] XMM banner reports `[xmm profile]`.
- [x] XMM banner reports `Berry heap external`.
- [x] XMM banner reports `XMM 16777216 B`.
- [x] XMM banner reports `block 16777216 B @ 16777216`.
- [x] `p2.heap_info()` reports `external_heap: true`.
- [x] `p2.c_allocator_test(262144)` returns `ok: true`.
- [x] Basic REPL checks pass on standalone XMM flash.
- [x] SD-backed `import math; print(math.sqrt(81))` prints `9` on standalone XMM flash.

## XMM PSRAM Berry VM heap progress

- [x] Changed the XMM profile Berry heap target from a small fixed `512 KiB` arena to a `15 MiB` VM heap arena intended for Catalina's pointer-addressable lower PSRAM/XMM window.
- [x] Changed `p2_heap.c` so the main XMM Berry heap arena is allocated at runtime through Catalina's C allocator instead of emitting a huge static image segment; COMPACT Edge32 keeps the existing static Hub heap fallback.
- [x] Added adaptive XMM heap arena allocation so the runtime can fall back below the `15 MiB` target in `512 KiB` steps instead of leaving the VM heap silently unready.
- [x] Added `p2.heap_info()` / `p2.status_info()` diagnostics for requested heap size, actual ready heap size, heap base pointer, readiness, and allocation failure.
- [x] Made the reported actual heap size return `0` if the main arena cannot initialize, so XMM hardware tests can distinguish a real PSRAM-backed VM heap from a failed allocation.
- [x] Preserved the upper PSRAM block/cache split by leaving `BE_P2_PSRAM_BLOCK_BASE == BE_P2_XMM_BYTES` for XMM, so the remaining 16 MiB stays available for cache/storage work.
- [x] Updated the standalone XMM flash target to prefer loadp2 `-FLASHRAW` for the prebuilt bootable SPI image, with the existing `-HIMEM=flash @80000000=...` raw-image path retained as a compatibility fallback.
- [x] Hardware-tested the adaptive XMM heap arena on `/dev/cu.usbserial-P97cvdxp`: standalone XMM flash boot reached `berry>`, `p2.heap_info()` reported `main_ready: true`, `external_heap: true`, `main_requested: 15728640`, `main_actual: 7864320`, `main_alloc_failed: false`, and `main_base: 1123920`.
- [x] Hardware-tested remaining Catalina allocator headroom after the XMM Berry heap arena allocation: `p2.c_allocator_test(262144)` returned `ok: true`.
- [x] Confirmed the latest standalone XMM flash image still preserves the intended PSRAM split in the banner: `XMM 16777216 B` and `block 16777216 B @ 16777216`.
- [x] Left recovery of the remaining lower XMM heap capacity, filesystem service repair, GC correctness, and multiple VM heaps open in `TODO.md`.
- [x] Tested a single huge static XMM C arena and rejected it: Catalina emitted `Data buffer overflow` for both `15 MiB` and `8 MiB` static arrays, so the VM heap cannot safely be one giant static C object in this build path.
- [x] Added a chunked external VM heap allocator for XMM so Berry can combine multiple smaller Catalina allocations into one logical VM heap while rejecting chunks that would start in or cross the upper PSRAM block/cache window.
- [x] Hardware-tested the chunked XMM heap on `/dev/cu.usbserial-P97cvdxp`: standalone XMM flash boot reached `berry>`, `p2.heap_info()` reported `main_ready: true`, `external_heap: true`, `main_requested: 15728640`, `main_actual: 15651832`, `main_segments: 4`, `main_alloc_failed: false`, and `main_base: 1125360`.
- [x] Hardware-smoked Berry object allocation on the chunked XMM heap with a `2000` entry list of strings; the REPL returned `2000`, and a follow-up `p2.heap_info()` kept `main_actual: 15651832` and `main_segments: 4`.
- [x] Added accepted-chunk boundary diagnostics to `p2.heap_info()` so the XMM VM heap reports `main_low`, `main_high`, `main_segments`, and whether accepted heap chunks cross the upper PSRAM block/cache window.
- [x] Hardware-tested the accepted-chunk boundary diagnostics on `/dev/cu.usbserial-P97cvdxp`: standalone XMM flash boot reached `berry>`, `p2.heap_info()` reported `main_actual: 15651136`, `main_segments: 4`, `main_low: 1126056`, `main_high: 16777216`, `main_crosses_block_window: false`, and `c_sbrk: 17903960`.
- [x] Hardware-smoked Berry object allocation after boundary diagnostics with a `5000` entry list of longer strings; the REPL returned `5000`, and follow-up `p2.heap_info()` kept `main_high: 16777216` and `main_crosses_block_window: false`.
- [x] Added `CATALINA_HEAP_TOP` build plumbing and defaulted the XMM profile to `-H16M` so Catalina's C allocator is capped below the upper PSRAM block/cache window instead of probing into the cache half.
- [x] Passed `CATALINA_HEAP_TOP` through the Catalina Docker build wrapper so Docker and direct Catalina builds use the same XMM heap ceiling.
- [x] Hardware-tested the capped XMM build on `/dev/cu.usbserial-P97cvdxp`: standalone XMM flash boot reached `berry>`, `p2.heap_info()` reported `c_sbrk: 16331048`, `main_actual: 15204352`, `main_segments: 4`, `main_high: 16330432`, and `main_crosses_block_window: false`.
- [x] Verified the capped XMM build leaves small Catalina C allocations usable: `p2.c_allocator_test(65536)` returned `ok: true` with `c_sbrk: 16593200`.
- [x] Verified the capped XMM build rejects larger Catalina C allocator growth before crossing the upper PSRAM block/cache window: `p2.c_allocator_test(1048576)` returned `ok: false` at `malloc`, and `p2.c_allocator_test(262144)` returned `ok: false` at `realloc` while `c_sbrk` stayed at `16593200`.
- [x] Hardware-smoked Berry object allocation on the capped XMM heap with a `5000` entry list of longer strings; the REPL returned `5000`, and follow-up `p2.heap_info()` kept `c_sbrk: 16593200`, `main_actual: 15204352`, `main_high: 16330432`, and `main_crosses_block_window: false`.
- [x] Added a dormant P2-only GC phase trace behind `BE_P2_TRACE_GC_COLLECT` for future XMM GC debugging without changing normal builds.
- [x] Added a dormant P2-only native GC module entry trace behind `BE_P2_TRACE_GC_MODULE` for future native-module call-path debugging without changing normal builds.
- [x] Added `/tests/p2/smoke_xmm_heap.be` as an XMM external-heap GC/churn smoke using the working P2-specific `p2.gc()` collector entrypoint.
- [x] Diagnosed that enabling the native `gc` module for XMM makes `import gc` succeed, but `print(gc.allocated())` wedges the REPL before the P2 module-entry trace prints; the public GC module exposure was backed out to avoid leaving a broken callable module in the default XMM image.
- [x] Restored and reflashed the quiet capped XMM image after GC diagnostics; hardware boot on `/dev/cu.usbserial-P97cvdxp` reached `berry>`, and `p2.heap_info()` reported `c_sbrk: 16331048`, `main_actual: 15204352`, `main_high: 16330432`, and `main_crosses_block_window: false`.
- [x] Added direct `p2.gc()` to the always-on P2 lazy member path so XMM builds can force Berry GC without enabling the broken generic `gc` module.
- [x] Hardware-tested `p2.gc()` on `/dev/cu.usbserial-P97cvdxp`: `print(type(p2.gc), p2.gc())` returned `function {'after': 7688, 'before': 8904, 'freed': 1216}` without wedging the REPL.
- [x] Hardware-smoked XMM external-heap object churn with maps, lists, and long strings through the direct REPL: a `384` object live batch reduced heap free space to `14918696`, stayed below the block/cache window with `main_high: 16330872` and `main_crosses_block_window: false`, then `p2.gc()` after `batch=nil` freed `260670` bytes and restored heap free space to `15190312`.
- [x] Wired `/tests/p2/smoke_xmm_heap.be` into `/tests/p2/smoke_all.be`; full SD-backed execution remains pending on the XMM SD upload/filesystem repair tracked in `TODO.md`.
- [x] Extended `scripts/p2/repl_smoke.py` with repeatable custom `--command` / `--expect` support so hardware smoke tests can run paced REPL command sequences without relying on SD uploads.
- [x] Fixed `scripts/p2/repl_smoke.py` serial opening to hold DTR and RTS low before opening the port, avoiding the pyserial-triggered P2 reset/boot disruption seen when the runner waited for `berry>` and saw no banner.
- [x] Added a named serial `xmm-heap` suite to `scripts/p2/repl_smoke.py` for SD-independent XMM heap/GC smoke testing.
- [x] Hardware-tested the named serial `xmm-heap` suite on `/dev/cu.usbserial-P97cvdxp`; it booted the XMM image, verified `p2.gc()` returns a function/result map, allocated `512` map/list/string objects, consumed `425416` bytes of Berry heap, kept `main_crosses_block_window` false, then `p2.gc()` freed `393623` bytes and the final boundary/recovery check printed `false true`.
- [x] Added a named serial `xmm-heap-cross` suite to `scripts/p2/repl_smoke.py` for SD-independent cross-segment XMM heap/GC smoke testing.
- [x] Hardware-tested the named serial `xmm-heap-cross` suite on `/dev/cu.usbserial-P97cvdxp`; it booted the XMM image, allocated `1280` long-string objects, proved heap consumption exceeded `4194304` bytes, kept `main_crosses_block_window` false, then `p2.gc()` freed `4955077` bytes and the final boundary/recovery check printed `false true`.
- [x] Hardware-tested a repeated `xmm-heap-cross` soak on `/dev/cu.usbserial-P97cvdxp` with `--repeat 2`: both iterations allocated `1280` long-string objects, proved heap consumption exceeded `4194304` bytes, kept `main_crosses_block_window` false, and ended with the recovery check `false true`.
- [x] In the repeated `xmm-heap-cross` soak, iteration 1 `p2.gc()` freed `4955077` bytes and iteration 2 `p2.gc()` freed `5937020` bytes, confirming repeated cross-segment allocation/free/GC cycles recover external XMM heap memory without crossing into the upper PSRAM block/cache window.
- [x] Added non-invasive `p2.heap_info()` capacity diagnostics for future independent VM heap partitioning: `vm_partition_bytes`, `vm_partition_capacity`, and `vm_partition_remainder`. These report how the current XMM heap arena could be divided before real child `bvm` heap allocation is implemented.
- [x] Added internal P2 heap partition arenas and per-cog heap-context selection primitives so future child `be_vm_new()` lifecycles can allocate from a selected independent PSRAM-backed heap instead of the default main VM arena. The default main VM path remains unchanged until a child VM wrapper explicitly selects a partition.
- [x] Extended `p2.heap_info()` with VM partition accounting fields: `vm_partition_max`, `vm_partition_created`, `vm_partition_total`, and `vm_partition_current`.
- [x] Added allocator ownership guardrails so `free()` or `realloc()` in the wrong selected heap context increments diagnostics and refuses to corrupt another heap arena.
- [x] Extended `p2.heap_info()` with wrong-context allocator diagnostics: `wrong_free_count` and `wrong_realloc_count`.
- [x] Added guarded `p2.vm_probe(slot=0, bytes=vm_partition_bytes)` diagnostic to create and delete a child Berry VM inside a selected PSRAM heap partition without running user code.
- [x] Added a named serial `xmm-vm-probe` suite to `scripts/p2/repl_smoke.py` for SD-independent hardware validation of child VM create/delete inside a selected PSRAM heap partition.
- [x] Extended `p2.vm_probe(slot, bytes, source)` so the diagnostic can run a controlled child Berry script inside the selected PSRAM heap partition and report only status/metrics back to the parent VM.
- [x] Extended the `xmm-vm-probe` serial suite to run a tiny child script and verify `child_run_result == 0`, empty child stack cleanup, restored parent heap context, and zero wrong-context allocator events.
- [x] Added `p2.vm_probe_many(count=2, bytes=vm_partition_bytes, source=nil)` to exercise child VM create/run/delete across multiple selected PSRAM heap partitions while returning only aggregate status and allocator safety metrics to the parent VM.
- [x] Extended the `xmm-vm-probe` serial suite to exercise `p2.vm_probe_many(2, ..., source)` and verify both child VM partitions create, run, delete, clean their stacks, restore the parent heap context, and avoid wrong-context allocator events.
- [x] Added guarded `p2.vm_call_probe(slot, bytes, source, name, ...int_args)` diagnostic to run a named child VM function with integer arguments and report only primitive result/status metrics to the parent VM.
- [x] Extended the `xmm-vm-probe` serial suite to exercise child function execution with `add(19, 23)` returning integer result `42` across the parent/child VM boundary.
- [x] Added bounded child string result copy-out to `p2.vm_call_probe()` by copying the child VM string into a fixed C buffer before deleting the child VM and creating a fresh parent VM string in the result map.
- [x] Extended the `xmm-vm-probe` serial suite to exercise bounded child string result copy-out with a child function returning `"child-ok"`.
- [x] Extended `p2.vm_call_probe()` primitive argument copy-in to support copied int, bool, nil, and bounded string arguments while rejecting unsupported live object/function argument transfer.
- [x] Extended the `xmm-vm-probe` serial suite to exercise copied string, bool, nil, and int arguments into a child VM function and bounded string result copy-out back to the parent VM.
- [x] Added read-only `p2.vm_partition_info(slot)` diagnostics for individual child VM heap partitions, including ready state, total/free/used bytes, low/high addresses, and current selected partition.
- [x] Extended the `xmm-vm-probe` serial suite to check per-partition readiness and nonzero total/free capacity after multiple child VM partitions are created.
- [x] Tightened child VM probe ownership boundaries by copying `source` and function-name text into bounded C buffers before selecting a child heap partition, so child execution no longer depends on parent-owned Berry string pointers after heap-context switching.
- [x] Added read-only `p2.vm_copyable(value)` diagnostics to classify VM-boundary transfer support: nil, bool, int, and bounded string are copyable; list, map, function/closure, and other live objects are rejected.
- [x] Extended the `xmm-vm-probe` serial suite to verify the VM-boundary copy/reject table for primitive values and live objects.
- [x] Added remaining child-partition capacity diagnostics to `p2.heap_info()`: `vm_partition_free_capacity` and `vm_partition_free_remainder`, derived from current parent main-heap free space after any child partitions have already been reserved.
- [x] Extended the `xmm-vm-probe` serial suite to sanity-check total partition capacity versus created partitions and remaining free partition capacity reporting.
- [x] Rebuilt the focused Catalina XMM target after child VM partition/copy-boundary changes: `make p2-xmm TOOLCHAIN=catalina CATALINA_USE_DOCKER=1 CATALINA_DIR=.third_party_cache/catalina-v8.8.9-build PORT=/dev/cu.usbserial-P97cvdxp` completed successfully with image `687040` bytes.
- [x] Reflashed the focused Catalina XMM image with `make p2-xmm-flash ... PORT=/dev/cu.usbserial-P97cvdxp`; local `loadp2` still lacks `-FLASHRAW`, so the make target used the equivalent `-HIMEM=flash` raw-image fallback and installed the standalone SPI flash image.
- [x] Hardware-tested the `xmm-vm-probe` serial suite on `/dev/cu.usbserial-P97cvdxp`; the board booted XMM profile build `Jun 06 2026 20:09:24` and the suite passed.
- [x] Hardware-verified `p2.vm_probe()` child VM partition create/delete and controlled script execution: `partition_ready`, `selected`, `child_created`, `child_deleted`, and `child_ran` all printed `true`, `child_run_result child_stack_top` printed `0 0`, and wrong-context deltas printed `0 0 -1`.
- [x] Hardware-verified `p2.vm_probe_many(2, ..., source)` across two child VM heap partitions: partition ready/selected/created/deleted/ran/run-ok counts printed `2 2 2 2 2 2`, stack-clean/wrong-context/current/failure/result printed `2 0 0 -1 -1 0`, and global wrong-context counters stayed `0 0`.
- [x] Hardware-verified `p2.vm_call_probe()` primitive child function call behavior: `add(19, 23)` returned integer result `42`; string result copy-out returned `child-ok`; mixed copied string/bool/nil/int args returned bounded string result `child-42`.
- [x] Hardware-verified per-partition diagnostics through `p2.vm_partition_info(0)` and `(1)`: both partitions reported ready, current `-1`, and nonzero total/free capacity.
- [x] Hardware-verified remaining partition capacity diagnostics through `p2.heap_info()`: total partition capacity was at least the created count and `vm_partition_free_capacity` was nonnegative after partitions were reserved.
- [x] Hardware-verified `p2.vm_copyable(value)` copy/reject classification: nil, bool, int, and string printed `true true true true`; list, map, and function values printed `false false false`.
- [x] Exposed the guarded child VM source/name function-call path as `p2.vm_call(...)`, sharing the already validated primitive copy-in/copy-out implementation used by `p2.vm_call_probe(...)`.
- [x] Extended the `xmm-vm-probe` serial suite to exercise `p2.vm_call(...)` with `api_add(5, 37)` returning integer result `42`.
- [x] Hardware-verified production-facing `p2.vm_call(...)` on `/dev/cu.usbserial-P97cvdxp`: focused XMM build succeeded with image `687136` bytes, flash installed via the `-HIMEM=flash` raw-image fallback, board booted build `Jun 06 2026 20:14:20`, and `xmm-vm-probe` passed with `api_add(5, 37)` returning integer result `42` plus wrong-context/current output `0 0 -1`.
- [x] Extended `p2.vm_call(...)` to accept a named, non-captured parent Berry closure as the function selector. The closure object itself is not transferred; only its validated name is copied before the child VM loads source and calls the child-side function of the same name.
- [x] Extended the `xmm-vm-probe` serial suite to exercise the non-captured closure-name bridge with parent `bridge_add` and child source defining `bridge_add`.
- [x] Hardware-tested the named non-captured parent closure bridge on `/dev/cu.usbserial-P97cvdxp`: focused XMM build succeeded with image `687840` bytes, flash installed via the `-HIMEM=flash` raw-image fallback, board booted build `Jun 06 2026 20:19:04`, and `xmm-vm-probe` passed with parent `bridge_add` mapped to child source `bridge_add(13, 29)` returning integer result `42` plus wrong-context/current output `0 0 -1`.
- [x] Added `p2.vm_partition_release(slot)` as a VM lifecycle primitive for returning an unselected child VM heap partition to the main PSRAM-backed Berry heap. The release path refuses to free a partition selected by any cog, clears partition metadata, and exposes before/after main-heap and partition accounting in the returned map.
- [x] Extended the `xmm-vm-probe` serial suite to cover `p2.vm_partition_release(slot)`: release slot `3`, check main heap/partition accounting recovery, recreate slot `3` through another `p2.vm_call(...)`, then release it again.
- [x] Hardware-tested `p2.vm_partition_release(slot)` on `/dev/cu.usbserial-P97cvdxp`: focused XMM build succeeded with image `689600` bytes, flash image `951748` bytes installed via the `-HIMEM=flash` raw-image fallback, board booted build `Jun 06 2026 20:24:39`, and `xmm-vm-probe` passed. The release check printed `true true false -1`, heap accounting recovery printed `true true true`, recreation through `p2.vm_call(...)` returned integer result `42`, and the second release again printed `true true false -1`.
- [x] Added `p2.vm_call_once(...)` as a one-shot child VM function-call API using the same primitive copy-in/copy-out boundary as `p2.vm_call(...)`, but releasing the selected PSRAM child VM partition before returning to the parent.
- [x] Extended the `xmm-vm-probe` serial suite to cover `p2.vm_call_once(...)`: run `api_add(21, 21)` in slot `3`, verify result `42`, verify release attempted/succeeded, and verify partition/main-heap accounting recovery.
- [x] Hardware-tested `p2.vm_call_once(...)` on `/dev/cu.usbserial-P97cvdxp`: focused XMM build succeeded with image `690816` bytes, flash image `952964` bytes installed via the `-HIMEM=flash` raw-image fallback, board booted build `Jun 06 2026 20:28:30`, and `xmm-vm-probe` passed. The one-shot call returned `0 0 1 42`, release status printed `true true false -1`, and release accounting recovery printed `true true true`.
- [x] Added synchronous persistent child VM handle diagnostics on top of PSRAM heap partitions: `p2.vm_open(slot, bytes)` creates a child `bvm` in a selected partition, `p2.vm_eval(slot, source)` runs source on the same child VM, `p2.vm_get(slot, name)` copies primitive child globals back to the parent, and `p2.vm_close(slot)` deletes the child VM and releases the partition.
- [x] Extended the `xmm-vm-probe` serial suite with persistent child VM handle coverage: open slot `3`, evaluate two separate source snippets that mutate the same child global, read the persisted integer value back as `42`, close the child VM, and verify partition/main-heap accounting recovery.
- [x] Hardware-tested persistent child VM handles on `/dev/cu.usbserial-P97cvdxp`: focused XMM build succeeded with image `699104` bytes, flash image `961252` bytes installed via the `-HIMEM=flash` raw-image fallback, board booted build `Jun 06 2026 20:33:17`, and `xmm-vm-probe` passed. `p2.vm_open(3, ...)` printed `true true true true -1`, two `p2.vm_eval(...)` calls printed `true true 0 0 -1`, `p2.vm_get(3, "child_persist")` printed `true true true 1 42 -1`, `p2.vm_close(3)` printed `true true true false false -1`, and close accounting recovery printed `true true true`.
- [x] Extended the `xmm-vm-probe` serial suite with simultaneous child VM coverage: keep slots `2` and `3` open at the same time, mutate separate child globals to `221` and `333`, verify both partitions remain ready, then close/release both child VMs.
- [x] Hardware-tested two simultaneous persistent child Berry VMs on `/dev/cu.usbserial-P97cvdxp`: the current XMM image booted build `Jun 06 2026 20:33:17` with image `699104` bytes, flash used the `-HIMEM=flash` raw-image fallback, and `xmm-vm-probe` passed. Slots `2` and `3` both opened active with parent current `-1`, separate evals returned `0 0 -1 -1`, `p2.vm_get(...)` returned independent values `221 333 -1 -1`, both partition infos reported ready, and closing both printed `true true false true true false`.
- [x] Added `p2.vm_invoke(slot, name_or_named_closure, ...primitive_args)` for calling functions already loaded inside a persistent child VM. It uses the same primitive copy-in/copy-out boundary as `p2.vm_call(...)`: int, bool, nil, and bounded string arguments/results are supported, while live object transfer remains rejected.
- [x] Extended the `xmm-vm-probe` serial suite with `p2.vm_invoke(...)` coverage for a single persistent child VM function using child-side persisted state, plus simultaneous slots `2` and `3` invoking separate child-side `bump(...)` functions.
- [x] Hardware-tested `p2.vm_invoke(...)` on `/dev/cu.usbserial-P97cvdxp`: focused XMM build succeeded with image `703808` bytes, flash image `965956` bytes installed via the `-HIMEM=flash` raw-image fallback, board booted build `Jun 06 2026 20:40:41`, and `xmm-vm-probe` passed. A child-resident `child_add(10, 20)` using persisted child state returned `true true true 0 1 72 -1` with wrong-context/stack output `0 0 0`; simultaneous child VMs in slots `2` and `3` invoked separate `bump(...)` functions and returned `226 340 -1 -1`, with follow-up `p2.vm_get(...)` confirming `226 340 -1 -1`.
- [x] Prototyped experimental real-cog child VM diagnostics behind `BE_P2_ENABLE_EXPERIMENTAL_VM_COG`: blocking `p2.vm_cog_start(slot, name_or_named_closure, ...primitive_args)` starts a Catalina C cog, waits for it to select the child VM's PSRAM heap partition and invoke an already-loaded child function, then returns primitive result/status metrics; `p2.vm_cog_info(slot)` reports the most recent cog status, cog id, primitive result, stack cleanup state, and wrong-context allocator deltas.
- [x] Hardware-tested the first real-cog child VM prototype and intentionally did not count it as working: XMM build/flash/boot reached the REPL, but after `cs=p2.vm_cog_start(2,"bump",9)` the next REPL command produced no echo/output. The prototype is gated off by default with `BE_P2_ENABLE_EXPERIMENTAL_VM_COG=0`, and the default `xmm-vm-probe` suite no longer runs it until proper runtime isolation is implemented.
- [x] Added a Catalina hardware-lock guardrail for child VM runtime sections. The lock serializes child VM heap selection, persistent child VM `open/eval/get/invoke/close`, partition release, one-shot VM calls, and the gated real-cog child VM execution section; `p2.vm_lock_info()` exposes lock allocation, acquire count, contention count, and allocation failure diagnostics. This is a synchronization guardrail, not proof that Berry or Catalina are fully reentrant across cogs.
- [x] Rebuilt the focused Catalina XMM target after adding child VM runtime lock guardrails: `make p2-xmm TOOLCHAIN=catalina CATALINA_USE_DOCKER=1 CATALINA_DIR=.third_party_cache/catalina-v8.8.9-build PORT=/dev/cu.usbserial-P97cvdxp` completed successfully with image `707424` bytes.
- [x] Reflashed the lock-guarded XMM image with `make p2-xmm-flash ... PORT=/dev/cu.usbserial-P97cvdxp`; the generated standalone SPI flash image was `969572` bytes and local `loadp2` used the equivalent `-HIMEM=flash` raw-image fallback because `-FLASHRAW` is unavailable locally.
- [x] Hardware-tested the default synchronous child VM stack after adding runtime lock guardrails on `/dev/cu.usbserial-P97cvdxp`: the board booted XMM profile build `Jun 06 2026 21:02:33` with image `707424` bytes, and `python3 scripts/p2/repl_smoke.py --port /dev/cu.usbserial-P97cvdxp --suite xmm-vm-probe --startup-timeout 60 --timeout 120` passed. The suite covered `p2.vm_probe`, `p2.vm_probe_many`, `p2.vm_call_probe`, `p2.vm_call`, non-captured closure-name bridge, `p2.vm_partition_release`, `p2.vm_call_once`, persistent `p2.vm_open/eval/get/invoke/close`, and two simultaneous persistent child VMs.
- [x] Extended `scripts/p2/repl_smoke.py` so the `xmm-vm-probe` suite now verifies `p2.vm_lock_info()` before and after the child VM lifecycle checks.
- [x] Hardware-verified Catalina child VM runtime lock diagnostics on `/dev/cu.usbserial-P97cvdxp` using the updated `xmm-vm-probe` suite against XMM profile build `Jun 06 2026 21:02:33`: initial `p2.vm_lock_info()` printed `true false 0 0` for available/failed/acquires/contentions, the child VM lifecycle suite passed, and final `p2.vm_lock_info()` printed `true false true true` for available/failed/acquires-positive/contentions-nonnegative.
- [x] Added `CATALINA_EXTRA_CFLAGS` build plumbing through `mk/p2.mk` and `scripts/build-p2-catalina-docker.sh`, so diagnostic Catalina defines can be passed without changing the default source macros or default P2 firmware behavior.
- [x] Added a focused `xmm-vm-cog` REPL smoke suite for opt-in real-cog child VM diagnostics. The default `xmm-vm-probe` suite remains synchronous and does not exercise `p2.vm_cog_start(...)`.
- [x] Built and flashed an opt-in experimental real-cog XMM diagnostic image with `CATALINA_EXTRA_CFLAGS='-DBE_P2_ENABLE_EXPERIMENTAL_VM_COG=1'`: the focused Catalina XMM build succeeded with image `719488` bytes, the generated standalone SPI flash image was `981636` bytes, and the board booted XMM profile build `Jun 06 2026 21:09:31`.
- [x] Hardware-tested the opt-in `xmm-vm-cog` diagnostic on `/dev/cu.usbserial-P97cvdxp` and confirmed the Catalina hardware-lock guardrail is not sufficient to make real-cog child VM execution safe yet. The suite reached `p2.vm_cog_start(2,"bump",9)` after opening a child VM and defining `bump`, but the next `print(cs[...])` command produced only a prompt with no output instead of `true 2 true 0 1 109 -1`.
- [x] Restored the board to the default gated-off XMM firmware after the failed experimental diagnostic: rebuilt/flashed without `CATALINA_EXTRA_CFLAGS`, producing image `707424` bytes and flash image `969572` bytes, then hardware-verified `xmm-vm-probe` passed on XMM profile build `Jun 06 2026 21:11:14`.
- [x] Added an opt-in C-only cog startup diagnostic, `p2.vm_cog_ping(input, slot=0)`, behind `BE_P2_ENABLE_EXPERIMENTAL_VM_COG`. It starts a Catalina C cog that does not touch Berry VM state, computes `(input * 2) + 1`, reports cog status/result/raw-running/stack-free diagnostics, and is covered by the focused `xmm-cog-ping` smoke suite.
- [x] Hardware-tested the opt-in C-only `xmm-cog-ping` diagnostic on `/dev/cu.usbserial-P97cvdxp`: the experimental XMM build with `CATALINA_EXTRA_CFLAGS='-DBE_P2_ENABLE_EXPERIMENTAL_VM_COG=1'` succeeded with image `721824` bytes, the standalone SPI flash image was `983972` bytes, and the board booted XMM profile build `Jun 06 2026 21:15:05`.
- [x] Confirmed the current real-cog failure is lower than Berry VM sharing: after `ping=p2.vm_cog_ping(41)`, the next `print(ping["started"], ping["status"], ping["result"], ...)` command produced only a prompt with no output instead of `true 2 83 false true -1`. This shows the current `_cogstart_C`/stack/runtime setup under standalone Catalina XMM is itself unsafe or incomplete.
- [x] Restored the board again to the default gated-off XMM firmware after the C-only cog diagnostic: rebuilt/flashed without `CATALINA_EXTRA_CFLAGS`, producing image `707424` bytes and flash image `969572` bytes, then hardware-verified `xmm-vm-probe` passed on XMM profile build `Jun 06 2026 21:16:35`.
- [x] Reconfirmed the board is on the default gated-off XMM firmware after the threaded diagnostic attempt: `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_USE_DOCKER=1 CATALINA_DIR=.third_party_cache/catalina-v8.8.9-build PORT=/dev/cu.usbserial-P97cvdxp` rebuilt/flashed with the `-HIMEM=flash` raw-image fallback, the board booted XMM profile build `Jun 06 2026 21:23:13`, and `python3 scripts/p2/repl_smoke.py --port /dev/cu.usbserial-P97cvdxp --suite xmm-vm-probe --startup-timeout 60 --timeout 120` passed.
- [x] Added a Catalina Docker build-wrapper safety guard: if the Catalina build path exits successfully but prints a fatal line beginning with `ERROR:`, `scripts/build-p2-catalina-docker.sh` now fails the build so flash targets cannot silently continue after Catalina linker/runtime errors.
- [x] Added explicit pointer/cache split diagnostics for the 32 MB PSRAM memory model: `p2.heap_info()` now names the 16 MiB pointer-addressable XMM window, the upper PSRAM block/cache base and size, and whether the live main Berry heap stays inside the pointer window; `p2.psram_info()` now mirrors the pointer window and cache window sizes.
- [x] Extended the default `xmm-vm-probe` serial smoke suite to assert the explicit 32 MB PSRAM split through both `p2.heap_info()` and `p2.psram_info()` before running the child VM partition/lifecycle checks.
- [x] Added a native upper-PSRAM cache reservation API for the explicit block/cache half: `p2.psram_cache_info()` reports the bottom-of-block cache cursor, remaining free bytes, and the top-1-MiB `libstore` source-cache reserve; `p2.psram_cache_reserve(size)` returns aligned address/size reservations in the upper block window for future cache users without hard-coding addresses.
- [x] Added `p2.psram_cache_reset()` so repeated diagnostics and future cache experiments can reset the native upper-PSRAM reservation cursor back to the bottom of the block/cache window without rebooting.
- [x] Added bounded native-cache-window transfer wrappers, `p2.psram_cache_write(address, data)` and `p2.psram_cache_read(address, size)`, which use Catalina PSRAM block transfers but reject ranges outside the native bottom-of-upper-PSRAM cache window.
- [x] Tightened `p2.psram_cache_read/write` so they only accept ranges that fall inside bytes already reserved by the native upper-PSRAM cache cursor; raw `p2.psram_read/write` remains available for explicit low-level block-window experiments.
- [x] Added lightweight native PSRAM cache reservation metadata: `p2.psram_cache_reserve(size, owner)` stores address, aligned size, and a bounded owner string in a fixed reservation table; `p2.psram_cache_entries()` exposes the current table and `p2.psram_cache_reset()` clears it.
- [x] Added handle-style native PSRAM cache transfers: `p2.psram_cache_write_entry(index, offset, data)` and `p2.psram_cache_read_entry(index, offset, size)` operate inside a reserved cache entry by index, avoiding raw-address use for future cache clients.
- [x] Added owner-based native PSRAM cache reservation lookup: `p2.psram_cache_find(owner)` returns reservation records whose bounded owner tag matches, so future cache users can recover entry indexes without manually walking the full table.
- [x] Added a conservative LIFO release primitive for native PSRAM cache reservations: `p2.psram_cache_release(index)` releases only the latest reservation, rewinds the native cache cursor, and keeps the fixed reservation table contiguous without pretending to support full eviction/compaction yet.
- [x] Extended `modules/p2mem.be` with `p2mem.native_cache()` and included the native upper-PSRAM reservation table in `p2mem.stats()` and `p2mem.cache()` so higher-level diagnostics can see both the existing `libstore` source cache and the new native cache reservations.
- [x] Added thin `p2mem` facade helpers for the native upper-PSRAM cache table: `native_cache_reset`, `native_cache_reserve`, `native_cache_find`, `native_cache_release`, `native_cache_read`, and `native_cache_write` delegate to the safe entry-index `p2.psram_cache_*` APIs.
- [x] Added a focused `xmm-p2mem-native-cache` serial smoke suite to exercise the higher-level `p2mem` native-cache facade over SD/module import: reset, reserve with owner metadata, owner lookup, entry-index write/read, stats/cache visibility, and LIFO release.
- [x] Added native PSRAM cache payload-size tracking: reservation records now report both reserved `size` and written-byte high-water `used`, and entry-index writes update `used`.
- [x] Added high-level blob helpers to `p2mem`: `native_cache_put(owner, data)` reserves and writes a payload, while `native_cache_get(owner)` finds the first owner-matching reservation and reads only its tracked `used` bytes.
- [x] Added native PSRAM cache write metadata: each reservation record now reports `write_count`, `last_write_offset`, and `last_write_size`, and entry-index writes update those fields for diagnostics and future cache accounting.
- [x] Added a simple native PSRAM cache write checksum: each entry-index write computes a deterministic byte-sum `last_write_checksum`, exposes it in the reservation record and write result, and adds smoke expectations for known payloads. This is diagnostic integrity metadata, not a replacement for future source/compiled hashes.
- [x] Added read-back checksum verification for native PSRAM cache entries: `p2.psram_cache_verify_entry(index)` reads the last written range back from upper PSRAM and compares it with `last_write_checksum`; `p2mem.native_cache_verify(index)` and `p2mem.native_cache_verify_owner(owner)` expose the check through the higher-level facade.
- [x] Added `p2mem.native_cache_get_verified(owner)`, which finds the newest owner-tagged native PSRAM cache entry, verifies the last written range with the read-back checksum path, and only then materializes the cached payload into the active VM.
- [x] Added `p2mem.native_cache_status(owner)`, which reports the newest owner-tagged native PSRAM cache entry's index, reserved size, used payload bytes, write count, checksum, and read-back verification status without materializing the cached payload.
- [x] Added `p2mem.native_cache_put_verified(owner, data)`, which reserves/writes a native upper-PSRAM cache blob and immediately verifies the write through the read-back checksum path before reporting success.
- [x] Added `p2mem.native_cache_replace_verified(owner, data)`, which performs the conservative owner-scoped replacement and immediately verifies the replacement payload through the read-back checksum path.
- [x] Added source-namespaced native cache helpers in `p2mem`: `native_source_put_verified(name, source)`, `native_source_status(name)`, `native_source_get_verified(name)`, and `native_source_release(name)` use `source:<name>` owner tags on top of the verified upper-PSRAM blob cache without changing the working import resolver yet.
- [x] Added explicit module-source native cache candidate helpers in `p2mem`: `native_module_source_put_verified(name)` reads source through the existing `libstore.cached_source(name)` path and stores it under a `module-source:<name>` owner tag, with status/get/release helpers layered on the verified upper-PSRAM cache facade. Normal import resolution is unchanged.
- [x] Added `p2mem.native_module_sources_plan(names)` to inspect a list of module-source cache candidates before reserving native upper-PSRAM entries, reporting per-module owner tags, source availability, byte counts, and total bytes.
- [x] Extended `p2mem.native_module_sources_plan(names)` with native-cache fit reporting: it now includes current native cache free bytes and `will_fit` so callers can decide whether a verified warm list should fit before reserving upper-PSRAM entries.
- [x] Extended `p2mem.native_module_sources_plan(names)` with reservation-alignment accounting: each item now reports `reserved_bytes`, the plan reports `total_reserved_bytes`, and `will_fit` is based on aligned reservation bytes rather than raw source length.
- [x] Added `p2mem.native_module_sources_warm_verified(names)` to explicitly warm a list of module source files into the verified upper-PSRAM cache facade and report requested, succeeded, failed, and per-module result records without changing import resolution.
- [x] Added `p2mem.native_module_sources_warm_if_fits(names)`, which plans a module-source preload, refuses to reserve upper-PSRAM cache entries when sources are missing or aligned reservation bytes exceed current native cache free space, and otherwise performs the verified warm.
- [x] Added batch module-source cache diagnostics/cleanup helpers in `p2mem`: `native_module_sources_status(names)` checks presence/verification for a warmed list, and `native_module_sources_release(names)` releases warmed module-source entries in reverse order to respect the current LIFO cache policy.
- [x] Added latest-owner lookup for native PSRAM cache reservations: `p2.psram_cache_find_latest(owner)` returns the newest matching reservation record, `p2mem.native_cache_find_latest(owner)` exposes it at the diagnostics/facade layer, and `p2mem.native_cache_get(owner)` now reads the newest owner match instead of the oldest.
- [x] Added `p2mem.native_cache_replace(owner, data)` as a conservative owner-scoped blob replacement helper: it releases the latest owner match only when the LIFO cache-release policy can safely rewind it, then reserves/writes the replacement payload.
- [x] Added `p2mem.native_cache_release_owner(owner)` as a conservative owner-scoped release helper: it finds the newest owner match and releases it only when the LIFO cache-release policy can safely rewind that entry.
- [x] Added owner-history helpers to the `p2mem` native cache facade: `native_cache_owner_history(owner)` exposes all owner-matching reservations, and `native_cache_release_owner_chain(owner)` repeatedly releases the newest owner match while the LIFO policy allows it.

## SD card and import behavior

- [x] SD/module loading is live-verified on the P2 Edge 32 MB board.
- [x] The current SD card answers raw SPI reads.
- [x] Berry detects that sector 0 is not a valid MBR/FAT boot sector for the current card.
- [x] Berry falls back to common FAT volume starts when sector 0 is invalid.
- [x] A valid FAT boot sector is found at sector `2048` for the current card.
- [x] `p2.fs_info("/")` reports `mount_result_name == "ok"` on the current card.
- [x] `p2.fs_info("/")` reports `partition_start == 2048` on the current card.
- [x] `p2.fs_info("/")` reports `volinfo_result_name == "ok"` on the current card.
- [x] `/modules/math.be` is visible and imports from SD.
- [x] `import math; print(math.sqrt(81))` returns `9` with the current card/image.

## Catalina direct-SD and mount fixes

- [x] Catalina patch stamp is `berry-p2-patch-v23`.
- [x] The direct-SD profile disables Catalina's auto-started `-lcx` SD plugin with `-C BERRY_P2_DIRECT_SD_IO`.
- [x] Catalina DOSFS is patched to use direct Hub bounce-buffer SD I/O instead of the PSRAM SD sector cache.
- [x] Patched `sd_sectread()` and `sd_sectwrite()` stubs compile with the active `CATALINA_MODEL`.
- [x] COMPACT `edge32` no longer uses incorrectly compiled LARGE sector stubs for the direct-SD path.
- [x] XMM still compiles the patched sector stubs as LARGE because the XMM profile sets `CATALINA_MODEL=LARGE`.
- [x] The patched SD service wrapper fails fast on a held service lock instead of spinning forever.
- [x] Berry no longer calls Catalina `_mount()` directly for this path.
- [x] Berry performs partition/volume setup with one static sector buffer.
- [x] Berry updates Catalina `__pstart` and `__vi` after its own setup.
- [x] Berry avoids the extra stack pressure from Catalina `_mount()` in the near-full Hub image.

## Diagnostics

- [x] `p2.fs_info()` exposes useful SD diagnostics.
- [x] Low-level SD sector tracing was moved out of noisy `printf()` paths and into queryable diagnostics.
- [x] Current diagnosis is documented: the current SD card has no usable sector-0 partition table but has a valid FAT boot sector at `2048`.

## Baseline documentation

- [x] Created `docs/architecture-current.md` to document the current build system, Berry port state, SD loader behavior, PSRAM behavior, P2 hardware bindings, tests, examples, memory map, and known limitations.
- [x] Created `docs/source-research.md` to summarize relevant Berry reference behavior, standard libraries/modules, import/package/solidify/advanced/FFI/memory behavior, Catalina P2 APIs, Propeller 2 architecture, smart-pin behavior, and uC/OS-II concepts for inspiration without copying code.
- [x] Created `docs/coverage-matrix.md` to track Berry language, standard library, expansion module, SD loader, PSRAM cache, P2 primitive API, smart pin, high-level wrapper, PASM, multicog VM, closure-in-cog, cooperative task, debug, example, test, unsupported, and board-dependent coverage.
- [x] Created `docs/roadmap.md` to preserve the full implementation sequence, risks, acceptance evidence, and completion audit path.
- [x] Created `docs/testing.md` to document host, P2 hardware, smoke, and soak test entrypoints plus remaining coverage gaps.

## Repeatable test entrypoints

- [x] Added `make test-host` to run the existing host Berry suite plus P2 host regressions.
- [x] Added `tests/p2/host_libstore_chunk.be` to the `make test-host` flow for fake-PSRAM `libstore` chunked source-cache behavior.
- [x] Added `tests/p2/host_taskspin.be` to the `make test-host` flow for host-simulatable cooperative task scheduler behavior.
- [x] Added `make test-p2 PORT=... BOARD=p2edge|p2edge32` to provision `/modules` and `/tests/p2`, then run the selected serial P2 smoke suite.
- [x] Added `make soak-p2 PORT=... BOARD=p2edge|p2edge32 HOURS=1` to repeat the selected serial P2 smoke suite for a duration.
- [x] Extended `scripts/p2/repl_smoke.py` with `--repeat`, `--duration-sec`, and `--sleep-sec` options for repeated smoke/soak runs.

## Grouped low-level P2 API

- [x] Added grouped `p2.clock` submodule aliases for `freq`, `mode`, `set`, `cnt`, `cnth`, `waitx`, `waitus`, `waitms`, `waitsec`, `waitcnt`, and `hubset`.
- [x] Added grouped `p2.cog` submodule aliases for `id`, `check`, `stop`, `attention`, `poll_attention`, and `wait_attention`.
- [x] Added grouped `p2.lock` submodule aliases for `new`, `ret`, `try`, `release`, and `check`.
- [x] Added grouped `p2.pin` submodule aliases for `dir_low`, `dir_high`, `write`, `low`, `high`, `toggle`, `float`, and `read`.
- [x] Added grouped `p2.cordic` submodule aliases for `rotxy`, `polxy`, and `xypol`.
- [x] Added grouped `p2.math` submodule aliases for `isqrt`, `muldiv64`, `rev`, and `encod`.
- [x] Added grouped `p2.rng` submodule alias for `rnd`.
- [x] Added grouped raw `p2.smart` submodule aliases for `wrpin`, `wxpin`, `wypin`, `akpin`, `rdpin`, `rqpin`, `start`, and `clear`.
- [x] Added `/tests/p2/smoke_p2_api.be` and included it in the P2 smoke module suite to cover the grouped low-level API surface.
- [x] Documented the grouped low-level P2 API in `port/p2/docs/README.md`.

## P2 memory diagnostics module

- [x] Added `modules/p2mem.be` as a diagnostics facade over current `p2`, `libstore`, and `gc` runtime state.
- [x] Added `p2mem.stats()` for heap, runtime memory, PSRAM, libstore/cache, module count, cache item count, and GC allocation state.
- [x] Added `p2mem.modules()` to report discovered module metadata, including module name, source path, compiled path placeholder, storage tier, hash placeholders, hub bytes, PSRAM bytes, cache hit/miss placeholders, refcount placeholder, pinned state, last-used placeholder, existence, and cached state.
- [x] Added `p2mem.cache()` to report current PSRAM source-cache status and cached item metadata.
- [x] Added `p2mem.gc()` to run Berry GC and report before/after allocation counts.
- [x] Added `p2mem.evict()` to reset the current `libstore` PSRAM source cache and report before/window/after state.
- [x] Added `p2mem` coverage to `/tests/p2/smoke_libraries.be`.
- [x] Added `p2mem` host regression coverage to `tests/p2/host_libstore_chunk.be`.
- [x] Documented `p2mem` in `port/p2/docs/README.md`.

## Low-level P2 validation

- [x] Tightened unsigned P2 native arguments so negative values raise `value_error` before Catalina/P2 primitive calls.
- [x] Added explicit cog ID validation for low-level cog helpers, enforcing `0..7`.
- [x] Added explicit hardware lock ID validation for low-level lock helpers, enforcing `0..15`.
- [x] Kept pin validation on the shared P2 bus path, enforcing pin range `0..63`.
- [x] Kept reserved-pin validation for P2 Edge SD pins `58..61`, serial pins `62..63`, and PSRAM pins `40..57` on PSRAM builds.
- [x] Added grouped API smoke checks for negative integer, cog range, lock range, pin range, and reserved-pin validation in `/tests/p2/smoke_p2_api.be`.

## Additional verified runtime coverage from `PORTING_STATUS.md`

- [x] Direct Edge32 PSRAM smoke checks are documented as live-verified: `p2.psram_test()["ok"]` returns `true`.
- [x] Bounded PSRAM block reads and writes are documented as live-verified with a `"cache"` round trip.
- [x] Chunked `libstore.cache_source("binary_heap")` and `libstore.cached_source(...)` are documented as round-tripping `1565` bytes through the PSRAM source cache path.
- [x] `modules/libstore.be` reports the SD-first model, scans `.be` modules, mirrors source text into the safe PSRAM block/cache window, warms discovered source modules, and materializes cached source back into active VM RAM only when requested.
- [x] On COMPACT Edge32, live Berry objects and bytecode remain in Hub RAM while PSRAM is used as block/cache storage.
- [x] On XMM, Catalina owns the lower PSRAM window for external-memory heap use and `libstore` uses the upper block window.
- [x] `modules/taskspin.be` provides a 32-slot Spin2-shaped cooperative task API from SD, including `TASKHLT()` diagnostics and task `stack_address` metadata.
- [x] Current or prior P2 REPL checks cover lists, maps, ranges, `string`, SD-loaded `math`, `json`, `bytes`, `open()`, `os`, and `os.path`.
- [x] SD file read, write, mkdir, remove, rename, cwd, and path helper behavior is documented as live-verified.
- [x] Native `i2c` is documented as live on the current Catalina path with BMP180 scan and chip-id coverage on `SCL=25`, `SDA=24`.
- [x] Native `spi` is documented as live on the current Catalina path for initialization and one-byte raw read behavior.
- [x] Current exposed P2 helpers include clock/counter, wait, cog, raw cog startup, CORDIC, pin, smart-pin, status, heap, PSRAM, and filesystem diagnostics.
- [x] `rtos` is documented as covering locks, queues, flags, timers, callbacks, debug helpers, channels, and process-style child-VM launch for current supported cases.
- [x] Captured closure transfer is intentionally guarded until safe closure transfer exists.

## Known implemented limitations

- [x] Catalina's PSRAM SD sector cache is known to conflict with Berry's intended PSRAM block window.
- [x] XMM/PSRAM builds now use direct SD I/O through Hub bounce buffers for this direct-SD profile.
- [x] The earlier COMPACT hang root cause is identified as sector stubs compiled unconditionally as LARGE.
- [x] Heavy low-level SD `printf()` tracing is identified as unsafe for good boot images.
- [x] The near-full Hub image stack-pressure issue around Catalina `_mount()` is identified and avoided.

## Not counted as done yet

- [x] This file intentionally does not claim full Berry standard-library coverage.
- [x] This file intentionally does not claim full `.bec` support.
- [x] This file intentionally does not claim a completed PSRAM module/cache tier.
- [x] This file intentionally does not claim full P2 API, smart pin, PASM, multicog closure, task scheduler, debug, performance, example, or documentation coverage.
- [x] Remaining roadmap work is tracked in `port/p2/TODO.md`.

## Top-level examples

- `examples/blink.be`: board LED blink using `p2.status_info()`, `p2.pin`, and `p2.clock`.
- `examples/repl_sd.be`: SD card directory inspection and optional `/berry/main.be` startup handoff.
- `examples/import_all_libs.be`: import sweep for top-level libraries including `binary_heap`, `math`, `p2mem`, `taskspin`, and optional `wifi`.
- `examples/json_sd.be`: JSON encode/write/read/decode flow on SD storage with a root-file fallback.
- `examples/file_sd.be`: basic SD file create/read/delete smoke example.
- `examples/cog_channel.be`: lightweight `rtos.channel` send/receive example across tasks.
- `examples/task_scheduler.be`: cooperative `taskspin` scheduler example with two tasks.
- `examples/cordic_demo.be`: grouped `p2.cordic` and `p2.math` numeric helper demo.
- `examples/psram_cache_stats.be`: `libstore` cache attempt plus `p2mem.cache()`/`p2mem.evict()` diagnostics.
- `examples/debug_report.be`: compact debug snapshot using `p2.debug_snapshot()` and `p2mem` reports.

## Berry compatibility smoke coverage

- [x] Added `tests/p2/smoke_compat.be` and wired it into `tests/p2/smoke_modules.be`.
- [x] Added scripted P2 smoke coverage for `print`, `classname`, `classof`, `str`, `number`, `int`, `real`, `bool`, `type`, `size`, `super`, `assert`, `compile`, `module`, `issubclass`, `isinstance`, `call`, `list`, `map`, `range`, `bytes`, `time`, `global`, `introspect`, `solidify`, and `strict`.
- [x] Extended `tests/p2/smoke_sd.be` to cover SD-backed `file`, `os`, and `os.path` behavior, including create/read/rename/remove and path helpers.
- [x] Expanded the SD-loaded P2 `math` module with pure-Berry finite numeric helpers for `exp`, `log`, `log10`, fractional/negative `pow`, `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`, `sinh`, `cosh`, and `tanh`, plus compact P2 smoke assertions. Native-compatible `nan`/`inf` behavior remains open in `TODO.md`.
- [x] Expanded `smoke_compat.be` source coverage for the `introspect` surface: `members`, `get`, `set`, `contains`, `module`, `name`, `toptr`, `fromptr`, `solidified`, and `ismethod`. A focused host `introspect` check passed; full P2 hardware/profile verification remains open in `TODO.md`.

## Catalina Edge32 build repair

- [x] Added a P2-safe Catalina `introspect` override so Edge32 keeps reflection/module helpers without compiling the upstream raw pointer-resurrection path by default.
- [x] Removed `src/be_introspectlib.c` from the P2 library source list and compile `port/p2/overrides/be_introspectlib_p2.c` instead.
- [x] Fixed Catalina P2 direct-SD patch regeneration so COMPACT Edge32 helper stubs are not compiled with unconditional `-C PSRAM`; XMM/LARGE keeps `-C PSRAM`.
- [x] Hardened the Docker Catalina wrapper so assembler lines like `139748: ERROR:` fail the build instead of being treated as success.
- [x] `make p2-edge32 TOOLCHAIN=catalina CATALINA_USE_DOCKER=1 CATALINA_DIR=.third_party_cache/catalina-v8.8.9-build PORT=/dev/cu.usbserial-P97cvdxp` now builds without Catalina `ERROR:` lines; current image is `506080 / 524288` bytes.
- [x] `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_USE_DOCKER=1 CATALINA_DIR=.third_party_cache/catalina-v8.8.9-build PORT=/dev/cu.usbserial-P97cvdxp` flashes the standalone XMM/huge-heap image; `p2.status()` reports `15728640 B` main heap, `15193848 B` current free, and `Berry heap in PSRAM`.

## Safe p2.asm facade

- [x] Added `p2.asm` as a safe grouped submodule over existing native helpers.
- [x] Added `p2.asm.getrnd()`, `p2.asm.getct()`, `p2.asm.waitx(cycles)`, and `p2.asm.hubset(value)`.
- [x] Added `p2.asm` smoke coverage to `/tests/p2/smoke_p2_api.be`, including negative-argument error checks for `waitx` and `hubset`.
- [x] Added `examples/pasm_direct.be` as a safe PASM-adjacent intrinsic example.
- [x] Documented that arbitrary assembly text, PASM blob loading, function bridging, and unsafe execution remain open.

## Structured p2.debug facade

- [x] Added `p2.debug` as a grouped diagnostics submodule over currently backed runtime state.
- [x] Added `p2.debug.snapshot()`, `heap()`, `gc()`, `cogs()`, `memory_map()`, `pin(pin)`, `pins()`, `smartpin(pin)`, and `registers(cog=nil)`.
- [x] Added smoke coverage for `p2.debug` to `/tests/p2/smoke_p2_api.be`.
- [x] `p2.debug.memory_map()` reports Hub heap totals/free space, PSRAM/XMM tier placement, and SD mount tier labels.
- [x] `p2.debug.pin()`/`pins()` report pin reservation, direction, output, and input snapshots.
- [x] `p2.debug.smartpin()` reports smart-pin `RDPIN`/`RQPIN` snapshots for validated pins.
- [x] Documented that breakpoints, tracing, Berry source stack traces, task/module/lock/channel internals, broader registers, and PASM single-step remain open.

## Lower-case task facade

- [x] Added `modules/task.be` as the lower-case cooperative task facade over `taskspin`.
- [x] Implemented `task.spin(task_id, closure, *args)` with first-free slot behavior for `-1`, fixed task IDs `0..31`, stack metadata via trailing `{"stack": value}`, and task ID / `-1` return semantics.
- [x] Implemented `task.next()`, `task.stop(id)`, `task.halt(id)`, `task.cont(id)`, `task.chk(id)`, `task.id()`, `task.hlt()`, `task.info()`, `task.tasks()`, and `task.task_info(id)`.
- [x] Implemented nil/false/`task.STOP` top-level task return as task stop, `task.HALT` as halt, and `task.info()["all_halted"]` for all-halted behavior.
- [x] Added cooperative source-level `task.Semaphore`, `task.Mutex`, `task.Queue`, `task.EventFlags`, and `task.Timer` primitives.
- [x] Added `tests/p2/host_task.be` and included it in `make test-host`.
- [x] Added P2 smoke coverage for the lower-case `task` facade and cooperative primitives in `/tests/p2/smoke_libraries.be`.
- [x] Documented that independent Berry stacks/coroutines, true Spin2/PASM task switching, and non-callback stackful execution remain open.

## P2 documentation set expansion

- [x] Added `docs/getting-started.md` for first build, flash, and smoke flow.
- [x] Added `docs/building.md` for Catalina profile rules, board/profile selection, image-size policy, and documented P2 debug/trace/unsafe-ASM flags.
- [x] Added `docs/board-support.md` for P2 Edge and P2 Edge 32 MB board variants, silicon selection, and reserved pins.
- [x] Added `docs/sd-layout.md` for current `/modules` behavior and target `/berry/...` layout.
- [x] Added `docs/psram-loader.md` for Hub/PSRAM/XMM cache and loader rules.
- [x] Added `docs/berry-compatibility.md` to document current Berry coverage and host-like bare-metal limitations.
- [x] Added `docs/p2-api.md`, `docs/smartpins.md`, `docs/cogs.md`, `docs/tasks.md`, `docs/pasm.md`, and `docs/debugging.md` for current APIs and honest remaining gaps.
- [x] Added `docs/performance.md` as the required benchmark plan without claiming unmeasured numbers.
- [x] Added `docs/hardware-tests.md` covering required pins, loopback wiring, resistors/electrical notes, board variants, skipped tests, and runnable hardware-test entrypoints.
- [x] Added `docs/limitations.md` to centralize unsupported/open P2 features and no-stub policy.
- [x] Updated root `README.md` with a P2 documentation map.

## Cooperative p2 IPC facade

- [x] Added `modules/p2ipc.be` to attach cooperative current-VM IPC helpers to the native `p2` module.
- [x] Implemented `p2.channel.new(depth)` with `send`, `recv`, `size`, `free`, and `close`.
- [x] Implemented `p2.mailbox.new()` with `put`, `get`, `ready`, and `close`.
- [x] Implemented `p2.shared.Buffer(size)` with bounded byte `read`, `write`, `fill`, `size`, and `aslist`.
- [x] Implemented `p2.mutex.new()` with `lock`, `unlock`, `id`, and `close`, using `p2.lock` hardware locks when available.
- [x] Added `tests/p2/host_p2ipc.be` and included it in `make test-host`.
- [x] Added P2 smoke coverage for `p2ipc` in `/tests/p2/smoke_libraries.be`.
- [x] Documented that cross-cog attention, cross-VM serialization, and stress/soak coverage remain open.

## Consistency repair for recorded smoke evidence

- [x] Repaired `port/p2/overrides/be_p2lib_p2.c` by adding the missing `be_gc.h` include used by the backed `p2.debug.gc()` facade and replacing an accidental embedded NUL char literal with `\0`.
- [x] Restored `/tests/p2/smoke_p2_api.be` coverage for the already-recorded `p2.asm` and `p2.debug` facades.
- [x] Restored `/tests/p2/smoke_libraries.be` coverage for the already-recorded lower-case `task` and cooperative `p2ipc` facades.

## Recovery and migration policy reset

- [x] Restored the default Edge32 Catalina build by quarantining roadmap-shaped native `p2.*` and `p2.debug` facades behind `BE_P2_ENABLE_ROADMAP_NATIVE_FACADES=0`.
- [x] Verified the default Edge32 image builds and flashes on `/dev/cu.usbserial-P97cvdxp` after the quarantine, preserving the working SD/direct-SD/PSRAM-block architecture.
- [x] Reframed migration direction: preserve the working P2 port first, prioritize full 32 MB PSRAM Berry VM memory, then replace Spin2/worker with real closure-based cog/VM support.
- [x] Archived Spin2 and worker native source paths out of the default compiled image without deleting their source files.

## Corrected scope for roadmap facades

- [x] Grouped native `p2.clock`, `p2.cog`, `p2.lock`, `p2.pin`, `p2.cordic`, `p2.math`, `p2.rng`, `p2.smart`, `p2.asm`, and `p2.debug` code is preserved as opt-in experimental source, not enabled in the default recovery image.
- [x] Existing flat/native P2 APIs remain the default supported runtime surface while cleaner architecture migration continues.
