# P2 Edge32 SD/XMM TODO

Date created: 2026-06-06

Source documents:

- `port/p2/goal.md`
- `port/p2/docs/P2_EDGE32_SD_XMM_HANDOFF.md`

Maintenance rule:

- Do not edit `port/p2/goal.md` just to update progress.
- Update this file and `port/p2/DONE.md` in the same change whenever a feature is added, verified, or intentionally declared unsupported.
- Keep partially implemented work here until the implementation has tests, examples, documentation, and honest coverage notes.
- Move only verified facts to `DONE.md`; do not count a stub or placeholder API as done.

## Migration priorities

- [ ] Preserve the implemented Edge32 memory architecture as the first priority: Catalina/XMM owns the lower pointer-safe PSRAM window for active Berry VM heap, and the upper PSRAM window is cache/storage/block-transfer space.
- [ ] Preserve the working Edge32 SD/direct-SD path, including FAT volume fallback at sector `2048`, while the lower-XMM heap plus upper-PSRAM cache architecture is hardened.
- [ ] Preserve working pins, I2C, SPI, SD-backed files, SD module imports, and existing Berry library behavior while migrating architecture.
- [ ] Archive the current Spin2 native module path out of the default build; replace it later with real closure-based cog/VM support.
- [ ] Archive the current worker native module path out of the default build; replace it later with real closure-based cog/VM support.
- [ ] Keep roadmap-shaped/native facades opt-in until they compile, boot, and prove they do not destabilize the working Edge32 baseline.

## XMM heap plus upper-PSRAM cache architecture

- [ ] Keep the accepted lower-XMM/upper-cache memory split documented and enforced in the build, runtime diagnostics, and P2 smoke tests.
- [ ] Continue validating the lower Catalina/XMM pointer-safe Berry VM heap with normal allocation, GC mark/sweep, strings, lists, maps, closures, and modules on hardware.
- [ ] Continue integrating the upper PSRAM block/cache window for module/source storage, bytecode staging, large buffers, inactive data, and explicit block transfers.
- [ ] Rebuild and hardware-verify the explicit pointer/cache split diagnostics through the updated `xmm-vm-probe` suite: `p2.heap_info()` should report `pointer_window_bytes == 16777216`, `psram_block_base == 16777216`, `psram_block_bytes == 16777216`, and `main_inside_pointer_window == true`; `p2.psram_info()` should report matching `pointer_window_bytes`, `cache_base`, and `cache_bytes` values on the XMM Edge32 profile.
- [ ] Rebuild and hardware-verify the new native upper-PSRAM cache reservation API through `xmm-vm-probe`: `p2.psram_cache_reset()` should reset the reservation cursor, `p2.psram_cache_info()` should reserve the bottom of the upper 16 MiB block/cache window, stop before the existing top-1-MiB `libstore` source-cache convention, and support a `p2.psram_cache_reserve(64)` plus bounded `p2.psram_cache_write/read` round trip.
- [ ] Run deeper GC stress across the chunked XMM heap, including allocation/free cycles that cross segment boundaries.
- [ ] Repair the generic native `gc` module call path on XMM if the upstream-style `import gc` module is needed: enabling `BE_USE_GC_MODULE` made `import gc` work, but calling `gc.allocated()` wedged the REPL before the P2 module-entry trace printed. The P2-specific `p2.gc()` entrypoint is the working collector path for current XMM heap stress.
- [ ] Run `/tests/p2/smoke_xmm_heap.be` through the normal SD-backed `smoke_all` flow after the XMM SD test upload/filesystem path is repaired.
- [ ] Run a longer duration-based `xmm-heap-cross` soak, beyond the current verified two-iteration repeat, before treating external XMM heap GC as fully soaked.
- [ ] Continue proving GC correctness with XMM PSRAM-backed objects before enabling real-cog concurrent Berry VM execution by default.
- [ ] Preserve the current COMPACT Edge32 Hub-heap plus PSRAM block-cache image as the recovery fallback while XMM/cache work is experimental.
- [ ] Measure the actual largest stable XMM Berry heap arena size around the current chunked `15 MiB` target while preserving the upper block/cache window.
- [ ] Tune the final lower-XMM split between Berry VM heap and Catalina C allocator headroom: the capped build preserves the upper block/cache window and leaves a roughly `15.2 MiB` Berry heap, but `p2.c_allocator_test(262144)` now fails at the realloc stage because the C heap is intentionally capped below `16 MiB`.
- [ ] Use `p2.heap_info()` `vm_partition_*` capacity diagnostics to tune production per-VM heap partition sizing after the current independent child `bvm` partition prototype is rebuilt and reverified.
- [ ] Rework real-cog child VM execution with proper runtime isolation before enabling it by default: the first `p2.vm_cog_start(...)` prototype compiled and booted, but hardware smoke showed the REPL could not execute the next command after the child cog ran Berry VM code.
- [ ] Rework real-cog child VM execution beyond the Catalina hardware-lock guardrail: the opt-in `BE_P2_ENABLE_EXPERIMENTAL_VM_COG=1` diagnostic build still leaves the next REPL command with no output after `p2.vm_cog_start(...)`, so the remaining problem is likely Catalina/Berry runtime isolation, cog stack/runtime setup, VM ownership, or service/stdio state rather than a simple shared-section race.
- [ ] Investigate Catalina XMM C-cog startup before retrying Berry VM execution in another cog: the opt-in C-only `p2.vm_cog_ping(...)` diagnostic also leaves the next REPL command with no output, so `_cogstart_C` with the current XMM stack/runtime setup is not safe enough yet. Focus next on Hub/LUT stack placement, Catalina-supported thread/cog APIs, C runtime registration, and whether secondary C cogs can safely execute from the standalone XMM image.
- [ ] Investigate the proper Catalina XMM threading link/runtime path before using `_threadstart_C`: simply adding `-lthreads` through `CATALINA_MLIB` for the opt-in cog diagnostic emitted Catalina linker `ERROR:` lines for undefined thread symbols, so that path is not a valid diagnostic firmware yet.
- [ ] Verify the new Catalina build-log guard with an intentionally failing non-flash build before relying on it as a final safety gate for all future experimental profiles.
- [ ] Use the lower-XMM multiple-VM heap partition model as the foundation for real closure-per-cog execution.

## Immediate next steps

- [ ] Re-run the full scripted SD smoke suite against the provisioned P2 Edge 32 MB SD card after the latest XMM/cache changes are rebuilt.
- [ ] Keep `p2.fs_info("/")`, FAT sector-`2048` fallback, SD-backed `import math`, and `math.sqrt(81)` in the scripted regression path.
- [ ] Re-run SD test upload on the latest XMM image and repair only if the previous `/tests/p2/host_libstore_chunk.be` write failure still reproduces.
- [ ] Keep the existing no-external-RAM P2 Edge Catalina profile working while Edge32/XMM work continues.

## Architecture and documentation

The initial source research summary exists in `docs/source-research.md`. Keep refining it as deeper implementation choices need source-specific detail.

## Coverage tracking

The initial coverage matrix exists in `docs/coverage-matrix.md`. Keep expanding it as implementation evidence improves.

## Berry compatibility

- [ ] Verify and test all included/upstream Berry language features for this repository version.
- [ ] Verify and test all included/upstream Berry libraries and modules.
- [ ] Rebuild and hardware-verify the newly enabled native `introspect` module on P2 full/Edge32/XMM profiles, including the expanded `smoke_compat.be` coverage.
- [ ] Add coverage for `input`.
- [ ] Rebuild and hardware-verify the expanded finite `math` module surface on P2: `exp`, `log`, `log10`, `pow` with fractional/negative exponents, trig, inverse trig, and hyperbolic helpers.
- [ ] Add native-compatible `math.nan`, `math.inf`, and invalid-result behavior for the SD-loaded P2 `math` module without using Berry division-by-zero expressions that raise `divzero_error`.
- [ ] Run or adapt the upstream `tests/math.be` expectations for the P2 SD-loaded `math` module once `nan`/`inf` behavior is solved.
- [ ] Add coverage for any other included Berry modules in this repository/version.
- [ ] For each Berry module, add a normal test.
- [ ] For each Berry module, add an SD import test.
- [ ] For each Berry module, add a repeated import/cache test.
- [ ] For each relevant Berry module, add a PSRAM-cache import test.
- [ ] For each relevant Berry module, add a low-memory behavior test.

## SD layout and import system

- [ ] Support `/berry/main.be`.
- [ ] Support `/berry/lib/*.be`.
- [ ] Support `/berry/lib/*.bec`.
- [ ] Support `/berry/app/*.be`.
- [ ] Support `/berry/app/*.bec`.
- [ ] Support `/berry/cache/*.bec`.
- [ ] Support `/berry/config/*.json`.
- [ ] Support `/berry/examples/*`.
- [ ] Support `/berry/pasm/*`.
- [ ] Preserve native-module-first import resolution.
- [ ] Preserve current-directory import resolution.
- [ ] Add or verify configured `sys.path` import resolution.
- [ ] Prefer valid and newer `.bec` files over `.be`.
- [ ] Fall back to `.be` when `.bec` is missing, invalid, or stale.
- [ ] Add optional compile-to-cache behavior.
- [ ] Add or verify the global module cache.
- [ ] Preserve lazy loading.
- [ ] Use PSRAM-backed inactive module/cache storage where safe.

## PSRAM cache and memory model

- [ ] Use PSRAM aggressively as a cache/storage tier for inactive modules, bytecode, source cache, compiled cache, large buffers, and inactive data.
- [ ] Keep active VM heap, stacks, executing bytecode/pages, prototypes, and live GC-managed objects in safe VM memory.
- [ ] Stage active code/data from PSRAM into hub RAM only when needed.
- [ ] Do not store arbitrary live Berry GC objects in PSRAM unless safe pointer-like random access is proven by tests.
- [ ] Add low-memory behavior tests.
- [ ] Track hub RAM high-water marks.
- [ ] Track PSRAM usage.
- [ ] Add cache eviction behavior.
- [ ] Add source hash tracking.
- [ ] Add compiled hash tracking.
- [ ] Add module/cache metadata tracking.
- [ ] Replace the temporary native PSRAM cache bump cursor with coordinated cache metadata/ownership once module cache, large-buffer cache, and compiled-cache users share the same upper-PSRAM window.
- [ ] Replace the fixed-size native PSRAM cache reservation table with reusable/freeable cache records once eviction and ownership policies are implemented.
- [ ] Replace the temporary LIFO-only `p2.psram_cache_release(index)` policy with real free/reuse/eviction semantics when non-stack-like cache lifetimes are needed.
- [ ] Decide whether final native PSRAM cache users should use entry-index handles, named handles, or owner-scoped handles before wiring module bytecode/source caches to the table.
- [ ] Integrate the existing owner-scoped native PSRAM cache helper APIs into real module/source/bytecode users once the facade is rebuilt and hardware-verified.
- [ ] Decide whether final module/source/bytecode cache users should use the current LIFO-safe `p2mem.native_cache_replace(owner, data)` helper, keep stack-like owner history, or forbid repeated owner reservations.
- [ ] Add negative coverage for native PSRAM cache bounds: `p2.psram_cache_read/write` should reject lower-XMM addresses and the top-1-MiB `libstore` reserve.
- [ ] Add negative coverage for native PSRAM cache reservations: `p2.psram_cache_read/write` should reject addresses inside the native cache window that have not been reserved yet.
- [ ] Add capacity/error coverage for the fixed native PSRAM cache reservation table when more than 16 entries are requested.
- [ ] Add negative coverage for `p2.psram_cache_read_entry/write_entry`: invalid index, offset beyond entry size, and transfer crossing entry bounds.
- [ ] Add negative coverage for `p2.psram_cache_release(index)` when attempting to release a non-latest reservation.
- [ ] Add broader coverage for repeated owners in `p2.psram_cache_find(owner)` when more than two reservations share an owner tag.
- [ ] Add negative coverage for `p2mem.native_cache_replace(owner, data)` when the latest owner match is not the newest global cache reservation and therefore cannot be safely released by the LIFO policy.
- [ ] Add negative coverage for `p2mem.native_cache_release_owner(owner)` when the owner is missing or the latest owner match is not the newest global cache reservation.
- [ ] Add negative coverage for `p2mem.native_cache_release_owner_chain(owner)` when another owner has a newer reservation and blocks full owner-history pruning.
- [ ] Add module cache hit and miss counts.
- [ ] Add refcount or pinned-state tracking.
- [ ] Add last-used timestamp tracking where available.

## Diagnostics modules

- [ ] Add real compiled path/hash/mtime tracking to `p2mem` once `.bec` support exists.
- [ ] Add real module cache hit/miss, refcount, pinned, and last-used tracking to `p2mem`.
- [ ] Rebuild and verify `p2mem.native_cache()`, `p2mem.stats()["native_cache"]`, and `p2mem.cache()["native"]` on XMM after the native upper-PSRAM cache reservation table is compiled into the firmware and `/modules/p2mem.be` is available on SD.
- [ ] Rebuild and verify the `p2mem` native-cache facade helpers on XMM through the new `xmm-p2mem-native-cache` smoke suite: `native_cache_reset`, `native_cache_reserve`, `native_cache_find`, `native_cache_write`, `native_cache_read`, and `native_cache_release`.
- [ ] Rebuild and verify native PSRAM cache payload-size tracking and the `p2mem.native_cache_put/get` helpers on XMM through the `xmm-p2mem-native-cache` smoke suite.
- [ ] Rebuild and verify native PSRAM cache write metadata (`write_count`, `last_write_offset`, and `last_write_size`) on XMM through `xmm-vm-probe` and `xmm-p2mem-native-cache`.
- [ ] Rebuild and verify native PSRAM cache simple write checksums (`last_write_checksum`) on XMM through `xmm-vm-probe` and `xmm-p2mem-native-cache`.
- [ ] Rebuild and verify native PSRAM cache checksum read-back verification (`p2.psram_cache_verify_entry` and `p2mem.native_cache_verify_owner`) on XMM through `xmm-vm-probe` and `xmm-p2mem-native-cache`.
- [ ] Rebuild and verify `p2mem.native_cache_get_verified(owner)` on XMM through `xmm-p2mem-native-cache`.
- [ ] Rebuild and verify `p2mem.native_cache_status(owner)` on XMM through `xmm-p2mem-native-cache`.
- [ ] Rebuild and verify `p2mem.native_cache_put_verified(owner, data)` on XMM through `xmm-p2mem-native-cache`.
- [ ] Rebuild and verify `p2mem.native_cache_replace_verified(owner, data)` on XMM through `xmm-p2mem-native-cache`.
- [ ] Rebuild and verify source-namespaced native cache helpers (`native_source_put_verified`, `native_source_status`, `native_source_get_verified`, `native_source_release`) on XMM through `xmm-p2mem-native-cache`.
- [ ] Rebuild and verify module-source native cache helpers (`native_module_source_put_verified`, `native_module_source_status`, `native_module_source_get_verified`, `native_module_source_release`) on XMM through `xmm-p2mem-native-cache`.
- [ ] Rebuild and verify `p2mem.native_module_sources_plan(names)` on XMM through `xmm-p2mem-native-cache`.
- [ ] Add negative planning coverage where `p2mem.native_module_sources_plan(names)` reports `will_fit == false` because sources are missing or native cache free space is insufficient.
- [ ] Rebuild and verify aligned native-cache reservation accounting in `p2mem.native_module_sources_plan(names)` on XMM through `xmm-p2mem-native-cache`.
- [ ] Rebuild and verify `p2mem.native_module_sources_warm_verified(names)` on XMM through `xmm-p2mem-native-cache`.
- [ ] Rebuild and verify `p2mem.native_module_sources_warm_if_fits(names)` on XMM through `xmm-p2mem-native-cache`.
- [ ] Rebuild and verify `p2mem.native_module_sources_status(names)` and `p2mem.native_module_sources_release(names)` on XMM through `xmm-p2mem-native-cache`.
- [ ] Wire source-namespaced native cache helpers into actual module/source import caching only after the SD import path and native cache smoke suites are hardware-verified.
- [ ] Wire native PSRAM cache write metadata into real module/source/bytecode cache hit/miss accounting once those cache users exist.

## Low-level P2 native API

- [ ] Raise clear errors for unsupported build or board combinations.

## Smart pins and high-level wrappers

- [ ] Research and define constants for all relevant smart pin mode families.
- [ ] Cover normal/dumb pin mode.
- [ ] Cover repository mode.
- [ ] Cover DAC noise mode.
- [ ] Cover DAC random dither mode.
- [ ] Cover DAC PWM dither mode.
- [ ] Cover pulse/cycle output.
- [ ] Cover transition output.
- [ ] Cover NCO frequency output.
- [ ] Cover NCO duty output.
- [ ] Cover PWM triangle mode.
- [ ] Cover PWM sawtooth mode.
- [ ] Cover PWM SMPS mode.
- [ ] Cover quadrature encoder mode.
- [ ] Cover register up counter mode.
- [ ] Cover register up/down counter mode.
- [ ] Cover rise counting.
- [ ] Cover high counting.
- [ ] Cover state ticks.
- [ ] Cover high ticks.
- [ ] Cover event ticks.
- [ ] Cover period ticks.
- [ ] Cover period highs.
- [ ] Cover counter ticks.
- [ ] Cover counter highs.
- [ ] Cover counter periods.
- [ ] Cover ADC internal mode.
- [ ] Cover ADC external mode.
- [ ] Cover ADC scope/capture mode.
- [ ] Cover USB pin pair modes.
- [ ] Cover synchronous serial TX.
- [ ] Cover synchronous serial RX.
- [ ] Cover asynchronous serial TX.
- [ ] Cover asynchronous serial RX.
- [ ] Add high-level GPIO input/output classes.
- [ ] Add high-level PWM wrapper.
- [ ] Add high-level ADC wrapper.
- [ ] Add high-level DAC wrapper.
- [ ] Add high-level timer wrapper.
- [ ] Add high-level quadrature wrapper.
- [ ] Add high-level UART wrapper.
- [ ] Add high-level SPI/synchronous serial wrapper.
- [ ] Add high-level USB pair wrapper where possible.

## PASM2 and assembly integration

- [ ] Implement PASM blob loading.
- [ ] Implement PASM cog launching.
- [ ] Implement PASM function bridge.
- [ ] Consider optional inline assembler only if reasonable.
- [ ] Gate unsafe arbitrary assembly behind `BE_P2_ENABLE_UNSAFE_ASM`.

## Multicore Berry closures

- [ ] Build this on top of proven pointer-safe XMM PSRAM-backed independent VM heaps, not the archived Spin2/worker paths.
- [ ] Implement real closure-based cog spawning.
- [ ] Ensure `p2.cog.spawn(closure, ...args)` runs in another cog, not a fake worker queue.
- [ ] Host each cog Berry process in its own VM state, stack, heap, and GC model.
- [ ] Define safe sharing of read-only code, prototypes, and modules.
- [ ] Define mutable capture behavior.
- [ ] Add copy-by-value semantics or explicit rejection for non-serializable captures.
- [ ] Add explicit sharing through `p2.shared` if needed.
- [ ] Prevent blind native pointer transfer.
- [ ] Prevent blind file handle transfer.
- [ ] Add hardware resource manager behavior.
- [ ] Return parent handles.
- [ ] Propagate child return values to `join()`.
- [ ] Propagate child errors to `join()`.
- [ ] Make child VM cleanup deterministic.
- [ ] Implement `handle.id()`.
- [ ] Implement `handle.status()`.
- [ ] Implement `handle.join()`.
- [ ] Implement `handle.stop()`.
- [ ] Implement `handle.kill()`.
- [ ] Implement `handle.result()`.
- [ ] Implement `handle.error()`.
- [ ] Add stress tests for closure spawning and cleanup.

## IPC primitives

- [ ] Extend the current cooperative `p2ipc` helpers toward real cross-cog locks, hub-memory channels, mailboxes, and cog attention where appropriate.

## Cooperative task scheduler

- [ ] Keep the current `task`/`taskspin` compatibility layer as a source-level cooperative facade, and avoid expanding it as a substitute for real closure/cog VM work.
- [ ] Provide independent Berry call stacks or a proven safe coroutine/continuation mechanism.
- [ ] Do not implement this as simple callback polling.

## Debugging

- [ ] Add debug build mode.
- [ ] Implement `p2.debug.breakpoint()`.
- [ ] Implement `p2.debug.trace(true)`.
- [ ] Implement `p2.debug.stack()`.
- [ ] Implement `p2.debug.tasks()`.
- [ ] Implement `p2.debug.modules()`.
- [ ] Implement `p2.debug.locks()`.
- [ ] Implement `p2.debug.channels()`.
- [ ] Include Berry stack traces with source file/line where possible.
- [ ] Include native error info where possible.
- [ ] Include module cache stats.
- [ ] Include task state.
- [ ] Include lock state.
- [ ] Include channel/mailbox state.
- [ ] Consider PASM breakpoint/single-step/hardware debug support.

## Performance work

- [ ] Measure baseline Berry VM speed.
- [ ] Measure import latency from SD.
- [ ] Measure import latency from PSRAM cache.
- [ ] Measure hub RAM high-water mark.
- [ ] Measure PSRAM usage.
- [ ] Measure GC pause time.
- [ ] Measure cog spawn latency.
- [ ] Measure task switch latency.
- [ ] Measure channel latency.
- [ ] Measure smart-pin wrapper overhead.
- [ ] Measure native/PASM speedup.
- [ ] Measure video/streamer throughput if relevant.
- [ ] Measure SD read throughput.
- [ ] Measure PSRAM read/write throughput.
- [ ] Investigate LUT RAM tables for Berry bytecode dispatch.
- [ ] Investigate hot VM dispatch code in cog RAM.
- [ ] Investigate P2 custom-bytecode/execution features for Berry dispatch.
- [ ] Investigate CORDIC acceleration for Berry math.
- [ ] Investigate streamer acceleration for video/audio/buffer movement.
- [ ] Investigate smart pins for timing-heavy protocol offload.
- [ ] Prove PSRAM cache value with benchmarks before adding complicated acceleration.

## Tests

- [ ] Cover Berry standard libraries in host tests.
- [ ] Cover loader behavior using fake SD.
- [ ] Expand PSRAM cache behavior coverage using fake PSRAM beyond the current `libstore` chunked source-cache regression.
- [ ] Cover import cache behavior.
- [ ] Cover module eviction.
- [ ] Cover error paths.
- [ ] Cover closure serialization/copy rules.
- [ ] Expand host-simulatable task scheduler coverage beyond the current `task` and `taskspin` regressions.
- [ ] Cover boot on P2 hardware.
- [ ] Cover REPL or main program launch on P2 hardware.
- [ ] Cover SD mount on P2 hardware.
- [ ] Cover PSRAM detection on P2 hardware.
- [ ] Cover `.be` load from SD.
- [ ] Cover `.bec` load from SD/cache.
- [ ] Cover import of all standard Berry modules.
- [ ] Cover GPIO.
- [ ] Cover raw smart pin.
- [ ] Run `/tests/p2/smoke_p2_api.be` on P2 hardware through `make test-p2` or the existing smoke suite.
- [ ] Cover PWM.
- [ ] Cover ADC.
- [ ] Cover DAC.
- [ ] Cover UART loopback.
- [ ] Cover SPI/sync serial loopback where wired.
- [ ] Cover timer/counter.
- [ ] Cover CORDIC.
- [ ] Cover locks.
- [ ] Cover cog spawn.
- [ ] Cover cog join.
- [ ] Cover channel IPC.
- [ ] Cover cooperative task scheduler.
- [ ] Cover VGA/video demo if hardware is available.
- [ ] Cover USB keyboard/mouse if hardware is available.
- [ ] Cover PASM blob launcher.
- [ ] Soak-test imports.
- [ ] Soak-test module eviction.
- [ ] Soak-test GC.
- [ ] Soak-test SD usage.
- [ ] Soak-test PSRAM usage.
- [ ] Soak-test cog spawn/stop.
- [ ] Soak-test channels.
- [ ] Soak-test cooperative tasks.
- [ ] Soak-test GPIO/smart pins.
- [ ] Report memory leaks or failures.

## Examples

- [ ] Add `examples/adc_read.be`.
- [ ] Add `examples/dac_write.be`.
- [ ] Add `examples/pwm_fade.be`.
- [ ] Add `examples/uart_loopback.be`.
- [ ] Add `examples/spi_loopback.be`.
- [ ] Add `examples/quadrature_counter.be`.
- [ ] Add `examples/vga_test_pattern.be`.
- [ ] Add `examples/usb_keyboard_mouse.be`.
- [ ] Add `examples/cog_closure.be`.

## Acceptance criteria still open

- [ ] Firmware builds cleanly in the final target configuration.
- [ ] Firmware boots on the selected P2 board in the final target configuration.
- [ ] A Berry program can run from SD card.
- [ ] `.be` programs can be loaded from SD card.
- [ ] `.bec` files can be loaded when present.
- [ ] Berry imports are lazy.
- [ ] Inactive libraries/modules are cached or staged through PSRAM where safe.
- [ ] Hub RAM usage is measured and reported.
- [ ] All included Berry standard libraries are present or honestly documented.
- [ ] Berry standard libraries have tests.
- [ ] P2 low-level hardware functions equivalent to Catalina-style coverage are exposed or explicitly documented as unsupported.
- [ ] Raw smart pin access works.
- [ ] High-level wrappers exist for ADC, DAC, PWM, timers/counters, serial, quadrature, and USB building blocks where possible.
- [ ] VGA/video and USB keyboard/mouse have working demos or clear staged implementation notes.
- [ ] PASM blobs can be loaded and launched.
- [ ] A Berry closure can run in a new cog with its own VM or a clearly documented safe VM model.
- [ ] Multiple Berry VMs can run across multiple cogs.
- [ ] Inter-cog channel/mailbox communication works.
- [ ] Cooperative tasks work inside a cog with the requested Spin2-like API.
- [ ] Debug APIs report VM, memory, module, cog, task, and pin state.
- [ ] Tests cover every implemented API.
- [ ] Hardware tests are documented and runnable.
- [ ] Examples are included.
- [ ] No stub silently pretends to work.
- [ ] `docs/coverage-matrix.md` honestly shows remaining gaps.
