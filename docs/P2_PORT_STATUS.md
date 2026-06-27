# Propeller 2 Port Status

This is the human-readable status page for the Berry Propeller 2 port. Use it
as the first stop before opening the detailed trackers.

## Current Normal Path

- Hardware: P2 Edge 32 MB board.
- Serial port used by the current harness: `/dev/ttyUSB0` at `230400`.
- Toolchain: Catalina from the sibling checkout, `CATALINA_DIR=../Catalina`.
- Main high-capacity profile: `p2-xmm`, flashed with `make p2-xmm-flash`.
- Current verified XMM image size: `1168384 / 16777216` bytes.
- Normal heap shape: Catalina XMM uses the lower PSRAM window for the VM heap;
  Berry keeps the upper PSRAM window available for explicit block/cache use.

Use this command for the normal high-capacity board image:

```sh
make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
```

Use this command for the non-hardware consistency gates:

```sh
make p2-baseline-guards TOOLCHAIN=catalina CATALINA_DIR=../Catalina
```

## What Works Today

- Interactive `berry>` REPL over serial.
- Core language coverage for normal scripts, classes, closures, maps, lists,
  strings, numbers, ranges, modules, and many parser/runtime edge cases.
- SD-backed files through `open()`, `os`, and `os.path`.
- Lazy source imports from `/modules`, `/berry/lib`, and `/berry/app`.
- Native `p2`, `task`, `math`, `string`, `json`, `bytes`, `i2c`, and `spi`
  paths on the current firmware profiles.
- Grouped P2 APIs for `p2.clock`, `p2.cog`, `p2.lock`, `p2.pin`,
  `p2.cordic`, `p2.math`, `p2.rng`, `p2.smart`, `p2.asm`, and `p2.debug`.
- Focused smart-pin examples and smokes on jumpers `0-1`, `2-3`, `4-5`, and
  `6-7`.
- Current-VM cooperative tasks through native `task`.
- Current-VM IPC helpers through `p2ipc`.
- Safe PASM-adjacent intrinsics and fixed marker/fixture-call proofs through
  `p2.asm`.
- Queryable unsupported boundaries for debug controls, cross-cog IPC,
  arbitrary PASM, real isolated Berry VM cogs, calibrated analog/timer claims,
  USB, and VGA.

## Important Limits

- Do not use containerized Catalina for normal validation.
- Do not spend routine time on FlexC builds unless explicitly selected.
- Do not treat historical macOS serial-port entries as current instructions;
  they are old evidence captures.
- `try` / `except` and line-start `for` are avoided in user-facing P2 examples
  because current normal images can hang on those paths.
- `p2smart` remains useful, but routine hardware checks prefer native `p2.smart`
  files when the source wrapper would make upload/load too slow.
- `.bec` module preference is still gated by P2 ABI compatibility. Current
  P2 behavior is explicit source fallback plus bytecode ABI guard coverage.

## Best Focused Checks

Use focused checks for normal development. Avoid broad suites unless broad
regression evidence is explicitly needed.

| Need | Command |
| --- | --- |
| Non-hardware consistency | `make p2-baseline-guards TOOLCHAIN=catalina CATALINA_DIR=../Catalina` |
| Quick first-four priority hardware health | `make p2-smoke-priority1-4-min-staged TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0` |
| SD/file core | `make p2-smoke-sd-file-core-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0` |
| Standard-library quick path | `make p2-smoke-stdlib-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0` |
| Smart pins, focused native path | `make p2-smoke-smartpins-focused TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0` |
| PASM policy and fixtures | `make p2-smoke-pasm-policy-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0` |
| Cog handle policy | `make p2-smoke-cog-policy-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0` |
| Debug capability boundary | `make p2-smoke-debug-capabilities-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0` |
| `.bec` ABI guard/source fallback | `make p2-smoke-bec-abi-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0` |

## Where To Read More

- Quick setup: `docs/getting-started.md`
- Build profiles and command details: `docs/P2_BUILD.md`
- Test strategy and smoke target reference: `docs/testing.md`
- Hardware wiring: `docs/hardware-tests.md`
- Current architecture: `docs/architecture-current.md`
- Coverage details: `docs/coverage-matrix.md`
- Live work queue: `port/p2/TODO.md`
- Historical evidence log: `port/p2/DONE.md`
