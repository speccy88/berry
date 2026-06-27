# P2 Edge32 SD/XMM DONE
Date created: 2026-06-06

Human reading guide:

- This file is a chronological evidence log, not the current user guide.
- Older entries intentionally keep the ports, Catalina paths, and image sizes
  that were true when those checks ran.
- For current instructions, read `docs/P2_PORT_STATUS.md`,
  `docs/getting-started.md`, `docs/P2_BUILD.md`, and `docs/testing.md`.

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
- [x] Verified native macOS Catalina/lcc at `/Users/fred/Documents/Code/catalina-speccy88`.
- [x] Verified Catalina remains the working toolchain path for this P2 work.
- [x] Documented the current focused P2 hardware test harness in `docs/hardware-tests.md`: `/dev/ttyUSB0` at `230400`, native sibling Catalina `CATALINA_DIR=../Catalina`, P2 Edge 32 MB XMM reserved-pin policy, LED pins `38`/`39`, direct smart-pin jumpers `0-1`, `2-3`, `4-5`, and `6-7`, sync-serial data/clock grouping, no-series-resistor digital loopback assumption, and explicit diagnostic-only/skipped status for ADC/DAC calibration, NCO-duty waveform validation, quadrature motion/direction, sync-serial received words, USB/HID, and VGA.

## Native macOS Catalina toolchain repair

- [x] Fixed the native macOS Catalina Cake-enabled driver source at `/Users/fred/Documents/Code/catalina-speccy88/source/lcc/etc/catalina_darwin_cake.c` so `clcc` invokes Cake with `-target=catalina` instead of letting Cake evaluate target code with the default macOS host ABI model.
- [x] Rebuilt `/Users/fred/Documents/Code/catalina-speccy88/bin/clcc` directly from the corrected Catalina source; this is a Catalina repo fix, not a Berry workaround or patch script.
- [x] Rebuilt the P2 minimal profile with native Catalina after the driver fix; the build completed and Cake reported `emulating catalina`.
- [x] Hardware-verified the P2 minimal RAM image on `/dev/cu.usbserial-P97cvdxp`: `print(6*7)` returned `42`, `print([2,5][0])` returned `2`, and `m={"a":2,"b":5}; print(m["a"]+m["b"])` returned `7`.
- [x] Rebuilt the P2 Edge32 profile with native Catalina after the driver fix; the build completed with image size `487648 / 524288` bytes.
- [x] Hardware-verified the P2 Edge32 RAM image on `/dev/cu.usbserial-P97cvdxp`: `print(6*7)` returned `42`, `print([2,5][0])` returned `2`, map indexing returned `7`, `import p2` and `import os` completed, and read-only `p2.fs_info("/")` reported `mount_result_name == "ok"`, `partition_start == 2048`, and `volinfo_result_name == "ok"`.

## Edge32 flash path

- [x] `make p2-edge32-flash PORT=/dev/cu.usbserial-P97cvdxp TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88` is the verified Edge32 flash command from the handoff.
- [x] Edge32 image boots from SPI flash.
- [x] Current Edge32 image size in the handoff is `499008` bytes.
- [x] Basic REPL arithmetic check passes: `print(6*7)` returns `42`.
- [x] Basic REPL string check passes: `s="abc"; print(s+"def")` returns `abcdef`.
- [x] Basic REPL map check passes: `m={"a":2,"b":5}; print(m["a"]+m["b"])` returns `7`.
- [x] SD-backed `import math; print(math.sqrt(81))` prints `9` on the Edge32 path covered by the handoff.

## Standalone XMM flash path

- [x] `make p2-xmm-flash PORT=/dev/cu.usbserial-P97cvdxp TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88` is the verified standalone XMM flash command from the handoff.
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
- [x] Passed `CATALINA_HEAP_TOP` through the native Catalina build wrapper so native Catalina builds use the same XMM heap ceiling.
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
- [x] Added read-only `p2.vm_copyable_args(...values)` diagnostics to preflight whole child-VM argument lists, including aggregate copyable/rejected counts, first rejected argument index/kind/reason, primitive-copy-only policy, bounded string copy, and explicit no-ownership/no-shared-state/no-resource-transfer flags.
- [x] Wired child-VM primitive-copy preflight into `p2.vm_call(...)`, `p2.vm_call_once(...)`, and `p2.vm_invoke(...)` so unsupported live-object arguments return `args_copyable == false` with first rejected argument diagnostics before selecting a child heap partition, taking the child VM runtime lock, or running child code.
- [x] Added explicit `ok` / `status` fields to synchronous child-call results so callers can distinguish `ok`, `args_rejected`, missing function, child source/call errors, partition failures, stack cleanup issues, and release failures without reconstructing success from raw diagnostic fields.
- [x] Added explicit `ok` / `status` fields to persistent child-VM lifecycle helpers `p2.vm_open(...)`, `p2.vm_eval(...)`, `p2.vm_get(...)`, and `p2.vm_close(...)`, covering successful lifecycle steps plus inactive slots, missing globals, unsupported child result values, partition failures, child deletion failures, and release failures.
- [x] Added non-mutating `p2.vm_info(slot)` diagnostics for persistent child-VM slots, reporting inactive/active/cog-running status, active child handle presence, partition readiness and byte counts, current partition selection, cog status/id/running state, cog stack presence, and runtime-lock availability.
- [x] Extended the `xmm-vm-probe` serial suite to verify the VM-boundary copy/reject table for primitive values and live objects.
- [x] Added remaining child-partition capacity diagnostics to `p2.heap_info()`: `vm_partition_free_capacity` and `vm_partition_free_remainder`, derived from current parent main-heap free space after any child partitions have already been reserved.
- [x] Fixed native `p2.vm_copyable(value)` so Berry list and map instances are classified as rejected `list` and `map` values rather than generic unsupported values.
- [x] Added focused `p2-smoke-p2compat` / `scripts/p2/repl_smoke.py --suite p2compat` hardware entrypoints that upload `modules/p2compat.be` and the 8.3-safe `/tests/p2/p2compvm.be`, with short direct metadata probes in the runner.
- [x] Hardware-verified `/tests/p2/smoke_p2compat.be` on `/dev/ttyUSB0` with the flashed Catalina XMM image (`1043072 / 16777216` bytes): it passed `P2_SMOKE_PASS p2compat` and now covers native `p2.vm_copyable()` nil/bool/int/string copyable diagnostics, list/map/function rejection diagnostics, no-argument rejection, and p2compat bytecode/report snapshot isolation.
- [x] Wired the focused p2compat VM-boundary smoke into the Priority 4 aggregate paths: `make p2-smoke-priority4`, `scripts/p2/repl_smoke.py --suite priority4`, and the already-staged `priority1-4` suite.
- [x] Extended the `xmm-vm-probe` serial suite to sanity-check total partition capacity versus created partitions and remaining free partition capacity reporting.
- [x] Rebuilt the focused Catalina XMM target after child VM partition/copy-boundary changes: `make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88 PORT=/dev/cu.usbserial-P97cvdxp` completed successfully with image `687040` bytes.
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
- [x] Rebuilt the focused Catalina XMM target after adding child VM runtime lock guardrails: `make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88 PORT=/dev/cu.usbserial-P97cvdxp` completed successfully with image `707424` bytes.
- [x] Reflashed the lock-guarded XMM image with `make p2-xmm-flash ... PORT=/dev/cu.usbserial-P97cvdxp`; the generated standalone SPI flash image was `969572` bytes and local `loadp2` used the equivalent `-HIMEM=flash` raw-image fallback because `-FLASHRAW` is unavailable locally.
- [x] Hardware-tested the default synchronous child VM stack after adding runtime lock guardrails on `/dev/cu.usbserial-P97cvdxp`: the board booted XMM profile build `Jun 06 2026 21:02:33` with image `707424` bytes, and `python3 scripts/p2/repl_smoke.py --port /dev/cu.usbserial-P97cvdxp --suite xmm-vm-probe --startup-timeout 60 --timeout 120` passed. The suite covered `p2.vm_probe`, `p2.vm_probe_many`, `p2.vm_call_probe`, `p2.vm_call`, non-captured closure-name bridge, `p2.vm_partition_release`, `p2.vm_call_once`, persistent `p2.vm_open/eval/get/invoke/close`, and two simultaneous persistent child VMs.
- [x] Extended `scripts/p2/repl_smoke.py` so the `xmm-vm-probe` suite now verifies `p2.vm_lock_info()` before and after the child VM lifecycle checks.
- [x] Hardware-verified Catalina child VM runtime lock diagnostics on `/dev/cu.usbserial-P97cvdxp` using the updated `xmm-vm-probe` suite against XMM profile build `Jun 06 2026 21:02:33`: initial `p2.vm_lock_info()` printed `true false 0 0` for available/failed/acquires/contentions, the child VM lifecycle suite passed, and final `p2.vm_lock_info()` printed `true false true true` for available/failed/acquires-positive/contentions-nonnegative.
- [x] Added `CATALINA_EXTRA_CFLAGS` build plumbing through `mk/p2.mk` and `native Catalina build path`, so diagnostic Catalina defines can be passed without changing the default source macros or default P2 firmware behavior.
- [x] Added a focused `xmm-vm-cog` REPL smoke suite for opt-in real-cog child VM diagnostics. The default `xmm-vm-probe` suite remains synchronous and does not exercise `p2.vm_cog_start(...)`.
- [x] Built and flashed an opt-in experimental real-cog XMM diagnostic image with `CATALINA_EXTRA_CFLAGS='-DBE_P2_ENABLE_EXPERIMENTAL_VM_COG=1'`: the focused Catalina XMM build succeeded with image `719488` bytes, the generated standalone SPI flash image was `981636` bytes, and the board booted XMM profile build `Jun 06 2026 21:09:31`.
- [x] Hardware-tested the opt-in `xmm-vm-cog` diagnostic on `/dev/cu.usbserial-P97cvdxp` and confirmed the Catalina hardware-lock guardrail is not sufficient to make real-cog child VM execution safe yet. The suite reached `p2.vm_cog_start(2,"bump",9)` after opening a child VM and defining `bump`, but the next `print(cs[...])` command produced only a prompt with no output instead of `true 2 true 0 1 109 -1`.
- [x] Restored the board to the default gated-off XMM firmware after the failed experimental diagnostic: rebuilt/flashed without `CATALINA_EXTRA_CFLAGS`, producing image `707424` bytes and flash image `969572` bytes, then hardware-verified `xmm-vm-probe` passed on XMM profile build `Jun 06 2026 21:11:14`.
- [x] Added an opt-in C-only cog startup diagnostic, `p2.vm_cog_ping(input, slot=0)`, behind `BE_P2_ENABLE_EXPERIMENTAL_VM_COG`. It starts a Catalina C cog that does not touch Berry VM state, computes `(input * 2) + 1`, reports cog status/result/raw-running/stack-free diagnostics, and is covered by the focused `xmm-cog-ping` smoke suite.
- [x] Hardware-tested the opt-in C-only `xmm-cog-ping` diagnostic on `/dev/cu.usbserial-P97cvdxp`: the experimental XMM build with `CATALINA_EXTRA_CFLAGS='-DBE_P2_ENABLE_EXPERIMENTAL_VM_COG=1'` succeeded with image `721824` bytes, the standalone SPI flash image was `983972` bytes, and the board booted XMM profile build `Jun 06 2026 21:15:05`.
- [x] Confirmed the current real-cog failure is lower than Berry VM sharing: after `ping=p2.vm_cog_ping(41)`, the next `print(ping["started"], ping["status"], ping["result"], ...)` command produced only a prompt with no output instead of `true 2 83 false true -1`. This shows the current `_cogstart_C`/stack/runtime setup under standalone Catalina XMM is itself unsafe or incomplete.
- [x] Restored the board again to the default gated-off XMM firmware after the C-only cog diagnostic: rebuilt/flashed without `CATALINA_EXTRA_CFLAGS`, producing image `707424` bytes and flash image `969572` bytes, then hardware-verified `xmm-vm-probe` passed on XMM profile build `Jun 06 2026 21:16:35`.
- [x] Reconfirmed the board is on the default gated-off XMM firmware after the threaded diagnostic attempt: `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88 PORT=/dev/cu.usbserial-P97cvdxp` rebuilt/flashed with the `-HIMEM=flash` raw-image fallback, the board booted XMM profile build `Jun 06 2026 21:23:13`, and `python3 scripts/p2/repl_smoke.py --port /dev/cu.usbserial-P97cvdxp --suite xmm-vm-probe --startup-timeout 60 --timeout 120` passed.
- [x] Added a native Catalina build-wrapper safety guard: if the Catalina build path exits successfully but prints a fatal line beginning with `ERROR:`, `native Catalina build path` now fails the build so flash targets cannot silently continue after Catalina linker/runtime errors.
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
- [x] Added `p2mem.native_cache_replace(owner, data)` as a conservative owner-scoped blob replacement helper. It originally released the latest owner match before writing the replacement when LIFO-safe; later Priority 1 hardening changed it to write replacements as new latest entries so a failed write or verification cannot discard the previous owner payload.
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

## Priority 1 source-level Berry compatibility smoke additions

- [x] Added source-level `tests/p2/smoke_map_keys.be` coverage for equivalent fresh custom-hash key replacement, including the forced hash-collision bucket case. This is not hardware-verified yet.

## Closure-cog pin 38 / pin 39 blinker proof

- [x] Hardware-verified the pin 38 / pin 39 `p2.cog.spawn(blinker, pin, rate_ms)` proof on `/dev/cu.usbserial-P97cvdxp` with the no-PSRAM P2 Edge RAM image: build `Jun 08 2026 04:56:47`, image `524064 / 524288` bytes, handles `100` and `101`, native pins `38` and `39`, periods `250` and `700` ms, both cogs running with `native_blink == true`, `stack_bytes == 2048`, and final `p2.cog.info()` returning `[]` after `p2.cog.stop(h38)` and `p2.cog.stop(h39)`.
- [x] Compiled the unsafe shared-VM closure dispatcher out of the default P2 firmware behind `BE_P2_ENABLE_UNSAFE_SHARED_VM_COG`, preserving the pin 38 / pin 39 native blinker closure-spawn path and improving the no-PSRAM P2 Edge RAM image from `524224 / 524288` bytes to `522336 / 524288` bytes.
- [x] Updated `/tests/p2/smoke_cog_closure.be` to cover the default closure-cog contract: two pin 38 / pin 39 `native_blink` handles with `model == "native_blink"`, `repl_idle_only == false`, `stack_bytes == 2048`, successful stop cleanup, and loud rejection of unsupported closure shapes.
- [x] Hardware-validated the updated closure-cog smoke contract interactively on `/dev/cu.usbserial-P97cvdxp`: handles `100` and `101`, native diagnostics for pins `38` and `39`, stop results `false false false false` for running/raw-running, final `[]`, and unsupported `p2.cog.spawn(tick)` printing `REJECT runtime_error` with no leaked handles.
- [x] Added `scripts/p2/repl_smoke.py --suite cog-closure` as a focused host harness entry for `/tests/p2/smoke_cog_closure.be`, so the closure-cog proof can be run without the full P2 smoke suite after the SD card has the updated test file.
- [x] Checked the opt-in no-PSRAM full RAM build with `CATALINA_EXTRA_CFLAGS='-DBE_P2_ENABLE_EXPERIMENTAL_VM_COG=1'` while investigating the path toward true VM-on-cog closure execution; the image correctly failed the Hub RAM size guard at `531808 / 524288` bytes, `7520` bytes over the limit, so this diagnostic needs a smaller profile or XMM/flash target before hardware testing on this board.
- [x] Fixed the minimal-profile REPL idle hook so `make p2-minimal ... CATALINA_EXTRA_CFLAGS='-DBE_P2_ENABLE_EXPERIMENTAL_VM_COG=1'` no longer fails with undefined `p2_closure_cog_repl_idle`; minimal excludes the p2 module, so `berry_port.c` now treats the closure-cog idle hook as a no-op for `BE_P2_PROFILE_MINIMAL`.
- [x] Added the narrower opt-in `BE_P2_ENABLE_EXPERIMENTAL_COG_PING` flag so the no-PSRAM full RAM image can register only the C-only `p2.vm_cog_ping()` diagnostic without pulling in the larger child-VM cog-start API.
- [x] Built and RAM-loaded the no-PSRAM full profile with `CATALINA_EXTRA_CFLAGS='-DBE_P2_ENABLE_EXPERIMENTAL_COG_PING=1'`; the image fit at `524064 / 524288` bytes. Hardware execution reached the REPL, but `p2.vm_cog_ping(41)` raised `memory_error: failed to allocate cog ping stack` before starting the C cog. The REPL survived and `print(6*7)` returned `42`; `p2.heap_info()` reported `current: 115608`, `worker: 32752`, and `main: 115608`.
- [x] Added source-level `tests/p2/smoke_operator_overload.be` coverage for chained binary overloaded `+` where the result instance from one overloaded operation becomes the next left operand. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_function_capture.be` coverage for two returned closures sharing and observing the same captured upvalue. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_closure.be` coverage for a closure that captures a mutable list, returns snapshot copies, and keeps its private captured list isolated from caller mutation. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_for_loop.be` coverage for list iteration with loop-local `continue` and `break` behavior. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_errors.be` coverage for a raised error propagating through a helper function call while preserving error type and message. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_exception_assert.be` coverage for an `assert_failed` exception propagating through an escaped closure while preserving its custom message. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_compiler_parser.be` coverage for indexing the selected result of a parenthesized ternary expression. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_classes.be` coverage for an instance method reading instance state and static members together. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_member_indirect.be` coverage for indirect method dispatch using method names selected from a list expression. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_static_decls.be` coverage for a grouped static declaration holding a mutable list shared through class and instance lookup. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_class_const.be` coverage for a static map object mutated through an instance and observed through class lookup. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_module_system.be` coverage for replacing an injected custom module and confirming future imports use the replacement while the old module object keeps its state. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_introspect_ismethod.be` coverage for `introspect.ismethod()` classification after instance and static member lookup results are saved in locals. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_module_attrs.be` coverage for a function-valued virtual module member synthesized through `member()` and invoked normally. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_int_numeric.be` coverage for lowercase hexadecimal integer parsing and zero-shift identity. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_super.be` coverage for calling grandparent methods through a leveled `super(obj, Class)` proxy. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_subobject.be` coverage for ordinary instance fields coexisting with inherited list/map subclass storage. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_virtual_members.be` coverage for computed-name virtual member reads on class instances and modules. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_virtual_setmember.be` coverage for assigning a function-valued virtual member through a computed member name. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_list_core.be` coverage for `reverse()` mutating the list object in place, not only returning reversed contents. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_map_core.be` coverage proving `0`, `false`, and `"0"` remain distinct map keys. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_range.be` coverage proving a descending-range iterator keeps its original sequence after the range object is retargeted. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_bytes_b64_fixed.be` coverage for a three-byte no-padding base64 round trip. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_bytes_extra.be` coverage proving `fromstring()` replacement with a shorter string drops stale tail bytes. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_conversions.be` coverage for numeric passthrough through `number()`, `int()`, and `real()`. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_compile_module.be` coverage for compiled source creating and mutating a local list before returning a result. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_collections.be` coverage proving map keys()/values() snapshots stay unchanged after later map mutation. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_call.be` coverage proving terminal list expansion preserves nested list arguments for fixed and vararg calls. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_vm_ops.be` coverage for `!=` behavior derived from overloaded class equality. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_vm_error_paths.be` coverage for invalid relational comparison overload return type errors. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_be_api_edges.be` coverage for replacing a module member through `introspect.set()` and reading it back normally and through reflection. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_string.be` coverage for expanding `string.replace()` results when each non-overlapping match is replaced by a longer string. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_json.be` coverage for whitespace-tolerant top-level array parsing. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_json_advanced.be` coverage for escaped Unicode decoding inside array values. This is not hardware-verified yet.
- [x] Added source-level `tests/p2/smoke_json_stack.be` coverage for embedding the generated 128-key object under another object key and reading nested fields back. This is not hardware-verified yet.

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
- [x] Added `CATALINA_PLAIN_SD=1` as a diagnostic build switch to compare against Catalina's unmodified SD plugin path without removing the default Berry direct-SD work.
- [x] Updated the Catalina patch generator to `berry-p2-patch-v34`: DOSFS directory helpers now compile with `APPLY_PATCHES=1`, and `dgfreed.c` is rebuilt alongside `dgnext.c` so empty-directory file/directory creation does not use the wrong `currententry - 1` slot.
- [x] Changed ordinary read-only `p2.fs_info("/")` diagnostics and the regular mount fallback path so they do not run raw sector-0 probes; mount fallback now uses normal DOSFS sector reads against known FAT start candidates.
- [x] Rebuilt and flashed the patched non-XMM Edge32 image after `berry-p2-patch-v34`: build `Jun 07 2026 10:28:51`, image `505888` bytes, and the board booted from flash on `/dev/cu.usbserial-P97cvdxp`.
- [x] Hardware-verified regular read-only SD mount on the freshly formatted empty card without raw probes: `p2.fs_info("/")` reported `mounted == true`, `mount_result_name == "ok"`, `partition_start == 2048`, `volinfo_result_name == "ok"`, `root_open_result_name == "ok"`, `root_first_result_name == "ok"`, and `root_entry_count == 0`.
- [x] Hardware-verified regular SD file and directory creation on the freshly formatted empty card in the non-XMM Edge32 profile: `open("/BERRYSD.TXT","w")` wrote `hello sd`, readback returned `hello sd` with size `8`, `os.path.exists` and `os.path.isfile` returned `true`, and `os.mkdir("/BERRYDIR")` made `os.path.isdir("/BERRYDIR")` return `true`.
- [x] Hardware-verified cleanup/read-only root listing after the SD write smoke: the temporary file/directory were absent afterward and `os.listdir("/")` returned `[]` on the empty card.
- [x] Added `file.readlines()` to the Berry file class, implemented on top of the existing `be_fgets()` backend and returning a normal Berry `list` object.
- [x] Hardware-verified the requested non-XMM Edge32 file/open SD API surface on `/dev/cu.usbserial-P97cvdxp` with build `Jun 07 2026 10:36:22`, image `506304` bytes: `open`, `write`, `read`, `readbytes`, `readlines`, `seek`, `tell`, `size`, `flush`, and `close` all worked on a small SD file.
- [x] Hardware-verified the requested non-XMM Edge32 `os` and `os.path` SD API surface on `/dev/cu.usbserial-P97cvdxp`: `os.getcwd`, `os.chdir`, `os.mkdir`, `os.remove`, `os.listdir`, `os.system`, callable `os.exit`, and `os.path.exists/isfile/isdir/join/split/splitext` all returned usable results in the SD smoke sequence.
- [x] Built and flashed the XMM image after the `file.readlines()`/SD fixes using the default patched Catalina path: `make p2-xmm` produced image `735104` bytes and `make p2-xmm-flash` installed standalone flash image `997252` bytes. XMM SD validation is still not counted done because the post-flash attach was silent.
- [x] Repaired native Catalina XMM SD service startup directly in `/Users/fred/Documents/Code/catalina-speccy88/target/p2/cogsd.t`: the SD service now puts the shared P2 Edge boot flash into deep power-down at startup without probing/initializing the SD card until the first real SD request.
- [x] Repaired the Catalina SD service write-success cleanup path in `/Users/fred/Documents/Code/catalina-speccy88/target/p2/cogsd.t` so successful sector writes send final clocks and deselect the SD card before returning.
- [x] Corrected the Catalina `DFS_WriteSector` source precedence bug in `/Users/fred/Documents/Code/catalina-speccy88/source/lib/io/dwrite.c` so the source assigns the raw `sectwrite()` result before comparing it with zero.
- [x] Hardware-verified RAM-loaded XMM read-only SD mount on `/dev/cu.usbserial-P97cvdxp`: `p2.fs_info("/")` reported `mount_result_name == "ok"`, `partition_start == 2048` on first mount, and `sd_response == 0`.
- [x] Hardware-verified standalone XMM flash read-only SD mount on `/dev/cu.usbserial-P97cvdxp` after the Catalina startup flash-sleep fix: three read-only rounds of `p2.fs_info("/")` reported `mount_result_name == "ok"` and `sd_response == 0`, with the first round finding `partition_start == 2048`.
- [x] Diagnosed the earlier standalone XMM flash-only `sd_response == 255` failure as the boot flash remaining awake on the shared P2 Edge SD/flash pins before SD access; `p2.flash_diag()` showed the flash answering JEDEC `0x00EF7018` before sleep.
- [x] Restored the board to the working non-XMM Edge32 firmware after the silent XMM attempt: `make p2-edge32-flash ... PORT=/dev/cu.usbserial-P97cvdxp` booted build `Jun 07 2026 10:36:22` back to `berry>`.
- [x] Berry updates Catalina `__pstart` and `__vi` after its own setup.
- [x] Berry avoids the extra stack pressure from Catalina `_mount()` in the near-full Hub image.

## Diagnostics

- [x] `p2.fs_info()` exposes useful SD diagnostics.
- [x] Low-level SD sector tracing was moved out of noisy `printf()` paths and into queryable diagnostics.
- [x] Current diagnosis is documented: the current SD card has no usable sector-0 partition table but has a valid FAT boot sector at `2048`.

## Priority 1 compatibility test coverage

- [x] Added `/tests/p2/smoke_compat.be` to `/tests/p2/smoke_all.be` so the full SD smoke chain now exercises the Priority 1 Berry compatibility checks instead of leaving them as a standalone file.
- [x] Added `/tests/p2/smoke_vm_ops.be` and wired it into `/tests/p2/smoke_all.be`; it covers arithmetic, bitwise operations, comparisons, string/list slicing, and class operator overloads. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_sys.be` to cover native `sys.path_add()` import-root snapshot isolation: an older `sys.path()` list stays unchanged while a later `sys.path()` call sees the newly appended root and can import from it. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_p2compat.be` to check declarative capability inventory integrity: `p2compat.items()` records match `p2compat.summary()` counts, each record has string name/status/summary fields, and mutating the returned list does not alter module metadata. Hardware execution remains open in `TODO.md`.
- [x] Added `p2compat.items_by_status(status)` for filtered supported/partial/staged/unsupported capability queries and extended `/tests/p2/smoke_p2compat.be` to cover staged filtering, unknown-status empty results, and filtered-list mutation isolation. Hardware execution remains open in `TODO.md`.
- [x] Added `p2compat.statuses()` and `p2compat.status_known(status)` so tooling can discover and validate the supported capability-status vocabulary, with smoke coverage for all four statuses, unknown-status rejection, and returned-list mutation isolation. Hardware execution remains open in `TODO.md`.
- [x] Added `p2compat.names()` and `p2compat.names_by_status(status)` so tooling can enumerate capability names without materializing full records, with smoke coverage for full-name lists, unsupported-name filtering, unknown-status empty results, and returned-list mutation isolation. Hardware execution remains open in `TODO.md`.
- [x] Added `p2compat.report()` as a compact capability snapshot containing statuses, summary counts, capability names, status-grouped names, full records, and bytecode policy metadata, with smoke coverage for report consistency and mutation isolation. Hardware execution remains open in `TODO.md`.
- [x] Hardened `p2compat` record-returning helpers so `items()`, `find()`, `unsupported()`, `items_by_status()`, and `report()` expose copied capability records instead of mutable module-owned maps, with smoke coverage for returned-record mutation isolation. Hardware execution remains open in `TODO.md`.
- [x] Added `p2compat.audit()` as a declarative metadata self-check for duplicate capability names, unknown statuses, and summary/count consistency, with smoke coverage for successful audit results and returned-list mutation isolation. Hardware execution remains open in `TODO.md`.
- [x] Added `p2compat.audit_problems()` and `p2compat.audit_ok()` so smoke tooling can consume concise audit status without parsing the full audit map, with smoke coverage for the current clean table and returned-list mutation isolation. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_global.be` with native `global` module edge coverage for repeated/idempotent `global.undef()` cleanup and the `global()` table view after create/remove of a temporary symbol. Hardware execution remains open in `TODO.md`.
- [x] Added `/tests/p2/smoke_errors.be` and wired it into `/tests/p2/smoke_all.be`; it covers normal `try`, custom `raise`, nested handling, syntax errors, type errors, and bytes index errors. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_errors.be` with nested handler rethrow propagation coverage, preserving the original message while changing the outer error type. Hardware execution remains open in `TODO.md`.
- [x] Added `/tests/p2/smoke_classes.be` and wired it into `/tests/p2/smoke_all.be`; it covers class iteration, invoking classes stored in module members, static fields/methods, and indirect member access with `.(name)`. Hardware execution remains open in `TODO.md`.
- [x] Added `/tests/p2/smoke_syntax.be` and wired it into `/tests/p2/smoke_all.be`; it covers f-strings and walrus assignment across locals, loops, globals, list indexes, and instance members. Hardware execution remains open in `TODO.md`.
- [x] Expanded `/tests/p2/smoke_compat.be` with explicit non-interactive built-in coverage for `assert`, `type`, `size`, `list`, `map`, `range`, `bytes`, `module`, and additional `introspect` behavior.
- [x] Expanded `/tests/p2/smoke_compat.be` with compact upstream-derived language coverage for closures/upvalues, loop-variable closure capture, loop `break`/`continue`, varargs, and richer `call()` argument expansion. Hardware execution remains open in `TODO.md`.
- [x] Expanded `/tests/p2/smoke_compat.be` with additional `list`, `map`, and `range` coverage for insert/remove/pop/find, key iteration, descending ranges, and literal range iteration. Hardware execution remains open in `TODO.md`.
- [x] Expanded `/tests/p2/smoke_compat.be` with additional upstream-derived `bytes` coverage for construction/stringification, add/get, resize, copy/clear isolation, append/concatenation, negative indexing, range slicing, and item mutation. Hardware execution remains open in `TODO.md`.
- [x] Added a focused host-driven `compat` suite to `scripts/p2/repl_smoke.py` so interactive `input()` coverage can be run over the REPL without changing the file-based smoke scripts.
- [x] Hardware execution of the expanded compatibility smoke remains open in `TODO.md`; these entries record implemented test coverage, not a new hardware verification claim.

## Priority 1 SD import layout progress

- [x] Added optional `/berry/main.be` startup support in the P2 runtime: after VM creation, the firmware attempts to load and run `/berry/main.be` once, treats missing file as normal, warns and falls through to the REPL on script failure, and preserves the existing `os.exit()` exit path.
- [x] Added `/BERRY/LIB` and `/BERRY/APP` to the P2 VM startup module path after the existing `/MODULES` root, preserving the known-good `/modules` layout while staging the requested `/berry/...` source layout.
- [x] Updated `modules/libstore.be` so its diagnostic/cache source path list mirrors the runtime source roots: `/modules`, `/berry/lib`, and `/berry/app`.
- [x] Added `/tests/p2/smoke_import_layout.be`, which creates tiny source modules under `/berry/lib` and `/berry/app`, checks `libstore.source_path(...)`, imports both modules through the normal lazy import path, and removes the temporary source files afterward.
- [x] Added `/tests/p2/smoke_import_alias.be` and wired it into `/tests/p2/smoke_all.be`; it checks `import name as alias` for native and SD-loaded modules including `string`, `json`, `math`, `libstore`, and `p2compat`. Hardware execution remains open in `TODO.md`.
- [x] Added `/tests/p2/smoke_import_cwd.be` and wired it into `/tests/p2/smoke_all.be`; it creates a tiny source module in the active SD working directory, imports it by name to preserve current-directory import coverage, restores the previous directory, and removes the temporary source file and working directory. Hardware execution remains open in `TODO.md`.
- [x] Tightened `/tests/p2/smoke_import_cwd.be` so it removes `/berry/app/p2cwd` only when the smoke created that temporary directory, preserving any pre-existing SD directory. Hardware execution remains open in `TODO.md`.
- [x] Added `/tests/p2/smoke_import_native_first.be` and wired it into `/tests/p2/smoke_all.be`; it stages a fake `/berry/app/json.be`, imports `json`, verifies the native module still wins over SD source shadowing, and removes the staged file when the smoke created it. Hardware execution remains open in `TODO.md`.
- [x] Added `/tests/p2/smoke_import_missing.be` and wired it into `/tests/p2/smoke_all.be`; it verifies a missing module import fails catchably and `libstore` reports explicit missing source/compiled/selected metadata. Hardware execution remains open in `TODO.md`.
- [x] Added `/tests/p2/smoke_import_order.be` and wired it into `/tests/p2/smoke_all.be`; it stages the same temporary module under `/modules`, `/berry/lib`, and `/berry/app`, then verifies `/modules` remains the first source root. Hardware execution remains open in `TODO.md`.
- [x] Tightened `/tests/p2/smoke_import_order.be` so it asserts its temporary module paths are absent instead of pre-deleting them, then removes only the files it stages. Hardware execution remains open in `TODO.md`.
- [x] Tightened temporary-file layout smokes so `/tests/p2/smoke_import_layout.be`, `/tests/p2/smoke_import_cwd.be`, `/tests/p2/smoke_package_paths.be`, `/tests/p2/smoke_app_paths.be`, `/tests/p2/smoke_example_paths.be`, and `/tests/p2/smoke_pasm_layout.be` assert their temp paths are absent instead of pre-deleting possible pre-existing files. Hardware execution remains open in `TODO.md`.
- [x] Tightened `/tests/p2/smoke_sd.be` and `/tests/p2/smoke_configstore.be` so compact file/config smokes assert their temporary targets are absent instead of pre-deleting possible pre-existing files or configs. Hardware execution remains open in `TODO.md`.
- [x] Added `libstore.path_add(path)`, `libstore.path_remove(path)`, and `libstore.path_list()` so `libstore` diagnostics/cache/loading can use staged configurable SD source paths without mutating the VM's native startup import path.
- [x] Added `/tests/p2/smoke_libstore_paths.be` and wired it into `/tests/p2/smoke_all.be`; it adds a temporary `/berry/app` source path, loads a tiny module through `libstore.load()`, removes the path, and cleans up the test file. Hardware execution remains open in `TODO.md`.
- [x] Added `libstore.module_file(name, ext)` and updated `libstore.source_path()` / `compiled_path()` so dotted module names such as `pkg.mod` map to nested SD paths such as `pkg/mod.be` for `libstore` diagnostics/cache/loading.
- [x] Added `/tests/p2/smoke_package_paths.be` and wired it into `/tests/p2/smoke_all.be`; it creates `/berry/app/pkg/mod.be`, resolves it as `pkg.mod`, loads it through `libstore.load()`, and cleans up the temporary source file and package directory afterward. Hardware execution remains open in `TODO.md`.
- [x] Tightened `/tests/p2/smoke_package_paths.be` so it removes `/berry/app/pkg` only when the smoke created that temporary directory, preserving any pre-existing SD package directory. Hardware execution remains open in `TODO.md`.
- [x] Added explicit `/berry/app` application helpers in `modules/libstore.be`: `app_path(name)`, `app_exists(name)`, and `run_app(name)`.
- [x] Added `/tests/p2/smoke_app_paths.be` and wired it into `/tests/p2/smoke_all.be`; it creates a tiny `/berry/app` application, runs it through `libstore.run_app()`, checks missing-app behavior, and cleans up afterward. Hardware execution remains open in `TODO.md`.
- [x] Added explicit `/berry/examples` helpers in `modules/libstore.be`: `example_path(name)`, `example_exists(name)`, and `run_example(name)`.
- [x] Added `/tests/p2/smoke_example_paths.be` and wired it into `/tests/p2/smoke_all.be`; it creates a tiny `/berry/examples` script, runs it through `libstore.run_example()`, checks missing-example behavior, and cleans up afterward. Hardware execution remains open in `TODO.md`.
- [x] Added non-executing `/berry/pasm` layout helpers in `modules/libstore.be`: `pasm_path(name)`, `pasm_exists(name)`, and `pasm_info(name)`.
- [x] Added `/tests/p2/smoke_pasm_layout.be` and wired it into `/tests/p2/smoke_all.be`; it creates a dummy `/berry/pasm/*.bin` file, verifies detection metadata marks execution as deferred, and cleans up afterward. Hardware execution remains open in `TODO.md`.
- [x] Added `/tests/p2/smoke_sd_main.be`, which creates a tiny `/berry/main.be`, runs it explicitly, and removes it so the smoke does not permanently alter future boot behavior.
- [x] Added `/tests/p2/smoke_import_cache.be`, a read-only repeated-import/cache smoke that checks module identity is preserved across repeated imports of native and SD-loaded modules and conditionally exercises the PSRAM-backed `libstore.cache_source("math")` path when available.
- [x] Expanded `/tests/p2/smoke_import_cache.be` so repeated-import/module-identity coverage includes the full current SD module set: `binary_heap`, `configstore`, `libstore`, `math`, `p2compat`, `p2ipc`, `p2mem`, `task`, `taskspin`, and `wifi`, plus native `json`.
- [x] Expanded the conditional PSRAM source-cache path in `/tests/p2/smoke_import_cache.be` from `math` only to the full current SD module set, checking cache miss/hit accounting, source hash, source size, and cached-source round trips when the active policy supports PSRAM source caching.
- [x] Added the import-layout, SD-main, and import-cache smokes to `/tests/p2/smoke_all.be`; hardware execution of the expanded full smoke remains open in `TODO.md`.
- [x] Extended `scripts/p2/repl_upload.py` with `--mkdir` so SD layout targets can create real empty directories without uploading fake placeholder files.
- [x] Added opt-in `/berry/...` provisioning targets: `p2-sd-berry-dirs` creates `/berry/lib`, `/berry/app`, `/berry/cache`, `/berry/config`, `/berry/examples`, and `/berry/pasm`; `p2-sd-berry-lib` uploads repo `modules/` to `/berry/lib`; `p2-sd-berry-examples` uploads repo `examples/` to `/berry/examples`; `p2-sd-berry-sync` runs the staged layout provisioning sequence.
- [x] Kept the existing conservative `p2-sd-sync` behavior unchanged; it still uploads only `/modules` and `/tests/p2`.
- [x] Added `modules/configstore.be`, a lazy SD-loaded JSON helper for `/berry/config/*.json` with filename-only paths, `ensure`, `path`, `exists`, `load`, `save`, `remove`, and `list` helpers.
- [x] Added `/tests/p2/smoke_configstore.be` and wired it into `/tests/p2/smoke_all.be`; it saves, loads, lists, and removes a tiny `/berry/config` JSON file through normal Berry SD APIs. Hardware execution remains open in `TODO.md`.
- [x] Expanded `/tests/p2/smoke_configstore.be` with config directory ensure, `.json` suffix normalization, missing remove fallback, and filename-only `value_error` validation. Hardware execution remains open in `TODO.md`.
- [x] Added `/tests/p2/smoke_stdlib.be`, a compact standard-library smoke for `string`, `json`, `time`, `global`, `solidify`, and `strict`, using stable assertions lifted from the repository's host tests while avoiding larger host-only stress cases.
- [x] Expanded `/tests/p2/smoke_stdlib.be` with additional stable upstream-style checks for string search/split/escape/format/replace/translate, JSON scalar/nested/invalid/pretty-dump behavior, and global module compile lookup. Hardware execution remains open in `TODO.md`.
- [x] Expanded `/tests/p2/smoke_stdlib.be` with additional string prefix/suffix negative checks and string multiplication behavior. Hardware execution remains open in `TODO.md`.
- [x] Expanded `/tests/p2/smoke_stdlib.be` with strict-mode compile-error checks for side-effect-free expressions and missing globals. Hardware execution remains open in `TODO.md`.
- [x] Expanded `/tests/p2/smoke_stdlib.be` with deterministic `time.dump()` coverage for fixed epochs, expected fields, weekday range, and invalid real input. Hardware execution remains open in `TODO.md`.
- [x] Wired `/tests/p2/smoke_stdlib.be` into `/tests/p2/smoke_all.be`; hardware execution remains open in `TODO.md`.
- [x] Expanded `/tests/p2/smoke_sd.be` with compact file/open and `os` coverage for `flush`, `tell`, `size`, `seek`, `readlines`, and `rename`, while keeping the write workload small and cleanup-oriented. Hardware execution remains open in `TODO.md`.
- [x] Expanded `/tests/p2/smoke_sd.be` with compact temporary-directory coverage for `os.mkdir`, `os.chdir`, `os.getcwd`, `os.remove`, `os.path.isdir`, `os.path.isfile`, and `os.path.join`, while restoring the original working directory. Hardware execution remains open in `TODO.md`.
- [x] Added explicit staged `.bec` metadata to `modules/libstore.be`: `compiled_paths`, `compiled_supported`, `compiled_path(name)`, `compiled_exists(name)`, and `info()` fields for `compiled_path`, `compiled_exists`, `compiled_supported`, and `source_fallback`.
- [x] Added `libstore.resolve(name)`, which reports source/compiled candidates, selected path, selected kind, decision reason, and source fallback status for the current `.be`/`.bec` resolution policy.
- [x] Added deterministic SD source metadata in `modules/libstore.be`: `hash_text(text)` and `source_stats(name)` report source byte size and a rolling source hash for future `.bec` freshness decisions.
- [x] Added deterministic staged-bytecode metadata in `modules/libstore.be`: `compiled_stats(name)` reports `.bec` byte size and rolling hash, `info()` and `resolve()` expose `compiled_size` / `compiled_hash`, and `p2mem.module(name)` mirrors those fields for diagnostics.
- [x] Added explicit staged-bytecode freshness metadata in `modules/libstore.be`: `compiled_freshness(name)` reports source/compiled size/hash plus `fresh == false`, `usable == false`, and a reason such as `bytecode_freshness_manifest_unavailable`; `info()`, `resolve()`, and `p2mem.module(name)` mirror the relevant fields.
- [x] Added explicit compile-cache planning metadata in `modules/libstore.be`: `compile_cache_plan(name)` reports the future `.bec` target path, source/compiled size/hash metadata, selected fallback path, and `can_emit == false` with reason `bytecode_emit_unavailable` until real bytecode emission exists.
- [x] Added lightweight PSRAM source-cache accounting in `modules/libstore.be`: per-module cache hit counts, miss counts, and last-used access counters are updated by `cache_source()` / `cached_source()` and reset by `cache_reset()`.
- [x] Added `libstore.inventory()`, which returns a metadata record for every discovered SD module using the same source, compiled-bytecode, fallback, and cache-accounting fields as `libstore.info(name)`.
- [x] Added `p2mem.module(name)` as a single-module diagnostics lookup over the existing `p2mem.modules()` metadata, returning `nil` for unknown modules.
- [x] Updated `modules/p2mem.be` module records to reflect `libstore` compiled-bytecode metadata instead of always reporting nil-only compiled fields.
- [x] Updated `modules/p2mem.be` module records to expose `selected_path`, `selected_kind`, and `resolve_reason` from `libstore.resolve(name)`.
- [x] Updated `modules/p2mem.be` module records and PSRAM source-cache item records to expose `source_size` / `source_hash` metadata where available.
- [x] Updated `modules/p2mem.be` module records and cache item records to expose `cache_hit_count`, `cache_miss_count`, and `last_used` from `libstore` where available.
- [x] Added `/tests/p2/smoke_module_inventory.be` and wired it into `/tests/p2/smoke_all.be`; it checks that discovered SD modules expose consistent source, compiled-bytecode, fallback, and cache-accounting metadata. Hardware execution remains open in `TODO.md`.
- [x] Added `/tests/p2/smoke_bec_fallback.be`, which creates a dummy unsupported `.bec` under `/berry/cache` plus a matching `.be` under `/berry/lib`, checks that metadata reports bytecode as unsupported, and confirms the `.be` source fallback still loads. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_bec_fallback.be` and `/tests/p2/smoke_module_inventory.be` to assert staged `.bec` size/hash metadata while keeping `.bec` execution unsupported. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_bec_fallback.be` and `/tests/p2/smoke_module_inventory.be` to assert staged `.bec` freshness/usable metadata while keeping `.bec` execution unsupported. Hardware execution remains open in `TODO.md`.
- [x] Tightened `/tests/p2/smoke_libraries.be` so lazy-loader diagnostics assert honest `.bec` fallback semantics, compiled size, compiled freshness, and compiled usability fields instead of assuming every source load is a `.bec` fallback. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_bec_fallback.be` to assert compile-cache planning metadata without writing or executing `.bec` files. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_bec_fallback.be` with compiled-only and fully-missing negative `.bec` cases, covering `compiled_unsupported_no_source`, `source_missing`, `compiled_without_source`, and `missing` planning/freshness reasons. Hardware execution remains open in `TODO.md`.
- [x] Added `/tests/p2/smoke_import_churn.be`, a bounded allocation/GC/import regression smoke that checks repeated imports of `math`, `json`, and `binary_heap` preserve module identity and behavior after temporary heap churn.
- [x] Expanded `/tests/p2/smoke_import_churn.be` so bounded allocation/GC/import regression coverage includes the full current SD module set: `binary_heap`, `configstore`, `libstore`, `math`, `p2compat`, `p2ipc`, `p2mem`, `task`, `taskspin`, and `wifi`, plus native `json`.
- [x] Wired `/tests/p2/smoke_import_churn.be` into `/tests/p2/smoke_all.be`; hardware execution remains open in `TODO.md`.
- [x] Added `/tests/p2/smoke_import_all_libs.be`, a safe import sweep for the current SD module set: `binary_heap`, `configstore`, `libstore`, `math`, `p2compat`, `p2ipc`, `p2mem`, `task`, `taskspin`, and `wifi`. The smoke checks syntax/importability and safe module metadata only, avoiding WiFi hardware detection or peripheral transactions.
- [x] Updated `modules/libstore.be` so `libstore.known` matches the current SD module set: `binary_heap`, `configstore`, `libstore`, `math`, `p2compat`, `p2ipc`, `p2mem`, `task`, `taskspin`, and `wifi`.
- [x] Tightened `/tests/p2/smoke_module_inventory.be` so metadata inventory coverage must see the full current SD module set, not only `math` and `p2compat`.
- [x] Updated `examples/import_all_libs.be` to include the newer SD modules `configstore`, `p2compat`, `p2ipc`, and `task`.
- [x] Added `modules/p2compat.be`, a declarative SD-loaded capability table that records supported, partial, staged, and unsupported bare-metal P2 features instead of exposing misleading host-like stubs.
- [x] Added `/tests/p2/smoke_p2compat.be` and wired it into `/tests/p2/smoke_all.be`; it verifies that host-like environment variables, subprocesses, generic sockets, and native host threads are explicitly marked unsupported. Hardware execution remains open in `TODO.md`.
- [x] Added SD-loaded `math.nan` and `math.inf` constants using Berry's string-to-real conversion (`real("nan")` / `real("inf")`) rather than division-by-zero expressions.
- [x] Updated `math.isinf()` to recognize positive and negative `math.inf` when the platform numeric parser provides a real infinity.
- [x] Extended `/tests/p2/smoke_modules.be` with `math.nan`, `math.inf`, `isnan`, `isinf`, and invalid finite-operation checks for `sqrt`, `log`, `log10`, `pow`, `asin`, and `acos`. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_modules.be` with `math.floor`, `math.ceil`, `math.round`, `math.deg`, and `math.rad` coverage. Hardware execution remains open in `TODO.md`.

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
- `examples/import_all_libs.be`: import sweep for top-level libraries including `binary_heap`, `configstore`, `math`, `p2compat`, `p2ipc`, `p2mem`, `task`, and optional `wifi`.
- `examples/json_sd.be`: JSON encode/write/read/decode flow on SD storage with a root-file fallback.
- `examples/file_sd.be`: basic SD file create/read/delete smoke example.
- `examples/cog_channel.be`: current-VM `p2ipc` channel send/receive/result diagnostic example.
- `examples/task_scheduler.be`: cooperative `task` scheduler example with two tasks.
- `examples/cordic_demo.be`: grouped `p2.cordic` and `p2.math` numeric helper demo.
- `examples/psram_cache_stats.be`: native `p2.psram_info()` and `p2.psram_cache_info()` diagnostics.
- `examples/debug_report.be`: compact native `p2.debug`, filesystem, and PSRAM runtime snapshot.

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
- [x] Hardened the native Catalina wrapper so assembler lines like `139748: ERROR:` fail the build instead of being treated as success.
- [x] `make p2-edge32 TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88 PORT=/dev/cu.usbserial-P97cvdxp` now builds without Catalina `ERROR:` lines; current image is `506080 / 524288` bytes.
- [x] `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88 PORT=/dev/cu.usbserial-P97cvdxp` flashes the standalone XMM/huge-heap image; `p2.status()` reports `15728640 B` main heap, `15193848 B` current free, and `Berry heap in PSRAM`.

## Safe p2.asm facade

- [x] Added `p2.asm` as a safe grouped submodule over existing native helpers.
- [x] Added `p2.asm.getrnd()`, `p2.asm.getct()`, `p2.asm.waitx(cycles)`, and `p2.asm.hubset(value)`.
- [x] Added `p2.asm` smoke coverage to `/tests/p2/smoke_p2_api.be`, including negative-argument error checks for `waitx` and `hubset`.
- [x] Added `examples/pasm_direct.be` as a safe PASM-adjacent intrinsic example.
- [x] Documented the initial safe-intrinsic-only state; later entries below record the subsequent PASM blob loading progress while arbitrary assembly text, function bridging, and unsafe execution remain open.

## Structured p2.debug facade

- [x] Added `p2.debug` as a grouped diagnostics submodule over currently backed runtime state.
- [x] Added `p2.debug.snapshot()`, `heap()`, `gc()`, `cogs()`, `memory_map()`, `pin(pin)`, `pins()`, `smartpin(pin)`, and `registers(cog=nil)`.
- [x] Added smoke coverage for `p2.debug` to `/tests/p2/smoke_p2_api.be`.
- [x] `p2.debug.memory_map()` reports Hub heap totals/free space, PSRAM/XMM tier placement, and SD mount tier labels.
- [x] `p2.debug.pin()`/`pins()` report pin reservation, direction, output, and input snapshots.
- [x] `p2.debug.smartpin()` reports smart-pin `RDPIN`/`RQPIN` snapshots for validated pins.
- [x] Documented that breakpoints, tracing, Berry source stack traces, task/module/lock/channel internals, broader registers, and PASM single-step remain open.

## Lower-case task facade

- [x] Added `modules/task.be` as the lower-case cooperative task facade for the current source-level scheduler.
- [x] Implemented `task.start(fn, *args)` / `task.start_result(fn, *args)` with first-free slot behavior across 16 cooperative task slots.
- [x] Implemented `task.next()`, `task.run()`, `task.stop(id)`, `task.pause(id)`, `task.resume(id)`, `task.status(id)`, `task.current()`, `task.info()`, `task.list()`, and `task.task_info(id)`.
- [x] Later Priority 4 entries below record the added `task.spin`, `task.halt`/`task.hlt`, `task.cont`, `task.chk`, `task.id`, and `task.tasks` compatibility names over this current scheduler.
- [x] Implemented nil/false/`task.done` top-level task return as task stop and `task.paused` as pause.
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
## 2026-06-07 SD/XMM card bring-up progress

- [x] Expanded the direct-SD fallback candidate list to include common FAT starts `0`, `1`, `32`, `63`, `128`, `256`, `512`, `1024`, `2048`, `4096`, `8192`, `16384`, `32768`, and `65536`.
- [x] Rebuilt and flashed the XMM firmware on `/dev/cu.usbserial-P97cvdxp`; the booted image reported `Berry 1.1.0 (build Jun 07 2026 01:43:52)` with `[xmm profile]`.
- [x] Hardware-verified that the current SD card can mount through `p2.fs_info("/")` after the retry-enabled mount path: `raw_sector0_result_name == "ok"`, `dfs_sector0_result_name == "ok"`, `mount_result_name == "ok"`, `partition_start == 8192`, and `sector0_signature == 65535` for invalid sector 0 plus fallback mount.
- [x] Fixed the Catalina patch installer so `CATALINA_MODEL=LARGE` updates the XMM library directory (`lib/p2/xmm/<clib>`) instead of only the CMM library directory.
- [x] Kept the CMM-only `dgnext` assembler workaround out of the XMM library variant after it produced `Immediate value must be between 0 and 511` in XMM assembly.
- [x] Matched the Catalina direct-SD bit-bang timing more closely to the working raw SD probe and added bounded Berry-side sector-read retries for the mount path.

## 2026-06-07 SD repair safety fixes

- Kept the full SD/FAT fallback sector list while prioritizing the observed Edge32 card starts (`0`, `8192`, `2048`, then the remaining requested candidates).
- Made raw sector-0 reads diagnostic-only so an invalid or transient sector-0 read does not by itself veto fallback mounting.
- Made failed DFS sector-0 reads enter the fallback scan instead of immediately failing the mount.
- Fixed `p2.fs_info()` diagnostics so sector probing uses a local `VOLINFO` and does not corrupt the live mounted `__vi` volume state.
- Bounded SD mount/read retry loops so failed SD probes return to the REPL instead of hanging for minutes.
- Updated the Catalina direct SD write patch to wait for the block data-response token instead of sampling only one byte.
- Rebuilt and flashed the XMM image on `/dev/cu.usbserial-P97cvdxp`; build `Jun 07 2026 03:17:42` boots to `berry>` and `p2.fs_info("/")` now returns a result map instead of hanging.

## 2026-06-07 SD mount retry on freshly formatted card

- [x] Hardware-verified the freshly formatted SD card with the full modules folder on `/dev/cu.usbserial-P97cvdxp`: XMM firmware booted, `p2.fs_info("/")` returned `mount_result_name: ok`, `mounted: true`, `partition_start: 2048`, `raw_sector0_result_name: ok`, `dfs_sector0_result_name: ok`, `volinfo_result_name: ok`, and `root_entry_count: 1`.
- [x] Hardware-verified raw SD command probing on the same card: normal P2 Edge SD pins returned valid CMD0/CMD8/ACMD41/CMD17 data and signature `0xaa55`, while the swapped CS/CLK diagnostic correctly returned `0xff` responses, confirming the normal pin mapping is correct.
- [x] Confirmed FAT directory traversal sees the copied module root as `MODULES` on the freshly formatted card.

## 2026-06-07 read-only SD retry after reformat

- [x] Re-tested the freshly reformatted SD card using only regular Berry filesystem/import paths, with no raw SD probes and no write/unlink diagnostics.
- [x] Hardware-verified on `/dev/cu.usbserial-P97cvdxp` that standalone XMM build `Jun 07 2026 09:27:09` boots, `os.listdir("/")` returns `['MODULES']`, and `os.listdir("/MODULES")` sees `MATH.BE` plus the copied module set.
- [x] Hardware-verified SD-loaded `modules/math.be`: `import math; print(math.sqrt(16))` returned `4`, and `print(math.sin(0))` returned `0`.

## 2026-06-07 CORDIC/native math check

- [x] Rebuilt and flashed standalone XMM build `Jun 07 2026 09:45:15` after regenerating Catalina direct-SD stubs with the read-only SD init retry changes.
- [x] Hardware-verified native P2 CORDIC helpers without SD dependency: `p2.rotxy(1000000, 0, 0)` returned `{'x': 1000000, 'y': 0}`, `p2.polxy(1000000, 0)` returned `{'x': 1000000, 'y': 0}`, and `p2.xypol(1000000, 0)` returned `{'r': 1000000, 't': 0}`.

## 2026-06-07 plain Catalina SD baseline

- [x] Added `CATALINA_PLAIN_SD=1` build support so the native Catalina path can skip `patch-catalina-p2.sh` and omit `__BERRY_P2_DIRECT_SD_IO` / `-C BERRY_P2_DIRECT_SD_IO` for controlled SD baselines.
- [x] Built and flashed a plain-Catalina XMM baseline from `.third_party_cache/catalina` / Catalina `8.8.7`; it booted build `Jun 07 2026 09:55:06` but `os.listdir("/")` returned `[]` and `/MODULES/MATH.BE` did not exist from Berry's regular filesystem view.
- [x] Built and flashed a plain-Catalina COMPACT Edge32 baseline from the same cache; it booted build `Jun 07 2026 09:57:07` but `os.listdir("/")` also returned `[]`.

## 2026-06-07 SD repair evidence: MBR-first mount selection

- [x] Tried `CATALINA_PLAIN_SD=1` as a controlled baseline. The Edge32 image built (`507936 / 524288` bytes) but the flashed plain-SD firmware did not reach the Berry banner before the flash wait timeout, so plain Catalina SD is not currently a usable replacement path on this board/profile.
- [x] Restored the patched Edge32 firmware after the failed plain-SD baseline; the board booted again to `berry>`.
- [x] Changed the regular P2 mount path to read sector 0 through normal Catalina `DFS_ReadSector`, parse an MBR FAT partition entry, and mount that partition start before trying the fixed fallback sector list.
- [x] Reordered the fallback candidate list to match the requested sequence: `0, 1, 32, 63, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536`.
- [x] Verified the MBR-first firmware builds and flashes; current boot banner is `Berry 1.1.0 (build Jun 07 2026 10:59:37)` with image size `506976 / 524288` bytes.

## 2026-06-07 SD diagnostic profile and normal filesystem evidence

- [x] Added an opt-in `sddiag` P2 profile for Edge32 SD diagnosis. It keeps normal Berry `file`, `os`, and `p2.fs_info()` support, but omits unrelated I2C/SPI/RTOS modules so FAT geometry diagnostics fit in Hub RAM.
- [x] Verified `P2_PROFILE=sddiag P2_BOARD=p2edge32` builds and flashes with Catalina. Latest diagnostic boot banner: `Berry 1.1.0 (build Jun 07 2026 11:06:00)` with image size `437920 / 524288` bytes.
- [x] Verified the diagnostic mount geometry on the current card: FAT32 MBR partition type `0x0B` at sector `2048`, `secperclus=32`, `fat1=2080`, `dataarea=31916`, `rootdir=2`, computed FAT32 root sector `31916`.
- [x] Verified P2 sees real FAT root entries through normal Catalina directory enumeration, not random data: volume label `P2`, hidden/system macOS entries `SPOTLI~1` and `FSEVEN~1`, and no visible `/MODULES` entry in the sampled root directory.
- [x] Verified normal file operations on the mounted SD volume without corruption: `open`, `write`, `flush`, `tell`, `size`, `seek`, `readbytes`, `readlines`, `read`, `close`, `os.listdir`, `os.path.exists`, `os.path.isfile`, and `os.remove` worked on `/BMETH.TXT` / `/BTEST.TXT`; temporary files were removed and visible root returned to `[]`.
- [x] Verified normal directory/path operations on the mounted SD volume: `os.mkdir('/BDIR')`, `os.path.isdir('/BDIR')`, `os.chdir('/BDIR')`, `os.getcwd()`, `os.chdir('/')`, `os.path.join`, `os.path.split`, `os.path.splitext`, `os.system('noop')`, `os.exit(0)`, and `os.remove('/BDIR')` behaved as expected.

## 2026-06-07 default Edge32 file/os compatibility pass

- [x] Rebuilt and flashed the normal `edge32` profile after adding guarded `sddiag` diagnostics. The default image remains bootable and under the Hub RAM guard: `Berry 1.1.0 (build Jun 07 2026 11:10:04)`, image size `507136 / 524288` bytes.
- [x] Verified default `edge32` still mounts the current FAT32 SD partition through normal filesystem calls: `p2.fs_info('/')` reported `mount_result_name='ok'`, `volinfo_result_name='ok'`, `partition_type=11`, `partition_start=2048`, `filesystem_type=2`, and no raw sector probe.
- [x] Verified every requested file-class/open operation on default `edge32`: `open('/EDGE.TXT','w+')`, `write`, `flush`, `size`, `tell`, `seek`, `readbytes`, `readlines`, `read`, and `close` all behaved correctly.
- [x] Verified requested `os` operations on default `edge32`: `os.getcwd`, `os.chdir`, `os.mkdir`, `os.remove`, `os.listdir`, `os.system`, and `os.exit` all behaved as expected.
- [x] Verified requested `os.path` operations on default `edge32`: `exists`, `isfile`, `isdir`, `join`, `split`, and `splitext` all behaved as expected.
- [x] Cleaned up `/EDGE.TXT` and `/EDGEDIR`; final visible `os.listdir('/')` returned `[]`.

## 2026-06-07 XMM boot restored, SD hang isolated

- [x] Rebuilt the normal `xmm` profile after the MBR-first SD changes. XMM app image size: `736960 / 16777216` bytes.
- [x] Built and flashed the composed standalone XMM SPI image. Flash image metadata reported stage1 at `0`, loader at `65536`, app at `262144`, app size `736960`, total size `999108` bytes.
- [x] Verified standalone XMM now reaches the Berry REPL after attach: `Berry 1.1.0 (build Jun 07 2026 11:12:25)` with `[xmm profile]`, `heap 15728640 B`, and `Berry heap external`.
- [x] Restored the board to the known-good default `edge32` firmware after XMM SD testing hung; current board booted back to `Berry 1.1.0 (build Jun 07 2026 11:10:04)`.

## 2026-06-07 - Edge32 restored after XMM SD retest

- Restored and flashed the default `edge32` Catalina profile after the XMM SD retest.
- Confirmed the restored firmware boots from flash on `/dev/cu.usbserial-P97cvdxp` and reaches `berry>`.
- Current restored image evidence:
 - `Berry 1.1.0 (build Jun 07 2026 11:26:19)`
 - `[edge32 profile]`
 - `[image 507168 B | code 285048 B | const 23000 B | init 7560 B | data 178244 B]`
 - `[heap 131072 B | stack 1024 slots | bytes max 4096 B]`
 - `[external 33554432 B PSRAM block API | Berry heap Hub RAM]`

## 2026-06-07 - XMM status retested before SD stall

- Built and flashed the huge XMM standalone image successfully.
- Confirmed the XMM REPL responded on `/dev/cu.usbserial-P97cvdxp`.
- Captured `p2.status()` from the huge PSRAM build:
 - `Build Jun 07 2026 11:21:05`
 - `Runtime Catalina P2_EDGE PSRAM`
 - `image 737024 / 16777216 B`
 - `main heap 536640 / 15728640 B`
 - `current free 15192000 B`
 - `external 33554432 B PSRAM block API, Berry heap in PSRAM`
 - `code 593116 B`, `const 22992 B`, `init 7688 B`, `data 47176 B`

## 2026-06-07 - XMM directory iteration no longer stalls with FAT zero end marker

- Fixed Berry's Catalina directory wrapper so FAT `name[0] == 0` is always treated as end-of-directory instead of skipping zero-first-byte long-name-looking entries.
- Added a conservative 1024-entry guard inside `p2_dir_load_next()` to prevent pathological directory scans from hanging Berry scripts.
- Hardware evidence on XMM build `Jun 07 2026 11:28:14`: `import os; print('ROOT0', os.listdir('/'))` returned immediately as `ROOT0 []` on the freshly formatted card.
- Preserved the working default Edge32 image after XMM retesting by reflashing and boot-confirming Edge32 build `Jun 07 2026 11:31:07`.

## 2026-06-07 - Code-side XMM DOSFS scratch-buffer repair

- Updated Berry's Catalina P2 runtime so XMM/LARGE file handles, directory handles, and mount/MBR paths use Hub-RAM sector scratch buffers via Catalina `hub_malloc()`.
- Preserved the existing COMPACT Edge32 layout by keeping inline static sector scratch storage for non-LARGE builds.
- Kept the earlier FAT directory-end fix: `name[0] == 0` terminates directory iteration, with a conservative scan cap.
- Not yet hardware-validated because SD card write testing is paused until the card is confirmed readable on the Mac and reinserted.

- [x] Fixed P2 `os.listdir()` root enumeration on freshly formatted FAT32 cards by matching Catalina's `readdir()` behavior: zero-name directory entries are skipped under a scan limit instead of treated as an immediate end marker.
- [x] Verified on `sddiag` that a freshly formatted empty FAT32 MBR card mounts at sector `2048`, reports FAT32, and supports normal Berry file create/read/exists/remove through the regular file API.

- [x] Archived the old RTOS/worker-backed task layer out of default `edge32`/`xmm` builds without deleting the source; it remains opt-in with `P2_COMPILE_ARCHIVED_RTOS=1` for historical/debug builds.

- [x] Rebuilt, RAM-loaded, SD-tested, and flashed the repaired default `edge32` profile. Flash boot reached `berry>` with image `491040 B`, code `276080 B`, const `21640 B`, init `7552 B`, data `172444 B`.
- [x] Verified full `edge32` on hardware with the freshly formatted FAT32 MBR card: `p2.fs_info('/')` reported `mount_result_name='ok'`, `dfs_sector0_result_name='ok'`, partition start `2048`, partition type `11`, filesystem type `2`, and `volinfo_result_name='ok'`.
- [x] Verified full `edge32` normal filesystem cycle on hardware: created `/EDGEOK.TXT`, confirmed `exists`/`isfile`, `os.listdir('/')` returned `['EDGEOK.TXT']`, removed the file, and root returned to `[]`.

- [x] Verified the full non-XMM `edge32` SD/file/os/os.path checklist on hardware from a freshly formatted empty FAT32 MBR card: mount at sector `2048`, `open`, `write`, `flush`, `size`, `tell`, `seek`, `readbytes`, `readlines`, `read`, `close`, `getcwd`, `chdir`, `mkdir`, `remove`, `listdir`, `system`, and `os.path.exists/isfile/isdir/join/split/splitext` all behaved as expected.
- [x] Fixed and verified `os.exit(0)` on P2: it now sets the P2 exit request, prints `bye`, and does not execute following REPL statements.
- [x] Flashed the repaired `edge32` image after the `os.exit` fix. Flash boot reached `berry>` with image `491072 B`, code `276100 B`, const `21640 B`, init `7552 B`, data `172444 B`.

## 2026-06-07 SD/XMM evidence

- [x] Re-verified the freshly formatted empty FAT32 MBR SD card on the non-XMM `edge32` profile after the XMM failures. `p2.fs_info('/')` returned `mount_result_name='ok'`, `dfs_sector0_result_name='ok'`, `partition_start=2048`, `partition_type=11`, `filesystem_type=2`, and `volinfo_result_name='ok'`.
- [x] Captured direct-SD diagnostic contrast: working Edge32 sector read reports `sd_request=120`, `sd_response=0`, `sd_service_code=254`; XMM direct-SD reports `sd_request=101`, `sd_response=255`, `sd_service_code=-1`, meaning the card never answered the init/CMD0 path under XMM.
- [x] Tried plain Catalina SD on XMM as a comparison path. The image booted, but `p2.fs_info('/')` failed before mount with `dfs_sector0_result_name='errmisc'`, so plain Catalina SD is not yet a replacement for the direct path in XMM.
- [x] Tried compiling the direct SD shim as COMPACT while linking it into the XMM/LARGE image. Catalina produced duplicate-label and undefined `I16A_*` / `I32_*` symbol errors, so mixed COMPACT/LARGE Catalina objects are not a viable repair path.

## 2026-06-07 - XMM SD v44 timing experiment result

- [x] Built and flashed the huge XMM standalone image with `berry-p2-patch-v44`. The VM booted successfully on `/dev/cu.usbserial-P97cvdxp` as `Berry 1.1.0 (build Jun 07 2026 13:38:12)` with `[xmm profile]`, image `774016 B`, and external Berry heap `15728640 B`.
- [x] Tested only read-only SD status on the freshly reformatted empty FAT32 MBR card. `import p2` returned, but `info=p2.fs_info('/')` did not return within the bounded wait, so the v44 slower XMM SD timing experiment is not a safe fix.
- [x] Applied the next conservative code repair: restore fast direct-SD timing in the Catalina patch script, add a direct-SD init-failure latch for fail-fast behavior, and make MBR sector-0 read failures propagate as mount I/O errors.

## 2026-06-07 - XMM SD v46 bounded failure verified

- [x] Built and flashed `berry-p2-patch-v46` XMM. Boot evidence: `Berry 1.1.0 (build Jun 07 2026 13:45:49)`, image `774048 B`, heap `15728640 B`, external PSRAM/XMM active.
- [x] Verified the read-only `p2.fs_info('/')` diagnostic now returns instead of hanging on the empty FAT32 MBR card.
- [x] Captured the returned failure: `mount_result_name='errmisc'`, `dfs_sector0_result_name='errmisc'`, `partition_start=-1`, `partition_type=-1`, `filesystem_type=-1`, `volinfo_result_name='not_run'`, `sd_request=101`, `sd_response=255`, `sd_service_code=-1`.

## 2026-06-07 - XMM service/no-cache and direct-register SD evidence

- [x] Added a controlled Catalina service/no-cache comparison mode: `CATALINA_PLAIN_SD=1 CATALINA_DISABLE_SD_CACHE=1`. The build path patches Catalina `dread.c`/`dwrite.c` so PSRAM/XMM builds can bypass `cached_sectread/cached_sectwrite` while using Catalina's SD service instead of Berry direct-SD.
- [x] Added bounded service waits in the generated Catalina sector stubs so service-mode `sd_sectread`/`sd_sectwrite` return timeout/busy style errors instead of hanging forever in `_long_service_2`.
- [x] Hardware-tested XMM service/no-cache read-only. The firmware booted, but `p2.fs_info('/')` reported `mount_result_name='errmisc'`, `dfs_sector0_result_name='sd_busy'`, `partition_start=-1`, and `sd_service_code=1`, so Catalina's SD service path is still not usable in XMM standalone boot.
- [x] Hardware-tested XMM direct-SD with generated direct `_OUTB/_DIRB/_INB` register pin operations instead of Catalina `_pin*()` calls. The firmware booted, but read-only `p2.fs_info('/')` still returned `A errmisc errmisc`, `B -1 -1 -1 not_run`, `C 101 255 -1`.
- [x] Rebuilt and flashed the normal non-XMM `edge32` profile after the direct-register generator change. The board is currently left on this working Edge32 firmware, build `Jun 07 2026 14:03:14`, image `491712 B`.
- [x] Re-verified the freshly formatted empty FAT32 MBR SD card read-only on Edge32 after all XMM tests: `A ok ok`, `B 2048 11 2 ok`, `C 120 0 254`. This confirms the card was not corrupted by the read-only XMM diagnostics in this pass.

## 2026-06-07 - XMM flash handoff ruled out as sole SD cause

- [x] Tested `berry-p2-patch-v51` XMM after removing the extra post-flash-sleep clock burst that toggled the shared SD CS pin. XMM flash boot still returned `A errmisc errmisc`, `B -1 -1 -1 not_run`, `C 101 255 -1` for read-only `p2.fs_info('/')`.
- [x] RAM-loaded the same XMM image with `make p2-xmm-run ... PORT=/dev/cu.usbserial-P97cvdxp`. The image reached `berry>` after a newline and returned the same read-only SD failure: `A errmisc errmisc`, `B -1 -1 -1 not_run`, `C 101 255 -1`.
- [x] Restored the board to the working `edge32` firmware and re-verified the freshly formatted FAT32 MBR card read-only after the v51 generator change: `A ok ok`, `B 2048 11 2 ok`, `C 120 0 254`.

## 2026-06-07 - Fresh FAT32 MBR card read-only Edge32 check

- After a board power cycle, the previous SD card contents were corrupted enough that the card had to be reformatted.
- User reformatted the card as empty FAT32 with an MBR partition table.
- Restored/flashed the known non-XMM `p2-edge32` image to `/dev/cu.usbserial-P97cvdxp` successfully.
- Read-only `p2.fs_info('/')` on the freshly formatted card returned:
 - `mount_result_name = ok`
 - `dfs_sector0_result_name = ok`
 - `partition_start = 2048`
 - `partition_type = 11`
 - `filesystem_type = 2`
 - `volinfo_result_name = ok`
 - `sd_request = 120`
 - `sd_response = 0`
 - `sd_service_code = 254`
- No file create, write, truncate, delete, or rename tests were run after this reformat.
- Current evidence: non-XMM Edge32 read-only SD mount is healthy on a clean FAT32 MBR card at sector 2048, but prior card corruption means SD write/shutdown/XMM paths remain unsafe until isolated.

## 2026-06-07 - Non-XMM Edge32 file/os/os.path write smoke and path-helper repair

- Hardware-tested the freshly formatted empty FAT32 MBR card on the non-XMM `p2-edge32` image at `/dev/cu.usbserial-P97cvdxp` using normal Berry filesystem APIs only.
- Verified one controlled file write/read cycle:
 - `open('/codex_sd_smoke.txt','w')` returned a file object.
 - `write('berry-p2-sd-smoke\n')`, `flush()`, and `close()` returned to the prompt.
 - Reopen/read returned `berry-p2-sd-smoke`.
- Verified file-class methods on the same file:
 - `tell()` returned `0` at open and `5` after `readbytes(5)`.
 - `size()` returned `18`.
 - `readbytes(5)` returned `bytes('6265727279')`.
 - `seek(0)` reset position to `0`.
 - `readline()` returned `berry-p2-sd-smoke`.
 - `readlines()` returned `['berry-p2-sd-smoke\n']`.
- Verified normal `os` operations:
 - `os.getcwd()` returned `/`.
 - `os.mkdir('/codex_dir')` returned `true`.
 - `os.listdir('/')` showed the created file and directory.
 - `os.chdir('/codex_dir')` returned `true`; `os.getcwd()` returned `/codex_dir`.
 - `os.remove('/codex_delete.tmp')` removed a temporary file.
- Found and repaired an `os.path` compatibility gap: `basename` and `dirname` were missing even though `exists`, `isfile`, `isdir`, `join`, `split`, and `splitext` were present.
- Rebuilt and flashed the patched non-XMM `edge32` image successfully:
 - build: `Berry 1.1.0 (build Jun 07 2026 14:24:03)`
 - image: `491936 B / 524288 B`
- Hardware-verified after flashing:
 - `os.path.basename('/codex_sd_smoke.txt')` -> `codex_sd_smoke.txt`
 - `os.path.dirname('/codex_sd_smoke.txt')` -> `/`
 - `os.path.split('/codex_sd_smoke.txt')` -> `['/', 'codex_sd_smoke.txt']`
 - `os.path.splitext('/codex_sd_smoke.txt')` -> `['/codex_sd_smoke', '.txt']`
 - `os.path.exists('/codex_sd_smoke.txt')` -> `true`
 - `os.path.isdir('/codex_dir')` -> `true`
- Cleaned up the test file and test directory with `os.remove`; `os.listdir('/')` returned `[]` afterward.
- Verified `os.system('noop')` returned `0` and `os.exit(0)` printed `bye` then restarted the Berry banner.
- Added `basename`, `dirname`, `split`, and `splitext` assertions to `tests/p2/smoke_sd.be` so future P2 SD smoke runs catch this path-helper surface.

## 2026-06-07 - XMM read-only SD attempts after runtime bus-handoff cleanup

- Cleaned up the P2 runtime SD bus handoff in `port/p2/runtime/berry_port.c`:
 - Changed the runtime flash reset wait before deep power-down from `1 ms` to `100 ms`, matching the generated direct-SD sector stub.
 - Removed the extra post-sleep flash clock burst that toggled shared flash/SD pins and could also toggle SD CS.
 - Removed duplicate runtime SD bus preparation from direct-SD builds so the generated Catalina sector stub owns flash sleep and SD init for direct I/O.
- Rebuilt and flashed non-XMM `p2-edge32`; it still booted successfully.
- Built and flashed standalone XMM twice for read-only SD metadata tests only.
- XMM still boots from flash, but read-only `p2.fs_info('/')` still fails before FAT/MBR detection:
 - first XMM attempt after handoff timing cleanup: `A errmisc errmisc`, `B -1 -1 -1 not_run`, `C 101 255 -1`
 - second XMM attempt after removing duplicate runtime direct-SD prep: `A errmisc errmisc`, `B -1 -1 -1 not_run`, `C 101 255 -1`
- Interpretation: the XMM failure is still at the direct sector stub's card-init/CMD0 stage, with an all-high `0xff` response; it is not caused by the duplicate runtime bus preparation.
- Restored the board to non-XMM `edge32` firmware after the XMM attempts.
- Final read-only Edge32 confirmation after restoration:
 - `A ok ok`
 - `B 2048 11 2 ok`
 - `C 120 0 254`
- No XMM or post-XMM file writes were run.

## 2026-06-07 - Catalina upstream service-repair branch started

- Cloned Ross Higson's Catalina repository to `/Users/fred/Documents/Code/Catalina`.
- Created Catalina branch `codex/p2-xmm-sd-service-repair` for PR-shaped upstream work.
- Added upstream-candidate Catalina fixes:
 - `target/p2/cogsd.t`: on `P2_EDGE`, put the shared boot flash into deep power-down before SD initialization using flash commands `0x66`, `0x99`, and `0xB9` on the P2 Edge shared flash/SD pins.
 - `target/p2/cogsd.t`: added `.SD_EnsureReady` so sector read/write can retry `_SDcard_Init` if `_SD_Ready` fails.
 - `source/lib/catalina/secread.c` and `source/lib/catalina/secwrite.c`: call `SVC_SD_INIT` once before first sector read/write through the normal Catalina SD service.
 - `source/lib/io/dread.c` and `source/lib/io/dwrite.c`: added `__CATALINA_NO_SD_CACHE` as a general compile-time way to bypass the PSRAM/HYPER SD sector cache.
 - `source/lib/io/dwrite.c`: fixed the write-result precedence bug so `result` receives `sectwrite(...)`, not the boolean comparison result.
- For board validation, overlaid those Catalina files into the existing built Catalina cache at `/Users/fred/Documents/Code/catalina-speccy88` and built Berry XMM with `CATALINA_PLAIN_SD=1 CATALINA_EXTRA_CFLAGS='-D__CATALINA_NO_SD_CACHE'` so Berry did not replace Catalina's SD service stubs.
- XMM service-mode image built and booted from flash:
 - `Berry 1.1.0 (build Jun 07 2026 14:42:55)` / image `774400 B`
 - `Berry 1.1.0 (build Jun 07 2026 14:45:36)` / image `774400 B`
- XMM service-mode read-only `p2.fs_info('/')` still failed before FAT/MBR detection:
 - `A errmisc errmisc`
 - `B -1 -1 -1 not_run`
 - `C 0 255 1`
- Interpretation: Catalina's SD service cog is active, but SD read still returns `255`; the repair is not yet sufficient for XMM SD on this P2 Edge board.
- Restored board to non-XMM `edge32` after the tests.
- Final read-only Edge32 confirmation:
 - `A ok ok`
 - `B 2048 11 2 ok`
 - `C 120 0 254`
- No XMM file writes were run.

## 2026-06-07 - SD safety checkpoint after fresh FAT32 MBR reformat

- Restored the board to the known-good `p2-edge32` firmware after an XMM SD-service diagnostic flash.
- Verified the freshly formatted empty FAT32 MBR card still mounts read-only on restored Edge32 firmware:
 - `mount_result_name = ok`
 - `dfs_sector0_result_name = ok`
 - `partition_start = 2048`
 - `partition_type = 11`
 - `filesystem_type = 2`
 - `volinfo_result_name = ok`
 - `sd_request = 120`, `sd_response = 0`, `sd_service_code = 254`
- Confirmed the latest XMM plain-Catalina SD service diagnostic still reaches Berry but fails read-only `p2.fs_info('/')` before FAT volume info:
 - `mount_result_name = errmisc`
 - `dfs_sector0_result_name = errmisc`
 - `partition_start = -1`
 - `volinfo_result_name = not_run`
 - `sd_request = 0`, `sd_response = 255`, `sd_service_code = 1`

## 2026-06-07 - XMM Catalina SD service now reaches patched diagnostic path

- Forced the XMM image to rebuild instead of reflashing a stale binary by removing generated XMM artifacts before `make p2-xmm-flash`.
- Replaced the stale Berry direct-SD overlay in the installed Catalina XMM `cx` sector stubs with Catalina-generated LARGE `sd_sectread`/`sd_sectwrite` service stubs.
- Updated the installed XMM `c/ci/cix/cx` `catalina.idx` entries for `secread.s` and `secwrite.s` so `_long_service_2` is pulled correctly; this fixed the forced rebuild error where `C__long_service_2` was undefined.
- Rebuilt and flashed XMM successfully. Fresh banner:
 - `Berry 1.1.0 (build Jun 07 2026 15:08:40)`
 - `[Catalina] on Propeller 2 Edge (P2_EDGE, PSRAM) [xmm profile]`
 - `image 764128 B`, `heap 15728640 B`, `Berry heap external`
- Ran read-only `p2.fs_info('/')` on XMM. The failure changed from stale/raw `255` to the patched Catalina diagnostic code:
 - `A errmisc unknown`
 - `B -1 -1 -1 not_run`
 - `C 0 498 1`
- Interpreted result: the patched Catalina SD service is now definitely embedded in the XMM image, and the remaining fault is specifically `SVC_SD_INIT` / `_SDcard_Init` returning `SD_ERR_INIT` before any FAT volume read.
- Restored non-XMM `p2-edge32` firmware afterward and verified the same freshly formatted FAT32 MBR card still mounts read-only:
 - `A ok ok`
 - `B 2048 11 2 ok`
 - `C 120 0 254`

## 2026-06-07 - XMM SD init narrowed to CMD0 failure

- Added stage-specific Catalina `_SDcard_Init` diagnostics in `target/p2/cogsd.t` so `SVC_SD_INIT` failures return the failing SD init stage instead of only generic `SD_ERR_INIT`.
- Rebuilt and flashed a fresh XMM image with the stage diagnostics:
 - `Berry 1.1.0 (build Jun 07 2026 15:12:42)`
 - `image 764224 B`, `heap 15728640 B`, `Berry heap external`
- Ran read-only `p2.fs_info('/')` on XMM. Result:
 - `A errmisc unknown`
 - `B -1 -1 -1 not_run`
 - `C 0 528 1`
- Interpreted result: decimal `528` is `0x210` / `SD_ERR_CMD0`, so Catalina XMM SD service reaches `_SDcard_Init` but the card does not return CMD0 idle.
- Restored non-XMM `p2-edge32` afterward. The same FAT32 MBR card still mounts read-only at sector `2048`, FAT type `2`, with empty root and no corruption observed.

## 2026-06-07 - XMM slow-SPI CMD0 test

- Patched Catalina `target/p2/cogsd.t` SD byte send/receive loop to use conservative `delay5us` half-periods instead of the normal fast `CLOCK_EXTRA` timing.
- Rebuilt and flashed XMM image successfully:
 - `Berry 1.1.0 (build Jun 07 2026 15:17:19)`
 - `image 764224 B`, `heap 15728640 B`, `Berry heap external`
- Ran read-only `p2.fs_info('/')` on XMM. Result remained:
 - `A errmisc unknown`
 - `B -1 -1 -1 not_run`
 - `C 0 528 1`
- Interpreted result: slowing Catalina SD SPI timing alone does not fix CMD0; the card still does not return idle to the XMM SD service.
- Restored non-XMM `p2-edge32` afterward and verified the SD card still mounts read-only: `A ok ok`, `B 2048 11 2 ok`, `C 120 0 254`.

## 2026-06-07 - Reverted non-fixing slow-SPI experiment

- Reverted the temporary Catalina SD byte-loop slowdown after hardware evidence showed it did not move the XMM failure past `SD_ERR_CMD0`.
- Kept the useful Catalina changes: XMM service stubs/index repair, P2 Edge flash sleep hook, and stage-specific `_SDcard_Init` diagnostics.

## 2026-06-07 - Reverted non-fixing flash-handoff delay experiment

- Tested a longer post-`FLASH_DEEP_POWER_DOWN` wait and explicit SD idle pin handoff before CMD0 in Catalina `cogsd.t`.
- XMM read-only `p2.fs_info('/')` still returned `C 0 528 1`, so the CMD0 failure did not move.
- Restored non-XMM `p2-edge32` afterward and verified the SD card still mounted read-only: `A ok ok`, `B 2048 11 2 ok`, `C 120 0 254`.
- Reverted the non-fixing extra handoff delay so it is not proposed as a Catalina repair without evidence.

## 2026-06-07 - Reverted non-fixing CMD0 timeout experiment

- Tested increasing Catalina `_SDcard_Init` CMD0 response timeout from `delay10ms` to `delay1s`.
- XMM still returned `C 0 528 1` (`SD_ERR_CMD0`) on read-only `p2.fs_info('/')`.
- Restored non-XMM `p2-edge32` and verified the card still mounted read-only: `A ok ok`, `B 2048 11 2 ok`, `C 120 0 254`.
- Reverted the CMD0 timeout experiment because it did not move the failure.

## 2026-06-07 - XMM CMD0 narrowed to no-response timeout

- Changed Catalina `cogsd.t` diagnostics so CMD0 preserves the lower-level `_getreply` timeout result instead of always overwriting it with generic `SD_ERR_CMD0`.
- Rebuilt and flashed a fresh XMM image:
 - `Berry 1.1.0 (build Jun 07 2026 15:30:10)`
 - `image 764224 B`, `heap 15728640 B`, `Berry heap external`
- Ran read-only `p2.fs_info('/')` on XMM. Result:
 - `A errmisc unknown`
 - `B -1 -1 -1 not_run`
 - `C 0 539 1`
- Interpreted result: decimal `539` is `0x21B` / `SD_ERR_TIMEOUT`, so CMD0 is seeing only timeout/no non-`0xFF` reply. This points to card not selected, MISO stuck high, wrong pin ownership/mapping, or another device/cog holding the shared bus, rather than a malformed SD R1 response.
- Restored non-XMM `p2-edge32` afterward and verified the same card still mounts read-only: `A ok ok`, `B 2048 11 2 ok`, `C 120 0 254`.

## 2026-06-07 - XMM status captured after CMD0 timeout

- Attempted to run read-only `p2.sd_probe(0, false)` and `p2.sd_probe(0, true)` from the XMM image to separate physical SD bus health from Catalina SD-service behavior.
- The XMM image does not currently expose `p2.sd_probe`; both calls returned `type_error: 'nil' value is not callable`, so no direct probe was run.
- Captured `p2.status()` from the XMM image instead. It showed:
 - `Build Jun 07 2026 15:30:10`
 - `[xmm profile]`, Berry heap in PSRAM
 - current cog `0`
 - cogs `1`, `2`, `3`, `4`, and `5` active before SD mount succeeds
- Restored non-XMM `p2-edge32` afterward and verified the card still mounts read-only: `A ok ok`, `B 2048 11 2 ok`, `C 120 0 254`.

## 2026-06-07 - Fresh FAT32 MBR card XMM raw probe result

- After the user power-cycled the board and reformatted the SD card as an empty FAT32 MBR card, rebuilt and flashed the XMM Catalina-service diagnostic image with `CATALINA_PLAIN_SD=1` and `__CATALINA_NO_SD_CACHE`.
- The XMM image booted normally:
 - `Berry 1.1.0 (build Jun 07 2026 15:39:13)`
 - `[Catalina] on Propeller 2 Edge (P2_EDGE, PSRAM) [xmm profile]`
 - `image 767392 B`, `heap 15728640 B`, `Berry heap external`
- Confirmed the callable diagnostic entrypoint is `p2.sd_raw_probe`, not `p2.sd_probe`.
- Ran read-only raw probes on sector `0` using both normal and swapped CS/CLK mapping:
 - normal: `cmd0=255`, `cmd8=255`, `cmd55=255`, `acmd41=255`, `cmd58=255`, `cmd17=255`, `token=255`, `signature=65535`
 - swapped: `cmd0=255`, `cmd8=255`, `cmd55=255`, `acmd41=255`, `cmd58=255`, `cmd17=255`, `token=255`, `signature=65535`
- Ran read-only `p2.fs_info('/')` on the same XMM boot:
 - `A errmisc unknown`
 - `B -1 -1 -1 not_run`
 - `C 0 539 1`
- Captured service registration fields from XMM:
 - `sd_service_entry=20353`
 - `sd_service_cog=4`
 - `sd_service_lock=31`
 - `fil_cog=4`
 - `fil_registered_type=6`
- Interpreted result: both Catalina SD service and Berry raw bit-bang diagnostics see only `0xff` on the shared SD bus in XMM, so the remaining failure is below FAT/MBR and below sector reads.
- Restored non-XMM `p2-edge32` firmware afterward and verified the same freshly formatted card still mounts read-only:
 - `A ok ok`
 - `B 2048 -1 2 ok`
 - `C 120 0 254`

## 2026-06-07 - XMM raw probe after stopping SD service cog

- Reflashed the same XMM Catalina-service diagnostic image and stopped the registered SD service cog before running Berry's direct raw probe:
 - before: `p2.cog_states()` returned `[1, 1, 1, 1, 1, 1, 0, 0]`
 - command: `p2.cog_stop(4)`
 - after: `p2.cog_states()` returned `[1, 1, 1, 1, 0, 1, 0, 0]`
- With cog `4` stopped, read-only `p2.sd_raw_probe(0, false)` still returned all `255`.
- With cog `4` stopped, read-only `p2.sd_raw_probe(0, true)` still returned all `255`.
- Interpreted result: the all-high XMM raw probe is not caused only by Catalina's SD service cog actively holding the bus.
- Tried public `p2.pin_low`, `p2.pin_high`, `p2.pin_float`, and `p2.pin_read` on pins `58..61`; these are correctly rejected with `value_error: pin is reserved by the P2 Edge SD card interface`, so a diagnostic-only bypass would be needed for pin-level state capture.
- Restored non-XMM `p2-edge32` firmware afterward and verified the card still mounts read-only:
 - `A ok ok`
 - `B 2048 -1 2 ok`
 - `C 120 0 254`

## 2026-06-07 - Catalina patch guard made idempotent

- Fixed `tools/p2/bootstrap/patch-catalina-p2.sh` so the Catalina `dread.c` / `dwrite.c` cache guard replacement is idempotent when the local Catalina cache already contains a `__CATALINA_NO_SD_CACHE` guard.
- This repaired the `p2-edge32-flash` restore path after it failed with:
 - `patch pattern not found in /work//Users/fred/Documents/Code/catalina-speccy88/source/lib/io/dread.c`
- Rebuilt and flashed `p2-edge32` successfully afterward:
 - `Berry 1.1.0 (build Jun 07 2026 15:57:11)`
 - `image 492608 B`
- Verified the same freshly formatted card still mounts read-only:
 - `A ok ok`
 - `B 2048 -1 2 ok`
 - `C 120 0 254`

## 2026-06-07 - XMM SD pin diagnostic evidence

- Fixed the first draft `p2.sd_pin_diag()` return path by matching the established native map-return pattern (`be_pop(vm, 1)` before `be_return(vm)`).
- Rebuilt and flashed an XMM diagnostic image:
 - `Berry 1.1.0 (build Jun 07 2026 16:00:56)`
 - `image 769696 B`, `heap 15728640 B`, `Berry heap external`
- Stopped the registered SD service cog before running the pin diagnostic:
 - `states0 [1, 1, 1, 1, 1, 1, 0, 0]`
 - `p2.cog_stop(4)`
 - `states1 [1, 1, 1, 1, 0, 1, 0, 0]`
- `p2.sd_pin_diag()` returned a proper map:
 - `initial_cs=1`, `cs_low=0`, `cs_high=1`
 - `initial_clk=0`, `clk_low=0`, `clk_high=1`
 - `initial_di=1`, `di_low=0`, `di_high=1`
 - `initial_do=1`, `do_after_cs_low=1`, `do_after_clk_high=1`, `do_final=1`
- Interpreted result: XMM Berry can drive/read the shared CS, CLK, and DI pins, but SD DO/MISO remains high throughout the diagnostic.
- Read-only `p2.sd_raw_probe(0, false)` and `p2.sd_raw_probe(0, true)` still returned all `255`.
- Restored non-XMM `p2-edge32` afterward and verified the same card still mounts read-only:
 - `A ok ok`
 - `B 2048 -1 2 ok`
 - `C 120 0 254`

## 2026-06-07 - XMM flash diagnostic was inconclusive

- Added a read-only `p2.flash_diag()` helper to check whether the P2 Edge boot flash responds to JEDEC-ID reads around the existing flash deep-power-down sequence.
- Rebuilt and flashed an XMM diagnostic image:
 - `Berry 1.1.0 (build Jun 07 2026 16:07:27)`
 - `image 770752 B`, `heap 15728640 B`, `Berry heap external`
- Ran `p2.flash_diag()` before stopping the SD service cog. Result:
 - `before_sleep='0x00FFFFFF'`
 - `after_sleep='0x00FFFFFF'`
 - `after_release='0x00FFFFFF'`
 - `sleep_quiet=true`
 - `release_answers=false`
- Interpreted result: the current C-side flash diagnostic does not get a valid JEDEC ID in XMM, even after release. Therefore it cannot yet prove whether the boot flash is awake or asleep; treat it as inconclusive, not as evidence that flash deep-power-down is correct.
- Repeated the read-only XMM SD checks after this diagnostic:
 - `p2.sd_pin_diag()` still showed CS/CLK/DI can be driven and DO/MISO remains high.
 - `p2.sd_raw_probe(0, false)` and `p2.sd_raw_probe(0, true)` still returned all `255`.
- Restored non-XMM `p2-edge32` afterward and verified the same card still mounts read-only:
 - `A ok ok`
 - `B 2048 -1 2 ok`
 - `C 120 0 254`

## 2026-06-07 - XMM flash diagnostic valid after stopping SD service cog

- Reflashed the same XMM diagnostic image and compared `p2.flash_diag()` before and after stopping the registered SD service cog.
- With cog `4` still active:
 - `states0 [1, 1, 1, 1, 1, 1, 0, 0]`
 - `flash0 {'before_sleep': '0x00FFFFFF', 'after_sleep': '0x00FFFFFF', 'sleep_quiet': true, 'release_answers': false, 'after_release': '0x00FFFFFF'}`
- After `p2.cog_stop(4)`:
 - `states1 [1, 1, 1, 1, 0, 1, 0, 0]`
 - `flash1 {'before_sleep': '0x00EF7018', 'after_sleep': '0x00FFFFFF', 'sleep_quiet': true, 'release_answers': true, 'after_release': '0x00EF7018'}`
- Interpreted result: the flash diagnostic is valid once cog `4` is stopped. Cog `4` interferes with flash-ID access on the shared P2 Edge flash/SD pins.
- The flash deep-power-down/release sequence itself works in the XMM app context after cog `4` is stopped: JEDEC ID `0xEF7018`, quiet after sleep, ID returns after release.
- SD remained all-high after cog `4` was stopped and flash sleep was proven:
 - `p2.sd_pin_diag()` still showed DO/MISO high throughout.
 - `p2.sd_raw_probe(0, false)` still returned all `255`.
- Restored non-XMM `p2-edge32` afterward and verified the same card still mounts read-only:
 - `A ok ok`
 - `B 2048 -1 2 ok`
 - `C 120 0 254`
- [x] Removed the old alternate Catalina build path from the Berry P2 build system. `mk/p2.mk` now invokes native Catalina directly, exports `LCCDIR=$(CATALINA_DIR)`, and the flash/XMM helper scripts require native Catalina tools.

## 2026-06-07 - Native Catalina XMM SD service repair progress

- [x] Repaired Berry's native Catalina XMM flash-image builder so it works with the macOS Catalina fork: the builder now passes repo-relative output paths to Catalina because native Catalina silently produced no `.bin` for absolute `-o` paths.
- [x] Rebuilt and flashed standalone XMM from `/Users/fred/Documents/Code/catalina-speccy88` on `/dev/cu.usbserial-P97cvdxp` using the `loadp2` `-HIMEM=flash` raw-image fallback.
- [x] Confirmed standalone XMM boots to `berry>` and core VM execution still works: `print(6*7)` returned `42`, `import p2` returned, and `os.listdir("/")` returned `[]` without hanging.
- [x] Added Catalina-side SD service timeout wrappers in `source/lib/catalina/secread.c` and `source/lib/catalina/secwrite.c`; XMM `p2.fs_info("/")` now returns instead of wedging.
- [x] Restored Catalina `P2_EDGE` flash deep-power-down handling in `target/p2/cogsd.t` before SD initialization, using boot-flash commands `0x66`, `0x99`, and `0xB9` on the shared P2 Edge flash/SD pins.
- [x] Added a Catalina SD service retry path in `target/p2/cogsd.t` so read/write retry `_SDcard_Init` once if `_SD_Ready` fails.
- [x] Moved Catalina LARGE `sd_sectread()` / `sd_sectwrite()` sector bounce buffers from automatic locals to static data and rebuilt the P2 LARGE Catalina libraries.
- [x] Captured the current read-only XMM SD status after those repairs: `mount_result_name='errmisc'`, `dfs_sector0_result_name='eof'`, `partition_start=-1`, `volinfo_result_name='not_run'`, `sd_request=40`, `sd_response=1`, `sd_service_code=0`.

## 2026-06-07 - XMM SD diagnostic narrowed to init/read-stage failure

- [x] Added staged Catalina SD read diagnostics in `target/p2/cogsd.t`: `0x600 + reply` for init failure, `0x700 + reply` for not-ready-after-init, and `0x800 + reply` for CMD17/data-token failure.
- [x] Rebuilt and flashed XMM after the staged diagnostic change. Read-only `p2.fs_info("/")` returned `sd_response=2049` (`0x800 + 1`), proving the service reached CMD17 and the card replied R1 idle to the read command.
- [x] Forced `_SDcard_Init` at the point of sector read in Catalina `target/p2/cogsd.t` and rebuilt/flashed XMM. Read-only `p2.fs_info("/")` then returned `sd_response=1791` (`0x600 + 255`), proving the immediate initialization attempt timed out waiting for a card response.
- [x] Broadened the P2 Edge shared-flash sleep guard from `P2_EDGE` to `P2_EDGE || P2_CUSTOM` in Catalina `target/p2/cogsd.t`; the XMM read-only result remained `sd_response=1791`.
- [x] Reflashed non-XMM `p2-edge32` to re-check the SD card baseline. The board booted, but the same read-only `p2.fs_info("/")` failed with `mount_result_name='errmisc'`, `dfs_sector0_result_name='eof'`, `partition_start=-1`, `volinfo_result_name='not_run'`, `sd_request=40`, `sd_response=1`, and `sector0_signature=-1`.

## 2026-06-07 - RossH handoff documentation updated

- [x] Updated `port/p2/docs/CATALINA_SD_PATCHES_FOR_ROSSH.md` with the native macOS Catalina fork path, current direct Catalina source changes, staged XMM SD diagnostic return-code meanings, latest XMM/non-XMM board evidence, and the safety pause requiring a known-good non-XMM read-only SD baseline before further XMM validation.

## 2026-06-07 XMM SD progress after formatted-card retest

- Repaired Catalina Edge32 shared flash/SD sleep exit in `/Users/fred/Documents/Code/catalina-speccy88/target/p2/cogsd.t` so `_Flash_Sleep` leaves both shared devices deselected (`SD_CS=1`, `SD_CLK=1`) instead of selecting the sleeping flash.
- Verified standalone XMM flash boot reached `berry>` and `p2.status()` reported the XMM PSRAM profile with Berry heap in PSRAM and about `15192120 B` free.
- Verified XMM read-only SD mount once after the shared-pin repair: `p2.fs_info("/")` reported `mount_result_name='ok'`, FAT start sector `2048`, and `sd_response=0`.
- Verified a normal Berry `os.mkdir("/BTEST")` returned `true`; after reboot, `/BTEST` was still visible and `os.path.isdir("/BTEST")` returned `true`, proving at least directory creation persisted to SD.
- Rebuilt Catalina's P2/LARGE DOSFS helper assembly directly from the cloned Catalina repo with the existing `APPLY_PATCHES=1` source logic and installed it into `/Users/fred/Documents/Code/catalina-speccy88/lib/p2/xmm/cx` for Berry's `-lcx` XMM link path.

- [x] Repaired the standalone XMM flash-loader SD bus handoff on P2 Edge32: the loader and first-stage boot code now leave `SD_CS` high whenever SPI flash is idle, instead of holding the SD card selected during the long flash-to-PSRAM copy.
- [x] Rebuilt and flashed `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88 CATALINA_PLAIN_SD=1 PORT=/dev/cu.usbserial-P97cvdxp`; the standalone XMM banner now matches the app metadata: `image 769408 B`, `code 636504 B`.
- [x] Verified standalone XMM SD read/write through normal Berry APIs only: `p2.fs_info("/")` returned `mount_result_name='ok'`, `sd_response=0`, `partition_start=2048`, FAT32; `/XMMCHK.TXT` was created with `open(...,"w+")`, read back as `xmm-ok`, removed with `os.remove`, and `os.listdir("/")` returned `[]` after cleanup.

- [x] Stabilized the P2 Edge32 shared flash/SD bus ordering for standalone XMM boot: stage1, the Berry C XMM flash loader, and Catalina `target/p2/cogsd.t` now avoid asserting SD `/CS` while SD clock is high during flash read/sleep handoff.
- [x] Verified standalone XMM full SD/file/os/os.path checklist after the shared-pin ordering fix on `/dev/cu.usbserial-P97cvdxp`: `p2.fs_info("/")` mounted FAT32 at `partition_start=2048` with `sd_response=0`; `open`, `write`, `flush`, `tell`, `size`, `seek`, `readbytes`, `readlines`, `read`, and `close` passed on `/APICHECK.TXT`; `os.getcwd`, `os.chdir`, `os.mkdir`, `os.remove`, `os.listdir`, `os.system`, and `os.exit` passed; `os.path.exists`, `isfile`, `isdir`, `join`, `split`, and `splitext` passed; cleanup returned root to `[]`.
- [x] Verified non-XMM Edge32 flash path with the same full SD/file/os/os.path checklist after the Catalina shared-pin fix; banner was `[edge32 profile]`, image `488160 B`, FAT32 mounted at sector `2048`, and cleanup returned root to `[]`.
- [x] Verified non-XMM Edge32 RAM-load path under a PTY: `make p2-edge32-ram TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88 PORT=/dev/cu.usbserial-P97cvdxp` reached `[edge32 profile]`, imported `p2` and `os`, `p2.fs_info("/")` mounted with `mount_result_name='ok'`, `sd_response=0`, `partition_start=2048`, and `os.listdir("/")` returned `[]`.
- [x] Restored the board to the repaired standalone XMM flash image after non-XMM validation with `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88 CATALINA_PLAIN_SD=1 PORT=/dev/cu.usbserial-P97cvdxp`.

## Priority 1 source-only smoke preservation hardening

- [x] Tightened `/tests/p2/smoke_configstore.be` so its missing-config negative remove check first asserts the temporary config name is absent before calling `configstore.remove()`. This keeps the Priority 1 configstore smoke aligned with the Priority 0 rule that smoke tests must not pre-delete possible user/card content. Hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated introspect smoke coverage

- [x] Added `/tests/p2/smoke_introspect.be` and wired it into `/tests/p2/smoke_all.be` so the native `introspect` module has dedicated P2 source-level coverage for module/class/instance member lookup and mutation, method classification, pointer conversion and same-VM round-trip behavior, `solidified()`, `members()` edge cases, fallback reads, and missing-module handling. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated global smoke coverage

- [x] Added `/tests/p2/smoke_global.be` and wired it into `/tests/p2/smoke_all.be` so the native `global` module has dedicated P2 source-level coverage for contains/listing/member lookup, compile visibility of created globals, mutation, list-valued globals, non-string edge cases, and cleanup-oriented undef/redefine behavior. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated strict smoke coverage

- [x] Added `/tests/p2/smoke_strict.be` and wired it into `/tests/p2/smoke_all.be` after the existing `smoke_stdlib.be` strict activation point. The smoke covers native `strict` compiler-mode activation, expression-without-side-effect rejection, missing-global rejection, accepted side-effect expressions, known-global compile visibility, and cleanup after `global.undef()`. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_strict.be` with strict compiler-mode coverage for known and missing global lookups inside compiled function bodies, preserving cleanup through `global.undef()`. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_string.be` with native `string` module API-shape coverage for the main exported helpers: `find`, `count`, `split`, `escape`, `tr`, `replace`, `format`, `startswith`, and `endswith`. Hardware execution remains open in `TODO.md`.

## Priority 1 dedicated time smoke coverage

- [x] Added `/tests/p2/smoke_time.be` and wired it into `/tests/p2/smoke_all.be` before the later strict-mode checks. The smoke covers native `time.clock()`, deterministic `time.dump()` map shape and fixed epochs, invalid dump inputs, and `time.time()` / `time.dump(time.time())` consistency without assuming a real RTC date. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_time.be` with native `time.dump()` edge coverage for integer field types and returned-map mutation isolation across repeated deterministic epoch dumps. Hardware execution remains open in `TODO.md`.

## Priority 1 dedicated JSON smoke coverage

- [x] Added `/tests/p2/smoke_json.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers native `json` scalar and exponent parsing, escape and Unicode decoding, malformed input rejection, nested object/list parsing, formatted dumps, map subclass dumps, and round trips. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_json.be` with native `json` module API-shape coverage for callable `load` and `dump` exports before the parser/dumper behavior assertions. Hardware execution remains open in `TODO.md`.

## Priority 1 dedicated string smoke coverage

- [x] Added `/tests/p2/smoke_string.be` and wired it into `/tests/p2/smoke_all.be` before JSON/time users. The smoke covers native `string` find/count/split, escape/translate/replace, format conversions, range indexing, prefix/suffix helpers, and string multiplication. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated bytes smoke coverage

- [x] Added `/tests/p2/smoke_bytes.be` and wired it into `/tests/p2/smoke_all.be` near the core compatibility smokes. The smoke covers builtin `bytes` construction, add/get endianness, resize/clear, equality/concat/append, appendhex, indexing/ranges, mutation/index errors, copy isolation, string conversion, and hex conversion. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_bytes.be` with builtin `bytes` method API-shape coverage for callable `add`, `get`, `resize`, `clear`, `append`, `appendhex`, `copy`, `asstring`, `fromstring`, and `tohex`. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_range.be` with builtin `range.setrange()` coverage for retargeting an existing range to a descending negative-increment sequence while preserving lower/upper/increment accessors. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_list_core.be` with builtin `list` method API-shape coverage for callable `iter`, `copy`, `insert`, `remove`, `reverse`, `push`, `pop`, `find`, `keys`, and `concat`. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_map_core.be` with builtin `map` method API-shape coverage for callable `find`, `contains`, `remove`, `insert`, `iter`, and `size`. Hardware execution remains open in `TODO.md`.

## Priority 1 dedicated collection smoke coverage

- [x] Added `/tests/p2/smoke_collections.be` and wired it into `/tests/p2/smoke_all.be` near the core compatibility smokes. The smoke covers builtin list indexing/slicing/iteration/mutation/copy/concat/find/clear, map lookup/insert/remove/keys/values and selected key errors, plus range iteration, accessors, `setrange()`, string forms, and selected value errors. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated call smoke coverage

- [x] Added `/tests/p2/smoke_call.be` and wired it into `/tests/p2/smoke_all.be` near the core compatibility smokes. The smoke covers builtin `call()` behavior for fixed-argument functions, varargs functions, varargs-only functions, terminal list expansion, non-terminal list preservation, native function calls, moderate argument-list expansion, and class constructor calls. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_call.be` with builtin `call()` coverage for captured closures, including direct arguments and terminal-list expansion while preserving closure state. Hardware execution remains open in `TODO.md`.

## Priority 1 dedicated conversion/type smoke coverage

- [x] Added `/tests/p2/smoke_conversions.be` and wired it into `/tests/p2/smoke_all.be` near the core compatibility smokes. The smoke covers core conversion/type behavior for `str`, `number`, `int`, `real`, `bool`, `type`, `size`, custom conversion hooks, `classname`, `classof`, `super`, `issubclass`, and `isinstance`. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_conversions.be` with invalid `int()` / `real()` conversion fallback coverage for non-numeric strings and `nil`, matching the existing `number()` negative-path behavior. Hardware execution remains open in `TODO.md`.

## Priority 1 dedicated compile/module/assert smoke coverage

- [x] Added `/tests/p2/smoke_compile_module.be` and wired it into `/tests/p2/smoke_all.be` near the core compatibility smokes. The smoke covers core `assert`, `compile`, and `module` behavior: assert pass/fail exceptions, compile success/failure, compiled global lookup, module member mutation, and introspect-assisted module metadata. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_compile_module.be` with `compile()` coverage for returning a captured closure from compiled source and invoking it after the compiled entry function returns. Hardware execution remains open in `TODO.md`.

## Priority 1 dedicated solidify smoke coverage

- [x] Added `/tests/p2/smoke_solidify.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers native `solidify` API shape, no-argument behavior, invalid-type errors, compacting a tiny class without noisy generated dump output, and optional `nocompact()` behavior when that helper is present. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_solidify.be` with compact inherited-class coverage so a compacted child class still resolves `super()` method behavior plus static member/method access. Hardware execution remains open in `TODO.md`.

## Priority 1 dedicated virtual member smoke coverage

- [x] Added `/tests/p2/smoke_virtual_members.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers the native `undefined` sentinel, class-level virtual `member()` dispatch for dynamic methods and fields, undefined-triggered attribute errors, module-level virtual `member()` dispatch, nil fallback behavior, and `introspect.get(..., true)` returning the `undefined` sentinel for missing members. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated module-system smoke coverage

- [x] Added `/tests/p2/smoke_module_system.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers `module()` creation with and without names, module member mutation and functions, `sys.path()` shape, cached module injection via `introspect.setmodule()`, and a native `string` module monkey-patch/restore path that delegates missing members back to the original module. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated super/inheritance smoke coverage

- [x] Added `/tests/p2/smoke_super.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers multi-level constructor chaining through `super(self).init(...)`, instance and class `super()` traversal, leveled `super(obj, Class)` selection, inherited default `init()` behavior when a parent lacks one, and parent-chain method dispatch where a parent implementation calls back into the concrete child method. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated subobject smoke coverage

- [x] Added `/tests/p2/smoke_subobject.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style builtin subclass behavior for `classof([])`, list class/instance `issubclass()` and `isinstance()` distinctions, and a compact `map` subclass with inherited initialization and index mutation. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated static class smoke coverage

- [x] Added `/tests/p2/smoke_static_classes.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers richer upstream static class behavior: mixed static initializer values, instance access to static members, subclass static overrides, `_class` in static initializer and static method contexts, and nested static classes with static and instance methods. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated conditional-expression smoke coverage

- [x] Added `/tests/p2/smoke_cond_expr.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers Berry conditional expressions for truthy and falsey selection, nesting, use inside `if` conditions, map lookups with fallback branches, loop-generated values, and branch laziness by raising from the unselected branch if it executes. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated compound-assignment smoke coverage

- [x] Added `/tests/p2/smoke_compound.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers scalar arithmetic compound assignments, member compound updates inside methods, direct instance-member compound updates, list index compound updates, computed map-key compound updates, and bitwise/shift compound operators. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated suffix-expression smoke coverage

- [x] Added `/tests/p2/smoke_suffix.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style suffix behavior for dynamic map keys, string concatenation with numeric conversion through `..`, list append expressions, nested list appends, and member slice/index regression cases. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated boolean smoke coverage

- [x] Added `/tests/p2/smoke_bool.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style boolean comparisons, double-negation, `&&`/`||` behavior, short-circuit laziness, unary-not input preservation, `bool()` conversion for scalar and collection values, and the local-value preservation pattern from the upstream boolean regression. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_bool.be` with boolean operator coverage for truthy non-bool operands and falsey collection operands, while preserving short-circuit laziness. Hardware execution remains open in `TODO.md`.

## Priority 1 dedicated relational/equality smoke coverage

- [x] Added `/tests/p2/smoke_relop.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style relational and equality behavior for ints, reals, nil/bool distinctions, builtin class identity, list equality including nested lists, list-vs-nil behavior, and map equality. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_relop.be` with bytes value equality/inequality coverage and bytes-vs-nil distinctions. Hardware execution remains open in `TODO.md`.

## Priority 1 dedicated assignment smoke coverage

- [x] Added `/tests/p2/smoke_assignment.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style continuous suffix assignment for direct instance members, nested instance members, local nested members inside a function, and map-selected object member chains with compound updates. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated reference/cycle smoke coverage

- [x] Added `/tests/p2/smoke_reference.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style cyclic list stringification with `[...]`, nested cyclic rendering, custom `tostring()` participation in list rendering, exception propagation from `tostring()`, and recovery of cyclic rendering after the exception path. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated integer numeric smoke coverage

- [x] Added `/tests/p2/smoke_int_numeric.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style custom `toint()` conversion, hexadecimal string parsing including a large literal, bitwise AND/OR/XOR with variables and literals, and bitwise NOT. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated lexer smoke coverage

- [x] Added `/tests/p2/smoke_lexer.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style lexer behavior for hex and octal string escapes, standard escaped characters, numeric literal forms, Unicode escape encoding through bytes conversion, and malformed literal/token syntax errors. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated map key smoke coverage

- [x] Added `/tests/p2/smoke_map_keys.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style map keys for real numbers, instances with custom `hash()` and `==`, instances without `hash()` using identity behavior, and the `runtime_error` path when an instance `hash()` method returns a non-integer. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated division-by-zero smoke coverage

- [x] Added `/tests/p2/smoke_divzero.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style integer and real division/modulo-by-zero exceptions with `divzero_error` and `division by zero`, plus normal integer and real division/modulo operations. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_divzero.be` with computed-denominator zero coverage so runtime expression evaluation paths raise the same `divzero_error` as literal zero denominators. Hardware execution remains open in `TODO.md`.

## Priority 1 dedicated class constant/static-member smoke coverage

- [x] Added `/tests/p2/smoke_class_const.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style static member defaults, class-member attribute errors, instance access to static members, dynamic function values stored in instance and static members, static method/static function fields, GC survival for static string/real members, and subclass static overrides that reference parent classes. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated bytes base64/fixed-size smoke coverage

- [x] Added `/tests/p2/smoke_bytes_b64_fixed.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style `bytes.tob64()`, `bytes.fromb64()`, fixed-size `bytes(-n)` initialization, fixed-size hex/base64 initialization, fixed-size get/set/index mutation, unchanged-size resize, fixed-size mutation rejection paths, and fixed-size concatenation. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`. Mapped-pointer bytes remain a separate XMM-aware compatibility item.

## Priority 1 dedicated advanced JSON smoke coverage

- [x] Added `/tests/p2/smoke_json_advanced.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style uppercase exponent parsing, slash/backspace/formfeed escapes, Unicode expansion sizing, invalid Unicode escape rejection, unescaped control-character rejection, valid escaped control characters, invalid escape rejection, moderate long strings, mixed ASCII/Unicode text, nested Unicode objects, and malformed string/object rejection. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated for-loop smoke coverage

- [x] Added `/tests/p2/smoke_for_loop.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style range `for` summation, loop `break`, loop `continue`, return from inside a loop, and a compact recursive `for` recurrence that exercises repeated `stop_iteration` handling. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated closure/upvalue smoke coverage

- [x] Added `/tests/p2/smoke_closure.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers independent factory closures, captured upvalue mutation, post-creation outer mutation visibility, loop-variable plus local capture, returned-closure arguments, and the upstream closure-compilation shape with a captured numeric update. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated range smoke coverage

- [x] Added `/tests/p2/smoke_range.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style literal ranges, positive and negative `range()` increments, same-bound descending ranges, large increments, range accessors, string forms, positive and custom-increment `setrange()` reconfiguration, post-`setrange()` iteration, and selected `value_error` paths. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated vararg smoke coverage

- [x] Added `/tests/p2/smoke_vararg.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style direct varargs with required and varargs-only functions, nil-preserving vararg lists, returned closure varargs, and method varargs that preserve `self` plus required and rest arguments. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_vararg.be` with vararg-list mutation isolation coverage: mutating one returned rest-list does not alter closure-captured state or later vararg calls. Hardware execution remains open in `TODO.md`.

## Priority 1 dedicated compiler/parser regression smoke coverage

- [x] Added `/tests/p2/smoke_compiler_parser.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style compiler/parser regression shapes for member-index access through `self`, negative index register ordering, string slicing followed by a `for` loop, ternary assignment parsing, nested map access followed by loop return, and boolean short-circuit parser compilation. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_compiler_parser.be` with call-argument ternary expressions that contain chained list suffixes, covering another compact parser/register-ordering edge without touching runtime hardware paths. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 static declaration method-visible field coverage

- [x] Extended `/tests/p2/smoke_static_decls.be` with an instance method that updates a grouped static field through the class and reads it through instance fallback, covering static field visibility inside method bodies. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 inherited static class member readback coverage

- [x] Extended `/tests/p2/smoke_class_const.be` with inherited static readback through both a subclass and subclass instance, including parent-side mutation after instance creation. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 subclass-from-module inherited static fallback coverage

- [x] Extended `/tests/p2/smoke_static_super_member.be` with a subclass static override observed through an inherited base method, covering instance fallback to the dynamic subclass static field while preserving the base-class value on base instances. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 class iterator closure isolation coverage

- [x] Extended `/tests/p2/smoke_classes.be` with two independent iterator closures returned from the same class instance, confirming their captured iteration state does not alias and `stop_iteration` remains scoped to the exhausted iterator. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 indirect static member write coverage

- [x] Extended `/tests/p2/smoke_member_indirect.be` with computed-name indirect assignment to a class static field and direct/indirect readback. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 builtin subclass method/storage coverage

- [x] Extended `/tests/p2/smoke_subobject.be` with user-defined methods on list and map subclasses that mutate their inherited builtin storage, then verify list indexing and map key lookup read the updated values. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 map hash-collision instance-key coverage

- [x] Extended `/tests/p2/smoke_map_keys.be` with distinct instance keys that intentionally share the same integer hash, verifying equality still separates entries and `contains()` rejects a same-hash missing key. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 virtual member real-member precedence coverage

- [x] Extended `/tests/p2/smoke_virtual_members.be` so class and module `member()` hooks return alternate values for real member names, while direct reads/calls still use the real field or method. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 virtual setmember computed-name write coverage

- [x] Extended `/tests/p2/smoke_virtual_setmember.be` with computed-name assignment through `setmember()` for a virtual payload, plus computed-name assignment to a real field to confirm real-member writes do not get routed into the virtual assignment map. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 external super-proxy method call coverage

- [x] Extended `/tests/p2/smoke_super.be` with direct method calls through `super(c)` and `super(super(c))`, confirming external super proxies dispatch to the expected parent methods while preserving inherited route behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 integer conversion and shift precedence coverage

- [x] Extended `/tests/p2/smoke_int_numeric.be` with negative `toint()` conversion and compact left/right shift assertions, including parenthesized bitwise/shift precedence combinations. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 lexer hex escape boundary coverage

- [x] Extended `/tests/p2/smoke_lexer.be` with uppercase hex escape and NUL byte escape readback, plus incomplete `\x` escape syntax-error cases. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 conditional-expression collection truthiness coverage

- [x] Extended `/tests/p2/smoke_cond_expr.be` with empty/non-empty list and map operands in conditional expressions, covering Berry collection truthiness in ternary selection. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 computed-member compound assignment coverage

- [x] Extended `/tests/p2/smoke_compound.be` with compound assignment through a computed member name, verifying direct and indirect readback agree after the update. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 computed nested assignment coverage

- [x] Extended `/tests/p2/smoke_assignment.be` with nested assignment and compound update through computed member names, verifying direct and indirect readback match. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 suffix method-chain indexing coverage

- [x] Extended `/tests/p2/smoke_suffix.be` with method-call suffix chaining that returns an object/list and immediately indexes the returned list, covering another compact suffix parser/runtime shape. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 cyclic map reference stringification coverage

- [x] Extended `/tests/p2/smoke_reference.be` with cyclic map rendering and post-exception recovery readback, covering map self-reference formatting alongside the existing cyclic list recovery path. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 walrus sequential value-expression coverage

- [x] Extended `/tests/p2/smoke_walrus_edges.be` with sequential assignment expressions inside a list literal, verifying left-to-right value production and readback from the assigned local. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 f-string indexed expression formatting coverage

- [x] Extended `/tests/p2/smoke_syntax.be` with f-string expressions that read list/map suffixes, including integer formatting from an indexed arithmetic expression. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 map nil-value presence coverage

- [x] Extended `/tests/p2/smoke_map_core.be` with a present key whose value is `nil`, confirming `contains()` distinguishes presence while `find(key, default)` still returns the stored `nil` instead of the default. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 collection map values coverage

- [x] Extended `/tests/p2/smoke_collections.be` with order-independent `map.values()` assertions, matching the existing collection coverage goal for map keys and values. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 list index-list ordering coverage

- [x] Extended `/tests/p2/smoke_list_core.be` with duplicate/reordered list-of-indices selection, confirming selection preserves requested order and duplicate indexes. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 compile-to-module mutation coverage

- [x] Extended `/tests/p2/smoke_compile_module.be` with compiled source that mutates a module member through a global module reference, then verifies the module state is visible to normal and introspect reads. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 inherited introspect.ismethod coverage

- [x] Extended `/tests/p2/smoke_introspect_ismethod.be` with inherited method and inherited static-method checks through both subclass and subclass instance lookup. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 binary operator-overload instance result coverage

- [x] Extended `/tests/p2/smoke_operator_overload.be` with a binary `+` overload between two instances that returns a new instance, then verifies the resulting instance payload. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 module member real-attribute precedence coverage

- [x] Extended `/tests/p2/smoke_module_attrs.be` so a module with a virtual `member()` hook also has a real field with the same name, confirming real module attributes take precedence while other names still use dynamic dispatch. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 injected module import identity coverage

- [x] Extended `/tests/p2/smoke_module_system.be` with repeated import of an injected module after mutation through the imported alias, confirming repeated imports keep the same live module object and state. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 custom conversion edge-value coverage

- [x] Extended `/tests/p2/smoke_conversions.be` with custom conversion hooks returning an empty string, a negative integer, and a negative real value, covering edge values through `str()`, `int()`, and `real()`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 range iterator isolation coverage

- [x] Extended `/tests/p2/smoke_range.be` with two independent iterators from the same range object, confirming iterator state does not alias and the range remains reusable for later `for` expansion. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 VM full-span negative slicing coverage

- [x] Extended `/tests/p2/smoke_vm_ops.be` with full-span negative-index string and list slices, covering boundary normalization for `[-len..-1]` style slices. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 VM shift-operator error coverage

- [x] Extended `/tests/p2/smoke_vm_error_paths.be` with invalid shift operand cases for `<<` and `>>`, covering shift-operator `type_error` paths alongside the existing arithmetic error coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 call bound-method dispatch coverage

- [x] Extended `/tests/p2/smoke_call.be` with `call()` on a bound instance method, including direct arguments and list-expanded arguments. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 broad compat map values coverage

- [x] Extended `/tests/p2/smoke_compat.be` with compact `map.values()` readback, ensuring the top-level core compat smoke samples map values as well as keys. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 closure parameter/local capture coverage

- [x] Extended `/tests/p2/smoke_function_capture.be` with a returned closure that captures both an outer function parameter and an inner local, then combines them with a call argument. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 escaped vararg rest-list capture coverage

- [x] Extended `/tests/p2/smoke_vararg.be` with a returned closure that captures the vararg rest list and reads it back later, covering escaped vararg storage separately from immediate return. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 nested closure upvalue-chain coverage

- [x] Extended `/tests/p2/smoke_closure.be` with a nested returned closure that captures and mutates values from two enclosing scopes, covering chained upvalue state across repeated calls. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 nested for-loop control-flow isolation coverage

- [x] Extended `/tests/p2/smoke_for_loop.be` with nested loops that use inner `continue` and `break`, confirming inner-loop control flow does not leak into the outer loop. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 map equality order/nil coverage

- [x] Extended `/tests/p2/smoke_relop.be` with order-independent map equality and nil-valued map equality/distinction checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 safe API map copy isolation coverage

- [x] Extended `/tests/p2/smoke_be_api_edges.be` with map `copy()` mutation-isolation coverage, mirroring the existing list copy isolation probe through safe Berry-level behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated assert-failure exception smoke coverage

- [x] Added `/tests/p2/smoke_exception_assert.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style `assert_failed` exception capture for an assertion failure raised inside a `for` loop, including preservation of the custom assertion message. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_exception_assert.be` with a passing assert guard plus function-call and closure-call assert propagation coverage, confirming a custom `assert_failed` message survives across call and closure frames. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated plain map smoke coverage

- [x] Added `/tests/p2/smoke_map_core.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style plain map access/find/contains behavior, missing-key removal preserving a map, boolean keys, `key_error` lookup, insert true/false semantics, comma-bearing map stringification, `map.iter()` value iteration, and bulk insert/remove behavior that exercises collision-chain cleanup. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated list core smoke coverage

- [x] Added `/tests/p2/smoke_list_core.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style list stringification, iterator order, negative-index insert/remove/reverse behavior, `..` append expression behavior, pop variants, `find()` edge cases including nested lists and nil, `keys()` for populated/nil/empty lists, rich `concat()` delimiter behavior, negative-index compound assignment, list-of-indices selection, and out-of-range list-index selection returning `nil`. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated operator-overload smoke coverage

- [x] Added `/tests/p2/smoke_operator_overload.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style class operator overload behavior for callable instances through `def ()()` and the no-argument `def +()` overload shape used by the upstream regression test. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated string format/edge smoke coverage

- [x] Added `/tests/p2/smoke_string_format_extra.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style string format conversion edges for custom `toint()`, empty conversions for unsupported numeric formatting, `%c`, `%q`, adjacent string literal concatenation with comments, larger short/long string multiplication boundaries, invalid string multiplication type errors, and multiplication inside expressions. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated module attribute smoke coverage

- [x] Added `/tests/p2/smoke_module_attrs.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style module `member()` dynamic attribute dispatch, `member()` returning `undefined` as an `attribute_error`, missing attributes on modules without `member()`, and `introspect.module("string")` returning the native module object. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated indirect-member smoke coverage

- [x] Added `/tests/p2/smoke_member_indirect.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style indirect member syntax for module writes and reads, class static reads, instance initialization through dynamic member names, indirect member writes from expressions, indirect method calls, class-valued method returns, chained indirect member reads, and chained compound updates. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated bytes extra smoke coverage

- [x] Added `/tests/p2/smoke_bytes_extra.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style bytes extra method API shape, float get/set/add behavior, `fromhex()`/`tohex()`, `setbytes()` range and truncation behavior, `reverse()` with offset/length/grouping arguments, bytes truthiness and `tobool()`, three-byte little/big-endian `get()`, `appendb64()` with offsets, three-byte `add()`, and selected `type_error` paths for `set()`, `add()`, and `addfloat()`. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`. Mapped-pointer bytes remain a separate XMM-aware compatibility item.
- [x] Extended `/tests/p2/smoke_bytes_extra.be` with `fromstring()` plus `copy()` mutation-isolation coverage, confirming a copied bytes object does not alias after the original buffer is mutated. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated introspect ismethod edge smoke coverage

- [x] Added `/tests/p2/smoke_introspect_ismethod.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style `introspect.ismethod()` edge behavior for missing arguments, non-closure values, modules, native functions, plain Berry functions, instance methods, static methods, and function-valued instance members. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated virtual setmember smoke coverage

- [x] Added `/tests/p2/smoke_virtual_setmember.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style class `setmember()` behavior for virtual attribute assignment, rejected virtual assignment, map-backed virtual members, and function-valued assignments that must remain callable after passing through `setmember()`. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated VM runtime error-path smoke coverage

- [x] Added `/tests/p2/smoke_vm_error_paths.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style VM runtime error paths for unary, binary, call, concat, and string-repetition type errors, instance operator overload edges for subtraction/multiply/divide/modulo/unary operations, default instance truthiness, invalid comparison return types, instance/class attribute errors, and named-global reads/writes through `global`. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated debug module smoke coverage

- [x] Added `/tests/p2/smoke_debug.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style native `debug` module behavior for `attrdump()` no-crash class inspection and `debug.caller()` stack introspection with function names resolved through `introspect.name()`. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_debug.be` with nested wrapper coverage so `debug.caller()` must preserve a three-frame named call chain resolved through `introspect.name()`. Hardware execution remains open in `TODO.md`.

## Priority 1 dedicated static superclass module-member smoke coverage

- [x] Added `/tests/p2/smoke_static_super_member.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers the upstream-style static-class regression where a subclass inherits from a superclass stored in a module member while defining static members on the subclass, preserving subclass checks, instance checks, inherited methods, and static member reads. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated Berry C API edge smoke coverage

- [x] Added `/tests/p2/smoke_be_api_edges.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style Berry C API edge paths through safe Berry-level probes for closure/function type checks, builtin list/map instance checks, pointer conversion, missing module-member lookup, no-op non-object member setting, list copy isolation, closure upvalue mutation, comparison operators, class inheritance, and native function type checks. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated function closure-capture smoke coverage

- [x] Added `/tests/p2/smoke_function_capture.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style escaped function closure capture where a closure is stored outside its defining function and still sees captured locals, plus independent factory closures with separate mutable captured state. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated walrus edge smoke coverage

- [x] Added `/tests/p2/smoke_walrus_edges.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style walrus regression behavior for local builtin-name shadowing, global and list-index walrus expressions returning the assigned value, member walrus assignment in conditions, and cleanup of temporary global-module state. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated static declaration-form smoke coverage

- [x] Added `/tests/p2/smoke_static_decls.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style legacy `static name` declarations, grouped `static var` declarations, class-vs-instance static visibility, class-side attribute errors for instance fields and missing members, instance reads of static values, and function-valued static members. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated JSON generated stack/growth smoke coverage

- [x] Added `/tests/p2/smoke_json_stack.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers compact upstream-style JSON stack/growth behavior with a generated 128-key object plus a generated list of nested objects, asserting successful parse results without turning the P2 smoke into a large heap stress. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 dedicated math parity smoke coverage

- [x] Added `/tests/p2/smoke_math_parity.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers adapted upstream math semantics for `nan`/`inf` string and JSON behavior, `round` including half-boundaries around zero, `min`/`max` value/type/error behavior, no-argument fallbacks, deterministic `srand`/`rand`, and core constants while preserving the P2 module's documented invalid-domain `nil` behavior. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 explicit REPL input smoke harness coverage

- [x] Tightened `scripts/p2/repl_smoke.py --suite compat` so the interactive `input()` check waits for the prompt marker, sends the response text, then asserts the echoed value before returning to `berry>`. This is harness-level source coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 additive sys.path import-root support

- [x] Added native `sys.path_add(path)` to append deliberate runtime import roots through Berry's VM module-path API without replacing or reordering the P2 startup roots. `libstore.path_add(path)` now bridges to `sys.path_add(path)` when available, `/tests/p2/smoke_sys_path_add.be` stages a tiny module under `/berry/sys_path` and imports it through the normal importer, and `p2compat` now documents additive path support while keeping removal/reordering unsupported. This is source-level support only; hardware execution remains pending in `TODO.md`.
- [x] Hardened the additive import-root path so repeated `libstore.path_add(path)` calls do not duplicate VM module roots. `/tests/p2/smoke_sys_path_add.be` now checks duplicate-safe append behavior before importing its staged probe module. This is source-level support only; hardware execution remains pending in `TODO.md`.

### Priority 1 module coverage metadata

- Added curated per-module coverage metadata to `libstore.info()` / `libstore.inventory()` for the current SD module set: behavior smoke, SD import smoke, repeated import/cache smoke, PSRAM source-cache smoke, low-memory churn smoke, metadata smoke, status, and reason.
- Extended `/tests/p2/smoke_module_inventory.be` so every known SD module must report coverage metadata, while keeping `wifi` honestly marked as hardware-deferred rather than pretending hardware behavior is covered.
- Updated `docs/coverage-matrix.md` and `port/p2/TODO.md` to reflect the new metadata coverage while leaving hardware verification open.

### Priority 1 `.bec` sidecar freshness metadata

- Added staged `.bec` sidecar freshness manifest support through `libstore.compiled_manifest_path()`, `libstore.compiled_manifest()`, and expanded `libstore.compiled_freshness()` metadata.
- Sidecars use `<module>.bec.json` beside the staged bytecode and can prove `fresh == true` / `comparable == true`, while still reporting `compiled_usable == false` until real `.bec` execution support is enabled.
- Extended `p2mem.module()` diagnostics and `/tests/p2/smoke_bec_fallback.be` so fresh, stale, missing-manifest, compiled-only, and source-fallback cases stay explicit.
- Updated SD layout, module, architecture, PSRAM-loader, limitations, TODO, and coverage docs to distinguish staged freshness metadata from still-open `.bec` execution and compile-to-cache emission.

### Priority 1 math CORDIC backend metadata

- Added `math.accel_info()` to the SD-loaded P2 `math` module so the active math backend is explicit at runtime.
- The metadata reports when P2 CORDIC is used for compatible scaled trig/polar paths (`sin`, `cos`, `tan`, `atan2`, and indirect `asin`/`acos`) and keeps `sqrt`, `exp`, and `log` marked unaccelerated to avoid overclaiming unsafe or unmeasured paths.
- Extended `/tests/p2/smoke_modules.be` and `/tests/p2/smoke_math_parity.be` to assert the accelerator metadata while preserving the existing Berry finite/error semantics checks.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md` so CORDIC progress is visible but hardware timing/measurement remains open.

### Priority 1 nested package string imports

- Added native loader filesystem normalization so dotted module names are probed as nested paths for source/bytecode files, e.g. `pkg.mod` maps to `pkg/mod.be` or `pkg/mod.bec` under the current directory and configured module roots.
- Extended `/tests/p2/smoke_package_paths.be` so the staged `/berry/app/pkg/mod.be` module loads both through `libstore.load("pkg.mod")` and through native string import syntax `import "pkg.mod" as native_pkg_mod`.
- Updated `docs/sd-layout.md`, `docs/coverage-matrix.md`, and `port/p2/TODO.md` to mark nested string imports as staged while leaving bare dotted identifier syntax such as `import pkg.mod` open unless the parser grammar is intentionally extended.

### Priority 1 bare dotted package imports

- Extended the Berry parser import grammar to accept bare dotted module names such as `import pkg.mod` and `import pkg.mod as alias`.
- Bare dotted imports use the full dotted string as the module cache/load key and bind the final segment by default, so `import pkg.mod` stores the module in `mod` unless an explicit alias is supplied.
- Combined with the native loader nested-path mapping, dotted imports probe SD paths such as `pkg/mod.be` and `pkg/mod.bec` under the current directory and configured module roots.
- Extended `/tests/p2/smoke_package_paths.be` to cover `libstore.load("pkg.mod")`, `import "pkg.mod" as native_pkg_mod`, `import pkg.mod as dotted_pkg_mod`, and `import pkg.mod` against the same staged `/berry/app/pkg/mod.be` file.
- Updated `docs/sd-layout.md`, `docs/coverage-matrix.md`, and `port/p2/TODO.md`; hardware execution remains pending in TODO.

### Priority 1 invalid `.bec` manifest fallback coverage

- Extended `/tests/p2/smoke_bec_fallback.be` to stage an invalid `<module>.bec.json` sidecar and assert `libstore.compiled_manifest()`, `compiled_freshness()`, `resolve()`, and `compile_cache_plan()` all report the invalid manifest explicitly.
- Confirmed the invalid-manifest case remains non-fresh, non-comparable, non-usable, and still selects the matching `.be` source fallback instead of pretending the `.bec` can execute.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md` so the `.bec` fallback item now names missing, invalid, stale, unsupported, compiled-only, and fully-missing metadata cases.

### Priority 1 `.bec` sidecar manifest validation

- Tightened `libstore.compiled_manifest(name)` so a `.bec.json` sidecar must use format `berry-p2-bec-manifest-v1`, must not name a different module, and must include source and compiled hashes before it can be considered structurally valid.
- Extended `/tests/p2/smoke_bec_fallback.be` to cover invalid JSON, invalid format, module mismatch, missing hashes, stale hashes, and fresh-but-execution-disabled manifests while preserving `.be` source fallback.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md` so `.bec` fallback coverage now distinguishes malformed sidecars from stale-but-comparable sidecars.

### Priority 1 comma-separated dotted package imports

- Extended `/tests/p2/smoke_package_paths.be` to stage a second nested package module and cover comma-separated dotted import syntax: `import pkg.mod, pkg.other`.
- The smoke now proves nested SD package lookup works for `libstore.load("pkg.mod")`, string-path import, bare dotted import with alias, bare dotted import with default final-segment binding, and comma-separated dotted imports.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; hardware execution remains pending in TODO.

### Priority 1 SD file/open mode coverage

- Extended `/tests/p2/smoke_sd.be` with cleanup-oriented coverage for append mode (`a`), read/write update mode (`r+`), additional `os.path.join()` checks, and missing-path negative checks for `exists`, `isfile`, and `isdir`.
- Kept the smoke small and sequential: it stages only `/P2SMOKE.TXT`, `/P2LINES.TXT`, `/P2SMOKE2.TXT`, and `/P2DIR`, and removes the paths it creates.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md` to reflect broader file/open and `os.path` smoke coverage while leaving hardware verification open.

### Priority 1 dotted package import cache identity

- Extended `/tests/p2/smoke_package_paths.be` to verify nested package imports reuse the same cached module object across `import "pkg.mod" as ...`, repeated string import, `import pkg.mod as ...`, default `import pkg.mod`, and comma-separated `import pkg.mod, pkg.other` forms.
- The smoke uses `introspect.toptr()` for identity checks and keeps the same tiny cleanup-oriented staged package files under `/berry/app/pkg`.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; hardware execution remains pending in TODO.

### Priority 1 p2compat capability metadata refresh

- Added `package_import` as a supported `p2compat` capability for dotted SD imports that map to nested paths, including string, alias, bare, and comma-separated forms.
- Added `bec_manifest` as a staged `p2compat` capability for `.bec.json` sidecar format/module/hash validation used by fallback metadata, explicitly separate from disabled `.bec` execution.
- Extended `/tests/p2/smoke_p2compat.be` to assert the new capability entries and updated `port/p2/TODO.md` plus `docs/coverage-matrix.md`.

### Priority 1 missing-import cache recovery

- Extended `/tests/p2/smoke_import_missing.be` so a failed import is followed by staging the same module under `/berry/app` and importing it successfully.
- This proves missing imports fail catchably without creating bogus selected metadata or poisoning the module cache for a later SD source module.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; hardware execution remains pending in TODO.

### Priority 1 `.bec` preference/blocker metadata

- Added `compiled_preferred` and `compiled_blocked_reason` to `libstore.resolve()` and `libstore.info()` so a fresh staged `.bec` candidate can be identified without enabling bytecode execution.
- Extended `/tests/p2/smoke_bec_fallback.be` to assert missing-manifest, fresh-but-execution-disabled, and stale-manifest preference/blocker metadata while keeping `.be` source selected.
- Extended `/tests/p2/smoke_module_inventory.be` to require the new metadata fields on inventory records.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; `.bec` execution remains disabled and hardware execution remains pending in TODO.

### Priority 1 compile-cache plan blocker metadata

- Added `libstore.MANIFEST_FORMAT` and expanded `libstore.compile_cache_plan(name)` with `manifest_format`, `manifest_required`, `validator_required`, `execution_required`, and `emit_blocked_reason` fields.
- Extended `/tests/p2/smoke_bec_fallback.be` so normal, compiled-only, and missing-source cache plans assert the explicit blockers while `can_emit` remains false.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; this is planning metadata only and does not enable `.bec` emission or execution.

### Priority 1 compile-cache plan summary in module diagnostics

- Added compile-cache plan summary fields to `libstore.info()` / `libstore.inventory()`: support flag, can-emit flag, reason, blocked reason, target `.bec` path, target manifest path, and manifest format.
- Added matching fields to `p2mem.module(name)` so diagnostics expose why `.bec` emission is currently blocked without requiring a separate planner call.
- Extended `/tests/p2/smoke_module_inventory.be` and `/tests/p2/smoke_bec_fallback.be` to assert the new metadata while keeping `.bec` emission/execution disabled.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; this is diagnostic/planning metadata only.

### Priority 1 SD `+` file mode coverage

- Extended `/tests/p2/smoke_sd.be` with cleanup-oriented coverage for `w+` and `a+` read/write file modes using a tiny `/P2PLUS.TXT` temporary file.
- The smoke now covers documented `open()` modes `w`, `a`, `r+`, `w+`, and `a+` without expanding into broad host-like filesystem assumptions.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; hardware execution remains pending in TODO.

### Priority 1 `.bec` manifest template planning

- Added `libstore.compiled_manifest_template(name)` to compute the sidecar manifest payload that a future `.be` to `.bec` cache writer would emit when source and staged bytecode both exist.
- Extended `libstore.compile_cache_plan(name)` with manifest-template availability, reason, and data fields while keeping `can_emit == false` and bytecode execution disabled.
- Extended `/tests/p2/smoke_bec_fallback.be` to assert manifest-template metadata for matched, compiled-only, and missing cases.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; this is planning metadata only.

### Priority 1 manifest-template status in module diagnostics

- Added manifest-template availability and reason fields to `libstore.info()` / `libstore.inventory()` and `p2mem.module(name)` so module diagnostics can report whether future `.bec` sidecar payload generation is possible.
- Kept the full template payload in `libstore.compile_cache_plan(name)` to avoid bloating every inventory record.
- Extended `/tests/p2/smoke_module_inventory.be` and `/tests/p2/smoke_bec_fallback.be` to assert the new status fields.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; this remains planning metadata only.

### Priority 1 `.bec` manifest text preview

- Added `libstore.compiled_manifest_text(name)` to preview the JSON sidecar payload a future `.be` to `.bec` cache writer would save when source and staged bytecode both exist.
- Extended `/tests/p2/smoke_bec_fallback.be` to parse the preview text and verify its format, module, source hash, and compiled hash; compiled-only and missing cases return `nil`.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; this is preview/planning metadata only and does not write manifests, emit `.bec`, or enable `.bec` execution.

### Priority 1 `os.path` helper-shape coverage

- Extended `/tests/p2/smoke_sd.be` with additional `os.path` helper-shape assertions for nested paths, local relative filenames, missing extensions, and empty-directory split/dirname cases.
- Covered basename, dirname, join, split, and splitext behavior without adding new SD writes beyond the existing smoke files.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; hardware execution remains pending in TODO.

### Priority 1 SD directory listing coverage

- Extended `/tests/p2/smoke_sd.be` so the temporary `/P2DIR` directory creates a tiny cwd-relative `INNER.TXT`, verifies `os.listdir(".")` sees it, checks relative `exists` / `isfile`, removes the file, and then removes the directory.
- Kept the SD writes small, sequential, and cleanup-oriented within the existing smoke directory footprint.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; hardware execution remains pending in TODO.

### Priority 1 opt-in `.bec` compile-cache emission helper

- Added `BE_P2_ENABLE_BYTECODE_SAVER` as an explicit P2 build gate for Berry's bytecode saver, leaving default P2 firmware with bytecode saving disabled.
- Added `libstore.compile_cache_probe()` and `libstore.compile_cache_emit(name)`: the helper compiles a source module, writes the target `.bec`, writes the matching `.bec.json` sidecar manifest, and reports freshness metadata only when the opt-in saver exists.
- Added `BE_P2_ENABLE_BYTECODE_LOADER` as a separate explicit P2 build gate, and exposed both bytecode saver/loader flags through `p2.status_info()["build"]`.
- Added `BE_P2_ENABLE_BYTECODE_EXECUTION` as a separate default-off execution-policy gate, and exposed it through `p2.status_info()["build"]`.
- Added `libstore.compiled_execution_probe()` plus `compiled_loader_supported`, `compiled_validator_supported`, and `compiled_loader_reason` diagnostics so `.bec` freshness can distinguish default source fallback, opt-in loader-capable builds, and opt-in execution-policy builds.
- Added `libstore.compiled_validation(name)` to report comparable/fresh sidecar state separately from safe bytecode validation/execution support, and mirrored its summary fields through `libstore.info()` and `p2mem.module(name)`.
- Added `libstore.compiled_load_plan(name)` and loud-failing `libstore.load_compiled(name)` so future `.bec` execution has an explicit hook that reports precise blocked reasons instead of silently falling back.
- Added `libstore.compiled_status(name)` as a consolidated `.bec` diagnostics bundle covering freshness, validation, load, and emit state, and `libstore.compiled_status_text(name)` as a JSON export for tooling/smokes.
- Added `libstore.compiled_inventory()` and `libstore.compiled_inventory_text()` so tooling can query/export consolidated `.bec` diagnostics for all discovered SD modules.
- Added `libstore.compiled_summary()` and `libstore.compiled_summary_text()` so tooling can query/export aggregate `.bec` readiness counts and load/emit blocker-reason histograms across discovered SD modules.
- Added `libstore.compiled_loadable()`, `libstore.compiled_emittable()`, and `libstore.compiled_blocked()` candidate-list helpers plus matching JSON exports for future `.bec` provisioning scripts.
- Added `libstore.compiled_provision_plan()` and `libstore.compiled_provision_plan_text()` so future tooling can consume summary, candidate lists, blocked state, and a conservative recommendation from one diagnostics map.
- Added `libstore.compile_cache_plan_many(names)`, `compile_cache_plan_many_text(names)`, `compile_cache_plan_all()`, `compile_cache_plan_all_text()`, `compile_cache_emit_many(names)`, and `compile_cache_emit_all()` as explicit bulk `.be` to `.bec` planning/emission helpers that report per-module blocked reasons and reason histograms instead of requiring callers to catch one exception per module.
- Added staged `p2compat` metadata for bytecode emit blocker-reason summaries.
- Added `libstore.compile_cache_provision_plan(names)`, `compile_cache_provision_plan_text(names)`, `compile_cache_provision_plan_all()`, and `compile_cache_provision_plan_all_text()` as dry-run `.be` to `.bec` emit provisioning plans with conservative recommendations.
- Added dry-run compile-cache candidate filters: `compile_cache_emittable(names)`, `compile_cache_blocked(names)`, `compile_cache_emittable_all()`, and `compile_cache_blocked_all()`, plus matching JSON exports.
- Mirrored compact status fields through `libstore.info()` and `p2mem.module(name)`.
- Updated `p2compat.bytecode()` and staged capability metadata for bytecode cache emission, bytecode bulk emission, bytecode bulk plan JSON exports, bytecode emit provisioning plans, bytecode emit candidate lists, bytecode emit candidate JSON exports, bytecode validation, explicit bytecode load API, consolidated bytecode status API, bytecode inventory API, bytecode summary API, bytecode blocker-reason summary, bytecode candidate lists, bytecode candidate JSON exports, and bytecode provisioning plan, keeping default source fallback explicit.
- Kept default import resolution and `.bec` execution unchanged: source fallback remains the active path, and unsupported/default builds fail loudly with `unsupported_error`.
- Extended `/tests/p2/smoke_bec_fallback.be` to cover both default unsupported emission and opt-in saver-enabled emission behavior without requiring `.bec` execution, and relaxed `/tests/p2/smoke_module_inventory.be` so compile-cache blocker metadata can be `nil` when an opt-in saver build can emit.
- Updated `port/p2/TODO.md`, `docs/coverage-matrix.md`, `docs/sd-layout.md`, and `docs/P2_MODULES.md`; hardware execution remains pending in TODO.

### Priority 1 native `sys` module coverage

### Priority 1 module inventory mutation-isolation coverage

- [x] Extended `/tests/p2/smoke_module_inventory.be` so returned `libstore.inventory()` and `libstore.compiled_inventory()` records are mutated by the caller and then reacquired to prove fresh snapshots are not poisoned by caller-side metadata edits. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

- Added `/tests/p2/smoke_sys.be` and wired it into `/tests/p2/smoke_all.be`.
- The smoke covers `sys.path()` list shape, copy isolation for returned path lists, callable `sys.path_add`, direct native path append, importing a tiny module from the appended root, and loud errors for missing, non-string, and empty path arguments.
- Added `sys_module` as a supported `p2compat` capability and extended `/tests/p2/smoke_p2compat.be` to assert the supported metadata.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; hardware execution remains pending in TODO.

### Priority 1 module inventory mutation-isolation coverage

- [x] Extended `/tests/p2/smoke_module_inventory.be` so returned `libstore.inventory()` and `libstore.compiled_inventory()` records are mutated by the caller and then reacquired to prove fresh snapshots are not poisoned by caller-side metadata edits. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 repeated missing-import recovery coverage

- [x] Extended `/tests/p2/smoke_import_missing.be` so the same missing module can fail repeatedly without creating bogus metadata, then be staged under `/berry/app`, imported, mutated, and imported again through an alias without losing the recovered cached module state. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 native-first import shadow-root coverage

- [x] Extended `/tests/p2/smoke_import_native_first.be` so native `json` must beat fake `/berry/lib/json.be` and `/berry/app/json.be` shadows, including a repeated aliased import. The smoke now asserts both shadow paths are absent before staging and removes only the files it created, preserving the Priority 0 SD-card write guardrail. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 full SD source-root order coverage

- [x] Extended `/tests/p2/smoke_import_order.be` so the temporary source-root collision coverage now proves `/modules` wins over appended roots, `/berry/lib` wins over `/berry/app` when `/modules` is absent, and repeated aliased imports keep the selected module object cached. The smoke still asserts temporary paths are absent before staging and removes only files it created. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 SD alias import cache-identity coverage

- [x] Extended `/tests/p2/smoke_import_alias.be` with a temporary `/berry/app/p2_alias_cache.be` module that is imported under two aliases. The smoke mutates state through the first alias and verifies the second alias sees the cached module object, while asserting the temporary path is absent before staging and removing only the file it created. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 current-directory import precedence coverage

- [x] Extended `/tests/p2/smoke_import_cwd.be` so a module in the active SD working directory wins over a same-name `/berry/app` source shadow, then remains cached after restoring the previous working directory and re-importing through an alias. The smoke asserts both temporary files are absent before staging and removes only files/directories it created. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 scoped libstore path mutation coverage

- [x] Tightened `/tests/p2/smoke_libstore_paths.be` so `libstore.path_add()` / `path_remove()` coverage uses a dedicated temporary `/berry/app/p2paths` root instead of mutating the default `/berry/app` root. The smoke now asserts its temporary file is absent before staging and removes the temporary directory only if it created it. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 nested app helper path coverage

- [x] Extended `/tests/p2/smoke_app_paths.be` so `libstore.app_path()`, `app_exists()`, and `run_app()` cover both a flat `/berry/app/*.be` script and a dotted nested app path such as `app_probe_pkg.probe` resolving to `/berry/app/app_probe_pkg/probe.be`. The smoke asserts temporary files are absent before staging and removes the nested app directory only if it created it. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 nested example helper path coverage

- [x] Extended `/tests/p2/smoke_example_paths.be` so `libstore.example_path()`, `example_exists()`, and `run_example()` cover both a flat `/berry/examples/*.be` script and a dotted nested example path such as `example_probe_pkg.probe` resolving to `/berry/examples/example_probe_pkg/probe.be`. The smoke asserts temporary files are absent before staging and removes the nested example directory only if it created it. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 nested PASM blob metadata coverage

- [x] Extended `/tests/p2/smoke_pasm_layout.be` so `libstore.pasm_path()`, `pasm_exists()`, and `pasm_info()` cover both a flat `/berry/pasm/*.bin` blob and a dotted nested blob path such as `pasm_probe_pkg.probe` resolving to `/berry/pasm/pasm_probe_pkg/probe.bin`. The smoke keeps `executable == false` / `pasm_execution_deferred`, asserts temporary files are absent before staging, and removes the nested PASM directory only if it created it. This is source-level metadata coverage only; PASM execution remains deferred in `TODO.md`.

### Priority 1 configstore load/fresh-reload coverage

- [x] Extended `/tests/p2/smoke_configstore.be` so missing config loads prove the caller-provided fallback object is returned as-is, while successful JSON config loads are re-read fresh from SD: caller-side mutations to a loaded map/list do not alter the saved file observed by a later `configstore.load()`. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 `/berry/main.be` startup smoke safety coverage

- [x] Tightened `/tests/p2/smoke_sd_main.be` so the optional startup-path smoke refuses to overwrite a pre-existing `/berry/main.be`, stages a tiny import-capable main script using `json`, runs it explicitly with `run_file()`, and removes only the file it created. This is source-level path coverage only; hardware boot execution remains pending in `TODO.md`.

### Priority 1 nested `/berry/lib` source-layout coverage

- [x] Extended `/tests/p2/smoke_import_layout.be` so the staged source-layout coverage now includes flat `/berry/lib`, flat `/berry/app`, and a nested `/berry/lib/layout_probe_pkg/mod.be` module resolved as `layout_probe_pkg.mod` through `libstore.source_path()` and native string import. The smoke asserts temporary files are absent before staging and removes the nested package directory only if it created it. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 import-all metadata-anchor coverage

- [x] Extended `/tests/p2/smoke_import_all_libs.be` so the current SD module import sweep verifies each module's `libstore.info()` metadata reports `/tests/p2/smoke_import_all_libs.be` as its SD import smoke and `/tests/p2/smoke_module_inventory.be` as its metadata smoke, while keeping `wifi` explicitly `hardware_deferred`. This remains safe import/metadata coverage only and avoids WiFi or other peripheral transactions; hardware execution remains pending in `TODO.md`.

### Priority 1 repeated-import metadata-anchor coverage

- [x] Extended `/tests/p2/smoke_import_cache.be` so the current SD module repeated-import/cache smoke verifies each module's `libstore.info()` metadata reports `/tests/p2/smoke_import_cache.be` as its repeated-import and cache smoke, `/tests/p2/smoke_import_churn.be` as its low-memory smoke, and keeps `wifi` explicitly `hardware_deferred`. This remains source-level import/cache metadata coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 low-memory import metadata-anchor coverage

- [x] Extended `/tests/p2/smoke_import_churn.be` so the bounded allocation/GC/import-churn smoke verifies each current SD module's `libstore.info()` metadata reports `/tests/p2/smoke_import_churn.be` as its low-memory smoke, `/tests/p2/smoke_import_cache.be` as its repeated-import and cache smoke, and `/tests/p2/smoke_import_all_libs.be` as its SD-import smoke, while keeping `wifi` explicitly `hardware_deferred`. This remains source-level import/metadata coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 lazy-library diagnostic snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so `libstore.status()` and `libstore.strategy()` snapshots can be mutated by the caller without poisoning later lazy-loader diagnostics. This keeps SD-backed lazy-loading, no eager PSRAM execution, and cache-status reporting observable as fresh diagnostic data. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 compact stdlib JSON parse-freshness coverage

- [x] Extended `/tests/p2/smoke_stdlib.be` so compact JSON coverage now mutates a parsed map/list and reparses the same JSON text to prove each `json.load()` returns fresh caller-owned data rather than reusing poisoned parse state. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 string format conversion hook invocation coverage

- [x] Extended `/tests/p2/smoke_string_format_extra.be` so a custom `toint()` object is formatted twice and must update its return value on each call, proving `string.format("%i", value)` invokes the conversion hook per formatting operation rather than caching a stale conversion. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 JSON escaped object-key coverage

- [x] Extended `/tests/p2/smoke_json_advanced.be` with escaped Unicode object-key decoding, proving `json.load()` maps a key such as `"\\u006B\\u0065\\u0079"` to the decoded Berry map key `"key"`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 time leap-day dump coverage

- [x] Extended `/tests/p2/smoke_time.be` with deterministic leap-day epoch coverage for `time.dump(951782400)`, asserting the decoded date is February 29, 2000 while preserving the existing integer field and epoch-shape checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 strict method-body global lookup coverage

- [x] Extended `/tests/p2/smoke_strict.be` with class-method strict lookup coverage: a method body can compile and read a known global while it is defined, and the same method-body shape is rejected after the global is undefined. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 debug caller boundary coverage

- [x] Extended `/tests/p2/smoke_debug.be` with an over-deep `debug.caller(64)` boundary assertion, proving the debug module returns a falsey result instead of a bogus stack frame when the requested caller depth is beyond the active stack. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 solidify repeated compaction coverage

- [x] Extended `/tests/p2/smoke_solidify.be` with repeated `solidify.compact(P2SolidifySmoke)` coverage, proving a class can be compacted twice without changing the expected instance method behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 sys.path element-mutation isolation coverage

- [x] Extended `/tests/p2/smoke_sys.be` with returned-path-list element replacement coverage, proving a caller can mutate index `0` of a `sys.path()` snapshot without changing the VM's live import path list. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 global map-valued mutation coverage

- [x] Extended `/tests/p2/smoke_global.be` with map-valued global storage and mutation coverage, proving a global map member can be read, updated in place, and cleaned up through the native `global` module path. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 JSON mixed stack-shape coverage

- [x] Extended `/tests/p2/smoke_json_stack.be` with a generated mixed object/list stack shape by embedding the existing generated nested-record list under an object key and asserting count plus mid-list record access. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 math abs parity coverage

- [x] Extended `/tests/p2/smoke_math_parity.be` with deterministic `math.abs()` sign/type coverage for negative and positive integers plus a negative real, complementing the existing no-argument fallback and upstream-adapted math parity checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 string adjacent replacement coverage

- [x] Extended `/tests/p2/smoke_string.be` with adjacent non-overlapping replacement coverage for `string.replace("aaaa", "aa", "b") == "bb"`, making native string replacement semantics explicit for back-to-back matches. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 JSON whitespace parsing coverage

- [x] Extended `/tests/p2/smoke_json.be` with whitespace-tolerant object/list parsing coverage, proving `json.load()` accepts spaces around object keys, separators, list values, and the top-level value while preserving `true` and `null` decoding. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 p2compat bytecode snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_p2compat.be` with `p2compat.bytecode()` snapshot mutation isolation coverage, proving caller-side mutation of the returned bytecode diagnostics map does not alter the module's current bytecode execution metadata. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 file/open append-create coverage

- [x] Extended `/tests/p2/smoke_sd.be` with append-mode creation coverage for a new temporary file, proving `open(path, "a")` can create, write, read back, and clean up a previously absent file. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 bytes range-slice isolation coverage

- [x] Extended `/tests/p2/smoke_bytes.be` with range-slice copy isolation coverage, proving mutating a sliced `bytes` value does not alter the original buffer. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 bytes fromstring empty reset coverage

- [x] Extended `/tests/p2/smoke_bytes_extra.be` with empty `fromstring("")` reset coverage, proving a non-empty bytes buffer can be replaced by an empty string payload just as the existing `fromhex("")` path clears hex content. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 bytes base64 two-byte padding coverage

- [x] Extended `/tests/p2/smoke_bytes_b64_fixed.be` with two-byte base64 padding coverage, proving `bytes("1122").tob64()` emits the single-padding form `"ESI="` and `fromb64("ESI=")` round-trips to `bytes("1122")`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 map nil-valued insert coverage

- [x] Extended `/tests/p2/smoke_map_core.be` with nil-valued `insert()` coverage, proving a map can insert a present key with a `nil` value and that a duplicate insert does not replace that nil-valued entry. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 range retargeted iterator preservation coverage

- [x] Extended `/tests/p2/smoke_range.be` with iterator preservation across `setrange()` retargeting, proving an iterator captured before retargeting continues its original sequence while the range object exposes the new bounds. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 list index-selection isolation coverage

- [x] Extended `/tests/p2/smoke_list_core.be` with list-index selection copy-isolation coverage, proving mutating a selected result from `src[list(...)]` does not alter the original source list. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 collections map keys/values snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_collections.be` with map `keys()` and `values()` returned-list mutation isolation coverage, proving caller-side mutations to those snapshots do not add keys or values to the source map. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 numeric conversion parser edge coverage

- [x] Extended `/tests/p2/smoke_conversions.be` with negative-exponent `number("1e-2")` and negative-real `real("-0.5")` string conversion coverage, tightening deterministic parser compatibility around numeric conversion helpers. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 call explicit nil list-expansion coverage

- [x] Extended `/tests/p2/smoke_call.be` with explicit `nil` values inside terminal list expansion, proving `call(f, [1, nil, 3])` preserves the nil argument for both fixed-argument and vararg functions. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 vararg method rest-list freshness coverage

- [x] Extended `/tests/p2/smoke_vararg.be` with method rest-list freshness coverage, proving mutating the returned `*rest` list from one method call does not leak into a later call with the same arguments. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 compiled closure retained-state coverage

- [x] Extended `/tests/p2/smoke_compile_module.be` with compiled closure retained-state coverage, proving a function returned by `compile()` can capture a mutable local and preserve updates across repeated calls. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 boolean short-circuit side-effect coverage

- [x] Extended `/tests/p2/smoke_bool.be` with short-circuit side-effect accounting, proving skipped `&&` / `||` branches do not run while executed branches update a counter as expected. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 nested map equality coverage

- [x] Extended `/tests/p2/smoke_relop.be` with nested map order-insensitive equality coverage, proving maps nested inside maps compare equal even when their keys were inserted in different orders. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 divzero adjacent signed division coverage

- [x] Extended `/tests/p2/smoke_divzero.be` with negative non-zero division and modulo checks, anchoring `-5 / 2 == -2` and `-5 % 2 == -1` next to the existing division-by-zero exception coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 suffix method-chain slice coverage

- [x] Extended `/tests/p2/smoke_suffix.be` with method-chain range-slice coverage, proving a list returned through chained suffix calls can be sliced directly with `[0..1]`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 shared reference stringification coverage

- [x] Extended `/tests/p2/smoke_reference.be` with shared-child list stringification coverage, proving repeated references to the same non-cyclic child list render normally and are not mistaken for recursive cycles. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 conditional-expression side-effect coverage

- [x] Extended `/tests/p2/smoke_cond_expr.be` with selected-branch side-effect accounting, proving conditional expressions evaluate exactly the chosen branch while preserving the existing unselected-branch exception checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 conditional-expression condition-evaluation coverage

- [x] Extended `/tests/p2/smoke_cond_expr.be` with condition-operand side-effect accounting for empty and non-empty list operands, proving conditional expressions evaluate the condition once and then preserve branch laziness for the unselected arm. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 compound computed-index update coverage

- [x] Extended `/tests/p2/smoke_compound.be` with computed list-index compound assignment coverage, proving `values[value_index] += values[0]` updates the dynamically selected slot while preserving the surrounding list values. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 assignment computed map-key/member coverage

- [x] Extended `/tests/p2/smoke_assignment.be` with computed map-key plus computed-member assignment coverage, proving a dynamic key can select an object and dynamic member names can assign and update its nested field. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 lexer comment-adjacent token coverage

- [x] Extended `/tests/p2/smoke_lexer.be` with comment-adjacent token parsing coverage, proving a compact block comment between expression tokens does not disrupt `compile()` or execution. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 walrus map-literal coverage

- [x] Extended `/tests/p2/smoke_walrus_edges.be` with map-literal assignment-expression coverage, proving walrus assignments can provide both a map key and value while preserving the assigned bindings. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 f-string computed-width coverage

- [x] Extended `/tests/p2/smoke_syntax.be` with computed-width f-string formatting coverage, proving an expression-supplied width such as `{42:0{fwidth}i}` formats through the compact syntax smoke path. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 virtual member state-backed read coverage

- [x] Extended `/tests/p2/smoke_virtual_members.be` with a state-backed virtual member, proving `member(name)` can compute a virtual field from an instance's real fields while preserving existing real-member precedence checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 virtual setmember replacement coverage

- [x] Extended `/tests/p2/smoke_virtual_setmember.be` with repeated virtual payload assignment coverage, proving a later `setmember()` write replaces the previous virtual value and the backing assignment map reports the new payload. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 module attribute real-precedence hook coverage

- [x] Extended `/tests/p2/smoke_module_attrs.be` with virtual `member()` lookup counting, proving real module attributes are returned without invoking the virtual member hook while missing attributes still dispatch through it. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 module same-name independence coverage

- [x] Extended `/tests/p2/smoke_module_system.be` with same-name module independence coverage, proving repeated `module("name")` calls create distinct module objects until a module is explicitly injected into the import cache. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 signed right-shift numeric coverage

- [x] Extended `/tests/p2/smoke_int_numeric.be` with signed right-shift coverage, proving `-8 >> 1` produces `-4` alongside the existing integer conversion, hex parsing, bitwise, and positive shift checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 chained super argument-passing coverage

- [x] Extended `/tests/p2/smoke_super.be` with chained `super(self).method(arg)` argument-passing coverage, proving a three-level class hierarchy can pass an argument through successive super calls while accumulating instance state. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 subobject builtin method preservation coverage

- [x] Extended `/tests/p2/smoke_subobject.be` with builtin method preservation coverage for list/map subclasses, proving subclass instances retain native methods such as `copy()` and `keys()` while preserving subclass storage behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 static class mutable object sharing coverage

- [x] Extended `/tests/p2/smoke_static_classes.be` with mutable static-list sharing coverage, proving class-level and instance-level reads observe the same static list object after mutation. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 static declaration cross-instance sharing coverage

- [x] Extended `/tests/p2/smoke_static_decls.be` with cross-instance static storage sharing coverage, proving multiple instances observe the same mutated static field values after class-level updates. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 static super live base-static coverage

- [x] Extended `/tests/p2/smoke_static_super_member.be` with live base-static mutation coverage, proving an inherited method reads the updated base-class static value while the child class's static override remains separate. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 class static function reassignment coverage

- [x] Extended `/tests/p2/smoke_class_const.be` with static function reassignment readback coverage, proving both class-level and existing instance-level reads observe a replaced static callable. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 compact stdlib JSON dump-state coverage

- [x] Extended `/tests/p2/smoke_stdlib.be` with compact JSON dump-state coverage, proving `json.dump()` serializes the caller's current nested map/list state while leaving that caller-owned source object intact for subsequent reads. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 compact stdlib time dump snapshot coverage

- [x] Extended `/tests/p2/smoke_stdlib.be` with compact `time.dump()` snapshot-freshness coverage, proving caller-side mutation of one returned epoch map does not poison a later dump of the same epoch. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 time dump collection-input rejection coverage

- [x] Extended `/tests/p2/smoke_time.be` with collection-valued invalid-input checks for `time.dump([])` and `time.dump({})`, complementing the existing nil/string/real/bool rejection coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 global module API-shape coverage

- [x] Extended `/tests/p2/smoke_global.be` with native `global` API-shape assertions, proving the imported object is a module and the callable table view reports as a map before exercising lookup, mutation, compile visibility, and cleanup behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 string module object-shape coverage

- [x] Extended `/tests/p2/smoke_string.be` with an imported-module object-shape assertion, proving `string` reports as a module before the smoke exercises helper exports, formatting, replacement, prefix/suffix, indexing, and multiplication behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 JSON module object-shape coverage

- [x] Extended `/tests/p2/smoke_json.be` with an imported-module object-shape assertion, proving `json` reports as a module before the smoke exercises `load`, `dump`, scalar parsing, malformed input rejection, nested data, formatted dumps, subclass dumps, and round-trip behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 solidify introspected helper coverage

- [x] Extended `/tests/p2/smoke_solidify.be` with `introspect.contains()` checks for the native `solidify.dump` and `solidify.compact` helpers, proving the module's core helpers are both callable and discoverable before compacting class shapes. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 strict branch-condition global lookup coverage

- [x] Extended `/tests/p2/smoke_strict.be` with strict compiler-mode coverage for global lookup in branch conditions: the conditional shape compiles and runs while the global is defined, then the same shape is rejected after cleanup through `global.undef()`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 debug module API-shape coverage

- [x] Extended `/tests/p2/smoke_debug.be` with native `debug` module/API-shape assertions and `introspect.contains()` checks for `attrdump` and `caller`, proving the core helpers are callable and discoverable before stack introspection coverage runs. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 sys module API-shape coverage

- [x] Extended `/tests/p2/smoke_sys.be` with native `sys` module/API-shape assertions, proving the imported object reports as a module and exposes `path()` as a function before the smoke exercises path snapshots, element-mutation isolation, `path_add()` error paths, and direct import-root behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 introspect module API-shape coverage

- [x] Extended `/tests/p2/smoke_introspect.be` with native `introspect` module/API-shape assertions for the core reflection helpers before the smoke exercises member lookup, mutation, method classification, pointer round trips, solidified checks, fallback reads, and missing-module handling. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 bytes size API-shape coverage

- [x] Extended `/tests/p2/smoke_bytes.be` with a callable `size()` API-shape assertion on a fresh bytes object, pinning the method before construction, resize, range, copy, conversion, and mutation behavior rely on it. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 bytes extra method API-shape coverage

- [x] Extended `/tests/p2/smoke_bytes_extra.be` with callable API-shape assertions for extended bytes helpers such as `set`, float accessors, `fromhex`, `setbytes`, `reverse`, boolean conversion, and base64 append/encode methods before their behavior checks run. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 bytes base64 API-shape coverage

- [x] Extended `/tests/p2/smoke_bytes_b64_fixed.be` with callable API-shape assertions for `tob64()` and `fromb64()` before the smoke exercises padding, no-padding, fixed-size initialization, fixed-size mutation rejection, and concatenation behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 list size API-shape coverage

- [x] Extended `/tests/p2/smoke_list_core.be` with a callable `size()` API-shape assertion on a fresh list, pinning the method alongside iterator, copy, mutation, find, keys, and concat helper coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 map keys-values API-shape coverage

- [x] Extended `/tests/p2/smoke_map_core.be` with callable `keys()` and `values()` API-shape assertions on a fresh map, pinning those helper methods alongside find/contains/remove/insert/iter/size before map lookup, iteration, insertion, and cleanup behavior runs. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 range method API-shape coverage

- [x] Extended `/tests/p2/smoke_range.be` with callable API-shape assertions for `lower()`, `upper()`, `incr()`, `iter()`, and `setrange()` before the smoke exercises range accessors, retargeting, iterator independence, descending sequences, and value-error paths. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 range type classification coverage

- [x] Extended `/tests/p2/smoke_conversions.be` with `type(range(0, 1)) == "range"`, pinning range object classification alongside the existing nil/bool/int/real/string/list/map/bytes type checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 call constructor list-expansion coverage

- [x] Extended `/tests/p2/smoke_call.be` with class-constructor terminal-list expansion coverage, proving `call(Class, [arg])` expands the final list into constructor arguments while preserving the existing direct constructor path. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 vararg direct rest-list freshness coverage

- [x] Extended `/tests/p2/smoke_vararg.be` with direct required-plus-rest vararg freshness coverage, proving mutating a returned rest list from `f(1, 2)` does not leak into a later direct call with the same arguments. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 closure returned-function classification coverage

- [x] Extended `/tests/p2/smoke_closure.be` with returned-closure `type(...) == "function"` assertions for independent counter closures before exercising their captured state and mutation behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 function-capture returned-function classification coverage

- [x] Extended `/tests/p2/smoke_function_capture.be` with returned-function `type(...) == "function"` assertions for independent factory closures before exercising their separate captured mutable state. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 for-loop empty-range coverage

- [x] Extended `/tests/p2/smoke_for_loop.be` with empty descending-range iteration coverage, proving a `for i : 5 .. 0` loop body is skipped and does not mutate surrounding state. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 map key-error exception coverage

- [x] Extended `/tests/p2/smoke_errors.be` with map missing-key `key_error` coverage, adding that exception class beside the existing custom raise, syntax, type, bytes index, helper propagation, nested handling, and rethrow checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 assert default-message exception coverage

- [x] Extended `/tests/p2/smoke_exception_assert.be` with default-message `assert(false)` coverage, proving it raises `assert_failed` even when no custom assertion message is provided. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 operator-overload result class identity coverage

- [x] Extended `/tests/p2/smoke_operator_overload.be` with `classof(...)` assertions for overloaded `+` result instances, proving both direct and chained binary overload results preserve the expected class identity in addition to their payload values. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 VM comparison result-type coverage

- [x] Extended `/tests/p2/smoke_vm_ops.be` with boolean result-type assertions for equality and relational comparisons, pinning comparison expressions as `bool` before the smoke exercises overloaded equality/inequality behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 VM named-global cleanup coverage

- [x] Extended `/tests/p2/smoke_vm_error_paths.be` with named-global cleanup coverage, proving the temporary global used for named-global read/write opcode checks is absent after `global.undef()`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 compiler parser call-result chained-suffix coverage

- [x] Extended `/tests/p2/smoke_compiler_parser.be` with a function-call-result chained-suffix parser shape, proving a nested list returned by a helper can be indexed immediately as `make_suffix_rows()[1][0]`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 class instance identity coverage

- [x] Extended `/tests/p2/smoke_classes.be` with `classof(demo) == StaticDemo`, pinning class identity for a constructed instance before the smoke exercises instance state, static fallback, static methods, module-member construction, and indirect member access. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 indirect static method dispatch coverage

- [x] Extended `/tests/p2/smoke_member_indirect.be` with computed static method dispatch through `P2IndirectStatic.(static_methods[0])()`, complementing the existing module/class/instance indirect member reads, writes, instance method dispatch, dynamic static writes, and chained updates. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 nested static class identity coverage

- [x] Extended `/tests/p2/smoke_static_classes.be` with first-class nested static class readback coverage, constructing an instance through a saved `P2StaticOuter.Inner` reference and checking `classof()` plus instance method dispatch. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 static declaration mutable map coverage

- [x] Extended `/tests/p2/smoke_static_decls.be` with mutable static map sharing coverage, proving class-level and instance-level reads observe the same map after mutation through another instance. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 class constant scalar update coverage

- [x] Extended `/tests/p2/smoke_class_const.be` with class-side scalar compound update coverage, proving an existing instance observes the updated static value through instance fallback. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 static super child override mutation coverage

- [x] Extended `/tests/p2/smoke_static_super_member.be` with child static override mutation coverage, proving an inherited dynamic static lookup observes the updated child value while inherited base-method reads and base instances remain pinned to the base static value. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 module same-name member table independence coverage

- [x] Extended `/tests/p2/smoke_module_system.be` with same-name module member-table independence coverage, proving repeated `module("name")` objects keep separate mutable member state until explicit import-cache injection. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 module post-virtual shadow precedence coverage

- [x] Extended `/tests/p2/smoke_module_attrs.be` with post-virtual shadow precedence coverage, proving a real module field assigned after a virtual `member()` lookup takes precedence without invoking the virtual hook again. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 saved inherited ismethod coverage

- [x] Extended `/tests/p2/smoke_introspect_ismethod.be` with saved inherited method and saved inherited static-method classification, proving values fetched from a child instance preserve `ismethod()` behavior after assignment to locals. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 compiled local map mutation coverage

- [x] Extended `/tests/p2/smoke_compile_module.be` with compiled local map mutation coverage, proving code produced by `compile()` can create a map, assign a new key, and read the updated values before returning. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 string format character conversion-hook coverage

- [x] Extended `/tests/p2/smoke_string_format_extra.be` with `%c` conversion-hook coverage for a stateful `toint()` object, proving character formatting invokes the conversion hook and updates object state. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 JSON multi-entry Unicode array coverage

- [x] Extended `/tests/p2/smoke_json_advanced.be` with escaped Unicode decoding inside a multi-entry JSON array, proving ASCII, two-byte, and three-byte escape expansions decode correctly in array values. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 JSON generated matrix stack coverage

- [x] Extended `/tests/p2/smoke_json_stack.be` with a compact generated matrix/list-of-lists parse, proving JSON stack/growth coverage includes nested arrays with indexed numeric reads. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 time module API-shape coverage

- [x] Extended `/tests/p2/smoke_time.be` with native `time` module/API-shape assertions for `clock`, `dump`, and `time` before deterministic epoch, invalid-input, mutation-isolation, and `time()` consistency checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 solidify static mutation after compaction coverage

- [x] Extended `/tests/p2/smoke_solidify.be` with static member mutation after `solidify.compact()`, proving a compacted class's static method observes the updated static value while inherited instance behavior still works. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 debug attrdump instance coverage

- [x] Extended `/tests/p2/smoke_debug.be` with instance-level `debug.attrdump()` no-crash coverage, proving a normal instance method read still works before and after debug inspection. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 sys path fresh-list identity coverage

- [x] Extended `/tests/p2/smoke_sys.be` with `introspect.toptr()` checks proving repeated `sys.path()` calls return distinct list objects before the smoke exercises snapshot mutation, `path_add()` error paths, and direct import-root behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 strict loop-condition global lookup coverage

- [x] Extended `/tests/p2/smoke_strict.be` with strict compiler-mode coverage for known-global lookup in `while` conditions, proving the loop-condition shape compiles and runs while the global is defined and is rejected after cleanup through `global.undef()`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 global helper API-shape coverage

- [x] Extended `/tests/p2/smoke_global.be` with native `global.contains` and `global.undef` helper API-shape assertions before exercising lookup, mutation, compile visibility, table views, and cleanup behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 string count no-match coverage

- [x] Extended `/tests/p2/smoke_string.be` with `string.count()` no-match coverage, proving a missing substring returns zero before the smoke exercises bounded counts, splitting, escaping, replacement, formatting, prefix/suffix helpers, indexing, and multiplication behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 JSON formatted nested-list dump coverage

- [x] Extended `/tests/p2/smoke_json.be` with formatted nested-list dump coverage, proving `json.dump(value, "format")` indents a nested list while preserving the existing scalar/list/map dump and round-trip checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 bytes empty append no-op coverage

- [x] Extended `/tests/p2/smoke_bytes.be` with empty `bytes()` append no-op coverage, proving appending an empty bytes value preserves the receiver before the smoke exercises string append, appendhex, range slicing, copy isolation, conversion, and mutation behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 virtual setmember computed scalar write coverage

- [x] Extended `/tests/p2/smoke_virtual_setmember.be` with computed-name assignment to the scalar virtual field itself, proving `obj.(name) = value` routes through `setmember()` for `"virtual"` before the smoke exercises computed payload and function-valued assignments. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 module indirect function-call coverage

- [x] Extended `/tests/p2/smoke_member_indirect.be` with module indirect function-call coverage, proving a function-valued module member can be looked up through a computed `.(name)` expression and invoked immediately. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 subobject map keys snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_subobject.be` with map-subclass `keys()` snapshot isolation coverage, proving a saved keys list from a map subclass does not grow after later subclass storage mutation while a fresh `keys()` call sees the new key. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 walrus local call-argument value coverage

- [x] Extended `/tests/p2/smoke_walrus_edges.be` with local walrus assignments inside function-call arguments, proving argument evaluation returns assigned values left-to-right and leaves the assigned locals readable after the call. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 f-string computed map-key expression coverage

- [x] Extended `/tests/p2/smoke_syntax.be` with f-string computed map-key expression coverage, proving an f-string expression can index a map through a key variable after the existing list-index and literal map-key checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 lexer line-comment adjacent token coverage

- [x] Extended `/tests/p2/smoke_lexer.be` with line-comment-adjacent token parsing coverage, proving a `#` line comment between expression tokens does not disrupt `compile()` or execution alongside the existing compact block-comment coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 class static update observed by existing instance coverage

- [x] Extended `/tests/p2/smoke_classes.be` with static field mutation after instance creation, proving an existing instance and its instance method observe the updated class static value through fallback lookup. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 function-capture shared-upvalue group independence coverage

- [x] Extended `/tests/p2/smoke_function_capture.be` with a second shared-upvalue closure pair, proving closures from one factory call share their captured state while a separate factory call owns an independent shared-upvalue group. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 closure mutable capture independence coverage

- [x] Extended `/tests/p2/smoke_closure.be` with a second list-accumulator closure, proving separate factory calls retain independent captured mutable lists while the original accumulator keeps its own state. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 escaped vararg rest-list mutation persistence coverage

- [x] Extended `/tests/p2/smoke_vararg.be` with escaped rest-list mutation persistence coverage, proving a closure-captured vararg list remains a retained mutable object across later closure calls. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 callable-instance list lookup invocation coverage

- [x] Extended `/tests/p2/smoke_operator_overload.be` with callable-instance invocation after list lookup, proving an object implementing `def ()()` remains callable when fetched through an indexed collection suffix. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 integer variable shift-count coverage

- [x] Extended `/tests/p2/smoke_int_numeric.be` with variable shift-count coverage, proving left and right shifts accept a runtime integer shift amount alongside the existing literal, zero-shift, signed right-shift, and precedence checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 method-call raise propagation coverage

- [x] Extended `/tests/p2/smoke_errors.be` with method-call `raise` propagation coverage, proving a custom error type and message survive when raised inside an instance method and caught by the caller. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 method-call assert propagation coverage

- [x] Extended `/tests/p2/smoke_exception_assert.be` with method-call assert propagation coverage, proving a custom `assert_failed` message survives when the failing assertion is raised inside an instance method. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 nested for-loop outer-break coverage

- [x] Extended `/tests/p2/smoke_for_loop.be` with nested-loop outer `break` coverage, proving an outer-loop break stops later outer iterations after the completed inner-loop work for earlier outer values. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 suffix method-chain negative-index coverage

- [x] Extended `/tests/p2/smoke_suffix.be` with method-chain negative-index coverage, proving a list returned through chained suffix calls can be immediately indexed with `[-1]` after the existing positive-index and range-slice checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 compound computed map-key sibling isolation coverage

- [x] Extended `/tests/p2/smoke_compound.be` with computed map-key sibling isolation coverage, retargeting the dynamic key used for compound assignment and proving the selected map entry changes while the previously updated sibling remains stable. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 assignment computed map-key sibling isolation coverage

- [x] Extended `/tests/p2/smoke_assignment.be` with computed map-key sibling isolation coverage, proving dynamic-key nested member assignment updates the selected object while preserving a previously updated sibling object. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 falsey collection OR branch execution coverage

- [x] Extended `/tests/p2/smoke_bool.be` with side-effect accounting for `[] || mark(...)`, proving a falsey collection on the left side of `||` evaluates the right branch rather than only returning the expected boolean result. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 list equality order-sensitivity coverage

- [x] Extended `/tests/p2/smoke_relop.be` with list order-sensitivity checks, proving `[1, 2]` and `[2, 1]` compare unequal while map equality coverage remains order-independent. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 module computed virtual function read coverage

- [x] Extended `/tests/p2/smoke_virtual_members.be` with computed-name module virtual function lookup, saving `dyn.("fn")` through an indirect name and invoking the returned function to prove function-valued virtual members survive computed reads. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 saved function-valued member ismethod coverage

- [x] Extended `/tests/p2/smoke_introspect_ismethod.be` with saved function-valued instance-member classification, proving a plain function stored on an instance remains `introspect.ismethod(...) == false` after assignment to a local. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 solidify compact string invalid-type coverage

- [x] Extended `/tests/p2/smoke_solidify.be` with string-valued invalid-input coverage for `solidify.compact()`, pairing the existing integer rejection and proving non-class compact targets raise `value_error` before normal class compaction behavior runs. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 global nil helper rejection coverage

- [x] Extended `/tests/p2/smoke_global.be` with `global.contains(nil)` and `global.undef(nil)` rejection coverage, pairing the existing non-string integer helper checks and proving nil helper input is rejected without mutating the global table. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 time false-bool invalid dump input coverage

- [x] Extended `/tests/p2/smoke_time.be` with `time.dump(false) == nil`, pairing the existing true-bool rejection and proving falsey boolean input is rejected through the same invalid-input path. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 JSON top-level scalar whitespace coverage

- [x] Extended `/tests/p2/smoke_json.be` with whitespace-tolerant top-level scalar parsing coverage, proving `json.load()` accepts surrounding spaces for scalar `true` and `null` values before the smoke exercises numeric, string, object, list, dump, and round-trip behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 string adjacent substring count coverage

- [x] Extended `/tests/p2/smoke_string.be` with adjacent multi-character `string.count()` coverage, proving non-overlapping adjacent substring matches such as `"aa"` in `"aaaa"` are counted as two matches. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 range retargeted iterator exhaustion coverage

- [x] Extended `/tests/p2/smoke_range.be` with iterator exhaustion checks after `setrange()` retargeting, proving preserved positive and negative iterators terminate on their original bounds rather than drifting into the retargeted range. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 map equivalent-key removal coverage

- [x] Extended `/tests/p2/smoke_map_keys.be` with equivalent fresh-key removal coverage, proving `remove()` honors custom `hash()`/`==` identity by deleting the existing logical key without disturbing a separate entry. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 bytes length-based truthiness coverage

- [x] Extended `/tests/p2/smoke_bytes_extra.be` with `bytes("00").tobool() == true`, proving bytes truthiness is based on buffer length rather than nonzero byte contents. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 bytes four-byte base64 round-trip coverage

- [x] Extended `/tests/p2/smoke_bytes_b64_fixed.be` with four-byte base64 padding coverage, proving `bytes("11223344").tob64()` emits `"ESIzRA=="` and `fromb64("ESIzRA==")` round-trips to the original bytes. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 map keys snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_map_core.be` with `keys()` snapshot isolation coverage, proving a previously captured keys list does not grow after the source map is mutated with a new key. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 list copy bidirectional isolation coverage

- [x] Extended `/tests/p2/smoke_list_core.be` with copied-list mutation isolation coverage, proving mutating the copied list after `copy()` does not alter the source list, complementing the existing source-mutation-does-not-alter-copy check. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 map-core values snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_map_core.be` with `values()` snapshot isolation coverage, proving a previously captured values list does not grow after source-map mutation and that caller-side mutation of the values list does not mutate the source map. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 call non-callable error coverage

- [x] Extended `/tests/p2/smoke_call.be` with non-callable rejection coverage for `nil`, integer, and list receivers before the existing positive `call()` dispatch and argument-expansion checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 bytes truthiness conversion coverage

- [x] Extended `/tests/p2/smoke_conversions.be` with `bool(bytes()) == false` and `bool(bytes("00")) == true`, pinning core builtin truthiness for empty and non-empty bytes values by length. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 list iterator exhaustion coverage

- [x] Extended `/tests/p2/smoke_list_core.be` with an iterator exhaustion assertion after the last yielded list element, pinning the `nil` end-of-iteration result alongside existing iterator ordering coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 string empty-subject find/count coverage

- [x] Extended `/tests/p2/smoke_string.be` with empty-subject `string.find()` and `string.count()` boundary coverage, pinning empty-needle behavior on `""` alongside the existing non-empty search/count cases. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 range independent iterator exhaustion coverage

- [x] Extended `/tests/p2/smoke_range.be` with exhaustion coverage for a second iterator captured from the same range object, proving independent iterator state reaches its own `nil` endpoint without aliasing the first iterator. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 string empty-subject prefix/suffix coverage

- [x] Extended `/tests/p2/smoke_string.be` with empty-subject negative assertions for `string.startswith("", "x")` and `string.endswith("", "x")`, pinning prefix/suffix helper boundaries alongside the existing empty-needle positive cases. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 JSON empty container load/dump coverage

- [x] Extended `/tests/p2/smoke_json.be` with empty array/object `json.load()` and `json.dump()` assertions, pinning compact container boundaries alongside the existing scalar, nested, formatted, and round-trip cases. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 time dump non-empty collection rejection coverage

- [x] Extended `/tests/p2/smoke_time.be` with non-empty list and map invalid-input checks for `time.dump()`, proving collection rejection is type-based rather than limited to empty containers. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 JSON trailing-token rejection coverage

- [x] Extended `/tests/p2/smoke_json.be` with trailing-token rejection checks for scalar and array JSON inputs, pinning that `json.load()` fails rather than silently accepting a valid prefix. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 global boolean helper rejection coverage

- [x] Extended `/tests/p2/smoke_global.be` with boolean-input rejection checks for `global.contains(true)` and `global.undef(false)`, pinning non-string helper behavior alongside existing integer and nil edge cases. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 solidify nocompact string invalid-input coverage

- [x] Extended `/tests/p2/smoke_solidify.be` with optional `solidify.nocompact("not a function")` invalid-input coverage when the helper is present, pairing the existing integer rejection and valid-function behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 debug caller zero-depth coverage

- [x] Extended `/tests/p2/smoke_debug.be` with a `debug.caller(0)` assertion inside the caller-chain helper, proving zero depth resolves to the current function before the smoke walks direct, wrapped, nested, and over-deep caller frames. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 sys.path_add nil/list invalid-input coverage

- [x] Extended `/tests/p2/smoke_sys.be` with `sys.path_add(nil)` and `sys.path_add([])` rejection checks, pinning non-string invalid-input behavior alongside the existing missing, integer, and empty-string path cases. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 strict conditional-expression global lookup coverage

- [x] Extended `/tests/p2/smoke_strict.be` with strict compiler-mode coverage for known-global lookup inside a conditional expression, proving the ternary shape compiles while the global is defined and is rejected after cleanup through `global.undef()`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 bytes bidirectional copy isolation coverage

- [x] Extended `/tests/p2/smoke_bytes.be` with source-after-copy mutation isolation coverage, proving mutating the original bytes buffer after `copy()` does not alter the copied buffer, complementing the existing copy-mutation-does-not-affect-source check. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 bytes setbytes source-preservation coverage

- [x] Extended `/tests/p2/smoke_bytes_extra.be` with a `setbytes()` source-buffer preservation assertion, proving copying bytes into a target does not mutate the source buffer. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 bytes six-byte base64 round-trip coverage

- [x] Extended `/tests/p2/smoke_bytes_b64_fixed.be` with six-byte base64 no-padding coverage, proving two complete base64 quanta encode as `"ESIzRFVm"` and decode back to `bytes("112233445566")`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 math round half-boundary coverage

- [x] Extended `/tests/p2/smoke_math_parity.be` with `math.round(0.5) == 1` and `math.round(-0.5) == -1`, pinning half-away rounding behavior around zero alongside the existing positive and negative nonzero cases. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 p2compat summary snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_p2compat.be` with `p2compat.summary()` snapshot mutation isolation coverage, proving caller-side mutation of the returned summary map does not alter fresh summary results from the module. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 configstore path validation coverage

- [x] Extended `/tests/p2/smoke_configstore.be` with invalid `configstore.path()` checks for empty and slash-containing names, proving public path construction follows the same filename-only validation as `configstore.name()`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 example helper missing-exists coverage

- [x] Extended `/tests/p2/smoke_example_paths.be` with `libstore.example_exists("no_such_example_probe") == false`, pinning missing-example existence behavior alongside the existing missing `run_example()` nil result. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 PASM helper missing-exists coverage

- [x] Extended `/tests/p2/smoke_pasm_layout.be` with `libstore.pasm_exists("no_such_pasm_probe") == false`, pinning missing PASM blob existence behavior alongside the existing missing `pasm_info()` metadata. Source-level metadata coverage only; PASM execution remains deferred in `TODO.md`.

## Priority 1 missing-import compiled-status metadata coverage

- [x] Extended `/tests/p2/smoke_import_missing.be` with `libstore.compiled_status(missing_name) == "missing"`, pinning helper-level missing metadata before the smoke stages, imports, mutates, and reimports the recovered module. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 missing-import recovery diagnostics coverage

- [x] Extended `/tests/p2/smoke_import_missing.be` so the recovered module now pins `libstore.info()` selected kind, selected path, and nonzero source-size metadata after the previously missing `/berry/app` module is staged, imported, mutated, and reimported. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 import-alias info diagnostics coverage

- [x] Extended `/tests/p2/smoke_import_alias.be` so the staged repeated-alias module now pins `libstore.info()` existence, selected path, and nonzero source-size metadata alongside the existing `source_path()` and alias-cache mutation checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 import-cache source metadata parity coverage

- [x] Extended `/tests/p2/smoke_import_cache.be` so each current SD module now checks `libstore.info()` source size/hash metadata against `libstore.source_stats()` while preserving the existing repeated-import identity, metadata-anchor, and optional PSRAM source-cache checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 import-churn source metadata parity coverage

- [x] Extended `/tests/p2/smoke_import_churn.be` so each current SD module now checks `libstore.info()` source size/hash metadata against `libstore.source_stats()` inside the bounded allocation/GC/import-churn smoke. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 import-cache SD-import metadata-anchor coverage

- [x] Extended `/tests/p2/smoke_import_cache.be` so the repeated-import/cache smoke also verifies each current SD module reports `/tests/p2/smoke_import_all_libs.be` as its SD-import smoke metadata anchor, alongside the existing repeated-import, cache, and low-memory anchors. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 import-churn cache metadata-anchor coverage

- [x] Extended `/tests/p2/smoke_import_churn.be` so the bounded allocation/GC/import-churn smoke verifies each current SD module reports `/tests/p2/smoke_import_cache.be` as its cache smoke metadata anchor, alongside low-memory, repeated-import, and SD-import anchors. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 module inventory compiled-summary snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_module_inventory.be` with `libstore.compiled_summary()` snapshot mutation isolation coverage, proving caller-side mutation of the returned summary map does not alter fresh compiled-summary diagnostics. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 import-all behavior metadata coverage

- [x] Extended `/tests/p2/smoke_import_all_libs.be` so the safe import sweep verifies covered modules expose string-valued behavior-smoke metadata while `wifi` remains explicitly `hardware_deferred` with no behavior smoke claim. Source-level metadata coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 import-all source metadata parity coverage

- [x] Extended `/tests/p2/smoke_import_all_libs.be` so each current SD module now checks `libstore.info()` source size/hash metadata against `libstore.source_stats()` inside the safe import sweep. Source-level metadata coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 BEC execution-probe snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_bec_fallback.be` with `libstore.compiled_execution_probe()` snapshot mutation isolation coverage, proving caller-side mutation of the returned bytecode execution-policy map does not alter fresh probe diagnostics. Source-level metadata coverage only; `.bec` execution remains deferred in `TODO.md`.

## Priority 1 import-order source-path diagnostics coverage

- [x] Extended `/tests/p2/smoke_import_order.be` with `libstore.source_path()` assertions for the `/modules` and `/berry/lib` winning roots, proving diagnostics mirror the same precedence as native imports. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## Priority 1 import-alias source-path diagnostics coverage

- [x] Extended `/tests/p2/smoke_import_alias.be` with a `libstore.source_path("p2_alias_cache")` assertion for the staged alias-import module, proving diagnostics point at the same `/berry/app` source file used by repeated alias imports. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 app helper missing-exists fallback coverage

- [x] Extended `/tests/p2/smoke_app_paths.be` so the missing `/berry/app` helper path now checks both `libstore.app_exists("no_such_app_probe") == false` and `libstore.run_app("no_such_app_probe") == nil`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 example helper missing-path fallback coverage

- [x] Extended `/tests/p2/smoke_example_paths.be` so the missing `/berry/examples` helper path now checks `libstore.example_path("no_such_example_probe") == nil` before the existing missing existence/run fallback assertions. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 PASM helper missing-path fallback coverage

- [x] Extended `/tests/p2/smoke_pasm_layout.be` so the missing `/berry/pasm` helper path now checks `libstore.pasm_path("no_such_pasm_probe") == nil` before the existing missing existence/info fallback assertions. Source-level metadata coverage only; PASM execution remains deferred in `TODO.md`.

### Priority 1 app helper missing-path fallback coverage

- [x] Extended `/tests/p2/smoke_app_paths.be` so the missing `/berry/app` helper path now checks `libstore.app_path("no_such_app_probe") == nil` before the existing missing existence/run fallback assertions. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 configstore uppercase suffix normalization coverage

- [x] Extended `/tests/p2/smoke_configstore.be` so `configstore.name("Caps.JSON")` and `configstore.path("Caps.JSON")` preserve an existing uppercase `.JSON` suffix instead of appending a second suffix. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 os.path local no-extension splitext coverage

- [x] Extended `/tests/p2/smoke_sd.be` with `os.path.splitext("LOCAL") == ["LOCAL", ""]`, pinning the local relative no-extension helper shape without adding any new SD writes. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 `/berry/main.be` staged-file lifecycle coverage

- [x] Extended `/tests/p2/smoke_sd_main.be` so the optional startup-path smoke verifies `/berry/main.be` exists after staging and is absent again after cleanup, while still refusing to overwrite a pre-existing file. Source-level path coverage only; hardware boot execution remains pending in `TODO.md`.

### Priority 1 dotted package companion diagnostics coverage

- [x] Extended `/tests/p2/smoke_package_paths.be` so the companion comma-import module `pkg.other` now has direct `libstore.module_file()`, `source_path()`, and `info()` diagnostics pinned to `/berry/app/pkg/other.be`, matching the existing `pkg.mod` diagnostics. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 native-first repeated import identity coverage

- [x] Extended `/tests/p2/smoke_import_native_first.be` so repeated native `json` imports under fake `/berry/lib/json.be` and `/berry/app/json.be` shadows now prove cached module identity with `introspect.toptr()`, in addition to proving the native module wins over both SD shadows. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 import-order info diagnostics coverage

- [x] Extended `/tests/p2/smoke_import_order.be` so the `/modules` and `/berry/lib` winning-root cases now pin `libstore.info()` existence, path, and nonzero source-size metadata alongside the existing native import and `source_path()` precedence checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 current-directory import identity coverage

- [x] Extended `/tests/p2/smoke_import_cwd.be` so the cached current-directory module reimport now proves object identity with `introspect.toptr()` after restoring the original working directory, alongside the existing mutation-visibility check. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 sys.path_add diagnostics coverage

- [x] Extended `/tests/p2/smoke_sys_path_add.be` so the module staged under the appended `/berry/sys_path` root now pins `libstore.info()` existence, path, and nonzero source-size metadata alongside duplicate-safe `path_add()`, `source_path()`, and native import coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 scoped libstore path diagnostics coverage

- [x] Extended `/tests/p2/smoke_libstore_paths.be` so the module staged under the scoped `/berry/app/p2paths` root now pins `libstore.info()` path and nonzero source-size metadata alongside duplicate-safe `path_add()`, `source_path()`, `load()`, and `path_remove()` coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 import-layout info diagnostics coverage

- [x] Extended `/tests/p2/smoke_import_layout.be` so the staged flat `/berry/lib`, flat `/berry/app`, and nested `/berry/lib` package modules now pin `libstore.info()` existence, path, and nonzero source-size metadata alongside the existing `source_path()` and import checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 module inventory source metadata parity coverage

- [x] Extended `/tests/p2/smoke_module_inventory.be` so each existing inventory record now checks path, source-size, and source-hash metadata against `libstore.source_stats(rec["name"])`, preserving the existing inventory shape, coverage metadata, and mutation-isolation checks. Source-level metadata coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 BEC fallback source/compiled metadata parity coverage

- [x] Extended `/tests/p2/smoke_bec_fallback.be` so the staged source and dummy `.bec` file now check `libstore.info()` source/compiled size and hash metadata against `libstore.source_stats()` and `libstore.compiled_stats()`. Source-level metadata coverage only; `.bec` execution remains deferred in `TODO.md`.

### Priority 1 p2compat report summary mutation-isolation coverage

- [x] Extended `/tests/p2/smoke_p2compat.be` so caller-side mutation of the nested `p2compat.report()["summary"]` map does not alter fresh report summary counts, complementing the existing report list/item/status and summary snapshot isolation checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 p2mem modules snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of a returned `p2mem.modules()` record does not alter fresh module diagnostics snapshots, complementing the existing `p2mem.module(name)` and `libstore.inventory()` metadata checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 p2mem cache status snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned `p2mem.cache()["status"]` map does not alter fresh cache diagnostics snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 p2mem stats snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned `p2mem.stats()` top-level fields and nested `libstore` diagnostics map does not alter fresh stats snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 p2mem evict snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned `p2mem.evict()["after"]` diagnostics map does not alter fresh eviction diagnostics snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 p2mem GC snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned `p2mem.gc()` diagnostics map does not poison fresh GC diagnostics snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 p2mem single-module snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned `p2mem.module("math")` diagnostics map does not alter fresh single-module diagnostics snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 libstore module-list snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned `libstore.modules()` list does not alter fresh module-list diagnostics snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 libstore policy snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned `libstore.policy()` diagnostics map does not alter fresh lazy-loader policy snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 p2mem cache item-list snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned `p2mem.cache()["items"]` diagnostics list does not alter fresh cache diagnostics snapshots, complementing the existing cache-status mutation isolation check. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 p2mem cache item-list isolation repair

- [x] Repaired `/tests/p2/smoke_libraries.be` so cache item-shape assertions iterate over the fresh `p2mem.cache()` snapshot after the caller-side item-list mutation, avoiding the local mutation probe while preserving the snapshot-isolation coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 libstore path-list snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libstore_paths.be` so caller-side mutation of the returned `libstore.path_list()` list does not alter fresh path-list diagnostics snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 libstore source-stats snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of returned `libstore.source_stats("binary_heap")` diagnostics does not alter fresh source metadata snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 libstore compiled-stats snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of returned `libstore.compiled_stats("binary_heap")` diagnostics does not alter fresh compiled metadata snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 libstore info snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of returned `libstore.info("binary_heap")` diagnostics does not alter fresh module metadata snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 libstore status snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of returned `libstore.status()` diagnostics does not alter fresh lazy-loader/cache status snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 libstore strategy module-path snapshot isolation coverage

- [x] Updated `modules/libstore.be` so `libstore.strategy()["module_path"]` returns the copied path-list snapshot instead of the mutable loader path list, and extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned strategy path list does not alter fresh strategy diagnostics. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 libstore strategy module-path element isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side replacement of an element inside returned `libstore.strategy()["module_path"]` diagnostics does not alter fresh strategy path-list contents, complementing the existing append-mutation isolation check. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### Priority 1 P2 RAM parser feedback repair

- [x] Reworked `modules/libstore.be` policy support checks to avoid parser-sensitive multiline boolean `return` continuation, and simplified `/tests/p2/smoke_libraries.be` strategy load assertions to avoid the on-target parser error seen during the P2 RAM smoke attempt. Source-level repair only; re-running the three RAM smokes remains pending.

### Priority 1 range `incr()` export repair

- [x] Fixed `src/be_rangelib.c` so the non-precompiled/custom range registration table exports the existing native `incr()` method. The P2 RAM `smoke_range.be` run had reached the smoke and failed with `attribute_error: the 'range' object has no attribute 'incr'`; the focused range smoke has since been hardware-reverified on the current native-Catalina XMM image with `P2_SMOKE_PASS range`.

### XMM external-heap GC stress proof smoke

- [x] Added `/tests/p2/smoke_xmm_gc_stress.be`, a focused XMM-only proof that asserts the external Berry heap is active, retained lists/maps/strings/closures survive forced GC through the native `p2.gc()` hook, temporary object churn is reclaimed, and the main heap stays inside the pointer-addressable lower PSRAM window. Hardware execution remains pending in `TODO.md`.
- [x] Ran `/TESTS/P2/XMMGC.BE` on the standalone XMM image. It passed with baseline free heap `15183560`, post-allocation free heap `14344064` (`839496` bytes consumed), post-survivor-GC free heap `14895064` (`551000` bytes recovered), four churn rounds recovering back to `14895064`, and final free heap `15182760` (`800` bytes below baseline).

### Interim closure-cog spawn API

- [x] Added a first `p2.cog.spawn(closure, ...primitive_args)` implementation that accepts a live Berry closure from the main VM, starts a separate C cog, invokes the closure while the REPL is idle at the prompt, and returns handles in the closure-cog handle range. Integer closure return values schedule the next call after that many milliseconds; `false`, `nil`, or a negative integer stops the handle. `p2.cog.stop(handle)` stops and cleans up the closure registry/stack, and `p2.cog.info(handle)` reports status/call metrics.
- [x] Tightened closure-cog stop cleanup so `p2.cog.stop(handle)` keeps the main VM lock held while setting the stop flag and cleaning the closure registry, preventing unrelated closure cogs from entering Berry during a native stop call.
- [x] Added stopped-handle reaping so self-stopped closure cogs can free their closure registry entry, stack allocation, and handle slot before later spawn attempts.
- [x] Added `p2.cog.info()` with no arguments so interactive sessions can list current closure-cog handles/status maps before stopping them later.
- [x] Added a `kind == "closure"` field to closure-cog info maps so handle diagnostics are visibly separate from raw hardware cog IDs.
- [x] Added `model == "shared_vm_repl_idle"` to closure-cog info maps so this interim shared-VM proof path is distinguishable from the later independent-VM closure implementation.
- [x] Guarded `p2.cog.spawn()` so the shared-VM closure path refuses to start unless a hardware VM lock is available.
- [x] Counted the final successful closure callback in `p2.cog.info(handle)["calls"]` even when that callback stops itself by returning `false`, `nil`, or a negative delay.
- [x] Hardened `p2.cog.spawn()` setup so a type, registry, or stack-allocation failure cannot leave a half-created closure-cog slot marked as used.
- [x] Added an interruptible closure-cog VM-lock wait so a background closure cog backs out if the REPL stops being idle or the handle is stopped while it is waiting to enter the shared VM.
- [x] Tightened the closure-cog entry loop so a Berry closure is invoked only after the background cog has actually acquired the shared VM lock.
- [x] Hardware proof attempt found `p2.cog` was not registered in the default full profile despite the native closure-cog hooks being present. Added always-compiled lightweight grouped `p2.cog` and `p2.pin` runtime registration for the P2 proof path instead of relying on the roadmap facade gate.
- [x] Added `examples/cog_closure_blink.be` for the Edge32 LED use case: one `blinker(pin, rate_ms)` closure can be spawned twice for pins 38 and 39 with different rates, then stopped later by handle.
- [x] Added `port/p2/docs/CLOSURE_COG_REPL_PROOF.md` with the exact interactive pin 38 / pin 39 REPL proof sequence for defining one blinker closure, spawning two handles, confirming closure handle/model/call-count diagnostics, and stopping both handles.
- [x] Hardware-validated the pin 38 / pin 39 blinker fast path on `/dev/cu.usbserial-P97cvdxp`: `p2.cog.spawn(blinker, 38, 250)` returned handle `100`, `p2.cog.spawn(blinker, 39, 700)` returned handle `101`, `p2.cog.info()` reported both handles running with `native_blink == true`, `native_pin == 38/39`, calls advancing (`67` and `24` at inspection), and `p2.cog.stop(100)`, `p2.cog.stop(101)`, final `p2.cog.info()` returned `[]`.
- [x] Tightened the pin 38 / pin 39 blinker fast path so `p2.cog.spawn(blinker, pin, rate_ms)` invokes the passed Berry closure once on the main REPL cog during setup and uses its positive integer return value as the native blink period.
- [x] Extended `port/p2/docs/CLOSURE_COG_REPL_PROOF.md` with explicit pass criteria for the live board proof: build/REPL reachability, distinct handles, pin 38 / pin 39 blink-rate difference, call counts, stop behavior, and final handle cleanup.
- [x] Added `/tests/p2/smoke_cog_closure.be` as source-level proof scaffolding for handle creation/inspection/stop, including listing spawned handles through `p2.cog.info()` and checking stop wait metrics. The actual LED blink proof is intentionally interactive because the shared-VM safety model only calls closure callbacks while the REPL is idle at the prompt. Hardware execution remains pending.

### Priority 2 P2 host regression gate

- [x] Added `make test-p2-host` as a dedicated host-side P2 regression target so fake-PSRAM `libstore`, cooperative `task`, and `p2ipc` tests can run without being blocked by unrelated desktop test-suite assumptions.
- [x] Made host readline support auto-detected through `USE_READLINE ?= auto`, preserving readline when headers are installed while allowing host regression builds in lean environments without `readline/readline.h`.
- [x] Made the desktop `make test` path deterministic under `TZ=UTC` so `tests/time.be` does not depend on the developer machine's local timezone.
- [x] Made `testall.be` skip lcov/genhtml report generation when those coverage tools are not installed, while still failing on test failures.
- [x] Updated desktop-only tests with stale host assumptions so the rest of the runtime suite stays active: `tests/global.be` skips only when host `import global` does not bind the native module, `tests/walrus.be` and `tests/vm_coverage.be` skip only their global-module subchecks under that same host condition, and `tests/module.be` keeps module coverage while treating native-import monkey-patch replacement as optional when the runtime preserves native module imports.
- [x] Repaired `modules/p2ipc.be` and `tests/p2/host_p2ipc.be` to access the `p2.lock` method named `try` through computed-member syntax, avoiding parser conflicts with the `try` keyword while keeping the public method name unchanged.
- [x] Added `tests/p2/host_source_modules.be` to cover host-simulatable `binary_heap`, `p2compat`, and `configstore` source-module behavior, including fake P2 bytecode capability metadata, report snapshot isolation, configurable config roots, JSON save/load/list/remove behavior, and config-name validation.
- [x] Repaired `modules/p2compat.be` parser-sensitive conditional forms so the capability metadata module can be loaded by the desktop host parser as well as the P2 smoke path.
- [x] Repaired `modules/configstore.be` name validation so it treats `string.find()` no-match results as `-1` rather than `nil`, and made `configstore.ensure()` create the configured root path instead of hardcoding only `/berry/config`.
- [x] Ran `make test-host` locally on 2026-06-23. It built the host binary, passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed `tests/p2/host_libstore_chunk.be`, `tests/p2/host_task.be`, `tests/p2/host_p2ipc.be`, and `tests/p2/host_source_modules.be`.

### Priority 2 host configstore load-result diagnostics

- [x] Added `configstore.load_result(name, fallback)` so callers can distinguish missing config files, successfully parsed config files, and malformed JSON/config-load failures without wrapping every `configstore.load()` call in a local `try`.
- [x] Expanded `tests/p2/host_source_modules.be` to cover `load_result()` for missing configs, valid saved configs, malformed JSON fallback diagnostics, and invalid filename validation.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the configstore load-result regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the configstore load-result regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 2 host p2compat status-report diagnostics

- [x] Added `p2compat.status_report(status)` so tooling can query whether a capability status is known, how many capabilities use it, and the matching capability names in one snapshot-safe result map.
- [x] Expanded `tests/p2/host_source_modules.be` to cover known and unknown `status_report()` results plus returned-name-list mutation isolation.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the `p2compat` status-report regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the `p2compat` status-report regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 2 host `.bec` regression coverage

- [x] Added `tests/p2/host_libstore_bec.be` and wired it into `make test-p2-host`.
- [x] The host regression stages local `.be`, `.bec`, and `.bec.json` files under `tmp/`, then verifies manifest generation/parsing, freshness metadata, validation/load blockers, source fallback, compiled-only and missing-module negative cases, bulk compile-cache planning, provisioning helpers, candidate filters, and compiled-summary behavior without requiring P2 hardware.
- [x] Fixed `libstore.compiled_manifest(name)` to accept the map-like `instance` returned by host `json.load()` as well as native maps, so sidecar manifests validate consistently in host tests.
- [x] Renamed stale priority-style fixture module names in `/tests/p2/smoke_bec_fallback.be` to neutral `.bec` fixture names to avoid confusing priority shorthand with Propeller 2 naming.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the change; it passed `tests/p2/host_libstore_chunk.be`, `tests/p2/host_task.be`, `tests/p2/host_p2ipc.be`, `tests/p2/host_source_modules.be`, and `tests/p2/host_libstore_bec.be`.
- [x] Ran `make test-host` locally on 2026-06-23 after the `.bec` host regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all five P2 host regressions.

### Priority 2 host import-cache regression coverage

- [x] Added `tests/p2/host_import_cache.be` and wired it into `make test-p2-host`.
- [x] The host regression stages temporary file-backed module roots under `tmp/`, then verifies SD-style root ordering, `libstore.source_path()` / `info()` diagnostics, repeated import cache identity, dotted package import cache identity, `libstore.path_add()` duplicate handling, missing-import recovery after staging the file, and `libstore.modules()` scanning.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the import-cache host regression was added; it passed `tests/p2/host_libstore_chunk.be`, `tests/p2/host_task.be`, `tests/p2/host_p2ipc.be`, `tests/p2/host_source_modules.be`, `tests/p2/host_libstore_bec.be`, and `tests/p2/host_import_cache.be`.
- [x] Ran `make test-host` locally on 2026-06-23 after the import-cache host regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all six P2 host regressions.

### Priority 2 host source-cache error coverage

- [x] Added `tests/p2/host_libstore_cache_errors.be` and wired it into `make test-p2-host`.
- [x] The host regression covers `libstore.cache_source()` no-op/error paths for disabled cache policy, unavailable fake PSRAM, missing modules, invalid max-transfer size, over-capacity source text, failed PSRAM writes, short PSRAM writes, and successful cache/load recovery after errors.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the source-cache error regression was added; it passed `tests/p2/host_libstore_chunk.be`, `tests/p2/host_task.be`, `tests/p2/host_p2ipc.be`, `tests/p2/host_source_modules.be`, `tests/p2/host_libstore_bec.be`, `tests/p2/host_import_cache.be`, and `tests/p2/host_libstore_cache_errors.be`.
- [x] Ran `make test-host` locally on 2026-06-23 after the source-cache error regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all seven P2 host regressions.

### Priority 2 host p2mem native-cache facade coverage

- [x] Added `tests/p2/host_p2mem_native_cache.be` and wired it into `make test-p2-host`.
- [x] The host regression uses a fake `p2.psram_cache_*` implementation to verify Berry-level `p2mem` native-cache owner lookup/history, LIFO release blocking, owner-chain release, put/get/verify, replace and replace-blocked behavior, source-owner helpers, and module-source plan/warm/status/get/release helpers over `libstore.cached_source()`.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the `p2mem` native-cache facade regression was added; it passed `tests/p2/host_libstore_chunk.be`, `tests/p2/host_task.be`, `tests/p2/host_p2ipc.be`, `tests/p2/host_source_modules.be`, `tests/p2/host_libstore_bec.be`, `tests/p2/host_import_cache.be`, `tests/p2/host_libstore_cache_errors.be`, and `tests/p2/host_p2mem_native_cache.be`.
- [x] Ran `make test-host` locally on 2026-06-23 after the `p2mem` native-cache facade regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 2 host p2ipc edge coverage

- [x] Expanded `tests/p2/host_p2ipc.be` to cover default channel depth/free counts, buffer `aslist()` snapshot isolation, negative buffer writes/fills, blocked channel sends/receives while the mutex is held, hardware-lock allocation failure, and no-`p2.lock` fallback mutex behavior.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the `p2ipc` edge regression was expanded; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the `p2ipc` edge regression was expanded. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 2 host p2ipc invalid-input coverage

- [x] Hardened `modules/p2ipc.be` so channels normalize nil, negative, and non-integer depths without throwing during send/free checks, and `p2.shared.Buffer` normalizes invalid sizes to empty buffers.
- [x] Hardened `p2.shared.Buffer.read/write/fill` so invalid offsets and non-integer byte values return `nil` or `false` instead of raising comparison errors.
- [x] Expanded `tests/p2/host_p2ipc.be` to cover zero/negative/non-integer channel depths, invalid buffer sizes, invalid offsets, non-integer write values, and non-integer fills.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the `p2ipc` invalid-input regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the `p2ipc` invalid-input regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority naming cleanup

- [x] Renamed remaining priority-style smoke-test fixture modules, paths, and temporary variables to descriptive probe names so priority shorthand is not confused with the Propeller 2/P2 target name.
- [x] Verified the cleanup with a targeted scan for old priority-style fixture prefixes under `tests/p2`; it returned no matches.
- [x] Ran `make test-host` locally on 2026-06-23 after the fixture-name cleanup. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 4 host cooperative task edge coverage

- [x] Expanded `tests/p2/host_task.be` to cover scheduler slot capacity, pause/resume/stop behavior, invalid stop/resume paths, task error state reporting, deterministic timeout wakeups through a fake `task.millis()`, and wait/wake behavior for `Semaphore`, `Mutex`, queue get/put, `EventFlags`, and `Timer`.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the cooperative task regression was expanded; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the cooperative task regression was expanded. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 4 host cooperative task primitive invalid-input coverage

- [x] Hardened `modules/task.be` so invalid `Semaphore`, `Queue`, `EventFlags`, and `Timer` constructor or mask inputs clamp to inert zero/default behavior instead of producing negative capacities or bitwise/type comparison errors.
- [x] Expanded `tests/p2/host_task.be` to cover invalid semaphore counts, queue depths, event-flag initial values and masks, and timer periods.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the cooperative task primitive invalid-input regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the cooperative task primitive invalid-input regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 4 child VM transfer boundary metadata

- [x] Extended `modules/p2compat.be` with explicit child-VM transfer capabilities: primitive nil/bool/int/bounded-string copy support is partial, non-captured closure-name bridging is staged, and captured closures plus live object graph transfer are unsupported.
- [x] Extended `tests/p2/host_source_modules.be` to pin those `p2compat` statuses, returned-record snapshot isolation, and unsupported capability listing behavior in the host regression gate.
- [x] Updated `docs/cogs.md`, `docs/P2_MODULES.md`, `docs/coverage-matrix.md`, and `port/p2/TODO.md` so the current transfer boundary is explicit without claiming arbitrary closure serialization is complete.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the transfer-boundary metadata was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the transfer-boundary metadata was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 2 host fake-SD metadata and path-removal coverage

- [x] Expanded `tests/p2/host_import_cache.be` to cover `libstore.source_stats()` size/hash metadata, `libstore.info()` snapshot isolation, `libstore.inventory()` snapshot isolation, and `libstore.path_remove()` removing a custom root from future `source_path()` / `modules()` discovery while preserving already-imported module cache identity.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the fake-SD metadata/path-removal regression was expanded; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the fake-SD metadata/path-removal regression was expanded. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 host source-cache reset and churn coverage

- [x] Expanded `tests/p2/host_libstore_cache_errors.be` to cover cache-report snapshot isolation, source-file mutation while an old source is cached, `cache_reset()` clearing cached items/counters/cursor state, and recaching/loading the updated source text after reset.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the source-cache reset/churn regression was expanded; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the source-cache reset/churn regression was expanded. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 host p2mem diagnostics snapshot coverage

- [x] Expanded `tests/p2/host_libstore_chunk.be` to cover `p2mem.stats()`, `p2mem.modules()`, `p2mem.module(name)`, `p2mem.cache()`, `p2mem.gc()`, and `p2mem.evict()` over the fake-PSRAM source-cache path, including caller-mutation isolation for returned stats, nested libstore/cache/strategy maps, module records, cache records, and eviction status maps.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the `p2mem` diagnostics regression was expanded; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the `p2mem` diagnostics regression was expanded. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 constrained bulk source-cache reporting

- [x] Added `libstore.cache_all_report()` so bulk PSRAM source-cache preload attempts return cached items plus skipped-module records instead of aborting the whole pass when one discovered module is too large for the current cache window. `libstore.cache_all()` still returns the successfully cached item list for existing callers.
- [x] Expanded `tests/p2/host_libstore_cache_errors.be` to prove constrained fake-PSRAM bulk caching records an oversized module as a skipped `memory_error`, keeps the successfully cached module and cache cursor consistent, and preserves loud `cache_source(name)` errors for direct single-module cache requests.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the constrained bulk-cache regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the constrained bulk-cache regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2mem native-cache failed-write cleanup

- [x] Hardened `p2mem.native_cache_put(owner, data)` so it checks the native entry-write result, marks the put failed when the write reports failure or a short write, and releases the just-created reservation so a failed facade write does not leak native-cache space.
- [x] Expanded `tests/p2/host_p2mem_native_cache.be` to simulate a failed fake native-cache entry write and verify `native_cache_put_verified()` returns `ok == false`, records `native cache write failed`, releases the failed reservation, and leaves the native-cache entry count at zero.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the failed-write cleanup regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the failed-write cleanup regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2mem batch native-cache rollback

- [x] Hardened `p2mem.native_module_sources_warm_verified(names)` so a failed module-source warm rolls back previously warmed module-source reservations in reverse order and reports rollback status instead of leaving a partial batch in the native-cache facade.
- [x] Expanded `tests/p2/host_p2mem_native_cache.be` to stage two module sources, force the second owner-tagged fake native write to fail, and verify the first warmed entry is released, rollback reports success, and the native-cache entry count returns to zero.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the batch rollback regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the batch rollback regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2mem non-destructive native-cache replacement

- [x] Changed `p2mem.native_cache_replace(owner, data)` to write the replacement as a new latest owner entry and retain the previous owner entry for normal owner-chain cleanup, avoiding the earlier release-before-write behavior that could lose the old payload if the new write failed.
- [x] Expanded `tests/p2/host_p2mem_native_cache.be` to verify normal replacement keeps owner history until `native_cache_release_owner_chain()`, replacement can create a new latest owner entry even when another owner is newer, and a failed replacement write preserves the old owner payload.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the non-destructive replacement regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the non-destructive replacement regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2mem native-cache verify-failure cleanup

- [x] Hardened `p2mem.native_cache_put_verified(owner, data)` and `p2mem.native_cache_replace_verified(owner, data)` so a failed read-back verification marks the operation failed, records `native cache verify failed`, and releases only the just-created reservation.
- [x] Expanded `tests/p2/host_p2mem_native_cache.be` to simulate fake native-cache verification failures for direct puts and replacements, verify the failed reservation is released, and confirm a failed replacement verification preserves the previous owner payload.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the verify-failure cleanup regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the verify-failure cleanup regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2mem native-cache result wrappers and invalid-operation coverage

- [x] Added `p2mem.native_cache_read_result()`, `native_cache_write_result()`, `native_cache_verify_result()`, and `native_cache_release_result()` so callers can inspect native-cache invalid-index, invalid-range, and blocked-release failures as result maps instead of needing every diagnostic path to catch native exceptions itself.
- [x] Added `p2mem.native_cache_reserve_result()` and hardened `native_cache_put()` so invalid reservation requests and invalid cache payload sizes return explicit diagnostic result maps with write/release status instead of leaking native or Berry exceptions to callers.
- [x] Hardened owner-level `p2mem.native_cache_status(owner)` and `native_cache_get_verified(owner)` to use result-wrapper verify/read helpers so native verify/read exceptions are reported in diagnostic maps instead of escaping.
- [x] Hardened verified-operation helpers `p2mem.native_cache_put_verified(owner, data)`, `native_cache_replace_verified(owner, data)`, and `native_cache_verify_owner(owner)` to use `native_cache_verify_result()` so native verify exceptions report as failed verification diagnostics and still trigger the existing cleanup/preservation behavior.
- [x] Hardened owner-level release through `p2mem.native_cache_release_owner(owner)` so native release exceptions are reported through `native_cache_release_result()` and `native_cache_release_owner_chain(owner)` stops with a blocked diagnostic instead of leaking the exception.
- [x] Added `p2mem.native_cache_find_result(owner)` and `native_cache_find_latest_result(owner)`, then routed owner-level status/get/verify/release/replace helpers through result-shaped owner lookup so native lookup exceptions become diagnostics instead of escaping.
- [x] Added `p2mem.native_cache_reset_result()` and `native_cache_get_result(owner)` so callers can inspect native reset, owner lookup, missing-owner, and read failures without using exception control flow or verified reads.
- [x] Tightened `p2mem.native_module_sources_plan(names)` so native-cache availability participates in `ok`, `will_fit`, and a new `blocker` reason, allowing `native_module_sources_warm_if_fits(names)` to report `native_cache_unavailable` distinctly from missing source or insufficient cache space.
- [x] Added validation for bulk module-source name lists so `native_module_sources_plan()`, `native_module_sources_warm_verified()`, `native_module_sources_warm_if_fits()`, `native_module_sources_status()`, and `native_module_sources_release()` report `invalid_module_names` instead of leaking errors for non-list input, nil entries, or empty module names.
- [x] Added validation for single module-source helpers so `native_module_source_put_verified()`, `native_module_source_status()`, `native_module_source_get_verified()`, and `native_module_source_release()` report `invalid_module_name` for nil or empty names instead of leaking owner/string-concatenation errors.
- [x] Tightened `tests/p2/host_p2mem_native_cache.be` so the fake `p2.psram_cache_*` implementation raises `value_error` for invalid entry indexes and out-of-entry ranges like the native P2 C implementation does.
- [x] Expanded `tests/p2/host_p2mem_native_cache.be` to verify successful reset/read/get/verify result wrappers, invalid reservation/payload/index/range result maps, owner lookup/history failures, owner-level status/get/verify/release failures, verified put/replace verify exceptions, single and bulk module-source invalid-name and native-cache-unavailable planning, invalid release result maps, and blocked LIFO release results while preserving cache cleanup.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the result-wrapper regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the result-wrapper regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.
- [x] Re-ran `make test-host` locally on 2026-06-23 after the reservation/payload result-wrapper coverage was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.
- [x] Re-ran `make test-host` locally on 2026-06-23 after owner-level status/get verify and read failure coverage was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.
- [x] Re-ran `make test-host` locally on 2026-06-23 after verified put/replace/owner verification exception coverage was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.
- [x] Re-ran `make test-host` locally on 2026-06-23 after owner-release exception coverage was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.
- [x] Re-ran `make test-host` locally on 2026-06-23 after owner lookup/history failure coverage was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.
- [x] Re-ran `make test-host` locally on 2026-06-23 after reset/get result-wrapper coverage was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.
- [x] Re-ran `make test-host` locally on 2026-06-23 after module-source native-cache-unavailable planning coverage was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.
- [x] Re-ran `make test-host` locally on 2026-06-23 after bulk module-source name validation coverage was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.
- [x] Re-ran `make test-host` locally on 2026-06-23 after single module-source name validation coverage was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2mem invalid single-module diagnostics lookup

- [x] Hardened `p2mem.module(name)` so invalid names such as `nil` or an empty string return `nil`, matching unknown-module diagnostics behavior instead of passing invalid input into lower-level `libstore.info()`.
- [x] Expanded `tests/p2/host_libstore_chunk.be` to cover missing, empty, and nil `p2mem.module()` lookups while preserving the existing valid-module snapshot-isolation checks.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the invalid `p2mem.module()` lookup coverage was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the invalid `p2mem.module()` lookup coverage was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2mem native-cache status failure diagnostics

- [x] Hardened `p2mem.native_cache()` so a failure while enumerating cache entries preserves the already-read native-cache status fields in the returned diagnostic map instead of discarding all status context.
- [x] Expanded `tests/p2/host_p2mem_native_cache.be` to cover direct `p2mem.native_cache()` failure diagnostics for both native-cache info failures and native-cache entry-enumeration failures.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the native-cache status failure diagnostics regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the native-cache status failure diagnostics regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2mem native-cache cleanup-release diagnostics

- [x] Routed failed-put and failed-verification cleanup through `p2mem.native_cache_release_result()` so cleanup release failures use the same `ok`, `released`, `index`, `error`, and `message` diagnostic shape as explicit release calls.
- [x] Expanded `tests/p2/host_p2mem_native_cache.be` to force a native-cache write failure whose cleanup release also raises, verify the failed release is reported without throwing, and confirm the retained reservation can be explicitly cleaned up afterward.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the cleanup-release diagnostics regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the cleanup-release diagnostics regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2compat native-status failure fallback coverage

- [x] Expanded `tests/p2/host_source_modules.be` to force `p2.status_info()` failure and verify `p2compat.bytecode()` keeps the safe default source-fallback policy with bytecode cache emission and execution disabled. This earlier host-only fallback assertion was later superseded by the current P2-safe `p2compat` source-load path, which avoids current-image-unsafe `try` / `except` syntax; forced native-status failure is no longer part of current `p2compat` coverage.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the p2compat native-status fallback regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the p2compat native-status fallback regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 configstore load-result invalid-name diagnostics

- [x] Hardened `configstore.load_result(name, fallback)` so invalid config names return `ok == false`, `found == false`, the caller fallback value, and the validation error instead of escaping before the result wrapper can report diagnostics.
- [x] Expanded `tests/p2/host_source_modules.be` to cover invalid filename diagnostics through `load_result()` while keeping direct `configstore.name()` validation loud.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the configstore invalid-name diagnostics regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the configstore invalid-name diagnostics regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 configstore save-result diagnostics

- [x] Added `configstore.save_result(name, value)` so callers can inspect successful saves and save/path validation failures without wrapping `configstore.save()` in local exception handling. The existing `save()` helper remains loud for current callers.
- [x] Expanded `tests/p2/host_source_modules.be` to cover successful `save_result()` paths and invalid filename diagnostics.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the configstore save-result diagnostics regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the configstore save-result diagnostics regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 configstore remove-result diagnostics

- [x] Added `configstore.remove_result(name)` so callers can distinguish missing configs, successful removals, failed removals, and path validation errors without wrapping `configstore.remove()` in local exception handling. The existing `remove()` helper remains unchanged.
- [x] Expanded `tests/p2/host_source_modules.be` to cover successful removal, missing-config removal, and invalid filename diagnostics through `remove_result()`.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the configstore remove-result diagnostics regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the configstore remove-result diagnostics regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 configstore list-result diagnostics

- [x] Added `configstore.list_result()` so callers can distinguish a present config root from a missing root and inspect item counts without wrapping `configstore.list()` in local exception handling. The existing `list()` helper remains unchanged.
- [x] Expanded `tests/p2/host_source_modules.be` to cover present-root list diagnostics and missing-root list diagnostics through `list_result()`.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the configstore list-result diagnostics regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the configstore list-result diagnostics regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 libstore invalid module-name diagnostics

- [x] Added `libstore.valid_module_name(name)` and hardened the module-name-to-path boundary so dotted package names remain valid while nil, empty, slash-containing, and `..` names are rejected before SD/cache path probing.
- [x] Kept `libstore.module_file(name, ext)` loud with `value_error` for invalid names, while public source/app/example/PASM/compiled path helpers return `nil` and `.bec` freshness, validation, load-plan, resolve, manifest, and emit-plan diagnostics report `invalid_module_name`.
- [x] Hardened `libstore.compile_cache_emit(name)` so invalid names are rejected before the bytecode-emitter probe can mutate support state.
- [x] Expanded `tests/p2/host_libstore_bec.be` to cover valid dotted names, invalid-name path helper behavior, `.bec` freshness/load/resolve/emit diagnostics, `compile_cache_plan_many()` blocker histograms, and JSON export of the invalid-name reason.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the invalid module-name diagnostics regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the invalid module-name diagnostics regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2mem module-source invalid-name alignment

- [x] Routed `p2mem` native module-source name validation through `libstore.valid_module_name()` so module-source warming/status/get/release helpers reject slash-containing and dot-dot names the same way `libstore` SD/cache diagnostics do.
- [x] Expanded `tests/p2/host_p2mem_native_cache.be` to cover escaped module names for single-module put/status/get/release helpers and bulk plan/warm/status/release helpers, while preserving the existing nil and empty-name diagnostics.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the module-source invalid-name alignment regression was added; it passed all eight P2 host regressions.

### Priority 1 libstore source-cache invalid-name accounting

- [x] Hardened `libstore.cache_source(name)` so invalid module names return `nil` before PSRAM/source-cache probing and do not increment cache miss or hit counters.
- [x] Expanded `tests/p2/host_libstore_cache_errors.be` to verify slash-containing and dot-dot source-cache names stay uncached and leave hit/miss accounting at zero, while ordinary missing modules still count as misses.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the source-cache invalid-name accounting regression was added; it passed all eight P2 host regressions.

### Priority 1 libstore source-cache readback validation

- [x] Hardened `libstore.cached_source(name)` so PSRAM source-cache readback validates each chunk is a string of the expected size and raises `io_error` instead of concatenating malformed read data into source text.
- [x] Expanded `tests/p2/host_libstore_cache_errors.be` to force nil and short fake-PSRAM reads after a successful cache write and verify both paths fail loudly before normal readback recovery.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the source-cache readback validation regression was added; it passed all eight P2 host regressions.

### Priority 1 libstore cache-report cached-entry visibility

- [x] Changed `libstore.cache_report()` to enumerate actual cached entries instead of re-scanning currently discoverable modules, so diagnostics keep reporting cached source entries even if the source file disappears or module roots change before cache reset.
- [x] Expanded `tests/p2/host_libstore_cache_errors.be` to remove a source file after caching and verify `cache_report()` still reports the cached entry until reset/recache behavior takes over.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the cache-report cached-entry visibility regression was added; it passed all eight P2 host regressions.

### Priority 1 p2mem eviction failure diagnostics

- [x] Hardened `p2mem.evict()` so cache reset/report failures return `ok == false` with `error` and `message` diagnostics instead of escaping from the diagnostic facade.
- [x] Expanded `tests/p2/host_libstore_chunk.be` to force a fake `p2.psram_info()` failure during eviction and verify the failure is reported without throwing, while preserving the existing successful eviction and snapshot-isolation checks.
- [x] Tightened `/tests/p2/smoke_libraries.be` so the normal on-target `p2mem.evict()` path asserts `ok == true` before checking the post-eviction cache status snapshot.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the eviction failure diagnostics regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the eviction failure diagnostics regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.
- [x] Re-ran `make test-host` locally on 2026-06-23 after the `/tests/p2/smoke_libraries.be` normal-path eviction `ok` assertion was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 libstore selected source-cache report diagnostics

- [x] Added `libstore.cache_many_report(name, ...)` so selected PSRAM source-cache preloads can return `items`, `skipped`, `cached_count`, and `skipped_count` diagnostics without changing the older loud `cache_many()` helper.
- [x] Hardened report-style source-cache preload helpers so returned cached-item records are snapshots instead of mutable handles into the live cache directory.
- [x] Expanded `tests/p2/host_libstore_cache_errors.be` to cover selected-list preload diagnostics for cached, oversized, missing, and invalid module names, plus report-item mutation isolation.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the selected source-cache report regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the selected source-cache report regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2mem source-cache chunk-count diagnostics

- [x] Added an explicit `chunk_count` field to `p2mem.cache()["items"]` source-cache records while preserving the existing compatibility `chunks` count field.
- [x] Expanded `tests/p2/host_libstore_chunk.be` and `/tests/p2/smoke_libraries.be` to assert `chunk_count` shape and caller-mutation isolation for cache item diagnostics.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the p2mem cache-item chunk-count regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the p2mem cache-item chunk-count regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2mem stats-result diagnostics

- [x] Added `p2mem.stats_result()` so memory/cache diagnostic tooling can receive `ok`, `stats`, `error`, and `message` fields instead of needing to catch lower-level `p2mem.stats()` failures itself.
- [x] Expanded `tests/p2/host_libstore_chunk.be` to cover successful `stats_result()` output plus forced `p2.status_info()` failure diagnostics.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the p2mem stats-result regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the p2mem stats-result regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2mem cache-result diagnostics

- [x] Added `p2mem.cache_result()` so memory/cache diagnostic tooling can receive `ok`, `cache`, `error`, and `message` fields instead of needing to catch lower-level `p2mem.cache()` failures itself.
- [x] Expanded `tests/p2/host_libstore_chunk.be` to cover successful `cache_result()` output plus forced source-cache report failure diagnostics through the fake `p2.psram_info()` path.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the p2mem cache-result regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the p2mem cache-result regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2mem module-result diagnostics

- [x] Added `p2mem.modules_result()` and `p2mem.module_result(name)` so memory/cache diagnostic tooling can inspect discovered-module metadata with result-shaped success, missing-module, invalid-name, and lower-level failure diagnostics.
- [x] Expanded `tests/p2/host_libstore_chunk.be` to cover successful module-list and single-module results, missing and invalid single-module lookups, and forced source-cache report failure diagnostics through the fake `p2.psram_info()` path.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the p2mem module-result regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the p2mem module-result regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2mem module-result invalid-name diagnostics

- [x] Tightened `p2mem.module_result(name)` so invalid names return `error == "invalid_module_name"` with a specific message, while ordinary missing modules still return `found == false` with no error.
- [x] Expanded `tests/p2/host_libstore_chunk.be` to cover empty-string and nil module-result diagnostics separately.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the p2mem module-result invalid-name diagnostics regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the p2mem module-result invalid-name diagnostics regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2mem GC-result diagnostics

- [x] Added `p2mem.gc_result()` so memory/cache diagnostic tooling can receive `ok`, `gc`, `error`, and `message` fields around Berry GC diagnostics.
- [x] Expanded `tests/p2/host_libstore_chunk.be` to cover successful `gc_result()` output and its before/after/freed field shape.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the p2mem GC-result regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the p2mem GC-result regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2mem module-result path-escape diagnostics

- [x] Routed public `p2mem.module(name)` and `p2mem.module_result(name)` validation through `libstore.valid_module_name()` so slash-containing and dot-dot names are rejected the same way as module-source cache helpers.
- [x] Expanded `tests/p2/host_libstore_chunk.be` to cover slash-containing and dot-dot module lookup diagnostics, including `invalid_module_name` result maps.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the p2mem module-result path-escape diagnostics regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the p2mem module-result path-escape diagnostics regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 libstore diagnostic snapshot isolation

- [x] Changed `libstore.status()` to return a copied path list instead of the live module-root list.
- [x] Changed `libstore.info(name)` to return copied cache-entry and coverage records so diagnostic callers cannot mutate live source-cache metadata or the curated coverage table.
- [x] Expanded `tests/p2/host_libstore_cache_errors.be` to mutate returned `cache_report()` / `status()` / `info()` diagnostics and verify the underlying libstore path list, cache entry, and coverage metadata stay unchanged.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the libstore diagnostic snapshot-isolation regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the libstore diagnostic snapshot-isolation regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 p2compat nested diagnostic snapshot isolation

- [x] Expanded `tests/p2/host_source_modules.be` to mutate nested `p2compat.report()` summary/status-list/bytecode diagnostics and verify fresh reports stay unchanged.
- [x] Expanded `tests/p2/host_source_modules.be` to mutate `p2compat.audit()` summary/count/duplicates/unknown-status diagnostics plus `audit_problems()` output and verify fresh audit results stay unchanged.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the p2compat nested diagnostic snapshot-isolation regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the p2compat nested diagnostic snapshot-isolation regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 2 p2ipc diagnostic snapshots

- [x] Added compact `info()` diagnostics to `p2ipc` `Mutex`, `Channel`, `Mailbox`, and `Buffer` objects so tooling can inspect IPC state without reading implementation fields directly.
- [x] Expanded `tests/p2/host_p2ipc.be` to cover hardware-lock and fallback-lock diagnostic shapes, channel/mailbox/buffer state reporting, and mutation isolation for returned diagnostic maps.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the p2ipc diagnostic snapshot regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the p2ipc diagnostic snapshot regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 4 task wait-descriptor error containment

- [x] Hardened the cooperative task scheduler so malformed wait descriptors move only the owning task into `error` state instead of letting scheduler internals throw.
- [x] Hardened waiting-task wake polling so exceptions raised by wait-object methods are captured in that task's `last_error` and do not abort the scheduler turn.
- [x] Expanded `tests/p2/host_task.be` to cover unknown wait kinds, missing wait objects, and wait-object polling failures.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the task wait-descriptor containment regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the task wait-descriptor containment regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 configstore JSON null diagnostics

- [x] Fixed `configstore.load_result(name, fallback)` so a stored JSON `null` is reported as a found, successful config value even when the caller supplied a non-nil fallback.
- [x] Preserved malformed-JSON diagnostics by accepting `nil` parse results only when the config source text is the JSON `null` literal after whitespace trimming.
- [x] Expanded `tests/p2/host_source_modules.be` and `/tests/p2/smoke_configstore.be` to cover valid JSON `null` result diagnostics.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the configstore JSON null diagnostics regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the configstore JSON null diagnostics regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 1 binary_heap sort exception preservation

- [x] Changed `binary_heap.sort(array, cmp)` so it builds the sorted result from a heap copy and commits back to the caller array only after heap operations finish.
- [x] Expanded `tests/p2/host_source_modules.be` and `/tests/p2/smoke_libraries.be` to cover empty and singleton sorts plus caller-array preservation when a comparator raises.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the binary heap regression was added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the binary heap regression was added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 2 p2ipc result diagnostics

- [x] Added result-shaped diagnostics to `p2ipc` channels, mailboxes, and shared buffers: `send_result()`, `recv_result()`, `put_result()`, `get_result()`, `read_result()`, `write_result()`, and `fill_result()`.
- [x] Preserved the old simple `send`/`recv`/`put`/`get`/buffer method contracts while making the result helpers distinguish valid `nil` payloads from empty/full/busy/error states.
- [x] Expanded `tests/p2/host_p2ipc.be` and `/tests/p2/smoke_libraries.be` to cover nil channel/mailbox payloads, full/busy diagnostics, and invalid shared-buffer offset/value diagnostics.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the p2ipc result diagnostics were added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the p2ipc result diagnostics were added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 2 p2ipc lifecycle diagnostics

- [x] Hardened `p2ipc` mutexes, channels, and mailboxes so `close()` is idempotent and marks the object closed instead of letting later operations silently reuse released lock state.
- [x] Added `closed` fields to IPC `info()` diagnostics, kept legacy simple methods returning `false`/`nil` after close, and made result-shaped helpers return `error == "closed"`.
- [x] Expanded `tests/p2/host_p2ipc.be` and `/tests/p2/smoke_libraries.be` to cover hardware-lock and fallback-lock close behavior plus channel/mailbox operations after close.
- [x] Verified `/tests/p2/smoke_libraries.be` with `./berry -c tests/p2/smoke_libraries.be -o /tmp/berry-smoke-libraries.bec`.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the p2ipc lifecycle diagnostics were added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the p2ipc lifecycle diagnostics were added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 2 p2ipc mutex result diagnostics

- [x] Added `lock_result()`, `unlock_result()`, and `close_result()` to `p2ipc` mutexes so callers can distinguish acquired, busy, not-locked, closed, and idempotent-close states without changing the legacy boolean methods.
- [x] Tightened internal mutex state tracking so hardware-backed and fallback mutex result diagnostics report `not_locked` and `closed` consistently.
- [x] Expanded `tests/p2/host_p2ipc.be` and `/tests/p2/smoke_libraries.be` to cover hardware-lock, allocation-fallback, and no-native-lock mutex result diagnostics.
- [x] Verified `/tests/p2/smoke_libraries.be` with `./berry -c tests/p2/smoke_libraries.be -o /tmp/berry-smoke-libraries.bec`.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the p2ipc mutex result diagnostics were added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the p2ipc mutex result diagnostics were added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Priority 4 task lifecycle result diagnostics

- [x] Added `task.start_result()`, `task.stop_result()`, `task.pause_result()`, and `task.resume_result()` so scheduler callers can distinguish invalid functions, over-wide startup argument lists, slot exhaustion, invalid handles, free handles, and state transitions without changing the existing simple return values.
- [x] Expanded `tests/p2/host_task.be` and `/tests/p2/smoke_task.be` to cover the new lifecycle result diagnostics.
- [x] Verified `modules/task.be` with `./berry -c modules/task.be -o /tmp/berry-task-module.bec`.
- [x] Verified `/tests/p2/smoke_task.be` with `./berry -c tests/p2/smoke_task.be -o /tmp/berry-smoke-task.bec`.
- [x] Ran `make test-p2-host` locally on 2026-06-23 after the task lifecycle result diagnostics were added; it passed all eight P2 host regressions.
- [x] Ran `make test-host` locally on 2026-06-23 after the task lifecycle result diagnostics were added. It passed the 54-test desktop Berry suite, skipped lcov/genhtml report generation because those tools were absent, then passed all eight P2 host regressions.

### Native sibling Catalina default

- [x] Changed Berry's Catalina default to the sibling parent-directory install: `CATALINA_DIR=../Catalina`.
- [x] Updated P2 build/test documentation and repository instructions to use native sibling Catalina only; the stale container/cache Catalina validation path was removed from active docs.
- [x] Ran `make p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` locally on 2026-06-24. Native Catalina 8.8.9 compiled the image, then the P2 Hub RAM guard rejected the full no-PSRAM image at `550496 / 524288` bytes, preserving the size safety gate.
- [x] Ran `make p2-minimal TOOLCHAIN=catalina CATALINA_DIR=../Catalina` locally on 2026-06-24. Native Catalina 8.8.9 built the no-PSRAM minimal image successfully at `464416 / 524288` bytes.

### Priority 2 smart-pin loopback smoke

- [x] Added `/tests/p2/smoke_smartpins_loopback.be` for boards wired with jumpers between pins `0-1`, `2-3`, `4-5`, and `6-7`. The smoke resets those pins, verifies GPIO output/input loopback in both directions for each pair, exercises `p2.smart.wrpin`, `wxpin`, `wypin`, `akpin`, `rdpin`, `rqpin`, `start`, and `clear`, and checks invalid pin/value diagnostics.
- [x] Added always-on default-build `p2.smart` runtime module aliases and lower-case Catalina `smartpin.h` constants, excluding bit-31 `P_INVERT_A` until unsigned raw values are represented safely.
- [x] Extended `/tests/p2/smoke_smartpins_loopback.be` with PWM-output to rise-counter loopback coverage in both directions across each wired pair.
- [x] Extended `/tests/p2/smoke_smartpins_loopback.be` with NCO-output to rise-counter loopback coverage in both directions across each wired pair, using Catalina's documented NCO mode sequence.
- [x] Added `modules/p2smart.be`, a conservative source-level wrapper module for `p2smart.Counter`, `p2smart.PWM`, and `p2smart.NCO` over the raw `p2.smart` helpers, including bounded argument validation and compact `info()` diagnostics.
- [x] Added `tests/p2/host_p2smart.be` to verify `p2smart` counter/PWM/NCO generated call sequences and invalid argument diagnostics against a fake `p2.smart`/`p2.pin` backend, and wired it into `make test-p2-host`.
- [x] Extended `modules/p2smart.be` with `p2smart.Pulse` and `p2smart.Transition` wrappers for Catalina-documented pulse/cycle and transition smart-pin modes, including bounded X/Y setup validation, update helpers, and compact `info()` diagnostics.
- [x] Extended `tests/p2/host_p2smart.be` to verify pulse/cycle and transition generated smart-pin call sequences plus invalid argument diagnostics against the fake backend.
- [x] Added `p2smart` to `libstore.known`, coverage metadata, SD import, repeated import/cache, low-memory churn, and module inventory smokes.
- [x] Updated `/tests/p2/smoke_smartpins_loopback.be` so PWM, NCO, pulse/cycle, and transition loopback setup goes through the new `p2smart` wrappers while raw helper coverage remains in place.
- [x] Fixed parser-sensitive C-style conditionals in `/tests/p2/smoke_module_inventory.be` so the smoke bytecode-compiles under the current Berry parser.
- [x] Ran `make test-host` locally on 2026-06-24 after adding `p2smart`; it passed the 54-test desktop suite, skipped lcov/genhtml because those tools were absent, and completed all nine P2 host regressions including `tests/p2/host_p2smart.be`.
- [x] Re-ran focused bytecode/static checks after adding `p2smart`: `./berry -c modules/p2smart.be`, `smoke_smartpins_loopback.be`, `smoke_import_all_libs.be`, `smoke_import_cache.be`, `smoke_import_churn.be`, `smoke_module_inventory.be`, `python3 -m py_compile scripts/p2/repl_smoke.py`, and `git diff --check`; all passed.
- [x] Re-ran `make test-host` locally on 2026-06-24 after extending `p2smart` with pulse/cycle and transition wrappers; it passed the 54-test desktop suite, skipped lcov/genhtml because those tools were absent, and completed all nine P2 host regressions including the expanded `tests/p2/host_p2smart.be`.
- [x] Re-ran focused bytecode/static checks after extending `p2smart`: `./berry -c modules/p2smart.be`, `smoke_smartpins_loopback.be`, `smoke_import_all_libs.be`, `smoke_import_cache.be`, `smoke_import_churn.be`, `python3 -m py_compile scripts/p2/repl_smoke.py`, and `git diff --check`; all passed.
- [x] Ran `make p2-minimal TOOLCHAIN=catalina CATALINA_DIR=../Catalina` locally on 2026-06-24 after adding `p2smart`; the target completed the normal Catalina tool/prebuild path and did not need to relink because this change only added SD/host-side Berry modules and tests.
- [x] Added a `smartpins-loopback` suite to `scripts/p2/repl_smoke.py` and documented the wiring/command in `docs/testing.md`.
- [x] Verified the new smoke compiles with `./berry -c tests/p2/smoke_smartpins_loopback.be -o /tmp/berry-smoke-smartpins-loopback.bec`.
- [x] Ran `make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina` locally on 2026-06-24 after the default-build `p2.smart` runtime module and constants were added. Native Catalina 8.8.9 built the XMM image successfully at `948128 / 16777216` bytes.
- [x] Forced a fresh `make p2-minimal TOOLCHAIN=catalina CATALINA_DIR=../Catalina` rebuild locally on 2026-06-24 after the smart-pin updates; the no-PSRAM minimal image still passed the Hub RAM guard at `464416 / 524288` bytes.
- [x] Ran `make test-host` locally on 2026-06-24 after the smart-pin updates; it passed the 54-test desktop suite, skipped lcov/genhtml because those tools were absent, and completed all eight P2 host regressions.
- [x] Re-ran `./berry -c tests/p2/smoke_p2_api.be -o /tmp/berry-smoke-p2-api.bec`, `./berry -c tests/p2/smoke_smartpins_loopback.be -o /tmp/berry-smoke-smartpins-loopback.bec`, `python3 -m py_compile scripts/p2/repl_smoke.py`, and `git diff --check` after the smart-pin updates; all passed.
- [x] Checked for attached serial devices locally before running the hardware suite; none of `/dev/cu.*`, `/dev/ttyUSB*`, or `/dev/ttyACM*` was present, so on-board smart-pin execution remains pending.
- [x] Extended `modules/p2smart.be` with `p2smart.Repository` and `p2smart.AsyncSerialPair` wrappers. Repository mode stages X-register read/write checks; async serial pair stages adjacent-pin TX/RX byte setup using Catalina's smart-pin serial mode pattern.
- [x] Extended `tests/p2/host_p2smart.be` to verify repository and async serial generated call sequences, byte extraction from `rdpin`, neighbor-input mode selection for both jumper directions, and invalid argument diagnostics against the fake backend.
- [x] Extended `/tests/p2/smoke_smartpins_loopback.be` to cover repository mode on every jumper pin and async serial byte loopback in both directions across each wired pair.
- [x] Re-ran focused checks after repository/async-serial smart-pin coverage: `./berry tests/p2/host_p2smart.be`, bytecode compiles for `modules/p2smart.be`, `smoke_smartpins_loopback.be`, `smoke_import_all_libs.be`, `smoke_import_cache.be`, `smoke_import_churn.be`, `smoke_module_inventory.be`, `python3 -m py_compile scripts/p2/repl_smoke.py`, `make test-p2-host`, `make test-host`, `git diff --check`, stale legacy-reference scans, and `make p2-minimal TOOLCHAIN=catalina CATALINA_DIR=../Catalina`; all passed or completed, with hardware execution still blocked by no visible serial device.
- [x] Expanded `/tests/p2/smoke_p2_api.be` grouped GPIO coverage so `p2.pin` now stages `dir_low`, `dir_high`, `write`, `low`, `high`, `toggle`, `float`, and `read`, including bool/int writes, both toggle edges, invalid write values, invalid write pins, and reserved-pin write rejection when applicable.
- [x] Expanded `/tests/p2/smoke_p2_api.be` grouped clock coverage with `p2.clock.set` / `p2.clock.hubset` function-shape checks and non-destructive negative-argument diagnostics, while avoiding valid clock-changing calls in the smoke.
- [x] Expanded `/tests/p2/smoke_p2_api.be` grouped cog coverage with `stop`, `attention`, and `wait_attention` function-shape checks, no-op `attention(0)`, `poll_attention()` type coverage, and invalid `check`, `stop`, and `attention` diagnostics while avoiding blocking `wait_attention()` and valid cog-stop calls.
- [x] Re-ran focused validation after the grouped P2 API smoke expansion: `./berry -c tests/p2/smoke_p2_api.be`, `./berry tests/p2/host_p2smart.be`, `python3 -m py_compile scripts/p2/repl_smoke.py`, `git diff --check`, `make test-p2-host`, and `make p2-minimal TOOLCHAIN=catalina CATALINA_DIR=../Catalina`; all passed or completed through the native sibling Catalina path.
- [x] Expanded `/tests/p2/smoke_p2_api.be` grouped lock coverage with function-shape checks for `new`, `ret`, `try`, `release`, and `check`, allocated-lock exercise when a hardware lock is available, and invalid-range diagnostics for `try`, `release`, `ret`, and `check`.
- [x] Re-ran focused validation after the grouped lock smoke expansion: `./berry -c tests/p2/smoke_p2_api.be`, `python3 -m py_compile scripts/p2/repl_smoke.py`, `git diff --check`, `make test-p2-host`, and `make p2-minimal TOOLCHAIN=catalina CATALINA_DIR=../Catalina`; all passed or completed through the native sibling Catalina path.
- [x] Expanded `/tests/p2/smoke_p2_api.be` grouped CORDIC/math/RNG coverage with result-shape checks for `rotxy`, `polxy`, and `xypol`, deterministic checks for `isqrt`, `muldiv64`, `rev`, and `encod`, RNG return-type coverage, and negative diagnostics for unsigned math/CORDIC arguments.
- [x] Re-ran focused validation after the grouped CORDIC/math/RNG smoke expansion: `./berry -c tests/p2/smoke_p2_api.be`, `./berry tests/p2/host_p2smart.be`, `python3 -m py_compile scripts/p2/repl_smoke.py`, `git diff --check`, `make test-p2-host`, and `make p2-minimal TOOLCHAIN=catalina CATALINA_DIR=../Catalina`; all passed or completed through the native sibling Catalina path.
- [x] Restored and expanded `/tests/p2/smoke_p2_api.be` safe `p2.asm` and backed `p2.debug` facade coverage with safe intrinsic reads/waits, debug snapshot/heap/GC/cog/memory-map/pin/smart-pin/register diagnostics, and negative diagnostics for invalid `asm`/`debug` arguments.
- [x] Re-ran focused validation after restoring `p2.asm`/`p2.debug` API smoke coverage: `./berry -c tests/p2/smoke_p2_api.be`, `./berry tests/p2/host_p2smart.be`, `python3 -m py_compile scripts/p2/repl_smoke.py`, `git diff --check`, `make test-p2-host`, and `make p2-minimal TOOLCHAIN=catalina CATALINA_DIR=../Catalina`; all passed or completed through the native sibling Catalina path.
- [x] Expanded `/tests/p2/smoke_p2_api.be` backed `p2.debug` coverage with `pins()` 64-entry snapshot checks and explicit current-cog `registers(cog)` field checks.
- [x] Re-ran focused validation after expanding `p2.debug.pins()` / explicit-register smoke coverage: `./berry -c tests/p2/smoke_p2_api.be`, `./berry tests/p2/host_p2smart.be`, `python3 -m py_compile scripts/p2/repl_smoke.py`, `git diff --check`, `make test-p2-host`, and `make p2-minimal TOOLCHAIN=catalina CATALINA_DIR=../Catalina`; all passed or completed through the native sibling Catalina path.
- [x] Added explicit `soak` and `soak-smartpins` suites to `scripts/p2/repl_smoke.py`. The default soak suite repeats import/cache, bounded import churn plus GC, library behavior, cooperative task coverage, closure-based cog spawn/stop, and grouped P2 API coverage. The smart-pin variant adds the jumper-dependent smart-pin loopback coverage for pairs `0-1`, `2-3`, `4-5`, and `6-7`.
- [x] Changed `make soak-p2` to default to `SOAK_P2_SUITE=soak` instead of reusing the normal `TEST_P2_SUITE`, and documented `SOAK_P2_SUITE=soak-smartpins` for wired boards.
- [x] Hardware-probed `/dev/ttyUSB0` with the user-provided jumper wiring. Verified the board responds to the P2 REPL, uploaded revised `modules/p2smart.be` and `/tests/p2/smoke_smartpins_loopback.be` to SD, and loaded the current Catalina XMM image interactively with the sibling `../Catalina` payload path. The smartpin smoke currently reaches `P2_SMOKE_BEGIN smartpins_loopback` and then fails before pin exercise because native `p2.smartpin_*` attributes are not visible from the SD-loaded `p2smart` source module on that image.
- [x] Fixed native `p2` visibility for SD-loaded source modules by registering the cached native `p2` module as a global, so `import p2` / `import p2 as ...` returns the module object on the XMM image.
- [x] Fixed `p2smart` smart-pin wrappers so `start()` does not call GPIO `dir_high()` after `_pinstart()`. The GPIO helper intentionally clears smart-pin mode, so the old wrapper disabled PWM/NCO/pulse/transition immediately after setup.
- [x] Fixed `p2smart.Pulse.start()` and `p2smart.Transition.start()` to issue an explicit `wypin()` trigger after setup, which made pulse/cycle and transition events countable in the jumper smoke.
- [x] Adjusted `p2smart.AsyncSerialPair` default RX mode to local `async_rx` for physically wired TX/RX pins instead of forcing adjacent-pin selector bits.
- [x] Rebuilt and flashed the current Catalina XMM image with native sibling Catalina: `make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2` produced `948192 / 16777216` bytes, and `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0` installed it.
- [x] Hardware-verified `/tests/p2/smoke_smartpins_loopback.be` on `/dev/ttyUSB0` with jumpers `0-1`, `2-3`, `4-5`, and `6-7`: `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite smartpins-loopback --timeout 240` passed on the flashed XMM image. Coverage includes GPIO both directions, raw smart-pin helpers, repository mode calls, PWM/NCO/pulse/transition-to-rise-counter checks, async TX/RX setup/send/query/ack in both directions, and negative raw-helper diagnostics. Blocking async RX byte `rdpin` readback remains open.
- [x] Re-ran local validation after the smart-pin hardware fixes: `./berry -c modules/p2smart.be`, `./berry -c tests/p2/smoke_smartpins_loopback.be`, `./berry tests/p2/host_p2smart.be`, `python3 -m py_compile scripts/p2/repl_smoke.py scripts/p2/repl_upload.py`, `git diff --check`, and `make test-p2-host`; all passed, with only the existing `baselib_trace` unused warning during the host rebuild.
- [x] Enabled the grouped low-level P2 facade module builders in the default Catalina P2 image by setting `BE_P2_ENABLE_ROADMAP_NATIVE_FACADES=1`. Rebuilt and flashed with the native sibling Catalina path: `make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2` and `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0`. This was the intermediate grouped-facade XMM image before the later public-container fixes and reflash.
- [x] Fixed absolute counter waits so `waitcnt` accepts Berry's signed representation of 32-bit P2 counter values instead of rejecting high-bit counter ticks as negative values. The smoke now avoids executing a valid absolute `waitcnt` target because missed targets can block until counter wrap; relative wait helpers remain exercised.
- [x] Hardware-probed grouped P2 module exposure on `/dev/ttyUSB0`; `p2.clock`, `p2.cog`, `p2.lock`, `p2.pin`, `p2.cordic`, `p2.math`, `p2.rng`, `p2.smart`, `p2.asm`, and `p2.debug` all reported as modules on the flashed XMM image.
- [x] Ran focused `/dev/ttyUSB0` grouped API probes after enabling the facades: clock relative waits, cog `id/check/attention/poll_attention`, lock `new/check/ret`, LED pin write/read/float, deterministic math/RNG/asm reads, and debug map/register probes all returned. The first full grouped smoke exposed additional public-container/test-shape issues, which are fixed and recorded in the later passing hardware entry below.
- [x] Re-ran `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite smartpins-loopback --timeout 240` after enabling grouped facades; the smart-pin hardware loopback suite still passed across jumper pairs `0-1`, `2-3`, `4-5`, and `6-7`.
- [x] Fixed grouped P2 API hardware smoke blockers on `/dev/ttyUSB0`: `p2.status_info()["cogs"]`, `p2.debug.cogs()`, and `p2.debug.pins()` now return public Berry list instances containing public map instances rather than raw backing containers; `p2.clock.waitcnt` accepts signed Berry representations of 32-bit counter targets; the API smoke avoids executing valid absolute `waitcnt` targets; lock smoke uses `p2.lock.("try")` for the reserved method name; CORDIC result-shape checks expect public map instances; and heap diagnostics check the existing `current` key.
- [x] Rebuilt and flashed with native sibling Catalina only: `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0`. The flashed Catalina XMM image is `959808 / 16777216` bytes.
- [x] Hardware-verified grouped P2 API smoke on `/dev/ttyUSB0`: uploaded `/tests/p2/smoke_p2_api.be` and ran `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/tests/p2/smoke_p2_api.be")' --expect 'P2_SMOKE_PASS p2_api' --timeout 180`; it passed through status, clock, cog/lock, GPIO, math/ASM, debug, negative, and smart stages.
- [x] Re-ran smart-pin hardware loopback on `/dev/ttyUSB0` with jumpers `0-1`, `2-3`, `4-5`, and `6-7`: `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite smartpins-loopback --timeout 240` passed across all four pairs in both directions, including GPIO, raw helpers, repository, PWM, NCO, pulse, transition, async setup/send/query/ack, and negative diagnostics.
- [x] Re-ran local validation after the grouped API hardware fixes: `./berry -c tests/p2/smoke_p2_api.be`, `./berry tests/p2/host_p2smart.be`, `python3 -m py_compile scripts/p2/repl_smoke.py scripts/p2/repl_upload.py`, `git diff --check`, and `make test-p2-host`; all passed, with only the existing `baselib_trace` unused warning during the host rebuild.
- [x] Extended `modules/p2smart.be` with conservative `p2smart.ADC` / `p2smart.adc(...)` and `p2smart.DAC` / `p2smart.dac(...)` wrappers. ADC validates sample ticks and exposes `start()`, `read()`, `query()`, `ack()`, `clear()`, and `info()`; DAC validates byte output/frame values and exposes `start()`, `set(value)`, `clear()`, and `info()`.
- [x] Extended `tests/p2/host_p2smart.be` and the import/cache/churn smokes so ADC/DAC wrapper classes, factory functions, generated raw smart-pin call sequences, and invalid argument diagnostics are covered on the host.
- [x] Extended `/tests/p2/smoke_smartpins_loopback.be` with DAC-output to ADC-input setup/readback coverage in both directions across jumper pairs `0-1`, `2-3`, `4-5`, and `6-7`. The smoke prints `P2_SMOKE_ADC_VALUES` samples and asserts integer readback; calibrated low/high analog deltas are intentionally still open because the observed values vary by pair and suite context.
- [x] Uploaded the updated `/modules/p2smart.be` and `/tests/p2/smoke_smartpins_loopback.be`, then re-ran `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite smartpins-loopback --timeout 300`; it passed with `P2_SMOKE_PASS smartpins_loopback` on the flashed Catalina XMM image.
- [x] Re-ran grouped P2 API hardware smoke after the ADC/DAC smart-pin changes: `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/tests/p2/smoke_p2_api.be")' --expect 'P2_SMOKE_PASS p2_api' --timeout 180`; it still passed.
- [x] Re-ran local validation after the ADC/DAC wrapper work: `./berry -c modules/p2smart.be`, `./berry tests/p2/host_p2smart.be`, `./berry -c tests/p2/smoke_smartpins_loopback.be`, `./berry -c tests/p2/smoke_import_all_libs.be`, `./berry -c tests/p2/smoke_import_cache.be`, `./berry -c tests/p2/smoke_import_churn.be`, `python3 -m py_compile scripts/p2/repl_smoke.py scripts/p2/repl_upload.py`, `git diff --check`, and `make test-p2-host`; all passed, with only the existing `baselib_trace` unused warning during the host rebuild.
- [x] Added `count_highs` fallback metadata to `modules/p2smart.be` and extended `/tests/p2/smoke_smartpins_loopback.be` with GPIO-driven high-counter loopback in both directions across every jumper pair.
- [x] Re-uploaded the updated `p2smart` module and smartpin loopback smoke to `/dev/ttyUSB0`, then re-ran `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite smartpins-loopback --timeout 300`; it passed with `P2_SMOKE_CASE high_counter_ab`, `P2_SMOKE_CASE high_counter_ba`, and `P2_SMOKE_PASS smartpins_loopback`.
- [x] Extended `modules/p2smart.be` with conservative `p2smart.GPIOInput` / `p2smart.gpio_input(...)` and `p2smart.GPIOOutput` / `p2smart.gpio_output(...)` wrappers over the grouped `p2.pin` facade. The wrappers validate pins and output values, expose `start()`, `read()`, `high()`, `low()`, `write()`, `toggle()`, `clear()`, and `info()` as appropriate, and do not hide the underlying GPIO operations.
- [x] Extended `tests/p2/host_p2smart.be` and the import/cache/churn smokes so GPIO wrapper classes, factories, generated `p2.pin` call sequences, and invalid argument diagnostics are covered on the host.
- [x] Updated `/tests/p2/smoke_smartpins_loopback.be` so the existing GPIO loopback cases now exercise `p2smart.GPIOInput` and `p2smart.GPIOOutput` in both directions across jumper pairs `0-1`, `2-3`, `4-5`, and `6-7`, while raw pin reset coverage remains in place.
- [x] Re-uploaded the updated `p2smart` module and smartpin loopback smoke to `/dev/ttyUSB0`, then re-ran `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite smartpins-loopback --timeout 300`; it passed with GPIO wrapper loopback, high-counter loopback, DAC/ADC setup/readback samples, and `P2_SMOKE_PASS smartpins_loopback`.
- [x] Implemented native `map.values()` and changed native `map.keys()` to return public list snapshots, matching the P2 collection/map smokes' expected `.size()`, `.find()`, iteration, and mutation-isolation behavior while preserving `map.iter()` as the value iterator.
- [x] Updated stale P2 smoke assumptions for `list.remove()` / `map.remove()` return values and iterator exhaustion: remove calls now verify post-state instead of removed values, and list/range iterator exhaustion now expects `stop_iteration`.
- [x] Rebuilt and flashed the XMM image with native sibling Catalina only: `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0`; the stable flashed image is `960320 / 16777216` bytes.
- [x] Hardware-verified the map/list/range fixes on `/dev/ttyUSB0`: `/tests/p2/smoke_map_core.be`, `/tests/p2/smoke_collections.be`, `/tests/p2/smoke_range.be`, and `/tests/p2/smoke_list_core.be` all passed on the flashed Catalina XMM image.
- [x] Re-ran smart-pin hardware loopback on `/dev/ttyUSB0` after the runtime/test fixes with jumpers `0-1`, `2-3`, `4-5`, and `6-7`; `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite smartpins-loopback --timeout 360` passed across GPIO wrappers, raw helpers, repository mode, PWM, high-counter, NCO, pulse, transition, async serial setup, DAC/ADC setup/readback samples, and negative diagnostics.
- [x] Tried enabling XMM extended native modules to unblock the full compatibility/stdlib smoke. The image built at `966848 / 16777216`, but both `import global` and `import global as g` hung on hardware, so the extended-module gate was reverted and the board was reflashed to the stable `960320` byte image. The native `global` module remains a real runtime blocker for full `smoke_all`/stdlib verification.
- [x] Fixed a latent C syntax error in the non-precompiled `sys` native module registration table by adding the missing comma between `path` and `path_add`; this was exposed while compiling the extended-module XMM experiment.
- [x] Narrowed the native `global` blocker on `/dev/ttyUSB0`: skipping import-time auto-call for the native `global` module lets `import global` return on the XMM image, and host `tests/global.be`, `/tests/p2/smoke_global.be`, and `make test-p2-host` still pass. Hardware still hangs at `global()`, so the XMM extended-module gate remains disabled before claiming full stdlib/compat coverage.
- [x] Hardened the native `global()` table-view implementation on the host side so it returns a public `map` snapshot through low-level map insertion and bounded descriptor iteration. This is not yet hardware-verified because `global()` still hangs on P2 XMM and remains tracked in `TODO.md`.
- [x] Rebuilt and flashed the stable XMM image after re-disabling extended modules and native `time`: `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0` installed a `960416 / 16777216` byte image.
- [x] Hardware-verified the final stable flashed image on `/dev/ttyUSB0`: grouped P2 API passed, and `scripts/p2/repl_smoke.py --suite smartpins-loopback --timeout 300` passed across jumpers `0-1`, `2-3`, `4-5`, and `6-7`, including GPIO wrappers, raw helpers, repository mode, PWM, high-counter, NCO, pulse, transition, async serial setup/send/query/ack, DAC/ADC setup/readback samples, and negative diagnostics.
- [x] Re-ran grouped P2 API plus smartpin loopback as a two-iteration hardware repeat on the final `960416` byte XMM image: both iterations passed `P2_SMOKE_PASS p2_api` and `P2_SMOKE_PASS smartpins_loopback` on `/dev/ttyUSB0`.
- [x] Fixed the native P2 cooperative task backend return handling and timeout bookkeeping: task calls now pop arguments after `be_call()`, sleep/event timeouts use relative millisecond requests with wrap-safe comparisons, and timeout wakeups are reported correctly. Hardware-verified on `/dev/ttyUSB0` with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite task --timeout 180 --startup-timeout 120`, which passed `P2_SMOKE_PASS task` on the Catalina XMM image.
- [x] Hardened `libstore` and `p2mem` for P2 SD/XMM import-cache stress: `libstore.info()` now uses a shallow source-safe snapshot instead of deep compiled/cache probes, `compile_cache_plan()` no longer calls back into full resolve, `libstore.status()` avoids a full module directory scan for `library_count`, and `p2mem` no longer imports the generic `gc` module on P2, using the working `p2.gc()` path instead.
- [x] Added hardware-safe short import/cache/churn smoke aliases `/tests/p2/impcache.be` and `/tests/p2/impchurn.be`. They keep repeated-import and metadata coverage for `binary_heap`, `configstore`, `libstore`, `math`, `p2compat`, `p2ipc`, `p2mem`, `p2smart`, `task`, and `wifi`, avoid the P2-hostile `introspect` pointer checks and repeated full `libstore.info()` scans, and keep the PSRAM source-cache round trip to a representative module with explicit cleanup before the next smoke.
- [x] Hardware-verified the repaired import/cache/churn path on `/dev/ttyUSB0`: `run_file("/tests/p2/impcache.be")` passed `P2_SMOKE_PASS import_cache`, `run_file("/tests/p2/impchurn.be")` passed `P2_SMOKE_PASS import_churn`, and `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite soak-smartpins --repeat 1 --timeout 700 --startup-timeout 120` passed end to end through import cache, import churn, task, grouped P2 API, smartpin loopback on jumper pairs `0-1`, `2-3`, `4-5`, `6-7`, and final `p2.gc()`.
- [x] Re-audited active P2 build documentation and tooling for stale Catalina paths after switching to the sibling install. No `CATALINA_USE_DOCKER` or Docker-Catalina path remains in active docs/tooling, and current user-facing P2 docs now show `CATALINA_DIR=../Catalina` instead of the old absolute `catalina-speccy88` checkout. Re-verified the native sibling Catalina path with `make p2-minimal TOOLCHAIN=catalina CATALINA_DIR=../Catalina`; Catalina 8.8.9 built successfully and the image passed the Hub RAM guard at `464832 / 524288` bytes.
- [x] Repaired the default hardware `soak` path on `/dev/ttyUSB0`. `/tests/p2/smoke_libraries.be` now avoids P2-hostile deep `libstore`/`p2mem` diagnostics while preserving library, cache, policy, p2mem stats/cache/gc, and IPC checks; `/tests/p2/smoke_cog_closure.be` now treats native list/map containers as public instance-backed containers and checks closure-cog `calls` as a non-negative native loop counter instead of a deterministic immediate tick count. Verified with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite soak --repeat 1 --timeout 700 --startup-timeout 120`, which passed import cache, import churn, libraries, task, closure-cog, grouped P2 API, and final `p2.gc()` on the Catalina XMM image.
- [x] Made dormant P2 GC trace switches overrideable from the native Catalina command line by guarding `BE_P2_TRACE_GC_COLLECT` and `BE_P2_TRACE_GC_MODULE` in `port/p2/include/berry_conf_p2.h`; default builds still leave both traces off.
- [x] Rebuilt and flashed an opt-in extended-module diagnostic XMM image with native sibling Catalina: `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0 CATALINA_EXTRA_CFLAGS='-DBE_P2_ENABLE_EXTENDED_MODULES=1 -DBE_P2_TRACE_GC_MODULE=1'`. The image built at `967040 / 16777216` bytes before the dynamic-module experiment and `966816 / 16777216` bytes during it.
- [x] Narrowed the extended-module call-path blocker on `/dev/ttyUSB0`: `import string; string.format("%i", 7)` and `import json; json.load("{\"a\":1}")["a"]` still call successfully, and `import gc; print(type(gc.collect))` reports `function`, but `import gc; print(type(gc.collect), gc.collect())` hangs before the `[gcmod] collect start` trace. This proves the failing `gc.collect()` call is not entering `m_collect()`.
- [x] Tested and backed out a P2-only dynamic-module initializer experiment for `global`, `gc`, and `sys`: the image built, but lookup-only `import gc; print(type(gc), type(gc.collect), type(gc.allocated))` hung earlier than the prior static attr-table shape, so the experiment was not kept as a fix.
- [x] Rebuilt and reflashed the stable non-extended XMM image with native sibling Catalina only: `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0` installed a `960608 / 16777216` byte image.
- [x] Hardware-verified the restored stable `960608` byte XMM image on `/dev/ttyUSB0`: `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite soak-smartpins --repeat 1 --timeout 700 --startup-timeout 120` passed end to end through import cache, import churn, task, grouped P2 API, smartpin loopback on jumper pairs `0-1`, `2-3`, `4-5`, `6-7`, and final `p2.gc()`.
- [x] Fixed the P2 XMM extended native-module zero-function-pointer blocker for `gc`, `sys`, `global`, and `introspect` by adding P2 cached-module constructors that push native function values at runtime instead of relying on static attr-table function fields. The cached `global` module is explicitly named and P2 routes its assignments through the native `setmember` hook so `global.foo = value`, `global.contains()`, `global()`, and `global.undef()` agree.
- [x] Fixed `sys.path()` to return a fresh public list instance backed by a copy of the VM module path list, so caller mutation no longer changes future `sys.path()` results. Updated `/tests/p2/smoke_sys.be` to avoid P2-hostile raw-pointer identity checks through `introspect.toptr()` and to assert the public list contract with `isinstance(..., list)`.
- [x] Hardware-verified the extended-module diagnostic XMM image with native sibling Catalina only: `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0 CATALINA_EXTRA_CFLAGS='-DBE_P2_ENABLE_EXTENDED_MODULES=1 -DBE_P2_TRACE_GC_MODULE=1 -DBE_P2_TRACE_NATIVE_CALL=1'` built and flashed a `980416 / 16777216` byte image. On `/dev/ttyUSB0`, focused probes verified `gc.collect()` reaches `[gcmod] collect start`, `sys.path()` returns a function-backed fresh list, and `global.p2_probe=42` is visible through direct member read, `global.contains()`, and `global().find()` before `global.undef()`.
- [x] Hardware-verified the repaired extended `global` and `sys` smokes on `/dev/ttyUSB0`: `/tests/p2/smoke_global.be` passed with `P2_SMOKE_PASS global`, and after uploading the refreshed SD copy, `/tests/p2/smoke_sys.be` passed with `P2_SMOKE_PASS sys` on the diagnostic extended-module XMM image.
- [x] Restored the board to a normal non-diagnostic XMM image with native sibling Catalina only: `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0` installed a `967520 / 16777216` byte image with no extended trace flags. Final verification passed with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite soak-smartpins --repeat 1 --timeout 700 --startup-timeout 120`, covering import cache, import churn, task, grouped P2 API, smart-pin loopback over jumpers `0-1`, `2-3`, `4-5`, `6-7`, and final `p2.gc()`.

### Priority 1 extended stdlib module verification

- [x] Fixed the P2 XMM extended native `time` module by adding a cached-module constructor and routing `BE_P2_ENABLE_TIME_MODULE` through the opt-in `BE_P2_ENABLE_EXTENDED_MODULES` gate. Hardware-verified `/tests/p2/smoke_time.be` on `/dev/ttyUSB0`.
- [x] Fixed the P2 XMM extended native `strict` module by adding a cached-module constructor that installs the native import hook and enables compiler strict mode on the P2 cached import path. Hardware-verified `/tests/p2/smoke_strict.be` on `/dev/ttyUSB0`, including missing-global rejection, known-global visibility, branch/loop/conditional-expression checks, and cleanup-after-undef rejection.
- [x] Expanded and corrected `/tests/p2/smoke_stdlib.be` for P2 hardware: `time.dump()` checks are timezone-neutral, `strict` accepts either host-style `nil` or P2 cached-module return shape while still proving strict compile behavior, and `solidify` is explicitly reported as skipped because the current P2 XMM profile does not ship it. Hardware-verified `/tests/p2/smoke_stdlib.be` on the extended diagnostic XMM image with `P2_SMOKE_PASS stdlib`.
- [x] Fixed compact P2 native `string` compatibility used by the stdlib smoke: `escape()`, `tr()`, case-insensitive `startswith()` / `endswith()`, and `format == string.format` now match the expected compact behavior. Hardware probe coverage passed before the full `smoke_stdlib` run, and host execution/bytecode compile passed for `smoke_stdlib`.
- [x] Corrected P2 introspect smoke expectations for `introspect.get()` unbound methods, unsupported scalar `toptr()` inputs, and pointer resurrection behavior; hardware-verified the focused introspect and `ismethod` smokes on the extended diagnostic XMM image. The SD long-filename alias/collision observed while alternating `smoke_introspect.be` and `smoke_introspect_ismethod.be` remains tracked as follow-up.
- [x] Fixed the P2 XMM extended native `debug` module by adding a cached-module constructor that pushes native function values at runtime. Updated `/tests/p2/smoke_debug.be` for the observed `debug.caller()` depth semantics, then hardware-verified it on `/dev/ttyUSB0` with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/tests/p2/smoke_debug.be")' --expect 'P2_SMOKE_PASS debug' --timeout 240 --startup-timeout 120` on the opt-in extended diagnostic XMM image.
- [x] Rebuilt and flashed the normal non-diagnostic XMM image with native sibling Catalina only after the extended-module diagnostics: `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0` installed a `968352 / 16777216` byte image. Final hardware regression passed with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite soak-smartpins --repeat 1 --timeout 700 --startup-timeout 120`, covering import cache, import churn, task, grouped P2 API, smart-pin loopback over jumpers `0-1`, `2-3`, `4-5`, `6-7`, and final `p2.gc()`.

### Priority 1 solidify XMM hardware verification

- [x] Enabled the native `solidify` module on the normal P2 XMM profile while leaving smaller non-XMM profiles gated off. The P2 cached constructor provides `dump`, `compact`, and `nocompact`; the P2 build avoids unsupported instance-constant emission paths for list/map/bytes constants and keeps class/function compaction available.
- [x] Fixed the P2/Catalina solidify build path by making `be_print_inst()` available when either the debug module or solidify module is enabled, and by avoiding the empty generated native-module table entry for cached P2 `solidify`.
- [x] Corrected `/tests/p2/smoke_solidify.be` to use the established Berry `super(self)` pattern for inherited method calls, then verified the smoke on the host and as bytecode.
- [x] Rebuilt the normal XMM image with native sibling Catalina only: `make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2` passed at `1015648 / 16777216` bytes, then `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0` installed it.
- [x] Hardware-verified native `solidify` on `/dev/ttyUSB0` with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/tests/p2/smoke_solidify.be")' --expect 'P2_SMOKE_PASS solidify' --timeout 240 --startup-timeout 120`; it passed on the normal XMM image with `P2_SMOKE_PASS solidify`.
- [x] Re-ran the normal-image regression after enabling `solidify`: `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite soak-smartpins --repeat 1 --timeout 700 --startup-timeout 120` passed on the `1015648` byte XMM image, covering import cache, import churn, task, grouped P2 API, smart-pin loopback on jumper pairs `0-1`, `2-3`, `4-5`, `6-7`, and final `p2.gc()`.

### Priority 1 native math and module smoke verification

- [x] Hardened native P2 `math` behavior on the normal XMM image: `math.accel_info()` returns a public map describing the CORDIC backend, `math.nan` / `math.inf` use IEEE single-float non-finite values, non-finite string conversion and VM comparisons handle NaN/Inf explicitly, CORDIC angle conversion handles the `math.pi` half-turn boundary, and integer `sqrt()` returns exact integers for perfect squares while non-perfect squares return real approximations.
- [x] Fixed public container return/type behavior needed by the module smoke: builtin map/list instances report as `map`/`list` through `type()`, `p2.cog_states()` now returns a public list instance instead of a raw backing list or the native function value, and grouped CORDIC result tests now expect public maps.
- [x] Rebuilt and flashed the normal XMM image with native sibling Catalina only: `make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2` built a `1023392 / 16777216` byte image, and `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0` installed it.
- [x] Hardware-verified the repaired module path on `/dev/ttyUSB0`: `p2.cog_states()` focused probe returned `list 8`, `/tests/p2/smoke_p2_api.be` passed through status, clock, cog/lock, GPIO, math/ASM, debug, negative, and smart stages, `/tests/p2/smoke_modules.be` passed with nested P2 API coverage, and `/tests/p2/smoke_math_parity.be` passed on the same flashed image.
- [x] Re-ran the jumper-dependent regression after the math/module fixes: `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite soak-smartpins --repeat 1 --timeout 700 --startup-timeout 120` passed end to end through import cache, import churn, task, grouped P2 API, smart-pin loopback on jumper pairs `0-1`, `2-3`, `4-5`, `6-7`, and final `p2.gc()`.

### Priority 1 normal-XMM introspect and compat verification

- [x] Added 8.3-safe hardware smoke aliases `/tests/p2/intro.be` and `/tests/p2/ismeth.be` for the existing `smoke_introspect.be` and `smoke_introspect_ismethod.be` content, and updated `/tests/p2/smoke_all.be` to call the aliases. This avoids the observed FAT long-filename collision where `/tests/p2/smoke_introspect.be` could execute the `smoke_introspect_ismethod` file content on the P2 SD card.
- [x] Fixed cached module diagnostics by making `be_cache_module()` assign the cache key as the module name when caching an unnamed module. Hardware probe on `/dev/ttyUSB0` now reports `introspect.name(introspect.module("json")) == "json"` and likewise for `math` and `string`.
- [x] Fixed P2 interactive `input()` by making `be_readstring()` append a newline to lines returned through the P2 serial line editor, matching the `fgets()`-style contract expected by Berry's base `input()` implementation while leaving REPL line handling unchanged.
- [x] Updated `/tests/p2/smoke_compat.be` so `global`, `time`, `solidify`, and `strict` are exercised when present and skipped cleanly on the normal non-extended XMM profile. The normal profile still verifies the core, collections, bytes, closures/loops, `call()`, varargs, and `introspect` portions.
- [x] Rebuilt and flashed the normal XMM image with native sibling Catalina only: `make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2` built a `1023776 / 16777216` byte image, and `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0` installed it.
- [x] Hardware-verified on `/dev/ttyUSB0`: `/tests/p2/intro.be` passed `P2_SMOKE_PASS introspect`, `/tests/p2/ismeth.be` passed `P2_SMOKE_PASS introspect_ismethod`, `scripts/p2/repl_smoke.py --suite compat --timeout 420 --startup-timeout 120` passed including `print(input("P2_INPUT_PROMPT"))`, grouped P2 API still passed, and `soak-smartpins` still passed across jumper pairs `0-1`, `2-3`, `4-5`, and `6-7`.

### Priority 1 SD import/root verification and cache fallback

- [x] Fixed current-directory imports on the P2/Catalina build by letting `load_cwd()` fall back to a relative module filename when source-file debug paths are unavailable. This makes `import name` honor `os.chdir()` through the P2 SD path resolver instead of forcing `/<name>.be`.
- [x] Made the SD import/root smokes more hardware-safe: added stage markers, bounded metadata visibility waits after SD writes, and 8.3-safe staged module names where FAT aliases caused long-name collisions.
- [x] Corrected `/tests/p2/smoke_import_native_first.be` to check native module members through `introspect.contains()` instead of assuming native modules implement `contains()`.
- [x] Hardened `libstore.cached_source()` so reconstructed PSRAM source-cache text is checked against the recorded source hash; mismatches evict the cached item and return `nil` so callers can fall back to direct SD source instead of compiling corrupt cache bytes.
- [x] Hardware-verified the focused normal-XMM SD import/root path on `/dev/ttyUSB0` with short SD runners: `/tests/p2/ilayout.be`, `/tests/p2/infirst.be`, `/tests/p2/icwd.be`, `/tests/p2/iorder.be`, `/tests/p2/lpaths.be`, `/tests/p2/syspath.be` with expected normal-profile `sys` skip, `/tests/p2/pkgpath.be`, and `/tests/p2/sdmain.be` all passed.
- [x] Hardware-verified `/tests/p2/impcache.be` on `/dev/ttyUSB0` after the cache fallback change. The run reported `P2_SMOKE_STEP import_cache cache_rejected binary_heap`, evicted the bad PSRAM cache entry, cleaned up, and passed `P2_SMOKE_PASS import_cache`.
- [x] Focused local validation passed after these changes: `git diff --check`, bytecode compiles for the touched import/cache smokes and `modules/libstore.be`, `make test-p2-host`, and a native sibling Catalina XMM build/flash using `CATALINA_DIR=../Catalina`.

### Priority 1 configstore P2 FAT listing verification

- [x] Fixed `configstore.list()` to recognize P2/Catalina FAT directory entries that list `.json` files with the truncated `.JSO` extension, while preserving normal `.json` filtering.
- [x] Updated `/tests/p2/smoke_configstore.be` to use 8.3-safe temporary names, cover valid JSON `null`, and accept the observed P2 FAT `P2CFG.JSO` list entry without depending on long filename behavior.
- [x] Focused validation passed: `./berry -c modules/configstore.be -o /tmp/configstore.bec`, `./berry -c tests/p2/smoke_configstore.be -o /tmp/smoke_configstore.bec`, upload of `modules/configstore.be` and `/tests/p2/cfgstore.be`, cleanup of stale `p2cfg`, and `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/tests/p2/cfgstore.be")' --expect 'P2_SMOKE_PASS configstore' --timeout 240 --startup-timeout 120` on the normal XMM image.

### Priority 2 p2smart hardware examples

- [x] Added `examples/pwm_fade.be`, `examples/dac_write.be`, `examples/adc_read.be`, and `examples/uart_loopback.be` as small user-facing examples for the implemented `p2smart` PWM, DAC, ADC, and async serial wrappers. The examples default to the documented `0-1` jumper pair where a loopback/input is useful and clear/float their pins before exit.
- [x] Focused validation passed: `./berry -c examples/pwm_fade.be -o /tmp/pwm_fade.bec`, `./berry -c examples/dac_write.be -o /tmp/dac_write.bec`, `./berry -c examples/adc_read.be -o /tmp/adc_read.bec`, and `./berry -c examples/uart_loopback.be -o /tmp/uart_loopback.bec`.
- [x] Uploaded the four examples to `/berry/examples` and hardware-ran each once on `/dev/ttyUSB0` at `230400` baud with the normal XMM image: `/berry/examples/pwm_fade.be` reached `pwm fade done`, `/berry/examples/dac_write.be` reached `dac done`, `/berry/examples/adc_read.be` printed integer samples and reached `adc done`, and `/berry/examples/uart_loopback.be` printed raw loopback words for bytes 65, 66, and 67 before `uart loopback done`.
- [x] Added `examples/gpio_loopback.be` for the high-level `p2smart.GPIOOutput` / `GPIOInput` wrappers on the documented `0-1` jumper pair. It writes low/high patterns, reads the input side, exercises `toggle()`, and clears/floats both pins before exit.
- [x] Added `examples/nco_counter_loopback.be` for the high-level `p2smart.NCO` and `p2smart.Counter` wrappers on the documented `0-1` jumper pair. It starts an NCO output, samples rise counts, changes the NCO increment, and clears/floats both pins before exit.
- [x] Added `examples/cog_closure.be` under the expected top-level example name. It uses the currently supported `p2.cog.spawn(closure, pin, rate_ms)` native-blink shape on pins `38` and `39`, prints handle diagnostics, stops both handles, and floats both pins before exit.
- [x] Added `examples/cog_channel.be` using the current `p2ipc` channel API instead of the old `rtos.channel` wording. It demonstrates `send_result()`, full-channel diagnostics, `recv_result()`, empty-channel diagnostics, `close_result()`, and send-after-close diagnostics.
- [x] Added explicit unsupported VGA/USB capability records to `p2compat`: `video_output`, `vga_demo`, `usb_hid`, and `usb_demo`.
- [x] Added `examples/vga_test_pattern.be` and `examples/usb_keyboard_mouse.be` as honest unsupported examples that query `p2compat` and report the current no-backed-demo status instead of faking video or USB behavior.
- [x] Updated legacy `examples/p2/` blink and cog examples to compile against the current grouped APIs: `examples/p2/blink.be`, `examples/p2/pin_helpers.be`, and `examples/p2/closure_blinker.be` now use `p2.pin` / `p2.clock`, while `examples/p2/cog_spawn_source_blinker.be` checks `p2.cog.capabilities()["spawn_source"]` before attempting the experimental source-backed path.
- [x] Updated `docs/P2_SYSTEM_ROADMAP.md` and `docs/architecture-current.md` so their examples/current-state sections describe the active grouped APIs, `p2ipc` channels, cooperative `task` primitives, explicit unsupported VGA/USB examples, and the supported native-blink closure-cog shape instead of stale `p2.toggle`, `p2.cog.blinker`, `rtos`, or `taskspin` wording.
- [x] Updated `docs/P2_MODULES.md` task and `p2.cog` examples to use grouped `p2.pin` helpers and the supported `p2.cog.spawn(closure, pin, rate_ms)` native-blink shape instead of the removed `p2.cog.blinker` descriptor wording.

### Priority 2 p2smart quadrature wrapper

- [x] Added `p2smart.Quadrature` / `p2smart.quadrature(pin_a, pin_b, mode)` as a conservative quadrature smart-pin wrapper. It defaults to adjacent B-input selectors for `pin_b == pin_a +/- 1`, accepts an explicit selector override, exposes `start()`, `read()`, `position()`, `query()`, `ack()`, `clear()`, and `info()`, and clears/floats both pins on close.
- [x] Added `Quadrature.sample_after(wait_us)` result diagnostics with before/after position, signed delta, moved flag, direction, and wait interval. This improves static jumper and encoder probes without claiming real motion/direction validation is complete.
- [x] Expanded `tests/p2/host_p2smart.be` to verify quadrature class/factory shape, forward and reverse adjacent selectors, custom selector setup, generated raw smart-pin call sequences, read/query/ack/clear behavior, and invalid pin/mode diagnostics.
- [x] Added `examples/quadrature_counter.be`, a small example that opens quadrature mode on pins `0-1`, prints raw position samples, acknowledges samples, and clears the pins before exit.
- [x] Focused validation passed: `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, `./berry tests/p2/host_p2smart.be`, bytecode compiles for the updated import/cache shape smokes, and `./berry -c examples/quadrature_counter.be -o /tmp/quadrature_counter.bec`.
- [x] Uploaded `modules/p2smart.be` and `examples/quadrature_counter.be` to `/dev/ttyUSB0`, then hardware-ran `run_file("/berry/examples/quadrature_counter.be")`; it reported stable integer positions on the static `0-1` jumper and reached `quadrature counter done`.

### Priority 2 p2smart smart-pin constants

- [x] Expanded the `p2smart` fallback smart-pin constant table to preserve positive-valued Catalina `smartpin.h` names across selector bits, A/B filters, input/output drive options, DAC variants, NCO duty, PWM sawtooth/SMPS, register/counter/timer families, ADC external/scope variants, USB pair, and sync/async serial modes.
- [x] Extended `tests/p2/host_p2smart.be` to pin representative constant values through the `p2smart.smart` surface so host/fallback refactors cannot silently drop those names.
- [x] Focused validation passed: `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, `./berry tests/p2/host_p2smart.be`, and scoped `git diff --check`.

### Priority 2 p2smart NCO duty wrapper

- [x] Added setup-only `p2smart.NCODuty` / `p2smart.nco_duty(pin, bit_period, duty, mode)` for the Catalina `nco_duty` smart-pin mode. It validates pin/period/duty bounds, starts with `oe + nco_duty`, updates duty through `set_duty()`, exposes `info()`, and clears/floats the pin on close.
- [x] Extended `tests/p2/host_p2smart.be` to verify `NCODuty` class/factory shape, capability status, generated raw smart-pin setup/update/clear calls, status-report grouping, and invalid duty bounds. Hardware waveform validation remains open in `TODO.md`.
- [x] Focused validation passed: `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, `./berry tests/p2/host_p2smart.be`, and scoped `git diff --check`.

### Priority 2 p2smart DAC variant helpers

- [x] Added setup-only `p2smart.dac_mode(resistor, dither)` and `p2smart.dac_variant(pin, value, frame, resistor, dither)` helpers for named DAC mode setup. Supported names are `990r_3v`, `600r_2v`, `124r_3v`, `75r_2v`, `dither_pwm`, `dither_rnd`, `noise`, and `plain`.
- [x] Extended `tests/p2/host_p2smart.be` to verify named DAC mode words, generated `DAC` setup/clear calls for a non-default variant, capability/status-report grouping, and invalid resistor/dither diagnostics. Hardware variant calibration remains open in `TODO.md`.
- [x] Focused validation passed: `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, `./berry tests/p2/host_p2smart.be`, and scoped `git diff --check`.

### Priority 2 p2smart PWM mode helpers

- [x] Added setup-only `p2smart.pwm_mode(name)` and `p2smart.pwm_variant(pin, frame, duty, divisor, mode_name)` helpers for named PWM mode setup. Supported names are `triangle`, `sawtooth`, and `smps`; the existing `p2smart.pwm(...)` default remains triangle PWM.
- [x] Extended `tests/p2/host_p2smart.be` to verify named PWM mode words, generated `PWM` setup/clear calls for a non-default variant, capability/status-report grouping, and invalid mode diagnostics. Sawtooth/SMPS hardware waveform validation remains open in `TODO.md`.
- [x] Focused validation passed: `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, `./berry tests/p2/host_p2smart.be`, and scoped `git diff --check`.

### Priority 2 p2smart counter/timer mode helpers

- [x] Added setup-only `p2smart.counter_mode(name)` and `p2smart.counter_variant(pin, mode_name)` helpers for named counter/timer mode setup. Supported names cover register counters, rise/high counters, state/high/event timers, period timers, and counter timer modes.
- [x] Extended `tests/p2/host_p2smart.be` to verify named counter/timer mode words, generated `Counter` setup/ack/clear calls for a non-default variant, capability/status-report grouping, and invalid mode diagnostics. Broad timer/counter timing validation remains open in `TODO.md`.
- [x] Focused validation passed: `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, `./berry tests/p2/host_p2smart.be`, and scoped `git diff --check`.

### Priority 2 p2smart ADC mode helpers

- [x] Added setup-only `p2smart.adc_mode(source, family)` and `p2smart.adc_variant(pin, source, family, sample_ticks)` helpers for named ADC source/gain and family setup. Supported source/gain names are `1x`, `gio`, `vio`, `float`, `3x`, `10x`, `30x`, and `100x`; supported family names are `adc`, `adc_ext`, and `adc_scope`.
- [x] Extended `tests/p2/host_p2smart.be` to verify named ADC mode words, generated `ADC` setup/ack/clear calls for a non-default variant, capability/status-report grouping, and invalid source/family diagnostics. ADC variant calibration and filtering validation remain open in `TODO.md`.
- [x] Focused validation passed: `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, `./berry tests/p2/host_p2smart.be`, and scoped `git diff --check`.

### Priority 2 p2smart normal-pin wrapper

- [x] Added setup-only `p2smart.NormalPin` / `p2smart.normal_pin(pin, mode, value)` for explicit smart-pin normal-mode setup. It starts `smart.normal` by default, then uses the normal GPIO read/write/high/low/toggle helpers, and clears/floats the pin on close.
- [x] Extended `tests/p2/host_p2smart.be` to verify normal-mode setup, input-style floating start, output-style initial value, read/write/toggle/clear behavior, capability/status-report grouping, and invalid input diagnostics. Hardware loopback coverage remains with the existing verified GPIO wrapper smoke.
- [x] Focused validation passed: `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, `./berry tests/p2/host_p2smart.be`, and scoped `git diff --check`.

### Priority 2 p2smart synchronous serial wrapper

- [x] Added `p2smart.SyncSerialPair` / `p2smart.sync_serial_pair(tx_pin, rx_pin, baud, bits, tx_mode, rx_mode)` as a conservative wrapper for `sync_tx`/`sync_rx` smart-pin setup. It exposes `start()`, `send()`, `available()`, `read_raw()`, `ack()`, `clear()`, and `info()`, with clear/floating cleanup for both pins.
- [x] Added staged `transfer_result(value, wait_us, clock=nil)` and `transfer_results(values, wait_us, clock=nil)` diagnostics. They ack, send, optionally trigger a supplied `p2smart.Pulse` clock, wait/read through the existing result-shaped receive path, and report `sent`, `matched`, and `clocked` fields without claiming sync receive is hardware-validated.

### Priority 2 p2smart counter diagnostics

- [x] Added `p2smart.Counter.sample_after(wait_us)` for before/after counter sampling with `delta`, `advanced`, and `wait_us` result fields. This keeps NCO/PWM/pulse-to-counter probes result-shaped without claiming broader timer/counter timing validation.
- [x] Updated `examples/nco_counter_loopback.be` to print the new counter sample diagnostics instead of raw ad hoc reads, and pinned the capability as `counter_sample_diagnostics: diagnostic`.

### Priority 2 p2smart NCO diagnostics

- [x] Added `p2smart.NCO.set_increment_result(increment, settle_us=nil)` diagnostics. It updates the NCO increment, optionally waits for settling, and reports pin/bit-period/increment/mode plus settle metadata without claiming NCO-duty waveform validation.
- [x] Updated `examples/nco_counter_loopback.be` to print the NCO update result map and pinned the capability as `nco_increment_diagnostics: diagnostic`.
- [x] Added `p2smart.NCODuty.set_duty_result(duty, settle_us=nil)` diagnostics. It updates duty, optionally waits for settling, and reports pin/bit-period/duty/mode plus settle metadata while leaving waveform validation open.

### Priority 2 p2smart ADC diagnostics

- [x] Added `p2smart.ADC.read_result()` and `sample_after(wait_us)` diagnostics. They report ready/event state, raw/value sample, pin/mode/sample ticks, and delay metadata while keeping calibrated ADC scaling/filtering open.
- [x] Updated `examples/adc_read.be` to print the ADC sample result map instead of raw numbers, and pinned the capability as `adc_sample_diagnostics: diagnostic`.

### Priority 2 p2smart DAC diagnostics

- [x] Added `p2smart.DAC.set_result(value, settle_us=nil)` diagnostics. It writes the byte output, optionally waits for analog settling, and reports pin/mode/frame/value plus settle metadata without claiming DAC calibration.
- [x] Updated `examples/dac_write.be` to print DAC write result maps and pinned the capability as `dac_set_diagnostics: diagnostic`.

### Priority 2 p2smart PWM diagnostics

- [x] Added `p2smart.PWM.set_duty_result(duty, settle_us=nil)` diagnostics. It updates duty, optionally waits for settling, and reports pin/frame/duty/divisor/mode plus settle metadata without claiming sawtooth/SMPS validation.
- [x] Updated `examples/pwm_fade.be` to print PWM duty result maps and pinned the capability as `pwm_duty_diagnostics: diagnostic`.
- [x] Added `p2smart.Pulse.trigger_result(count, settle_us=nil)` and `p2smart.Transition.trigger_result(count, settle_us=nil)` diagnostics. They trigger the output, optionally wait, and report wrapper-specific timing/count metadata while keeping broader waveform validation open.

### Priority 2 p2smart repository diagnostics

- [x] Added `p2smart.Repository.write_result(value, settle_us=nil)` diagnostics. It writes the repository X register, optionally waits for settling, and reports pin/mode/value plus settle metadata.

### Priority 2 p2smart normal-pin diagnostics

- [x] Added `p2smart.NormalPin.read_result()` and `write_result(value)` diagnostics so explicit normal-mode smart-pin probes can report pin/mode/value maps while keeping the existing read/write/high/low/toggle helpers intact.
- [x] Expanded `tests/p2/host_p2smart.be` to verify synchronous serial class/factory shape, generated raw smart-pin setup/send/read/query/ack/clear behavior, and invalid pin/bit/send diagnostics. Updated the import/cache shape smokes to include `SyncSerialPair`.
- [x] Added `examples/spi_loopback.be`, a small synchronous-serial probe. It now uses `0-1` as data plus `2-3` as clock, sends three bytes, prints `available`/`raw` receive status, and clears all pins before exit.
- [x] Focused validation passed: `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, `./berry tests/p2/host_p2smart.be`, bytecode compiles for the updated import/cache shape smokes, and `./berry -c examples/spi_loopback.be -o /tmp/spi_loopback.bec`.
- [x] Uploaded `modules/p2smart.be` and the earlier `examples/spi_loopback.be` to `/dev/ttyUSB0`, then hardware-ran `run_file("/berry/examples/spi_loopback.be")`; it reached `spi loopback done`. The static `2-3` jumper run reported `available 0 raw 0` for the sent bytes, so this is setup/send/read surface verification, not received-data loopback validation. A later data/clock probe also failed before ready RX data.

### Priority 3 PASM SD blob loading

- [x] Added read-only PASM blob helpers to `libstore`: `pasm_load(name)` returns bytes from `/berry/pasm/*.bin`, `pasm_load_result(name)` returns found/path/data/size/hash/reason diagnostics, and `pasm_info(name)` now includes size/hash metadata while keeping `executable: false` and `reason: "pasm_execution_deferred"` for found blobs.
- [x] Hardened module-style path handling for PASM/app/example/source/compiled lookups so invalid names such as `bad/name`, leading/trailing dot names, and parent traversal do not resolve to arbitrary filesystem paths.
- [x] Focused validation passed: `./berry -c modules/libstore.be -o /tmp/libstore.bec`, `./berry -c tests/p2/smoke_pasm_layout.be -o /tmp/smoke_pasm_layout.bec`, refreshed `/modules/libstore.be` on SD with the native `/dev/ttyUSB0` uploader after an interrupted earlier upload, uploaded the short `/tests/p2/pasmly.be` smoke alias, and hardware-ran `run_file("/tests/p2/pasmly.be")` to `P2_SMOKE_PASS pasm_layout` on the normal XMM image.

### Priority 3 native `p2.asm.load()` facade

- [x] Added native `p2.asm.load(path)` to read a non-empty 4-byte-aligned PASM blob file into a Berry `bytes` object, with clear errors for missing, empty, unaligned, oversized, or short-read blobs.
- [x] Exposed the existing PASM cog primitive through the grouped facade as `p2.asm.cognew(blob, arg=nil, cog=nil)`, plus `p2.asm.cogstop(cog)` and `p2.asm.cogcheck(cog)`. This is API exposure over the existing native `_cogstart_PASM` path; arbitrary SD blob launch remains tracked in `TODO.md` until a public ABI contract and broader safe fixture coverage are verified.
- [x] Focused validation passed with native sibling Catalina only: `./berry -c tests/p2/smoke_pasm_layout.be -o /tmp/smoke_pasm_layout.bec`, `./berry -c modules/libstore.be -o /tmp/libstore.bec`, `make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2`, and `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0`, producing/flashing image `1025120 / 16777216` bytes.
- [x] Hardware-verified the updated PASM layout smoke on `/dev/ttyUSB0`: after uploading `/tests/p2/pasmly.be`, `run_file("/tests/p2/pasmly.be")` passed `P2_SMOKE_PASS pasm_layout` on the rebuilt XMM image and proved `p2.asm.load("/berry/pasm/pasm_probe.bin").asstring() == "PASM"` plus grouped PASM cog API shape.

### Priority 3 safe PASM launch probe

- [x] Added `p2.asm.launch_probe(target_cog=nil)`, a safe known-good PASM launch fixture that starts the existing mailbox-marker PASM program with `_cogstart_PASM`, waits for the marker and child cog id, stops the cog, and returns an `ok`/`marker_seen`/`cog_seen_matches`/`stopped` diagnostics map.
- [x] Extended `/tests/p2/smoke_pasm_layout.be` to verify `p2.asm.launch_probe()` succeeds, sees the marker, reports the child cog id consistently, stops the child cog, and leaves `p2.asm.cogcheck(cog) == 0`.
- [x] Focused validation passed with native sibling Catalina only: `./berry -c tests/p2/smoke_pasm_layout.be -o /tmp/smoke_pasm_layout.bec`, `./berry -c modules/libstore.be -o /tmp/libstore.bec`, `make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2`, and `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0`, producing/flashing image `1026336 / 16777216` bytes.
- [x] Hardware-verified the safe PASM launch probe on `/dev/ttyUSB0`: after uploading `/tests/p2/pasmly.be`, `run_file("/tests/p2/pasmly.be")` passed `P2_SMOKE_PASS pasm_layout` on the rebuilt XMM image. This proves the known-good launch/marker/stop path, not arbitrary SD blob launch.

### Priority 3 SD-loaded PASM marker fixture

- [x] Added `p2.asm.marker_blob()` to expose the known-good mailbox-marker PASM fixture as a Berry `bytes` object, and `p2.asm.launch_loaded_probe(blob, target_cog=nil)` to launch only that exact fixture bytes, wait for the marker/cog id, stop the cog, and report diagnostics. Non-matching blobs raise `value_error` instead of becoming an arbitrary runner.
- [x] Extended `/tests/p2/smoke_pasm_layout.be` to write `p2.asm.marker_blob()` to `/berry/pasm/pasm_marker.bin`, reload it through `p2.asm.load()`, and verify `p2.asm.launch_loaded_probe(loaded_blob)` reports `ok`, marker seen, cog id match, stopped, and `p2.asm.cogcheck(cog) == 0`.
- [x] Focused validation passed with native sibling Catalina only: `./berry -c tests/p2/smoke_pasm_layout.be -o /tmp/smoke_pasm_layout.bec`, `./berry -c modules/libstore.be -o /tmp/libstore.bec`, `make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2`, and `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0`, producing/flashing image `1028224 / 16777216` bytes.
- [x] Hardware-verified the SD-loaded PASM marker fixture on `/dev/ttyUSB0`: after uploading `/tests/p2/pasmly.be`, `run_file("/tests/p2/pasmly.be")` passed `P2_SMOKE_PASS pasm_layout` on the rebuilt XMM image. This proves write-to-SD, `p2.asm.load()`, exact-fixture launch, mailbox marker, and stop cleanup for the documented fixture.

### Priority 3 PASM ABI and capability diagnostics

- [x] Added `p2.asm.capabilities()` and `p2.asm.abi()` so Berry code can query the current PASM contract directly: safe intrinsics, SD blob loading, raw cog controls, marker probe, and exact SD-staged marker probe are available; arbitrary SD blob launch, function bridges, inline assembler, and unsafe assembly are reported unsupported.
- [x] Expanded `docs/pasm.md` and `docs/p2-api.md` so the documented PASM surface matches the current native facade, including `p2.asm.load()`, marker fixture launch probes, `capabilities()`, `abi()`, and the marker-fixture-only ABI fields. The docs keep arbitrary SD blob launch and PASM function bridges explicitly unsupported.

### Priority 4 cooperative task event diagnostics

- [x] Added `task.events()` for an isolated list of currently signaled event names and `task.clear_all()` for clearing scheduler event state.
- [x] Extended `tests/p2/host_task.be` to verify event snapshot isolation, per-event clear behavior, and clear-all cleanup without touching hardware scheduler paths.
- [x] Extended `/tests/p2/smoke_task.be` with the same event diagnostics and hardware-verified it on `/dev/ttyUSB0`: after uploading `modules/task.be` and `/tests/p2/smoke_task.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite task --timeout 180 --startup-timeout 120` passed `P2_SMOKE_PASS task` on the existing native-Catalina XMM image.

### Priority 4 cooperative task capability diagnostics

- [x] Added `task.capabilities()` so tooling can query the current cooperative/current-VM task contract without inferring from docs. The map reports cooperative scheduling, no preemption, no independent stacks, event diagnostics, lifecycle result diagnostics, wait descriptors, primitive families, and current P2 counter/attention availability.
- [x] Extended host, import-all, and P2 task smokes to assert the capability map and verify returned-map mutation does not affect later calls.
- [x] Hardware-verified the capability diagnostics on `/dev/ttyUSB0`: after uploading the updated `modules/task.be` and `/tests/p2/smoke_task.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite task --timeout 180 --startup-timeout 120` passed `P2_SMOKE_PASS task` on the existing native-Catalina XMM image.

### Priority 4 cooperative task lifecycle compatibility

- [x] Added `task.spin(id, fn, *args)` to the source-level cooperative scheduler. `id == -1` selects the first free slot; explicit `0..31` IDs start only when that fixed slot is free.
- [x] Added cooperative compatibility lifecycle names over the existing scheduler: `task.halt(handle)`, `task.hlt(handle)`, `task.cont(handle)`, `task.chk(handle)`, `task.id()`, and `task.tasks()`.
- [x] Extended `task.capabilities()` with `spin` and `spin2_lifecycle_names`, while keeping the contract explicit that this is cooperative/current-VM and not preemptive or stackful.
- [x] Focused validation passed: `./berry tests/p2/host_task.be`, `./berry -c modules/task.be -o /tmp/task.bec`, `./berry -c tests/p2/smoke_task.be -o /tmp/smoke_task.bec`, and `./berry -c tests/p2/smoke_import_all_libs.be -o /tmp/smoke_import_all_libs.bec`.
- [x] Hardware-verified the lifecycle compatibility names on `/dev/ttyUSB0`: after uploading updated `modules/task.be` and `/tests/p2/smoke_task.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite task --timeout 180 --startup-timeout 120` passed `P2_SMOKE_PASS task` on the existing native-Catalina XMM image.

### Priority 4 cooperative task attention wakeup

- [x] Extended `tests/p2/host_task.be` to verify that `task.signal("attention")` wakes a cooperative task waiting on `task.wait("attention")`.
- [x] Extended `/tests/p2/smoke_task.be` to verify the P2 hardware path: a task waits on `attention`, the smoke calls `p2.cog.attention(1 << p2.cog.id())`, and the scheduler wakes the task through `_poll_attention()` / `task.woke_by_event("attention")`.
- [x] Extended both host and P2 task smokes to repeat the attention wake path three times, proving the cooperative event/attention path can be reused rather than only triggered once.
- [x] Focused validation passed: `./berry tests/p2/host_task.be`, `./berry -c modules/task.be -o /tmp/task.bec`, and `./berry -c tests/p2/smoke_task.be -o /tmp/smoke_task.bec`.
- [x] Hardware-verified the attention wakeup path on `/dev/ttyUSB0`: after uploading updated `/tests/p2/smoke_task.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite task --timeout 180 --startup-timeout 120` passed `P2_SMOKE_PASS task`.
- [x] Extended `/tests/p2/smoke_pasm_layout.be` to assert the new diagnostic functions and key marker-fixture-only ABI fields.
- [x] Focused validation passed with native sibling Catalina only: `./berry -c tests/p2/smoke_pasm_layout.be -o /tmp/smoke_pasm_layout.bec`, `./berry -c modules/libstore.be -o /tmp/libstore.bec`, `make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2`, and `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2 PORT=/dev/ttyUSB0`, producing/flashing image `1030368 / 16777216` bytes.
- [x] Hardware-verified `/tests/p2/pasmly.be` on `/dev/ttyUSB0` with `run_file("/tests/p2/pasmly.be")`; it passed `P2_SMOKE_PASS pasm_layout` on the rebuilt XMM image.

### Priority 2 async smart-pin RX readback

- [x] Added `/tests/p2/smoke_smartpins_async_rx.be`, a focused hardware smoke for `p2smart.AsyncSerialPair.read_byte()` on the physically jumped `0-1`, `2-3`, `4-5`, and `6-7` pairs in both directions.
- [x] Adjusted `p2smart.AsyncSerialPair.clear()` to detach TX/RX smart-pin mode with direct `wrpin`/`wxpin`/`wypin` register clears instead of the shared GPIO reset path that can hang after async receive reads.
- [x] Updated `tests/p2/host_p2smart.be` so the fake `p2.smart` backend exposes grouped `wrpin` and asserts `AsyncSerialPair.clear()` uses the direct-register cleanup sequence.
- [x] Added `p2smart.AsyncSerialPair.read_byte_after(wait_us)` for bounded delayed reads; host fake coverage asserts it calls `waitus` before `rdpin`.
- [x] The smoke proves byte receive plus wrapper cleanup for `0x00`, `0x55`, `0xa5`, and `0xff` on all four jumper pairs in both directions. The broader setup/query/ack coverage remains in `/tests/p2/smoke_smartpins_loopback.be`; `0x00` readiness/event semantics remain intentionally separate because `available()` returns an ambiguous zero event value for a zero byte.
- [x] Focused validation passed: `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, `./berry -c tests/p2/smoke_smartpins_loopback.be -o /tmp/smoke_smartpins_loopback.bec`, and `./berry -c tests/p2/smoke_smartpins_async_rx.be -o /tmp/smoke_smartpins_async_rx.bec`.
- [x] Hardware-verified `/tests/p2/smoke_smartpins_async_rx.be` on `/dev/ttyUSB0` with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite smartpins-async-rx --timeout 260 --startup-timeout 120`; it passed `P2_SMOKE_PASS smartpins_async_rx` on the existing native-Catalina XMM image and printed readback for `0->1`, `1->0`, `2->3`, `3->2`, `4->5`, `5->4`, `6->7`, and `7->6` across `0x00`, `0x55`, `0xa5`, and `0xff`.

### Priority 2 async smart-pin RX result semantics

- [x] Added `p2smart.AsyncSerialPair.read_result()` for readiness-query reads. It returns an isolated result map with `ready`, `event`, `raw`, and decoded byte `value`, preserving `nil` for `value` when no event is reported.
- [x] Added `p2smart.AsyncSerialPair.read_result_after(wait_us)` for timed async RX samples. It waits, reads `rdpin` directly without querying `rqpin` first, and returns `ready=true`, `event=nil`, `raw`, decoded `value`, and `delayed`, which avoids the valid-zero-byte ambiguity in `available()`.
- [x] Extended `tests/p2/host_p2smart.be` to cover not-ready result maps, ready byte-zero result maps, delayed nonzero reads, and delayed zero-byte reads.
- [x] Extended `/tests/p2/smoke_smartpins_async_rx.be` to verify result-shaped reads on jumper pairs `0-1`, `2-3`, `4-5`, and `6-7` in both directions. Hardware output showed forward zero-byte raw words of `0` and reverse zero-byte raw words of `4194304`, while decoded `value` remained `0`; the documented byte contract is therefore `value`, not raw-word equality.
- [x] Focused validation passed: `./berry tests/p2/host_p2smart.be`, `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, `./berry -c tests/p2/smoke_smartpins_async_rx.be -o /tmp/smoke_smartpins_async_rx.bec`, and `./berry -c tests/p2/smoke_import_all_libs.be -o /tmp/smoke_import_all_libs.bec`.
- [x] Hardware-verified the result-shaped async RX semantics on `/dev/ttyUSB0`: after uploading updated `modules/p2smart.be` and `/tests/p2/smoke_smartpins_async_rx.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite smartpins-async-rx --timeout 260 --startup-timeout 120` passed `P2_SMOKE_PASS smartpins_async_rx` on the existing native-Catalina XMM image.

### Priority 2 async smart-pin paced byte-list helpers

- [x] Added `p2smart.AsyncSerialPair.send_bytes(values, inter_byte_us)` to validate and send byte lists with an optional inter-byte delay.
- [x] Added `p2smart.AsyncSerialPair.exchange_bytes_after(values, wait_us)` and `exchange_results_after(values, wait_us)` for paced one-byte-at-a-time loopback/protocol checks on top of the verified timed result path. These helpers are not a claim of a receive FIFO.
- [x] Extended `tests/p2/host_p2smart.be` to verify generated send/wait/read call sequences, invalid byte diagnostics, zero-byte result preservation, and returned byte/result lists.
- [x] Extended `/tests/p2/smoke_smartpins_async_rx.be` to hardware-verify `exchange_bytes_after([0x00, 0x55, 0xa5, 0xff], 2000)` on `0->1` and `exchange_results_after(...)` on `1->0`, while retaining the all-pair/all-direction single-byte coverage.
- [x] Focused validation passed: `./berry tests/p2/host_p2smart.be`, `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, and `./berry -c tests/p2/smoke_smartpins_async_rx.be -o /tmp/smoke_smartpins_async_rx.bec`.
- [x] Hardware-verified the paced byte-list helpers on `/dev/ttyUSB0`: after uploading updated `modules/p2smart.be` and `/tests/p2/smoke_smartpins_async_rx.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite smartpins-async-rx --timeout 260 --startup-timeout 120` passed `P2_SMOKE_PASS smartpins_async_rx`.

### P2 Catalina documentation cleanup

- [x] Re-audited active P2 build instructions for stale Catalina examples. `AGENTS.md`, `mk/toolchain-catalina.mk`, `docs/building.md`, `docs/P2_BUILD.md`, and `README.md` now point normal P2 builds at the sibling native Catalina checkout with `CATALINA_DIR=../Catalina`.
- [x] Removed active README guidance that listed a managed Catalina cache or `/opt/catalina` as the normal P2 Catalina path; `.third_party_cache` is now described only for loader tooling such as FlexProp/loadp2.
- [x] Focused validation for this docs-only cleanup passed with `rg` scans for `CATALINA_USE_DOCKER`, Docker-Catalina paths, `.third_party_cache/catalina`, and `/opt/catalina` across active build docs/tooling, plus `git diff --check`.

### Priority 2 p2smart capability diagnostics

- [x] Added `p2smart.capabilities()` so smart-pin wrapper support status is queryable instead of inferred from docs. The map marks backed wrapper families as `verified`, ADC/DAC and quadrature as setup/readback or setup-only, synchronous serial receive and ADC/DAC delta as `unverified`, and true async buffering plus USB pair support as `unsupported`.
- [x] Added `p2smart.status_report()` to group the same support facts into `verified`, `staged`, `open`, and `capabilities` fields for diagnostic use.
- [x] Extended `tests/p2/host_p2smart.be` and `/tests/p2/smoke_import_all_libs.be` to assert the diagnostic map, unsupported/unverified statuses, and returned-map mutation isolation.
- [x] Focused validation passed: `./berry tests/p2/host_p2smart.be`, `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, and `./berry -c tests/p2/smoke_import_all_libs.be -o /tmp/smoke_import_all_libs.bec`.

### Priority 2 ADC/DAC jumper diagnostic probe

- [x] Added `p2smart.dac_adc_probe(out_pin, in_pin, low_value, high_value, settle_us, threshold)` as a result-shaped DAC-to-ADC diagnostic helper. It starts an `ADC` and `DAC`, samples low/high raw ADC values, reports signed `delta`, `abs_delta`, threshold, `ok`, and `reason`, then clears both pins.
- [x] The helper intentionally uses absolute delta for `ok` because observed DAC-to-ADC direction can be negative under the current mode/board setup; calibrated voltage polarity remains open.
- [x] Extended `tests/p2/host_p2smart.be` to cover successful and below-threshold probe maps, generated call sequence, cleanup, and invalid argument diagnostics. `/tests/p2/smoke_import_all_libs.be` now checks the helper is exported.
- [x] Focused validation passed: `./berry tests/p2/host_p2smart.be`, `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, and `./berry -c tests/p2/smoke_import_all_libs.be -o /tmp/smoke_import_all_libs.bec`.
- [x] Hardware-probed `p2smart.dac_adc_probe(0, 1, 0, 255, 5000, 1)` on `/dev/ttyUSB0` with the existing `0-1` jumper. It returned `ADCPROBE true 2 0 -2 nil`, proving the diagnostic helper reports a measurable absolute delta while preserving signed raw direction.
- [x] Added repeatable `/tests/p2/smoke_smartpins_loopback.be` coverage for `p2smart.dac_adc_probe(0, 1, 0, 255, 5000, 1)` and hardware-verified the focused `smartpins-loopback` suite on `/dev/ttyUSB0`. In the full loopback smoke context it reported `P2_SMOKE_ADC_PROBE true 0 2 2 2` before passing `P2_SMOKE_PASS smartpins_loopback`.

### Priority 2 sync serial probe

- [x] Updated `p2smart.SyncSerialPair` defaults to include the ROM-documented `sync_io` smart-pin mode bit for both sync TX and sync RX; host fake coverage now asserts the generated raw setup modes include `sync_io`.
- [x] Hardware-probed sync receive on `/dev/ttyUSB0` without broad regression reruns. A two-pin jumper path still reported no data, and a four-pin data/clock probe using `0-1` for data plus `2-3` for clock also failed before ready RX data. This is recorded as an honest staged gap, not claimed support.

### Priority 4 cooperative Queue result diagnostics

- [x] Added `task.Queue.put_result(value)` and `task.Queue.get_result()` so callers can distinguish full queues, empty queues, and queued `nil` payloads without changing the existing `put`/`get` contracts.
- [x] Extended focused host and P2 task smoke coverage for full result maps, nil-payload retrieval, and empty result maps.

### Priority 2 sync serial result diagnostics

- [x] Added `p2smart.SyncSerialPair.read_result()` and `read_result_after(wait_us)` so staged sync serial receive probes report ready/not-ready state, raw value, error name, and message in a stable result map.
- [x] Added `sync_serial_result_diagnostics` to `p2smart.capabilities()` / `status_report()` as staged support while keeping `sync_serial_receive` unverified.
- [x] Added a focused `/tests/p2/smoke_smartpins_sync_diag.be` hardware smoke and `smartpins-sync-diag` runner suite for this diagnostic helper without running the full smart-pin matrix.

### Priority 2 direct cog attention validation

- [x] Extended `/tests/p2/smoke_p2_api.be` to clear pending attention, signal the current cog with `p2.cog.attention(1 << p2.cog.id())`, and verify `p2.cog.poll_attention()` reports the expected bit. This proves direct nonblocking attention delivery without exercising blocking `wait_attention()`.

### Priority 2 p2smart status-report consistency

- [x] Added `p2smart.items_by_status(status)` so callers can query capability names by status without hand-filtering the full map.
- [x] Reworked `p2smart.status_report()` so `verified`, `staged`, and `open` lists are derived from `capabilities()` rather than maintained as a second drift-prone status table.
- [x] Extended focused host/import coverage for status-name queries, report list membership, and returned-list mutation isolation.

### Priority 2 p2smart status vocabulary diagnostics

- [x] Added `p2smart.statuses()` and `p2smart.status_known(status)` so tooling can discover and validate the capability-status vocabulary.
- [x] Tightened `p2smart.items_by_status(status)` to reject unknown status names instead of silently returning an empty list for typos.
- [x] Extended focused host/import coverage for status vocabulary discovery, unknown-status rejection, and returned status-list mutation isolation.

### Priority 2 p2smart capability name diagnostics

- [x] Added `p2smart.names()` and `p2smart.names_by_status(status)` so tooling can enumerate all smart-pin capability names or filter them by validated status without parsing map keys directly.
- [x] Extended focused host/import coverage for all-name lists, filtered-name lists, unknown-status rejection, and returned-list mutation isolation.

### Priority 2 p2smart capability metadata audit

- [x] Added `p2smart.audit()`, `p2smart.audit_problems()`, and `p2smart.audit_ok()` so tooling and smokes can verify capability metadata consistency without duplicating checks.
- [x] The audit reports duplicate capability names, unknown capability statuses, per-status counts, and total count consistency.
- [x] Extended focused host/import coverage for clean audit results, count consistency, and returned problem-list mutation isolation.

### Priority 4 cooperative task 32-slot limit

- [x] Raised the source-level cooperative scheduler from 16 to 32 fixed slots by setting `task.MAX_TASKS = 32`.
- [x] Added `max_tasks` to `task.capabilities()` and updated host/P2 smoke assertions so both `task.info()` and `task.capabilities()` report `32`.
- [x] The existing host capacity regression now fills all 32 slots, verifies first-free handle ordering, verifies slot exhaustion diagnostics, and frees every slot.
- [x] Hardware-probed the uploaded SD source module directly on `/dev/ttyUSB0`: `t=run_file("/modules/task.be"); print(t.info()["max_tasks"], t.capabilities()["max_tasks"])` returned `32 32`. The default native `import task` compatibility path still reports its native 16-slot limit and remains covered by `/tests/p2/smoke_task.be`.

### Priority 4 cooperative primitive result diagnostics

- [x] Added `task.Semaphore.take_result()` / `give_result()` so callers can distinguish successful takes/gives from unavailable zero-count semaphores without changing the legacy boolean helpers.
- [x] Added `task.Mutex.lock_result()` / `unlock_result()` so callers can distinguish acquired, busy, unlocked, and not-locked states without changing the legacy boolean helpers.
- [x] Extended focused host and source task smoke coverage for Semaphore unavailable/give diagnostics and Mutex busy/not-locked diagnostics.
- [x] Hardware-probed the uploaded SD source module directly on `/dev/ttyUSB0`: a one-line `run_file("/modules/task.be")` check returned `true unavailable true true` for Semaphore take/unavailable and Mutex lock/unlock result helpers.

### Priority 4 EventFlags and Timer result diagnostics

- [x] Added `task.EventFlags.set_result(mask)` and `clear_result(mask)` so callers can distinguish successful flag updates from invalid-mask no-ops without changing `set()` / `clear()`. A direct `/dev/ttyUSB0` source-module probe returned `true 6 invalid_mask 2 invalid_mask` for set/set-invalid/clear/clear-invalid result paths.
- [x] Added `task.EventFlags.ready_result(mask, mode)` so callers can distinguish ready, not-ready, and invalid-mask states without changing `ready()` / `wait()`.
- [x] Added `task.Timer.expired_result()`, `cancel_result()`, and `restart_result()` so callers can inspect not-expired, fired, rearmed/deactivated, cancelled, and restarted states without changing the legacy boolean helpers.
- [x] Extended focused host and source task smoke coverage for EventFlags set/clear/ready/not-ready/invalid-mask diagnostics and Timer not-expired/cancel/restart/zero-period-expired diagnostics.
- [x] Hardware-probed the uploaded SD source module directly on `/dev/ttyUSB0`: a one-line `run_file("/modules/task.be")` check returned `true not_ready invalid_mask true false` for EventFlags ready/not-ready/invalid-mask and Timer zero-period expired/deactivated result helpers.

### Priority 4 primitive capability diagnostics

- [x] Added `task.primitive_capabilities()` so tooling can query the supported cooperative primitive families and result-shaped helper methods without scraping docs or instantiating each primitive.
- [x] Extended focused host and source task smoke coverage for primitive capability flags and returned-map mutation isolation.
- [x] Hardware-probed the uploaded SD source module directly on `/dev/ttyUSB0`: `task.primitive_capabilities()` returned `true true true` for Semaphore take-result, EventFlags set-result, and Timer restart-result flags.

### Priority 4 task execution-model diagnostics

- [x] Added `task.execution_model()` so tooling can query that the current scheduler is cooperative, current-VM, callback-step based, not preemptive, not stackful, and not true Spin2 task switching.
- [x] Extended focused host and source task smoke coverage for execution-model fields and returned-map mutation isolation.
- [x] Hardware-probed the uploaded SD source module directly on `/dev/ttyUSB0`: `task.execution_model()` returned `cooperative_step true false false false` for model/callback-step/preemptive/stackful/true-Spin2 flags.

### Priority 3 PASM fixture rejection guard

- [x] Extended `/tests/p2/smoke_pasm_layout.be` so `p2.asm.launch_loaded_probe(blob)` must reject a staged non-marker PASM blob instead of treating any SD-loaded bytes as launchable.
- [x] Updated `docs/pasm.md`, `docs/coverage-matrix.md`, and `port/p2/TODO.md` to keep the supported PASM launch policy explicit: only the exact marker fixture is supported; arbitrary SD PASM launch remains open.

### Priority 2 p2smart direct status lookup

- [x] Added `p2smart.status(name)` so tooling can query one smart-pin capability name directly and receive its exact status string, or `nil` for unknown/non-string names.
- [x] Extended `tests/p2/host_p2smart.be` to pin direct lookup for verified, setup-only, unverified, unsupported, unknown, and non-string capability names.
- [x] Extended `/tests/p2/smoke_import_all_libs.be` to assert the direct status lookup export and representative verified/unverified/unsupported values during SD import coverage.
- [x] Updated smart-pin docs and coverage/TODO notes while keeping unsupported and unverified wrapper areas explicit.

### Priority 4 task direct capability lookup

- [x] Added `task.capability(name)` and `task.primitive_capability(name)` so tooling can query one cooperative scheduler or primitive capability value without copying and filtering the full diagnostic maps.
- [x] Extended `tests/p2/host_task.be` and `/tests/p2/smoke_task.be` to cover true, false, numeric, unknown, and non-string direct lookup cases.
- [x] Extended `/tests/p2/smoke_import_all_libs.be` to assert the direct lookup exports and representative native task capability values during SD import coverage.
- [x] Updated task docs, coverage matrix, and TODO notes while keeping the independent-stack/real-VM task work explicitly open.
- [x] Corrected the task documentation example to use the active grouped GPIO API (`p2.pin.dir_high()` / `p2.pin.toggle()`) instead of the stale flat `p2.toggle()` call.
- [x] Added `examples/task_primitives.be` as a small cooperative primitive example for Queue result diagnostics including nil payloads, EventFlags set/ready/clear diagnostics, and Timer expired/restart/cancel diagnostics.

### Priority 4 p2ipc capability diagnostics

- [x] Added `p2ipc.capabilities()` and `p2ipc.capability(name)` so tooling can query the current IPC contract directly: current-VM channel/mailbox/mutex/shared-buffer helpers, result diagnostics, nil-payload result handling, close diagnostics, optional hardware-lock backend, fallback mutexes, and no cross-VM support.
- [x] Extended `tests/p2/host_p2ipc.be` to pin capability-map isolation, direct lookup behavior, hardware-lock-backend detection, fallback mutex reporting, unknown names, and non-string lookup.
- [x] Extended `/tests/p2/smoke_import_all_libs.be` to assert the new p2ipc diagnostic functions and key current-VM/cross-VM capability values during import coverage.

### Priority 4 p2ipc close-result hardware diagnostics

- [x] Fixed `p2ipc.Mutex.close_result()` so it preserves the pre-close hardware-lock flag and previous lock id in the returned diagnostic map instead of always reporting `hardware: false` after `close()` releases the lock.
- [x] Extended `tests/p2/host_p2ipc.be` to cover hardware-backed and fallback mutex close-result diagnostics.

### Priority 4 p2ipc channel/mailbox close diagnostics

- [x] Added `close_result()` to `p2.channel` and `p2.mailbox` objects so all closable p2ipc primitives now have result-shaped close diagnostics.
- [x] Channel close diagnostics report `ok`, `closed`, `was_closed`, `depth`, `size`, `free`, previous `lock_id`, and previous `hardware_lock`; mailbox close diagnostics report `ok`, `closed`, `was_closed`, `ready`, previous `lock_id`, and previous `hardware_lock`.
- [x] Extended `tests/p2/host_p2ipc.be` to cover first-close and repeated-close result maps for both channel and mailbox objects.
- [x] Extended `/tests/p2/smoke_import_all_libs.be` to assert the close-result capability flag and method shape for fresh channel/mailbox objects during safe import coverage.
- [x] Extended `/tests/p2/smoke_libraries.be` to use channel/mailbox `close_result()` and assert first-close plus repeated-close result semantics.

### Priority 1 configstore capability diagnostics

- [x] Added `configstore.capabilities()` and `configstore.capability(name)` so tooling can query JSON config-file support, filename-only validation, root creation, result-helper availability, JSON-null detection, FAT `.JSO` listing support, and the active config root.
- [x] Extended `tests/p2/host_source_modules.be` to cover capability-map isolation, direct lookup, unknown/non-string lookup, and root reflection after changing `configstore.root`.
- [x] Extended `/tests/p2/smoke_configstore.be` to assert capability-map isolation and direct lookup during the dedicated configstore smoke.
- [x] Extended `/tests/p2/smoke_import_all_libs.be` to assert the new configstore diagnostic functions and representative capability values during safe import coverage.
- [x] Extended `/tests/p2/smoke_libraries.be` with metadata-only configstore capability checks, avoiding config file writes in the broader libraries smoke.

### Priority 2 p2smart GPIO diagnostics

- [x] Added `GPIOInput.read_result()`, `GPIOOutput.write_result(value)`, and `GPIOOutput.toggle_result()` so GPIO wrapper probes can return result-shaped maps without parsing side effects.
- [x] Added `p2smart.gpio_loopback_probe(out_pin, in_pin, values, settle_us)` for output-to-input jumper diagnostics with validated bit patterns, optional settle delay, per-sample result maps, and cleanup of both pins.
- [x] Added `gpio_diagnostics` and `gpio_loopback_probe` to `p2smart.capabilities()` and extended focused host/import smoke coverage plus smart-pin status docs.
- [x] Updated `/tests/p2/smoke_smartpins_loopback.be` so the existing GPIO jumper cases exercise `p2smart.gpio_loopback_probe(...)` while preserving explicit toggle-result readback coverage.

### Priority 2 p2smart PWM counter diagnostics

- [x] Added `p2smart.pwm_counter_probe(out_pin, in_pin, frame, duty, divisor, settle_us)` for PWM-output to rise-counter jumper diagnostics using the existing `PWM` and `Counter.sample_after()` wrappers.
- [x] Added `pwm_counter_probe` to `p2smart.capabilities()` and updated focused host/import coverage, smart-pin docs, and the smartpins loopback smoke's PWM cases to exercise the helper.

### Priority 2 p2smart NCO counter diagnostics

- [x] Added `p2smart.nco_counter_probe(out_pin, in_pin, bit_period, increment, settle_us)` for NCO-output to rise-counter jumper diagnostics using the existing `NCO` and `Counter.sample_after()` wrappers.
- [x] Added `nco_counter_probe` to `p2smart.capabilities()` and updated focused host/import coverage, smart-pin docs, and the smartpins loopback smoke's NCO cases to exercise the helper.

### Priority 2 p2smart pulse and transition counter diagnostics

- [x] Added `p2smart.pulse_counter_probe(out_pin, in_pin, high_ticks, low_ticks, count, settle_us)` and `p2smart.transition_counter_probe(out_pin, in_pin, width, count, settle_us)` for output-to-rise-counter jumper diagnostics using the existing pulse/transition wrappers and `Counter.sample_after()`.
- [x] Added `pulse_counter_probe` and `transition_counter_probe` to `p2smart.capabilities()` and updated focused host/import coverage, smart-pin docs, and the smartpins loopback smoke's pulse/transition cases to exercise the helpers.

### Priority 2 p2smart high-counter diagnostics

- [x] Added `p2smart.high_counter_probe(out_pin, in_pin, high_us, settle_us)` for GPIO-high to count-highs jumper diagnostics with output write result maps, before/after counter data, and cleanup of both pins.
- [x] Added `high_counter_probe` to `p2smart.capabilities()` and updated focused host/import coverage, smart-pin docs, and the smartpins loopback smoke's high-counter cases to exercise the helper.

### Priority 2 p2smart repository diagnostics

- [x] Added `Repository.read_result()` and `p2smart.repository_probe(pin, first_value, second_value, settle_us)` for result-shaped repository-mode start/read/write/read/clear diagnostics.
- [x] Added `repository_read_diagnostics` and `repository_probe` to `p2smart.capabilities()` and updated focused host/import coverage, smart-pin docs, and the smartpins loopback smoke's repository cases to exercise the helper.

### Priority 2 p2smart async serial probe diagnostics

- [x] Added `p2smart.async_serial_probe(tx_pin, rx_pin, values, wait_us, baud, bits)` for conservative async serial send/query/ack/clear jumper diagnostics without claiming buffered receive semantics.
- [x] Added `async_serial_probe` to `p2smart.capabilities()` and updated focused host/import coverage, smart-pin docs, and the smartpins loopback smoke's async serial cases to exercise the helper.
- [x] Tightened `p2smart.AsyncSerialPair.clear()` so async TX/RX cleanup now matches the raw/sync cleanup pattern: clear both smart pins and float both pins, with focused host call-sequence coverage updated.
- [x] Added staged `p2smart.sync_serial_probe(tx_pin, rx_pin, values, wait_us, baud, bits)` for sync-serial start/transfer/clear diagnostics without promoting sync receive to verified.
- [x] Added staged `p2smart.sync_serial_clocked_probe(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin, values, wait_us, baud, bits)` for data/clock jumper diagnostics such as data `0-1` plus clock `2-3`, and updated the SPI/sync example to use it directly.
- [x] Tightened serial probe validation so async, sync, and clocked sync probes reject empty value lists instead of returning zero-transfer success diagnostics.
- [x] Tightened `p2smart.sync_serial_clocked_probe(...)` setup so the clock receive pin is floated before the clock output starts, not only during cleanup.
- [x] Added summary counters to serial probe diagnostics: async probes now report `ready_count`, and sync probes report `ready_count` plus `matched_count`.

### Priority 2 p2smart DAC/ADC smoke consolidation

- [x] Updated `/tests/p2/smoke_smartpins_loopback.be` so the per-pair DAC/ADC setup/readback cases use `p2smart.dac_adc_probe(..., threshold=0)` instead of duplicating ADC/DAC start/read/set/clear logic, while preserving the separate measurable-delta assertion for the dedicated `0-1` probe.

### Priority 2 p2smart raw helper diagnostics

- [x] Added `p2smart.raw_smartpin_probe(pin)` for result-shaped raw smart-pin helper diagnostics over zeroed `wrpin`/`wxpin`/`wypin`, `akpin`, `rdpin`, `rqpin`, normal-mode `start`, and `clear`.
- [x] Added `raw_smartpin_probe` to `p2smart.capabilities()` and updated focused host/import coverage, smart-pin docs, and the smartpins loopback smoke's raw helper cases to exercise the helper.
- [x] Tightened `p2smart.raw_smartpin_probe(pin)` cleanup so it explicitly floats the pin after clearing smart-pin mode.

### Priority 2 p2smart NCO example alignment

- [x] Updated `examples/nco_counter_loopback.be` to demonstrate `p2smart.nco_counter_probe(...)` directly for fast and slower NCO settings instead of manually wiring an `NCO` and `Counter`.
- [x] Updated `examples/uart_loopback.be` to demonstrate `p2smart.async_serial_probe(...)` directly instead of manually starting, sending, querying, acknowledging, and clearing an async serial pair.
- [x] Removed stale direct `p2` imports from smartpin examples that now only use `p2smart`: `adc_read.be`, `dac_write.be`, `pwm_fade.be`, `quadrature_counter.be`, and `spi_loopback.be`.

### Priority 2 p2smart diagnostics example

- [x] Added `examples/smartpin_diagnostics.be` as a compact `0-1` jumper example for `raw_smartpin_probe`, `repository_probe`, `high_counter_probe`, `pulse_counter_probe`, and `transition_counter_probe`.
- [x] Updated `docs/coverage-matrix.md` so current top-level example coverage includes `smartpin_diagnostics.be` and the raw/repository/high-counter/pulse-counter/transition-counter probe helpers it demonstrates.
- [x] Updated `docs/architecture-current.md` so its current examples summary includes the smart-pin diagnostics example.
- [x] Updated the high-level hardware wrapper row in `docs/coverage-matrix.md` so it records the current result-shaped `p2smart` probe helpers instead of only the base wrapper families.
- [x] Updated `docs/sd-layout.md` so the `/berry/examples` helper documentation names `run_example("smartpin_diagnostics")` as a concrete staged-example target.
- [x] Updated `docs/P2_LAYOUT.md` so the examples layout note covers top-level P2 hardware examples such as `examples/smartpin_diagnostics.be`, not only module subdirectories.
- [x] Updated `docs/P2_BUILD.md` so the smoke-suite coverage list includes smart-pin loopback diagnostics for the documented jumper pairs.

### Priority 2 p2smart jumper-pair diagnostics

- [x] Added `p2smart.jumper_pair_probe(out_pin, in_pin)` as a compact diagnostic bundle for one physically jumped pair, composing raw helper probes on both pins plus GPIO loopback, high-counter, pulse-counter, transition-counter, and async serial setup/query diagnostics.
- [x] Added `jumper_pair_probe` to `p2smart.capabilities()` and updated focused host coverage, smart-pin docs, and `examples/smartpin_diagnostics.be`.
- [x] Extended `p2smart.jumper_pair_probe(out_pin, in_pin)` summaries with `failed_count` and `failed_checks` so hardware output identifies which sub-check failed.
- [x] Hardened `p2smart.jumper_pair_probe(out_pin, in_pin)` so a raised sub-check returns an error result for that check and the remaining sub-checks continue to run.
- [x] Tightened the resilient `jumper_pair_probe(...)` path so after any raised sub-check it clears and floats both jumper pins before continuing with the next diagnostic.
- [x] Added `cleanup_attempted` to resilient `jumper_pair_probe(...)` sub-check error maps so hardware diagnostics show recovery was attempted before continuing.
- [x] Added `p2smart.jumper_pairs_probe(pairs)` to aggregate jumped-pair diagnostics across lists such as `[[0, 1], [2, 3], [4, 5], [6, 7]]`, with summary `count` and `ok_count` fields.
- [x] Tightened `p2smart.jumper_pairs_probe(pairs)` validation so it normalizes returned pair records, rejects invalid pins, and rejects same-pin pairs before dispatching the per-pair probe.
- [x] Extended `p2smart.jumper_pairs_probe(pairs)` summaries with `failed_count` and `failed_pairs` so hardware output identifies which jumped pair failed.
- [x] Extended `p2smart.jumper_pairs_probe(pairs)` summaries with per-pair `failures` records containing the failed pair and that pair's failed sub-check names.
- [x] Extended aggregate jumper `failures` records with the failed pair's `ok_count` and `failed_count` so serial summaries show how much of that pair passed.
- [x] Hardened aggregate jumper `failures` records so missing pair-level `ok_count`, `failed_count`, or `failed_checks` fields are normalized to stable defaults instead of propagating `nil`.
- [x] Added `p2smart.default_jumper_pairs()` so examples and REPL diagnostics can use the documented `0-1`, `2-3`, `4-5`, and `6-7` jumper set without hard-coding it; the helper returns a fresh copy for mutation isolation.
- [x] Updated `/tests/p2/smoke_smartpins_loopback.be` to use `p2smart.default_jumper_pairs()` for the documented jumper set while preserving the existing detailed per-case loopback checks.
- [x] Added `p2smart.default_jumper_directions()` to expose the documented jumper set expanded into both directions without running hardware probes.
- [x] Added `default_jumper_pairs` and `default_jumper_directions` to `p2smart.capabilities()` so tooling can discover the public default jumper-list helpers.
- [x] Added `p2smart.default_jumper_pairs_probe()` as the one-way aggregate convenience entry point for the documented jumper set, and updated `examples/smartpin_diagnostics.be` to use it.
- [x] Added `p2smart.jumper_pairs_bidirectional_probe(pairs)` and `default_jumper_pairs_bidirectional_probe()` to expand jumped pairs into both output/input directions before running aggregate diagnostics.
- [x] Updated `examples/smartpin_diagnostics.be` to print `default_jumper_pairs_bidirectional_probe()` output for the documented `0-1`, `2-3`, `4-5`, and `6-7` jumper set.
- [x] Tightened `examples/smartpin_diagnostics.be` output so aggregate jumper diagnostics print concise `ok`/`count`/`failed` summaries instead of dumping full nested maps over serial.
- [x] Updated `examples/smartpin_diagnostics.be` aggregate summaries to print the new `failures` records so failed pairs include failed sub-check names.
- [x] Updated `docs/coverage-matrix.md` so high-level wrapper and top-level example coverage mention the default one-way and bidirectional jumper aggregate diagnostics.
- [x] Updated `docs/p2-api.md`, `docs/architecture-current.md`, and `docs/P2_BUILD.md` so smart-pin sections mention default jumper lists and one-way/bidirectional aggregate diagnostics.
- [x] Added `p2smart.nco_duty_counter_probe(out_pin, in_pin, bit_period, duty, settle_us)` as a result-shaped NCO-duty output to rise-counter jumper diagnostic, with focused host call-sequence/result coverage and capability/import-smoke visibility.
- [x] Added `p2smart.pwm_variant_counter_probe(out_pin, in_pin, frame, duty, divisor, mode_name, settle_us)` as a result-shaped named PWM mode output to rise-counter jumper diagnostic, with focused host coverage for sawtooth mode selection, cleanup, result fields, and capability/import-smoke visibility.
- [x] Added `p2smart.dac_variant_adc_probe(out_pin, in_pin, low_value, high_value, frame, resistor, dither, settle_us, threshold)` as a result-shaped named DAC mode to ADC jumper diagnostic, with focused host coverage for mode selection, delta fields, cleanup, and capability/import-smoke visibility.
- [x] Added `p2smart.adc_variant_sample_probe(pin, source, family, sample_ticks, wait_us)` as a result-shaped named ADC mode sample diagnostic, with focused host coverage for mode selection, sample fields, cleanup, and capability/import-smoke visibility.
- [x] Added `p2smart.counter_variant_sample_probe(pin, mode_name, wait_us)` as a result-shaped named counter/timer mode sample diagnostic, with focused host coverage for mode selection, before/after delta fields, cleanup, and capability/import-smoke visibility.
- [x] Added `p2smart.quadrature_sample_probe(pin_a, pin_b, mode, wait_us)` as a result-shaped quadrature setup/sample/cleanup diagnostic, with focused host coverage for movement/direction fields, cleanup, and capability/import-smoke visibility.
- [x] Added explicit default-off unsafe assembly gate metadata to `p2.asm.capabilities()` and `p2.asm.abi()` (`unsafe_gate`, `unsafe_default`, and `unsafe_module`), with focused PASM layout smoke assertions and docs updates.
- [x] Added explicit PASM function-bridge unsupported-contract metadata to `p2.asm.capabilities()` and `p2.asm.abi()` (`function_bridge_policy`, reason, and required-contract fields), with focused PASM layout smoke assertions and docs/TODO updates.
- [x] Added explicit arbitrary PASM blob unsupported-contract metadata to `p2.asm.capabilities()` and `p2.asm.abi()` (`arbitrary_blob_policy`, reason, and required-contract fields), with focused PASM layout smoke assertions and docs/TODO updates.
- [x] Added explicit inline-assembler unsupported-contract metadata to `p2.asm.capabilities()` and `p2.asm.abi()` (`inline_assembler_policy`, reason, and required-contract fields), with focused PASM layout smoke assertions and docs/TODO updates.
- [x] Added explicit raw `p2.asm.cognew(...)` policy metadata (`raw_cognew_policy` and reason) so tooling can distinguish the low-level existing PASM cog path from a supported arbitrary-blob ABI, with focused PASM layout smoke assertions and docs/TODO updates.
- [x] Added `p2.asm.audit()`, `audit_problems()`, and `audit_ok()` so PASM smoke tooling can verify that capability and ABI policy metadata remain consistent for raw cog launch, arbitrary blobs, function bridges, inline assembler, and the unsafe-ASM gate.
- [x] Updated `examples/pasm_direct.be` so the user-facing PASM example covers guarded intrinsics, queryable marker-fixture launch policy, unsupported arbitrary-blob/function-bridge/inline-assembler policy metadata, and the safe `p2.asm.launch_probe()` path instead of only printing raw intrinsic values.
- [x] Hardened `/tests/p2/smoke_pasm_layout.be` metadata substring assertions to use module-level `string.find(text, needle)` instead of unsupported string instance `.find(...)`, avoiding runtime assertion failures while preserving the same PASM contract checks.
- [x] Added explicit cooperative task scheduler policy metadata to `task.capabilities()` and `task.execution_model()` (`scheduler_policy` and `unsupported_reason`), with focused host/P2 smoke assertions and docs/TODO updates.
- [x] Added `task.Timer.remaining()` and `remaining_result()` so cooperative timer users can query active/inactive remaining time without duplicating timer internals, with primitive capability metadata, focused host/P2 smoke assertions, and docs/TODO updates.
- [x] Added `task.audit()`, `audit_problems()`, and `audit_ok()` so host/P2 source-module smokes can verify that scheduler capability metadata, execution-model metadata, and primitive capability metadata remain consistent.
- [x] Updated `examples/task_scheduler.be` and `examples/task_primitives.be` so task examples expose the current scheduler policy/unsupported reason and timer remaining-result diagnostics alongside the existing cooperative scheduler and primitive demonstrations.
- [x] Added explicit `p2.cog.capabilities()` metadata for the current `native_blink_info_stop_only` handle model and backed non-blocking `id(handle)`, `status(handle)`, `join(handle)`, `result(handle)`, and `error(handle)` wrappers over the existing handle diagnostics plus `kill(handle)` as an explicit force-stop cleanup alias, while keeping blocking result waits and cross-cog exception propagation explicitly unsupported; updated the focused closure-cog smoke, examples, docs, and TODO wording to match.
- [x] Extended non-blocking `p2.cog.join(handle)` snapshots with explicit `result`, `result_type_name`, and `error` fields so child setup return values and recorded errors are visible through the join API without scraping `last_result_*` diagnostics.
- [x] Extended native closure-cog `stop(handle)` / `kill(handle)` return maps with explicit cleanup diagnostics: cleanup policy, stack/mailbox/source release indicators, slot release, and post-stop handle invalidation.
- [x] Added `p2compat.child_vm_transfer_policy()` as a structured child-VM transfer contract for tooling, exposing copyable primitive types, staged closure-name selector behavior, unsupported captured/live-object transfer, rejected native/resource categories, and explicit no-ownership/no-shared-mutable-state flags, with focused host/import/p2compat smoke coverage and audit consistency checks.
- [x] Added direct child-VM transfer policy helpers `p2compat.child_vm_copyable_type(name)` and `p2compat.child_vm_rejected_type(name)` so tooling can query allowed primitive type names and rejected live-object categories without parsing policy lists.
- [x] Added `p2ipc.contract()` plus IPC capability metadata for the current-VM-only boundary, explicitly reporting no cross-cog wakeups, no cross-VM serialization, and no ownership transfer, with focused host/import-smoke assertions and docs/TODO updates.
- [x] Added payload-contract fields to `p2ipc` channel/mailbox `send_result`/`recv_result`/`put_result`/`get_result` maps so each operation reports current-VM-reference payload handling, no serialization, no ownership transfer, payload type, and ownership/serialization policy strings.
- [x] Added `p2ipc.audit()`, `audit_problems()`, and `audit_ok()` so host/import smokes can verify that capability and contract metadata stay consistent for current-VM IPC, no cross-VM support, no serialization, no ownership transfer, cleanup flags, payload-contract results, hardware-lock reporting, and fallback mutex support.
- [x] Added `p2ipc.self_test_result(iterations)` as a bounded current-VM IPC cleanup diagnostic over channel send/receive/clear/close, mailbox put/get/clear/close, shared-buffer write/fill/clear, and mutex lock/unlock/close paths, with capability/contract metadata plus focused host/import coverage.
- [x] Tightened `p2ipc` channel/mailbox cleanup so `close()` releases queued/stored payload references, `close_result()` reports previous payload state and released payload counts, and capability/contract metadata exposes `close_releases_payloads`, with focused host/import-smoke assertions and docs/TODO updates.
- [x] Added reusable `p2.channel.clear()` / `clear_result()` and `p2.mailbox.clear()` / `clear_result()` cleanup helpers so retained payloads can be released without closing the IPC object, with blocked-lock/closed-state diagnostics, capability/contract metadata, focused host/import-smoke assertions, and docs/TODO updates.
- [x] Added `p2.shared.Buffer.clear()` and `clear_result()` so shared-buffer contents can be explicitly zeroed with result-shaped diagnostics, plus IPC capability/contract metadata, focused host/import-smoke assertions, and docs/TODO updates.
- [x] Updated `examples/cog_channel.be` so the user-facing IPC example now prints `p2ipc.contract()`, channel clear/close cleanup diagnostics, mailbox clear/close diagnostics, and shared-buffer clear diagnostics instead of only basic channel send/receive behavior.
- [x] Updated `examples/import_all_libs.be` so the import sweep reports current `p2ipc` contract/cleanup capabilities and `task` scheduler/timer metadata instead of only module type and max-task count.
- [x] Added `configstore.audit()`, `audit_problems()`, and `audit_ok()` so host/import/configstore smokes can verify root, result-helper, JSON-null, FAT `.JSO`, and capability lookup metadata consistency without touching hardware.
- [x] Added `binary_heap.capabilities()`, `capability(name)`, `audit()`, `audit_problems()`, and `audit_ok()` so host/import smokes can query and self-check the small in-memory heap/sort contract, including exception-preserved caller arrays.
- [x] Added metadata-only WiFi diagnostics: `wifi.capabilities()`, `capability(name)`, `default_config()`, `audit()`, `audit_problems()`, and `audit_ok()` now expose the AirLift/SPI hardware-deferred boundary, request-init rule, import no-op, default pins, and status names without starting SPI transactions.
- [x] Added source-level `math.capabilities()`, `capability(name)`, `audit()`, `audit_problems()`, and `audit_ok()` so host/import smokes can self-check the finite fallback, invalid-domain, non-number fallback, constants, rounding, min/max, angle conversion, and CORDIC backend metadata without rerunning hardware math parity.
- [x] Added metadata-only `p2mem.capabilities()`, `capability(name)`, `audit()`, `audit_problems()`, and `audit_ok()` so host/import smokes can query result-wrapper coverage, native-cache helper categories, invalid module-name diagnostics, and snapshot-diagnostic expectations without mutating cache state.
- [x] Added metadata-only `libstore.capabilities()`, `capability(name)`, `audit()`, `audit_problems()`, and `audit_ok()` so host/import smokes can self-check curated module coverage metadata, policy constants, default path roots, `.bec` fallback metadata, and module-name rules without scanning SD or mutating cache state.
- [x] Updated `examples/import_all_libs.be` so the user-facing import sweep prints audit status for `binary_heap`, `configstore`, `libstore`, `math`, `p2compat`, `p2ipc`, `p2mem`, `task`, and metadata-only `wifi` without starting hardware transactions.
- [x] Updated `examples/debug_report.be` and `examples/psram_cache_stats.be` so p2mem/libstore-facing diagnostic examples print audit status before dumping module/cache diagnostics or attempting cache operations.
- [x] Extended `/tests/p2/smoke_sd.be` so the scripted SD regression path starts with read-only `p2.fs_info("/")` mount evidence for `mount_result_name == "ok"`, FAT start sector `2048`, `volinfo_result_name == "ok"`, `sd_response == 0` when reported, and FAT32 filesystem type when reported. Source-level compile coverage only; hardware execution remains pending in `TODO.md`.
- [x] Added `make p2-catalina-build-log-guard-selftest`, backed by `scripts/p2/check_catalina_build_log_guard.sh`, so the Catalina build-log pipefail guard can be verified with an intentionally failing logged pipeline without running a firmware build.
- [x] Made the P2 Edge32/XMM Catalina wrapper targets pass `CATALINA_DIR="$(CATALINA_DIR)"` explicitly through their recursive make calls so the sibling `../Catalina` default is visible in dry-run expansion for `p2-edge32-ram`, `p2-edge32-flash`, and `p2-xmm-flash`.
- [x] Confirmed the upstream-facing Catalina SD note documents the `target/p2/cogsd.t` P2 Edge shared flash/SD pin ordering and deep-power-down sequence, while the P2 Edge32 SD/XMM handoff note documents the standalone XMM flash-loader path and verified boot shape.
- [x] Added `make p2-profile-invariants-selftest`, backed by `scripts/p2/check_profile_invariants.sh`, so the recovery Edge32 profile is checked as COMPACT/Hub-image-limited/PSRAM-block-access and kept distinct from the LARGE/XMM profile without running a firmware build.
- [x] Added `make p2-catalina-xmm-cx-sync-selftest`, backed by `scripts/p2/check_catalina_xmm_cx_sync.py`, so the sibling Catalina fork can be checked for regenerated P2/XMM `cx` SD/DOSFS objects and `catalina.idx` entries after SD source changes.
- [x] Added `make p2-catalina-warning-audit`, backed by `scripts/p2/audit_catalina_warnings.py`, so existing Catalina/Cake warnings remain visible by class while new target-width or pointer/integer ABI warning lines fail the audit.
- [x] Added `make p2-sd-write-smoke-audit`, backed by `scripts/p2/audit_sd_write_smokes.py`, and marked the active SD/file/layout/import/config/example/PASM smokes with bounded write-open budgets so future SD-write coverage stays small, preflighted, and cleanup-oriented without touching hardware.
- [x] Added aggregate `make p2-baseline-guards TOOLCHAIN=catalina CATALINA_DIR=../Catalina` and documented it in `docs/testing.md`; it runs the non-hardware build-log, profile, Catalina XMM `cx`, warning, and SD-write-smoke guards as one focused Priority 0 check.
- [x] Updated `docs/roadmap.md` so Phase 1 reflects the existing `docs/source-research.md` document and now tracks ongoing refinement instead of stale creation work.
- [x] Updated `docs/architecture-current.md` so its repeatable P2 entrypoint list includes `make p2-baseline-guards TOOLCHAIN=catalina CATALINA_DIR=../Catalina` alongside host, hardware, soak, provisioning, and smoke commands.
- [x] Updated `docs/coverage-matrix.md`, `docs/roadmap.md`, and `port/p2/TODO.md` so they reflect the existing `docs/performance.md` performance-plan document and keep the remaining work focused on measurement hooks/results instead of stale document creation.
- [x] Added `make p2-docs-audit`, backed by `scripts/p2/audit_p2_docs.py`, so the tracked P2 documentation set, including `docs/hardware-tests.md`, is checked for presence and non-empty content without running builds or hardware.
- [x] Folded `p2-docs-audit` into `make p2-baseline-guards` and updated the testing, architecture, roadmap, coverage, and TODO notes so the aggregate guard is the single non-hardware pre-change check for baseline/tooling/docs drift.
- [x] Added `make p2-catalina-path-audit`, backed by `scripts/p2/audit_catalina_paths.py`, to keep active P2 docs/tooling on the sibling `../Catalina` path and fail if Docker Catalina, `.third_party_cache/catalina`, `/opt/catalina`, or `catalina-speccy88` references return outside the historical done log.
- [x] Added aggregate staged sync-serial clocked diagnostics to `p2smart`: `default_clocked_jumper_groups()`, `sync_serial_clocked_jumper_probes(...)`, and `sync_serial_default_clocked_probe(...)` now cover the documented four-pin jumper groups without claiming received-data validation.
- [x] Extended `/tests/p2/smoke_smartpins_sync_diag.be` so the focused `smartpins-sync-diag` suite also exercises the default four-pin clocked sync-serial diagnostic result shape while leaving received-data validation open.
- [x] Folded the focused `smoke_smartpins_sync_diag.be` command into the `soak-smartpins` suite so wired-board soak runs exercise the staged sync-serial diagnostic shape after the main smart-pin loopback smoke.
- [x] Folded the focused `smoke_smartpins_async_rx.be` command into the `soak-smartpins` suite so wired-board soak runs also exercise the async RX byte/read-result proof across the documented jumper pairs.
- [x] Added explicit `SOAK_P2_TIMEOUT` and `SOAK_P2_STARTUP_TIMEOUT` make variables, defaulting to `700` and `120`, so `make soak-p2` uses the same conservative timeout shape as the documented hardware-safe runner commands.
- [x] Added focused make wrappers `p2-smoke-smartpins-loopback`, `p2-smoke-smartpins-async-rx`, and `p2-smoke-smartpins-sync-diag` with conservative `P2_SMARTPINS_TIMEOUT` / `P2_SMARTPINS_STARTUP_TIMEOUT` defaults so jumper-dependent smart-pin suites are easier to run repeatably.
- [x] Added aggregate `make p2-smoke-smartpins PORT=...`, which runs the focused loopback, async RX, and sync diagnostic smart-pin targets in order using the same timeout variables.
- [x] Strengthened `/tests/p2/smoke_pasm_layout.be` so the existing staged PASM files also verify `p2.asm.marker_blob()` returns stable 4-byte-aligned bytes and `p2.asm.load()` rejects empty, missing, and unaligned blob inputs without adding more SD write operations.
- [x] Added focused `make p2-smoke-pasm-layout PORT=...` to upload only `modules/libstore.be` plus `/tests/p2/smoke_pasm_layout.be`, then run the PASM layout smoke directly through the serial smoke runner with conservative timeout defaults.
- [x] Added focused `make p2-smoke-task PORT=...` to upload only `modules/task.be` plus `/tests/p2/smoke_task.be`, then run the cooperative task smoke through the existing `task` serial suite with the focused smoke timeout defaults.
- [x] Added non-consuming IPC diagnostics: `p2.channel.snapshot_result()` and `p2.mailbox.peek_result()` report current queued/stored payload state without removing it, expose the same current-VM/no-serialization/no-ownership-transfer policy fields as the existing result helpers, and are covered by focused host/import checks plus the current-VM IPC example.
- [x] Hardened import/cache/churn smokes so task slot-count checks accept either known backend limit (`16` for the native P2 compatibility module or `32` for the source module) while requiring `task.capability("max_tasks")` to match `task.info()["max_tasks"]`.
- [x] Removed the remaining Catalina bootstrap helpers from `tools/p2/bootstrap/`, changed `p2-tools-catalina` into an external-install check for `CATALINA_DIR`, updated tool/build docs to stop advertising Catalina cache/bootstrap workflows, and expanded `p2-catalina-path-audit` to cover `tools/p2`.
- [x] Tightened `p2-tools-catalina` so it verifies the external Catalina checkout has the expected `bin/catalina`, `bin/lcc`, `include`, `target`, and `lib` components before a P2 build starts.
- [x] Clarified task documentation and tracking so the 32-slot claim applies to the source-level `modules/task.be` backend, while the native P2 compatibility `import task` path is allowed to keep its current 16-slot limit as long as `task.info()` and `task.capability("max_tasks")` agree.
- [x] Added focused current-VM IPC hardware-smoke plumbing: `/tests/p2/smoke_p2ipc.be`, `scripts/p2/repl_smoke.py --suite p2ipc`, and `make p2-smoke-ipc PORT=...` upload only `modules/p2ipc.be` plus the smoke file before running channel/mailbox/buffer/mutex contract diagnostics.
- [x] Hardware-verified the focused current-VM IPC smoke on `/dev/ttyUSB0`: `make p2-smoke-ipc PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` uploaded `modules/p2ipc.be` plus `/tests/p2/smoke_p2ipc.be` and passed `P2_SMOKE_PASS p2ipc`.
- [x] Added focused closure-cog make plumbing: `make p2-smoke-cog-closure PORT=...` uploads only `/tests/p2/smoke_cog_closure.be` before running the existing `cog-closure` suite.
- [x] Added aggregate `make p2-smoke-priority4 PORT=...`, which runs the focused closure-cog, task, and IPC smoke targets in order using the same focused timeout defaults.
- [x] Added `scripts/p2/repl_smoke.py --suite priority4` for direct already-staged execution of the same focused closure-cog, task, and IPC smoke sequence.
- [x] Added focused grouped P2 API smoke plumbing: `scripts/p2/repl_smoke.py --suite p2-api` and `make p2-smoke-p2-api PORT=...`, which uploads only `/tests/p2/smoke_p2_api.be` before running the grouped low-level API smoke.
- [x] Added focused already-staged Priority 1 import/library smoke suites: `scripts/p2/repl_smoke.py --suite import-cache`, `--suite import-churn`, `--suite libraries`, and aggregate `--suite priority1`, avoiding a broad soak run when only the existing import/cache/library checks need to be exercised.
- [x] Added `make p2-smoke-priority1-staged PORT=...` as a no-upload wrapper around the already-staged Priority 1 import/cache/churn/library aggregate, using the focused smoke timeout defaults and making the SD precondition explicit in the target name.
- [x] Added `p2smart.async_serial_buffer_policy()` so the current async-serial no-FIFO/no-buffer limitation is queryable as structured metadata, with host/import assertions and smart-pin docs updated instead of implying buffered UART receive support exists.
- [x] Added `libstore.pasm_policy()` so the `/berry/pasm/*.bin` storage/readback contract is queryable separately from native PASM execution, with import and PASM-layout smoke assertions preserving `execution_supported == false` / `pasm_execution_deferred`.
- [x] Added `task.contract()` so the cooperative task scheduler's current-VM/no-preemption/no-independent-stack/no-cross-VM boundary is queryable as one structured map, with audit consistency checks and focused host/P2/import-smoke assertions.
- [x] Added `p2smart.adc_dac_delta_policy()` so the current DAC-to-ADC setup/readback path is queryable separately from unverified calibrated voltage, polarity, and threshold assertions, with focused host/import assertions and docs/TODO updates.
- [x] Added already-staged Priority 2 smoke plumbing: `scripts/p2/repl_smoke.py --suite priority2` groups the low-level P2 API smoke with the focused smart-pin suites, and `make p2-smoke-priority2-staged PORT=...` wraps it without doing an SD upload. Later entries record that this staged suite now uses the native/current-file normal-pin, counter-modes, output-modes, ADC/DAC sampled-shape, quadrature-motion, async RX, and sync diagnostic path rather than the broad wrapper-loopback smoke.
- [x] Added already-staged Priority 3 smoke plumbing: `scripts/p2/repl_smoke.py --suite priority3` runs the PASM layout/marker-fixture contract smoke, and `make p2-smoke-priority3-staged PORT=...` wraps it without doing an SD upload.
- [x] Added already-staged first-four priority smoke plumbing: `scripts/p2/repl_smoke.py --suite priority1-4` and `make p2-smoke-priority1-4-staged PORT=...` run the existing Priority 1 through Priority 4 staged suites in order without doing a make upload.
- [x] Added the focused composed first-four priority make entrypoint: `make p2-smoke-priority1-4 PORT=...` now runs `p2-smoke-priority1`, `p2-smoke-priority2`, `p2-smoke-priority3`, and `p2-smoke-priority4` in order. This gives a normal make target for checking all four priority areas through the current focused paths while keeping `p2-smoke-priority1-4-min` as the tiny health target and `p2-smoke-priority1-4-staged` as the broad already-staged regression path.
- [x] Added bounded async UART drain helpers to `p2smart.AsyncSerialPair`: `read_available_results(max_count=nil)` returns result-shaped currently-ready RX events and acknowledges each consumed byte, while `read_available(max_count=nil)` returns just the byte values without claiming a background FIFO.
- [x] Extended `/tests/p2/smoke_smartpins_async_rx.be` so the focused async RX hardware smoke now includes a bounded drain/ack check for `read_available_results()` and `read_available()` on the documented `0-1` jumper path.
- [x] Added `p2smart.async_serial_drain_probe(...)`, a top-level setup/send/wait/drain/clear diagnostic helper for the bounded async UART drain path, with capability metadata and focused host/import coverage.
- [x] Updated `examples/uart_loopback.be` to demonstrate the bounded async UART drain probe alongside the existing async send/query diagnostic.
- [x] Updated `examples/smartpin_diagnostics.be` to include the bounded async UART drain probe in the broader jumper diagnostics bundle.
- [x] Folded `p2smart.async_serial_drain_probe(...)` into `p2smart.jumper_pair_probe(...)` so the compact one-pair diagnostic bundle now includes bounded async UART drain/ack coverage in addition to setup/query.
- [x] Added `p2smart.jumper_pair_checks()` so tests and users can inspect the ordered `jumper_pair_probe(...)` sub-check list without touching hardware; focused host/import/smart-pin smoke coverage now pins that `async_serial_drain` is part of the bundle.
- [x] Changed `p2smart.jumper_pair_probe(...)` to use `jumper_pair_checks()` for its ordered sub-check names/counts and return a `checks` snapshot, reducing metadata drift as the bundle evolves.
- [x] Extended `p2smart.audit()` / `audit_problems()` so smart-pin metadata self-checks now fail if `jumper_pair_checks()` loses a required unique sub-check such as `async_serial_drain`.
- [x] Extended `p2ipc.audit()` with required capability/contract key lists so missing IPC metadata fields are reported explicitly, with focused host/import/P2-smoke assertions.
- [x] Added `p2smart.required_capability_keys()` and extended `p2smart.audit()` so missing smart-pin capability metadata is reported explicitly, with focused host/import assertions.
- [x] Added task required-key metadata helpers for scheduler capabilities, primitive capabilities, and the cooperative contract, and extended `task.audit()` to report missing metadata keys with focused host/P2/import-smoke assertions.
- [x] Added `task.self_test_result(iterations)` as a bounded current-VM cooperative task cleanup diagnostic over a tiny task lifecycle, Queue, Semaphore, Mutex, EventFlags, Timer, and event cleanup path, with capability metadata plus focused host/P2/import-smoke assertions.
- [x] Hardware-verified the task self-test diagnostic on `/dev/ttyUSB0`: `make p2-smoke-task PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` uploaded `modules/task.be` plus `/tests/p2/smoke_task.be` and passed `P2_SMOKE_PASS task`.
- [x] Added `p2compat.required_capability_names()` and `required_child_vm_policy_keys()` so p2compat audit now reports missing bare-metal capability records or child-VM transfer-policy fields explicitly, with focused host/p2compat/import-smoke assertions.
- [x] Added `p2mem.required_capability_keys()` and extended `p2mem.audit()` so missing memory/cache diagnostic capability metadata is reported explicitly, with focused host/import assertions.
- [x] Added `libstore.required_capability_keys()` and extended `libstore.audit()` so missing module-coverage/cache-policy capability metadata is reported explicitly, with focused host/import assertions.
- [x] Added `wifi.required_capability_keys()` and extended metadata-only `wifi.audit()` so missing AirLift/SPI capability metadata is reported explicitly without starting hardware transactions, with focused host/import assertions.
- [x] Added `configstore.required_capability_keys()` and extended `configstore.audit()` so missing `/berry/config` JSON helper capability metadata is reported explicitly, with focused host/configstore/import assertions.
- [x] Added `math.required_capability_keys()` and extended `math.audit()` so missing finite-fallback/CORDIC capability metadata is reported explicitly, with focused host/import assertions.
- [x] Added `binary_heap.required_capability_keys()` and extended `binary_heap.audit()` so missing tiny in-memory heap capability metadata is reported explicitly, with focused host/import assertions.
- [x] Added `make p2-source-module-metadata-audit`, backed by `scripts/p2/audit_source_module_metadata.py`, and folded it into `make p2-baseline-guards` so source-module capability maps must stay aligned with `required_capability_keys()` and `missing_capability_keys` audit reporting.
- [x] Tightened `p2ipc.required_capability_keys()` to include the remaining basic channel/mailbox/mutex/shared-buffer/result diagnostic capability fields after the source-module metadata audit exposed the drift.
- [x] Added native `p2.asm.required_capability_keys()` and `required_abi_keys()` plus `missing_capability_keys` / `missing_abi_keys` audit fields so the PASM marker-fixture contract metadata is explicitly queryable, with focused PASM-layout smoke assertions and docs/TODO updates.
- [x] Added native `p2.cog.required_capability_keys()` plus metadata-only `p2.cog.audit()` / `audit_problems()` / `audit_ok()` so the interim native-blink handle contract reports missing capability metadata without spawning cogs, with focused closure-cog smoke assertions and docs/TODO updates.
- [x] Added `p2smart` synchronous-serial clock variant diagnostics: the source fallback now preserves the native `invert_b` selector, the module reports normal/inverted RX-clock and clock-output mode plans for the documented four-pin jumper groups, and the focused sync diagnostic smoke now avoids the unbounded clocked TX/RX path after hardware showed that execution can run past the smoke timeout before received-data validation is solved.
- [x] Repaired the focused `smartpins-sync-diag` hardware smoke after the clocked sync-serial TX/RX helper ran past the smoke timeout: the smoke now validates sync setup/readiness and clock-mode planning only, so the jumper-dependent suite completes while received-data execution stays open in TODO.
- [x] Reworked `p2smart.sync_serial_clocked_jumper_variant_probes(...)` so aggregate variant diagnostics are compact planning records that return `execution_deferred` instead of invoking the clocked TX/RX path per group; hardware on `/dev/ttyUSB0` now verifies both one-group and default aggregate variant helpers return without hanging.
- [x] Restored bounded hardware coverage for one real clocked sync-serial attempt in `/tests/p2/smoke_smartpins_sync_diag.be`: `sync_serial_clocked_probe(0, 1, 2, 3, [0x12], ...)` returns on `/dev/ttyUSB0` and reports the current no-ready/no-match receive status without hanging the suite.
- [x] Added `p2smart.dac_adc_sampled_probe(...)` for multi-sample DAC-to-ADC jumper diagnostics, reporting low/high sample lists, min/max/average, signed and absolute average delta, polarity labels, and explicit uncalibrated polarity/voltage flags; host coverage pins the call sequence and `/tests/p2/smoke_smartpins_loopback.be` now stages one sampled `0->1` analog check.
- [x] Added `p2smart.dac_variant_adc_sampled_probe(...)` so named DAC modes have the same multi-sample DAC-to-ADC diagnostic shape, including resistor/dither metadata, uncalibrated polarity/voltage flags, focused host call-sequence coverage, and a conservative `0->1` hardware smoke case.
- [x] Added `p2smart.adc_variant_dac_sampled_probe(...)` so named ADC source/family modes can be sampled against a DAC jumper without claiming calibrated voltage; host coverage pins mode selection/call order and `/tests/p2/smoke_smartpins_loopback.be` now stages a conservative `3x`/`adc_ext` `0->1` check.
- [x] Added `p2smart.adc_dac_variants_sampled_probe(...)` for combined named ADC source/family plus named DAC resistor/dither sampled jumper diagnostics; host coverage pins both mode selections and `/tests/p2/smoke_smartpins_loopback.be` now stages a conservative `10x`/`adc_scope` plus `75r_2v`/`plain` `0->1` check.
- [x] Relaxed the analog smartpin smoke so DAC-to-ADC probes report sampled values and verify result shape/cleanup without requiring a nonzero delta; this matches current `/dev/ttyUSB0` behavior where a `0->1` DAC/ADC run can return flat readings while calibrated analog validation remains open.
- [x] Fixed `p2smart.pulse_counter_probe(...)` and `transition_counter_probe(...)` so they arm the output with count `0`, read the counter baseline, then trigger the requested count; isolated hardware showed the old probes counted pulses before the baseline read, and the repaired `/tests/p2/smoke_smartpins_loopback.be` now passes again on `/dev/ttyUSB0`.
- [x] Extended `/tests/p2/smoke_smartpins_loopback.be` to hardware-check named PWM `sawtooth`/`smps` through rise-counter loopback on every documented jumper pair in both directions.
- [x] Added NCO-duty hardware diagnostics to `/tests/p2/smoke_smartpins_loopback.be` without claiming a passing waveform: direct `/dev/ttyUSB0` probes for several bit-period/duty values on jumper `0-1` currently report no rise-counter delta, so the smoke records result shape and values while TODO keeps NCO-duty waveform validation open.
- [x] Added `p2smart.counter_variant_drive_probe(...)` for named counter/timer modes driven by a jumped GPIO output; focused host coverage pins the call sequence and `/tests/p2/smoke_smartpins_loopback.be` now hardware-checks named `count_highs` in both directions on every documented jumper pair.
- [x] Added `p2smart.counter_variant_drive_modes_probe(...)` as an aggregate named-counter drive diagnostic with per-mode failure reporting.
- [x] Added a dedicated `/tests/p2/smoke_smartpins_counter_modes.be` smoke and `smartpins-counter-modes` runner suite for the aggregate default counter-drive probe across the documented `0-1`, `2-3`, `4-5`, and `6-7` jumper pairs in both directions, while keeping the heavier smartpin loopback suite on its stable single-mode per-pair counter check.
- [x] Kept `count_rises` out of the aggregate hardware default after direct `/dev/ttyUSB0` smoke attempts hung on the first `0->1` aggregate case; `count_highs` remains the hardware-safe default and `count_rises` remains explicit setup/host coverage until a timeout-safe hardware validation pattern is found.
- [x] Added `make p2-smoke-smartpins-counter-modes PORT=...` and folded it into the aggregate `make p2-smoke-smartpins PORT=...` target so the focused counter-mode jumper smoke is repeatable through the same make entrypoints as the other smart-pin suites.
- [x] Hardened the Catalina loader default on Linux: `mk/toolchain-catalina.mk` now resolves `LOADP2` from `command -v loadp2` before falling back to `.third_party_cache/flexprop/bin/loadp2`, so `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina` no longer fails just because the optional FlexProp cache is absent when a system `loadp2` is installed.
- [x] Promoted sampled ADC/DAC jumper probes in `p2smart.capabilities()` from generic diagnostics to verified sampled-loopback coverage for the default and named-DAC paths: `adc_dac_sampled_probe` and `dac_variant_adc_sampled_probe`. Later focused native hardware evidence showed sampled named-ADC variants can read flat on the current jumper harness, so `adc_variant_dac_sampled_probe` and `adc_dac_variants_sampled_probe` are now tracked as diagnostics instead of verified capabilities. The separate `adc_dac_delta` capability remains `unverified` because calibrated voltage and polarity thresholds are still not claimed.
- [x] Extended `/tests/p2/smoke_import_all_libs.be` so SD import-all coverage also pins the verified sampled ADC/DAC `p2smart` statuses and status-filtered name list, not just the host-only smart-pin regression.
- [x] Wired the focused Priority 4 cooperative task and current-VM IPC smokes into `/tests/p2/smoke_all.be` so the umbrella SD smoke now includes `smoke_task.be` and `smoke_p2ipc.be` alongside the existing closure-cog and p2compat coverage.
- [x] Wired the grouped low-level P2 API smoke into `/tests/p2/smoke_all.be` so the umbrella SD smoke now includes `smoke_p2_api.be` before p2compat/task/IPC coverage; the focused `make p2-smoke-p2-api PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` target passes after keeping `wait_attention()` as pending semantics instead of a false self-attention assertion.
- [x] Added bounded native `p2.cog.wait_attention_result(timeout_us)` / flat `p2.attention_wait_result(timeout_us)` as a result-shaped attention wait helper that polls with a timeout instead of using the raw blocking `_waitatn()` path. Rebuilt and flashed the Catalina XMM image with `CATALINA_DIR=../Catalina`; `make p2-smoke-p2-api PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed on the new `1044416` byte image.
- [x] Added `p2ipc.attention_policy()` plus matching capability/contract/audit metadata so IPC reports bounded native cog-attention wait availability without falsely claiming channel/mailbox cross-cog wakeups. Host and import/P2 smokes pin the policy fields and keep `cross_cog_attention_wakeup == false`.
- [x] Added `task.attention_policy()` plus matching capability/contract/audit metadata so the cooperative task scheduler reports bounded native cog-attention wait availability while keeping `task.wait("attention")` documented as a current-VM event, not a cross-cog task wakeup contract.
- [x] Added current-VM `task.wait()` integration for imported `p2ipc` channel/mailbox objects: channel receive/send readiness and mailbox get/put readiness are now scheduler-pollable through task-readable object kinds, with focused host/P2 task coverage and IPC marker assertions.
- [x] Hardened object-wait timeout parsing so `task.wait(queue, timeout)`, `task.wait(channel, timeout)`, and `task.wait(mailbox, timeout)` now apply the timeout to default get/receive waits instead of requiring the explicit mode argument form.
- [x] Added `p2ipc` task-wait integration metadata (`task_wait_integration`, `task_wait_channel`, and `task_wait_mailbox`) to capabilities, contract, audit, required-key lists, and focused host/P2 IPC smokes.
- [x] Added `p2compat.child_vm_policy(name)` as a snapshot-safe direct lookup helper for child-VM transfer-policy fields, including copied list values, with focused host/P2 p2compat coverage.
- [x] Added `p2ipc.contract_value(name)` so tools can query individual current-VM IPC contract fields without parsing the full contract map, with focused host/P2 IPC coverage.
- [x] Added `task.contract_value(name)` so tools can query individual cooperative scheduler contract fields without parsing the full contract map, with focused host/P2 task coverage.
- [x] Added `task.execution_model_value(name)` so tools can query one cooperative scheduler execution-model field without parsing the full map, with focused host/P2 task coverage.
- [x] Added `p2ipc.attention_policy_value(name)` so tools can query one bounded-attention/no-IPC-wakeup policy field without parsing the full map, with focused host/P2 IPC coverage.
- [x] Added `task.attention_policy_value(name)` so tools can query one cooperative scheduler attention-policy field without parsing the full map, with focused host/P2 task coverage.
- [x] Added `task.required_attention_policy_keys()` and extended `task.audit()` to report missing task attention-policy metadata separately, with focused host/P2 task coverage.
- [x] Repaired the non-interactive Linux `loadp2 -t` wrapper path so `make p2-edge32-ram ...` no longer strips terminal mode; it now uses a bounded PTY attach, reaches the Berry prompt, disconnects, and exits successfully under non-TTY make runs.
- [x] Restored the COMPACT Edge32 recovery image after grouped roadmap facades made it exceed Hub RAM: grouped roadmap facades now default to XMM-only, and non-XMM Edge32 uses a `92 KiB` main heap plus `8 KiB` worker heap. `make p2-edge32 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` now builds `518304 / 524288` bytes.
- [x] Added a Hub RAM size guard for generated Catalina flash-loader wrapper images so an oversized `berry_p2_flash_loader.binary` fails during build instead of timing out silently during flash boot. The repaired Edge32 flash-loader wrapper is `520384 / 524288` bytes.
- [x] Hardware-verified the Priority 0 aliases with native sibling Catalina on `/dev/ttyUSB0`: `make p2-edge32-ram PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` reached the Edge32 prompt, `make p2-edge32-flash ...` programmed and booted the Edge32 SPI-flash image, a REPL probe reported `edge32`, `make p2-xmm-flash ...` restored the standalone XMM image, and a REPL probe reported `xmm true` for the XMM profile and pointer-window heap.
- [x] Fixed `p2.fs_info("/")` mounted-state diagnostics so calling `os.path.exists()` or other filesystem APIs before `p2.fs_info()` no longer leaves `partition_start=-1` / `volinfo_result_name='not_run'`; mounted snapshots now report the current Catalina volume start and FAT metadata.
- [x] Fixed `os.path.splitext("LOCAL")` to return `["LOCAL", ""]` instead of `["", "LOCAL"]`, preserving the expected no-extension local filename shape.
- [x] Hardened `/tests/p2/smoke_sd.be` for P2 fixed file-handle pools by closing every read handle explicitly, accepting P2 `seek()` success via `tell()` checks, and pinning the current uppercase `bytes.tohex()` result.
- [x] Hardware-verified the full SD/file/os/os.path checklist on both current P2 Edge 32 MB profiles with native sibling Catalina: XMM standalone flash image `1044640 / 16777216` passed `run_file("/tests/p2/smoke_sd.be")`, Edge32 SPI-flash image `518304 / 524288` with flash wrapper `520384 / 524288` passed the same checklist, and the board was restored to XMM afterward with a final `xmm true` profile probe.
- [x] Hardware-verified the focused range built-in smoke on the current native-Catalina XMM image: staged `/tests/p2/smoke_range.be` and `run_file("/tests/p2/smoke_range.be")` passed with `P2_SMOKE_PASS range`.
- [x] Tightened the Priority 1 `p2mem` diagnostics after focused library-smoke probing: `p2mem.stats()` now keeps `p2.status_info()` error detection without returning the large nested status payload, and `p2mem.gc()` reports an explicit bounded `p2_gc_collect_deferred` snapshot on P2 instead of forcing a slow native collection from source-module diagnostics. Host `tests/p2/host_libstore_chunk.be` passes, and the focused hardware `stats -> cache -> gc` probe passed on `/dev/ttyUSB0`.
- [x] Hardware-verified the Priority 1 host-like API compatibility metadata with the focused native-Catalina XMM smoke: `make p2-smoke-p2compat PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` stages only 8.3-safe `/tests/p2/p2compvm.be`, runs short native metadata probes without source-loading `modules/p2compat.be`, and passes `P2_SMOKE_PASS p2compat`.
- [x] Rechecked `/berry/main.be` startup behavior with a minimal boot marker on the current native-Catalina XMM image: normal boot did not run the marker because `BE_P2_RUN_SD_MAIN` defaults to `0`, manual `run_file("/berry/main.be")` printed `P2_SD_MAIN_BOOT_MARKER` and returned `123`, and a final focused REPL probe confirmed `/berry/main.be` was removed from the SD card.
- [x] Hardware-verified the opt-in `/berry/main.be` startup path with native sibling Catalina: `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina CATALINA_EXTRA_CFLAGS='-DBE_P2_RUN_SD_MAIN=1'` built/flashed an XMM image `1044992 / 16777216`; a staged `/berry/main.be` printed `P2_SD_MAIN_BOOT_MARKER` during startup before `berry>` and removed itself; the board was restored with normal `make p2-xmm-flash ...` to image `1044640 / 16777216`, and a final focused REPL probe reported `xmm false` for profile plus `/berry/main.be` absence.
- [x] Hardware-verified focused native `introspect` smokes on the non-XMM Edge32 profile with native sibling Catalina: `make p2-edge32-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` booted image `518304 / 524288`, staged only `/tests/p2/intro.be` and `/tests/p2/ismeth.be`, and both `run_file()` checks passed with `P2_SMOKE_PASS introspect` and `P2_SMOKE_PASS introspect_ismethod`; the board was restored afterward to normal XMM and a final profile probe returned `xmm`.
- [x] Added and hardware-verified a minimal normal smart-pin mode smoke: `/tests/p2/smoke_smartpins_normal_pin.be` drives `p2smart.NormalPin` output pin `0` into input pin `1`, checks high/low readback and clear state, promotes `p2smart.capabilities()["normal_pin"]` to `verified`, adds direct `smartpins-normal-pin` smoke plumbing, and passes on `/dev/ttyUSB0` after staging the current `modules/p2smart.be`.
- [x] Added and hardware-verified a minimal `.bec` fallback smoke: `/tests/p2/smoke_bec_fallback_min.be` stages `/berry/lib/bec_min.be` plus dummy `/berry/cache/bec_min.bec`, verifies `libstore.info()` / `resolve()` select source fallback while reporting compiled metadata, cleans up both files, passes the SD write audit, and passes on `/dev/ttyUSB0` via a single direct `run_file()` smoke. `scripts/p2/repl_smoke.py --suite bec-fallback-min` exposes the same focused check.
- [x] Added `make p2-smoke-bec-fallback-min PORT=... TOOLCHAIN=catalina CATALINA_DIR=../Catalina` plus the matching narrow SD staging helper so the minimal `.bec` fallback smoke can be rerun without invoking the broader Priority 1 or `.bec` fallback suites.
- [x] Added and hardware-verified `/tests/p2/smoke_smartpins_quadrature_static.be` through `make p2-smoke-smartpins-quadrature-static PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` on the normal XMM image; the focused static-jumper smoke covers quadrature setup/sample/ack/clear and deliberately leaves `p2smart.status("quadrature") == "setup_only"` until real motion/direction validation exists.
- [x] Added and hardware-verified `/tests/p2/smoke_libraries_lazy_min.be` with `scripts/p2/repl_smoke.py --suite libraries-lazy-min` on `/dev/ttyUSB0`; the focused Priority 1 smoke checks lazy SD source loading, zero eager PSRAM source-cache use, no direct PSRAM execution, expected policy/strategy fields, and status/policy/strategy snapshot isolation without running the broader library behavior suite.
- [x] Added and hardware-verified `scripts/p2/repl_smoke.py --suite p2mem-policy-min` plus `make p2-smoke-p2mem-policy-min PORT=...`; the focused Priority 1 direct probe loads `/modules/p2mem.be` and verifies `p2mem` capability lookup, audit status, and bounded `gc_result()` diagnostics without running the broader library suite.
- [x] Added and hardware-verified `scripts/p2/repl_smoke.py --suite p2mem-native-cache-min` plus `make p2-smoke-p2mem-native-cache-min PORT=...`; the focused Priority 1 direct probe loads `/modules/p2mem.be`, resets the native upper-PSRAM cache, performs a verified put/get through upper PSRAM, and checks the final entry count without running the broader library suite.
- [x] Fixed Catalina XMM PSRAM block transfers in the P2 native wrappers by staging reads and writes through an explicit HUB buffer before calling Catalina's `psram_read()` / `psram_write()`. This makes Berry heap strings safe to store in native upper-PSRAM cache entries and restores checksum verification for short payloads such as `"abc"`.
- [x] Added and hardware-verified `/tests/p2/smoke_pasm_policy_min.be` with `scripts/p2/repl_smoke.py --suite pasm-policy-min` on `/dev/ttyUSB0`; the focused Priority 3 smoke checks `p2.asm` function-bridge, inline-assembler, arbitrary-blob, and unsafe-gate policy/ABI metadata plus audit helpers without staging PASM blobs or running the full PASM layout smoke.
- [x] Retired the stale Priority 3 TODO for safe native `p2.asm` intrinsics: `getrnd()`, `getct()`, `waitx(cycles)`, and guarded `hubset(value)` are implemented in the native grouped facade, documented in `docs/pasm.md` and `docs/p2-api.md`, and covered by `/tests/p2/smoke_p2_api.be` with positive safe calls plus non-destructive negative-argument diagnostics.
- [x] Retired the stale Priority 3 TODO for PASM blob loading from SD: `libstore.pasm_load()` / `pasm_load_result()` cover `/berry/pasm/*.bin` flat and dotted nested names, `libstore.pasm_policy()` exposes the non-executing storage/readback contract, native `p2.asm.load(path)` returns 4-byte-aligned bytes with error coverage, and `/tests/p2/smoke_pasm_layout.be` hardware-verifies flat/nested staging, metadata, native loading, marker-fixture loading, and rejection of non-marker launch attempts. Arbitrary PASM execution remains tracked separately under the cog-launch ABI item.
- [x] Retired the stale Priority 3 wording that treated all PASM cog launching as open: the safe exact-marker fixture launch path is implemented as `p2.asm.launch_probe()` and `p2.asm.launch_loaded_probe(blob)`, verifies marker/cog-id/stop cleanup, rejects non-marker blobs, and is covered by the PASM layout smoke. The remaining open item is now the narrower public arbitrary-blob launch ABI.
- [x] Retired the Priority 3 inline-assembler decision TODO as an explicit default policy: `p2.asm.capabilities()` and `p2.asm.abi()` report `inline_assembler_policy == "unsupported_no_parser_or_safety_contract"` with required parser/codegen/ABI/clobber/relocation/source-mapping/safety-contract fields, docs describe that boundary, and the focused PASM policy smoke hardware-verifies the metadata. Inline assembly is intentionally unavailable in the normal build instead of silently missing.
- [x] Retired the Priority 3 unsafe-assembly gate TODO for the default build: `p2.asm.capabilities()` and `p2.asm.abi()` report `unsafe_gate == "BE_P2_ENABLE_UNSAFE_ASM"`, `unsafe_default == false`, and `unsafe_module == "none"`; `p2.asm.audit()` checks the duplicated metadata; docs state raw PASM must remain explicit; and the focused PASM policy smoke hardware-verifies the default-off gate. Actual arbitrary unsafe execution remains part of the separate arbitrary-blob ABI work.
- [x] Added and hardware-verified `/tests/p2/smoke_cog_policy_min.be` with `make p2-smoke-cog-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`; the focused Priority 4 smoke checks native-blink closure-cog handle metadata, nonblocking join/result/error policy, cleanup policy, unsupported isolated-VM/live-closure transfer flags, required capability keys, and audit helpers without spawning closure cogs.
- [x] Added and hardware-verified `scripts/p2/repl_smoke.py --suite task-policy-min` on `/dev/ttyUSB0`; the focused Priority 4 direct probe now uses native `import task` as a quick hardware sanity check without source-loading the large task module.
- [x] Added and hardware-verified `scripts/p2/repl_smoke.py --suite ipc-policy-min` plus `make p2-smoke-ipc-policy-min PORT=...`; the focused Priority 4 direct probe loads `/modules/p2ipc.be` and checks current-VM IPC model metadata, task-wait integration, bounded-attention policy, and audit status without running the broader IPC suite.
- [x] Updated `docs/testing.md` and `docs/coverage-matrix.md` so the documented normal progress path names the minimal focused smokes for Priority 1 lazy library and `.bec` fallback checks, Priority 2 normal-pin/quadrature-static checks, Priority 3 PASM policy checks, and Priority 4 cog/task/IPC policy checks instead of steering routine work toward broad aggregate suites.
- [x] Added `p2smart.sync_serial_receive_policy()` to make the current synchronous-serial boundary explicit: unclocked probes can report constant raw samples, the bounded four-pin clocked probe returns cleanly without ready RX data, and matched receive words remain unverified. Host coverage and the focused sync diagnostic smoke now pin that policy without running broad smart-pin suites.
- [x] Hardened `scripts/p2/repl_smoke.py` so uncaught Berry errors and stack tracebacks fail the runner even for custom commands without `--expect`; an intentional `assert(false)` probe now exits nonzero, while a one-line positive marker still passes. A focused ADC/DAC delta probe on jumper `0-1` stayed flat (`low avg 0`, `high avg 0`, `delta 0`), so `adc_dac_delta` remains unverified instead of being promoted from weak analog evidence.
- [x] Added a focused Priority 1 core built-ins smoke entrypoint: `scripts/p2/repl_smoke.py --suite core-builtins-min` runs 8.3-safe short aliases for the existing `call`, `vararg`, `compile_module`, `conversions`, `list_core`, `map_core`, `map_keys`, and `bytes` smoke files, and `make p2-smoke-core-builtins-min PORT=...` uploads only those aliases before running the focused slice instead of the full SD smoke suite.
- [x] Repaired `/tests/p2/smoke_call.be` after the focused core-builtins run exposed stale assumptions: invalid `call()` targets raise `value_error` with `first argument must be a function or a class`, terminal-list expansion into a vararg function preserves all expanded values, and raw method values are not bound callables, so the smoke now wraps the method call in a closure before exercising `call(..., [args])`.
- [x] Repaired the remaining focused core-builtins smoke assumptions and hardware-verified `make p2-smoke-core-builtins-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` on the normal XMM image. The pass covers `call`, `vararg`, `compile_module`, `conversions`, `list_core`, `map_core`, `map_keys`, and `bytes` through 8.3-safe aliases. The fixes keep `compile_module` tolerant of normal profiles without the optional `global` module, align conversion expectations with current `bytes`/`range` instance typing and invalid-string numeric conversion behavior, align `map_core` with native `map` typing, and make `map_keys` record the P2 boundary where equivalent distinct instance keys and invalid hash return errors are not claimed even though same-instance object keys, real keys, and retained collision-key objects work.
- [x] Added and hardware-verified the focused Priority 1 SD/file smoke target: `scripts/p2/repl_smoke.py --suite sd-file-min` runs only `/tests/p2/smoke_sd.be`, and `make p2-smoke-sd-file-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` uploads only that smoke before running it on the normal native-Catalina XMM image. The pass covers SD mount diagnostics, `open()` write/append/update/plus modes, explicit close behavior, `read()`, `readbytes()`, `readlines()`, `seek()`/`tell()`, rename/remove/listdir, cwd/mkdir cleanup, and `os.path` basename/dirname/join/split/splitext/existence/file/dir helpers without invoking the broad SD smoke suite.
- [x] Re-verified the focused Priority 2 sync-serial diagnostic on the current native-Catalina XMM image with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite smartpins-sync-diag --timeout 300 --startup-timeout 120`. The smoke passes after allowing the large staged `modules/p2smart.be` source import/compile to complete, covering the structured `sync_serial_receive_policy()` boundary, a bounded single clocked data/clock probe, and the default four-pin variant planning while keeping matched receive words explicitly unverified.
- [x] Added and hardware-verified `scripts/p2/repl_smoke.py --suite smartpins-adc-dac-diag` plus `make p2-smoke-smartpins-adc-dac-diag PORT=...` as a focused Priority 2 ADC/DAC diagnostic-only target that assumes `modules/p2smart.be` is already staged. On `/dev/ttyUSB0` with the current native-Catalina XMM image, `make p2-smoke-smartpins-adc-dac-diag PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed and printed `P2_SMOKE_ADC_DAC_DIAG true 0 0 0 0 flat`, proving the policy and sampled result shape while keeping calibrated/nonzero ADC-DAC delta unverified.
- [x] Added and hardware-verified `scripts/p2/repl_smoke.py --suite smartpins-nco-duty-diag` plus `make p2-smoke-smartpins-nco-duty-diag PORT=...` as a focused Priority 2 NCO-duty diagnostic-only target that assumes `modules/p2smart.be` is already staged. On `/dev/ttyUSB0` with the current native-Catalina XMM image, `make p2-smoke-smartpins-nco-duty-diag PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed and printed `P2_SMOKE_NCO_DUTY_DIAG false 0 0 0`, proving the result shape while keeping NCO-duty waveform validation open.
- [x] Added and hardware-verified `scripts/p2/repl_smoke.py --suite smartpins-quadrature-diag` plus `make p2-smoke-smartpins-quadrature-diag PORT=...` as a focused Priority 2 quadrature diagnostic-only target that assumes `modules/p2smart.be` is already staged. On `/dev/ttyUSB0` with the current native-Catalina XMM image, `make p2-smoke-smartpins-quadrature-diag PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed and printed `P2_SMOKE_QUADRATURE_DIAG 0 0 0 0 false setup_only`, proving the static sample result shape while keeping real encoder motion/direction validation open.
- [x] Re-verified the focused Priority 1 range smoke without running broad suites: uploaded only `tests/p2/smoke_range.be`, then ran `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/tests/p2/smoke_range.be")' --expect 'P2_SMOKE_PASS range' --timeout 180 --startup-timeout 120`. It passed on the current native-Catalina XMM image and printed `P2_SMOKE_PASS range`, confirming the `incr()`/`setrange()` range-method fix is no longer pending in the coverage matrix.
- [x] Hardware-verified the focused `examples/gpio_loopback.be` example on the current native-Catalina XMM image. After repairing the staged `/modules/p2smart.be` copy and uploading only `examples/gpio_loopback.be` to `/berry/examples`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/gpio_loopback.be")' --expect 'gpio loopback done' --timeout 240 --startup-timeout 120` passed. The run printed `ok true count 4`, four matching write/read samples on jumper `0-1`, and `gpio loopback done`.
- [x] Hardware-verified the focused `examples/nco_counter_loopback.be` example on the current native-Catalina XMM image. Uploaded only `examples/nco_counter_loopback.be` to `/berry/examples`, then ran `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/nco_counter_loopback.be")' --expect 'nco counter loopback done' --timeout 240 --startup-timeout 120`. The run printed a fast `p2smart.nco_counter_probe(...)` result with counter delta `41`, a slower probe with counter delta `21`, and `nco counter loopback done`.
- [x] Repaired and hardware-verified the focused `examples/task_primitives.be` example on the current native-Catalina XMM image. The example now prints scalar Queue/EventFlags/Timer result fields instead of whole result maps, avoiding the on-target map stringification failure seen during the first run. After staging `modules/task.be` and the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/modules/task.be"); run_file("/berry/examples/task_primitives.be")' --expect 'task primitives example done' --timeout 300 --startup-timeout 120` passed, printing Queue nil-payload/full/empty diagnostics, EventFlags ready/not-ready diagnostics, Timer expired/restart/cancel diagnostics, and `task primitives example done`. This older source-preload run is superseded by the later direct native `import task` example verification.
- [x] Repaired and hardware-verified the focused `examples/cog_channel.be` current-VM IPC example on the current native-Catalina XMM image. The example now prints scalar result fields instead of whole result maps, and the hardware run fixed stale field assumptions for mailbox `put_result()` (`stored`/`ready`, not `full`) and buffer `fill_result()` (`filled`, not `size`). After staging `modules/p2ipc.be` and the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/cog_channel.be")' --expect 'cog channel example done' --timeout 240 --startup-timeout 120` passed, printing current-VM IPC contract metadata, channel full/snapshot/recv/clear/close diagnostics, mailbox put/peek/clear/close diagnostics, buffer fill/clear diagnostics, and `cog channel example done`.
- [x] Repaired and hardware-verified the focused `examples/import_all_libs.be` quick import example on the current native-Catalina XMM image. The example now avoids heavy audit scans and optional hardware-deferred imports, prints progress markers, imports `binary_heap`, `configstore`, `math`, `p2compat`, `p2ipc`, and the active `task` backend from `/berry/examples`, and reaches `import all libs example done` with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/import_all_libs.be")' --expect 'import all libs example done' --timeout 120 --startup-timeout 120`. The heavier `p2mem` and `p2smart` modules stay out of the user-facing quick example so it remains fast, but focused direct import-chain probes now cover them separately.
- [x] Repaired and hardware-verified the focused `examples/smartpin_diagnostics.be` example on the current native-Catalina XMM image. The example now prints scalar result fields instead of whole nested probe maps and keeps the user-facing path to the representative `0-1` jumper pair, leaving the all-pair aggregate coverage to the dedicated smart-pin smokes. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/smartpin_diagnostics.be")' --expect 'smartpin diagnostics done' --timeout 240 --startup-timeout 120` passed, printing pair checks `8/8`, raw smart-pin reads, repository first/second values, high-counter delta `10240760`, pulse-counter delta `8`, transition-counter delta `4`, async drain `matched true count 4`, and `smartpin diagnostics done`.
- [x] Repaired and hardware-verified the focused `examples/cog_closure.be` native-blink closure-cog example on the current native-Catalina XMM image. The example now prints scalar capability/info/result/cleanup fields instead of whole maps and avoids optional join/cleanup keys that are not present on the current boot image. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/cog_closure.be")' --expect 'cog closure example done' --timeout 240 --startup-timeout 120` passed, reporting handle policy `native_blink_info_stop_only`, native blink stack `2048`, handles `100` and `101` on cogs `6` and `7`, pins `38` and `39`, result values `150` and `450`, stop/kill `running false`, and `cog closure example done`.
- [x] Re-verified the current `examples/uart_loopback.be` after adding the bounded drain probe. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/uart_loopback.be")' --expect 'uart loopback done' --timeout 180 --startup-timeout 120` passed on the current native-Catalina XMM image. The run printed three ready send/query events for bytes `65`, `66`, and `67`, then `drain ok true matched true count 4 values [68, 68, 68, 68]`, and reached `uart loopback done`.
- [x] Repaired and hardware-verified the focused `examples/pasm_direct.be` safe PASM-adjacent example on the current native-Catalina XMM image. The example now uses scalar `p2.asm.audit_ok()` / `audit_problems().size()` helpers instead of indexing the current image's string-shaped `p2.asm.audit()` result, and it has a final `pasm direct done` marker. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/pasm_direct.be")' --expect 'pasm direct done' --timeout 240 --startup-timeout 120` passed, printing safe counter/random/hubset intrinsic output, marker-fixture-only launch policy, unsupported arbitrary-blob/function-bridge/inline-assembler policy values, `policy audit ok: true problems: 0`, marker fixture `ok/seen/cog-match/stopped` all `true`, and `pasm direct done`.
- [x] Repaired and hardware-verified the focused `examples/task_scheduler.be` cooperative scheduler example on the current native-Catalina XMM image. The example now prints scalar scheduler/task/log diagnostics instead of whole maps/lists, uses short cooperative sleeps, and has a final `task scheduler example done` marker. After staging only the example and preloading the source scheduler with `/modules/task.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/modules/task.be"); run_file("/berry/examples/task_scheduler.be")' --expect 'task scheduler example done' --timeout 300 --startup-timeout 120` passed, reporting `scheduler policy: current_vm_callback_step`, handles `0` and `1`, `steps: 5`, both task statuses `free`, five log entries `A1/B1/A2/B2/B3`, and `task scheduler example done`.
- [x] Repaired and hardware-verified the focused `examples/cordic_demo.be` grouped CORDIC/math example on the current native-Catalina XMM image. The example now prints scalar `xypol`, `polxy`, and `rotxy` fields instead of whole result maps and has a final `cordic demo done` marker. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/cordic_demo.be")' --expect 'cordic demo done' --timeout 180 --startup-timeout 120` passed, printing `xypol r/t: 5 633866811`, `polxy x/y: 1 0`, `rotxy x/y: 1 0`, `isqrt(81): 9`, `muldiv64(6,7,3): 14`, and `cordic demo done`.
- [x] Repaired and hardware-verified the focused `examples/debug_report.be` compact diagnostics example on the current native-Catalina XMM image. The example now uses backed `p2.debug` facade calls plus cheap `p2mem` policy/audit fields, avoids the slow full `p2mem.stats()` and module-record scan in the user-facing path, and has a final `debug report done` marker. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/debug_report.be")' --expect 'debug report done' --timeout 180 --startup-timeout 120` passed, printing profile `xmm`, LED pin `38`, cog count `8`, heap current `15049104`, GC after `110473`, hub total `524288`, p2mem audit `true 0`, p2mem capabilities `true true true`, and `debug report done`.
- [x] Repaired and hardware-verified the focused `examples/psram_cache_stats.be` native PSRAM/cache stats example on the current native-Catalina XMM image. The example now uses native `p2.psram_info()` and `p2.psram_cache_info()` only, avoids slow source-module `libstore`/`p2mem` imports in the user-facing stats path, does not mutate/reset the cache, and has a final `psram cache stats done` marker. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/psram_cache_stats.be")' --expect 'psram cache stats done' --timeout 120 --startup-timeout 120` passed, reporting PSRAM available/heap `true true`, `33554432` bytes, `xmm+block` access, block base/bytes `16777216 16777216`, max transfer `8192`, native cache available `true`, cache base/limit `16777216 32505856`, next/used/free `16777216 0 15728640`, entries/max `0 16`, alloc count `0`, and `psram cache stats done`.
- [x] Repaired and hardware-verified the focused `examples/file_sd.be` SD file example on the current native-Catalina XMM image. The example now uses a bounded temporary `/P2FEXMP.TXT` path, refuses to overwrite a pre-existing file, writes/reads/removes only the file it creates, and has a final `file sd example done` marker. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/file_sd.be")' --expect 'file sd example done' --timeout 120 --startup-timeout 120` passed, printing existence `true`, the expected text `hello from Berry on P2 SD`, hex bytes `68656C6C6F2066726F6D204265727279206F6E205032205344`, successful remove `true`, and `file sd example done`.
- [x] Repaired and hardware-verified the focused `examples/json_sd.be` JSON-on-SD example on the current native-Catalina XMM image. The example now uses a bounded temporary `/P2JSON.TXT` path, refuses to overwrite a pre-existing file, writes/reads/removes only the file it creates, and has a final `json sd example done` marker. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/json_sd.be")' --expect 'json sd example done' --timeout 180 --startup-timeout 120` passed, printing `wrote /P2JSON.TXT`, `answer: 42`, `feature count: 3`, successful remove `true`, and `json sd example done`.
- [x] Repaired and hardware-verified the focused `examples/repl_sd.be` read-only SD REPL helper on the current native-Catalina XMM image. The example now prints scalar mount/list diagnostics instead of dumping the whole root list and has a final `repl sd helper done` marker. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/repl_sd.be")' --expect 'repl sd helper done' --timeout 120 --startup-timeout 120` passed, printing filesystem `ok`, partition start `2048`, root entries `6`, `/berry/main.be` absent, and `repl sd helper done`.
- [x] Hardware-verified the focused `examples/blink.be` board LED example on the current native-Catalina XMM image. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/blink.be")' --expect 'blink done' --timeout 180 --startup-timeout 120` passed, printing `Blinking P2 board LED on pin 38` and `blink done`; the example floats the LED pin before exit.
- [x] Repaired and hardware-verified the focused `examples/adc_read.be` ADC wrapper example on the current native-Catalina XMM image. The example now prints scalar sample diagnostics instead of whole result maps, limits the user-facing run to four samples, acknowledges each sample, clears/floats the pin, and keeps the final `adc done` marker. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/adc_read.be")' --expect 'adc done' --timeout 180 --startup-timeout 120` passed, printing samples on pin `1` with ready/event/raw/wait fields: `false 0 0 20000`, `true 2 2 20000`, `true 2 2 20000`, `true 2 0 20000`, then `adc done`.
- [x] Repaired and hardware-verified the focused `examples/dac_write.be` DAC wrapper example on the current native-Catalina XMM image. The example now prints scalar write diagnostics instead of whole result maps, uses a shorter bounded value sequence, clears/floats the pin, and keeps the final `dac done` marker. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/dac_write.be")' --expect 'dac done' --timeout 180 --startup-timeout 120` passed, printing successful writes on pin `0` for values `0`, `64`, `128`, `192`, `255`, and `0` with frame `256`, settle `60000`, then `dac done`.
- [x] Repaired and hardware-verified the focused `examples/pwm_fade.be` PWM wrapper example on the current native-Catalina XMM image. The example now prints scalar duty diagnostics instead of whole result maps, uses a short bounded fade sequence on pin `0`, clears/floats the pin, and has a final `pwm fade done` marker. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/pwm_fade.be")' --expect 'pwm fade done' --timeout 180 --startup-timeout 120` passed, printing successful duty updates for `0`, `40`, `80`, `120`, `160`, and `200` with frame `200`, divisor `1`, settle `50000`, then `pwm fade done`.
- [x] Repaired and hardware-verified the focused `examples/quadrature_counter.be` quadrature wrapper example on the current native-Catalina XMM image. The example now prints scalar sample diagnostics instead of whole result maps, limits the user-facing run to six static samples on the documented `0-1` jumper, acknowledges each sample, clears/floats the pins, and keeps the final `quadrature counter done` marker. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/quadrature_counter.be")' --expect 'quadrature counter done' --timeout 180 --startup-timeout 120` passed, printing six `before 0 after 0 delta 0 moved false direction 0 wait 50000` samples, then `quadrature counter done`.
- [x] Repaired and hardware-verified the focused `examples/spi_loopback.be` synchronous-serial diagnostic example on the current native-Catalina XMM image. The example now prints scalar receive-policy, single clocked-probe, first-word, and default-variant planning diagnostics instead of dumping nested maps/lists, and keeps the final `sync serial probe done` marker. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/spi_loopback.be")' --expect 'sync serial probe done' --timeout 240 --startup-timeout 120` passed, reporting policy `unverified_no_matched_receive_words`, a bounded clocked probe with `ok false`, `ready 0`, `matched 0`, first word `sent 18 ready false event 0 raw nil value nil matched false error not_ready`, default variants `groups 2 failed 2 supported false error execution_deferred`, then `sync serial probe done`.
- [x] Added final markers and hardware-verified the focused unsupported-hardware examples on the current native-Catalina XMM image. `examples/vga_test_pattern.be` now reaches `vga test pattern done` after reporting `video_output` and `vga_demo` as unsupported through `p2compat`; `examples/usb_keyboard_mouse.be` now reaches `usb keyboard mouse done` after reporting `usb_hid` and `usb_demo` as unsupported through `p2compat`. Both were compiled locally, staged to `/berry/examples`, and run with focused `scripts/p2/repl_smoke.py --command 'run_file(...)'` checks, preserving the explicit no-fake-demo contract.
- [x] Re-ran the focused Catalina path audit after the native-sibling-Catalina cleanup: `make p2-catalina-path-audit TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed and reported that active P2 docs/tooling use the sibling Catalina path with no Docker Catalina references.
- [x] Repaired and hardware-verified the focused `examples/nco_counter_loopback.be` NCO-to-counter example on the current native-Catalina XMM image. The example now prints scalar probe fields instead of whole result maps. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/nco_counter_loopback.be")' --expect 'nco counter loopback done' --timeout 180 --startup-timeout 120` passed, reporting fast NCO counter delta `41` for increment `536870912`, slower delta `20` for increment `268435456`, and `nco counter loopback done`.
- [x] Repaired and hardware-verified the focused `examples/cog_closure_blink.be` closure-cog LED example on the current native-Catalina XMM image. The example now prints scalar capability/handle diagnostics instead of a whole capability map, stops/kills the spawned native-blink handles, floats pins `38` and `39`, and has a final `cog closure blink done` marker. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/cog_closure_blink.be")' --expect 'cog closure blink done' --timeout 180 --startup-timeout 120` passed, reporting handle policy `native_blink_info_stop_only`, native blink stack `2048`, handles `100` and `101` on cogs `6` and `7`, stopped/killed running `false`, and `cog closure blink done`.
- [x] Repaired and hardware-verified the legacy `examples/p2/` helper examples on the current native-Catalina XMM image. `examples/p2/blink.be` now uses the active board LED from `p2.status_info()`, runs a bounded blink, floats the pin, and reaches `p2 blink done`; `pin_helpers.be`, `smartpin_helpers.be`, and `timing_helpers.be` now have final markers and pass focused `run_file(...)` smokes; `hardware_helpers.be` now prints scalar clock/tick/CORDIC/cog/attention diagnostics instead of whole maps/lists and reaches `p2 hardware helpers done`; `closure_blinker.be` now stops/kills native-blink handles and reaches `p2 closure blinker done`; `cog_spawn_source_blinker.be` reports unsupported `spawn_source` on this build and reaches `p2 source blinker done`.
- [x] Repaired and hardware-verified the focused `examples/wifi/detect.be` AirLift/WiFi example on the current native-Catalina XMM image as a metadata-only diagnostic. The example no longer calls `wifi.init()`, `firmware_version()`, or `status()` and does not start SPI transactions; it prints `wifi.capabilities()`, `default_config()`, `audit()` and status-name metadata, then reaches `wifi detect done`. The first hardware run exposed a stale staged `/modules/wifi.be` without `capabilities()`; after uploading the current `modules/wifi.be`, the focused run passed and reported hardware `wifinina_airlift`, transport `spi`, deferred `true`, audit `true 0 metadata_only_no_spi_transaction`, pins `16 17 18 19 20 21 22`, and status names `connected no_shield`.
- [x] Repaired and hardware-verified the focused `examples/import_all_libs.be` quick import sweep with metadata-only `wifi` included. After staging the current `modules/wifi.be` and the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/import_all_libs.be")' --expect 'import all libs example done' --timeout 180 --startup-timeout 120` passed, importing `binary_heap`, `configstore`, `math`, `p2compat`, `p2ipc`, the active `task` backend, and `wifi`, then reporting `wifi audit: true true` before `import all libs example done`. Separate focused direct probes also passed the heavier import chain through `p2mem` and `p2smart` while keeping this example quick.
- [x] Hardware-verified the heavier Priority 1 import chain separately from the quick example on the current native-Catalina XMM image. A direct probe importing `binary_heap`, `configstore`, `math`, `p2compat`, `p2ipc`, `task`, `wifi`, and `p2mem` printed `P2_IMPORT_CHAIN_P2MEM true true`, and the full direct chain adding `p2smart` printed `P2_IMPORT_CHAIN_P2SMART true verified unverified`; `examples/import_all_libs.be` still excludes `p2mem` and `p2smart` because those source imports are slow and belong in focused probes rather than the user-facing quick sweep.
- [x] Extended and hardware-verified the focused Priority 2 low-level validation smoke with additional grouped API negative coverage. `make p2-smoke-p2-api PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` uploaded only `/tests/p2/smoke_p2_api.be` and passed on the current native-Catalina XMM image after adding negative checks for `p2.clock.waitus(-1)`, `waitms(-1)`, `waitsec(-1)`, grouped pin direction/output/toggle/float invalid pins, and PSRAM-reserved pin `57` direction/float rejection.
- [x] Closed the Priority 1 `/berry/lib` and `/berry/app` source-path item with focused hardware evidence on the current native-Catalina XMM image. Long `/tests/p2/smoke_import_*.be` names can collide on the target FAT view, so the verification staged only the relevant files under 8.3-safe aliases: `/tests/p2/ilayout.be` passed `P2_SMOKE_PASS import_layout`, `/tests/p2/iorder.be` passed `P2_SMOKE_PASS import_order`, and `/tests/p2/pkgpath.be` passed `P2_SMOKE_PASS package_paths` after cleaning only the known temporary package files `/berry/app/pkg/mod.be` and `/berry/app/pkg/other.be`.
- [x] Closed the Priority 1 import-resolution preservation items with focused current-XMM hardware evidence. After staging only 8.3-safe aliases, `/tests/p2/infirst.be` passed `P2_SMOKE_PASS import_native_first`, `/tests/p2/icwd.be` passed `P2_SMOKE_PASS import_cwd`, `/tests/p2/lpaths.be` passed `P2_SMOKE_PASS libstore_paths`, and `/tests/p2/syspath.be` passed `P2_SMOKE_PASS sys_path_add` with the expected `P2_SMOKE_SKIP sys_path_add` on the normal profile where optional `sys` is absent. This verifies native-module-first import precedence, active-cwd import precedence/cache identity, scoped `libstore.path_add()` diagnostics, and configured-path behavior without running the broad SD suite.
- [x] Closed the Priority 1 documented SD layout locations item with focused current-XMM hardware evidence. `/tests/p2/cfgstore.be` passed `P2_SMOKE_PASS configstore` for `/berry/config/*.json`; after changing `/tests/p2/smoke_example_paths.be` to use 8.3-safe temporary names, `/tests/p2/expath.be` passed `P2_SMOKE_PASS example_paths` for flat/nested `/berry/examples` helpers; after changing `/tests/p2/smoke_pasm_layout.be` to use stable `p2.asm.audit_ok()` / `audit_problems()` helpers instead of indexing the current image's string-shaped `audit()` result, `/tests/p2/pasmly.be` passed `P2_SMOKE_PASS pasm_layout` for `/berry/pasm` flat/nested blob paths, `p2.asm.load()`, marker-blob load, exact-fixture launch, non-marker rejection, missing-path diagnostics, and cleanup. A long `libstore.be` upload was interrupted once and then successfully retried alone with a longer timeout before these focused runs.
- [x] Tightened Priority 1 `.bec` metadata handling after focused fallback probing on the current native-Catalina XMM image: `libstore.info()` now reports compiled manifest/freshness/load/selection fields from current helper state instead of stale hardcoded values, `compile_cache_probe()` handles missing `file.savecode` as `bytecode_emit_unavailable`, `libstore` read helpers now close file handles explicitly, and new compiled-manifest candidates use 8.3-safe `.jsn` sidecars instead of creating unrecoverable `.bec.json` names on the P2 FAT view. Focused validation passed through `make p2-smoke-bec-fallback-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`; the larger `/tests/p2/smoke_bec_fallback.be` remains open and is not counted as closed evidence.
- [x] Repaired and hardware-verified the broader Priority 1 `.bec` source-fallback smoke on the current native-Catalina XMM image. `libstore.compile_cache_plan()` now reports selection reasons consistently without a heavy nested `resolve()` pass, invalid non-object manifest sidecars fail fast as `invalid_manifest`, missing-source manifest templates short-circuit before unnecessary `.bec` reads, and compiled load/status plans avoid bytecode validation when freshness already proves the file cannot load. `/tests/p2/smoke_bec_fallback.be` was bounded for P2 hardware by keeping core fallback/manifest/compiled-only/emit-plan checks and leaving heavier aggregate JSON/provision emit-report coverage to host tests. The staged 8.3-safe alias passed with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/tests/p2/becfall.be")' --expect 'P2_SMOKE_PASS bec_fallback' --timeout 480 --startup-timeout 120`.
- [x] Closed the Priority 2 USB pair wrapper item as explicitly unsupported until a real implementation exists. `p2smart` keeps `usb_pair` unsupported, `p2compat` reports `usb_hid` and `usb_demo` as unsupported, host and P2 p2compat smokes pin those records, docs name the limitation, and `examples/usb_keyboard_mouse.be` hardware-runs to `usb keyboard mouse done` while reporting the unsupported records instead of faking HID behavior.
- [x] Closed the Priority 1 host-like API documentation item. `p2compat` is now the backed compatibility ledger for bare-metal P2: supported/staged/partial/unsupported capabilities are queryable, unsupported host-like APIs such as environment variables, subprocesses, generic sockets, native host threads, VGA/video, and USB/HID are pinned by host and P2 smokes, and `docs/limitations.md`, `docs/p2-api.md`, and `docs/coverage-matrix.md` state that these are unsupported instead of hidden stubs.
- [x] Closed the Priority 1 focused-smoke-entrypoint item. `scripts/p2/repl_smoke.py` exposes direct already-staged suites for `import-cache`, `import-churn`, `libraries`, `libraries-lazy-min`, and `priority1`, plus quick inline `priority1-min`, while `mk/p2.mk` provides focused wrappers including quick no-upload `p2-smoke-priority1`, staged broad `p2-smoke-priority1-staged`, `p2-smoke-libraries-lazy-min`, `p2-smoke-core-builtins-min`, `p2-smoke-sd-file-min`, and `p2-smoke-bec-fallback-min`. `docs/testing.md` and `docs/coverage-matrix.md` document using these smaller entrypoints instead of broad suites for routine progress. Hardware validation passed with `make p2-smoke-priority1 PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_P1_BUILTINS 42 9 true instance 0 list map`, `P2_P1_COLLECTIONS 3 4 3 3 true`, `P2_P1_SD ok`, and `P2_SMOKE_PASS priority1_min`.
- [x] Turned `examples/smartpin_diagnostics.be` into a practical four-jumper health check for the documented `0-1`, `2-3`, `4-5`, and `6-7` wiring instead of a single-pair demo. After staging only the updated example and current `modules/p2smart.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/smartpin_diagnostics.be")' --expect 'smartpin diagnostics done' --timeout 360 --startup-timeout 120` passed on the native-Catalina XMM image, with all four pairs reporting `ok true`, `8 / 8` checks, GPIO loopback, high-counter deltas, pulse/transition counts, async serial, and async drain matches.
- [x] Upgraded quadrature from static-only example coverage to synthetic motion/direction proof using the documented jumper wiring. The new focused `/tests/p2/smoke_smartpins_quadrature_motion.be` drives pins `0` and `2` into quadrature inputs `1` and `3`; the hardware run passed with `P2_SMOKE_QUAD_FORWARD 0 8 8 1 true`, `P2_SMOKE_QUAD_REVERSE 0 -8 -8 -1 true`, and `P2_SMOKE_PASS smartpins_quadrature_motion`. `examples/quadrature_counter.be` now uses the same two-jumper pattern and hardware-runs to `quadrature counter done`, printing forward direction `1` and reverse direction `-1`.
- [x] Added and hardware-verified `examples/task_ipc.be`, a compact Priority 4 user-facing demo for cooperative task waits over current-VM IPC objects. After staging current `modules/task.be`, `modules/p2ipc.be`, and the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/modules/task.be"); run_file("/berry/examples/task_ipc.be")' --expect 'task ipc example done' --timeout 300 --startup-timeout 120` passed on the native-Catalina XMM image. The run showed channel receive wait released by `send_result("ready")`, channel send wait released after freeing a full channel, mailbox get wait released by `put_result("mail-ready")`, and mailbox put wait released after freeing a full mailbox.
- [x] Repaired and hardware-verified `examples/cog_closure.be` on the current native-Catalina XMM image. The example now avoids stale/optional `status()` and `join()` map keys, prints scalar status fields plus the returned join snapshots and `p2.cog.result()` / `p2.cog.error()` values, then stops/kills the native-blink handles and floats pins `38` and `39`. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/cog_closure.be")' --expect 'cog closure example done' --timeout 240 --startup-timeout 120` passed, reporting handles `100` and `101`, result values `150` and `450`, stop/kill running `false`, and `cog closure example done`.
- [x] Repaired and hardware-verified the native `p2.cog` handle return contract on the current native-Catalina XMM image. `p2.cog.join(handle)` now returns a compact nonblocking result snapshot with `joined`, `blocking`, `join_policy`, `result`, `result_type_name`, and `error`; `p2.cog.audit()` returns a structured map with real list values instead of a string/unknown map shape; `p2.cog.stop(handle)` / `kill(handle)` return cleanup diagnostics including `cleanup_attempted`, `cleanup_policy`, resource-release booleans, `slot_released`, and `handle_valid_after_stop == false`. After flashing with `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2`, focused hardware validation passed through `make p2-smoke-pasm-policy-min`, `make p2-smoke-cog-closure`, and `make p2-smoke-cog-policy-min` on image `1054080 / 16777216`.
- [x] Repaired and hardware-verified `p2.cog.wait_attention()` on the current native-Catalina XMM image. The native helper now waits interruptibly by polling `_pollatn()` with `p2_check_interrupt_now()` instead of depending on the raw `_waitatn()` return value, and `/tests/p2/smoke_p2_api.be` now asserts that a pre-signaled self-attention mask is returned by `wait_attention()`. After flashing with `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2`, `make p2-smoke-p2-api PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed on image `1054144 / 16777216`.
- [x] Hardened and hardware-verified public cog-stop self-protection on the current native-Catalina XMM image. `p2.cog.stop(p2.cog.id())` and the flat raw cog stop helper now raise `value_error` instead of stopping the current VM/REPL cog, and `/tests/p2/smoke_p2_api.be` covers the grouped self-stop rejection. After flashing with `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2`, `make p2-smoke-p2-api PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed on image `1054368 / 16777216`.
- [x] Hardware-verified safe non-current `p2.cog.stop(cog_id)` execution on the current native-Catalina XMM image. `/tests/p2/smoke_cog_closure.be` now spawns a native-blink handle, records the child cog id, confirms it is not the current VM cog, stops it through `p2.cog.stop(raw_cog)`, verifies `p2.cog.check(raw_cog) == 0`, then releases the handle/slot through `p2.cog.kill(handle)` and confirms the registry is empty. `make p2-smoke-cog-closure PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed on image `1054368 / 16777216`.
- [x] Added bounded closure-cog lifecycle stress coverage to the focused hardware smoke. `/tests/p2/smoke_cog_closure.be` now runs a three-iteration native-blink spawn/join/kill loop, checks each join result/error snapshot, verifies cleanup diagnostics, and confirms `p2.cog.info().size() == 0` after each iteration. `make p2-smoke-cog-closure PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed on image `1054368 / 16777216`.
- [x] Added focused closure-cog spawn rejection cleanup coverage. `/tests/p2/smoke_cog_closure.be` now checks unsupported closure shape, setup-function exception, and unsupported live-object argument cases, and verifies `p2.cog.info().size() == 0` after each rejected spawn. `make p2-smoke-cog-closure PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed on image `1054368 / 16777216`.
- [x] Repaired the focused sync-serial smart-pin diagnostic so phase-variant helpers cannot wedge the board. `p2smart.sync_serial_clocked_variant_probe(...)` and the default aggregate variant helper now return explicit `execution_deferred` planning records, while `/tests/p2/smoke_smartpins_sync_diag.be` still hardware-verifies the bounded normal clocked data/clock probe shape. `make p2-smoke-smartpins-sync-diag PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed on image `1054368 / 16777216`.
- [x] Added result-shaped cooperative scheduler diagnostics to the source task module. `task.next_result()` reports one scheduler step with handle/status/live-count/result/error fields, and `task.run_result(max_steps, idle_ms)` reports bounded run summary fields without requiring callers to infer state from side effects. Host and hardware coverage now assert these helpers plus their capability/contract metadata: `./berry tests/p2/host_task.be` passed locally, and `make p2-smoke-task PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed on image `1054368 / 16777216`.
- [x] Added non-mutating IPC readiness diagnostics for current-VM channels and mailboxes. `Channel.ready_result(mode)` reports `recv`/`send` readiness plus `get`/`put` aliases, and `Mailbox.ready_result(mode)` reports `get`/`put` readiness plus `recv`/`send` aliases; both return closed and invalid-mode diagnostics without consuming payloads. Focused validation passed with `./berry tests/p2/host_p2ipc.be` and `make p2-smoke-ipc PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` on image `1054368 / 16777216`.
- [x] Updated and hardware-verified the user-facing `examples/cog_channel.be` IPC example to print scalar readiness diagnostics. After staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/cog_channel.be")' --expect 'cog channel example done' --timeout 240 --startup-timeout 120` passed on image `1054368 / 16777216`, showing channel full readiness `true false true false`, channel empty readiness `false true false true`, mailbox full readiness `true false true false`, mailbox empty readiness `false true false true`, and `cog channel example done`.
- [x] Updated and hardware-verified the user-facing `examples/task_ipc.be` cooperative task/IPC example to print scalar p2ipc readiness transitions around each `task.wait()` path. After staging only the example and preloading the source task module, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/modules/task.be"); run_file("/berry/examples/task_ipc.be")' --expect 'task ipc example done' --timeout 300 --startup-timeout 120` passed on image `1054368 / 16777216`, showing channel receive/send and mailbox get/put readiness false before release and true after the producer/consumer action, then closed channel/mailbox wakes reporting `closed`, then `task ipc example done`.
- [x] Added `task.ready_result(target, mode, extra)` as a non-mutating readiness diagnostic for current-VM task wait targets: events, queues, p2ipc channels/mailboxes, semaphores, mutexes, timers, and event flags. Focused validation passed with `./berry tests/p2/host_task.be` and `make p2-smoke-task PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` on image `1054368 / 16777216`.
- [x] Added non-mutating IPC lifecycle/resource diagnostics. `Channel`, `Mailbox`, `Buffer`, and `Mutex` now expose `lifecycle_result()`, and `p2ipc.lifecycle_result(obj)` provides the generic helper; the result maps report usable/closed state, pending payload references, held hardware-lock resources, cleanup policy, and the explicit current-VM/no-serialization/no-ownership-transfer boundary. Focused validation passed with `./berry tests/p2/host_p2ipc.be` and `make p2-smoke-ipc PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` on image `1054368 / 16777216`.
- [x] Updated and hardware-verified the user-facing `examples/cog_channel.be` IPC example to print scalar lifecycle/resource diagnostics alongside readiness and cleanup state. After staging current `modules/p2ipc.be` and the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/cog_channel.be")' --expect 'cog channel example done' --timeout 240 --startup-timeout 120` passed on image `1054368 / 16777216`, showing live/full/closed channel and mailbox lifecycle state plus shared-buffer lifecycle state before `cog channel example done`.
- [x] Added `task.lifecycle_result(handle)` as a non-mutating task slot lifecycle and wait-state diagnostic. It reports allocated/free/invalid state, status, run/wakeup counts, last result/error, wait kind, wait target kind, wait mode/value/event, deadline, and remaining wait time without mutating the scheduler. Focused validation passed with `./berry tests/p2/host_task.be` and `make p2-smoke-task PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` on image `1054368 / 16777216`.
- [x] Made current-VM task waits over `p2ipc` channels/mailboxes wake when the object is closed. Receive/send/get/put waiters can now observe the result-shaped `closed` error and clean up instead of waiting for timeout. Focused validation passed with `./berry tests/p2/host_task.be` and `make p2-smoke-task PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` on image `1054368 / 16777216`.
- [x] Updated and hardware-verified `examples/task_ipc.be` to demonstrate the new closed-object wake behavior. After staging current `modules/task.be`, `modules/p2ipc.be`, and the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/modules/task.be"); run_file("/berry/examples/task_ipc.be")' --expect 'task ipc example done' --timeout 300 --startup-timeout 120` passed on image `1054368 / 16777216`, printing `channel close wake: closed status free` and `mailbox close wake: closed status free`.
- [x] Added `task.reset_result()` as a result-shaped cleanup diagnostic for the cooperative scheduler. It reports the active task and signaled-event counts released by reset plus before/after cleanup counters, and its capability/contract/audit metadata is pinned by focused task coverage. Validation passed with `./berry tests/p2/host_task.be` and `make p2-smoke-task PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` on image `1054368 / 16777216`.
- [x] Improved the staged sync-serial smart-pin diagnostics without changing the risky execution path. `p2smart.sync_serial_clocked_probe(...)` now reports explicit `tx_mode`, `rx_mode`, `clock_mode`, `receive_status`, `receive_policy`, `matched_receive_words`, and `execution_supported` fields, and deferred variant records carry the same policy/status shape while remaining non-executing. Focused validation passed with `./berry tests/p2/host_p2smart.be`, `make p2-smoke-smartpins-sync-diag PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and a hardware run of `examples/spi_loopback.be` to `sync serial probe done` on image `1054368 / 16777216`.
- [x] Added direct PASM metadata lookup helpers to the native `p2.asm` facade. `p2.asm.capability(name)` and `p2.asm.abi_value(name)` return one known capability/ABI field or `nil` for unknown/non-string names, with flat lazy lookup aliases `p2.asm_capability` and `p2.asm_abi_value` also registered. The focused policy smoke now pins those helpers against the existing map fields, `examples/pasm_direct.be` demonstrates direct lookup for arbitrary-blob/function-bridge policy and ABI status/argument, and the docs now describe the compact query surface. After flashing with `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2`, `make p2-smoke-pasm-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed and the example hardware-ran to `pasm direct done` on image `1059520 / 16777216`.
- [x] Added aggregate closure-cog cleanup for interactive Priority 4 work. `p2.cog.cleanup_result()` stops and releases every spawned closure-cog slot and reports released handles, stopped raw cogs, floated pins, resource-release counters, and empty-registry state; `p2.cog.capabilities()` / `required_capability_keys()` / `audit()` now expose the `cleanup_all_policy`. `/tests/p2/smoke_cog_closure.be` hardware-verifies aggregate cleanup of two live native-blink handles plus empty cleanup, while `examples/cog_closure.be` now uses the aggregate cleanup path and prints the release/empty diagnostics. After flashing with `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2`, `make p2-smoke-cog-closure PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed and the example hardware-ran to `cog closure example done` on image `1062112 / 16777216`.
- [x] Added direct closure-cog capability lookup. `p2.cog.capability(name)` and flat lazy lookup `p2.cog_capability` return one known native-blink handle/cleanup capability field or `nil`, matching the compact query style used by the source modules and `p2.asm`. The focused policy smoke now pins direct lookup for native-blink support, handle model, cleanup policy, missing names, and non-string names, and `examples/cog_closure.be` uses the direct helper for user-facing policy output. After flashing with `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2`, `make p2-smoke-cog-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed and the example hardware-ran to `cog closure example done` on image `1066304 / 16777216`.
- [x] Added a fixed named-operation PASM mailbox fixture-call proof under the native `p2.asm` facade. `p2.asm.fixture_call(operation, lhs, rhs, target_cog=nil)` copies a Catalina-assembled PASM fixture generated from `tools/p2/pasm/fixture_call.pasm`, passes an operation code plus two integer arguments through a Hub mailbox in `PTRA`, returns one integer result plus cog-id/cleanup diagnostics, and stops the child cog after completion. Supported fixture operations are `add`, `sub`, `xor`, `and`, and `or`; `p2.asm.fixture_add(lhs, rhs, target_cog=nil)` remains the add wrapper. Capability/ABI metadata reports `fixture_call == true`, `fixture_call_policy == "fixed_named_operation_fixture_mailbox_only"`, `fixture_call_ops`, and `status == "marker_and_fixture_call_only"` while keeping the general PASM function bridge explicitly unsupported as `unsupported_no_calling_convention`. After flashing with `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina LOADP2=/usr/local/bin/loadp2`, `make p2-smoke-pasm-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed and `examples/pasm_direct.be` hardware-ran to `pasm direct done`, printing fixture add result `42`, fixture sub result `42`, and fixture xor result `90`, on image `1071680 / 16777216`.
- [x] Made the native P2 `import task` backend the practical hardware path for basic cooperative task usage. The native backend now exposes Spin2-style aliases `spin`, fixed-slot startup, `halt`/`hlt`, `cont`, `chk`, and `id`, plus compact `capabilities()`, direct `capability(name)`, `attention_policy()`, `execution_model()`, `contract()`, `required_capability_keys()`, and `audit_ok()` metadata without source-loading the large `modules/task.be`. After flashing with `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make p2-smoke-task-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed on image `1090944 / 16777216`, verifying native metadata, first-free `spin`, fixed-slot `spin`, `halt`/`cont`, `chk`, and `id`.
- [x] Added result-shaped diagnostics to the native P2 `import task` backend so user code can inspect scheduler operations without source-loading `modules/task.be`. Native `task.start_result()`, `next_result()`, `run_result()`, `stop_result()`, `pause_result()`, `resume_result()`, `reset_result()`, and `lifecycle_result()` now return compact maps, and native capability/contract metadata reports the result surface. After flashing with `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make p2-smoke-task-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed on image `1104128 / 16777216`, verifying result metadata, start/lifecycle/next/run/reset result helpers, and pause/resume/stop result helpers.
- [x] Added native P2 task event readiness and cleanup helpers to the practical `import task` path. Native `task.ready_result("event")` and `task.ready_result(task.wait("event"))` now return non-mutating readiness diagnostics for signaled string events, `task.events()` returns the current signaled event list, and `task.clear_all()` clears native scheduler event state; capability/contract metadata reports `event_readiness_result`, `event_inspection`, and `clear_all_events`. After building and flashing with sibling Catalina (`make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`), `make p2-smoke-task-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` and `make p2-smoke-priority1-4-min-staged PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed on image `1107072 / 16777216`.
- [x] Added a compact native P2 `task.Queue(depth)` primitive to the practical `import task` path. The native Queue stores items in normal Berry list state and exposes `put`, `put_result`, `get`, `get_result`, `size`, `free`, and `info`, with result diagnostics that distinguish queued `nil` payloads from full/empty states. Capability/contract metadata reports `native_queue` and `queue_result_diagnostics`. After building and flashing with sibling Catalina (`make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`), `make p2-smoke-task-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed and verified nil-payload put/get, full, empty, info, and direct capability lookup on image `1113408 / 16777216`. `make p2-smoke-priority1-4-min-staged PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` also passed on the same image.
- [x] Added a compact native P2 `task.Semaphore(count)` primitive to the practical `import task` path. The native Semaphore stores count state in the Berry instance and exposes `take`, `take_result`, `give`, `give_result`, `value`, and `info`, with unavailable diagnostics when the count is zero. Capability/contract metadata reports `native_semaphore` and `semaphore_result_diagnostics`. After building and flashing with sibling Catalina (`make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`), `make p2-smoke-task-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed and verified take/unavailable/give/value/info plus direct capability lookup on image `1116640 / 16777216`. `make p2-smoke-priority1-4-min-staged PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` also passed on the same image.
- [x] Added a compact native P2 `task.Mutex()` primitive to the practical `import task` path. The native Mutex stores lock and owner state in the Berry instance and exposes `lock`, `lock_result`, `unlock`, `unlock_result`, `owner`, `is_locked`, and `info`, with busy and not-locked diagnostics. Capability/contract metadata reports `native_mutex` and `mutex_result_diagnostics`. After building and flashing with sibling Catalina (`make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`), `make p2-smoke-task-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed and verified lock/busy/unlock/not-locked/info plus direct capability lookup on image `1121440 / 16777216`. `make p2-smoke-priority1-4-min-staged PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` also passed on the same image.
- [x] Added a compact native P2 `task.EventFlags(initial=0)` primitive to the practical `import task` path. The native EventFlags stores integer flag state in the Berry instance and exposes `set`, `set_result`, `clear`, `clear_result`, `value`, `ready`, `ready_result`, `wait`, and `info`, with invalid-mask and not-ready diagnostics. Capability/contract metadata reports `native_event_flags` and `event_flags_result_diagnostics`. After building and flashing with sibling Catalina (`make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`), `make p2-smoke-task-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed and verified set/ready/all/not-ready/clear/invalid-mask/info plus direct capability lookup on image `1128736 / 16777216`. `make p2-smoke-priority1-4-min-staged PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` also passed on the same image.
- [x] Added a compact native P2 `task.Timer(period_ms=10, repeat=true)` primitive to the practical `import task` path. The native Timer stores deadline/active/repeat state in the Berry instance and exposes `expired`, `expired_result`, `remaining`, `remaining_result`, `restart`, `restart_result`, `cancel`, `cancel_result`, and `info`, with not-expired, inactive, one-shot expiry, repeating expiry, restart, and remaining-time diagnostics. Capability/contract metadata reports `native_timer` and `timer_result_diagnostics`. After building and flashing with sibling Catalina (`make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`), `make p2-smoke-task-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed and verified non-expired, zero-period one-shot expiry/cancel/inactive remaining, zero-period repeating expiry/restart/info, and direct capability lookup on image `1136192 / 16777216`. `make p2-smoke-priority1-4-min-staged PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` also passed on the same image.
- [x] Added native primitive-object readiness diagnostics to the practical `import task` path. `task.ready_result(obj, mode=nil, extra=nil)` now reports non-mutating readiness maps for native Semaphore take, Mutex lock, Queue get/put, EventFlags any/all masks, and Timer expiry, and metadata reports `primitive_readiness_result`. After building and flashing with sibling Catalina (`make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`), `make p2-smoke-task-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed and verified each native primitive readiness path plus direct capability lookup on image `1143712 / 16777216`. `make p2-smoke-priority1-4-min-staged PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` also passed on the same image.
- [x] Added native P2 `task.ready_result()` delegation for current-VM `p2ipc` channel and mailbox objects in the practical `import task` path. The native backend now reports `p2ipc_object_readiness_result` and returns the source object readiness maps for channel receive/send and mailbox get/put states, including full/empty/closed diagnostics, without source-loading `modules/task.be` or claiming native scheduler waits/cross-cog IPC wakeups. After building and flashing with sibling Catalina (`make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`), `make p2-smoke-task-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed with the new p2ipc readiness probes on image `1144960 / 16777216`. `make p2-smoke-priority1-4-min-staged PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` also passed on the same image.
- [x] Added native P2 scheduler waits over current-VM `p2ipc` channel and mailbox objects in the practical `import task` path. Native `task.wait(channel, "recv"/"send", timeout)` and `task.wait(mailbox, "get"/"put", timeout)` now retain the object in the task registry while blocked, poll the object's `wait_ready(mode)` hook during cooperative scheduler steps, wake on readiness or close, and report `p2ipc_object_waits` in capability/contract metadata without claiming cross-cog IPC wakeups or serialization. After building and flashing with sibling Catalina (`make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`), `make p2-smoke-task-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed on image `1151008 / 16777216`, verifying channel recv wake after send, mailbox put wake after get, and channel recv wake after close.
- [x] Added native P2 scheduler waits over native task primitives in the practical `import task` path. Native `task.wait(queue, "get"/"put", timeout)`, `task.wait(semaphore, timeout)`, `task.wait(mutex, timeout)`, `task.wait(event_flags, mask, mode, timeout)`, and `task.wait(timer, timeout)` now retain the object in the task registry while blocked and poll the same current-VM readiness state used by `task.ready_result(...)`; capability/contract metadata reports `primitive_object_waits`. After building and flashing with sibling Catalina (`make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`), `make p2-smoke-task-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed on image `1158720 / 16777216`, verifying Queue get wake after put, Semaphore wake after give, Mutex wake after unlock, EventFlags all-mask wake after set, and Timer expiry wake.
- [x] Converted and hardware-verified the user-facing task examples on the practical native `import task` path. `examples/task_scheduler.be` now uses `task.lifecycle_result(task.current())["runs"]` instead of the source-only `task.task_info()` helper, and `examples/task_scheduler.be`, `examples/task_primitives.be`, and `examples/task_ipc.be` were staged with current `modules/p2ipc.be` and run directly without `run_file("/modules/task.be")`. `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/task_scheduler.be")' --expect 'task scheduler example done' --command 'run_file("/berry/examples/task_primitives.be")' --expect 'task primitives example done' --command 'run_file("/berry/examples/task_ipc.be")' --expect 'task ipc example done' --timeout 300 --startup-timeout 120` passed on image `1158720 / 16777216`, covering scheduler lifecycle, Queue/EventFlags/Timer primitive diagnostics, native primitive waits, current-VM p2ipc channel/mailbox waits, and closed channel/mailbox wakeups.
- [x] Made the user-facing `examples/spi_loopback.be` synchronous-serial example safer by avoiding the risky sync receive execution path by default. The example now reports `p2smart.sync_serial_receive_policy()`, prints the normal clocked TX/RX/clock mode plan for the documented `0-1` data and `2-3` clock jumpers, marks receive execution as deferred, and reaches `sync serial probe done` without running the clocked receive probe. After an interrupted large-module upload, `modules/p2smart.be` was restored with `python3 scripts/p2/repl_upload.py --port /dev/ttyUSB0 --baud 230400 --timeout 120 --target-dir /modules --file modules/p2smart.be`, `import p2smart; print("P2SMART_IMPORT_OK")` passed, and `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/spi_loopback.be")' --expect 'sync serial probe done' --timeout 300 --startup-timeout 120` passed on image `1158720 / 16777216`.
- [x] Converted the user-facing `examples/spi_loopback.be` synchronous-serial example to the fast native `p2.smart` constant path. The example now imports only native `p2`, prints the documented `0-1` data and `2-3` clock mode plan, keeps matched receive words explicitly unverified/deferred, and avoids the large `p2smart` source-module import that made a simple example wait through roughly 85 seconds of import/compile time. Local compile passed with `./berry -c examples/spi_loopback.be -o /tmp/spi_loopback.bec`; after staging only the example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/spi_loopback.be")' --expect 'sync serial probe done' --timeout 120 --startup-timeout 120` passed in about 6 seconds on image `1158720 / 16777216`, printing TX mode `33620088`, RX mode `33620026`, clock mode `72`, and `receive execution deferred`.
- [x] Added native P2 direct metadata lookup helpers to the practical `import task` backend. Native `task.contract_value(name)`, `task.attention_policy_value(name)`, and `task.execution_model_value(name)` now match the source-module compact lookup shape and are advertised through `task.capability(...)` / `task.capabilities()` / `required_capability_keys()`, so scripts can query one scheduler-boundary field without allocating/parsing the full maps. Built and flashed with sibling Catalina (`make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`); `make p2-smoke-task-policy-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed on image `1165696 / 16777216`, including `TASK_NATIVE_META_VALUES current_vm_callback_step native_attention_event_current_vm_only p2_native_cooperative true true`.
- [x] Repaired and hardware-verified the native SPI JEDEC example as a bounded user-facing diagnostic. `examples/spi/jedec.be` now prints the configured pins/mode/rate, wraps select/transfer in cleanup so `spi.deselect()` / `spi.stop()` run on errors, reports the four-byte response length and raw bytes, and reaches a stable `spi jedec done` marker without claiming a specific attached SPI flash ID. Local compile passed with `./berry -c examples/spi/jedec.be -o /tmp/spi_jedec.bec`; after staging only the example under `/berry/examples/spi`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/spi/jedec.be")' --expect 'spi jedec done' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`, printing response length `4` and raw `0xff` bytes on the current wiring.
- [x] Repaired and hardware-verified the native I2C scan example as a bounded user-facing BMP180 diagnostic. `examples/i2c/scan.be` now prints scalar SCL/SDA/rate setup, scan count, BMP180 presence, chip-id value, chip-id match status, cleans up with `i2c.stop()` on error, and reaches a stable `i2c scan done` marker. Local compile passed with `./berry -c examples/i2c/scan.be -o /tmp/i2c_scan.bec`; after staging only the example under `/berry/examples/i2c`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/i2c/scan.be")' --expect 'i2c scan done' --timeout 180 --startup-timeout 120` passed on image `1165696 / 16777216`, printing scan count `1`, `bmp180 present: true`, chip id `U`, and `bmp180 chip id ok: true`.
- [x] Repaired and hardware-verified the focused `examples/spin2/*.be` examples for the default firmware boundary. `list.be`, `mailbox_demo.be`, `mailbox_suite.be`, and `standalone_suite.be` now use `introspect.module("spin2")` instead of unconditional `import spin2`, so normal builds where Spin2 is archived report `spin2 default build: module archived` and still reach stable done markers; archived Spin2-enabled builds still run the original list/mailbox/standalone behavior. Local compile passed for all four examples with `./berry -c ...`; after staging only those files under `/berry/examples/spin2`, one focused hardware smoke passed on image `1165696 / 16777216`: `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/spin2/list.be")' --expect 'spin2 list done' --command 'run_file("/berry/examples/spin2/mailbox_demo.be")' --expect 'spin2 mailbox demo done' --command 'run_file("/berry/examples/spin2/mailbox_suite.be")' --expect 'spin2 mailbox suite done' --command 'run_file("/berry/examples/spin2/standalone_suite.be")' --expect 'spin2 standalone suite done' --timeout 180 --startup-timeout 120`.
- [x] Repaired and hardware-verified `examples/core/run_file_demo.be` for the P2 staged example layout. The demo now checks `/berry/examples/core/run_file.be` first, then desktop fallback paths, prints the selected path, runs the target, and reaches `run_file demo done`. Local validation passed with `./berry -c examples/core/run_file_demo.be -o /tmp/run_file_demo.bec` and `./berry examples/core/run_file_demo.be`; after staging only `examples/core/run_file.be` and `examples/core/run_file_demo.be` under `/berry/examples/core`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/core/run_file_demo.be")' --expect 'run_file demo done' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`, printing the P2 path and `run_file target executed`.
- [x] Repaired and hardware-verified `examples/core/listdir.be` for the P2 staged example layout. The original recursive `scandir(".")` example was not bounded for the SD card and the first P2 repair exposed a target list-iterator hang after printing the three `/berry/examples/core` entries, so the example now lists a bounded number of entries with indexed list access. Local validation passed with `./berry -c examples/core/listdir.be -o /tmp/listdir.bec` and `./berry examples/core/listdir.be`; after staging only `examples/core/listdir.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/core/listdir.be")' --expect 'listdir demo done' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`, printing `/berry/examples/core`, entry count `3`, `RUN_FILE.BE`, `RUN_FILE._DE`, `LISTDIR.BE`, and `listdir demo done`.
- [x] Repaired and hardware-verified `examples/core/bigloop.be` as a bounded quick loop demo. The original timing benchmark imported unavailable `time` on P2 and ran two 100,000,000-iteration loops; target probing also showed both range and literal-list `for` iterator forms can hang on the current image, so the example now demonstrates the safe bounded `while` loop and explicitly skips the iterator path. Local validation passed with `./berry -c examples/core/bigloop.be -o /tmp/bigloop.bec` and `./berry examples/core/bigloop.be`; after staging only `examples/core/bigloop.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/core/bigloop.be")' --expect 'bigloop demo done' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`, printing `while iterations: 100`, `for iterator demo: skipped on current P2 image`, and `bigloop demo done`.
- [x] Repaired and hardware-verified `examples/core/fib_rec.be` as a quick recursion sanity example. The original example imported unavailable `time` on P2 and computed expensive `fib(38)`; it now computes `fib(10) == 55` and reaches `fib recursion demo done`. Local validation passed with `./berry -c examples/core/fib_rec.be -o /tmp/fib_rec.bec` and `./berry examples/core/fib_rec.be`; after staging only `examples/core/fib_rec.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/core/fib_rec.be")' --expect 'fib recursion demo done' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`, printing `fib: 10 55`.
- [x] Hardware-verified `examples/core/calcpi.be` as a quick floating-point while-loop example. The example now has stable scalar output and a `calcpi demo done` marker. Local validation passed with `./berry -c examples/core/calcpi.be -o /tmp/calcpi.bec` and `./berry examples/core/calcpi.be`; after staging only `examples/core/calcpi.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/core/calcpi.be")' --expect 'calcpi demo done' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`, printing `pi terms: 100 value: 3.14159`.
- [x] Repaired and hardware-verified `examples/core/json.be` as a compact native JSON example. The example now prints scalar parse/dump diagnostics and a `json core demo done` marker instead of dumping raw maps only. Local validation passed with `./berry -c examples/core/json.be -o /tmp/core_json.bec` and `./berry examples/core/json.be`; after staging only `examples/core/json.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/core/json.be")' --expect 'json core demo done' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`, printing key value `value`, nil dump `{"test key":null}`, formatted size `32`, and `json core demo done`.
- [x] Repaired and hardware-verified `examples/core/anon_func.be` as a quick closure example. The example now uses indexed `while` loops for closure creation/invocation instead of `for` iterators that hang on the current image, prints scalar square results, and reaches `anonymous closure demo done`. Local validation passed with `./berry -c examples/core/anon_func.be -o /tmp/anon_func.bec` and `./berry examples/core/anon_func.be`; after staging only `examples/core/anon_func.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/core/anon_func.be")' --expect 'anonymous closure demo done' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`, printing squares `0` through `36`.
- [x] Repaired and hardware-verified `examples/core/qsort.be` as a deterministic recursive sort example. The example now uses a fixed small list instead of unavailable target `time`/`math` imports and range iteration, prints before/after lists, and reaches `qsort demo done`. Local validation passed with `./berry -c examples/core/qsort.be -o /tmp/qsort.bec` and `./berry examples/core/qsort.be`; after staging only `examples/core/qsort.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/core/qsort.be")' --expect 'qsort demo done' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`, printing `[42, 7, 19, 3, 42, 0, 11]` and sorted `[0, 3, 7, 11, 19, 42, 42]`.
- [x] Repaired and hardware-verified `examples/core/lambda.be` as a compact lambda/Y-combinator example. The example now prints stable scalar output, uses bounded `fact(6)` instead of `fact(10)`, and reaches `lambda demo done`. Local validation passed with `./berry -c examples/core/lambda.be -o /tmp/lambda.bec` and `./berry examples/core/lambda.be`; after staging only `examples/core/lambda.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/core/lambda.be")' --expect 'lambda demo done' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`, printing `lambda result: 10` and `fact(6): 720`.
- [x] Repaired and hardware-verified `examples/core/bintree.be` as a deterministic binary-tree sort example. The existing example failed locally because child nodes were constructed as `node(v)` without explicit `nil` child fields, so later inserts could treat a scalar as a node; the example now initializes `node(v, nil, nil)`, prints count/first/last/sorted diagnostics, and reaches `bintree demo done`. Local validation passed with `./berry -c examples/core/bintree.be -o /tmp/bintree.bec` and `./berry examples/core/bintree.be`; after staging only `examples/core/bintree.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/core/bintree.be")' --expect 'bintree demo done' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`, printing count `9`, first/last `-100 10000000`, and sorted list `[-100, -10, -1, 1, 3, 5, 9, 10, 10000000]`.
- [x] Repaired and hardware-verified `examples/core/string.be` as a stable native string-module example. The original example used wide shift arithmetic that produced target-dependent output on P2, so it now demonstrates `string.hex()` on a common 32-bit value and uses a small modulo/divide binary helper with stable padded and unpadded output. Local validation passed with `./berry -c examples/core/string.be -o /tmp/core_string.bec` and `./berry examples/core/string.be`; after staging only `examples/core/string.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/core/string.be")' --expect 'string demo done' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`, printing `hex: 5678ABCD`, `binary: 100001`, `binary padded: 00100001`, and `string demo done`.
- [x] Repaired and hardware-verified `examples/core/strmod.be` as a stable native `string.format()` example. The example now labels each formatted value and has a final `string format demo done` marker. Local validation passed with `./berry -c examples/core/strmod.be -o /tmp/core_strmod.bec` and `./berry examples/core/strmod.be`; after staging only `examples/core/strmod.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/core/strmod.be")' --expect 'string format demo done' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`, printing padded integer, fixed/width float, left/right text formatting, and `string format demo done`.
- [x] Made `examples/core/exception.be` safe on the current P2 image. A first repair exposed `import_error: module 'debug' not found`; after guarding/removing `debug`, both the staged example using `try/except` and a direct REPL probe `try 1 / 0 except .. as e, v print("TRY_OK", e) end` timed out waiting for the prompt on image `1165696 / 16777216`, so the user-facing example now explicitly skips exception execution on this firmware and reaches `exception demo done` instead of hanging. Local validation passed with `./berry -c examples/core/exception.be -o /tmp/core_exception.bec` and `./berry examples/core/exception.be`; after staging only `examples/core/exception.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/core/exception.be")' --expect 'exception demo done' --timeout 120 --startup-timeout 120` passed, printing the skip reason and `exception demo done`.
- [x] Repaired and hardware-verified `examples/core/guess_number.be` as an interactive input example on the current P2 image. The original example imported unavailable `time` and seeded random state, so it now uses a deterministic answer `42`, keeps the `input()` prompt path, and reaches `guess number demo done`. `scripts/p2/repl_smoke.py` now accepts custom `--input-marker` and `--input-text` values for `--command` checks, matching the existing suite-level input handshake. Local validation passed with `./berry -c examples/core/guess_number.be -o /tmp/core_guess_number.bec` and `printf '42\n' | ./berry examples/core/guess_number.be`; after staging only `examples/core/guess_number.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/core/guess_number.be")' --expect 'guess number demo done' --input-marker 'enter the number you guessed:' --input-text '42' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`, printing the prompt, echoed `42`, `You win!`, and `guess number demo done`.
- [x] Repaired and hardware-verified `examples/core/repl.be` as a bounded interactive mini-REPL demo on the current P2 image. The original infinite REPL used compile-time `try/except` paths plus optional `debug`, which are unsafe or unavailable on this firmware, so the example now accepts one line, exits cleanly on `quit`, and reaches `repl demo done`. Local validation passed with `./berry -c examples/core/repl.be -o /tmp/core_repl.bec` and `printf 'quit\n' | ./berry examples/core/repl.be`; after staging only `examples/core/repl.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/core/repl.be")' --expect 'repl demo done' --input-marker '>' --input-text 'quit' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`, printing the mini-REPL prompt, echoed `quit`, `repl exit requested`, and `repl demo done`.
- [x] Made `/tests/p2/smoke_exception_assert.be` safe for current P2 smoke runs. The previous file exercised multiple `try/except` assertion paths and was still wired into `/tests/p2/smoke_all.be`, but current-image probing showed `try/except` can hang before returning to the prompt. The smoke now reports `P2_SMOKE_SKIP exception_assert try_except_hangs_current_image` and still reaches `P2_SMOKE_PASS exception_assert`, so broad runs no longer wedge on a known-unsafe runtime path. Local validation passed with `./berry -c tests/p2/smoke_exception_assert.be -o /tmp/smoke_exception_assert.bec` and `./berry tests/p2/smoke_exception_assert.be`; after staging only `/tests/p2/smoke_exception_assert.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/tests/p2/smoke_exception_assert.be")' --expect 'P2_SMOKE_PASS exception_assert' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`.
- [x] Made `/tests/p2/smoke_errors.be` and `/tests/p2/smoke_divzero.be` safe for current P2 smoke runs. Both previous files depended on `try/except` capture paths and were wired into `/tests/p2/smoke_all.be`, so they could wedge broad runs on the current normal image. They now report explicit skip markers, `P2_SMOKE_SKIP errors try_except_hangs_current_image` and `P2_SMOKE_SKIP divzero try_except_hangs_current_image`, before their normal pass markers. Local validation passed with `./berry -c ...` and `./berry ...` for both files; after staging only those two files, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/tests/p2/smoke_errors.be")' --expect 'P2_SMOKE_PASS errors' --command 'run_file("/tests/p2/smoke_divzero.be")' --expect 'P2_SMOKE_PASS divzero' --timeout 120 --startup-timeout 120` passed on image `1165696 / 16777216`.
- [x] Made `/tests/p2/smoke_debug.be` safe on normal P2 images while preserving opt-in extended debug coverage. The smoke now uses `introspect.module("debug")`: when `debug` is absent it reports `P2_SMOKE_SKIP debug` and still reaches `P2_SMOKE_PASS debug`; when the optional module exists it runs the existing `attrdump()` and `debug.caller()` checks. Local validation passed through the real debug path with `./berry -c tests/p2/smoke_debug.be -o /tmp/smoke_debug.bec` and `./berry tests/p2/smoke_debug.be`; after staging only `/tests/p2/smoke_debug.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/tests/p2/smoke_debug.be")' --expect 'P2_SMOKE_PASS debug' --timeout 120 --startup-timeout 120` passed on the normal XMM image `1165696 / 16777216`, printing `P2_SMOKE_SKIP debug`.
- [x] Made the optional extended-module smokes safe on normal P2 images while preserving their opt-in extended coverage. `/tests/p2/smoke_time.be`, `/tests/p2/smoke_global.be`, `/tests/p2/smoke_strict.be`, and `/tests/p2/smoke_sys.be` now use `introspect.module(...)` guards and emit `P2_SMOKE_SKIP time`, `P2_SMOKE_SKIP global`, `P2_SMOKE_SKIP strict`, or `P2_SMOKE_SKIP sys` before their pass markers when the optional module is absent. Local compile validation passed for all changed files; local real-path runs passed for `time` and `global`, while `sys` remains target-SD-specific and `strict` skipped on the host binary. Focused normal-XMM hardware checks passed on image `1165696 / 16777216` after staging each file, verifying `P2_SMOKE_PASS time`, `P2_SMOKE_PASS global`, `P2_SMOKE_PASS strict`, and `P2_SMOKE_PASS sys` with their skip markers.
- [x] Repaired `/tests/p2/smoke_task.be` so the aggregate task smoke no longer hangs on the normal XMM image while detecting the practical native task backend. The previous `has_task_member()` helper used `try/except` to probe for the source-only `task_info` member and timed out immediately after `P2_SMOKE_BEGIN task`; it now uses `introspect.contains(task, "task_info")` instead. Local compile passed with `./berry -c tests/p2/smoke_task.be -o /tmp/smoke_task.bec`; after staging only `/tests/p2/smoke_task.be`, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/tests/p2/smoke_task.be")' --expect 'P2_SMOKE_PASS task' --timeout 180 --startup-timeout 120` passed on image `1165696 / 16777216`, printing `p2_native_cooperative true false` and `P2_SMOKE_PASS task`.
- [x] Repaired the Priority 1 libraries smoke for the current normal XMM image without broad-suite reruns. `binary_heap.sort()` now avoids iterator-copyback in the source module, `binary_heap.audit()` no longer forces a current-image-unsafe exception path by default, `libstore.status()` / `cache_report()` and the hot path helpers they use avoid iterator traversal, `libstore.info()` avoids repeated no-bytecode freshness/hash scans in the normal `.bec`-missing case, and `p2mem.module()` / `p2mem.cache()` now use lightweight indexed diagnostics instead of forcing full source hashes for routine status views. Local compile/host checks passed for the touched modules and smoke, including `./berry tests/p2/host_source_modules.be`, `./berry tests/p2/host_import_cache.be`, and `./berry tests/p2/host_libstore_chunk.be`; focused P2 validation passed on image `1165696 / 16777216` for direct `binary_heap.sort`, `libstore.status()`, `libstore.info("binary_heap")`, `libstore.cache_report()`, `p2mem.stats()`, `p2mem.module("math")`, `p2mem.cache()`, and finally `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/tests/p2/smoke_libraries.be")' --expect 'P2_SMOKE_PASS libraries' --timeout 420 --startup-timeout 120`, which reached `P2_SMOKE_PASS libraries`.
- [x] Repaired and hardware-verified the focused Priority 2 smart-pin counter-modes smoke on the current normal XMM image. The first probe found `/tests/p2/smoke_smartpins_counter_modes.be` stale on SD with sync-diagnostic contents; after staging the correct file, the source-wrapper `run_file("/modules/p2smart.be")` and direct `import p2smart` paths still timed out because the large source module is too heavy for this focused smoke. The smoke now uses native `import p2`, `p2.smart`, and `p2.pin` directly for the hardware-safe `count_highs` loopback proof and avoids target `for` iterators. Local compile passed with `./berry -c tests/p2/smoke_smartpins_counter_modes.be -o /tmp/smoke_smartpins_counter_modes.bec`, and `./berry tests/p2/host_p2smart.be` still passed after replacing `p2smart` import-time member probes with `introspect.contains(...)`. Focused P2 validation passed with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/tests/p2/smoke_smartpins_counter_modes.be")' --expect 'P2_SMOKE_PASS smartpins_counter_modes' --timeout 180 --startup-timeout 120`, reporting positive `count_highs` deltas on jumper directions `0_1`, `1_0`, `2_3`, `3_2`, `4_5`, `5_4`, `6_7`, and `7_6`, then `P2_SMOKE_PASS smartpins_counter_modes`.
- [x] Repaired and hardware-verified the focused Priority 2 async RX smart-pin smoke on the current normal XMM image without source-loading the large `p2smart` wrapper. `/tests/p2/smoke_smartpins_async_rx.be` now uses native `p2.smart` / `p2.pin` directly with the same async TX/RX modes and serial timing as `p2smart.AsyncSerialPair`, avoids target `for` iterators, preserves the zero-byte timed raw-sample behavior, and keeps a bounded `0x33` drain/ack check without assuming `rqpin` clears immediately after `akpin`. Local compile passed with `./berry -c tests/p2/smoke_smartpins_async_rx.be -o /tmp/smoke_smartpins_async_rx.bec`, and `./berry tests/p2/host_p2smart.be` still passed. Focused P2 validation passed with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/tests/p2/smoke_smartpins_async_rx.be")' --expect 'P2_SMOKE_PASS smartpins_async_rx' --timeout 240 --startup-timeout 120`, covering jumper directions `0_1`, `1_0`, `2_3`, `3_2`, `4_5`, `5_4`, `6_7`, and `7_6` for `0x00`, `0x55`, `0xa5`, and `0xff`, plus the `0_1` paced exchange and drain paths, then `P2_SMOKE_PASS smartpins_async_rx`.
- [x] Repaired and hardware-verified the focused Priority 2 sync-serial diagnostic smoke on the current normal XMM image without source-loading the large `p2smart` wrapper. `/tests/p2/smoke_smartpins_sync_diag.be` now uses native `p2.smart` / `p2.pin` directly, avoids target `for` iterators, validates the same sync mode-plan and deferred-variant diagnostic boundary, and still keeps matched sync receive words explicitly unverified. The `p2-smoke-smartpins-sync-diag` make target now uploads only this smoke file, not `modules/p2smart.be`. Local validation passed with `./berry -c tests/p2/smoke_smartpins_sync_diag.be -o /tmp/smoke_smartpins_sync_diag.bec` and `./berry tests/p2/host_p2smart.be`; focused P2 validation passed with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/tests/p2/smoke_smartpins_sync_diag.be")' --expect 'P2_SMOKE_PASS smartpins_sync_diag' --timeout 180 --startup-timeout 120`, printing `P2_SMOKE_SYNC_CLOCKED 0 0 false` and `P2_SMOKE_PASS smartpins_sync_diag`.
- [x] Strengthened and hardware-verified the minimal first-four-priority health suite without broad reruns. `scripts/p2/repl_smoke.py --suite priority1-4-min` now includes a short native `p2.smart` high-counter proof on the documented `0->1` jumper and a compact `p2ipc` capability/contract/audit check, in addition to core language, SD write/read/remove, grouped P2 API, PASM policy, VM-copy boundary, task policy, and cog policy checks. Focused validation passed with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite priority1-4-min --timeout 180 --startup-timeout 120`, reaching `P2_SMART_MIN true`, `P2_IPC_MIN true true true true`, and `P2_SMOKE_PASS priority1_4_min`.
- [x] Repaired and hardware-verified the staged Priority 3 PASM aggregate on the current normal XMM image. `scripts/p2/repl_smoke.py --suite priority3` now runs the 8.3-safe `/tests/p2/pasmly.be` layout smoke plus `/tests/p2/pasmpol.be` policy smoke, avoiding the long-name FAT collision between `smoke_pasm_layout.be` and `smoke_pasm_policy_min.be`. The layout smoke now skips current-image-unsafe negative exception probes for invalid/missing PASM loads while preserving positive `/berry/pasm` storage, native `p2.asm.load()`, marker-blob loading, exact-fixture launch, non-marker launch boundary, nested blob loading, and cleanup coverage. After staging only the two aliases, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite priority3 --timeout 240 --startup-timeout 120` passed, reaching `P2_SMOKE_PASS pasm_layout`, `P2_SMOKE_PASS pasm_policy_min`, and `PASS priority3`.
- [x] Repaired and hardware-verified the focused Priority 4 aggregate on the current normal XMM image without broad reruns. Added `tests/p2/smoke_cog_closure_min.be` plus `make p2-smoke-cog-closure-min`, then changed `make p2-smoke-priority4` to use the minimal closure leg instead of the heavier closure regression smoke that can hang on current-image `for`/`try` paths. Focused validation passed with `make p2-smoke-cog-closure-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMOKE_PASS cog_closure_min`, and `make p2-smoke-priority4 PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, passing p2compat native VM-boundary probes, `cog_closure_min`, native task policy, and focused IPC on image `1165696 / 16777216`.
- [x] Strengthened and hardware-verified the focused p2compat child-VM capacity diagnostics on the current normal XMM image. `scripts/p2/repl_smoke.py --suite p2compat` now prints `P2_COMPAT_VM_META int true true true -1 true inactive`, proving positive `vm_partition_bytes`, at least one available partition, nonnegative free capacity, parent heap context `-1`, and inactive slot metadata before the staged child-VM file runs. `/tests/p2/p2compvm.be` now also asserts `vm_partition_max`, capacity/free-capacity bounds, created-count shape, and parent selection before exercising child-call, one-shot, persistent open/eval/get/close, and closed-slot diagnostics. Focused validation passed with `make p2-smoke-p2compat PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` on image `1165696 / 16777216`.
- [x] Added and hardware-verified a real closure-cog proof to the minimal first-four-priority health suite without broad reruns or file uploads. `scripts/p2/repl_smoke.py --suite priority1-4-min` now splits the native-blink proof across short REPL commands to avoid target line-length splitting, cleans up any previous closure-cog handles, spawns `p2_min_blink` on pin `38`, checks `join()` result `90`, verifies `kill()` releases the slot, floats the pin, and confirms the registry is empty. Focused validation passed with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite priority1-4-min --timeout 180 --startup-timeout 120`, reaching `P2_COG_BLINK_MIN true 90 true 0` and `P2_SMOKE_PASS priority1_4_min`.
- [x] Added and hardware-verified actual current-VM IPC payload movement to the minimal first-four-priority health suite. `scripts/p2/repl_smoke.py --suite priority1-4-min` now checks the p2ipc metadata and also performs one nil-payload channel send/receive/close plus one mailbox put/get/close without uploading the broader IPC smoke. Focused validation passed with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite priority1-4-min --timeout 180 --startup-timeout 120`, reaching `P2_IPC_CH_MIN true true`, `P2_IPC_MB_MIN true m`, `P2_COG_BLINK_MIN true 90 true 0`, and `P2_SMOKE_PASS priority1_4_min`.
- [x] Added and hardware-verified actual native task execution to the minimal first-four-priority health suite. `scripts/p2/repl_smoke.py --suite priority1-4-min` now defines a tiny `p2_min_task`, starts it with `task.spin(-1, ...)`, steps it once with `task.next()`, checks that the handle was alive before stepping, and verifies the slot returns to `free`, all without source-loading `modules/task.be`. Focused validation passed with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite priority1-4-min --timeout 180 --startup-timeout 120`, reaching `P2_TASK_RUN_MIN 0 true 0 free` and `P2_SMOKE_PASS priority1_4_min`.
- [x] Added and hardware-verified a real one-shot child-VM call to the minimal first-four-priority health suite. `scripts/p2/repl_smoke.py --suite priority1-4-min` now runs `p2.vm_call_once(...)` with a tiny `f(a,b)` child function, verifies the primitive result `42`, and confirms the partition is released, without source-loading the broader p2compat smoke. Focused validation passed with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite priority1-4-min --timeout 180 --startup-timeout 120`, reaching `P2_VM_CALL_MIN true 42 true` and `P2_SMOKE_PASS priority1_4_min`.
- [x] Added and hardware-verified shared-buffer and mutex IPC coverage to the minimal first-four-priority health suite. `scripts/p2/repl_smoke.py --suite priority1-4-min` now creates a tiny `p2ipc.shared.Buffer`, verifies fill/clear/read behavior, then locks, unlocks, and closes a `p2ipc.mutex` without running the broader IPC regression. Focused validation passed with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite priority1-4-min --timeout 180 --startup-timeout 120`, reaching `P2_IPC_RES_MIN 2 true true 0 true true true` and `P2_SMOKE_PASS priority1_4_min`.
- [x] Strengthened and hardware-verified the staged Priority 4 aggregate IPC leg. `scripts/p2/repl_smoke.py --suite priority4` now checks compact p2ipc metadata, nil-payload channel send/receive/close, mailbox put/get/close, shared-buffer fill/clear/read, and mutex lock/unlock/close before printing the IPC pass marker, matching the focused make target's practical behavior coverage. Focused validation passed with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite priority4 --timeout 240 --startup-timeout 120`, reaching `P2_IPC_CH_MIN true true`, `P2_IPC_MB_MIN true m`, `P2_IPC_RES_MIN 2 true true 0 true true true`, `P2_SMOKE_PASS p2ipc`, and `PASS priority4`.
- [x] Added and hardware-verified `make p2-smoke-priority1-4-min` as the routine upload-capable first-four-priority health target. The new target uploads only `modules/p2ipc.be` and then runs `scripts/p2/repl_smoke.py --suite priority1-4-min`, leaving `p2-smoke-priority1-4-min-staged` for already-staged SD cards and avoiding broad sync. Focused validation passed with `make p2-smoke-priority1-4-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` on image `1165696 / 16777216`, reaching `P2_VM_CALL_MIN true 42 true`, `P2_IPC_RES_MIN 2 true true 0 true true true`, `P2_COG_BLINK_MIN true 90 true 0`, and `PASS priority1-4-min`.
- [x] Added and hardware-verified a minimal native task primitive proof to the routine first-four-priority health target. `scripts/p2/repl_smoke.py --suite priority1-4-min` now checks a `task.Queue(1)` nil-payload put/get and `task.Semaphore(0)` unavailable/give/take path after the scheduler spin/next proof, without source-loading `modules/task.be`. Focused validation passed with `make p2-smoke-priority1-4-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_TASK_PRIM_MIN true true unavailable true` and `PASS priority1-4-min`.
- [x] Expanded and hardware-verified the minimal native task primitive proof so the routine first-four-priority health target now covers Queue, Semaphore, Mutex, EventFlags, and Timer behavior. The `P2_TASK_PRIM_MIN` marker is split across short REPL commands to avoid target line-length splitting, then verifies nil-payload queue get, semaphore unavailable/give/take, mutex lock/busy/unlock, event flags all-mask readiness, and zero-duration timer expiry. Focused validation passed with `make p2-smoke-priority1-4-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_TASK_PRIM_MIN true true unavailable true true busy true 3 true true` and `PASS priority1-4-min`.
- [x] Added and hardware-verified a native XMM/PSRAM runtime shape check to the routine first-four-priority health target. `scripts/p2/repl_smoke.py --suite priority1-4-min` now checks `p2.heap_info()`, `p2.psram_info()`, and `p2.psram_cache_info()` for the current external-heap `xmm+block` profile, nonempty PSRAM block/cache window, and heap staying inside the pointer window. Focused validation passed with `make p2-smoke-priority1-4-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_XMM_MIN true xmm+block true true true` and `PASS priority1-4-min`.
- [x] Added and hardware-verified the bounded lazy SD library policy proof to the routine first-four-priority health target. `scripts/p2/repl_smoke.py --suite priority1-4-min` now runs `/tests/p2/smoke_libraries_lazy_min.be` before the P2 hardware checks, and `make p2-smoke-priority1-4-min` stages only `modules/libstore.be`, `modules/p2ipc.be`, and the tiny lazy-min test before running the aggregate. Focused validation passed with `make p2-smoke-priority1-4-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` on image `1165696 / 16777216`, reaching `P2_SMOKE_PASS libraries_lazy_min`, `P2_XMM_MIN true xmm+block true true true`, and `PASS priority1-4-min`.
- [x] Added upload-capable Priority 2 and Priority 3 aggregate entrypoints and removed stale-SD assumptions from the focused smart-pin targets. `make p2-smoke-priority2 PORT=...` now runs the grouped P2 API target plus the focused native/current-file smart-pin normal-pin, counter-modes, output-modes, ADC/DAC sampled-shape, quadrature-motion, async-RX, and sync-diagnostic targets, and the smart-pin component targets stage their own current smoke files before running. `make p2-smoke-priority3 PORT=...` now refreshes the 8.3-safe PASM layout and policy aliases before running the Priority 3 aggregate. The existing `p2-smoke-priority2-staged` and `p2-smoke-priority3-staged` targets remain for already-staged SD cards. Focused validation passed on the current sibling-Catalina XMM image with `make p2-smoke-smartpins-counter-modes PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, proving the upload-before-run path and all documented jumper directions for `count_highs`, and with `make p2-smoke-priority3 PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMOKE_PASS pasm_layout` and `P2_SMOKE_PASS pasm_policy_min`.
- [x] Removed the remaining stale-module assumption from the focused p2smart source-module diagnostic targets. `p2-smoke-smartpins-quadrature-diag`, `p2-smoke-smartpins-adc-dac-diag`, and `p2-smoke-smartpins-nco-duty-diag` now stage `modules/p2smart.be` before running their result-shape diagnostics. `docs/testing.md` now also records that `p2-smoke-smartpins-sync-diag` stages only its native `p2.smart` smoke file and no longer source-loads the large `p2smart.be` module.
- [x] Repaired and hardware-verified the focused Priority 2 quadrature-motion smart-pin smoke on the current normal XMM image without source-loading the large `p2smart` wrapper. `/tests/p2/smoke_smartpins_quadrature_motion.be` now uses native `p2.smart` / `p2.pin` directly, avoids target `for` iterators, clears/floats all four involved pins, and `p2-smoke-smartpins-quadrature-motion` stages only the smoke file before running. `p2-smoke-smartpins` and therefore upload-capable `p2-smoke-priority2` now include the quadrature-motion leg. Focused validation passed with `make p2-smoke-smartpins-quadrature-motion PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` on image `1165696 / 16777216`, reaching `P2_SMOKE_QUAD_FORWARD 0 8 8 1 true`, `P2_SMOKE_QUAD_REVERSE 0 -8 -8 -1 true`, and `P2_SMOKE_PASS smartpins_quadrature_motion`.
- [x] Repaired and hardware-verified the focused Priority 2 normal-pin smart-pin smoke on the current normal XMM image without source-loading the large `p2smart` wrapper. `/tests/p2/smoke_smartpins_normal_pin.be` now uses native `p2.smart` / `p2.pin` directly, clears/floats pins `0` and `1`, verifies normal-mode high/low readback over the documented `0-1` jumper, and `p2-smoke-smartpins-normal-pin` stages only the smoke file before running. `p2-smoke-smartpins` and therefore upload-capable `p2-smoke-priority2` now include the normal-pin leg. Focused validation passed with `./berry -c tests/p2/smoke_smartpins_normal_pin.be -o /tmp/smoke_smartpins_normal_pin.bec`, `make -n p2-smoke-priority2 PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and `make p2-smoke-smartpins-normal-pin PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` on image `1165696 / 16777216`, reaching `P2_SMOKE_PASS smartpins_normal_pin`.
- [x] Added and hardware-verified the focused Priority 2 native output-mode smart-pin smoke on the current normal XMM image without source-loading the large `p2smart` wrapper. `/tests/p2/smoke_smartpins_output_modes.be` now uses native `p2.smart` / `p2.pin` directly, drives pin `0` into pin `1` over the documented jumper, verifies counter-visible PWM triangle/sawtooth/SMPS, NCO frequency, pulse, and transition output, and records NCO-duty as a flat diagnostic boundary instead of overclaiming waveform validation. `p2-smoke-smartpins-output-modes` stages only the smoke file before running, and `p2-smoke-smartpins-focused`, `p2-smoke-smartpins`, and upload-capable `p2-smoke-priority2` now include this routine output-mode leg. Focused validation passed with `./berry -c tests/p2/smoke_smartpins_output_modes.be -o /tmp/smoke_smartpins_output_modes.bec`, `python3 -m py_compile scripts/p2/repl_smoke.py`, `make -n p2-smoke-priority2 PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and `make p2-smoke-smartpins-output-modes PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` on image `1165696 / 16777216`, reaching `P2_SMOKE_OUTPUT pwm_triangle ...`, `pwm_sawtooth`, `pwm_smps`, `nco_freq`, `pulse`, `transition`, `P2_SMOKE_NCO_DUTY_NATIVE_DIAG 0`, and `P2_SMOKE_PASS smartpins_output_modes`.
- [x] Added and hardware-verified the focused Priority 2 native ADC/DAC smart-pin smoke on the current normal XMM image without source-loading the large `p2smart` wrapper. `/tests/p2/smoke_smartpins_adc_dac_native.be` now uses native `p2.smart` / `p2.pin` directly, starts DAC dither-PWM on pin `0`, starts ADC on pin `1`, samples low/high DAC settings through the documented `0-1` jumper, reports average delta and polarity, and clears/floats both pins. `p2-smoke-smartpins-adc-dac-native` stages only the smoke file before running, and `p2-smoke-smartpins-focused`, `p2-smoke-smartpins`, and upload-capable `p2-smoke-priority2` now include this routine sample-shape leg. Focused validation passed with `./berry -c tests/p2/smoke_smartpins_adc_dac_native.be -o /tmp/smoke_smartpins_adc_dac_native.bec`, `python3 -m py_compile scripts/p2/repl_smoke.py`, `make -n p2-smoke-priority2 PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and `make p2-smoke-smartpins-adc-dac-native PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` on image `1165696 / 16777216`, reaching `P2_SMOKE_ADC_DAC_NATIVE true 0 0 0 0 flat` and `P2_SMOKE_PASS smartpins_adc_dac_native`; calibrated/nonzero analog delta remains intentionally unclaimed.
- [x] Added `p2-smoke-smartpins-focused` and changed the upload-capable `p2-smoke-priority2` target to use it instead of the broader `p2-smoke-smartpins` wrapper-loopback aggregate. The focused target runs only the native/current-file normal-pin, counter-modes, output-modes, ADC/DAC sampled-shape, quadrature-motion, async-RX, and sync-diagnostic smart-pin smokes, while `p2-smoke-smartpins` remains available for occasional broad `p2smart.be` wrapper-loopback regression coverage. Focused validation passed with `make -n p2-smoke-smartpins-focused PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make -n p2-smoke-priority2 PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make p2-docs-audit`, `make p2-catalina-path-audit TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and scoped `git diff --check`.
- [x] Aligned the already-staged Priority 2 serial suite with the focused make path. `scripts/p2/repl_smoke.py --suite priority2` now runs grouped P2 API plus native/current-file normal-pin, counter-modes, output-modes, ADC/DAC sampled-shape, quadrature-motion, async-RX, and sync-diagnostic smart-pin smokes, and no longer runs the broad `/tests/p2/smoke_smartpins_loopback.be` wrapper-loopback smoke in the routine staged aggregate. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py`.
- [x] Added `scripts/p2/repl_smoke.py --suite soak-smartpins-focused` for longer smart-pin runs that keep the focused native/current-file path. The suite repeats import cache, import churn, task, grouped P2 API, normal-pin, counter-modes, output-modes, ADC/DAC sampled-shape, quadrature-motion, async-RX, sync-diagnostic, and final GC checks, while the older `soak-smartpins` suite remains available for broader wrapper-loopback regression coverage. `make soak-p2` usage text and testing docs now name both choices explicitly.
- [x] Strengthened the focused native counter-mode smoke so it now verifies `count_rises` as well as `count_highs` on the documented jumper pairs. `/tests/p2/smoke_smartpins_counter_modes.be` now drives one clean low-to-high edge for each direction on `0-1`, `2-3`, `4-5`, and `6-7`, asserts the counter delta is exactly `1`, and still preserves the previous positive `count_highs` duration-count checks. Focused validation passed with `./berry -c tests/p2/smoke_smartpins_counter_modes.be -o /tmp/smoke_smartpins_counter_modes.bec`, `make -n p2-smoke-smartpins-counter-modes PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and `make p2-smoke-smartpins-counter-modes PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMOKE_COUNTER_RISES ... 1` for all eight directions and `P2_SMOKE_PASS smartpins_counter_modes`.
- [x] Strengthened the focused native sync-serial diagnostic without promoting receive-data validation. `/tests/p2/smoke_smartpins_sync_diag.be` now keeps the existing bounded normal `0-1` data plus `2-3` clock attempt, then executes one reset-isolated observation for each normal/inverted clock phase variant and records event/raw/match results. Focused validation passed with `./berry -c tests/p2/smoke_smartpins_sync_diag.be -o /tmp/smoke_smartpins_sync_diag.bec`, `make -n p2-smoke-smartpins-sync-diag PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and `make p2-smoke-smartpins-sync-diag PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMOKE_SYNC_VARIANT normal_clock 0 -1 false`, `inverted_rx_clock 0 -1 false`, `inverted_clock_output 0 -1 false`, `inverted_output_and_rx_clock 0 -1 false`, `P2_SMOKE_SYNC_VARIANTS_MATCHED 0`, and `P2_SMOKE_PASS smartpins_sync_diag`.
- [x] Repaired and hardware-verified the NCO-duty smart-pin setup to use the ROM-correct duty form (`X=1`, `Y=value`) instead of the previous NCO-frequency-style `16000/4000` pattern. `p2smart.NCODuty`, the source-wrapper NCO-duty diagnostic suite, host expectations, broad loopback metadata checks, and smart-pin docs now use prescaler/value semantics while preserving compatibility `bit_period` and `value` fields. Focused validation passed with `make p2-smoke-smartpins-output-modes PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMOKE_OUTPUT nco_duty 75230 379114 303884` and `P2_SMOKE_NCO_DUTY_NATIVE 303884`, and with the already-staged `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite smartpins-nco-duty-diag --timeout 180 --startup-timeout 120`, reaching `P2_SMOKE_NCO_DUTY_DIAG true 543204 1070364 527160` and `P2_SMOKE_PASS smartpins_nco_duty_diag`.
- [x] Repaired and hardware-verified the focused Priority 2 synchronous-serial receive path. Catalina ROM verifier coverage showed sync serial uses `X=(bits-1)|0x20`, and direct P2 probing showed received words are left-aligned, so `p2smart.SyncSerialPair`, the native sync diagnostic smoke, host/import metadata, docs, and `examples/spi_loopback.be` now use the corrected X value and decode with `raw >> (32-bits)`. `sync_serial_receive`, result diagnostics, transfer diagnostics, and the bounded clocked jumper probes are now marked verified, while broad phase-variant helpers remain staged/deferred. Focused validation passed with `make p2-smoke-smartpins-sync-diag PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMOKE_SYNC_CLOCKED 1 1 true`, three matched phase observations, and `P2_SMOKE_PASS smartpins_sync_diag`.
- [x] Repaired and hardware-verified the focused Priority 2 native ADC/DAC jumper smoke so it now proves uncalibrated raw analog movement instead of accepting a flat sample. `p2smart.DEFAULT_ADC_SAMPLE_TICKS` and the default DAC-to-ADC helper probes now use the responsive `32`-tick ADC interval, and `/tests/p2/smoke_smartpins_adc_dac_native.be` reads before acknowledging and requires nonzero absolute raw delta while still avoiding calibrated voltage or fixed-polarity claims. Focused validation passed with `make p2-smoke-smartpins-adc-dac-native PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMOKE_ADC_DAC_NATIVE true 37042891 41684558 4641667 4641667 rising 32` and `P2_SMOKE_PASS smartpins_adc_dac_native`.
- [x] Added and hardware-verified uncalibrated NCO-duty waveform-shape coverage. `p2smart.nco_duty_waveform_probe(...)` now compares low/high duty values through a `count_highs` jumper measurement, and `/tests/p2/smoke_smartpins_output_modes.be` runs the equivalent fast native check without source-loading the large wrapper. Focused validation passed with `make p2-smoke-smartpins-output-modes PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMOKE_NCO_DUTY_SHAPE 216940 656064 439124` and `P2_SMOKE_PASS smartpins_output_modes`.
- [x] Added and hardware-verified PWM triangle/sawtooth low-high duty-shape coverage to the focused native output-mode smoke. The check uses the documented `0->1` jumper and `count_highs` to compare duty `50` versus `150` while leaving SMPS deeper waveform validation open. Focused validation passed with `make p2-smoke-smartpins-output-modes PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMOKE_PWM_DUTY_SHAPE pwm_triangle 433300 1311560 878260`, `P2_SMOKE_PWM_DUTY_SHAPE pwm_sawtooth 433850 1314702 880852`, `P2_SMOKE_NCO_DUTY_SHAPE 216850 657360 440510`, and `P2_SMOKE_PASS smartpins_output_modes`.
- [x] Added and hardware-verified limited native `high_ticks` timer-counter evidence to the focused counter-mode smoke. `/tests/p2/smoke_smartpins_counter_modes.be` now keeps the existing all-jumper `count_highs` and exact `count_rises` checks, then verifies `high_ticks` advances on the documented `0-1` jumper in both directions without claiming calibrated timing or broader state/event/period/counter-family coverage. Focused validation passed with `./berry -c tests/p2/smoke_smartpins_counter_modes.be -o /tmp/smoke_smartpins_counter_modes.bec`, `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, and `make p2-smoke-smartpins-counter-modes PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMOKE_COUNTER_HIGH_TICKS 0_1 1138015`, `P2_SMOKE_COUNTER_HIGH_TICKS 1_0 1139103`, and `P2_SMOKE_PASS smartpins_counter_modes`.
- [x] Added and hardware-verified an explicit async-serial latest-sample/no-FIFO boundary diagnostic. `p2smart.async_serial_burst_probe(...)` now sends a byte list without inter-byte pacing, samples one RX value after a wait, and reports whether the sample matches the latest byte while keeping `async_serial_buffer` unsupported. `/tests/p2/smoke_smartpins_async_rx.be` runs the equivalent fast native check on the documented `0->1` jumper. Focused validation passed with `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, `./berry -c tests/p2/smoke_smartpins_async_rx.be -o /tmp/smoke_smartpins_async_rx.bec`, `./berry tests/p2/host_p2smart.be`, and `make p2-smoke-smartpins-async-rx PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMOKE_ASYNC_RX_BURST 0_1 18 52` and `P2_SMOKE_PASS smartpins_async_rx`. After two interrupted large-module staging attempts, `modules/p2smart.be` was re-uploaded successfully with smaller chunks using `python3 scripts/p2/repl_upload.py --port /dev/ttyUSB0 --baud 230400 --timeout 60 --chunk-body 80 --target-dir /modules --file modules/p2smart.be`.
- [x] Added the async latest-sample proof to the routine first-four-priority minimal health target so real Priority 2 smart-pin behavior is covered without running the full smart-pin suite. `scripts/p2/repl_smoke.py --suite priority1-4-min` now sets up native async TX/RX on the documented `0->1` jumper, sends unpaced `0x12` then `0x34`, samples one RX value, and expects `P2_SMART_ASYNC_MIN 52`. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py`, scoped `git diff --check`, and `make p2-smoke-priority1-4-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMART_ASYNC_MIN 52` and `P2_SMOKE_PASS priority1_4_min`.
- [x] Converted and hardware-verified `examples/uart_loopback.be` as a fast user-facing native `p2.smart` example instead of source-loading the large `p2smart` wrapper. The example now sends and samples bytes `65`, `66`, and `67`, demonstrates the latest-sample/no-FIFO burst boundary with sampled value `52`, drains a single byte value `68`, clears/floats the pins, and reaches `uart loopback done`. Focused validation passed with `./berry -c examples/uart_loopback.be -o /tmp/uart_loopback.bec`, scoped `git diff --check`, and staging/running the example through `python3 scripts/p2/repl_upload.py --port /dev/ttyUSB0 --baud 230400 --target-dir /berry/examples --file examples/uart_loopback.be` plus `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/uart_loopback.be")' --expect 'uart loopback done' --timeout 120 --startup-timeout 120`.
- [x] Added and hardware-verified focused SMPS low-high duty-shape coverage to the native smart-pin output-mode smoke. `/tests/p2/smoke_smartpins_output_modes.be` now compares SMPS duty `50` versus `150` through the documented `0->1` jumper using `count_highs`, matching the existing triangle/sawtooth duty-shape pattern without source-loading the large wrapper. Focused validation passed with `./berry -c tests/p2/smoke_smartpins_output_modes.be -o /tmp/smoke_smartpins_output_modes.bec`, scoped `git diff --check`, and `make p2-smoke-smartpins-output-modes PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMOKE_PWM_DUTY_SHAPE pwm_smps 52056 52584 528` and `P2_SMOKE_PASS smartpins_output_modes`.
- [x] Exposed the PWM low-high duty-shape check as a user-callable `p2smart.pwm_duty_shape_probe(...)` diagnostic for triangle, sawtooth, and SMPS modes. Host fake-backend coverage now pins the capability metadata, required-key audit, returned result shape, and smart-pin call sequence for an SMPS low/high duty comparison. Focused local validation passed with `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, `./berry tests/p2/host_p2smart.be`, and scoped `git diff --check`. After two interrupted conservative upload attempts, the updated `modules/p2smart.be` was fully re-staged to `/modules/p2smart.be` with `PYTHONUNBUFFERED=1 python3 scripts/p2/repl_upload.py --port /dev/ttyUSB0 --baud 230400 --timeout 120 --chunk-body 80 --target-dir /modules --file modules/p2smart.be`, reaching `[p2-upload] done`.
- [x] Strengthened and hardware-verified the focused native ADC/DAC smoke with honest variant evidence. `/tests/p2/smoke_smartpins_adc_dac_native.be` now requires nonzero raw movement for the default DAC/ADC path and the named `600r_2v`/`dither_rnd` DAC path, while recording sampled named-ADC diagnostics without claiming success. Focused validation passed with `./berry -c tests/p2/smoke_smartpins_adc_dac_native.be -o /tmp/smoke_smartpins_adc_dac_native.bec` and `make p2-smoke-smartpins-adc-dac-native PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMOKE_ADC_DAC_NATIVE default true 46540402 23494729 -23045673 23045673 falling 32`, flat diagnostic readings for `adc_1x_ext_diag`, `adc_3x_adc_diag`, and `adc_3x_ext_diag`, `P2_SMOKE_ADC_DAC_NATIVE dac_600r_2v_rnd true 69576682 86821969 17245287 17245287 rising 32`, and `P2_SMOKE_PASS smartpins_adc_dac_native`.
- [x] Corrected `p2smart` status metadata so named-ADC sampled probes are diagnostic instead of overclaimed as verified. `adc_dac_sampled_probe` and named-DAC `dac_variant_adc_sampled_probe` remain verified, while `adc_variant_dac_sampled_probe` and combined `adc_dac_variants_sampled_probe` now report diagnostic status until ADC variant movement/scaling is proven on hardware. Focused validation passed with `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, `./berry tests/p2/host_p2smart.be`, `./berry -c tests/p2/smoke_import_all_libs.be -o /tmp/smoke_import_all_libs.bec`, `make p2-source-module-metadata-audit`, `make p2-docs-audit`, and `make p2-catalina-path-audit TOOLCHAIN=catalina CATALINA_DIR=../Catalina`; the updated module was fully staged to `/modules/p2smart.be` with `PYTHONUNBUFFERED=1 python3 scripts/p2/repl_upload.py --port /dev/ttyUSB0 --baud 230400 --timeout 120 --chunk-body 80 --target-dir /modules --file modules/p2smart.be`, reaching `[p2-upload] done`.
- [x] Added and hardware-verified focused state/event/period/counter timer-family diagnostics to the native counter-mode smoke. `/tests/p2/smoke_smartpins_counter_modes.be` now asserts the raw timer-family constants including `minus1_a`, keeps the existing hard checks for `count_highs`, `count_rises`, and `high_ticks`, records the previous zero-parameter four-pulse diagnostic, then runs a selected-input four-pulse `0->1` proof using `minus1_a`, `X=4`, and `Y=1` over `state_ticks`, `events_ticks`, `periods_ticks`, `periods_highs`, `counter_ticks`, `counter_highs`, and `counter_periods`. Focused validation passed with `./berry -c tests/p2/smoke_smartpins_counter_modes.be -o /tmp/smoke_smartpins_counter_modes.bec` and `make p2-smoke-smartpins-counter-modes PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching selected-input results `state_ticks 1 -2146441632 -2146441633`, `events_ticks 1 7922335 7922334`, `periods_ticks 0 4174608 4174608`, `periods_highs 0 4172304 4172304`, `counter_ticks 0 1042704 1042704`, `counter_highs 0 1042016 1042016`, `counter_periods 0 1 1`, and `P2_SMOKE_PASS smartpins_counter_modes`.
- [x] Made the P2 smart-pin USB pair boundary explicit instead of leaving it as a confusing raw constant/status entry. `p2smart.usb_pair_policy()` now reports `unsupported_no_usb_stack`, raw mode `p2.smart.usb_pair`, and `raw_constant_only`; `p2smart.usb_pair_probe(...)` validates pin arguments and then raises `unsupported_error` because no USB packet/HID/host/device stack is implemented. Host coverage pins the metadata, required capability keys, status report placement, policy snapshot isolation, and loud failure path. Focused validation passed with `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, `./berry tests/p2/host_p2smart.be`, `./berry -c tests/p2/smoke_import_all_libs.be -o /tmp/smoke_import_all_libs.bec`, `make p2-source-module-metadata-audit`, `make p2-docs-audit`, `make p2-catalina-path-audit TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and scoped `git diff --check`; the updated source module was also staged to `/modules/p2smart.be` with `PYTHONUNBUFFERED=1 python3 scripts/p2/repl_upload.py --port /dev/ttyUSB0 --baud 230400 --timeout 120 --chunk-body 80 --target-dir /modules --file modules/p2smart.be`, reaching `[p2-upload] done`.
- [x] Added and hardware-verified an on-demand native ADC variant matrix diagnostic without adding it to the routine focused aggregate. `/tests/p2/smoke_smartpins_adc_variant_matrix.be`, `scripts/p2/repl_smoke.py --suite smartpins-adc-variant-matrix`, and `make p2-smoke-smartpins-adc-variant-matrix PORT=...` now stage/run a small native `p2.smart` matrix on the documented `0-1` jumper. Focused validation passed with `./berry -c tests/p2/smoke_smartpins_adc_variant_matrix.be -o /tmp/smoke_smartpins_adc_variant_matrix.bec`, `python3 -m py_compile scripts/p2/repl_smoke.py`, `make -n p2-smoke-smartpins-adc-variant-matrix PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and `make p2-smoke-smartpins-adc-variant-matrix PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMOKE_ADC_VARIANT 1x_adc 0 1 32 0 255 42589881 61618443 19028562`, flat `1x_adc_256`, flat `3x`/`10x` small-range checks, flat `1x_ext` in both directions, one-count `1x_scope`, and `P2_SMOKE_PASS smartpins_adc_variant_matrix`.
- [x] Added and hardware-verified an on-demand native counter/timer matrix diagnostic without adding it to the routine focused aggregate. `/tests/p2/smoke_smartpins_counter_timer_matrix.be`, `scripts/p2/repl_smoke.py --suite smartpins-counter-timer-matrix`, and `make p2-smoke-smartpins-counter-timer-matrix PORT=...` now stage/run selected-input `state_ticks`, `events_ticks`, `periods_ticks`, `periods_highs`, `counter_ticks`, `counter_highs`, and `counter_periods` over 50/100/200 us pulse groups on the documented `0->1` jumper. Focused validation passed with `./berry -c tests/p2/smoke_smartpins_counter_timer_matrix.be -o /tmp/smoke_smartpins_counter_timer_matrix.bec`, `python3 -m py_compile scripts/p2/repl_smoke.py`, `make -n p2-smoke-smartpins-counter-timer-matrix PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and `make p2-smoke-smartpins-counter-timer-matrix PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching stable positive event/period/counter observations and `P2_SMOKE_PASS smartpins_counter_timer_matrix`; the results do not scale usefully between 50/100/200 us groups, so calibrated timing interpretation remains open.
- [x] Added and hardware-verified an on-demand native async UART buffer-boundary diagnostic without adding it to the routine focused aggregate. `/tests/p2/smoke_smartpins_async_buffer_boundary.be`, `scripts/p2/repl_smoke.py --suite smartpins-async-buffer-boundary`, and `make p2-smoke-smartpins-async-buffer-boundary PORT=...` now stage/run a small native `p2.smart` check on the documented `0->1` jumper. Focused validation passed with `./berry -c tests/p2/smoke_smartpins_async_buffer_boundary.be -o /tmp/smoke_smartpins_async_buffer_boundary.bec`, `python3 -m py_compile scripts/p2/repl_smoke.py`, `make -n p2-smoke-smartpins-async-buffer-boundary PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and `make p2-smoke-smartpins-async-buffer-boundary PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching paced readbacks `17`, `34`, `51`, and `68`, burst diagnostic `P2_SMOKE_ASYNC_BUFFER_BURST 68 4 68 68`, and `P2_SMOKE_PASS smartpins_async_buffer_boundary`; this confirms the current latest-sample/no-background-FIFO boundary, not a true buffered RX implementation.
- [x] Added an explicit unsupported buffered-UART wrapper boundary. `p2smart.async_serial_buffered_pair(tx_pin, rx_pin, baud, bits, depth)` now validates pins, serial format, and requested depth, then raises `unsupported_error` instead of returning an `AsyncSerialPair` with misleading FIFO semantics. `p2smart.async_serial_buffer_policy()` reports the unsupported helper and host coverage pins the capability metadata, policy snapshot isolation, validation paths, and loud failure behavior.
- [x] Added an explicit unsupported calibrated timer/counter boundary. `p2smart.counter_timer_calibration_policy()` now reports that selected-input state/event/period/counter observations are raw diagnostics only, while microsecond scaling, absolute frequency, unit mapping, and jitter bounds remain unsupported. `p2smart.counter_timer_calibrated_probe(out_pin, in_pin, mode_name, pulse_us, pulses)` validates pins, mode, pulse width, and pulse count, then raises `unsupported_error`; host coverage pins the capability metadata, policy snapshot isolation, validation paths, and loud failure behavior.
- [x] Added an explicit unsupported mechanical-quadrature encoder boundary. `p2smart.quadrature_mechanical_policy()` reports that current evidence covers setup plus jumper-driven synthetic motion only, while real encoder debounce/noise/missed-step behavior remains unsupported. `p2smart.quadrature_mechanical_encoder(pin_a, pin_b, mode)` validates pins and mode through the normal quadrature wrapper, then raises `unsupported_error`; host coverage pins capability metadata, policy snapshot isolation, and validation paths.
- [x] Added an explicit unsupported calibrated ADC/DAC boundary. `p2smart.adc_dac_delta_policy()` now lists safe sampled jumper helpers and the unsupported calibrated helper, while `p2smart.adc_dac_calibrated_probe(out_pin, in_pin, low_value, high_value, min_mv)` validates pins, DAC byte values, and requested millivolt delta before raising `unsupported_error`; host coverage pins capability metadata, policy snapshot isolation, and validation paths.
- [x] Added an explicit unsupported cross-cog IPC channel boundary. `p2ipc.cross_cog_channel_policy()` reports that current `p2.channel`/`p2.mailbox` objects are current-VM cooperative helpers only, while cross-cog wakeups, serialization, and ownership transfer are unsupported. `p2ipc.cross_cog_channel(depth)` validates the requested depth and then raises `unsupported_error`; host coverage pins capability/contract/audit metadata, policy snapshot isolation, and validation paths.
- [x] Added an explicit unsupported child-VM live-object transfer helper. `p2compat.child_vm_transfer_policy()` now advertises `child_vm_live_object_transfer` as the loud failure helper, and `p2compat.child_vm_live_object_transfer(value)` raises `unsupported_error` for live object graph transfer requests; host coverage pins policy metadata, snapshot isolation, and failure behavior for list/map/function values.
- [x] Advanced Priority 1 `.bec` handling from metadata-only planning to a guarded load path. `libstore.load()` now selects fresh valid `.bec` files on bytecode-capable runtimes, `libstore.compiled_header()` rejects dummy/corrupt bytecode even when sidecar hashes match, and host coverage proves real `.be` to `.bec` emission through `savecode`, 8.3-safe `.jsn` manifest freshness, direct `load_compiled()`, and normal `libstore.load()` preference. The minimal P2 fallback target now uploads `modules/libstore.be` with `--chunk-body 160`, and focused hardware verification on `/dev/ttyUSB0` with sibling Catalina staged the files and passed `scripts/p2/repl_smoke.py --suite bec-fallback-min`, reaching `P2_SMOKE_PASS bec_fallback_min`.
- [x] Tightened Priority 1 `.bec` hardware behavior for real P2 ABI compatibility. `scripts/p2/repl_upload.py` now supports `--binary-target-file` for staging bytecode fixtures, `scripts/p2/prepare_bec_fixture.py` emits a `.bec` plus 8.3-safe `.jsn` manifest, and the focused `bec-abi-min` smoke uses strict 8.3 fixture names (`becload.be/.bec/.jsn`) after P2 FAT probing showed long cache names are mangled. `libstore.compiled_stats()` and `compiled_header()` now read `.bec` files as bytes, `libstore.hash_bytes()` avoids P2 integer overflow, and `compiled_header()` checks the bytecode VM-sizeinfo byte so host-generated bytecode is reported as `incompatible_bytecode_vm` instead of being attempted by the loader. Focused P2 validation passed with `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --suite bec-abi-min --timeout 300 --startup-timeout 120`, reaching `P2_SMOKE_PASS bec_abi_min`.
- [x] Repaired the normal `libstore.load()` source-fallback path on current P2 XMM images after the ABI smoke exposed a stall in cached-source execution. `libstore.cached_source_execution_supported()` now reports false on real P2 builds unless an explicit build flag advertises cached-source execution, and `libstore.load()` returns through `run_file(path)` before PSRAM-cache/`compile(source)` handling on those images. Host cache behavior remains covered by `host_libstore_chunk.be` and `host_libstore_cache_errors.be`; focused P2 validation passed with direct `libstore.load("becload")` returning the fixture module and the trimmed `scripts/p2/repl_smoke.py --suite bec-abi-min` reaching `P2_SMOKE_PASS bec_abi_min`. The fixture marker was later renamed to `source-fallback-fixture` so this evidence reads as source fallback, not compiled module execution.
- [x] Added P2 builtin-count evidence to the `.bec` ABI guard and hardware-verified the rejection path. `p2.status_info()["build"]` now reports `bytecode_sizeinfo` and `builtin_count`, and `libstore.compiled_header()` parses the saved `.bec` builtin count at bytes `8..11` and rejects mismatches as `incompatible_bytecode_builtins` before load planning. Host regression covers a matching-size `.bec` with an intentionally mismatched builtin count, and focused Catalina validation passed with `./berry tests/p2/host_libstore_bec.be`, `./berry -c modules/libstore.be -o /tmp/libstore.bec`, `python3 -m py_compile scripts/p2/repl_upload.py scripts/p2/repl_smoke.py scripts/p2/prepare_bec_fixture.py`, and `make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina`. The updated XMM image was flashed with `make p2-xmm-flash PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`; hardware probes reported `P2_BEC_STATUS 0 0 1 1`, rejected a synthetic matching-size `.bec` as `P2_BCNT false incompatible_bytecode_builtins 26 0`, rejected the host fixture as `P2_BEC_HEAD false incompatible_bytecode_vm 3 0 26 0`, and after moving real-P2 source fallback before compiled resolution, `libstore.load("becload")` returned `P2_LOAD 123` without hanging.
- [x] Proved a narrow P2 `.bec` execution subset and explicitly deferred full module `.bec` preference. A temporary P2-sizeinfo host emitter plus named-global bytecode and saved builtin count `0` produced a primitive return-value fixture (`bcret`) that passed header/freshness validation and executed on hardware: `PRH true ok true true fresh` followed by `PRV 123`. The same approach does not make module-shaped bytecode usable: the strict module fixture first failed as a malformed callable after a raw builtin-count patch, then failed as `type_error: value must be an int` after named-global generation and builtin-count adjustment. The actionable conclusion is that P2 bytecode execution can run simple closures, but preferred `.bec` module loading still needs a real P2-matched emitter/runtime contract; the TODO now directs first-four-priority work away from further `.bec` chasing until that effort is explicitly chosen.
- [x] Rejected an unsafe Priority 2 sync-serial wrapper promotion after a focused hardware attempt. `p2smart.sync_serial_clocked_variant_probe(...)` was briefly changed locally to execute all clock-phase variants, and host coverage plus `./berry -c modules/p2smart.be -o /tmp/p2smart.bec` passed, but the focused hardware command `run_file("/modules/p2smart.be"); sync_serial_clocked_variant_probe(0,1,2,3,[0x12],...)` timed out before returning on the current XMM image. The safe source-wrapper behavior was restored, host coverage again passes, and the corrected `modules/p2smart.be` was re-staged to `/modules/p2smart.be` so variant helpers remain explicit `execution_deferred` diagnostics while the native focused sync smoke remains the verified hardware path.
- [x] Added and hardware-verified the clearly named `examples/sync_serial_loopback.be` user-facing example for the native P2 synchronous-serial jumper diagnostic. The older `examples/spi_loopback.be` remains for compatibility, but docs now point new users to the sync-serial name and describe the old SPI-looking filename as a compatibility alias for the same `0-1` data plus `2-3` clock jumper proof. Focused validation passed with `./berry -c examples/sync_serial_loopback.be -o /tmp/sync_serial_loopback.bec`, `./berry -c examples/spi_loopback.be -o /tmp/spi_loopback.bec`, `make p2-docs-audit`, and after staging only the new example, `python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 --command 'run_file("/berry/examples/sync_serial_loopback.be")' --expect 'sync serial loopback done' --timeout 120 --startup-timeout 120`, reaching `receive execution clocked ... value 18 matched true`.
- [x] Aligned the public coverage matrix with the new sync-serial example name. `docs/coverage-matrix.md` now lists `examples/sync_serial_loopback.be` as the canonical synchronous-serial jumper example, keeps `examples/spi_loopback.be` only as a compatibility-named alias, and separates that proof from native SPI framing evidence in `examples/spi/jedec.be`. Focused validation passed with `make p2-docs-audit`, `git diff --check` on the touched docs/tracker/example files, `./berry -c examples/sync_serial_loopback.be -o /tmp/sync_serial_loopback.bec`, and `make p2-catalina-path-audit TOOLCHAIN=catalina CATALINA_DIR=../Catalina`.
- [x] Made `/tests/p2/smoke_example_paths.be` safer for eventual P2 runs by removing `try/except` cleanup from the happy path; the smoke already asserts it created the temporary example files, so direct `os.remove(...)` assertions are enough. A focused hardware target was intentionally not kept after a trial run timed out while source-loading the large `libstore.be`; the TODO now records that this should not consume routine first-four-priority effort until the helper can run without that slow source-load path. The interrupted trial left `/modules/libstore.be` truncated, so it was restored with smaller chunks; a direct file read then confirmed the staged file starts with `# P2 SD l` instead of the earlier syntax-error truncation.
- [x] Removed current-image-unsafe `try/except` cleanup wrappers from the user-facing I2C and SPI examples while preserving their bounded diagnostics. `examples/i2c/scan.be` now runs the BMP180 scan/chip-id path directly and calls `i2c.stop()` on the normal path; `examples/spi/jedec.be` now runs select/transfer/deselect/stop directly. Focused validation passed with `./berry -c examples/i2c/scan.be -o /tmp/i2c_scan.bec`, `./berry -c examples/spi/jedec.be -o /tmp/spi_jedec.bec`, scoped `git diff --check`, staging only each changed example to `/berry/examples/i2c` and `/berry/examples/spi`, and direct hardware runs on `/dev/ttyUSB0` with sibling Catalina reaching `i2c scan done` and `spi jedec done`.
- [x] Removed the last `try/except` syntax from user-facing examples by changing `examples/spin2/standalone_suite.be` to report the guarded high-level image rejection check as skipped on current normal P2 images. This keeps the archived/default Spin2 example safe while leaving exception-based rejection proof to opt-in Spin2 regression work. Focused validation passed with `./berry -c examples/spin2/standalone_suite.be -o /tmp/spin2_standalone_suite.bec`, `rg -n "^\\s*(try|except)\\b" examples -g "*.be"` returning no syntax matches, staging only `examples/spin2/standalone_suite.be`, and hardware-running `run_file("/berry/examples/spin2/standalone_suite.be")` to `spin2 standalone suite done` on `/dev/ttyUSB0`.
- [x] Cleaned active docs so the normal default P2 image no longer appears to support unconditional `import spin2`. `port/p2/docs/README.md`, `port/p2/docs/PORTING_STATUS.md`, `docs/berry-compatibility.md`, and `docs/P2_SYSTEM_ROADMAP.md` now describe Spin2 as archived/opt-in or detectable through `introspect.module("spin2")`; `port/p2/TODO.md` now says to stop spending priority time on archived/default-unsafe Spin2 paths when they do not work quickly and move effort to working P2 usage paths. Focused validation passed with `make p2-docs-audit`, `make p2-catalina-path-audit TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and scoped `git diff --check`.
- [x] Tried a narrow raw `p2.smart` reserved-pin negative smoke, rejected it as unproductive after it hung on the current XMM image, and made the boundary queryable instead of adding it to routine focused tests. `p2smart.raw_smartpin_reserved_pin_policy()` now reports `raw_smartpin_reserved_pin_rejection` as `staged`, records the attempted `/tests/p2/smoke_smartpins_reserved_pins.be` probe and `hung_before_begin_marker` result, and recommends keeping routine smart-pin work on documented safe jumper pins. `docs/smartpins.md`, `docs/p2-api.md`, `docs/coverage-matrix.md`, and `port/p2/TODO.md` now avoid overclaiming direct raw smart-pin reserved-pin proof. Focused validation passed with `./berry tests/p2/host_p2smart.be`, `./berry -c modules/p2smart.be -o /tmp/p2smart.bec`, `make p2-source-module-metadata-audit`, and scoped `git diff --check`.
- [x] Tightened current Catalina command guidance to prefer the sibling Catalina install explicitly. The Spin2 user-facing examples, `docs/SPIN2_MODULE_TESTS.md`, `docs/P2_BUILD.md`, `docs/P2_MODULES.md`, `docs/building.md`, `docs/architecture-current.md`, `port/p2/docs/README.md`, and `port/p2/docs/PORTING_STATUS.md` now show `CATALINA_DIR=../Catalina` in active copy-paste Catalina commands; `mk/p2.mk` Spin2 SD usage strings do the same. Focused validation passed with local compiles for the edited Spin2 examples, `make p2-docs-audit`, `make p2-catalina-path-audit TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, scoped `git diff --check`, and `make -n spin2-sd-sync TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0`.
- [x] Extended the sibling-Catalina command cleanup into active make wrapper targets. `mk/p2.mk` now shows `CATALINA_DIR=../Catalina` in SD staging/smoke usage strings, passes `CATALINA_DIR="$(CATALINA_DIR)"` through `p2-sd-sync`, `p2-sd-berry-sync`, `test-p2`, `p2-minimal`, and `p2-full`, and keeps current P2 staging dry-runs aligned with the sibling Catalina path. Focused validation passed with dry-runs for `p2-sd-sync`, `p2-sd-berry-sync`, `test-p2`, and `p2-minimal`, plus `make p2-profile-invariants-selftest TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make p2-docs-audit`, `make p2-catalina-path-audit TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, a targeted makefile scan for missing `CATALINA_DIR`, and scoped `git diff --check`.
- [x] Strengthened the Catalina path audit so future active copy-paste commands cannot drop the sibling Catalina path. `scripts/p2/audit_catalina_paths.py` now joins shell continuation lines and rejects active Catalina make command examples that omit `CATALINA_DIR`, while skipping historical release/P2 TODO notes. The new guard caught and fixed stale commands in `AGENTS.md`, `README.md`, `docs/P2_BUILD.md`, `docs/P2_MODULES.md`, and `docs/SPIN2_MODULE_TESTS.md`. Focused validation passed with `python3 -m py_compile scripts/p2/audit_catalina_paths.py`, `make p2-catalina-path-audit TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `make p2-docs-audit`, and scoped `git diff --check`.
- [x] Finished the follow-up cleanup for the deferred raw smart-pin reserved-pin probe. `port/p2/TODO.md` now explicitly says to stop spending routine first-four-priority time on that hung negative path, `docs/smartpins.md` names `p2smart.raw_smartpin_reserved_pin_policy()` as the queryable boundary, and `/tests/p2/smoke_import_all_libs.be` now checks the imported `p2smart` function, diagnostic/staged statuses, policy string, and `hung_before_begin_marker` attempt result. Focused validation passed with `./berry -c tests/p2/smoke_import_all_libs.be -o /tmp/smoke_import_all_libs.bec`, `./berry tests/p2/host_p2smart.be`, `make p2-docs-audit`, `make p2-catalina-path-audit TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and scoped `git diff --check`.
- [x] Cleaned the active P2 testing guides so routine first-four-priority commands no longer point at the old macOS serial port or omit the sibling Catalina setup. `docs/testing.md` and `docs/hardware-tests.md` now use `/dev/ttyUSB0`, set `TOOLCHAIN=catalina` and `CATALINA_DIR=../Catalina` before command lists, keep `priority1-4-min` as the routine direct serial example, and label broader staged/wrapper-loopback paths as occasional regression coverage. Focused validation passed with `make p2-docs-audit`, `make p2-catalina-path-audit TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, `rg -n "/dev/cu\\.usbserial" docs/testing.md docs/hardware-tests.md` returning no matches, dry-runs for `p2-smoke-priority1-4-min`, `p2-smoke-smartpins-focused`, and `soak-p2 SOAK_P2_SUITE=soak-smartpins-focused`, plus scoped `git diff --check`.
- [x] Strengthened the Priority 1 SD-write smoke audit so new SD-writing smoke files cannot silently skip the cleanup contract. `scripts/p2/audit_sd_write_smokes.py` now fails on unmarked direct write opens, keeps the broad cache-rewriting `/tests/p2/smoke_bec_fallback.be` as an explicit non-routine exception, and `/tests/p2/smoke_sys_path_add.be` now carries `P2_SD_WRITE_AUDIT max_write_opens=1`. Focused validation passed with `make p2-sd-write-smoke-audit`, explicit relative and absolute-path audit runs for the broad `.bec` exception, a temporary unmarked-write negative self-test that failed with the expected missing-marker error, `./berry -c tests/p2/smoke_sys_path_add.be -o /tmp/smoke_sys_path_add.bec`, `python3 -m py_compile scripts/p2/audit_sd_write_smokes.py`, and scoped `git diff --check`.
- [x] Made the routine first-four-priority minimal health target cover real Priority 3 PASM behavior instead of metadata only. `scripts/p2/repl_smoke.py --suite priority1-4-min` now runs `p2.asm.fixture_add(20,22)` and expects `P2_PASM_MIN true true 42`, proving the safe fixed mailbox fixture-call path without adding the broad PASM layout/policy suites to the minimal aggregate. `docs/coverage-matrix.md` and `port/p2/TODO.md` now describe `priority1-4-min` as covering real Priority 1 lazy-import policy, real Priority 2 smart-pin signal behavior, real Priority 3 fixture-call behavior, and real Priority 4 VM/task/IPC/multicog behavior. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py`, `make p2-docs-audit`, `make -n p2-smoke-priority1-4-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and scoped `git diff --check`.
- [x] Added the general first-four-priority triage rule requested after the deferred hardware attempts: current-image-unsafe or hanging paths get one narrow focused try, then the exact failure/defer reason is recorded and routine effort moves to working P2 usage paths, examples, and cheap guards unless that path is explicitly chosen again.
- [x] Added a cheap user-facing example safety guard for the current normal P2 image. `scripts/p2/audit_example_safety.py` rejects line-start `try` / `except` syntax under `examples/`, `make p2-example-safety-audit` exposes the check directly, and `make p2-baseline-guards` now runs it with the other non-hardware guards so examples stay copy-paste-safe without blocking host-only or non-routine exception regression tests.
- [x] Tightened the same example safety guard to require explicit final `done` markers for runnable examples. The audit currently checks all `57` `.be` files under `examples/`, treats `examples/core/run_file.be` as the single support-only file because `run_file_demo.be` owns the runnable completion marker, and confirms the other `56` runnable examples avoid current-image-unsafe line-start `try` / `except` syntax and expose stable completion markers.
- [x] Extended the example safety guard to compile every example locally with `./berry -c` into a temporary directory before checking the P2 safety rules. This gives the first-four-priority baseline a cheap syntax gate for user-facing examples without adding hardware time or broad smoke reruns.
- [x] Tightened the sibling-Catalina guard around active make guidance. `mk/p2.mk` usage messages that show `/dev/ttyUSB0` now include `TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, composed first-four and smart-pin aggregate targets propagate `TOOLCHAIN=catalina` plus `CATALINA_DIR="$(CATALINA_DIR)"` into nested smoke submakes, and `scripts/p2/audit_catalina_paths.py` now rejects future P2 make usage strings that omit `CATALINA_DIR`.
- [x] Extended the sibling-Catalina guard to active `make ... PORT=/dev/ttyUSB0` command examples, not just usage strings. `docs/testing.md`, `docs/hardware-tests.md`, and the active TODO command labels now show `TOOLCHAIN=catalina CATALINA_DIR=../Catalina` inline for P2 hardware/smoke/soak commands, `scripts/p2/repl_smoke.py --help` now uses `/dev/ttyUSB0` as its serial example, and `scripts/p2/audit_catalina_paths.py` rejects future active P2 make command examples that omit `CATALINA_DIR` while leaving explicit FlexC loader-tool notes alone.
- [x] Removed the old macOS serial-port path from active P2 user guidance. `README.md`, `docs/getting-started.md`, `docs/sd-layout.md`, `docs/P2_BUILD.md`, `docs/P2_MODULES.md`, `docs/building.md`, `docs/architecture-current.md`, `docs/P2_SYSTEM_ROADMAP.md`, `port/p2/docs/README.md`, and `port/p2/docs/PORTING_STATUS.md` now use `/dev/ttyUSB0` plus sibling Catalina command examples for active P2 build/smoke/sync instructions, while historical release and handoff capture files are left unchanged. `make p2-catalina-path-audit` now rejects `/dev/cu.usbserial-P97cvdxp` in the active scanned guidance.
- [x] Re-aligned `docs/roadmap.md` with the current first-four-priority operating model. The roadmap now says Priority labels are sequencing labels, not Propeller hardware names, names sibling Catalina as the normal toolchain, points routine hardware checks at `p2-smoke-priority1-4-min`, and replaces the old "zero open TODO items" completion wording with the current evidence rule: current-scope items must be done, tested, or explicitly deferred/unsupported with a focused attempt and tracker evidence.
- [x] Added a docs guard for the earlier confusing old compact priority style shorthand. `make p2-docs-audit` now rejects ambiguous non-`P2` priority shorthand in the active P2 docs and live TODO/DONE trackers, so roadmap sequencing must be written as `Priority N` and hardware references stay clearly `P2`.
- [x] Removed remaining line-start `for` iterator loops from user-facing examples and tightened `make p2-example-safety-audit` to reject new example-level `for` loops along with `try` / `except`. `examples/blink.be`, `examples/p2/blink.be`, `examples/adc_read.be`, `examples/dac_write.be`, `examples/pwm_fade.be`, `examples/gpio_loopback.be`, `examples/quadrature_counter.be`, and the archived Spin2 example files now use bounded indexed `while` loops so normal P2 examples avoid a known current-image hang shape. The audit compiles all `57` example files and confirms the `56` runnable examples avoid line-start `try` / `except` / `for` syntax and keep final `done` markers.
- [x] Added explicit board/profile compatibility policy metadata to `p2compat`. `p2compat.board_profile_policy()` now reports build-facing fields such as board, profile, Catalina model, runtime memory profile, PSRAM board state from `p2.status_info()["build"]["board_has_psram"]`, reserved-pin policy, normal toolchain path `../Catalina`, normal serial port `/dev/ttyUSB0`, and the rule that unsupported board/profile combinations must raise loudly or report unsupported instead of being guessed. `p2compat.board_profile_value(name)` provides snapshot-safe single-field lookup, and `required_board_profile_policy_keys()` plus `audit()` keep the policy present. Host coverage pins the returned values, mutation isolation, and audit consistency.
- [x] Repaired and hardware-verified the p2compat source-module smoke path after the first hardware attempt timed out at `P2_SMOKE_BEGIN p2compat`. `modules/p2compat.be` now avoids current-image-unsafe line-start `for` / `try` / `except` syntax by using indexed `while` loops and direct `p2.status_info()` calls for build/runtime metadata. After staging the cleaned module and `/tests/p2/smoke_p2compat.be`, the focused hardware command `run_file("/tests/p2/smoke_p2compat.be")` passed on `/dev/ttyUSB0`, reaching `P2_SMOKE_PASS p2compat`. The routine `p2-smoke-p2compat` target and `scripts/p2/repl_smoke.py --suite p2compat` now include the source policy smoke before `/tests/p2/p2compvm.be`, and the full focused target passed with sibling Catalina, reaching `P2_SMOKE_PASS p2compat`, `P2_SMOKE_PASS p2compat_child_vm`, and `[p2-smoke] PASS p2compat iterations=1`.
- [x] Made the p2compat board/profile policy actionable for pin use. `board_profile_policy()` now includes copied `reserved_pin_ranges`, `board_pin_policy(pin)` returns result-shaped `ok` / `reserved` / `reason` diagnostics for invalid, PSRAM, SD, serial, and allowed pins, and `board_pin_allowed(pin)` gives the compact boolean answer. Host coverage pins the XMM `p2edge32` PSRAM/SD/serial ranges and returned-range mutation isolation; the focused p2compat source smoke checks allowed jumper pin `0`, reserved SD pin `58`, reserved serial pin `63`, out-of-range pin `64`, and PSRAM pin `40` when the active policy has PSRAM enabled.
- [x] Added and hardware-verified `make p2-smoke-examples-bus` as a focused user-facing bus-example target. The target stages only `examples/i2c/scan.be` and `examples/spi/jedec.be`, then runs `scripts/p2/repl_smoke.py --suite examples-bus` instead of syncing the broad example tree. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py`, local compiles for both examples, `make -n p2-smoke-examples-bus PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and `make p2-smoke-examples-bus PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `i2c scan done`, `spi jedec done`, and `[p2-smoke] PASS examples-bus iterations=1`.
- [x] Added and hardware-verified `make p2-smoke-examples-system` as a focused user-facing system/SD example target. The target stages only `examples/cordic_demo.be`, `examples/psram_cache_stats.be`, `examples/repl_sd.be`, `examples/file_sd.be`, and `examples/json_sd.be`, then runs `scripts/p2/repl_smoke.py --suite examples-system` instead of syncing the broad example tree. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py`, local compiles for all five examples, `make -n p2-smoke-examples-system PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and `make p2-smoke-examples-system PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `cordic demo done`, `psram cache stats done`, `repl sd helper done`, `file sd example done`, `json sd example done`, and `[p2-smoke] PASS examples-system iterations=1`.
- [x] Added and hardware-verified `make p2-smoke-examples-runtime` as a focused native runtime example target. The first version tried to include `modules/p2ipc.be`, `task_ipc.be`, and `cog_channel.be`, but the combined target was interrupted while uploading the large p2ipc source module, so the routine target was narrowed to native examples only and p2ipc-backed examples remain covered by `p2-smoke-ipc` or direct one-off runs. The final target stages only `examples/task_scheduler.be`, `examples/task_primitives.be`, short-alias `examples/cog_closure.be`, short-alias `examples/cog_closure_blink.be`, and `examples/pasm_direct.be`, then runs `scripts/p2/repl_smoke.py --suite examples-runtime`. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py`, local compiles for the runtime examples, `make -n p2-smoke-examples-runtime PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and `make p2-smoke-examples-runtime PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, now reaching `task scheduler example done`, `task primitives example done`, `cog closure example done`, `cog closure blink done`, `pasm direct done`, and `[p2-smoke] PASS examples-runtime iterations=1`.
- [x] Added and hardware-verified `make p2-smoke-examples-serial` as a focused native serial example target. The target stages only `examples/uart_loopback.be` and `examples/sync_serial_loopback.be`, then runs `scripts/p2/repl_smoke.py --suite examples-serial` without syncing broad examples or source-loading `p2smart.be`. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py`, local compiles for both examples, `make -n p2-smoke-examples-serial PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and `make p2-smoke-examples-serial PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `uart loopback done`, `sync serial loopback done`, and `[p2-smoke] PASS examples-serial iterations=1`.
- [x] Added `make p2-smoke-examples-wifi` as an on-demand metadata-only WiFi example target, then applied the one-focused-attempt rule when the current run did not complete. The target stages only `modules/wifi.be` and `examples/wifi/detect.be`; validation passed for `python3 -m py_compile scripts/p2/repl_smoke.py`, local bytecode compiles for both files, `make -n p2-smoke-examples-wifi PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and scoped `git diff --check`. The hardware attempt uploaded both files, reached the REPL prompt on image `1165888 / 16777216`, sent `run_file("/berry/examples/wifi/detect.be")`, then produced no `wifi detect done` marker before interruption, so docs now keep this out of the common routine command list and say to stop after one focused attempt until the WiFi metadata path is fixed.
- [x] Added and hardware-verified `make p2-smoke-examples-p2` as a focused legacy P2 helper-example target. The target stages only the seven small `examples/p2/` helper files, then runs `scripts/p2/repl_smoke.py --suite examples-p2` without syncing the broad example tree. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py`, local compiles for all seven helper files, `make -n p2-smoke-examples-p2 PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, scoped `git diff --check`, and `make p2-smoke-examples-p2 PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `p2 blink done`, `p2 pin helpers done`, `p2 smartpin helpers done`, `p2 timing helpers done`, `p2 hardware helpers done`, `p2 closure blinker done`, `p2 source blinker done`, and `[p2-smoke] PASS examples-p2 iterations=1`.
- [x] Added and hardware-verified `make p2-smoke-examples-unsupported` as a focused user-facing unsupported-boundary target. The target stages current `modules/p2compat.be`, `examples/vga_test_pattern.be`, and `examples/usb_keyboard_mouse.be`, then runs `scripts/p2/repl_smoke.py --suite examples-unsupported`. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py`, local compiles for the module and both examples, `make -n p2-smoke-examples-unsupported PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, scoped `git diff --check`, and `make p2-smoke-examples-unsupported PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `vga test pattern done`, `usb keyboard mouse done`, and `[p2-smoke] PASS examples-unsupported iterations=1` while reporting backed unsupported `p2compat` records instead of fake VGA/USB behavior.
- [x] Added and hardware-verified `make p2-smoke-examples-core` as a focused user-facing core-example target. The target stages only `examples/core` under `/berry/examples/core`, then runs `scripts/p2/repl_smoke.py --suite examples-core`, including scripted input for `guess_number.be` and `repl.be`. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py`, local compiles for all core examples, `make -n p2-smoke-examples-core PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, scoped `git diff --check`, and `make p2-smoke-examples-core PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `run_file demo done`, `listdir demo done`, `bigloop demo done`, `fib recursion demo done`, `calcpi demo done`, `json core demo done`, `anonymous closure demo done`, `qsort demo done`, `lambda demo done`, `bintree demo done`, `string demo done`, `string format demo done`, `exception demo done`, `guess number demo done`, `repl demo done`, and `[p2-smoke] PASS examples-core iterations=1`.
- [x] Folded `examples/blink.be` into the routine quick user-facing example target. `make p2-smoke-examples-quick` now stages `blink.be` along with the native GPIO/PWM/ADC/DAC/NCO examples and runs all six final markers through `scripts/p2/repl_smoke.py --suite examples-quick`. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py`, `./berry -c examples/blink.be -o /tmp/blink.bec`, `make -n p2-smoke-examples-quick PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, scoped `git diff --check`, and `make p2-smoke-examples-quick PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `blink done`, `gpio loopback done`, `pwm fade done`, `adc done`, `dac done`, `nco counter loopback done`, and `[p2-smoke] PASS examples-quick iterations=1`.
- [x] Converted `examples/quadrature_counter.be` to the native `import p2` / `p2.smart` path and folded it into the routine quick user-facing example target. The example now clears/floats pins `0..3`, drives pins `0` and `2` into quadrature inputs `1` and `3`, and reports synthetic forward/reverse motion without source-loading the large `p2smart.be` wrapper. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py`, `./berry -c examples/quadrature_counter.be -o /tmp/quadrature_counter.bec`, `make p2-example-safety-audit`, `make -n p2-smoke-examples-quick PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, scoped `git diff --check`, and `make p2-smoke-examples-quick PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `quadrature counter done` with forward delta `8` / direction `1`, reverse delta `-8` / direction `-1`, and `[p2-smoke] PASS examples-quick iterations=1`.
- [x] Converted `examples/smartpin_diagnostics.be` from the broad `p2smart.jumper_pair_probe()` wrapper path to direct native `import p2` / `p2.smart` checks, and added a separate focused `make p2-smoke-examples-smartpin-diagnostics` target so the quick example smoke stays small. The example now checks GPIO low/high, one counted rise, positive high-ticks, and one async serial byte on each documented jumper pair `0-1`, `2-3`, `4-5`, and `6-7`, then clears/floats the pins. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py`, `./berry -c examples/smartpin_diagnostics.be -o /tmp/smartpin_diagnostics.bec`, `make p2-example-safety-audit`, `make -n p2-smoke-examples-smartpin-diagnostics PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and `make p2-smoke-examples-smartpin-diagnostics PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `smartpin diagnostics ok true`, `smartpin diagnostics done`, and `[p2-smoke] PASS examples-smartpin-diagnostics iterations=1`.
- [x] Tried a narrower p2ipc-backed user-facing example aggregate for `examples/task_ipc.be` and `examples/cog_channel.be`, then rejected it as routine first-four-priority work after the one focused attempt produced no visible progress before interruption during `modules/p2ipc.be` upload. Local validation passed for the temporary wiring with `python3 -m py_compile scripts/p2/repl_smoke.py`, local compiles for both examples, `make p2-example-safety-audit`, and a dry-run using sibling Catalina, but the unproven target wiring was removed. The TODO now says to keep routine work on `p2-smoke-ipc` or direct one-off example runs until the p2ipc upload/load path is made cheap enough for a focused example aggregate.
- [x] Converted `examples/debug_report.be` to a native-only debug/runtime example and added `make p2-smoke-examples-debug` as a focused target. The first focused target attempt that still staged `modules/p2mem.be` was rejected after it produced no visible progress during the source-module upload; the example now avoids `p2mem`, prints compact backed `p2.debug` fields plus `p2.fs_info()` and `p2.psram_info()` runtime fields, and the target stages only `examples/debug_report.be`. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py`, `./berry -c examples/debug_report.be -o /tmp/debug_report.bec`, `make p2-example-safety-audit`, `make -n p2-smoke-examples-debug PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and `make p2-smoke-examples-debug PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`; after fixing the PSRAM field from missing `present` to `available`, the hardware run reached `profile: xmm`, `led pin: 38`, `cog count: 8`, `fs mounted: true`, `psram available: true`, `debug report done`, and `[p2-smoke] PASS examples-debug iterations=1`.
- [x] Tried the requested narrow rerun path for the user-facing import sweep, then moved it out of routine work when it did not complete. A temporary `p2-smoke-examples-imports` target staged `modules/binary_heap.be`, `modules/configstore.be`, `modules/p2compat.be`, `modules/p2ipc.be`, `modules/wifi.be`, and `examples/import_all_libs.be`; the bounded hardware attempt on `/dev/ttyUSB0` with sibling Catalina completed all uploads including `modules/p2ipc.be`, but timed out before `import all libs example done`. The unproven target wiring was removed, and the TODO now says not to spend routine first-four-priority time retrying that aggregate unless explicitly chosen again.
- [x] Folded the full `examples/cog_closure.be` user-facing example into the focused runtime example target and fixed the P2 FAT 8.3 collision it exposed. The first hardware run staged both `cog_closure.be` and `cog_closure_blink.be` under their long names, then `run_file("/berry/examples/cog_closure.be")` executed the blink example and failed to reach `cog closure example done`. The target now stages them as short aliases `cogclo.be` and `cogblk.be`; `make p2-smoke-examples-runtime PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passes, reaching `task scheduler example done`, `task primitives example done`, `cog closure example done`, `cog closure blink done`, `pasm direct done`, and `[p2-smoke] PASS examples-runtime iterations=1`.
- [x] Extended the user-facing example safety audit to catch the same focused target staging bug class before hardware runs. `scripts/p2/audit_example_safety.py` now parses `p2-sd-examples-*` upload blocks in `mk/p2.mk`, computes the direct target directory plus 8.3-style key for `--file` and `--target-file` uploads, and fails if two directly staged files in one focused example target would collide without explicit aliases. `make p2-example-safety-audit` now reports that all examples compile, avoid current-image-unsafe syntax, have final markers, and focused example staging avoids direct 8.3 collisions. A temporary negative self-test that reverted both runtime closure uploads to long-name `--file` staging failed with the expected `COG_CLOS.BE` collision diagnostic.
- [x] Broadened the focused staging collision guard from example-only blocks to focused P2 smoke/example upload targets. `scripts/p2/audit_example_safety.py` now checks direct `--file`, `--target-file`, and `--binary-target-file` staging under focused `p2-sd-*smoke`, `p2-sd-examples-*`, and `p2-smoke-*` targets, so test-smoke aliases get the same P2 FAT 8.3 protection as user examples. Focused validation passed with `python3 -m py_compile scripts/p2/audit_example_safety.py`, `make p2-example-safety-audit`, and a temporary negative self-test where two focused test files collided as `SMOKE_PA.BE`.
- [x] Extended the same focused P2 staging guard to reject missing literal source files before a board run. `scripts/p2/audit_example_safety.py` now checks direct non-generated `--file` and `--target-file` upload sources in focused P2 smoke/example targets, while skipping generated/variable fixture paths and binary target files. Focused validation passed with `python3 -m py_compile scripts/p2/audit_example_safety.py`, `make p2-example-safety-audit`, and a temporary negative self-test where `p2-smoke-missing-demo` tried to stage `tests/p2/no_such_smoke.be` and failed with the expected missing-source diagnostic. `make p2-baseline-guards TOOLCHAIN=catalina CATALINA_DIR=../Catalina` also passes with the widened guard in the normal non-hardware baseline bundle.
- [x] Extended the focused example guard to verify `scripts/p2/repl_smoke.py --suite examples-*` run paths are actually staged by their matching `p2-sd-examples-*` make targets. This protects short aliases such as `/berry/examples/cogclo.be` and `/berry/examples/cogblk.be` from drifting away from the make upload target before a hardware run. Focused validation passed with `python3 -m py_compile scripts/p2/audit_example_safety.py`, `make p2-example-safety-audit`, and a temporary negative self-test where removing `/berry/examples/cogclo.be` from the staged runtime target map produced the expected `suite examples-runtime runs /berry/examples/cogclo.be` diagnostic. `make p2-baseline-guards TOOLCHAIN=catalina CATALINA_DIR=../Catalina` also passes with the runner/staging alignment check in the normal non-hardware baseline bundle.
- [x] Extended the same focused staging guard to mapped non-example test suites in `scripts/p2/repl_smoke.py`. `scripts/p2/audit_example_safety.py` now verifies focused suites such as `core-builtins-min`, `p2compat`, `bec-abi-min`, `priority2`, `priority3`, `priority4`, and the focused smart-pin suites run only `/tests/p2/...` and `/modules/...` paths staged by their explicit focused make targets or target unions. This catches runner/staging drift before a board run without broad hardware testing.
- [x] Added and hardware-verified `make p2-smoke-stdlib-min` as a focused normal-image standard-library quick path. The target stages only `/tests/p2/smoke_stdlib_min.be` and runs `scripts/p2/repl_smoke.py --suite stdlib-min`; the smoke avoids current-image-unsafe `try` / `except` / `for` syntax, verifies common `string`, `json`, and `solidify.compact()` behavior, and reports explicit skips for absent optional `time`, `global`, and `strict` modules on the normal XMM image. Focused validation passed with `./berry -c tests/p2/smoke_stdlib_min.be -o /tmp/smoke_stdlib_min.bec`, `python3 -m py_compile scripts/p2/repl_smoke.py scripts/p2/audit_example_safety.py`, `make p2-example-safety-audit`, `make -n p2-smoke-stdlib-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and `make p2-smoke-stdlib-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMOKE_STDLIB_MIN string`, `P2_SMOKE_STDLIB_MIN json`, `P2_SMOKE_STDLIB_MIN solidify`, `P2_SMOKE_SKIP stdlib_min_time`, `P2_SMOKE_SKIP stdlib_min_global`, `P2_SMOKE_SKIP stdlib_min_strict`, and `P2_SMOKE_PASS stdlib_min`.
- [x] Folded the focused normal-image standard-library proof into the upload-capable Priority 1 wrapper. `make p2-smoke-priority1` still starts with the quick inline `priority1-min` REPL checks for core builtins, collections, and SD file write/read/remove, then invokes `p2-smoke-stdlib-min` so the normal Priority 1 target also covers common `string`, `json`, and `solidify.compact()` behavior without uploading the large source-module set or running broad import/cache/churn suites.
- [x] Folded the focused normal-image standard-library proof into the routine first-four-priority minimal aggregate and applied the one-focused-attempt rule to the slow upload path. `scripts/p2/repl_smoke.py --suite priority1-4-min` now runs `/tests/p2/smoke_stdlib_min.be` before the lazy-library policy smoke, and `make p2-smoke-priority1-4-min` stages that file alongside `modules/libstore.be`, `modules/p2ipc.be`, and `tests/p2/smoke_libraries_lazy_min.be`. The upload-capable target was tried once after the change but was interrupted during the pre-existing large `libstore.be` upload path after no useful progress, leaving `/modules/libstore.be` truncated; the file was repaired with a direct smaller-chunk upload, `libraries-lazy-min` passed afterward, and the already-staged `make p2-smoke-priority1-4-min-staged PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` passed with `P2_SMOKE_PASS stdlib_min` and `P2_SMOKE_PASS priority1_4_min`. The tracker now says to stop spending routine first-four-priority time rerunning that slow upload-capable path unless it is explicitly selected again.
- [x] Added and hardware-verified `make p2-smoke-sd-file-core-min` as the routine Priority 1 SD/file slice. `/tests/p2/smoke_sd_min.be` avoids current-image-unsafe line-start `for` / `try` / `except` syntax and verifies SD mount metadata, `open()` write/append/read-update behavior, `flush`/`tell`/`size`/`seek`, path helpers, directory create/chdir/remove, rename, missing-path checks, and cleanup. The new suite is staged by `p2-sd-file-core-min-smoke`, mapped by the focused staging guard, included in `make p2-smoke-priority1`, and staged by `make p2-smoke-priority1-4-min` before the first-four minimal aggregate. Focused validation passed with `./berry -c tests/p2/smoke_sd_min.be -o /tmp/smoke_sd_min.bec`, `python3 -m py_compile scripts/p2/repl_smoke.py scripts/p2/audit_example_safety.py`, `make p2-example-safety-audit`, `make p2-sd-write-smoke-audit`, dry-runs for the new target and `p2-smoke-priority1-4-min`, `make p2-smoke-sd-file-core-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and `make p2-smoke-priority1 PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, reaching `P2_SMOKE_PASS sd_file_core_min`, `P2_SMOKE_PASS priority1_min`, and `P2_SMOKE_PASS stdlib_min`.
- [x] Strengthened the routine first-four-priority Priority 3 PASM proof without adding broad layout/runtime cost. `scripts/p2/repl_smoke.py --suite priority1-4-min` still keeps the existing `fixture_add(20,22)` audit/result check, and now also calls fixed mailbox fixture operations `sub`, `xor`, `and`, and `or` as short serial-safe REPL commands, expecting `P2_PASM_OPS_MIN true 42 true 90 true 5 true 95`. This proves the named-operation fixture bridge used by normal P2 code beyond one add path while still avoiding arbitrary PASM launch or the broader PASM layout suite. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py` and a direct hardware REPL sequence on `/dev/ttyUSB0` with sibling Catalina, reaching `P2_PASM_OPS_MIN true 42 true 90 true 5 true 95`.
- [x] Added and hardware-verified compact p2ipc payload-boundary evidence to the routine first-four-priority minimal suite. `scripts/p2/repl_smoke.py --suite priority1-4-min` now checks `p2ipc.payload_result("abc")` and `p2ipc.payload_result([1,2])`, expecting `P2_IPC_PAY_MIN true string false list`, so routine Priority 4 coverage proves the current primitive-copyable/string versus live-list rejection boundary before the channel/mailbox payload movement checks. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py` and a direct hardware REPL sequence on `/dev/ttyUSB0` with sibling Catalina, reaching `P2_IPC_PAY_MIN true string false list`.
- [x] Added and hardware-verified a compact PWM-output proof to the routine first-four-priority minimal suite. `scripts/p2/repl_smoke.py --suite priority1-4-min` now starts native `p2.smart` PWM triangle output on pin `0` and `count_highs` input on pin `1`, then expects `P2_SMART_PWM_MIN true` after a bounded 2 ms sample. This proves routine Priority 2 smart-pin output behavior on the documented `0->1` jumper without running the broader output-mode suite or claiming calibrated PWM waveform timing. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py` and a direct hardware REPL sequence on `/dev/ttyUSB0` with sibling Catalina, reaching `P2_SMART_PWM_MIN true`.
- [x] Added and hardware-verified a compact ADC/DAC proof to the routine first-four-priority minimal suite. `scripts/p2/repl_smoke.py --suite priority1-4-min` now starts native `p2.smart` DAC output on pin `0` and ADC input on pin `1`, writes low then high DAC values, and expects `P2_SMART_ADC_DAC_MIN true` when the bounded ADC samples differ. This keeps Priority 2 analog signal coverage in the routine path without running the broader ADC/DAC variant suite or claiming calibrated voltage accuracy. Focused validation passed with a direct hardware REPL sequence on `/dev/ttyUSB0` with sibling Catalina, reaching `P2_SMART_ADC_DAC_MIN true`.
- [x] Added and hardware-verified a persistent child-VM lifecycle proof to the routine first-four-priority minimal suite. `scripts/p2/repl_smoke.py --suite priority1-4-min` now opens child slot `1`, evaluates `child_status_value=41`, reads it back with `p2.vm_get(...)`, closes the slot, and expects `P2_VM_LIFE_MIN true true 41 true inactive`. This extends Priority 4 VM coverage beyond the existing one-shot child-call proof while still avoiding broader VM-cog and p2compat source-suite cost. Focused validation passed with a direct hardware REPL sequence on `/dev/ttyUSB0` with sibling Catalina, reaching `P2_VM_LIFE_MIN true true 41 true inactive`.
- [x] Added and hardware-verified an explicit isolated-child-VM-cog unsupported-policy proof to the routine first-four-priority minimal suite. `scripts/p2/repl_smoke.py --suite priority1-4-min` now expects `P2_COG_ISO_MIN unsupported_catalina_xmm_c_cog_runtime_not_safe string`, proving the current Catalina XMM image reports the VM-per-cog boundary loudly instead of implying hidden support. Focused validation passed with a direct hardware REPL sequence on `/dev/ttyUSB0` with sibling Catalina, reaching that marker.
- [x] Added and hardware-verified an explicit native task scheduler policy proof to the routine first-four-priority minimal suite. `scripts/p2/repl_smoke.py --suite priority1-4-min` now expects `P2_TASK_POLICY_MIN current_vm_callback_step p2_native_cooperative false false`, proving the current native task backend is current-VM cooperative, non-preemptive, and does not expose independent stacks. Focused validation passed with a direct hardware REPL sequence on `/dev/ttyUSB0` with sibling Catalina, reaching that marker.
- [x] Added and hardware-verified a child-VM live-object argument rejection proof to the routine first-four-priority minimal suite. `scripts/p2/repl_smoke.py --suite priority1-4-min` now expects `P2_VM_REJECT_MIN false args_rejected list false`, proving a list argument is rejected before partition/runtime selection. Focused validation passed with a direct hardware REPL sequence on `/dev/ttyUSB0` with sibling Catalina, reaching that marker.
- [x] Added and hardware-verified a native cog cleanup baseline proof to the routine first-four-priority minimal suite. `scripts/p2/repl_smoke.py --suite priority1-4-min` now expects `P2_COG_CLEAN_MIN true 0 0` before spawning the routine native-blink handle, proving aggregate cleanup starts from an empty registry with no released handles or stopped raw cogs. Focused validation passed with a direct hardware REPL sequence on `/dev/ttyUSB0` with sibling Catalina, reaching that marker.
- [x] Applied the one-focused-attempt rule to the routine IPC cross-cog boundary probe. A direct hardware attempt to read `p2ipc.contract()` / `attention_policy()` for `P2_IPC_BOUNDARY_MIN false false false false` timed out at `import p2ipc` on the current image, so this was not added to `priority1-4-min`; keep routine IPC coverage on the existing compact current-VM probes until the p2ipc import path is cheaper or native-backed.
- [x] Fixed the routine first-four-priority minimal runner so the PWM and ADC/DAC smart-pin checks are self-contained from a clean REPL. The `priority1-4-min` PWM and ADC/DAC steps now call `p2.waitus(...)` directly instead of relying on a stale `c` alias that was only defined later in the async-serial step. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py`, scoped `git diff --check`, and a direct hardware sequence on `/dev/ttyUSB0` with sibling Catalina that reached `P2_SMART_PWM_MIN true` and `P2_SMART_ADC_DAC_MIN true` without defining `c`.
- [x] Hardened custom focused REPL probes so repeated `--command` sequences cannot accidentally attach `--expect`, `--input-marker`, or `--input-text` to the wrong command. `scripts/p2/repl_smoke.py` now rejects mismatched positional option counts before opening serial, and `docs/testing.md` documents using empty strings for setup commands. Focused validation passed with `python3 -m py_compile scripts/p2/repl_smoke.py`, scoped `git diff --check`, and a no-hardware negative invocation that exited with the expected positional `--expect` diagnostic before touching `/dev/ttyUSB0`.
- [x] Closed three stale Priority 1 math TODO entries whose own tracker evidence already proved completion: expanded finite `math` surface, native-compatible `math.nan` / `math.inf` / invalid-result behavior, and adapted upstream `tests/math.be` parity coverage. The TODO now keeps the separate CORDIC timing/measurement item open instead of conflating it with the already hardware-verified math behavior.
- [x] Closed four stale Priority 4 native-blink/child-VM-boundary TODO entries whose tracker evidence already proved the current contract: primitive-copy/reject child-VM argument behavior, rejection of native-pointer/file-handle/hardware-resource live transfer, current native-blink handle APIs (`id`, `status`, `join`, `stop`, `kill`, `result`, `error`), and nonblocking join/result/error propagation. The TODO still keeps independent VM-cog execution, broader serialization, blocking waits, and cross-cog exception propagation open.
- [x] Closed three stale Priority 4 current-VM task TODO entries whose tracker evidence already proved the implemented surface: native/source task lifecycle aliases (`spin`, `next`, `stop`, `halt`/`hlt`, `cont`, `chk`, `id`), current-VM RTOS-style primitives (`Semaphore`, `Mutex`, `Queue`, `EventFlags`, `Timer`), and host plus focused hardware coverage for task switching/synchronization. The TODO still keeps independent Berry stacks/coroutines, true Spin2/PASM switching, cross-cog IPC wakeups, and broader timing/soak work open.
- [x] Closed five stale Priority 2 grouped low-level API TODO entries whose tracker evidence already proved the exact current surfaces: `p2.clock`, `p2.cog`, `p2.lock`, `p2.pin`, and `p2.cordic` / `p2.math` / `p2.rng`. The TODO still keeps broader unsupported-build validation, all-API stress/examples, and arbitrary cog lifecycle work open.
- [x] Closed the stale Priority 2 smart-pin status/queryability TODO. The tracked `p2smart` capability, status, status-report, and audit helpers already expose verified, setup-only, staged, unverified, and unsupported wrapper areas with host/import coverage for direct lookup, unknown-status rejection, snapshot isolation, required-key audit diagnostics, and explicit unsupported-policy boundaries. Actual calibrated ADC/DAC, buffered UART/FIFO, USB, mechanical quadrature, and broader timing validation remain tracked separately.
- [x] Closed three stale Priority 2 smart-pin implementation TODOs whose tracker evidence already proved the current usable surfaces: raw smart-pin helpers (`wrpin`, `wxpin`, `wypin`, `akpin`, `rdpin`, `rqpin`, `start`, `clear`), high-level GPIO input/output classes, and high-level PWM/Pulse/Transition wrappers. Remaining calibrated waveform measurements, buffered serial behavior, non-jumper patterns, and broader timing validation stay open under their own caveats instead of blocking these completed surfaces.
- [x] Closed five more stale Priority 2 smart-pin wrapper TODOs whose evidence already proves implemented user-facing surfaces: ADC, DAC, timer/counter/NCO, quadrature, and async UART. The tracker still keeps calibrated ADC/DAC scaling and polarity, broader DAC variant validation, calibrated state/event/period/counter timing interpretation, mechanical encoder behavior, real background UART buffering/FIFO, synchronous-serial source-wrapper promotion, and wrapper-wide loopback/example completeness open.
- [x] Closed the stale Priority 2 user-facing examples alignment TODO. The listed examples now either use the real native P2 APIs, run through focused hardware targets/direct runs with final markers, avoid slow source-wrapper imports on the normal image, clear/floats pins and clean up temp files where relevant, or report explicit unsupported VGA/USB boundaries instead of fake behavior. Broader soak duration, p2ipc aggregate upload cost, and full `test-p2` breadth remain open separately.
- [x] Closed the stale Priority 2 low-level API tests/examples TODO. The grouped P2 API smoke and focused legacy `examples/p2/` hardware target already cover the implemented low-level surfaces and examples; unsupported board/build combinations and broader cross-API validation remain open separately.
- [x] Closed the stale Priority 1 built-ins/core-features test TODO. The focused core-builtins slice, dedicated compact smokes, and scripted `compat` input handshake already cover the named built-ins and core collection/conversion/call/compile/module/range/bytes behavior on the current native-Catalina XMM path. Broader standard-library, profile, and full-suite verification remain open separately.
- [x] Closed two stale Priority 1 SD/import TODOs whose current tests already prove the implemented behavior: global module cache identity/metadata/cache accounting and lazy SD library loading with no eager PSRAM-cache use. `.bec` module preference, compile-to-cache on default P2 firmware, SD module provisioning across profiles, and the broad scripted SD smoke rerun remain open separately.
- [x] Closed the stale Priority 1 SD-backed `math` provisioning TODO. Existing XMM and Edge32/non-XMM evidence already verifies `/modules/math.be` is present and SD-backed `import math` works, while `smoke_edge32.be` additionally covers PSRAM cache/load behavior for that SD module. The broad full scripted SD smoke rerun remains open separately.
- [x] Strengthened the focused p2compat smoke path for unsupported board/build policy. `scripts/p2/repl_smoke.py --suite p2compat` now directly checks `p2compat.board_profile_policy()` and `board_pin_policy(...)` for loud unsupported-build policy metadata, sibling Catalina guidance, one safe jumper pin, one SD-reserved pin, and `audit_ok()` before running the existing child-VM probes.
- [x] Closed the stale Priority 1 user-facing docs creation/update TODO. The named getting-started, build, board-support, SD layout, PSRAM loader, compatibility, P2 API, smart-pin, cog, task, PASM, debugging, testing, hardware-test, performance, and limitations docs all exist and are guarded by `make p2-docs-audit`; ongoing freshness remains tracked by the separate architecture/source-research/coverage/roadmap items.
- [x] Applied the one-focused-attempt rule to the synchronous-serial source-wrapper promotion path. The TODO now says to make only one bounded source-wrapper promotion attempt and, if it still times out or wedges the image, stop spending routine first-four-priority time there and keep the native sync diagnostic plus fast `examples/sync_serial_loopback.be` as the useful supported path. The existing bounded native sync diagnostic was re-run with sibling Catalina through `make p2-smoke-smartpins-sync-diag PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina P2_SMARTPINS_TIMEOUT=180 P2_SMARTPINS_STARTUP_TIMEOUT=60`, reaching `P2_SMOKE_SYNC_CLOCKED 1 1 true`, three matched phase observations, `P2_SMOKE_SYNC_VARIANTS_MATCHED 3`, `P2_SMOKE_PASS smartpins_sync_diag`, and `[p2-smoke] PASS smartpins-sync-diag iterations=1`.
- [x] Split the Priority 2 soak tracker item so implemented soak plumbing is no longer counted as missing work. The existing `make soak-p2` duration runner, default `soak` suite, focused `soak-smartpins-focused` suite, broader `soak-smartpins` suite, conservative timeout variables, and one-iteration hardware evidence are now marked complete; the remaining open item is specifically longer-duration leak/failure reporting for release evidence.
- [x] Closed the remaining stale Priority 2 high-level wrapper TODOs for the implemented surface. `p2smart.SyncSerialPair` / `sync_serial_pair(...)` is now counted as implemented because it has bounded host coverage, verified clocked jumper diagnostics, native focused hardware smoke coverage, and user-facing `sync_serial_loopback` / compatibility `spi_loopback` examples; the broad source-wrapper phase-variant sweep stays explicitly deferred under the one-focused-attempt rule instead of blocking the wrapper. The wrapper-wide tests/examples TODO is also closed for implemented wrappers because focused hardware targets and examples now cover GPIO, PWM/Pulse/Transition, ADC, DAC, timer/counter/NCO, quadrature, async UART, and sync serial; calibrated analog/timer behavior, mechanical quadrature, true async FIFO, USB, and broad source-wrapper sync sweeps remain tracked under their specific unsupported/deferred items.
- [x] Removed the old bit-31 smart-pin constant gap. Native `p2.smart` and the `p2smart` source fallback now expose `invert_a == -2147483648` for Catalina `P_INVERT_A`, and the raw smart-pin mode helpers accept signed 32-bit mode bit patterns so that selector can be passed through to `_wrpin()` / `_pinstart()` while X/Y arguments still reject negative values. Focused coverage was added to host `p2smart` checks and the grouped P2 API smoke; docs now explain the signed representation instead of saying `P_INVERT_A` is absent.
- [x] Closed the smart-pin constant inventory item against the sibling Catalina install and made it repeatable. `make p2-smartpin-constants-audit TOOLCHAIN=catalina CATALINA_DIR=../Catalina` compares `../Catalina/include/smartpin.h` to `p2_smart_constants`; it found 114 Catalina `P_` smart-pin macros and 114 Berry `p2.smart` constants, with zero missing and zero extra names after the `invert_a` fix. The guard is part of `p2-baseline-guards`, and the TODO/user docs now say the constant list is complete for the current Catalina header and that future Priority 2 smart-pin time should go to behavior, calibration, or explicit unsupported boundaries unless Catalina changes.
- [x] Tightened the focused `.bec` ABI smoke wording so it no longer reads like compiled module execution succeeded when the expected result is source fallback. `tests/p2/fixtures/becload.be` now reports `origin == "source-fallback-fixture"`, and `/tests/p2/smoke_bec_load_min.be` asserts that value after proving the host-generated `.bec` is rejected as `incompatible_bytecode_vm` and `libstore.resolve("becload")` selects `/berry/lib/becload.be`.
- [x] Closed the stale Priority 2 board/build compatibility item and guarded the make-time failure path. Unsupported `P2_PROFILE` and `P2_BOARD` values fail at make time, unsupported compiled profile IDs fail through the P2 config header, and `make p2-profile-invariants-selftest TOOLCHAIN=catalina CATALINA_DIR=../Catalina` now checks both valid Edge32/XMM profile invariants and invalid profile/board rejection. The runtime `p2compat.board_profile_policy()` / `board_pin_policy(pin)` surface reports the active board/profile contract, sibling Catalina path, reserved PSRAM/SD/serial pin ranges, invalid pin types/ranges, and `raise_loud_or_report_unsupported` policy with host and focused p2compat smoke coverage. Broader per-API integer/range validation remains tracked separately.
- [x] Extended the grouped low-level P2 API smoke with safe raw smart-pin negative coverage. `/tests/p2/smoke_p2_api.be` now checks invalid raw smart-pin ranges for `wrpin`, `wxpin`, `rdpin`, `rqpin`, and `clear`, plus negative X/Y argument rejection for `wxpin`, `wypin`, and `start`, while avoiding raw smart-pin reserved-pin mutation because the earlier direct reserved-pin probe hung on this image.
- [x] Added queryable child-VM heap partition sizing metadata without overclaiming production tuning. `p2compat.child_vm_partition_policy()` now exposes `p2.heap_info()` `vm_partition_*` values as runtime-derived sizing diagnostics, reports `production_count_selected == false`, and carries the explicit retry rule `stop_routine_priority_work_until_native_partition_allocator_changes` so routine Priority 1-4 effort moves elsewhere unless the native partition allocator or isolated child-VM cog runtime is actually being changed. Host/source coverage, import-all-libs coverage, the focused p2compat source smoke, and the compact `P2_COMPAT_VM_PARTITION_POLICY` direct serial probe pin the policy fields and audit keys.
- [x] Refreshed the current-state tracking docs after the p2compat partition-policy work. `docs/architecture-current.md` now reflects the expanded baseline guard bundle, implemented grouped low-level APIs, the implemented high-level `p2smart` wrapper surface plus unsupported/calibrated boundaries, the `p2compat` board/profile and child-VM partition policy role, and the focused-smoke stance for first-four work. `docs/source-research.md` now records the child-VM/cog-runtime lesson that primitive-copy transfer and `vm_partition_*` diagnostics do not prove live closure transfer or isolated VM-cog runtime safety. `docs/roadmap.md` now records the same partition-diagnostics boundary in the multicog phase.
- [x] Added queryable `p2mem.memory_pressure_policy()` diagnostics for the low-memory/high-water/PSRAM tracking item. The policy reports current heap, PSRAM, native-cache, and source-cache accounting, names the bounded import-churn anchor, states that heap high-water tracking is not instrumented yet, and carries the retry rule to stop routine first-four-priority work unless native high-water instrumentation or allocator/cache behavior is being changed. Focused host coverage pins the fields. A single focused hardware attempt uploaded `libstore.be` and `p2mem.be`, reached the REPL, then timed out on source-loading `p2mem`, so the TODO now explicitly redirects routine effort away from this source-load policy path.
- [x] Added and hardware-verified a focused CORDIC math timing hook. `tests/p2/smoke_math_perf_min.be` measures a bounded empty loop, CORDIC-backed `math.sin`/`math.cos` loop, and software-fallback `math.sqrt` loop using `p2.clock.cnt()`, while asserting `math.accel_info()["backend"] == "p2_cordic"` and `sqrt == false`. `make p2-smoke-math-perf-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` stages only `/tests/p2/mathperf.be` and passed on image `1165888`, reporting `P2_MATH_PERF_MIN p2_cordic 64 5943592 60154344 34037192`.
- [x] Added a queryable `p2.debug` capability boundary. Native `p2.debug.capabilities()` and `p2.debug.capability(name)` report the backed snapshot/heap/GC/cog/memory/pin/smart-pin/register probes and explicitly mark breakpoints, trace controls, source stack traces, native error detail, module-cache internals, task/lock/channel internals, and PASM single-step as unsupported. The sibling-Catalina XMM image builds and flashed as `1168384` bytes, and direct `/dev/ttyUSB0` probes verified supported capabilities, unsupported capabilities, the policy string, and missing-name `nil` behavior. `scripts/p2/repl_smoke.py --suite debug-capabilities-min` plus `make p2-smoke-debug-capabilities-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` now provide the repeatable focused smoke path, while the larger grouped API source smoke is documented as non-routine after its focused retry stalled at `run_file()`.
- [x] Updated the user-facing `examples/debug_report.be` path to print the new native debug capability boundary. The example still avoids `p2mem` and large source imports, but now shows supported snapshot/heap/register probes, unsupported breakpoint/trace controls, and the debug policy string alongside filesystem and PSRAM runtime fields.
