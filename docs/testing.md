# Testing

Date: 2026-06-06

This document describes the repeatable test entrypoints for the host Berry runtime and the Propeller 2 target.

## Host tests

Run the desktop Berry language/runtime tests plus P2-specific host regressions:

```sh
make test-host
```

`make test-host` builds the host Berry binary with the existing sanitizer and coverage flags, runs `./testall.be`, then runs these P2 host regressions:

- `tests/p2/host_libstore_chunk.be`
- `tests/p2/host_taskspin.be`

Current coverage:

- Standard desktop Berry tests under `tests/*.be`.
- Fake-PSRAM `libstore` chunked source-cache behavior.
- Host-simulatable `taskspin` cooperative scheduler behavior.

Still open:

- Fake SD loader behavior beyond the current file-backed module tests.
- `.bec` cache behavior, stale cache fallback, eviction errors, closure serialization/copy rules, and broader low-memory behavior.

## P2 hardware tests

Provision the SD card and run the full on-target P2 smoke suite:

```sh
make test-p2 PORT=/dev/ttyUSB0 BOARD=p2edge
```

For the P2 Edge 32 MB RAM board, select the Edge32 suite:

```sh
make test-p2 PORT=/dev/cu.usbserial-P97cvdxp BOARD=p2edge32
```

`make test-p2` does two things:

- Uploads `modules/` to `/modules` and `tests/p2/` to `/tests/p2` through the running Berry REPL using `make p2-sd-sync`.
- Runs `scripts/p2/repl_smoke.py` against the selected suite.

Suite selection:

- `BOARD=p2edge` runs the existing full suite, equivalent to `p2-smoke`.
- `BOARD=p2edge32` runs the Edge32 suite, equivalent to `p2-smoke-edge32`.

The target must already be running Berry at the REPL prompt. Build/flash commands are still separate because board boot mode and flash/RAM choice are hardware-setup decisions.

## P2 smoke suites

Existing direct smoke commands remain available:

```sh
make p2-smoke PORT=/dev/ttyUSB0
make p2-smoke-quick PORT=/dev/ttyUSB0
make p2-smoke-edge32 PORT=/dev/cu.usbserial-P97cvdxp
```

The on-target smoke files live under `tests/p2/` and are intended to be present on the SD card at `/tests/p2`.

## P2 soak tests

Run the selected smoke suite repeatedly for a duration:

```sh
make soak-p2 PORT=/dev/cu.usbserial-P97cvdxp BOARD=p2edge32 HOURS=1
```

`soak-p2` reuses the same serial smoke runner with duration-based repetition. This provides a repeatable soak entrypoint, but it does not yet prove the full final soak matrix from `port/p2/goal.md`.

Still open for soak coverage:

- Explicit repeated module eviction.
- Explicit GC stress.
- Explicit cog spawn/stop stress.
- Explicit channel stress.
- Dedicated GPIO/smart-pin stress.
- Leak reporting and long-run memory accounting.

