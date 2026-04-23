# Berry on Propeller 2

This directory holds the P2-specific notes that sit closest to the runtime and bring-up work.

## Layout

- `../include/` contains the P2 configuration shim and small public headers.
- `../runtime/` contains the P2 entry point, serial backend, and heap implementation.
- `../overrides/` contains the small maintained override layer used by the port.
- `../patches/optional/` contains temporary or host-specific workaround files.
- `../tests/` contains tiny on-target probes for serial, loading, and allocation.

## Current Goal

Bring up a basic Berry REPL on Propeller 2 with:

- `print()`
- variable assignment
- simple arithmetic
- reliable serial interaction

Current Catalina status on P2 Edge / latest silicon:

- `make p2-run TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp` reaches a working REPL
- `print()`, assignment, and basic arithmetic are live-verified
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

## Main References

- [`PORTING_STATUS.md`](./PORTING_STATUS.md)
- [`../../../docs/P2_BUILD.md`](../../../docs/P2_BUILD.md)
- [`../../../docs/P2_LAYOUT.md`](../../../docs/P2_LAYOUT.md)
