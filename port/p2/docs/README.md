# Berry on Propeller 2

This directory holds the P2-specific notes that sit closest to the runtime and bring-up work.

## Layout

- `../include/` contains the P2 configuration shim and small public headers.
- `../runtime/` contains the P2 entry point, serial backend, and heap implementation.
- `../overrides/` contains the small maintained override layer used by the port.
- `../patches/optional/` contains temporary or host-specific workaround files.
- `../tests/` contains tiny on-target probes for serial, loading, and allocation.

## Current Goal

Make Berry feel native on the Propeller 2: keep the REPL stable, expose useful
hardware modules, and grow the multicog model in small safe layers.

- `print()`
- variable assignment
- simple arithmetic
- `for` loops over ranges, lists, and maps
- `import string`
- `import math`
- `import json`
- `import bytes`
- `import os`
- `import p2`
- `import worker`
- `import threads`
- `import i2c`
- `import spi`
- `import spin2`
- SD card backed file and directory access through `open()` and `os`
- reliable serial interaction without prompt drift or blank-line heap loss
- second-cog Berry worker jobs through Hub-RAM mailboxes

Current Catalina status on P2 Edge / latest silicon:

- `make p2-run TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp` reaches a working REPL
- `print()`, assignment, and basic arithmetic are live-verified
- `for i:0..3`, `for e:list`, `for v:map`, and `for k:map.keys()` are live-verified
- `import string`, `import math`, `import json`, `import bytes`, and `import os` are live-verified
- `import p2`, `import worker`, `import threads`, `import i2c`, `import spi`, and `import spin2` are now live-verified
- blank Enter presses no longer leak the REPL into an out-of-memory state
- `bytes('1122')`, `bytes().fromstring('AB')`, `tohex()`, `asstring()`, `readbytes()`, and range slicing are live-verified
- `json.load()` and `json.dump()` are live-verified
- SD card access through `open('/HELLO.TXT','r')`, `os.listdir('/')`, `os.mkdir()`, `os.rename()`, `os.remove()`, `os.chdir()`, `os.getcwd()`, and `os.path.*` is live-verified
- P2 helpers are exposed as `prop2_*` globals for clock, counter, pin, and smart-pin operations
- friendlier P2 helpers are exposed as `p2.*`
- native bus helpers are exposed as `i2c.*` and `spi.*`
- the first worker VM path is exposed as `worker.*` and `p2.cog_start()`
- fixed v1 channels are exposed as `threads.*`
- Spin2/PASM binary loading scaffolding is exposed as `spin2.*`

Current hardware verification examples:

- `import p2; print(p2.cogid())` -> `0`
- `p2.pinmode(56,p2.OUTPUT); p2.low(56); print(p2.read(56))` -> `0`
- `p2.high(56); print(p2.read(56))` -> `1`
- `import i2c; i2c.init(25, 24, 400); print(i2c.scan())` -> `[119]`
- `print(i2c.writeread(0x77, "\xD0", 1))` -> `U` (`0x55`, BMP180 chip id)
- `import spi; spi.init(10, 11, 12, 13, 0, 1000)` is live-verified
- `import worker; print(worker.start())` -> `5`
- `worker.exec("blink", 56, 50); print(worker.state())` -> `running`
- `import threads; threads.channel("a"); threads.put("a",123); print(threads.get("a"))` -> `123`
- `import spin2; print(spin2.path()); print(spin2.list())` -> `/spin2` and `[]` on the current SD-visible path

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

Reserved-pin note on the current Catalina `P2_EDGE` path:

- pins `58..61` are reserved by the SD card interface
- pins `62..63` are reserved by the serial console
- on the tested no-PSRAM board, pins `56` and `57` are exposed as LEDs and are left available for Berry GPIO use
- Berry GPIO, `i2c`, and `spi` helpers should avoid the SD and serial pins

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
