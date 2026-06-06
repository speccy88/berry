<p align="center">
  <h1 align="center">Berry with Propeller 2 Port</h1>
  <p align="center">Berry remains the main project here, with the Propeller 2 port isolated for maintainable upstream sync.</p>
</p>

## Overview

This repository stays clone-first for users who want Berry plus the Propeller 2 port.

- Upstream Berry source layout stays largely intact under `src/`, `default/`, `modules/`, `examples/`, and `tests/`.
- Propeller 2 runtime code, overrides, probes, and status notes now live under `port/p2/`.
- P2 build logic lives under `mk/`.
- Tool bootstrap and loader helpers live under `tools/p2/`.
- Downloaded toolchains belong in `.third_party_cache/` or in user-provided paths, not in git.

The long-term maintenance rule is simple: keep the fork easy to use, while keeping Berry upstream merges manageable.


## P2 Documentation Map

The active Propeller 2 docs are split by purpose:

- [`docs/getting-started.md`](./docs/getting-started.md): first build, flash, and smoke path.
- [`docs/building.md`](./docs/building.md): Catalina profiles, board/profile flags, and P2 trace/debug/unsafe-ASM flag policy.
- [`docs/board-support.md`](./docs/board-support.md): supported board profiles and reserved pins.
- [`docs/sd-layout.md`](./docs/sd-layout.md): current `/modules` layout and target `/berry/...` layout.
- [`docs/psram-loader.md`](./docs/psram-loader.md): Hub/PSRAM/XMM cache model.
- [`docs/berry-compatibility.md`](./docs/berry-compatibility.md): Berry compatibility coverage and bare-metal host-like limitations.
- [`docs/p2-api.md`](./docs/p2-api.md): current `p2` API snapshot.
- [`docs/smartpins.md`](./docs/smartpins.md): raw smart-pin API and remaining mode-family roadmap.
- [`docs/cogs.md`](./docs/cogs.md): current cog/child-VM model and closure-transfer policy.
- [`docs/tasks.md`](./docs/tasks.md): cooperative `task` and `taskspin` modules.
- [`docs/pasm.md`](./docs/pasm.md): safe `p2.asm` facade and future PASM ABI rules.
- [`docs/debugging.md`](./docs/debugging.md): query-based diagnostics and debug flag policy.
- [`docs/performance.md`](./docs/performance.md): benchmark plan and reporting format.
- [`docs/hardware-tests.md`](./docs/hardware-tests.md): pins, wiring, resistors, board variants, skips, and runnable hardware-test entrypoints.
- [`docs/limitations.md`](./docs/limitations.md): explicit unsupported/open areas.

## Quick Start

Standard Berry host build:

```sh
make
./berry
```

P2 build with Catalina:

```sh
make p2 TOOLCHAIN=catalina
make p2-minimal
make p2-full
make p2-run TOOLCHAIN=catalina PORT=COM5
```

Catalina is the preferred and verified P2 toolchain for compiling Berry. The
old FlexC targets are still present for historical/debugging work, but do not
use FlexC for normal Berry P2 builds unless you are deliberately investigating
that toolchain.

P2 Edge flash install with Catalina:

```sh
make configure TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp P2_SILICON=latest CATALINA_PLATFORM=P2_EDGE CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=
make p2-flash
tio -b 230400 /dev/cu.usbserial-P97cvdxp
```

For the verified P2 Edge Rev D path, use boot switches `FLASH=ON, △=OFF, ▽=OFF`. Catalina flash uses a generated `flshload.t` programmer image; do not flash `build/p2/catalina/full/berry_p2.binary` directly with `loadp2 -SPI`.

The default Catalina P2 Edge profile targets the no-PSRAM board, where pins `56` and `57` are LEDs. Do not add `-lpsram` for that board; Catalina's PSRAM profile uses pin `57` as chip-select. Keep `CATALINA_MODEL=COMPACT` for `make p2-ram`; `NATIVE` builds are too large for the Hub RAM load path.

P2 build profiles are selected with `P2_PROFILE` or with convenience targets:

- `make p2-minimal` builds the smallest practical REPL profile: core language, standard classes, and `string`, with filesystem, JSON, math, OS, P2 hardware modules, and `prop2_*` globals disabled. The saved image uses the freed Hub RAM for the main Berry heap.
- `make p2-full` builds the current no-PSRAM P2 Edge profile with the existing modules enabled.
- `make p2-edge32` builds the P2 Edge 32 MB RAM profile with Catalina `-lpsram`. This enables PSRAM block-transfer support and reserves pins `40..57`; Berry's object heap remains in Hub RAM because COMPACT PSRAM is not ordinary C pointer-addressable storage.
- `make p2-xmm` builds the experimental Catalina `LARGE`/XMM profile for the P2 Edge 32 MB RAM board. It uses the lower `16 MiB` PSRAM window for Catalina XMM/external heap storage and leaves the upper `16 MiB` as an explicit block/cache window.

P2 app images are checked against the 512 KiB Hub RAM limit. Oversized builds fail before `berry_p2.binary` is published.

Windows PowerShell example:

```powershell
make p2 TOOLCHAIN=catalina CATALINA_DIR=C:\tools\catalina
make p2-run TOOLCHAIN=catalina PORT=COM6 LOADP2=C:\tools\flexprop\bin\loadp2.exe
```

## Release Binaries

Catalina releases for the Propeller 2 now ship two binaries:

- `berry_p2.binary`
  The normal Berry application image. Use this for RAM loading with `make p2-run` or `make p2-ram`.
- `berry_p2_flash_loader.binary`
  A Catalina flash-programmer wrapper image generated from `berry_p2.binary`. Use this for `make p2-flash` and `make p2-flash-run`.

RAM vs flash on Catalina:

- RAM load:

```sh
make p2 TOOLCHAIN=catalina
make p2-run TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp
```

- Flash install:

```sh
make p2 TOOLCHAIN=catalina
make p2-flash TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp
tio -b 230400 /dev/cu.usbserial-P97cvdxp
```

Important Catalina flash note:

- `berry_p2.binary` is the Berry app image
- `berry_p2_flash_loader.binary` is the temporary flash-programmer wrapper
- do not flash `berry_p2.binary` directly with `loadp2 -SPI` on the Catalina path

## P2 Feature Tour

This fork is meant to be usable, not just buildable. Each release should describe both the newly added features and the already working features so the release notes double as a mini tutorial.

The current release notes live here:

- [`docs/releases/v0.9.5.md`](./docs/releases/v0.9.5.md)

### New Features

#### `p2` Hardware Module

The `p2` module is the friendly hardware namespace for day-to-day P2 work: GPIO, low-level counter/timing helpers, cog ID/state inspection, heap reporting, and a small tone helper.
The P2 REPL includes a tiny line editor: Up/Down cycles through the last three
commands, Left/Right moves within the line, and Backspace/Delete edit recalled
commands before Enter.

```berry
import p2
import rtos

p2.pinmode(56, p2.OUTPUT)
p2.high(56)
rtos.sleep_ms(250)
p2.low(56)
print(p2.cogid())
print(p2.sbrk())
p2.status()
```

#### `rtos` Module

The `rtos` module owns P2 concurrency: process-style task spawn/cog start, cooperative sleep/yield, hardware locks, named queues, event flags, counter timers, deferred event callbacks, and debug maps. The older experimental `worker` and `threads` modules are no longer exported in the normal P2 profile; their backend pieces are folded under `rtos`. The current implementation supports the main VM plus one child Berry VM/cog, with shared Hub-RAM queues/events/locks shaped for a later multi-VM heap expansion.

```berry
import rtos

rtos.channel("sensor")
rtos.load_file("/examples/rtos/workers/packet_reader.be")
rtos.newcog("packet_reader", 100)
print(rtos.get("sensor", 500))
rtos.stop()

lock = rtos.new_lock()
rtos.lock(lock)
rtos.unlock(lock)
rtos.delete_lock(lock)
```

Use `rtos.load_file(path)` for readable child-task code stored on the SD card. `rtos.load_str(source)` is available when generated source is useful, and `rtos.load(source)` remains as the compatibility alias for `rtos.load_str(source)`. Child code runs in a separate Berry VM on another cog, so functions or closures defined only in the main VM cannot be passed directly yet. The preferred process spelling is `rtos.newcog("function_name", ...int_args)` after loading the task source. `rtos.newcog(function, ...)` is reserved for the real closure-transfer path and currently raises a clear runtime error instead of sharing unsafe VM pointers.

The global `run_file(path)` helper compiles and runs a `.be` file from the current VM, which makes it useful from the REPL or from another script:

```berry
run_file("/examples/core/qsort.be")
```

#### Native `i2c` Module

The P2 port has a native Berry `i2c` module for simple device bring-up, register access, readiness checks, and bus scanning. It uses module-global bus state, so the first version stays easy to use from the REPL and small scripts.

```berry
import i2c

i2c.init(25, 24, 400)
print(i2c.scan())                  # [119] on a BMP180
print(i2c.present(0x77))           # true
print(i2c.writeread(0x77, "\xD0", 1))  # "U" == 0x55 chip id
```

Supported API:

- `i2c.init(scl_pin, sda_pin, khz, pullup=false)`
- `i2c.write(addr, data)`
- `i2c.read(addr, count)`
- `i2c.writeread(addr, txdata, rxcount)`
- `i2c.present(addr)`
- `i2c.wait(addr, timeout_ms=1000)`
- `i2c.start()` / `i2c.stop()`
- `i2c.scan()`

#### Native `spi` Module

The P2 port now also has a native Berry `spi` module for mode-aware transfers with explicit chip select control. This is aimed at common flash, EEPROM, ADC, and sensor bring-up.

```berry
import spi

spi.init(10, 11, 12, 13, 0, 1000)
spi.select()
id = spi.transfer("\x9F\x00\x00\x00")
spi.deselect()
print(id)
```

Supported API:

- `spi.init(clk_pin, mosi_pin, miso_pin, cs_pin, mode, khz)`
- `spi.select()`
- `spi.deselect()`
- `spi.write(data)`
- `spi.read(count, filler=0xFF)`
- `spi.transfer(data)`
- `spi.stop()`

#### WiFiNINA / AirLift Skeleton

`modules/wifi.be` is the first Berry-side WiFiNINA/AirLift transport layer for
ESP32 coprocessors flashed with Adafruit's firmware. It handles the configured
P2 pins, reset pulse, SPI framing, firmware-version request, and connection
status request. It is intentionally documented as bring-up work: the current
ESP32-C6 board still needs hardware READY/BUSY detection before higher-level
network APIs are added.

```berry
import wifi

wifi.init({
    "sck": 16, "mosi": 17, "miso": 18, "cs": 19,
    "busy": 20, "reset": 21, "irq": 22
})

print(wifi.firmware_version())
print(wifi.status())
```

#### `spin2` Loader Prototype

The `spin2` module is the first path for running Spin2/PASM binaries from Berry. Binaries live on the SD card under `/spin2` by default. Berry-callable binaries use the documented integer mailbox convention. Raw standalone PASM images can be started with `PTRA == nil`; high-level FlexSpin images are detected and rejected with `value_error` because their `.BIN` payloads contain absolute Hub addresses and are not relocatable from Berry's heap loader.

```berry
import spin2

print(spin2.list())
handle = spin2.start("MBOXDEMO.BIN")
print(spin2.info(handle))
print(spin2.call(handle, 1, 123))
spin2.stop(handle)
```

Build bundled Spin2 examples with:

```sh
make spin2
```

Copy the demo to the SD card with an 8.3 filename, for example `/spin2/MBOXDEMO.BIN`. The current Catalina DOSFS path may show long filenames as aliases such as `BERRY_~2.BIN`.

### Existing Features

#### Interactive REPL Basics

The P2 port already supports a practical interactive Berry REPL for quick testing, small scripts, and board bring-up work.

```berry
print(1 + 2)
a = 6
print(a * 7)
for i:0..3
    print(i)
end
```

#### Standard Modules: `string`, `math`, `json`

Several standard Berry modules are already live on the P2 port, which makes it much easier to do real work without dropping to C for every little task.

```berry
import string
import math
import json

print(string.toupper("berry"))
print(math.sqrt(81))
print(json.dump({"a": 1, "b": [2, 3]}))
```

#### Raw Byte Handling with `bytes`

The `bytes` support is already useful for packet work, register dumps, and binary file access.

```berry
b = bytes().fromstring("AB")
print(b.tohex())     # 4142
print(bytes("1122"))
```

#### SD Card Files and `os`

The port already supports SD-backed file I/O and common `os` helpers, so you can read files, create directories, and inspect paths directly from Berry.

```berry
import os

print(os.listdir("/"))
f = open("/TMPD/TEST.TXT", "w")
f.write("hello from berry")
f.close()
print(open("/TMPD/TEST.TXT", "r").read())
```

#### Propeller 2 Hardware Helpers

Propeller 2 hardware helpers are exposed through the `p2` module for clocks, counters, pins, smartpins, CORDIC, locks, attention, and cog inspection. Task sleep and process-style cog startup live in `rtos` so those concepts have one public home. The older `prop2_*` globals remain available for compatibility, but new examples should use `p2` and `rtos`.

```berry
import p2

print(p2.clock_freq())
print(p2.ticks())
p2.smartpin_clear(56)
p2.pin_output(56)
p2.pin_write(56, 0) # active-low LED on the tested no-PSRAM board
print(p2.pin_read(56))
```

P2 module examples live under `examples/p2/`; other modules use their own directories such as `examples/i2c/`, `examples/spi/`, `examples/rtos/`, and `examples/spin2/`. General Berry examples such as quicksort, REPL, and string handling live under `examples/core/`.

The fuller P2 module API reference lives in [`docs/P2_MODULES.md`](./docs/P2_MODULES.md).
The longer-term P2 Berry system plan lives in [`docs/P2_SYSTEM_ROADMAP.md`](./docs/P2_SYSTEM_ROADMAP.md).

On the tested no-PSRAM P2 Edge setup, keep Berry GPIO and bus examples off the SD pins `58..61` and serial pins `62..63`. Pins `56` and `57` are left available because they are exposed as LEDs on that board.

On a P2 Edge with the 32 MB RAM module, build and flash with:

```sh
make p2-edge32-flash PORT=/dev/cu.usbserial-P97cvdxp
tio -b 230400 /dev/cu.usbserial-P97cvdxp
```

Then verify PSRAM support from the REPL with:

```berry
import p2
print(p2.psram_info())
print(p2.psram_test())
```

Repeatable SD smoke tests live under `tests/p2/`. Copy that directory and
`modules/` to the SD card root, start Berry, then run:

```sh
make p2-smoke PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-edge32 PORT=/dev/cu.usbserial-P97cvdxp
```

The edge32 target includes the general smoke suite plus PSRAM block-access
assertions.

The P2 runtime also adds `/modules` to the default lazy import path, so SD
libraries such as `binary_heap.be`, `wifi.be`, `libstore.be`, and
`taskspin.be` can be imported without enabling the larger upstream `sys`
module. On edge32, PSRAM is exposed as block-transfer storage for future library
cache work; the active Berry heap remains in Hub RAM.

#### Reliable Catalina RAM and Flash Flow

The Catalina path is already set up so RAM loading and flash programming are separate, documented flows instead of ad-hoc `loadp2` commands.

```sh
make configure TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp \
  P2_SILICON=latest CATALINA_PLATFORM=P2_EDGE CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=

make p2-ram
make p2-flash
make p2-attach
```

## P2 Toolchain Model

Catalina is the preferred and verified compiler flow for Berry on P2:

- `TOOLCHAIN=catalina`

The old `TOOLCHAIN=flexc` path remains in the tree for historical/debugging
work, but do not use it for normal Berry P2 builds.

Path overrides:

```sh
make p2 TOOLCHAIN=catalina CATALINA_DIR=/opt/catalina
make p2 TOOLCHAIN=catalina P2_PROFILE=minimal CATALINA_DIR=/opt/catalina
make p2-run TOOLCHAIN=catalina LOADP2=/opt/flexprop/bin/loadp2 PORT=/dev/ttyUSB0
```

Local managed caches are supported and ignored by git:

- `.third_party_cache/catalina/`
- `.third_party_cache/flexprop/` for loader tools such as `loadp2`

## P2 Silicon Selection

The P2 build keeps explicit silicon selection:

- `P2_SILICON=latest` uses `-2`
- `P2_SILICON=b` uses `-2`
- `P2_SILICON=c` uses `-2`
- `P2_SILICON=a` uses `-2a`

Examples:

```sh
make configure TOOLCHAIN=catalina P2_SILICON=latest
make p2
```

## Repository Layout

The main P2 areas are:

- [`mk/`](./mk)
- [`port/p2/`](./port/p2)
- [`tools/p2/`](./tools/p2)
- [`docs/P2_BUILD.md`](./docs/P2_BUILD.md)
- [`docs/P2_MODULES.md`](./docs/P2_MODULES.md)
- [`docs/P2_LAYOUT.md`](./docs/P2_LAYOUT.md)
- [`docs/UPSTREAM_SYNC.md`](./docs/UPSTREAM_SYNC.md)

## Berry

Berry is an ultra-lightweight dynamically typed embedded scripting language designed for constrained systems. The interpreter core is ANSI C99 and uses a one-pass compiler plus a register-based VM.

Reference material:

- [Berry documentation](https://berry.readthedocs.io/)
- [Short manual PDF](https://github.com/berry-lang/berry_doc/blob/master/pdf/berry_short_manual.pdf)
- [`tools/grammar/berry.ebnf`](./tools/grammar/berry.ebnf)

## Host Build

Host build requirements are unchanged:

1. Install a C compiler.
2. Install `readline` on Unix-like hosts if desired.
3. Run:

```sh
make
```

## Notes

- The repo no longer vendors full P2 toolchain distributions.
- `build/` is output-only.
- Optional P2 workaround files that shadow upstream Berry sources now live under `port/p2/patches/optional/` and are documented as maintenance exceptions, not normal source layout.
