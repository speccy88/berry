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
- [x] Verified native macOS Catalina/lcc at `/Users/fred/Documents/Code/catalina-speccy88`.
- [x] Verified Catalina remains the working toolchain path for this P2 work.

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
- [x] Extended the `xmm-vm-probe` serial suite to verify the VM-boundary copy/reject table for primitive values and live objects.
- [x] Added remaining child-partition capacity diagnostics to `p2.heap_info()`: `vm_partition_free_capacity` and `vm_partition_free_remainder`, derived from current parent main-heap free space after any child partitions have already been reserved.
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

## P1 source-level Berry compatibility smoke additions

- [x] Added source-level `tests/p2/smoke_map_keys.be` coverage for equivalent fresh custom-hash key replacement, including the forced hash-collision bucket case. This is not hardware-verified yet.

## Closure-cog p38/p39 blinker proof

- [x] Hardware-verified the p38/p39 `p2.cog.spawn(blinker, pin, rate_ms)` proof on `/dev/cu.usbserial-P97cvdxp` with the no-PSRAM P2 Edge RAM image: build `Jun 08 2026 04:56:47`, image `524064 / 524288` bytes, handles `100` and `101`, native pins `38` and `39`, periods `250` and `700` ms, both cogs running with `native_blink == true`, `stack_bytes == 2048`, and final `p2.cog.info()` returning `[]` after `p2.cog.stop(h38)` and `p2.cog.stop(h39)`.
- [x] Compiled the unsafe shared-VM closure dispatcher out of the default P2 firmware behind `BE_P2_ENABLE_UNSAFE_SHARED_VM_COG`, preserving the p38/p39 native blinker closure-spawn path and improving the no-PSRAM P2 Edge RAM image from `524224 / 524288` bytes to `522336 / 524288` bytes.
- [x] Updated `/tests/p2/smoke_cog_closure.be` to cover the default closure-cog contract: two p38/p39 `native_blink` handles with `model == "native_blink"`, `repl_idle_only == false`, `stack_bytes == 2048`, successful stop cleanup, and loud rejection of unsupported closure shapes.
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

## P1 compatibility test coverage

- [x] Added `/tests/p2/smoke_compat.be` to `/tests/p2/smoke_all.be` so the full SD smoke chain now exercises the P1 Berry compatibility checks instead of leaving them as a standalone file.
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

## P1 SD import layout progress

- [x] Added optional `/berry/main.be` startup support in the P2 runtime: after VM creation, the firmware attempts to load and run `/berry/main.be` once, treats missing file as normal, warns and falls through to the REPL on script failure, and preserves the existing `os.exit()` exit path.
- [x] Added `/BERRY/LIB` and `/BERRY/APP` to the P2 VM startup module path after the existing `/MODULES` root, preserving the known-good `/modules` layout while staging the requested `/berry/...` source layout.
- [x] Updated `modules/libstore.be` so its diagnostic/cache source path list mirrors the runtime source roots: `/modules`, `/berry/lib`, and `/berry/app`.
- [x] Added `/tests/p2/smoke_import_layout.be`, which creates tiny source modules under `/berry/lib` and `/berry/app`, checks `libstore.source_path(...)`, imports both modules through the normal lazy import path, and removes the temporary source files afterward.
- [x] Added `/tests/p2/smoke_import_alias.be` and wired it into `/tests/p2/smoke_all.be`; it checks `import name as alias` for native and SD-loaded modules including `string`, `json`, `math`, `libstore`, and `p2compat`. Hardware execution remains open in `TODO.md`.
- [x] Added `/tests/p2/smoke_import_cwd.be` and wired it into `/tests/p2/smoke_all.be`; it creates a tiny source module in the active SD working directory, imports it by name to preserve current-directory import coverage, restores the previous directory, and removes the temporary source file and working directory. Hardware execution remains open in `TODO.md`.
- [x] Tightened `/tests/p2/smoke_import_cwd.be` so it removes `/berry/app/p1cwd` only when the smoke created that temporary directory, preserving any pre-existing SD directory. Hardware execution remains open in `TODO.md`.
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
- [x] Hardened the native Catalina wrapper so assembler lines like `139748: ERROR:` fail the build instead of being treated as success.
- [x] `make p2-edge32 TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88 PORT=/dev/cu.usbserial-P97cvdxp` now builds without Catalina `ERROR:` lines; current image is `506080 / 524288` bytes.
- [x] `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88 PORT=/dev/cu.usbserial-P97cvdxp` flashes the standalone XMM/huge-heap image; `p2.status()` reports `15728640 B` main heap, `15193848 B` current free, and `Berry heap in PSRAM`.

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
- [x] Removed the Catalina Docker build path from the Berry P2 build system. `mk/p2.mk` now invokes native Catalina directly, exports `LCCDIR=$(CATALINA_DIR)`, and the flash/XMM helper scripts require native Catalina tools instead of falling back to Docker.

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

## P1 source-only smoke preservation hardening

- [x] Tightened `/tests/p2/smoke_configstore.be` so its missing-config negative remove check first asserts the temporary config name is absent before calling `configstore.remove()`. This keeps the P1 configstore smoke aligned with the P0 rule that smoke tests must not pre-delete possible user/card content. Hardware execution remains pending in `TODO.md`.

## P1 dedicated introspect smoke coverage

- [x] Added `/tests/p2/smoke_introspect.be` and wired it into `/tests/p2/smoke_all.be` so the native `introspect` module has dedicated P2 source-level coverage for module/class/instance member lookup and mutation, method classification, pointer conversion and same-VM round-trip behavior, `solidified()`, `members()` edge cases, fallback reads, and missing-module handling. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated global smoke coverage

- [x] Added `/tests/p2/smoke_global.be` and wired it into `/tests/p2/smoke_all.be` so the native `global` module has dedicated P2 source-level coverage for contains/listing/member lookup, compile visibility of created globals, mutation, list-valued globals, non-string edge cases, and cleanup-oriented undef/redefine behavior. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated strict smoke coverage

- [x] Added `/tests/p2/smoke_strict.be` and wired it into `/tests/p2/smoke_all.be` after the existing `smoke_stdlib.be` strict activation point. The smoke covers native `strict` compiler-mode activation, expression-without-side-effect rejection, missing-global rejection, accepted side-effect expressions, known-global compile visibility, and cleanup after `global.undef()`. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_strict.be` with strict compiler-mode coverage for known and missing global lookups inside compiled function bodies, preserving cleanup through `global.undef()`. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_string.be` with native `string` module API-shape coverage for the main exported helpers: `find`, `count`, `split`, `escape`, `tr`, `replace`, `format`, `startswith`, and `endswith`. Hardware execution remains open in `TODO.md`.

## P1 dedicated time smoke coverage

- [x] Added `/tests/p2/smoke_time.be` and wired it into `/tests/p2/smoke_all.be` before the later strict-mode checks. The smoke covers native `time.clock()`, deterministic `time.dump()` map shape and fixed epochs, invalid dump inputs, and `time.time()` / `time.dump(time.time())` consistency without assuming a real RTC date. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_time.be` with native `time.dump()` edge coverage for integer field types and returned-map mutation isolation across repeated deterministic epoch dumps. Hardware execution remains open in `TODO.md`.

## P1 dedicated JSON smoke coverage

- [x] Added `/tests/p2/smoke_json.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers native `json` scalar and exponent parsing, escape and Unicode decoding, malformed input rejection, nested object/list parsing, formatted dumps, map subclass dumps, and round trips. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_json.be` with native `json` module API-shape coverage for callable `load` and `dump` exports before the parser/dumper behavior assertions. Hardware execution remains open in `TODO.md`.

## P1 dedicated string smoke coverage

- [x] Added `/tests/p2/smoke_string.be` and wired it into `/tests/p2/smoke_all.be` before JSON/time users. The smoke covers native `string` find/count/split, escape/translate/replace, format conversions, range indexing, prefix/suffix helpers, and string multiplication. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated bytes smoke coverage

- [x] Added `/tests/p2/smoke_bytes.be` and wired it into `/tests/p2/smoke_all.be` near the core compatibility smokes. The smoke covers builtin `bytes` construction, add/get endianness, resize/clear, equality/concat/append, appendhex, indexing/ranges, mutation/index errors, copy isolation, string conversion, and hex conversion. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_bytes.be` with builtin `bytes` method API-shape coverage for callable `add`, `get`, `resize`, `clear`, `append`, `appendhex`, `copy`, `asstring`, `fromstring`, and `tohex`. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_range.be` with builtin `range.setrange()` coverage for retargeting an existing range to a descending negative-increment sequence while preserving lower/upper/increment accessors. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_list_core.be` with builtin `list` method API-shape coverage for callable `iter`, `copy`, `insert`, `remove`, `reverse`, `push`, `pop`, `find`, `keys`, and `concat`. Hardware execution remains open in `TODO.md`.
- [x] Extended `/tests/p2/smoke_map_core.be` with builtin `map` method API-shape coverage for callable `find`, `contains`, `remove`, `insert`, `iter`, and `size`. Hardware execution remains open in `TODO.md`.

## P1 dedicated collection smoke coverage

- [x] Added `/tests/p2/smoke_collections.be` and wired it into `/tests/p2/smoke_all.be` near the core compatibility smokes. The smoke covers builtin list indexing/slicing/iteration/mutation/copy/concat/find/clear, map lookup/insert/remove/keys/values and selected key errors, plus range iteration, accessors, `setrange()`, string forms, and selected value errors. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated call smoke coverage

- [x] Added `/tests/p2/smoke_call.be` and wired it into `/tests/p2/smoke_all.be` near the core compatibility smokes. The smoke covers builtin `call()` behavior for fixed-argument functions, varargs functions, varargs-only functions, terminal list expansion, non-terminal list preservation, native function calls, moderate argument-list expansion, and class constructor calls. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_call.be` with builtin `call()` coverage for captured closures, including direct arguments and terminal-list expansion while preserving closure state. Hardware execution remains open in `TODO.md`.

## P1 dedicated conversion/type smoke coverage

- [x] Added `/tests/p2/smoke_conversions.be` and wired it into `/tests/p2/smoke_all.be` near the core compatibility smokes. The smoke covers core conversion/type behavior for `str`, `number`, `int`, `real`, `bool`, `type`, `size`, custom conversion hooks, `classname`, `classof`, `super`, `issubclass`, and `isinstance`. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_conversions.be` with invalid `int()` / `real()` conversion fallback coverage for non-numeric strings and `nil`, matching the existing `number()` negative-path behavior. Hardware execution remains open in `TODO.md`.

## P1 dedicated compile/module/assert smoke coverage

- [x] Added `/tests/p2/smoke_compile_module.be` and wired it into `/tests/p2/smoke_all.be` near the core compatibility smokes. The smoke covers core `assert`, `compile`, and `module` behavior: assert pass/fail exceptions, compile success/failure, compiled global lookup, module member mutation, and introspect-assisted module metadata. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_compile_module.be` with `compile()` coverage for returning a captured closure from compiled source and invoking it after the compiled entry function returns. Hardware execution remains open in `TODO.md`.

## P1 dedicated solidify smoke coverage

- [x] Added `/tests/p2/smoke_solidify.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers native `solidify` API shape, no-argument behavior, invalid-type errors, compacting a tiny class without noisy generated dump output, and optional `nocompact()` behavior when that helper is present. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_solidify.be` with compact inherited-class coverage so a compacted child class still resolves `super()` method behavior plus static member/method access. Hardware execution remains open in `TODO.md`.

## P1 dedicated virtual member smoke coverage

- [x] Added `/tests/p2/smoke_virtual_members.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers the native `undefined` sentinel, class-level virtual `member()` dispatch for dynamic methods and fields, undefined-triggered attribute errors, module-level virtual `member()` dispatch, nil fallback behavior, and `introspect.get(..., true)` returning the `undefined` sentinel for missing members. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated module-system smoke coverage

- [x] Added `/tests/p2/smoke_module_system.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers `module()` creation with and without names, module member mutation and functions, `sys.path()` shape, cached module injection via `introspect.setmodule()`, and a native `string` module monkey-patch/restore path that delegates missing members back to the original module. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated super/inheritance smoke coverage

- [x] Added `/tests/p2/smoke_super.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers multi-level constructor chaining through `super(self).init(...)`, instance and class `super()` traversal, leveled `super(obj, Class)` selection, inherited default `init()` behavior when a parent lacks one, and parent-chain method dispatch where a parent implementation calls back into the concrete child method. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated subobject smoke coverage

- [x] Added `/tests/p2/smoke_subobject.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style builtin subclass behavior for `classof([])`, list class/instance `issubclass()` and `isinstance()` distinctions, and a compact `map` subclass with inherited initialization and index mutation. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated static class smoke coverage

- [x] Added `/tests/p2/smoke_static_classes.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers richer upstream static class behavior: mixed static initializer values, instance access to static members, subclass static overrides, `_class` in static initializer and static method contexts, and nested static classes with static and instance methods. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated conditional-expression smoke coverage

- [x] Added `/tests/p2/smoke_cond_expr.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers Berry conditional expressions for truthy and falsey selection, nesting, use inside `if` conditions, map lookups with fallback branches, loop-generated values, and branch laziness by raising from the unselected branch if it executes. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated compound-assignment smoke coverage

- [x] Added `/tests/p2/smoke_compound.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers scalar arithmetic compound assignments, member compound updates inside methods, direct instance-member compound updates, list index compound updates, computed map-key compound updates, and bitwise/shift compound operators. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated suffix-expression smoke coverage

- [x] Added `/tests/p2/smoke_suffix.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style suffix behavior for dynamic map keys, string concatenation with numeric conversion through `..`, list append expressions, nested list appends, and member slice/index regression cases. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated boolean smoke coverage

- [x] Added `/tests/p2/smoke_bool.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style boolean comparisons, double-negation, `&&`/`||` behavior, short-circuit laziness, unary-not input preservation, `bool()` conversion for scalar and collection values, and the local-value preservation pattern from the upstream boolean regression. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_bool.be` with boolean operator coverage for truthy non-bool operands and falsey collection operands, while preserving short-circuit laziness. Hardware execution remains open in `TODO.md`.

## P1 dedicated relational/equality smoke coverage

- [x] Added `/tests/p2/smoke_relop.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style relational and equality behavior for ints, reals, nil/bool distinctions, builtin class identity, list equality including nested lists, list-vs-nil behavior, and map equality. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_relop.be` with bytes value equality/inequality coverage and bytes-vs-nil distinctions. Hardware execution remains open in `TODO.md`.

## P1 dedicated assignment smoke coverage

- [x] Added `/tests/p2/smoke_assignment.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style continuous suffix assignment for direct instance members, nested instance members, local nested members inside a function, and map-selected object member chains with compound updates. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated reference/cycle smoke coverage

- [x] Added `/tests/p2/smoke_reference.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style cyclic list stringification with `[...]`, nested cyclic rendering, custom `tostring()` participation in list rendering, exception propagation from `tostring()`, and recovery of cyclic rendering after the exception path. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated integer numeric smoke coverage

- [x] Added `/tests/p2/smoke_int_numeric.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style custom `toint()` conversion, hexadecimal string parsing including a large literal, bitwise AND/OR/XOR with variables and literals, and bitwise NOT. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated lexer smoke coverage

- [x] Added `/tests/p2/smoke_lexer.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style lexer behavior for hex and octal string escapes, standard escaped characters, numeric literal forms, Unicode escape encoding through bytes conversion, and malformed literal/token syntax errors. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated map key smoke coverage

- [x] Added `/tests/p2/smoke_map_keys.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style map keys for real numbers, instances with custom `hash()` and `==`, instances without `hash()` using identity behavior, and the `runtime_error` path when an instance `hash()` method returns a non-integer. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated division-by-zero smoke coverage

- [x] Added `/tests/p2/smoke_divzero.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style integer and real division/modulo-by-zero exceptions with `divzero_error` and `division by zero`, plus normal integer and real division/modulo operations. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_divzero.be` with computed-denominator zero coverage so runtime expression evaluation paths raise the same `divzero_error` as literal zero denominators. Hardware execution remains open in `TODO.md`.

## P1 dedicated class constant/static-member smoke coverage

- [x] Added `/tests/p2/smoke_class_const.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style static member defaults, class-member attribute errors, instance access to static members, dynamic function values stored in instance and static members, static method/static function fields, GC survival for static string/real members, and subclass static overrides that reference parent classes. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated bytes base64/fixed-size smoke coverage

- [x] Added `/tests/p2/smoke_bytes_b64_fixed.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style `bytes.tob64()`, `bytes.fromb64()`, fixed-size `bytes(-n)` initialization, fixed-size hex/base64 initialization, fixed-size get/set/index mutation, unchanged-size resize, fixed-size mutation rejection paths, and fixed-size concatenation. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`. Mapped-pointer bytes remain a separate XMM-aware compatibility item.

## P1 dedicated advanced JSON smoke coverage

- [x] Added `/tests/p2/smoke_json_advanced.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style uppercase exponent parsing, slash/backspace/formfeed escapes, Unicode expansion sizing, invalid Unicode escape rejection, unescaped control-character rejection, valid escaped control characters, invalid escape rejection, moderate long strings, mixed ASCII/Unicode text, nested Unicode objects, and malformed string/object rejection. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated for-loop smoke coverage

- [x] Added `/tests/p2/smoke_for_loop.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style range `for` summation, loop `break`, loop `continue`, return from inside a loop, and a compact recursive `for` recurrence that exercises repeated `stop_iteration` handling. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated closure/upvalue smoke coverage

- [x] Added `/tests/p2/smoke_closure.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers independent factory closures, captured upvalue mutation, post-creation outer mutation visibility, loop-variable plus local capture, returned-closure arguments, and the upstream closure-compilation shape with a captured numeric update. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated range smoke coverage

- [x] Added `/tests/p2/smoke_range.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style literal ranges, positive and negative `range()` increments, same-bound descending ranges, large increments, range accessors, string forms, positive and custom-increment `setrange()` reconfiguration, post-`setrange()` iteration, and selected `value_error` paths. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated vararg smoke coverage

- [x] Added `/tests/p2/smoke_vararg.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style direct varargs with required and varargs-only functions, nil-preserving vararg lists, returned closure varargs, and method varargs that preserve `self` plus required and rest arguments. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_vararg.be` with vararg-list mutation isolation coverage: mutating one returned rest-list does not alter closure-captured state or later vararg calls. Hardware execution remains open in `TODO.md`.

## P1 dedicated compiler/parser regression smoke coverage

- [x] Added `/tests/p2/smoke_compiler_parser.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style compiler/parser regression shapes for member-index access through `self`, negative index register ordering, string slicing followed by a `for` loop, ternary assignment parsing, nested map access followed by loop return, and boolean short-circuit parser compilation. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_compiler_parser.be` with call-argument ternary expressions that contain chained list suffixes, covering another compact parser/register-ordering edge without touching runtime hardware paths. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 static declaration method-visible field coverage

- [x] Extended `/tests/p2/smoke_static_decls.be` with an instance method that updates a grouped static field through the class and reads it through instance fallback, covering static field visibility inside method bodies. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 inherited static class member readback coverage

- [x] Extended `/tests/p2/smoke_class_const.be` with inherited static readback through both a subclass and subclass instance, including parent-side mutation after instance creation. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 subclass-from-module inherited static fallback coverage

- [x] Extended `/tests/p2/smoke_static_super_member.be` with a subclass static override observed through an inherited base method, covering instance fallback to the dynamic subclass static field while preserving the base-class value on base instances. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 class iterator closure isolation coverage

- [x] Extended `/tests/p2/smoke_classes.be` with two independent iterator closures returned from the same class instance, confirming their captured iteration state does not alias and `stop_iteration` remains scoped to the exhausted iterator. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 indirect static member write coverage

- [x] Extended `/tests/p2/smoke_member_indirect.be` with computed-name indirect assignment to a class static field and direct/indirect readback. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 builtin subclass method/storage coverage

- [x] Extended `/tests/p2/smoke_subobject.be` with user-defined methods on list and map subclasses that mutate their inherited builtin storage, then verify list indexing and map key lookup read the updated values. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 map hash-collision instance-key coverage

- [x] Extended `/tests/p2/smoke_map_keys.be` with distinct instance keys that intentionally share the same integer hash, verifying equality still separates entries and `contains()` rejects a same-hash missing key. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 virtual member real-member precedence coverage

- [x] Extended `/tests/p2/smoke_virtual_members.be` so class and module `member()` hooks return alternate values for real member names, while direct reads/calls still use the real field or method. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 virtual setmember computed-name write coverage

- [x] Extended `/tests/p2/smoke_virtual_setmember.be` with computed-name assignment through `setmember()` for a virtual payload, plus computed-name assignment to a real field to confirm real-member writes do not get routed into the virtual assignment map. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 external super-proxy method call coverage

- [x] Extended `/tests/p2/smoke_super.be` with direct method calls through `super(c)` and `super(super(c))`, confirming external super proxies dispatch to the expected parent methods while preserving inherited route behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 integer conversion and shift precedence coverage

- [x] Extended `/tests/p2/smoke_int_numeric.be` with negative `toint()` conversion and compact left/right shift assertions, including parenthesized bitwise/shift precedence combinations. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 lexer hex escape boundary coverage

- [x] Extended `/tests/p2/smoke_lexer.be` with uppercase hex escape and NUL byte escape readback, plus incomplete `\x` escape syntax-error cases. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 conditional-expression collection truthiness coverage

- [x] Extended `/tests/p2/smoke_cond_expr.be` with empty/non-empty list and map operands in conditional expressions, covering Berry collection truthiness in ternary selection. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 computed-member compound assignment coverage

- [x] Extended `/tests/p2/smoke_compound.be` with compound assignment through a computed member name, verifying direct and indirect readback agree after the update. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 computed nested assignment coverage

- [x] Extended `/tests/p2/smoke_assignment.be` with nested assignment and compound update through computed member names, verifying direct and indirect readback match. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 suffix method-chain indexing coverage

- [x] Extended `/tests/p2/smoke_suffix.be` with method-call suffix chaining that returns an object/list and immediately indexes the returned list, covering another compact suffix parser/runtime shape. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 cyclic map reference stringification coverage

- [x] Extended `/tests/p2/smoke_reference.be` with cyclic map rendering and post-exception recovery readback, covering map self-reference formatting alongside the existing cyclic list recovery path. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 walrus sequential value-expression coverage

- [x] Extended `/tests/p2/smoke_walrus_edges.be` with sequential assignment expressions inside a list literal, verifying left-to-right value production and readback from the assigned local. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 f-string indexed expression formatting coverage

- [x] Extended `/tests/p2/smoke_syntax.be` with f-string expressions that read list/map suffixes, including integer formatting from an indexed arithmetic expression. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 map nil-value presence coverage

- [x] Extended `/tests/p2/smoke_map_core.be` with a present key whose value is `nil`, confirming `contains()` distinguishes presence while `find(key, default)` still returns the stored `nil` instead of the default. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 collection map values coverage

- [x] Extended `/tests/p2/smoke_collections.be` with order-independent `map.values()` assertions, matching the existing collection coverage goal for map keys and values. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 list index-list ordering coverage

- [x] Extended `/tests/p2/smoke_list_core.be` with duplicate/reordered list-of-indices selection, confirming selection preserves requested order and duplicate indexes. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 compile-to-module mutation coverage

- [x] Extended `/tests/p2/smoke_compile_module.be` with compiled source that mutates a module member through a global module reference, then verifies the module state is visible to normal and introspect reads. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 inherited introspect.ismethod coverage

- [x] Extended `/tests/p2/smoke_introspect_ismethod.be` with inherited method and inherited static-method checks through both subclass and subclass instance lookup. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 binary operator-overload instance result coverage

- [x] Extended `/tests/p2/smoke_operator_overload.be` with a binary `+` overload between two instances that returns a new instance, then verifies the resulting instance payload. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 module member real-attribute precedence coverage

- [x] Extended `/tests/p2/smoke_module_attrs.be` so a module with a virtual `member()` hook also has a real field with the same name, confirming real module attributes take precedence while other names still use dynamic dispatch. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 injected module import identity coverage

- [x] Extended `/tests/p2/smoke_module_system.be` with repeated import of an injected module after mutation through the imported alias, confirming repeated imports keep the same live module object and state. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 custom conversion edge-value coverage

- [x] Extended `/tests/p2/smoke_conversions.be` with custom conversion hooks returning an empty string, a negative integer, and a negative real value, covering edge values through `str()`, `int()`, and `real()`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 range iterator isolation coverage

- [x] Extended `/tests/p2/smoke_range.be` with two independent iterators from the same range object, confirming iterator state does not alias and the range remains reusable for later `for` expansion. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 VM full-span negative slicing coverage

- [x] Extended `/tests/p2/smoke_vm_ops.be` with full-span negative-index string and list slices, covering boundary normalization for `[-len..-1]` style slices. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 VM shift-operator error coverage

- [x] Extended `/tests/p2/smoke_vm_error_paths.be` with invalid shift operand cases for `<<` and `>>`, covering shift-operator `type_error` paths alongside the existing arithmetic error coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 call bound-method dispatch coverage

- [x] Extended `/tests/p2/smoke_call.be` with `call()` on a bound instance method, including direct arguments and list-expanded arguments. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 broad compat map values coverage

- [x] Extended `/tests/p2/smoke_compat.be` with compact `map.values()` readback, ensuring the top-level core compat smoke samples map values as well as keys. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 closure parameter/local capture coverage

- [x] Extended `/tests/p2/smoke_function_capture.be` with a returned closure that captures both an outer function parameter and an inner local, then combines them with a call argument. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 escaped vararg rest-list capture coverage

- [x] Extended `/tests/p2/smoke_vararg.be` with a returned closure that captures the vararg rest list and reads it back later, covering escaped vararg storage separately from immediate return. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 nested closure upvalue-chain coverage

- [x] Extended `/tests/p2/smoke_closure.be` with a nested returned closure that captures and mutates values from two enclosing scopes, covering chained upvalue state across repeated calls. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 nested for-loop control-flow isolation coverage

- [x] Extended `/tests/p2/smoke_for_loop.be` with nested loops that use inner `continue` and `break`, confirming inner-loop control flow does not leak into the outer loop. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 map equality order/nil coverage

- [x] Extended `/tests/p2/smoke_relop.be` with order-independent map equality and nil-valued map equality/distinction checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 safe API map copy isolation coverage

- [x] Extended `/tests/p2/smoke_be_api_edges.be` with map `copy()` mutation-isolation coverage, mirroring the existing list copy isolation probe through safe Berry-level behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated assert-failure exception smoke coverage

- [x] Added `/tests/p2/smoke_exception_assert.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style `assert_failed` exception capture for an assertion failure raised inside a `for` loop, including preservation of the custom assertion message. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_exception_assert.be` with a passing assert guard plus function-call and closure-call assert propagation coverage, confirming a custom `assert_failed` message survives across call and closure frames. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated plain map smoke coverage

- [x] Added `/tests/p2/smoke_map_core.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style plain map access/find/contains behavior, missing-key removal preserving a map, boolean keys, `key_error` lookup, insert true/false semantics, comma-bearing map stringification, `map.iter()` value iteration, and bulk insert/remove behavior that exercises collision-chain cleanup. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated list core smoke coverage

- [x] Added `/tests/p2/smoke_list_core.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style list stringification, iterator order, negative-index insert/remove/reverse behavior, `..` append expression behavior, pop variants, `find()` edge cases including nested lists and nil, `keys()` for populated/nil/empty lists, rich `concat()` delimiter behavior, negative-index compound assignment, list-of-indices selection, and out-of-range list-index selection returning `nil`. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated operator-overload smoke coverage

- [x] Added `/tests/p2/smoke_operator_overload.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style class operator overload behavior for callable instances through `def ()()` and the no-argument `def +()` overload shape used by the upstream regression test. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated string format/edge smoke coverage

- [x] Added `/tests/p2/smoke_string_format_extra.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style string format conversion edges for custom `toint()`, empty conversions for unsupported numeric formatting, `%c`, `%q`, adjacent string literal concatenation with comments, larger short/long string multiplication boundaries, invalid string multiplication type errors, and multiplication inside expressions. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated module attribute smoke coverage

- [x] Added `/tests/p2/smoke_module_attrs.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style module `member()` dynamic attribute dispatch, `member()` returning `undefined` as an `attribute_error`, missing attributes on modules without `member()`, and `introspect.module("string")` returning the native module object. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated indirect-member smoke coverage

- [x] Added `/tests/p2/smoke_member_indirect.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style indirect member syntax for module writes and reads, class static reads, instance initialization through dynamic member names, indirect member writes from expressions, indirect method calls, class-valued method returns, chained indirect member reads, and chained compound updates. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated bytes extra smoke coverage

- [x] Added `/tests/p2/smoke_bytes_extra.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style bytes extra method API shape, float get/set/add behavior, `fromhex()`/`tohex()`, `setbytes()` range and truncation behavior, `reverse()` with offset/length/grouping arguments, bytes truthiness and `tobool()`, three-byte little/big-endian `get()`, `appendb64()` with offsets, three-byte `add()`, and selected `type_error` paths for `set()`, `add()`, and `addfloat()`. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`. Mapped-pointer bytes remain a separate XMM-aware compatibility item.
- [x] Extended `/tests/p2/smoke_bytes_extra.be` with `fromstring()` plus `copy()` mutation-isolation coverage, confirming a copied bytes object does not alias after the original buffer is mutated. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated introspect ismethod edge smoke coverage

- [x] Added `/tests/p2/smoke_introspect_ismethod.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style `introspect.ismethod()` edge behavior for missing arguments, non-closure values, modules, native functions, plain Berry functions, instance methods, static methods, and function-valued instance members. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated virtual setmember smoke coverage

- [x] Added `/tests/p2/smoke_virtual_setmember.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style class `setmember()` behavior for virtual attribute assignment, rejected virtual assignment, map-backed virtual members, and function-valued assignments that must remain callable after passing through `setmember()`. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated VM runtime error-path smoke coverage

- [x] Added `/tests/p2/smoke_vm_error_paths.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style VM runtime error paths for unary, binary, call, concat, and string-repetition type errors, instance operator overload edges for subtraction/multiply/divide/modulo/unary operations, default instance truthiness, invalid comparison return types, instance/class attribute errors, and named-global reads/writes through `global`. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated debug module smoke coverage

- [x] Added `/tests/p2/smoke_debug.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style native `debug` module behavior for `attrdump()` no-crash class inspection and `debug.caller()` stack introspection with function names resolved through `introspect.name()`. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.
- [x] Extended `/tests/p2/smoke_debug.be` with nested wrapper coverage so `debug.caller()` must preserve a three-frame named call chain resolved through `introspect.name()`. Hardware execution remains open in `TODO.md`.

## P1 dedicated static superclass module-member smoke coverage

- [x] Added `/tests/p2/smoke_static_super_member.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers the upstream-style static-class regression where a subclass inherits from a superclass stored in a module member while defining static members on the subclass, preserving subclass checks, instance checks, inherited methods, and static member reads. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated Berry C API edge smoke coverage

- [x] Added `/tests/p2/smoke_be_api_edges.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style Berry C API edge paths through safe Berry-level probes for closure/function type checks, builtin list/map instance checks, pointer conversion, missing module-member lookup, no-op non-object member setting, list copy isolation, closure upvalue mutation, comparison operators, class inheritance, and native function type checks. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated function closure-capture smoke coverage

- [x] Added `/tests/p2/smoke_function_capture.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style escaped function closure capture where a closure is stored outside its defining function and still sees captured locals, plus independent factory closures with separate mutable captured state. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated walrus edge smoke coverage

- [x] Added `/tests/p2/smoke_walrus_edges.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style walrus regression behavior for local builtin-name shadowing, global and list-index walrus expressions returning the assigned value, member walrus assignment in conditions, and cleanup of temporary global-module state. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated static declaration-form smoke coverage

- [x] Added `/tests/p2/smoke_static_decls.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers upstream-style legacy `static name` declarations, grouped `static var` declarations, class-vs-instance static visibility, class-side attribute errors for instance fields and missing members, instance reads of static values, and function-valued static members. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated JSON generated stack/growth smoke coverage

- [x] Added `/tests/p2/smoke_json_stack.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers compact upstream-style JSON stack/growth behavior with a generated 128-key object plus a generated list of nested objects, asserting successful parse results without turning the P2 smoke into a large heap stress. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 dedicated math parity smoke coverage

- [x] Added `/tests/p2/smoke_math_parity.be` and wired it into `/tests/p2/smoke_all.be`. The smoke covers adapted upstream math semantics for `nan`/`inf` string and JSON behavior, `round` including half-boundaries around zero, `min`/`max` value/type/error behavior, no-argument fallbacks, deterministic `srand`/`rand`, and core constants while preserving the P2 module's documented invalid-domain `nil` behavior. This is source-level smoke coverage only; hardware execution remains pending in `TODO.md`.

## P1 explicit REPL input smoke harness coverage

- [x] Tightened `scripts/p2/repl_smoke.py --suite compat` so the interactive `input()` check waits for the prompt marker, sends the response text, then asserts the echoed value before returning to `berry>`. This is harness-level source coverage only; hardware execution remains pending in `TODO.md`.

## P1 additive sys.path import-root support

- [x] Added native `sys.path_add(path)` to append deliberate runtime import roots through Berry's VM module-path API without replacing or reordering the P2 startup roots. `libstore.path_add(path)` now bridges to `sys.path_add(path)` when available, `/tests/p2/smoke_sys_path_add.be` stages a tiny module under `/berry/sys_path` and imports it through the normal importer, and `p2compat` now documents additive path support while keeping removal/reordering unsupported. This is source-level support only; hardware execution remains pending in `TODO.md`.
- [x] Hardened the additive import-root path so repeated `libstore.path_add(path)` calls do not duplicate VM module roots. `/tests/p2/smoke_sys_path_add.be` now checks duplicate-safe append behavior before importing its staged probe module. This is source-level support only; hardware execution remains pending in `TODO.md`.

### P1 module coverage metadata

- Added curated per-module coverage metadata to `libstore.info()` / `libstore.inventory()` for the current SD module set: behavior smoke, SD import smoke, repeated import/cache smoke, PSRAM source-cache smoke, low-memory churn smoke, metadata smoke, status, and reason.
- Extended `/tests/p2/smoke_module_inventory.be` so every known SD module must report coverage metadata, while keeping `wifi` honestly marked as hardware-deferred rather than pretending hardware behavior is covered.
- Updated `docs/coverage-matrix.md` and `port/p2/TODO.md` to reflect the new metadata coverage while leaving hardware verification open.

### P1 `.bec` sidecar freshness metadata

- Added staged `.bec` sidecar freshness manifest support through `libstore.compiled_manifest_path()`, `libstore.compiled_manifest()`, and expanded `libstore.compiled_freshness()` metadata.
- Sidecars use `<module>.bec.json` beside the staged bytecode and can prove `fresh == true` / `comparable == true`, while still reporting `compiled_usable == false` until real `.bec` execution support is enabled.
- Extended `p2mem.module()` diagnostics and `/tests/p2/smoke_bec_fallback.be` so fresh, stale, missing-manifest, compiled-only, and source-fallback cases stay explicit.
- Updated SD layout, module, architecture, PSRAM-loader, limitations, TODO, and coverage docs to distinguish staged freshness metadata from still-open `.bec` execution and compile-to-cache emission.

### P1 math CORDIC backend metadata

- Added `math.accel_info()` to the SD-loaded P2 `math` module so the active math backend is explicit at runtime.
- The metadata reports when P2 CORDIC is used for compatible scaled trig/polar paths (`sin`, `cos`, `tan`, `atan2`, and indirect `asin`/`acos`) and keeps `sqrt`, `exp`, and `log` marked unaccelerated to avoid overclaiming unsafe or unmeasured paths.
- Extended `/tests/p2/smoke_modules.be` and `/tests/p2/smoke_math_parity.be` to assert the accelerator metadata while preserving the existing Berry finite/error semantics checks.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md` so CORDIC progress is visible but hardware timing/measurement remains open.

### P1 nested package string imports

- Added native loader filesystem normalization so dotted module names are probed as nested paths for source/bytecode files, e.g. `pkg.mod` maps to `pkg/mod.be` or `pkg/mod.bec` under the current directory and configured module roots.
- Extended `/tests/p2/smoke_package_paths.be` so the staged `/berry/app/pkg/mod.be` module loads both through `libstore.load("pkg.mod")` and through native string import syntax `import "pkg.mod" as native_pkg_mod`.
- Updated `docs/sd-layout.md`, `docs/coverage-matrix.md`, and `port/p2/TODO.md` to mark nested string imports as staged while leaving bare dotted identifier syntax such as `import pkg.mod` open unless the parser grammar is intentionally extended.

### P1 bare dotted package imports

- Extended the Berry parser import grammar to accept bare dotted module names such as `import pkg.mod` and `import pkg.mod as alias`.
- Bare dotted imports use the full dotted string as the module cache/load key and bind the final segment by default, so `import pkg.mod` stores the module in `mod` unless an explicit alias is supplied.
- Combined with the native loader nested-path mapping, dotted imports probe SD paths such as `pkg/mod.be` and `pkg/mod.bec` under the current directory and configured module roots.
- Extended `/tests/p2/smoke_package_paths.be` to cover `libstore.load("pkg.mod")`, `import "pkg.mod" as native_pkg_mod`, `import pkg.mod as dotted_pkg_mod`, and `import pkg.mod` against the same staged `/berry/app/pkg/mod.be` file.
- Updated `docs/sd-layout.md`, `docs/coverage-matrix.md`, and `port/p2/TODO.md`; hardware execution remains pending in TODO.

### P1 invalid `.bec` manifest fallback coverage

- Extended `/tests/p2/smoke_bec_fallback.be` to stage an invalid `<module>.bec.json` sidecar and assert `libstore.compiled_manifest()`, `compiled_freshness()`, `resolve()`, and `compile_cache_plan()` all report the invalid manifest explicitly.
- Confirmed the invalid-manifest case remains non-fresh, non-comparable, non-usable, and still selects the matching `.be` source fallback instead of pretending the `.bec` can execute.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md` so the `.bec` fallback item now names missing, invalid, stale, unsupported, compiled-only, and fully-missing metadata cases.

### P1 `.bec` sidecar manifest validation

- Tightened `libstore.compiled_manifest(name)` so a `.bec.json` sidecar must use format `berry-p2-bec-manifest-v1`, must not name a different module, and must include source and compiled hashes before it can be considered structurally valid.
- Extended `/tests/p2/smoke_bec_fallback.be` to cover invalid JSON, invalid format, module mismatch, missing hashes, stale hashes, and fresh-but-execution-disabled manifests while preserving `.be` source fallback.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md` so `.bec` fallback coverage now distinguishes malformed sidecars from stale-but-comparable sidecars.

### P1 comma-separated dotted package imports

- Extended `/tests/p2/smoke_package_paths.be` to stage a second nested package module and cover comma-separated dotted import syntax: `import pkg.mod, pkg.other`.
- The smoke now proves nested SD package lookup works for `libstore.load("pkg.mod")`, string-path import, bare dotted import with alias, bare dotted import with default final-segment binding, and comma-separated dotted imports.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; hardware execution remains pending in TODO.

### P1 SD file/open mode coverage

- Extended `/tests/p2/smoke_sd.be` with cleanup-oriented coverage for append mode (`a`), read/write update mode (`r+`), additional `os.path.join()` checks, and missing-path negative checks for `exists`, `isfile`, and `isdir`.
- Kept the smoke small and sequential: it stages only `/P2SMOKE.TXT`, `/P2LINES.TXT`, `/P2SMOKE2.TXT`, and `/P2DIR`, and removes the paths it creates.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md` to reflect broader file/open and `os.path` smoke coverage while leaving hardware verification open.

### P1 dotted package import cache identity

- Extended `/tests/p2/smoke_package_paths.be` to verify nested package imports reuse the same cached module object across `import "pkg.mod" as ...`, repeated string import, `import pkg.mod as ...`, default `import pkg.mod`, and comma-separated `import pkg.mod, pkg.other` forms.
- The smoke uses `introspect.toptr()` for identity checks and keeps the same tiny cleanup-oriented staged package files under `/berry/app/pkg`.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; hardware execution remains pending in TODO.

### P1 p2compat capability metadata refresh

- Added `package_import` as a supported `p2compat` capability for dotted SD imports that map to nested paths, including string, alias, bare, and comma-separated forms.
- Added `bec_manifest` as a staged `p2compat` capability for `.bec.json` sidecar format/module/hash validation used by fallback metadata, explicitly separate from disabled `.bec` execution.
- Extended `/tests/p2/smoke_p2compat.be` to assert the new capability entries and updated `port/p2/TODO.md` plus `docs/coverage-matrix.md`.

### P1 missing-import cache recovery

- Extended `/tests/p2/smoke_import_missing.be` so a failed import is followed by staging the same module under `/berry/app` and importing it successfully.
- This proves missing imports fail catchably without creating bogus selected metadata or poisoning the module cache for a later SD source module.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; hardware execution remains pending in TODO.

### P1 `.bec` preference/blocker metadata

- Added `compiled_preferred` and `compiled_blocked_reason` to `libstore.resolve()` and `libstore.info()` so a fresh staged `.bec` candidate can be identified without enabling bytecode execution.
- Extended `/tests/p2/smoke_bec_fallback.be` to assert missing-manifest, fresh-but-execution-disabled, and stale-manifest preference/blocker metadata while keeping `.be` source selected.
- Extended `/tests/p2/smoke_module_inventory.be` to require the new metadata fields on inventory records.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; `.bec` execution remains disabled and hardware execution remains pending in TODO.

### P1 compile-cache plan blocker metadata

- Added `libstore.MANIFEST_FORMAT` and expanded `libstore.compile_cache_plan(name)` with `manifest_format`, `manifest_required`, `validator_required`, `execution_required`, and `emit_blocked_reason` fields.
- Extended `/tests/p2/smoke_bec_fallback.be` so normal, compiled-only, and missing-source cache plans assert the explicit blockers while `can_emit` remains false.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; this is planning metadata only and does not enable `.bec` emission or execution.

### P1 compile-cache plan summary in module diagnostics

- Added compile-cache plan summary fields to `libstore.info()` / `libstore.inventory()`: support flag, can-emit flag, reason, blocked reason, target `.bec` path, target manifest path, and manifest format.
- Added matching fields to `p2mem.module(name)` so diagnostics expose why `.bec` emission is currently blocked without requiring a separate planner call.
- Extended `/tests/p2/smoke_module_inventory.be` and `/tests/p2/smoke_bec_fallback.be` to assert the new metadata while keeping `.bec` emission/execution disabled.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; this is diagnostic/planning metadata only.

### P1 SD `+` file mode coverage

- Extended `/tests/p2/smoke_sd.be` with cleanup-oriented coverage for `w+` and `a+` read/write file modes using a tiny `/P2PLUS.TXT` temporary file.
- The smoke now covers documented `open()` modes `w`, `a`, `r+`, `w+`, and `a+` without expanding into broad host-like filesystem assumptions.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; hardware execution remains pending in TODO.

### P1 `.bec` manifest template planning

- Added `libstore.compiled_manifest_template(name)` to compute the sidecar manifest payload that a future `.be` to `.bec` cache writer would emit when source and staged bytecode both exist.
- Extended `libstore.compile_cache_plan(name)` with manifest-template availability, reason, and data fields while keeping `can_emit == false` and bytecode execution disabled.
- Extended `/tests/p2/smoke_bec_fallback.be` to assert manifest-template metadata for matched, compiled-only, and missing cases.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; this is planning metadata only.

### P1 manifest-template status in module diagnostics

- Added manifest-template availability and reason fields to `libstore.info()` / `libstore.inventory()` and `p2mem.module(name)` so module diagnostics can report whether future `.bec` sidecar payload generation is possible.
- Kept the full template payload in `libstore.compile_cache_plan(name)` to avoid bloating every inventory record.
- Extended `/tests/p2/smoke_module_inventory.be` and `/tests/p2/smoke_bec_fallback.be` to assert the new status fields.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; this remains planning metadata only.

### P1 `.bec` manifest text preview

- Added `libstore.compiled_manifest_text(name)` to preview the JSON sidecar payload a future `.be` to `.bec` cache writer would save when source and staged bytecode both exist.
- Extended `/tests/p2/smoke_bec_fallback.be` to parse the preview text and verify its format, module, source hash, and compiled hash; compiled-only and missing cases return `nil`.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; this is preview/planning metadata only and does not write manifests, emit `.bec`, or enable `.bec` execution.

### P1 `os.path` helper-shape coverage

- Extended `/tests/p2/smoke_sd.be` with additional `os.path` helper-shape assertions for nested paths, local relative filenames, missing extensions, and empty-directory split/dirname cases.
- Covered basename, dirname, join, split, and splitext behavior without adding new SD writes beyond the existing smoke files.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; hardware execution remains pending in TODO.

### P1 SD directory listing coverage

- Extended `/tests/p2/smoke_sd.be` so the temporary `/P2DIR` directory creates a tiny cwd-relative `INNER.TXT`, verifies `os.listdir(".")` sees it, checks relative `exists` / `isfile`, removes the file, and then removes the directory.
- Kept the SD writes small, sequential, and cleanup-oriented within the existing smoke directory footprint.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; hardware execution remains pending in TODO.

### P1 opt-in `.bec` compile-cache emission helper

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

### P1 native `sys` module coverage

### P1 module inventory mutation-isolation coverage

- [x] Extended `/tests/p2/smoke_module_inventory.be` so returned `libstore.inventory()` and `libstore.compiled_inventory()` records are mutated by the caller and then reacquired to prove fresh snapshots are not poisoned by caller-side metadata edits. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

- Added `/tests/p2/smoke_sys.be` and wired it into `/tests/p2/smoke_all.be`.
- The smoke covers `sys.path()` list shape, copy isolation for returned path lists, callable `sys.path_add`, direct native path append, importing a tiny module from the appended root, and loud errors for missing, non-string, and empty path arguments.
- Added `sys_module` as a supported `p2compat` capability and extended `/tests/p2/smoke_p2compat.be` to assert the supported metadata.
- Updated `port/p2/TODO.md` and `docs/coverage-matrix.md`; hardware execution remains pending in TODO.

### P1 module inventory mutation-isolation coverage

- [x] Extended `/tests/p2/smoke_module_inventory.be` so returned `libstore.inventory()` and `libstore.compiled_inventory()` records are mutated by the caller and then reacquired to prove fresh snapshots are not poisoned by caller-side metadata edits. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 repeated missing-import recovery coverage

- [x] Extended `/tests/p2/smoke_import_missing.be` so the same missing module can fail repeatedly without creating bogus metadata, then be staged under `/berry/app`, imported, mutated, and imported again through an alias without losing the recovered cached module state. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 native-first import shadow-root coverage

- [x] Extended `/tests/p2/smoke_import_native_first.be` so native `json` must beat fake `/berry/lib/json.be` and `/berry/app/json.be` shadows, including a repeated aliased import. The smoke now asserts both shadow paths are absent before staging and removes only the files it created, preserving the P0 SD-card write guardrail. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 full SD source-root order coverage

- [x] Extended `/tests/p2/smoke_import_order.be` so the temporary source-root collision coverage now proves `/modules` wins over appended roots, `/berry/lib` wins over `/berry/app` when `/modules` is absent, and repeated aliased imports keep the selected module object cached. The smoke still asserts temporary paths are absent before staging and removes only files it created. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 SD alias import cache-identity coverage

- [x] Extended `/tests/p2/smoke_import_alias.be` with a temporary `/berry/app/p2_alias_cache.be` module that is imported under two aliases. The smoke mutates state through the first alias and verifies the second alias sees the cached module object, while asserting the temporary path is absent before staging and removing only the file it created. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 current-directory import precedence coverage

- [x] Extended `/tests/p2/smoke_import_cwd.be` so a module in the active SD working directory wins over a same-name `/berry/app` source shadow, then remains cached after restoring the previous working directory and re-importing through an alias. The smoke asserts both temporary files are absent before staging and removes only files/directories it created. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 scoped libstore path mutation coverage

- [x] Tightened `/tests/p2/smoke_libstore_paths.be` so `libstore.path_add()` / `path_remove()` coverage uses a dedicated temporary `/berry/app/p1paths` root instead of mutating the default `/berry/app` root. The smoke now asserts its temporary file is absent before staging and removes the temporary directory only if it created it. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 nested app helper path coverage

- [x] Extended `/tests/p2/smoke_app_paths.be` so `libstore.app_path()`, `app_exists()`, and `run_app()` cover both a flat `/berry/app/*.be` script and a dotted nested app path such as `p1_app_pkg.probe` resolving to `/berry/app/p1_app_pkg/probe.be`. The smoke asserts temporary files are absent before staging and removes the nested app directory only if it created it. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 nested example helper path coverage

- [x] Extended `/tests/p2/smoke_example_paths.be` so `libstore.example_path()`, `example_exists()`, and `run_example()` cover both a flat `/berry/examples/*.be` script and a dotted nested example path such as `p1_example_pkg.probe` resolving to `/berry/examples/p1_example_pkg/probe.be`. The smoke asserts temporary files are absent before staging and removes the nested example directory only if it created it. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 nested PASM blob metadata coverage

- [x] Extended `/tests/p2/smoke_pasm_layout.be` so `libstore.pasm_path()`, `pasm_exists()`, and `pasm_info()` cover both a flat `/berry/pasm/*.bin` blob and a dotted nested blob path such as `p1_pasm_pkg.probe` resolving to `/berry/pasm/p1_pasm_pkg/probe.bin`. The smoke keeps `executable == false` / `pasm_execution_deferred`, asserts temporary files are absent before staging, and removes the nested PASM directory only if it created it. This is source-level metadata coverage only; PASM execution remains deferred in `TODO.md`.

### P1 configstore load/fresh-reload coverage

- [x] Extended `/tests/p2/smoke_configstore.be` so missing config loads prove the caller-provided fallback object is returned as-is, while successful JSON config loads are re-read fresh from SD: caller-side mutations to a loaded map/list do not alter the saved file observed by a later `configstore.load()`. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 `/berry/main.be` startup smoke safety coverage

- [x] Tightened `/tests/p2/smoke_sd_main.be` so the optional startup-path smoke refuses to overwrite a pre-existing `/berry/main.be`, stages a tiny import-capable main script using `json`, runs it explicitly with `run_file()`, and removes only the file it created. This is source-level path coverage only; hardware boot execution remains pending in `TODO.md`.

### P1 nested `/berry/lib` source-layout coverage

- [x] Extended `/tests/p2/smoke_import_layout.be` so the staged source-layout coverage now includes flat `/berry/lib`, flat `/berry/app`, and a nested `/berry/lib/p1_layout_pkg/mod.be` module resolved as `p1_layout_pkg.mod` through `libstore.source_path()` and native string import. The smoke asserts temporary files are absent before staging and removes the nested package directory only if it created it. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 import-all metadata-anchor coverage

- [x] Extended `/tests/p2/smoke_import_all_libs.be` so the current SD module import sweep verifies each module's `libstore.info()` metadata reports `/tests/p2/smoke_import_all_libs.be` as its SD import smoke and `/tests/p2/smoke_module_inventory.be` as its metadata smoke, while keeping `wifi` explicitly `hardware_deferred`. This remains safe import/metadata coverage only and avoids WiFi or other peripheral transactions; hardware execution remains pending in `TODO.md`.

### P1 repeated-import metadata-anchor coverage

- [x] Extended `/tests/p2/smoke_import_cache.be` so the current SD module repeated-import/cache smoke verifies each module's `libstore.info()` metadata reports `/tests/p2/smoke_import_cache.be` as its repeated-import and cache smoke, `/tests/p2/smoke_import_churn.be` as its low-memory smoke, and keeps `wifi` explicitly `hardware_deferred`. This remains source-level import/cache metadata coverage only; hardware execution remains pending in `TODO.md`.

### P1 low-memory import metadata-anchor coverage

- [x] Extended `/tests/p2/smoke_import_churn.be` so the bounded allocation/GC/import-churn smoke verifies each current SD module's `libstore.info()` metadata reports `/tests/p2/smoke_import_churn.be` as its low-memory smoke, `/tests/p2/smoke_import_cache.be` as its repeated-import and cache smoke, and `/tests/p2/smoke_import_all_libs.be` as its SD-import smoke, while keeping `wifi` explicitly `hardware_deferred`. This remains source-level import/metadata coverage only; hardware execution remains pending in `TODO.md`.

### P1 lazy-library diagnostic snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so `libstore.status()` and `libstore.strategy()` snapshots can be mutated by the caller without poisoning later lazy-loader diagnostics. This keeps SD-backed lazy-loading, no eager PSRAM execution, and cache-status reporting observable as fresh diagnostic data. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 compact stdlib JSON parse-freshness coverage

- [x] Extended `/tests/p2/smoke_stdlib.be` so compact JSON coverage now mutates a parsed map/list and reparses the same JSON text to prove each `json.load()` returns fresh caller-owned data rather than reusing poisoned parse state. This is source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 string format conversion hook invocation coverage

- [x] Extended `/tests/p2/smoke_string_format_extra.be` so a custom `toint()` object is formatted twice and must update its return value on each call, proving `string.format("%i", value)` invokes the conversion hook per formatting operation rather than caching a stale conversion. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 JSON escaped object-key coverage

- [x] Extended `/tests/p2/smoke_json_advanced.be` with escaped Unicode object-key decoding, proving `json.load()` maps a key such as `"\\u006B\\u0065\\u0079"` to the decoded Berry map key `"key"`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 time leap-day dump coverage

- [x] Extended `/tests/p2/smoke_time.be` with deterministic leap-day epoch coverage for `time.dump(951782400)`, asserting the decoded date is February 29, 2000 while preserving the existing integer field and epoch-shape checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 strict method-body global lookup coverage

- [x] Extended `/tests/p2/smoke_strict.be` with class-method strict lookup coverage: a method body can compile and read a known global while it is defined, and the same method-body shape is rejected after the global is undefined. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 debug caller boundary coverage

- [x] Extended `/tests/p2/smoke_debug.be` with an over-deep `debug.caller(64)` boundary assertion, proving the debug module returns a falsey result instead of a bogus stack frame when the requested caller depth is beyond the active stack. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 solidify repeated compaction coverage

- [x] Extended `/tests/p2/smoke_solidify.be` with repeated `solidify.compact(P2SolidifySmoke)` coverage, proving a class can be compacted twice without changing the expected instance method behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 sys.path element-mutation isolation coverage

- [x] Extended `/tests/p2/smoke_sys.be` with returned-path-list element replacement coverage, proving a caller can mutate index `0` of a `sys.path()` snapshot without changing the VM's live import path list. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 global map-valued mutation coverage

- [x] Extended `/tests/p2/smoke_global.be` with map-valued global storage and mutation coverage, proving a global map member can be read, updated in place, and cleaned up through the native `global` module path. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 JSON mixed stack-shape coverage

- [x] Extended `/tests/p2/smoke_json_stack.be` with a generated mixed object/list stack shape by embedding the existing generated nested-record list under an object key and asserting count plus mid-list record access. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 math abs parity coverage

- [x] Extended `/tests/p2/smoke_math_parity.be` with deterministic `math.abs()` sign/type coverage for negative and positive integers plus a negative real, complementing the existing no-argument fallback and upstream-adapted math parity checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 string adjacent replacement coverage

- [x] Extended `/tests/p2/smoke_string.be` with adjacent non-overlapping replacement coverage for `string.replace("aaaa", "aa", "b") == "bb"`, making native string replacement semantics explicit for back-to-back matches. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 JSON whitespace parsing coverage

- [x] Extended `/tests/p2/smoke_json.be` with whitespace-tolerant object/list parsing coverage, proving `json.load()` accepts spaces around object keys, separators, list values, and the top-level value while preserving `true` and `null` decoding. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 p2compat bytecode snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_p2compat.be` with `p2compat.bytecode()` snapshot mutation isolation coverage, proving caller-side mutation of the returned bytecode diagnostics map does not alter the module's current bytecode execution metadata. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 file/open append-create coverage

- [x] Extended `/tests/p2/smoke_sd.be` with append-mode creation coverage for a new temporary file, proving `open(path, "a")` can create, write, read back, and clean up a previously absent file. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 bytes range-slice isolation coverage

- [x] Extended `/tests/p2/smoke_bytes.be` with range-slice copy isolation coverage, proving mutating a sliced `bytes` value does not alter the original buffer. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 bytes fromstring empty reset coverage

- [x] Extended `/tests/p2/smoke_bytes_extra.be` with empty `fromstring("")` reset coverage, proving a non-empty bytes buffer can be replaced by an empty string payload just as the existing `fromhex("")` path clears hex content. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 bytes base64 two-byte padding coverage

- [x] Extended `/tests/p2/smoke_bytes_b64_fixed.be` with two-byte base64 padding coverage, proving `bytes("1122").tob64()` emits the single-padding form `"ESI="` and `fromb64("ESI=")` round-trips to `bytes("1122")`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 map nil-valued insert coverage

- [x] Extended `/tests/p2/smoke_map_core.be` with nil-valued `insert()` coverage, proving a map can insert a present key with a `nil` value and that a duplicate insert does not replace that nil-valued entry. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 range retargeted iterator preservation coverage

- [x] Extended `/tests/p2/smoke_range.be` with iterator preservation across `setrange()` retargeting, proving an iterator captured before retargeting continues its original sequence while the range object exposes the new bounds. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 list index-selection isolation coverage

- [x] Extended `/tests/p2/smoke_list_core.be` with list-index selection copy-isolation coverage, proving mutating a selected result from `src[list(...)]` does not alter the original source list. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 collections map keys/values snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_collections.be` with map `keys()` and `values()` returned-list mutation isolation coverage, proving caller-side mutations to those snapshots do not add keys or values to the source map. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 numeric conversion parser edge coverage

- [x] Extended `/tests/p2/smoke_conversions.be` with negative-exponent `number("1e-2")` and negative-real `real("-0.5")` string conversion coverage, tightening deterministic parser compatibility around numeric conversion helpers. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 call explicit nil list-expansion coverage

- [x] Extended `/tests/p2/smoke_call.be` with explicit `nil` values inside terminal list expansion, proving `call(f, [1, nil, 3])` preserves the nil argument for both fixed-argument and vararg functions. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 vararg method rest-list freshness coverage

- [x] Extended `/tests/p2/smoke_vararg.be` with method rest-list freshness coverage, proving mutating the returned `*rest` list from one method call does not leak into a later call with the same arguments. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 compiled closure retained-state coverage

- [x] Extended `/tests/p2/smoke_compile_module.be` with compiled closure retained-state coverage, proving a function returned by `compile()` can capture a mutable local and preserve updates across repeated calls. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 boolean short-circuit side-effect coverage

- [x] Extended `/tests/p2/smoke_bool.be` with short-circuit side-effect accounting, proving skipped `&&` / `||` branches do not run while executed branches update a counter as expected. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 nested map equality coverage

- [x] Extended `/tests/p2/smoke_relop.be` with nested map order-insensitive equality coverage, proving maps nested inside maps compare equal even when their keys were inserted in different orders. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 divzero adjacent signed division coverage

- [x] Extended `/tests/p2/smoke_divzero.be` with negative non-zero division and modulo checks, anchoring `-5 / 2 == -2` and `-5 % 2 == -1` next to the existing division-by-zero exception coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 suffix method-chain slice coverage

- [x] Extended `/tests/p2/smoke_suffix.be` with method-chain range-slice coverage, proving a list returned through chained suffix calls can be sliced directly with `[0..1]`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 shared reference stringification coverage

- [x] Extended `/tests/p2/smoke_reference.be` with shared-child list stringification coverage, proving repeated references to the same non-cyclic child list render normally and are not mistaken for recursive cycles. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 conditional-expression side-effect coverage

- [x] Extended `/tests/p2/smoke_cond_expr.be` with selected-branch side-effect accounting, proving conditional expressions evaluate exactly the chosen branch while preserving the existing unselected-branch exception checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 conditional-expression condition-evaluation coverage

- [x] Extended `/tests/p2/smoke_cond_expr.be` with condition-operand side-effect accounting for empty and non-empty list operands, proving conditional expressions evaluate the condition once and then preserve branch laziness for the unselected arm. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 compound computed-index update coverage

- [x] Extended `/tests/p2/smoke_compound.be` with computed list-index compound assignment coverage, proving `values[value_index] += values[0]` updates the dynamically selected slot while preserving the surrounding list values. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 assignment computed map-key/member coverage

- [x] Extended `/tests/p2/smoke_assignment.be` with computed map-key plus computed-member assignment coverage, proving a dynamic key can select an object and dynamic member names can assign and update its nested field. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 lexer comment-adjacent token coverage

- [x] Extended `/tests/p2/smoke_lexer.be` with comment-adjacent token parsing coverage, proving a compact block comment between expression tokens does not disrupt `compile()` or execution. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 walrus map-literal coverage

- [x] Extended `/tests/p2/smoke_walrus_edges.be` with map-literal assignment-expression coverage, proving walrus assignments can provide both a map key and value while preserving the assigned bindings. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 f-string computed-width coverage

- [x] Extended `/tests/p2/smoke_syntax.be` with computed-width f-string formatting coverage, proving an expression-supplied width such as `{42:0{fwidth}i}` formats through the compact syntax smoke path. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 virtual member state-backed read coverage

- [x] Extended `/tests/p2/smoke_virtual_members.be` with a state-backed virtual member, proving `member(name)` can compute a virtual field from an instance's real fields while preserving existing real-member precedence checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 virtual setmember replacement coverage

- [x] Extended `/tests/p2/smoke_virtual_setmember.be` with repeated virtual payload assignment coverage, proving a later `setmember()` write replaces the previous virtual value and the backing assignment map reports the new payload. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 module attribute real-precedence hook coverage

- [x] Extended `/tests/p2/smoke_module_attrs.be` with virtual `member()` lookup counting, proving real module attributes are returned without invoking the virtual member hook while missing attributes still dispatch through it. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 module same-name independence coverage

- [x] Extended `/tests/p2/smoke_module_system.be` with same-name module independence coverage, proving repeated `module("name")` calls create distinct module objects until a module is explicitly injected into the import cache. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 signed right-shift numeric coverage

- [x] Extended `/tests/p2/smoke_int_numeric.be` with signed right-shift coverage, proving `-8 >> 1` produces `-4` alongside the existing integer conversion, hex parsing, bitwise, and positive shift checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 chained super argument-passing coverage

- [x] Extended `/tests/p2/smoke_super.be` with chained `super(self).method(arg)` argument-passing coverage, proving a three-level class hierarchy can pass an argument through successive super calls while accumulating instance state. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 subobject builtin method preservation coverage

- [x] Extended `/tests/p2/smoke_subobject.be` with builtin method preservation coverage for list/map subclasses, proving subclass instances retain native methods such as `copy()` and `keys()` while preserving subclass storage behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 static class mutable object sharing coverage

- [x] Extended `/tests/p2/smoke_static_classes.be` with mutable static-list sharing coverage, proving class-level and instance-level reads observe the same static list object after mutation. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 static declaration cross-instance sharing coverage

- [x] Extended `/tests/p2/smoke_static_decls.be` with cross-instance static storage sharing coverage, proving multiple instances observe the same mutated static field values after class-level updates. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 static super live base-static coverage

- [x] Extended `/tests/p2/smoke_static_super_member.be` with live base-static mutation coverage, proving an inherited method reads the updated base-class static value while the child class's static override remains separate. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 class static function reassignment coverage

- [x] Extended `/tests/p2/smoke_class_const.be` with static function reassignment readback coverage, proving both class-level and existing instance-level reads observe a replaced static callable. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 compact stdlib JSON dump-state coverage

- [x] Extended `/tests/p2/smoke_stdlib.be` with compact JSON dump-state coverage, proving `json.dump()` serializes the caller's current nested map/list state while leaving that caller-owned source object intact for subsequent reads. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 compact stdlib time dump snapshot coverage

- [x] Extended `/tests/p2/smoke_stdlib.be` with compact `time.dump()` snapshot-freshness coverage, proving caller-side mutation of one returned epoch map does not poison a later dump of the same epoch. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 time dump collection-input rejection coverage

- [x] Extended `/tests/p2/smoke_time.be` with collection-valued invalid-input checks for `time.dump([])` and `time.dump({})`, complementing the existing nil/string/real/bool rejection coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 global module API-shape coverage

- [x] Extended `/tests/p2/smoke_global.be` with native `global` API-shape assertions, proving the imported object is a module and the callable table view reports as a map before exercising lookup, mutation, compile visibility, and cleanup behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 string module object-shape coverage

- [x] Extended `/tests/p2/smoke_string.be` with an imported-module object-shape assertion, proving `string` reports as a module before the smoke exercises helper exports, formatting, replacement, prefix/suffix, indexing, and multiplication behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 JSON module object-shape coverage

- [x] Extended `/tests/p2/smoke_json.be` with an imported-module object-shape assertion, proving `json` reports as a module before the smoke exercises `load`, `dump`, scalar parsing, malformed input rejection, nested data, formatted dumps, subclass dumps, and round-trip behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 solidify introspected helper coverage

- [x] Extended `/tests/p2/smoke_solidify.be` with `introspect.contains()` checks for the native `solidify.dump` and `solidify.compact` helpers, proving the module's core helpers are both callable and discoverable before compacting class shapes. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 strict branch-condition global lookup coverage

- [x] Extended `/tests/p2/smoke_strict.be` with strict compiler-mode coverage for global lookup in branch conditions: the conditional shape compiles and runs while the global is defined, then the same shape is rejected after cleanup through `global.undef()`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 debug module API-shape coverage

- [x] Extended `/tests/p2/smoke_debug.be` with native `debug` module/API-shape assertions and `introspect.contains()` checks for `attrdump` and `caller`, proving the core helpers are callable and discoverable before stack introspection coverage runs. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 sys module API-shape coverage

- [x] Extended `/tests/p2/smoke_sys.be` with native `sys` module/API-shape assertions, proving the imported object reports as a module and exposes `path()` as a function before the smoke exercises path snapshots, element-mutation isolation, `path_add()` error paths, and direct import-root behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 introspect module API-shape coverage

- [x] Extended `/tests/p2/smoke_introspect.be` with native `introspect` module/API-shape assertions for the core reflection helpers before the smoke exercises member lookup, mutation, method classification, pointer round trips, solidified checks, fallback reads, and missing-module handling. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 bytes size API-shape coverage

- [x] Extended `/tests/p2/smoke_bytes.be` with a callable `size()` API-shape assertion on a fresh bytes object, pinning the method before construction, resize, range, copy, conversion, and mutation behavior rely on it. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 bytes extra method API-shape coverage

- [x] Extended `/tests/p2/smoke_bytes_extra.be` with callable API-shape assertions for extended bytes helpers such as `set`, float accessors, `fromhex`, `setbytes`, `reverse`, boolean conversion, and base64 append/encode methods before their behavior checks run. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 bytes base64 API-shape coverage

- [x] Extended `/tests/p2/smoke_bytes_b64_fixed.be` with callable API-shape assertions for `tob64()` and `fromb64()` before the smoke exercises padding, no-padding, fixed-size initialization, fixed-size mutation rejection, and concatenation behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 list size API-shape coverage

- [x] Extended `/tests/p2/smoke_list_core.be` with a callable `size()` API-shape assertion on a fresh list, pinning the method alongside iterator, copy, mutation, find, keys, and concat helper coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 map keys-values API-shape coverage

- [x] Extended `/tests/p2/smoke_map_core.be` with callable `keys()` and `values()` API-shape assertions on a fresh map, pinning those helper methods alongside find/contains/remove/insert/iter/size before map lookup, iteration, insertion, and cleanup behavior runs. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 range method API-shape coverage

- [x] Extended `/tests/p2/smoke_range.be` with callable API-shape assertions for `lower()`, `upper()`, `incr()`, `iter()`, and `setrange()` before the smoke exercises range accessors, retargeting, iterator independence, descending sequences, and value-error paths. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 range type classification coverage

- [x] Extended `/tests/p2/smoke_conversions.be` with `type(range(0, 1)) == "range"`, pinning range object classification alongside the existing nil/bool/int/real/string/list/map/bytes type checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 call constructor list-expansion coverage

- [x] Extended `/tests/p2/smoke_call.be` with class-constructor terminal-list expansion coverage, proving `call(Class, [arg])` expands the final list into constructor arguments while preserving the existing direct constructor path. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 vararg direct rest-list freshness coverage

- [x] Extended `/tests/p2/smoke_vararg.be` with direct required-plus-rest vararg freshness coverage, proving mutating a returned rest list from `f(1, 2)` does not leak into a later direct call with the same arguments. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 closure returned-function classification coverage

- [x] Extended `/tests/p2/smoke_closure.be` with returned-closure `type(...) == "function"` assertions for independent counter closures before exercising their captured state and mutation behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 function-capture returned-function classification coverage

- [x] Extended `/tests/p2/smoke_function_capture.be` with returned-function `type(...) == "function"` assertions for independent factory closures before exercising their separate captured mutable state. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 for-loop empty-range coverage

- [x] Extended `/tests/p2/smoke_for_loop.be` with empty descending-range iteration coverage, proving a `for i : 5 .. 0` loop body is skipped and does not mutate surrounding state. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 map key-error exception coverage

- [x] Extended `/tests/p2/smoke_errors.be` with map missing-key `key_error` coverage, adding that exception class beside the existing custom raise, syntax, type, bytes index, helper propagation, nested handling, and rethrow checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 assert default-message exception coverage

- [x] Extended `/tests/p2/smoke_exception_assert.be` with default-message `assert(false)` coverage, proving it raises `assert_failed` even when no custom assertion message is provided. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 operator-overload result class identity coverage

- [x] Extended `/tests/p2/smoke_operator_overload.be` with `classof(...)` assertions for overloaded `+` result instances, proving both direct and chained binary overload results preserve the expected class identity in addition to their payload values. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 VM comparison result-type coverage

- [x] Extended `/tests/p2/smoke_vm_ops.be` with boolean result-type assertions for equality and relational comparisons, pinning comparison expressions as `bool` before the smoke exercises overloaded equality/inequality behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 VM named-global cleanup coverage

- [x] Extended `/tests/p2/smoke_vm_error_paths.be` with named-global cleanup coverage, proving the temporary global used for named-global read/write opcode checks is absent after `global.undef()`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 compiler parser call-result chained-suffix coverage

- [x] Extended `/tests/p2/smoke_compiler_parser.be` with a function-call-result chained-suffix parser shape, proving a nested list returned by a helper can be indexed immediately as `make_suffix_rows()[1][0]`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 class instance identity coverage

- [x] Extended `/tests/p2/smoke_classes.be` with `classof(demo) == StaticDemo`, pinning class identity for a constructed instance before the smoke exercises instance state, static fallback, static methods, module-member construction, and indirect member access. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 indirect static method dispatch coverage

- [x] Extended `/tests/p2/smoke_member_indirect.be` with computed static method dispatch through `P2IndirectStatic.(static_methods[0])()`, complementing the existing module/class/instance indirect member reads, writes, instance method dispatch, dynamic static writes, and chained updates. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 nested static class identity coverage

- [x] Extended `/tests/p2/smoke_static_classes.be` with first-class nested static class readback coverage, constructing an instance through a saved `P2StaticOuter.Inner` reference and checking `classof()` plus instance method dispatch. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 static declaration mutable map coverage

- [x] Extended `/tests/p2/smoke_static_decls.be` with mutable static map sharing coverage, proving class-level and instance-level reads observe the same map after mutation through another instance. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 class constant scalar update coverage

- [x] Extended `/tests/p2/smoke_class_const.be` with class-side scalar compound update coverage, proving an existing instance observes the updated static value through instance fallback. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 static super child override mutation coverage

- [x] Extended `/tests/p2/smoke_static_super_member.be` with child static override mutation coverage, proving an inherited dynamic static lookup observes the updated child value while inherited base-method reads and base instances remain pinned to the base static value. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 module same-name member table independence coverage

- [x] Extended `/tests/p2/smoke_module_system.be` with same-name module member-table independence coverage, proving repeated `module("name")` objects keep separate mutable member state until explicit import-cache injection. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 module post-virtual shadow precedence coverage

- [x] Extended `/tests/p2/smoke_module_attrs.be` with post-virtual shadow precedence coverage, proving a real module field assigned after a virtual `member()` lookup takes precedence without invoking the virtual hook again. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 saved inherited ismethod coverage

- [x] Extended `/tests/p2/smoke_introspect_ismethod.be` with saved inherited method and saved inherited static-method classification, proving values fetched from a child instance preserve `ismethod()` behavior after assignment to locals. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 compiled local map mutation coverage

- [x] Extended `/tests/p2/smoke_compile_module.be` with compiled local map mutation coverage, proving code produced by `compile()` can create a map, assign a new key, and read the updated values before returning. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 string format character conversion-hook coverage

- [x] Extended `/tests/p2/smoke_string_format_extra.be` with `%c` conversion-hook coverage for a stateful `toint()` object, proving character formatting invokes the conversion hook and updates object state. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 JSON multi-entry Unicode array coverage

- [x] Extended `/tests/p2/smoke_json_advanced.be` with escaped Unicode decoding inside a multi-entry JSON array, proving ASCII, two-byte, and three-byte escape expansions decode correctly in array values. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 JSON generated matrix stack coverage

- [x] Extended `/tests/p2/smoke_json_stack.be` with a compact generated matrix/list-of-lists parse, proving JSON stack/growth coverage includes nested arrays with indexed numeric reads. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 time module API-shape coverage

- [x] Extended `/tests/p2/smoke_time.be` with native `time` module/API-shape assertions for `clock`, `dump`, and `time` before deterministic epoch, invalid-input, mutation-isolation, and `time()` consistency checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 solidify static mutation after compaction coverage

- [x] Extended `/tests/p2/smoke_solidify.be` with static member mutation after `solidify.compact()`, proving a compacted class's static method observes the updated static value while inherited instance behavior still works. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 debug attrdump instance coverage

- [x] Extended `/tests/p2/smoke_debug.be` with instance-level `debug.attrdump()` no-crash coverage, proving a normal instance method read still works before and after debug inspection. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 sys path fresh-list identity coverage

- [x] Extended `/tests/p2/smoke_sys.be` with `introspect.toptr()` checks proving repeated `sys.path()` calls return distinct list objects before the smoke exercises snapshot mutation, `path_add()` error paths, and direct import-root behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 strict loop-condition global lookup coverage

- [x] Extended `/tests/p2/smoke_strict.be` with strict compiler-mode coverage for known-global lookup in `while` conditions, proving the loop-condition shape compiles and runs while the global is defined and is rejected after cleanup through `global.undef()`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 global helper API-shape coverage

- [x] Extended `/tests/p2/smoke_global.be` with native `global.contains` and `global.undef` helper API-shape assertions before exercising lookup, mutation, compile visibility, table views, and cleanup behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 string count no-match coverage

- [x] Extended `/tests/p2/smoke_string.be` with `string.count()` no-match coverage, proving a missing substring returns zero before the smoke exercises bounded counts, splitting, escaping, replacement, formatting, prefix/suffix helpers, indexing, and multiplication behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 JSON formatted nested-list dump coverage

- [x] Extended `/tests/p2/smoke_json.be` with formatted nested-list dump coverage, proving `json.dump(value, "format")` indents a nested list while preserving the existing scalar/list/map dump and round-trip checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 bytes empty append no-op coverage

- [x] Extended `/tests/p2/smoke_bytes.be` with empty `bytes()` append no-op coverage, proving appending an empty bytes value preserves the receiver before the smoke exercises string append, appendhex, range slicing, copy isolation, conversion, and mutation behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 virtual setmember computed scalar write coverage

- [x] Extended `/tests/p2/smoke_virtual_setmember.be` with computed-name assignment to the scalar virtual field itself, proving `obj.(name) = value` routes through `setmember()` for `"virtual"` before the smoke exercises computed payload and function-valued assignments. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 module indirect function-call coverage

- [x] Extended `/tests/p2/smoke_member_indirect.be` with module indirect function-call coverage, proving a function-valued module member can be looked up through a computed `.(name)` expression and invoked immediately. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 subobject map keys snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_subobject.be` with map-subclass `keys()` snapshot isolation coverage, proving a saved keys list from a map subclass does not grow after later subclass storage mutation while a fresh `keys()` call sees the new key. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 walrus local call-argument value coverage

- [x] Extended `/tests/p2/smoke_walrus_edges.be` with local walrus assignments inside function-call arguments, proving argument evaluation returns assigned values left-to-right and leaves the assigned locals readable after the call. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 f-string computed map-key expression coverage

- [x] Extended `/tests/p2/smoke_syntax.be` with f-string computed map-key expression coverage, proving an f-string expression can index a map through a key variable after the existing list-index and literal map-key checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 lexer line-comment adjacent token coverage

- [x] Extended `/tests/p2/smoke_lexer.be` with line-comment-adjacent token parsing coverage, proving a `#` line comment between expression tokens does not disrupt `compile()` or execution alongside the existing compact block-comment coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 class static update observed by existing instance coverage

- [x] Extended `/tests/p2/smoke_classes.be` with static field mutation after instance creation, proving an existing instance and its instance method observe the updated class static value through fallback lookup. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 function-capture shared-upvalue group independence coverage

- [x] Extended `/tests/p2/smoke_function_capture.be` with a second shared-upvalue closure pair, proving closures from one factory call share their captured state while a separate factory call owns an independent shared-upvalue group. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 closure mutable capture independence coverage

- [x] Extended `/tests/p2/smoke_closure.be` with a second list-accumulator closure, proving separate factory calls retain independent captured mutable lists while the original accumulator keeps its own state. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 escaped vararg rest-list mutation persistence coverage

- [x] Extended `/tests/p2/smoke_vararg.be` with escaped rest-list mutation persistence coverage, proving a closure-captured vararg list remains a retained mutable object across later closure calls. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 callable-instance list lookup invocation coverage

- [x] Extended `/tests/p2/smoke_operator_overload.be` with callable-instance invocation after list lookup, proving an object implementing `def ()()` remains callable when fetched through an indexed collection suffix. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 integer variable shift-count coverage

- [x] Extended `/tests/p2/smoke_int_numeric.be` with variable shift-count coverage, proving left and right shifts accept a runtime integer shift amount alongside the existing literal, zero-shift, signed right-shift, and precedence checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 method-call raise propagation coverage

- [x] Extended `/tests/p2/smoke_errors.be` with method-call `raise` propagation coverage, proving a custom error type and message survive when raised inside an instance method and caught by the caller. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 method-call assert propagation coverage

- [x] Extended `/tests/p2/smoke_exception_assert.be` with method-call assert propagation coverage, proving a custom `assert_failed` message survives when the failing assertion is raised inside an instance method. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 nested for-loop outer-break coverage

- [x] Extended `/tests/p2/smoke_for_loop.be` with nested-loop outer `break` coverage, proving an outer-loop break stops later outer iterations after the completed inner-loop work for earlier outer values. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 suffix method-chain negative-index coverage

- [x] Extended `/tests/p2/smoke_suffix.be` with method-chain negative-index coverage, proving a list returned through chained suffix calls can be immediately indexed with `[-1]` after the existing positive-index and range-slice checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 compound computed map-key sibling isolation coverage

- [x] Extended `/tests/p2/smoke_compound.be` with computed map-key sibling isolation coverage, retargeting the dynamic key used for compound assignment and proving the selected map entry changes while the previously updated sibling remains stable. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 assignment computed map-key sibling isolation coverage

- [x] Extended `/tests/p2/smoke_assignment.be` with computed map-key sibling isolation coverage, proving dynamic-key nested member assignment updates the selected object while preserving a previously updated sibling object. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 falsey collection OR branch execution coverage

- [x] Extended `/tests/p2/smoke_bool.be` with side-effect accounting for `[] || mark(...)`, proving a falsey collection on the left side of `||` evaluates the right branch rather than only returning the expected boolean result. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 list equality order-sensitivity coverage

- [x] Extended `/tests/p2/smoke_relop.be` with list order-sensitivity checks, proving `[1, 2]` and `[2, 1]` compare unequal while map equality coverage remains order-independent. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 module computed virtual function read coverage

- [x] Extended `/tests/p2/smoke_virtual_members.be` with computed-name module virtual function lookup, saving `dyn.("fn")` through an indirect name and invoking the returned function to prove function-valued virtual members survive computed reads. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 saved function-valued member ismethod coverage

- [x] Extended `/tests/p2/smoke_introspect_ismethod.be` with saved function-valued instance-member classification, proving a plain function stored on an instance remains `introspect.ismethod(...) == false` after assignment to a local. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 solidify compact string invalid-type coverage

- [x] Extended `/tests/p2/smoke_solidify.be` with string-valued invalid-input coverage for `solidify.compact()`, pairing the existing integer rejection and proving non-class compact targets raise `value_error` before normal class compaction behavior runs. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 global nil helper rejection coverage

- [x] Extended `/tests/p2/smoke_global.be` with `global.contains(nil)` and `global.undef(nil)` rejection coverage, pairing the existing non-string integer helper checks and proving nil helper input is rejected without mutating the global table. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 time false-bool invalid dump input coverage

- [x] Extended `/tests/p2/smoke_time.be` with `time.dump(false) == nil`, pairing the existing true-bool rejection and proving falsey boolean input is rejected through the same invalid-input path. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 JSON top-level scalar whitespace coverage

- [x] Extended `/tests/p2/smoke_json.be` with whitespace-tolerant top-level scalar parsing coverage, proving `json.load()` accepts surrounding spaces for scalar `true` and `null` values before the smoke exercises numeric, string, object, list, dump, and round-trip behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 string adjacent substring count coverage

- [x] Extended `/tests/p2/smoke_string.be` with adjacent multi-character `string.count()` coverage, proving non-overlapping adjacent substring matches such as `"aa"` in `"aaaa"` are counted as two matches. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 range retargeted iterator exhaustion coverage

- [x] Extended `/tests/p2/smoke_range.be` with iterator exhaustion checks after `setrange()` retargeting, proving preserved positive and negative iterators terminate on their original bounds rather than drifting into the retargeted range. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 map equivalent-key removal coverage

- [x] Extended `/tests/p2/smoke_map_keys.be` with equivalent fresh-key removal coverage, proving `remove()` honors custom `hash()`/`==` identity by deleting the existing logical key without disturbing a separate entry. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 bytes length-based truthiness coverage

- [x] Extended `/tests/p2/smoke_bytes_extra.be` with `bytes("00").tobool() == true`, proving bytes truthiness is based on buffer length rather than nonzero byte contents. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 bytes four-byte base64 round-trip coverage

- [x] Extended `/tests/p2/smoke_bytes_b64_fixed.be` with four-byte base64 padding coverage, proving `bytes("11223344").tob64()` emits `"ESIzRA=="` and `fromb64("ESIzRA==")` round-trips to the original bytes. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 map keys snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_map_core.be` with `keys()` snapshot isolation coverage, proving a previously captured keys list does not grow after the source map is mutated with a new key. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 list copy bidirectional isolation coverage

- [x] Extended `/tests/p2/smoke_list_core.be` with copied-list mutation isolation coverage, proving mutating the copied list after `copy()` does not alter the source list, complementing the existing source-mutation-does-not-alter-copy check. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 map-core values snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_map_core.be` with `values()` snapshot isolation coverage, proving a previously captured values list does not grow after source-map mutation and that caller-side mutation of the values list does not mutate the source map. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 call non-callable error coverage

- [x] Extended `/tests/p2/smoke_call.be` with non-callable rejection coverage for `nil`, integer, and list receivers before the existing positive `call()` dispatch and argument-expansion checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 bytes truthiness conversion coverage

- [x] Extended `/tests/p2/smoke_conversions.be` with `bool(bytes()) == false` and `bool(bytes("00")) == true`, pinning core builtin truthiness for empty and non-empty bytes values by length. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 list iterator exhaustion coverage

- [x] Extended `/tests/p2/smoke_list_core.be` with an iterator exhaustion assertion after the last yielded list element, pinning the `nil` end-of-iteration result alongside existing iterator ordering coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 string empty-subject find/count coverage

- [x] Extended `/tests/p2/smoke_string.be` with empty-subject `string.find()` and `string.count()` boundary coverage, pinning empty-needle behavior on `""` alongside the existing non-empty search/count cases. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 range independent iterator exhaustion coverage

- [x] Extended `/tests/p2/smoke_range.be` with exhaustion coverage for a second iterator captured from the same range object, proving independent iterator state reaches its own `nil` endpoint without aliasing the first iterator. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 string empty-subject prefix/suffix coverage

- [x] Extended `/tests/p2/smoke_string.be` with empty-subject negative assertions for `string.startswith("", "x")` and `string.endswith("", "x")`, pinning prefix/suffix helper boundaries alongside the existing empty-needle positive cases. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 JSON empty container load/dump coverage

- [x] Extended `/tests/p2/smoke_json.be` with empty array/object `json.load()` and `json.dump()` assertions, pinning compact container boundaries alongside the existing scalar, nested, formatted, and round-trip cases. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 time dump non-empty collection rejection coverage

- [x] Extended `/tests/p2/smoke_time.be` with non-empty list and map invalid-input checks for `time.dump()`, proving collection rejection is type-based rather than limited to empty containers. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 JSON trailing-token rejection coverage

- [x] Extended `/tests/p2/smoke_json.be` with trailing-token rejection checks for scalar and array JSON inputs, pinning that `json.load()` fails rather than silently accepting a valid prefix. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 global boolean helper rejection coverage

- [x] Extended `/tests/p2/smoke_global.be` with boolean-input rejection checks for `global.contains(true)` and `global.undef(false)`, pinning non-string helper behavior alongside existing integer and nil edge cases. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 solidify nocompact string invalid-input coverage

- [x] Extended `/tests/p2/smoke_solidify.be` with optional `solidify.nocompact("not a function")` invalid-input coverage when the helper is present, pairing the existing integer rejection and valid-function behavior. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 debug caller zero-depth coverage

- [x] Extended `/tests/p2/smoke_debug.be` with a `debug.caller(0)` assertion inside the caller-chain helper, proving zero depth resolves to the current function before the smoke walks direct, wrapped, nested, and over-deep caller frames. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 sys.path_add nil/list invalid-input coverage

- [x] Extended `/tests/p2/smoke_sys.be` with `sys.path_add(nil)` and `sys.path_add([])` rejection checks, pinning non-string invalid-input behavior alongside the existing missing, integer, and empty-string path cases. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 strict conditional-expression global lookup coverage

- [x] Extended `/tests/p2/smoke_strict.be` with strict compiler-mode coverage for known-global lookup inside a conditional expression, proving the ternary shape compiles while the global is defined and is rejected after cleanup through `global.undef()`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 bytes bidirectional copy isolation coverage

- [x] Extended `/tests/p2/smoke_bytes.be` with source-after-copy mutation isolation coverage, proving mutating the original bytes buffer after `copy()` does not alter the copied buffer, complementing the existing copy-mutation-does-not-affect-source check. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 bytes setbytes source-preservation coverage

- [x] Extended `/tests/p2/smoke_bytes_extra.be` with a `setbytes()` source-buffer preservation assertion, proving copying bytes into a target does not mutate the source buffer. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 bytes six-byte base64 round-trip coverage

- [x] Extended `/tests/p2/smoke_bytes_b64_fixed.be` with six-byte base64 no-padding coverage, proving two complete base64 quanta encode as `"ESIzRFVm"` and decode back to `bytes("112233445566")`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 math round half-boundary coverage

- [x] Extended `/tests/p2/smoke_math_parity.be` with `math.round(0.5) == 1` and `math.round(-0.5) == -1`, pinning half-away rounding behavior around zero alongside the existing positive and negative nonzero cases. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 p2compat summary snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_p2compat.be` with `p2compat.summary()` snapshot mutation isolation coverage, proving caller-side mutation of the returned summary map does not alter fresh summary results from the module. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 configstore path validation coverage

- [x] Extended `/tests/p2/smoke_configstore.be` with invalid `configstore.path()` checks for empty and slash-containing names, proving public path construction follows the same filename-only validation as `configstore.name()`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 example helper missing-exists coverage

- [x] Extended `/tests/p2/smoke_example_paths.be` with `libstore.example_exists("p1_no_such_example") == false`, pinning missing-example existence behavior alongside the existing missing `run_example()` nil result. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 PASM helper missing-exists coverage

- [x] Extended `/tests/p2/smoke_pasm_layout.be` with `libstore.pasm_exists("p1_no_such_pasm") == false`, pinning missing PASM blob existence behavior alongside the existing missing `pasm_info()` metadata. Source-level metadata coverage only; PASM execution remains deferred in `TODO.md`.

## P1 missing-import compiled-status metadata coverage

- [x] Extended `/tests/p2/smoke_import_missing.be` with `libstore.compiled_status(missing_name) == "missing"`, pinning helper-level missing metadata before the smoke stages, imports, mutates, and reimports the recovered module. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 missing-import recovery diagnostics coverage

- [x] Extended `/tests/p2/smoke_import_missing.be` so the recovered module now pins `libstore.info()` selected kind, selected path, and nonzero source-size metadata after the previously missing `/berry/app` module is staged, imported, mutated, and reimported. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 import-alias info diagnostics coverage

- [x] Extended `/tests/p2/smoke_import_alias.be` so the staged repeated-alias module now pins `libstore.info()` existence, selected path, and nonzero source-size metadata alongside the existing `source_path()` and alias-cache mutation checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 import-cache source metadata parity coverage

- [x] Extended `/tests/p2/smoke_import_cache.be` so each current SD module now checks `libstore.info()` source size/hash metadata against `libstore.source_stats()` while preserving the existing repeated-import identity, metadata-anchor, and optional PSRAM source-cache checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 import-churn source metadata parity coverage

- [x] Extended `/tests/p2/smoke_import_churn.be` so each current SD module now checks `libstore.info()` source size/hash metadata against `libstore.source_stats()` inside the bounded allocation/GC/import-churn smoke. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 import-cache SD-import metadata-anchor coverage

- [x] Extended `/tests/p2/smoke_import_cache.be` so the repeated-import/cache smoke also verifies each current SD module reports `/tests/p2/smoke_import_all_libs.be` as its SD-import smoke metadata anchor, alongside the existing repeated-import, cache, and low-memory anchors. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 import-churn cache metadata-anchor coverage

- [x] Extended `/tests/p2/smoke_import_churn.be` so the bounded allocation/GC/import-churn smoke verifies each current SD module reports `/tests/p2/smoke_import_cache.be` as its cache smoke metadata anchor, alongside low-memory, repeated-import, and SD-import anchors. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 module inventory compiled-summary snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_module_inventory.be` with `libstore.compiled_summary()` snapshot mutation isolation coverage, proving caller-side mutation of the returned summary map does not alter fresh compiled-summary diagnostics. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 import-all behavior metadata coverage

- [x] Extended `/tests/p2/smoke_import_all_libs.be` so the safe import sweep verifies covered modules expose string-valued behavior-smoke metadata while `wifi` remains explicitly `hardware_deferred` with no behavior smoke claim. Source-level metadata coverage only; hardware execution remains pending in `TODO.md`.

### P1 import-all source metadata parity coverage

- [x] Extended `/tests/p2/smoke_import_all_libs.be` so each current SD module now checks `libstore.info()` source size/hash metadata against `libstore.source_stats()` inside the safe import sweep. Source-level metadata coverage only; hardware execution remains pending in `TODO.md`.

## P1 BEC execution-probe snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_bec_fallback.be` with `libstore.compiled_execution_probe()` snapshot mutation isolation coverage, proving caller-side mutation of the returned bytecode execution-policy map does not alter fresh probe diagnostics. Source-level metadata coverage only; `.bec` execution remains deferred in `TODO.md`.

## P1 import-order source-path diagnostics coverage

- [x] Extended `/tests/p2/smoke_import_order.be` with `libstore.source_path()` assertions for the `/modules` and `/berry/lib` winning roots, proving diagnostics mirror the same precedence as native imports. Source-level coverage only; hardware execution remains pending in `TODO.md`.

## P1 import-alias source-path diagnostics coverage

- [x] Extended `/tests/p2/smoke_import_alias.be` with a `libstore.source_path("p2_alias_cache")` assertion for the staged alias-import module, proving diagnostics point at the same `/berry/app` source file used by repeated alias imports. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 app helper missing-exists fallback coverage

- [x] Extended `/tests/p2/smoke_app_paths.be` so the missing `/berry/app` helper path now checks both `libstore.app_exists("p1_no_such_app") == false` and `libstore.run_app("p1_no_such_app") == nil`. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 example helper missing-path fallback coverage

- [x] Extended `/tests/p2/smoke_example_paths.be` so the missing `/berry/examples` helper path now checks `libstore.example_path("p1_no_such_example") == nil` before the existing missing existence/run fallback assertions. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 PASM helper missing-path fallback coverage

- [x] Extended `/tests/p2/smoke_pasm_layout.be` so the missing `/berry/pasm` helper path now checks `libstore.pasm_path("p1_no_such_pasm") == nil` before the existing missing existence/info fallback assertions. Source-level metadata coverage only; PASM execution remains deferred in `TODO.md`.

### P1 app helper missing-path fallback coverage

- [x] Extended `/tests/p2/smoke_app_paths.be` so the missing `/berry/app` helper path now checks `libstore.app_path("p1_no_such_app") == nil` before the existing missing existence/run fallback assertions. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 configstore uppercase suffix normalization coverage

- [x] Extended `/tests/p2/smoke_configstore.be` so `configstore.name("Caps.JSON")` and `configstore.path("Caps.JSON")` preserve an existing uppercase `.JSON` suffix instead of appending a second suffix. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 os.path local no-extension splitext coverage

- [x] Extended `/tests/p2/smoke_sd.be` with `os.path.splitext("LOCAL") == ["LOCAL", ""]`, pinning the local relative no-extension helper shape without adding any new SD writes. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 `/berry/main.be` staged-file lifecycle coverage

- [x] Extended `/tests/p2/smoke_sd_main.be` so the optional startup-path smoke verifies `/berry/main.be` exists after staging and is absent again after cleanup, while still refusing to overwrite a pre-existing file. Source-level path coverage only; hardware boot execution remains pending in `TODO.md`.

### P1 dotted package companion diagnostics coverage

- [x] Extended `/tests/p2/smoke_package_paths.be` so the companion comma-import module `pkg.other` now has direct `libstore.module_file()`, `source_path()`, and `info()` diagnostics pinned to `/berry/app/pkg/other.be`, matching the existing `pkg.mod` diagnostics. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 native-first repeated import identity coverage

- [x] Extended `/tests/p2/smoke_import_native_first.be` so repeated native `json` imports under fake `/berry/lib/json.be` and `/berry/app/json.be` shadows now prove cached module identity with `introspect.toptr()`, in addition to proving the native module wins over both SD shadows. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 import-order info diagnostics coverage

- [x] Extended `/tests/p2/smoke_import_order.be` so the `/modules` and `/berry/lib` winning-root cases now pin `libstore.info()` existence, path, and nonzero source-size metadata alongside the existing native import and `source_path()` precedence checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 current-directory import identity coverage

- [x] Extended `/tests/p2/smoke_import_cwd.be` so the cached current-directory module reimport now proves object identity with `introspect.toptr()` after restoring the original working directory, alongside the existing mutation-visibility check. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 sys.path_add diagnostics coverage

- [x] Extended `/tests/p2/smoke_sys_path_add.be` so the module staged under the appended `/berry/sys_path` root now pins `libstore.info()` existence, path, and nonzero source-size metadata alongside duplicate-safe `path_add()`, `source_path()`, and native import coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 scoped libstore path diagnostics coverage

- [x] Extended `/tests/p2/smoke_libstore_paths.be` so the module staged under the scoped `/berry/app/p1paths` root now pins `libstore.info()` path and nonzero source-size metadata alongside duplicate-safe `path_add()`, `source_path()`, `load()`, and `path_remove()` coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 import-layout info diagnostics coverage

- [x] Extended `/tests/p2/smoke_import_layout.be` so the staged flat `/berry/lib`, flat `/berry/app`, and nested `/berry/lib` package modules now pin `libstore.info()` existence, path, and nonzero source-size metadata alongside the existing `source_path()` and import checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 module inventory source metadata parity coverage

- [x] Extended `/tests/p2/smoke_module_inventory.be` so each existing inventory record now checks path, source-size, and source-hash metadata against `libstore.source_stats(rec["name"])`, preserving the existing inventory shape, coverage metadata, and mutation-isolation checks. Source-level metadata coverage only; hardware execution remains pending in `TODO.md`.

### P1 BEC fallback source/compiled metadata parity coverage

- [x] Extended `/tests/p2/smoke_bec_fallback.be` so the staged source and dummy `.bec` file now check `libstore.info()` source/compiled size and hash metadata against `libstore.source_stats()` and `libstore.compiled_stats()`. Source-level metadata coverage only; `.bec` execution remains deferred in `TODO.md`.

### P1 p2compat report summary mutation-isolation coverage

- [x] Extended `/tests/p2/smoke_p2compat.be` so caller-side mutation of the nested `p2compat.report()["summary"]` map does not alter fresh report summary counts, complementing the existing report list/item/status and summary snapshot isolation checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 p2mem modules snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of a returned `p2mem.modules()` record does not alter fresh module diagnostics snapshots, complementing the existing `p2mem.module(name)` and `libstore.inventory()` metadata checks. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 p2mem cache status snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned `p2mem.cache()["status"]` map does not alter fresh cache diagnostics snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 p2mem stats snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned `p2mem.stats()` top-level fields and nested `libstore` diagnostics map does not alter fresh stats snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 p2mem evict snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned `p2mem.evict()["after"]` diagnostics map does not alter fresh eviction diagnostics snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 p2mem GC snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned `p2mem.gc()` diagnostics map does not poison fresh GC diagnostics snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 p2mem single-module snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned `p2mem.module("math")` diagnostics map does not alter fresh single-module diagnostics snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 libstore module-list snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned `libstore.modules()` list does not alter fresh module-list diagnostics snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 libstore policy snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned `libstore.policy()` diagnostics map does not alter fresh lazy-loader policy snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 p2mem cache item-list snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned `p2mem.cache()["items"]` diagnostics list does not alter fresh cache diagnostics snapshots, complementing the existing cache-status mutation isolation check. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 p2mem cache item-list isolation repair

- [x] Repaired `/tests/p2/smoke_libraries.be` so cache item-shape assertions iterate over the fresh `p2mem.cache()` snapshot after the caller-side item-list mutation, avoiding the local mutation probe while preserving the snapshot-isolation coverage. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 libstore path-list snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libstore_paths.be` so caller-side mutation of the returned `libstore.path_list()` list does not alter fresh path-list diagnostics snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 libstore source-stats snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of returned `libstore.source_stats("binary_heap")` diagnostics does not alter fresh source metadata snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 libstore compiled-stats snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of returned `libstore.compiled_stats("binary_heap")` diagnostics does not alter fresh compiled metadata snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 libstore info snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of returned `libstore.info("binary_heap")` diagnostics does not alter fresh module metadata snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 libstore status snapshot isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side mutation of returned `libstore.status()` diagnostics does not alter fresh lazy-loader/cache status snapshots. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 libstore strategy module-path snapshot isolation coverage

- [x] Updated `modules/libstore.be` so `libstore.strategy()["module_path"]` returns the copied path-list snapshot instead of the mutable loader path list, and extended `/tests/p2/smoke_libraries.be` so caller-side mutation of the returned strategy path list does not alter fresh strategy diagnostics. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 libstore strategy module-path element isolation coverage

- [x] Extended `/tests/p2/smoke_libraries.be` so caller-side replacement of an element inside returned `libstore.strategy()["module_path"]` diagnostics does not alter fresh strategy path-list contents, complementing the existing append-mutation isolation check. Source-level coverage only; hardware execution remains pending in `TODO.md`.

### P1 P2 RAM parser feedback repair

- [x] Reworked `modules/libstore.be` policy support checks to avoid parser-sensitive multiline boolean `return` continuation, and simplified `/tests/p2/smoke_libraries.be` strategy load assertions to avoid the on-target parser error seen during the P2 RAM smoke attempt. Source-level repair only; re-running the three RAM smokes remains pending.

### P1 range `incr()` export repair

- [x] Fixed `src/be_rangelib.c` so the non-precompiled/custom range registration table exports the existing native `incr()` method. The P2 RAM `smoke_range.be` run had reached the smoke and failed with `attribute_error: the 'range' object has no attribute 'incr'`; re-running that RAM smoke remains pending.

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
- [x] Added `port/p2/docs/CLOSURE_COG_REPL_PROOF.md` with the exact interactive p38/p39 REPL proof sequence for defining one blinker closure, spawning two handles, confirming closure handle/model/call-count diagnostics, and stopping both handles.
- [x] Hardware-validated the p38/p39 blinker fast path on `/dev/cu.usbserial-P97cvdxp`: `p2.cog.spawn(blinker, 38, 250)` returned handle `100`, `p2.cog.spawn(blinker, 39, 700)` returned handle `101`, `p2.cog.info()` reported both handles running with `native_blink == true`, `native_pin == 38/39`, calls advancing (`67` and `24` at inspection), and `p2.cog.stop(100)`, `p2.cog.stop(101)`, final `p2.cog.info()` returned `[]`.
- [x] Tightened the p38/p39 blinker fast path so `p2.cog.spawn(blinker, pin, rate_ms)` invokes the passed Berry closure once on the main REPL cog during setup and uses its positive integer return value as the native blink period.
- [x] Extended `port/p2/docs/CLOSURE_COG_REPL_PROOF.md` with explicit pass criteria for the live board proof: build/REPL reachability, distinct handles, p38/p39 blink-rate difference, call counts, stop behavior, and final handle cleanup.
- [x] Added `/tests/p2/smoke_cog_closure.be` as source-level proof scaffolding for handle creation/inspection/stop, including listing spawned handles through `p2.cog.info()` and checking stop wait metrics. The actual LED blink proof is intentionally interactive because the shared-VM safety model only calls closure callbacks while the REPL is idle at the prompt. Hardware execution remains pending.
