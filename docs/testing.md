# Testing

Interactive acceptance record updated: 2026-09-20. Broader test recipes below
retain their individual scope; this date does not certify a rerun of each suite.

This document describes the repeatable test entrypoints for the host Berry runtime and the Propeller 2 target.

For the short human-readable P2 status and recommended focused checks, start
with [port status](P2_PORT_STATUS.md). This file is the detailed test reference.

## Accepted interactive preview

The [2026-09-20 acceptance record](P2_INTERACTIVE_PREVIEW.md) binds the tested
RAM image to the implementation and distinguishes 127 checked actual-board UART
steps, the separate readiness check, native host tests and remote compilation.
The four-job [CI run at `6876481`](https://github.com/speccy88/berry/actions/runs/35543007587)
passed and uploaded its evidence; it does not execute a P2 board. Complete bench
receipts are retained separately, not installed with this checkout.

The doc-only closeout changes neither firmware nor test code and does not
reopen UART. Do not count the hardware/peripheral/flash commands later in this
reference as having run for this preview merely because they are documented.

## Host tests

Run only the P2-specific host regressions:

```sh
make test-p2-host
```

Run the desktop Berry language/runtime tests plus the P2-specific host regressions:

```sh
make test-host
```

Validate the normal no-PSRAM P2 build with the sibling Catalina install:

```sh
make p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
```

Run the non-hardware P2 baseline guards before larger P2 changes:

```sh
make p2-baseline-guards TOOLCHAIN=catalina CATALINA_DIR=../Catalina
```

This checks the Catalina build-log pipefail guard, Edge32/XMM profile
invariants, regenerated Catalina XMM `cx` SD objects/index entries, Catalina
warning classes, marked SD-writing smoke discipline, required P2 documentation
presence, source-module capability metadata contracts, user-facing example
local compilation/safety/final-marker contracts, focused P2 staging collision
checks, focused runner/staging alignment checks, and active
Catalina path policy including make usage strings without rebuilding firmware
or touching the board.

Check only the user-facing example syntax and current-image safety contract:

```sh
make p2-example-safety-audit
```

This also checks focused P2 smoke/example staging blocks in `mk/p2.mk` for
missing literal source files, focused example runner/staging mismatches, mapped
focused test-suite runner/staging mismatches, and direct P2 FAT 8.3 target-name
collisions. Files sharing a target directory must use explicit short
`--target-file` aliases when their long filenames would collide.

Check only the source-module metadata contracts:

```sh
make p2-source-module-metadata-audit
```

Check that the tracked P2 documentation set exists:

```sh
make p2-docs-audit
```

Check that active P2 docs/tooling continue to use the sibling Catalina checkout
and do not reintroduce containerized or stale cache-path Catalina references:

```sh
make p2-catalina-path-audit
```

`make test-p2-host` builds the host Berry binary with the existing sanitizer and
coverage flags, then runs these P2 host regressions:

- `tests/p2/host_libstore_chunk.be`
- `tests/p2/host_task.be`
- `tests/p2/host_p2ipc.be`
- `tests/p2/host_source_modules.be`
- `tests/p2/host_libstore_bec.be`
- `tests/p2/host_import_cache.be`
- `tests/p2/host_libstore_cache_errors.be`
- `tests/p2/host_p2mem_native_cache.be`
- `tests/p2/host_p2smart.be`

`make test-host` runs the normal desktop suite through `./testall.be` before
running `make test-p2-host`.

Current coverage:

- Standard desktop Berry tests under `tests/*.be`.
- Fake-PSRAM `libstore` chunked source-cache behavior.
- Host-simulatable `task` cooperative scheduler behavior, including capacity, pause/resume/stop, result-shaped start/stop/pause/resume diagnostics, task function error state, malformed wait descriptor containment, wait-object polling failure containment, timeout wakeups, invalid primitive inputs, and wait descriptors for semaphores, mutexes, queues, event flags, and timers.
- Host-simulatable `p2ipc` channel, mailbox, shared buffer, mutex, fallback-lock, lock-allocation-failure, blocked-lock, default-depth, invalid-depth, buffer snapshot, invalid buffer input behavior, IPC `info()` diagnostics, idempotent close/closed-state behavior, and result-shaped channel/mailbox/buffer/mutex diagnostics that distinguish valid `nil` payloads from empty/full/busy/not-locked/closed/error states.
- Host-simulatable `binary_heap`, `p2compat`, and `configstore` source-module behavior, including `binary_heap.sort()` empty/singleton behavior and caller-array preservation when a comparator raises, `p2compat.status_report()` diagnostics, `configstore.load_result()` missing, valid, JSON `null`, malformed JSON, and invalid-name diagnostics, `configstore.save_result()` success and invalid-name diagnostics, `configstore.remove_result()` missing, successful, and invalid-name diagnostics, and `configstore.list_result()` present-root and missing-root diagnostics.
- Host-simulatable `.bec` manifest, freshness, source fallback, invalid module-name diagnostics, and compile-cache planning behavior.
- Host-simulatable SD-style import roots, root ordering, dotted package lookup, missing-import recovery, import cache identity, source metadata, inventory snapshot isolation, and `libstore.path_remove()` behavior.
- Host-simulatable `libstore` source-cache no-op and error paths for disabled policy, unavailable PSRAM, invalid module names, missing modules, invalid transfer size, over-capacity, failed writes, short writes, failed reads, short reads, recovery after errors, cache-report snapshot isolation, cache-report visibility for cached entries whose source disappeared, and reset/recache behavior after source changes.
- Host-simulatable constrained bulk source-cache behavior, including `cache_all_report()` skipped-module reporting when one module is too large for the current fake-PSRAM window and `cache_many_report()` selected-list reporting for cached, oversized, missing, and invalid module names.
- Host-simulatable `p2mem` stats/module/cache/gc/evict diagnostics snapshot isolation over the fake-PSRAM source-cache path.
- Host-simulatable `p2mem` native-cache facade behavior for reset/get result wrappers, owner lookup/history failures, LIFO release, result wrappers for invalid reservations, invalid payloads, invalid indexes and ranges, owner-level status/get/verify/release failures, verified put/replace verify exceptions, put/get/verify, write-failure and verify-failure cleanup, non-destructive replace preserving older payloads, source owners, single and bulk module-source invalid-name diagnostics including path-escape rejection, invalid `p2mem.module()` lookup handling, module-source warm/status/release planning including native-cache-unavailable diagnostics, and failed batch-warm rollback.
- Host-simulatable `p2smart` wrapper behavior for GPIO input/output, counter, repository, PWM, NCO, pulse/cycle, transition, ADC, DAC, async serial-pair setup, and sync serial-pair setup/receive-result helpers over a fake `p2.smart`/`p2.pin` backend, including generated native-call sequences and invalid argument diagnostics.

Still open:

- Fake SD loader behavior beyond the current file-backed module tests.
- Native C PSRAM cache bounds/release errors, closure serialization/copy rules, and broader low-memory behavior.

## P2 hardware tests

Provision the SD card and run the full on-target P2 smoke suite:

```sh
make test-p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0 BOARD=p2edge
```

For the P2 Edge 32 MB RAM board, select the Edge32 suite:

```sh
make test-p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0 BOARD=p2edge32
```

When the board has loopback jumpers between pins `0-1`, `2-3`, `4-5`, and
`6-7`, run the dedicated smart-pin hardware suite:

```sh
python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --suite smartpins-loopback
```

For the staged synchronous-serial diagnostic only, use the narrower suite:

```sh
python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --suite smartpins-sync-diag
```

On `/dev/ttyUSB0`, this suite has passed on the flashed Catalina XMM image
with jumpers `0-1`, `2-3`, `4-5`, and `6-7`; current focused XMM verification
uses image `1168384 / 16777216` bytes.
It covers `p2smart` GPIO wrappers both directions, raw smart-pin helpers, repository-mode calls,
PWM/NCO/pulse/transition output into rise counters, GPIO-driven high-counter
loopback, DAC-output to ADC-input setup/readback, async TX/RX setup/send/query/ack,
and negative raw-helper diagnostics. The focused
`/tests/p2/smoke_smartpins_async_rx.be` smoke separately proves async
`read_byte()` plus wrapper cleanup on jumper pairs `0-1`, `2-3`, `4-5`, and
`6-7` in both directions for `0x00`, `0x55`, `0xa5`, and `0xff`; the `0x00`
case uses `read_byte_after(2000)` because readiness remains ambiguous for a
zero event value. Zero-byte readiness/event semantics, buffering, and calibrated
ADC/DAC low/high-delta assertions remain open.
The focused `/tests/p2/smoke_smartpins_sync_diag.be` smoke covers the
sync-serial result-map shape plus bounded matched clocked receive checks on the
documented `0-1` data and `2-3` clock jumpers. Broader SPI framing remains
open.

The authoritative wiring and skip notes for this harness live in
`docs/hardware-tests.md`: current smart-pin tests use short direct jumpers
`0-1`, `2-3`, `4-5`, and `6-7`, no series resistors for the digital loopbacks,
the current Catalina XMM P2 Edge 32 MB profile on `/dev/ttyUSB0`, verified
focused raw ADC/DAC movement, NCO-duty high-time movement, and sync-serial
clocked receive checks, plus explicit diagnostic-only status for ADC/DAC
calibration, mechanical quadrature encoder behavior, USB/HID, and VGA.

`make test-p2` does two things:

- Uploads `modules/` to `/modules` and `tests/p2/` to `/tests/p2` through the running Berry REPL using `make p2-sd-sync`.
- Runs `scripts/p2/repl_smoke.py` against the selected suite.

Suite selection:

- `BOARD=p2edge` runs the existing full suite, equivalent to `p2-smoke`.
- `BOARD=p2edge32` runs the Edge32 suite, equivalent to `p2-smoke-edge32`.

The full suite includes `/tests/p2/smoke_p2_api.be`, so the grouped P2 clock,
cog, lock, pin, CORDIC/math, RNG, debug, ASM, and smart-pin API smoke runs with
the main SD umbrella after the card has been staged.

The target must already be running Berry at the REPL prompt. Build/flash commands are still separate because board boot mode and flash/RAM choice are hardware-setup decisions.

## P2 smoke suites

Existing direct smoke commands remain available:

```sh
export PORT=/dev/ttyUSB0
export TOOLCHAIN=catalina
export CATALINA_DIR=../Catalina

make p2-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-quick TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-edge32 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-examples-quick TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-examples-bus TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-examples-serial TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-examples-smartpin-diagnostics TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-examples-system TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-examples-runtime TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-examples-debug TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-examples-p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-examples-unsupported TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-examples-core TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-pasm-layout TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-pasm-policy-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-p2-api TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-p2compat TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-libraries-lazy-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-p2mem-native-cache-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-bec-fallback-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-bec-abi-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-core-builtins-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-stdlib-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-sd-file-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-cog-closure TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-cog-policy-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-task TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-task-policy-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-ipc TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-ipc-policy-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-debug-capabilities-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-priority1 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-priority1-staged TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-priority2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-priority2-staged TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-priority3 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-priority3-staged TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-priority4 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-priority1-4 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-priority1-4-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-priority1-4-min-staged TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-priority1-4-staged TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins-focused TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins-loopback TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins-normal-pin TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins-quadrature-static TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins-quadrature-motion TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins-quadrature-diag TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins-counter-modes TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins-counter-timer-matrix TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins-output-modes TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins-adc-dac-native TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins-adc-variant-matrix TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins-adc-dac-diag TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins-nco-duty-diag TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins-async-rx TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins-async-buffer-boundary TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-smoke-smartpins-sync-diag TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
```

The focused PASM target defaults to `P2_FOCUSED_SMOKE_TIMEOUT=300` and
`P2_FOCUSED_SMOKE_STARTUP_TIMEOUT=120`. It uploads only
`modules/libstore.be` and `tests/p2/smoke_pasm_layout.be` as the 8.3-safe
`/tests/p2/pasmly.be` alias before running, instead of doing a full SD sync.
Use `p2-smoke-pasm-policy-min` when only the current PASM policy contract needs
hardware evidence; it uploads only the policy smoke as `/tests/p2/pasmpol.be`
and skips staged PASM blobs.
The focused grouped P2 API target uses the same timeout defaults and uploads
only `tests/p2/smoke_p2_api.be` before running the `p2-api` suite.
The focused p2compat target uses the same timeout defaults, uploads
`modules/p2compat.be`, `tests/p2/smoke_p2compat.be`, and the 8.3-safe
`tests/p2/p2compvm.be`, then runs short native metadata probes, the source
p2compat policy smoke, and the child-VM smoke through the `p2compat` suite.
`modules/p2compat.be` avoids current-image-unsafe line-start `for` / `try` /
`except` syntax so this source policy leg is safe for the normal XMM hardware
path.
The focused quick-example target stages only the board LED blink plus native
GPIO, PWM, ADC, DAC, NCO-to-counter, and quadrature-counter examples under
`/berry/examples`, then runs those seven final markers through the
`examples-quick` REPL suite. It
intentionally avoids the broad example set and the large `p2smart` wrapper
diagnostic.
The focused bus-example target stages only `examples/i2c/scan.be` and
`examples/spi/jedec.be` under `/berry/examples/i2c` and `/berry/examples/spi`,
then runs their final markers through the `examples-bus` REPL suite. Use it
when the BMP180 I2C harness and SPI diagnostic pins are present and you want
normal bus example evidence without syncing every example.
The focused serial-example target stages only `uart_loopback.be` and
`sync_serial_loopback.be`, then runs their final markers through the
`examples-serial` REPL suite. It assumes the documented `0-1` async data jumper
and `0-1` data plus `2-3` clock jumpers for synchronous serial, and avoids the
larger `p2smart` wrapper.
The focused smart-pin diagnostics example target stages only
`smartpin_diagnostics.be`, then runs its final marker through the
`examples-smartpin-diagnostics` REPL suite. It assumes direct jumpers `0-1`,
`2-3`, `4-5`, and `6-7`, uses native `p2.smart` directly, and keeps this
broader four-pair diagnostic out of the quick example target.
The focused system-example target stages only `cordic_demo.be`,
`psram_cache_stats.be`, `repl_sd.be`, `file_sd.be`, and `json_sd.be`, then runs
their final markers through the `examples-system` REPL suite. It covers native
math/CORDIC, read-only PSRAM/cache stats, read-only SD layout diagnostics, and
two tiny cleanup-oriented SD write examples without uploading the broad example
tree.
The focused runtime-example target stages only `task_scheduler.be`,
`task_primitives.be`, `cog_closure.be`, `cog_closure_blink.be`, and
`pasm_direct.be`, then runs
their final markers through the `examples-runtime` REPL suite. It covers native
task scheduling, native task primitives, scalar closure-cog metadata/cleanup,
native-blink cog cleanup, and safe PASM fixture calls without running broad
task/PASM regressions. The two closure example files are staged as short
`cogclo.be` and `cogblk.be` aliases inside the target to avoid P2 FAT 8.3 name
collisions. Keep p2ipc-heavy examples on `p2-smoke-ipc` or direct one-off runs;
a combined example target that staged `modules/p2ipc.be` was too slow to be
useful as a routine example path.
The focused debug-example target stages only `debug_report.be`, then runs its
final marker through the `examples-debug` REPL suite. The example uses native
`p2.debug`, filesystem, and PSRAM diagnostics directly, so it avoids the large
`p2mem` source-module upload path.
The focused P2 helper-example target stages only the bounded legacy
`examples/p2/` helper files, then runs the `examples-p2` REPL suite. It covers
LED blink, pin helpers, smart-pin helper metadata, timing helpers, scalar
hardware helper diagnostics, native-blink closure cleanup, and the source-cog
unsupported-policy example without syncing the broad example tree.
The focused unsupported-example target stages current `modules/p2compat.be`
plus only `vga_test_pattern.be` and `usb_keyboard_mouse.be`, then runs the
`examples-unsupported` REPL suite. It verifies those examples report backed
unsupported VGA/USB capability records instead of faking hardware behavior.
The focused core-example target stages only `examples/core` under
`/berry/examples/core`, then runs the `examples-core` REPL suite. It covers the
bounded run-file, directory listing, loop, recursion, floating-point, JSON,
closure, sort, lambda, tree, string, string-format, exception-boundary, guess
number, and mini-REPL examples, including scripted input for the interactive
examples.
The focused WiFi-example target stages only `modules/wifi.be` and
`examples/wifi/detect.be`, then runs the metadata-only `examples-wifi` REPL
suite. It does not call `wifi.init()` or start SPI transactions. If this target
stalls or becomes unreliable on a given image, do not keep retrying it during
routine first-four-priority work; record the failed attempt and put the time
into the other focused example or priority targets. The current normal-XMM
attempt on `/dev/ttyUSB0` uploaded both files and reached the REPL prompt, but
the run produced no `wifi detect done` marker before it was interrupted, so it
is intentionally kept out of the common routine command list.
The focused Priority 1 minimal targets cover lazy source loading and `.bec`
source-fallback policy without invoking the broader import/cache/churn suites.
Do not use `p2-smoke-p2mem-policy-min` as a routine source-load proof on the
current normal XMM image: the latest focused attempt uploaded `libstore.be` and
`p2mem.be`, reached the REPL, then timed out while source-loading `p2mem`.
Keep `p2mem.memory_pressure_policy()` host/queryable coverage for now, and move
routine hardware effort to native-only PSRAM/runtime probes unless explicitly
working on `p2mem` source-load performance.
Use `p2-smoke-p2mem-native-cache-min` when only the native upper-PSRAM cache
wrapper path needs a small reset, verified put, verified get, and entry-count
hardware check.
Use `p2-smoke-core-builtins-min` when the board only needs the core
built-in/function/list/map/bytes smoke slice instead of the full SD smoke suite;
it uploads 8.3-safe aliases for those smoke files and then runs that focused
suite.
Use `p2-smoke-sd-file-min` when only SD-backed `open()`, `os`, and `os.path`
behavior need hardware evidence; it uploads only `tests/p2/smoke_sd.be` and
runs the single `sd-file-min` suite instead of the full SD smoke suite.
Use `p2-smoke-sd-file-core-min` for the routine Priority 1 SD/file slice: it
uploads only `tests/p2/smoke_sd_min.be` and verifies mount metadata, common
file modes, path helpers, directory create/chdir/remove, rename, and cleanup
without line-start `for` / `try` / `except` syntax.
The focused closure-cog target uses the same timeout defaults and uploads only
`tests/p2/smoke_cog_closure.be` before running the `cog-closure` suite.
Use `p2-smoke-cog-closure-min` for routine Priority 4 progress: it uploads
only `tests/p2/smoke_cog_closure_min.be` and verifies the native-blink handle,
join/result/error, kill cleanup, and empty-registry path without the heavier
closure regression probes.
Use `p2-smoke-cog-policy-min` when only native handle metadata, join/result
policy, and cleanup policy need hardware evidence without spawning closure
cogs.
The broader task source-module target uploads `modules/task.be` plus
`tests/p2/smoke_task.be` before running the source-module `task` suite. It is
non-default regression coverage; the current large source module is not the
routine hardware path and may exceed practical source-load time on the normal
XMM image.
Use `p2-smoke-task-policy-min` when only the native imported task backend needs
a quick P2 sanity check. It does not upload or source-load `modules/task.be`,
and it covers native metadata plus `spin`, fixed-slot startup, `halt`/`cont`,
`chk`, `id`, and native result-shaped lifecycle/scheduler diagnostics.
The focused IPC target also uses the focused timeout defaults, uploads only
`modules/p2ipc.be`, and then runs compact direct REPL probes for metadata,
payload copyability, one channel path, one mailbox path, buffer clear, and
mutex lock/unlock/close. The broader `tests/p2/smoke_p2ipc.be` remains
non-default broad regression coverage; keep normal progress work on the direct
focused target.
Use `p2-smoke-ipc-policy-min` when only the current-VM IPC contract,
task-wait integration flag, bounded-attention policy, payload-result
capability, and audit status need hardware evidence.
`scripts/p2/repl_smoke.py` fails a command if the REPL returns an uncaught Berry
error or stack traceback, even when a custom command has no explicit `--expect`
substring.
When repeating `--command`, repeated positional options such as `--expect`,
`--input-marker`, and `--input-text` must have the same count as `--command`.
Use an empty string for setup commands that do not need one, so an expected
marker cannot accidentally attach to the wrong REPL line.
For focused custom REPL commands that prompt for one input line, pass the prompt
substring and response alongside the command:

```sh
python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 \
  --command 'run_file("/berry/examples/core/guess_number.be")' \
  --expect 'guess number demo done' \
  --input-marker 'enter the number you guessed:' \
  --input-text '42'
```

The aggregate `p2-smoke-priority4` target runs the focused p2compat
VM-boundary, minimal closure-cog, native task-policy, and compact IPC behavior
targets in order.
If the files are already staged on the SD card, the same sequence can be run
directly with `scripts/p2/repl_smoke.py --suite priority4`.
`p2-smoke-priority1` is the quick Priority 1 health path. It runs short inline
core built-in, collection, and one-line SD file checks, then stages only the
small `smoke_sd_min.be` and `smoke_stdlib_min.be` files for focused SD/file and
normal-image standard-library coverage, without uploading the large
source-module set. When the SD card already has `/modules` and
`/tests/p2`, `p2-smoke-priority1-staged` runs the broader direct Priority 1
import/cache/churn and library suite without a make upload step. The same
already-staged checks can be run individually through the serial runner:

```sh
python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --suite import-cache
python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --suite import-churn
python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --suite libraries
python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --suite priority1
```

When the board has the documented smart-pin jumpers,
`p2-smoke-priority2` refreshes the grouped P2 API and smart-pin smoke files,
then runs grouped low-level P2 API coverage plus the focused native/current-file
normal-pin, counter-modes, output-modes, native ADC/DAC sample-shape,
quadrature-motion, async RX, and sync diagnostic suites. If the SD card is
already staged, `p2-smoke-priority2-staged` runs the
same focused serial aggregate without a make upload step. The direct serial
equivalent is:

```sh
python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --suite priority2
```

`p2-smoke-priority3` refreshes `modules/libstore.be`, `/tests/p2/pasmly.be`,
and `/tests/p2/pasmpol.be`, then runs the PASM layout plus policy smoke. If the
SD card is already staged, `p2-smoke-priority3-staged` runs the same serial
aggregate without a make upload step. The long source filenames collide on the
target FAT view, so use those aliases for staged Priority 3 checks. The direct
serial equivalent is:

```sh
python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --suite priority3
```

When the documented smart-pin jumpers are installed,
`p2-smoke-priority1-4` composes the focused Priority 1, 2, 3, and 4 make
targets in order. It is the normal named entrypoint when checking all four
priority areas without invoking broad staged regressions.
`p2-smoke-priority1-4-min` uploads only the focused dependencies
`modules/libstore.be`, `modules/p2ipc.be`,
`tests/p2/smoke_sd_min.be`, `tests/p2/smoke_stdlib_min.be`, and
`tests/p2/smoke_libraries_lazy_min.be`, then runs the routine minimal
first-four-priority checks. If the upload-capable path stalls or corrupts a
large source-module upload, stop after one focused attempt, repair the staged
file if needed, and use the already-staged runner path for current evidence
instead of spending routine priority time retrying the same slow upload. When the SD card is already staged,
`p2-smoke-priority1-4-min-staged` runs the same checks without a make upload
step. The broader `p2-smoke-priority1-4-staged` remains available for
occasional already-staged regression coverage across import churn, full
libraries, broader smart pins, PASM layout, and Priority 4.
The direct serial equivalent is:

```sh
python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --suite priority1-4-min
```

The routine `p2-smoke-smartpins-focused` target runs the native/current-file
normal-pin, counter-modes, output-modes, native ADC/DAC sample-shape,
quadrature-motion, async RX, and sync diagnostic targets in order.
`p2-smoke-priority2` uses this focused aggregate after the grouped P2 API smoke
so normal progress does not source-load the large
`p2smart.be` wrapper. The broader `p2-smoke-smartpins` target still includes
`p2-smoke-smartpins-loopback` for occasional full wrapper-loopback regression
coverage. The focused smart-pin make targets default to
`P2_SMARTPINS_TIMEOUT=300` and `P2_SMARTPINS_STARTUP_TIMEOUT=120`; override
those for slower boards.
`p2-smoke-smartpins-normal-pin` stages only
`tests/p2/smoke_smartpins_normal_pin.be` and uses native `p2.smart` directly
to verify normal-mode high/low loopback on the documented `0-1` jumper.
`p2-smoke-smartpins-counter-timer-matrix` stages only
`tests/p2/smoke_smartpins_counter_timer_matrix.be` and runs the native
selected-input timer matrix. It is an on-demand diagnostic, not part of the
routine focused aggregate.
`p2-smoke-smartpins-adc-dac-diag` stages `modules/p2smart.be`, then runs only
the ADC/DAC policy plus one sampled `0-1` observation. It prints the measured
delta fields but does not require calibrated voltage, stable polarity, or
nonzero threshold behavior.
`p2-smoke-smartpins-adc-variant-matrix` stages only
`tests/p2/smoke_smartpins_adc_variant_matrix.be` and runs the native `p2.smart`
ADC variant matrix. It is an on-demand diagnostic, not part of the routine
focused aggregate.
`p2-smoke-smartpins-quadrature-diag` stages `modules/p2smart.be`, then runs one
static quadrature sample on jumper `0-1`. It prints before/after/delta/
direction/moved fields without claiming movement.
`p2-smoke-smartpins-quadrature-motion` drives pins `0` and `2` through the
`0-1` and `2-3` jumpers into quadrature inputs `1` and `3`, then verifies
synthetic forward and reverse direction using native `p2.smart` directly. It
does not require `modules/p2smart.be` or a mechanical encoder.
`p2-smoke-smartpins-nco-duty-diag` stages `modules/p2smart.be`, then runs one
NCO-duty-to-counter observation on jumper `0-1`. It prints the counter delta
but does not claim waveform-shape validation.
`p2-smoke-smartpins-async-buffer-boundary` stages only
`tests/p2/smoke_smartpins_async_buffer_boundary.be` and runs a native
`p2.smart` UART boundary check on jumper `0->1`. It proves paced byte readback
for `0x11`, `0x22`, `0x33`, and `0x44`, then records the unpaced burst behavior
where the sampled value is the latest byte and the bounded drain does not prove
a background FIFO. It is an on-demand diagnostic, not part of the routine
focused aggregate.
`p2-smoke-smartpins-sync-diag` stages only
`tests/p2/smoke_smartpins_sync_diag.be` before running the bounded native
`p2.smart` sync policy and clocked-probe diagnostic.

The on-target smoke files live under `tests/p2/` and are intended to be present on the SD card at `/tests/p2`.

## P2 soak tests

Run the default soak suite repeatedly for a duration:

```sh
make soak-p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0 BOARD=p2edge32 HOURS=1
```

`soak-p2` reuses the same serial smoke runner with duration-based repetition.
By default it runs `SOAK_P2_SUITE=soak`, which repeats import/cache,
bounded import churn plus GC, library behavior, cooperative task coverage,
closure-based cog spawn/stop, and grouped P2 API coverage.
Soak runs default to `SOAK_P2_TIMEOUT=700` and
`SOAK_P2_STARTUP_TIMEOUT=120`; override those make variables for slower or
faster board setups.

The grouped P2 API smoke has passed on `/dev/ttyUSB0` with the flashed Catalina
XMM image. Current focused XMM verification uses image `1168384 / 16777216`
bytes:

```sh
python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 \
  --command 'run_file("/tests/p2/smoke_p2_api.be")' \
  --expect 'P2_SMOKE_PASS p2_api' --timeout 180
```

For the smart-pin loopback wiring on pins `0-1`, `2-3`, `4-5`, and `6-7`,
prefer the focused wired-board soak suite for routine longer runs. It uses the
native/current-file normal-pin, counter-modes, output-modes, native ADC/DAC
sample-shape, quadrature-motion, async RX, and sync diagnostic smokes without
source-loading the large smart-pin wrapper:

```sh
make soak-p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0 BOARD=p2edge32 HOURS=1 SOAK_P2_SUITE=soak-smartpins-focused
```

Use the broader wired-board regression suite when you explicitly want the main
wrapper-loopback smoke as well:

```sh
make soak-p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0 BOARD=p2edge32 HOURS=1 SOAK_P2_SUITE=soak-smartpins
```

Still open for soak coverage:

- Explicit repeated module eviction.
- Explicit channel stress.
- ADC/DAC calibrated voltage/delta stress and remaining smart-pin mode-family
  stress beyond the current raw helper, GPIO loopback, repository,
  PWM/NCO/pulse/transition-to-counter, high-counter loopback, ADC/DAC
  setup/readback, native ADC/DAC sampled-shape, and async RX byte-readback
  smoke, plus broader SPI framing stress beyond the current bounded
  sync-serial receive checks.
- Leak reporting and long-run memory accounting.
