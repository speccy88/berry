# Berry on Propeller 2

This directory holds the P2-specific notes that sit closest to the runtime and bring-up work.

## Layout

- `../include/` contains the P2 configuration shim and small public headers.
- `../runtime/` contains the P2 entry point, serial backend, and heap implementation.
- `../overrides/` contains the small maintained override layer used by the port.
- `../patches/optional/` contains temporary or host-specific workaround files.
- `../tests/` contains tiny on-target probes for serial, loading, and allocation.

## Current Goal

Stabilize the Berry REPL on Propeller 2 so normal interactive use feels like
Berry on other targets:

- `print()`
- variable assignment
- simple arithmetic
- `import string`
- `import math`
- reliable serial interaction without prompt drift or blank-line heap loss

Current Catalina status on P2 Edge / latest silicon:

- `make p2-run TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp` reaches a working REPL
- `print()`, assignment, and basic arithmetic are live-verified
- `import string` and `import math` are live-verified
- blank Enter presses no longer leak the REPL into an out-of-memory state
- P2 helpers are exposed as `prop2_*` globals for clock, counter, pin, and smart-pin operations

Examples:

- `prop2_clock_freq()`
- `prop2_ticks()`
- `prop2_ticks64()`
- `prop2_pin_output(pin)`
- `prop2_pin_write(pin, value)`
- `prop2_pin_read(pin)`
- `prop2_smartpin_write_mode(pin, mode)`
- `prop2_smartpin_query(pin)`
- `prop2_smartpin_start(pin, mode, x, y)`

Primary development focus from now on:

- macOS
- Catalina / `lcc`
- `P2_EDGE`
- latest silicon path (`P2_SILICON=latest`, targeting your Rev C board)

Other toolchains and silicon paths should still be kept buildable, but this is
the first path to validate when continuing the port.

## Main References

- [`PORTING_STATUS.md`](./PORTING_STATUS.md)
- [`../../../docs/P2_BUILD.md`](../../../docs/P2_BUILD.md)
- [`../../../docs/P2_LAYOUT.md`](../../../docs/P2_LAYOUT.md)
