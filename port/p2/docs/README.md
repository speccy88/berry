# Berry on Propeller 2

This directory holds the P2-specific notes that sit closest to the runtime and bring-up work.

## Layout

- `../include/` contains the P2 configuration shim and small public headers.
- `../runtime/` contains the P2 entry point, serial backend, and heap implementation.
- `../overrides/` contains the small maintained override layer used by the port.
- `../patches/optional/` contains temporary or host-specific workaround files.
- `../tests/` contains tiny on-target probes for serial, loading, and allocation.

## Current Goal

Stabilize and round out the Berry REPL on Propeller 2 so normal interactive
use feels like Berry on other targets:

- `print()`
- variable assignment
- simple arithmetic
- `for` loops over ranges, lists, and maps
- `import string`
- `import math`
- `import json`
- `import bytes`
- `import os`
- SD card backed file and directory access through `open()` and `os`
- reliable serial interaction without prompt drift or blank-line heap loss

Current Catalina status on P2 Edge / latest silicon:

- `make p2-run TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp` reaches a working REPL
- `print()`, assignment, and basic arithmetic are live-verified
- `for i:0..3`, `for e:list`, `for v:map`, and `for k:map.keys()` are live-verified
- `import string`, `import math`, `import json`, `import bytes`, and `import os` are live-verified
- blank Enter presses no longer leak the REPL into an out-of-memory state
- `bytes('1122')`, `bytes().fromstring('AB')`, `tohex()`, `asstring()`, `readbytes()`, and range slicing are live-verified
- `json.load()` and `json.dump()` are live-verified
- SD card access through `open('/HELLO.TXT','r')`, `os.listdir('/')`, `os.mkdir()`, `os.rename()`, `os.remove()`, `os.chdir()`, `os.getcwd()`, and `os.path.*` is live-verified
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

Filesystem probe note:

- `../tests/fs_probe.c` is a destructive Catalina DOSFS probe. It mutates the
  mounted SD card and is meant for low-level debugging, not routine smoke
  testing.

## Main References

- [`PORTING_STATUS.md`](./PORTING_STATUS.md)
- [`../../../docs/P2_BUILD.md`](../../../docs/P2_BUILD.md)
- [`../../../docs/P2_LAYOUT.md`](../../../docs/P2_LAYOUT.md)
