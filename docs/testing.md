# Testing

Date: 2026-06-06

This document describes the repeatable test entrypoints for the host Berry runtime and the Propeller 2 target.

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
presence, source-module capability metadata contracts, and active Catalina path
policy without rebuilding firmware or touching the board.

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
- Host-simulatable `p2smart` wrapper behavior for GPIO input/output, counter, repository, PWM, NCO, pulse/cycle, transition, ADC, DAC, async serial-pair setup, and staged sync serial-pair setup over a fake `p2.smart`/`p2.pin` backend, including generated native-call sequences and invalid argument diagnostics.

Still open:

- Fake SD loader behavior beyond the current file-backed module tests.
- Native C PSRAM cache bounds/release errors, closure serialization/copy rules, and broader low-memory behavior.

## P2 hardware tests

Provision the SD card and run the full on-target P2 smoke suite:

```sh
make test-p2 PORT=/dev/ttyUSB0 BOARD=p2edge
```

For the P2 Edge 32 MB RAM board, select the Edge32 suite:

```sh
make test-p2 PORT=/dev/cu.usbserial-P97cvdxp BOARD=p2edge32
```

When the board has loopback jumpers between pins `0-1`, `2-3`, `4-5`, and
`6-7`, run the dedicated smart-pin hardware suite:

```sh
python3 scripts/p2/repl_smoke.py --port /dev/cu.usbserial-P97cvdxp --suite smartpins-loopback
```

For the staged synchronous-serial diagnostic only, use the narrower suite:

```sh
python3 scripts/p2/repl_smoke.py --port /dev/cu.usbserial-P97cvdxp --suite smartpins-sync-diag
```

On `/dev/ttyUSB0`, this suite has passed on the flashed Catalina XMM image
`959808 / 16777216` bytes with jumpers `0-1`, `2-3`, `4-5`, and `6-7`.
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
The focused `/tests/p2/smoke_smartpins_sync_diag.be` smoke covers the staged
sync-serial result-map shape and default four-pin clocked diagnostic groups
without claiming received-data validation.

The authoritative wiring and skip notes for this harness live in
`docs/hardware-tests.md`: current smart-pin tests use short direct jumpers
`0-1`, `2-3`, `4-5`, and `6-7`, no series resistors for the digital loopbacks,
the current Catalina XMM P2 Edge 32 MB profile on `/dev/ttyUSB0`, and explicit
diagnostic-only status for ADC/DAC calibration, NCO-duty waveform validation,
mechanical quadrature encoder behavior, sync-serial received words, USB/HID,
and VGA.

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
make p2-smoke PORT=/dev/ttyUSB0
make p2-smoke-quick PORT=/dev/ttyUSB0
make p2-smoke-edge32 PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-pasm-layout PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-pasm-policy-min PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-p2-api PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-p2compat PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-libraries-lazy-min PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-p2mem-policy-min PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-p2mem-native-cache-min PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-bec-fallback-min PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-core-builtins-min PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-sd-file-min PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-cog-closure PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-cog-policy-min PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-task PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-task-policy-min PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-ipc PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-ipc-policy-min PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-priority1-staged PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-priority2-staged PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-priority3-staged PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-priority4 PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-priority1-4-staged PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-smartpins PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-smartpins-loopback PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-smartpins-normal-pin PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-smartpins-quadrature-static PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-smartpins-quadrature-motion PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-smartpins-quadrature-diag PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-smartpins-counter-modes PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-smartpins-adc-dac-diag PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-smartpins-nco-duty-diag PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-smartpins-async-rx PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-smartpins-sync-diag PORT=/dev/cu.usbserial-P97cvdxp
```

The focused PASM target defaults to `P2_FOCUSED_SMOKE_TIMEOUT=300` and
`P2_FOCUSED_SMOKE_STARTUP_TIMEOUT=120`. It uploads only
`modules/libstore.be` and `tests/p2/smoke_pasm_layout.be` before running,
instead of doing a full SD sync.
Use `p2-smoke-pasm-policy-min` when only the current PASM policy contract needs
hardware evidence; it uploads only the policy smoke and skips staged PASM blobs.
The focused grouped P2 API target uses the same timeout defaults and uploads
only `tests/p2/smoke_p2_api.be` before running the `p2-api` suite.
The focused p2compat target uses the same timeout defaults and uploads only
`modules/p2compat.be` plus `tests/p2/smoke_p2compat.be` before running the
`p2compat` suite.
The focused Priority 1 minimal targets cover lazy source loading and `.bec`
source-fallback policy without invoking the broader import/cache/churn suites.
Use `p2-smoke-p2mem-policy-min` when only `p2mem` capability metadata, audit
status, and bounded GC-result diagnostics need hardware evidence.
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
The focused closure-cog target uses the same timeout defaults and uploads only
`tests/p2/smoke_cog_closure.be` before running the `cog-closure` suite.
Use `p2-smoke-cog-policy-min` when only native handle metadata, join/result
policy, and cleanup policy need hardware evidence without spawning closure
cogs.
The focused task target uses the same focused timeout defaults and uploads only
`modules/task.be` plus `tests/p2/smoke_task.be` before running the `task`
suite.
Use `p2-smoke-task-policy-min` when only the source-level scheduler backend,
scheduler policy, and task audit status need hardware evidence.
The focused IPC target also uses the focused timeout defaults and uploads only
`modules/p2ipc.be` plus `tests/p2/smoke_p2ipc.be` before running the `p2ipc`
suite.
Use `p2-smoke-ipc-policy-min` when only the current-VM IPC contract,
task-wait integration flag, bounded-attention policy, and audit status need
hardware evidence.
`scripts/p2/repl_smoke.py` fails a command if the REPL returns an uncaught Berry
error or stack traceback, even when a custom command has no explicit `--expect`
substring.
The aggregate `p2-smoke-priority4` target runs the focused p2compat
VM-boundary, closure-cog, task, and IPC targets in order. If the files are
already staged on the SD card, the same sequence can be run directly with
`scripts/p2/repl_smoke.py --suite priority4`.
When the SD card already has `/modules` and `/tests/p2`,
`p2-smoke-priority1-staged` runs the direct Priority 1 import/cache/churn and
library suite without a make upload step. The same already-staged checks can be
run individually through the serial runner:

```sh
python3 scripts/p2/repl_smoke.py --port /dev/cu.usbserial-P97cvdxp --suite import-cache
python3 scripts/p2/repl_smoke.py --port /dev/cu.usbserial-P97cvdxp --suite import-churn
python3 scripts/p2/repl_smoke.py --port /dev/cu.usbserial-P97cvdxp --suite libraries
python3 scripts/p2/repl_smoke.py --port /dev/cu.usbserial-P97cvdxp --suite priority1
```

When the SD card is already staged and the board has the documented smart-pin
jumpers, `p2-smoke-priority2-staged` runs grouped low-level P2 API coverage plus
the focused smart-pin loopback, counter-modes, async RX, and sync diagnostic
suites without a make upload step. The direct serial equivalent is:

```sh
python3 scripts/p2/repl_smoke.py --port /dev/cu.usbserial-P97cvdxp --suite priority2
```

When the SD card already has `modules/libstore.be` and
`/tests/p2/smoke_pasm_layout.be`, `p2-smoke-priority3-staged` runs the PASM
layout and marker-fixture contract smoke without a make upload step. The direct
serial equivalent is:

```sh
python3 scripts/p2/repl_smoke.py --port /dev/cu.usbserial-P97cvdxp --suite priority3
```

When the SD card is already staged for the first four priority areas and the
documented smart-pin jumpers are installed, `p2-smoke-priority1-4-staged` runs
Priority 1 import/library coverage, Priority 2 low-level P2 and smart-pin
coverage, Priority 3 PASM layout coverage, and Priority 4 closure/task/IPC
coverage without a make upload step. The direct serial equivalent is:

```sh
python3 scripts/p2/repl_smoke.py --port /dev/cu.usbserial-P97cvdxp --suite priority1-4
```

The aggregate `p2-smoke-smartpins` target runs the loopback, counter-modes,
async RX, and sync diagnostic targets in order. The focused smart-pin make
targets default to `P2_SMARTPINS_TIMEOUT=300` and
`P2_SMARTPINS_STARTUP_TIMEOUT=120`; override those for slower boards.
`p2-smoke-smartpins-adc-dac-diag` assumes `modules/p2smart.be` is already staged
on SD and runs only the ADC/DAC policy plus one sampled `0-1` observation. It
prints the measured delta fields but does not require calibrated voltage,
stable polarity, or nonzero threshold behavior.
`p2-smoke-smartpins-quadrature-diag` assumes `modules/p2smart.be` is already
staged and runs one static quadrature sample on jumper `0-1`. It prints
before/after/delta/direction/moved fields without claiming movement.
`p2-smoke-smartpins-quadrature-motion` drives pins `0` and `2` through the
`0-1` and `2-3` jumpers into quadrature inputs `1` and `3`, then verifies
synthetic forward and reverse direction. It does not require a mechanical
encoder.
`p2-smoke-smartpins-nco-duty-diag` also assumes `modules/p2smart.be` is already
staged and runs one NCO-duty-to-counter observation on jumper `0-1`. It prints
the counter delta but does not claim waveform-shape validation.
`p2-smoke-smartpins-sync-diag` stages only `modules/p2smart.be` and
`tests/p2/smoke_smartpins_sync_diag.be` before running the bounded sync policy
and clocked-probe diagnostic. The `p2smart.be` source is large, so the sync
diagnostic can spend over a minute in source import/compile before printing its
first smoke marker; let the focused timeout expire before treating it as stuck.

The on-target smoke files live under `tests/p2/` and are intended to be present on the SD card at `/tests/p2`.

## P2 soak tests

Run the default soak suite repeatedly for a duration:

```sh
make soak-p2 PORT=/dev/cu.usbserial-P97cvdxp BOARD=p2edge32 HOURS=1
```

`soak-p2` reuses the same serial smoke runner with duration-based repetition.
By default it runs `SOAK_P2_SUITE=soak`, which repeats import/cache,
bounded import churn plus GC, library behavior, cooperative task coverage,
closure-based cog spawn/stop, and grouped P2 API coverage.
Soak runs default to `SOAK_P2_TIMEOUT=700` and
`SOAK_P2_STARTUP_TIMEOUT=120`; override those make variables for slower or
faster board setups.

The grouped P2 API smoke has passed on `/dev/ttyUSB0` with the flashed Catalina
XMM image `959808 / 16777216` bytes:

```sh
python3 scripts/p2/repl_smoke.py --port /dev/ttyUSB0 --baud 230400 \
  --command 'run_file("/tests/p2/smoke_p2_api.be")' \
  --expect 'P2_SMOKE_PASS p2_api' --timeout 180
```

For the smart-pin loopback wiring on pins `0-1`, `2-3`, `4-5`, and `6-7`,
run the wired-board soak suite explicitly. This includes the main loopback
smoke, the focused async RX proof, and the focused staged sync-serial diagnostic:

```sh
make soak-p2 PORT=/dev/cu.usbserial-P97cvdxp BOARD=p2edge32 HOURS=1 SOAK_P2_SUITE=soak-smartpins
```

Still open for soak coverage:

- Explicit repeated module eviction.
- Explicit channel stress.
- ADC/DAC calibrated voltage/delta stress and remaining smart-pin mode-family
  stress beyond the current raw helper, GPIO loopback, repository,
  PWM/NCO/pulse/transition-to-counter, high-counter loopback, ADC/DAC
  setup/readback, and async serial-pair setup/send/query smoke. Blocking async
  RX byte readback is still open.
- Leak reporting and long-run memory accounting.
