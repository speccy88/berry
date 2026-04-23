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

## Quick Start

Standard Berry host build:

```sh
make
./berry
```

P2 build with FlexC:

```sh
make p2 TOOLCHAIN=flexc
make p2-run TOOLCHAIN=flexc PORT=/dev/ttyUSB0
```

P2 build with Catalina:

```sh
make p2 TOOLCHAIN=catalina
make p2-run TOOLCHAIN=catalina PORT=COM5
```

P2 Edge flash install with Catalina:

```sh
make configure TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp P2_SILICON=latest CATALINA_PLATFORM=P2_EDGE CATALINA_MODEL=COMPACT
make p2-flash
tio -b 230400 /dev/cu.usbserial-P97cvdxp
```

For the verified P2 Edge Rev D path, use boot switches `FLASH=ON, △=OFF, ▽=OFF`. Catalina flash uses a generated `flshload.t` programmer image; do not flash `build/p2/catalina/berry_p2.binary` directly with `loadp2 -SPI`.

Windows PowerShell example:

```powershell
make p2 TOOLCHAIN=flexc
make p2-run TOOLCHAIN=flexc PORT=COM6
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

- [`docs/releases/v0.9.2.md`](./docs/releases/v0.9.2.md)

### New Features

#### Native `i2c` Module

The P2 port now has a native Berry `i2c` module for simple device bring-up, register access, and bus scanning. It uses module-global bus state, so the first version stays easy to use from the REPL and small scripts.

```berry
import i2c

i2c.init(25, 24, 100)
print(i2c.scan())                  # [119] on a BMP180
print(i2c.writeread(0x77, "\xD0", 1))  # "U" == 0x55 chip id
```

Supported API:

- `i2c.init(scl_pin, sda_pin, khz)`
- `i2c.write(addr, data)`
- `i2c.read(addr, count)`
- `i2c.writeread(addr, txdata, rxcount)`
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

Low-level P2 helpers are already exposed as `prop2_*` globals for clocks, counters, pins, smartpins, CORDIC, locks, and cog control. These are useful when you want board access without writing C first.

```berry
print(prop2_clock_freq())
print(prop2_ticks())
prop2_pin_output(56)
prop2_pin_write(56, 1)
print(prop2_pin_read(56))
```

#### Reliable Catalina RAM and Flash Flow

The Catalina path is already set up so RAM loading and flash programming are separate, documented flows instead of ad-hoc `loadp2` commands.

```sh
make configure TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp \
  P2_SILICON=latest CATALINA_PLATFORM=P2_EDGE CATALINA_MODEL=COMPACT

make p2-ram
make p2-flash
make p2-attach
```

## P2 Toolchain Model

Two P2 compiler flows are supported:

- `TOOLCHAIN=flexc`
- `TOOLCHAIN=catalina`

Path overrides:

```sh
make p2 TOOLCHAIN=flexc FLEXPROP_DIR=/opt/flexprop
make p2 TOOLCHAIN=catalina CATALINA_DIR=/opt/catalina
make p2-run TOOLCHAIN=flexc LOADP2=/opt/flexprop/bin/loadp2 PORT=/dev/ttyUSB0
```

Local managed caches are supported and ignored by git:

- `.third_party_cache/flexprop/`
- `.third_party_cache/catalina/`

## P2 Silicon Selection

The P2 build keeps explicit silicon selection:

- `P2_SILICON=latest` uses `-2`
- `P2_SILICON=b` uses `-2`
- `P2_SILICON=c` uses `-2`
- `P2_SILICON=a` uses `-2a`

Examples:

```sh
make p2 TOOLCHAIN=flexc P2_SILICON=latest
make p2-run TOOLCHAIN=flexc P2_SILICON=a PORT=COM6
```

## Repository Layout

The main P2 areas are:

- [`mk/`](./mk)
- [`port/p2/`](./port/p2)
- [`tools/p2/`](./tools/p2)
- [`docs/P2_BUILD.md`](./docs/P2_BUILD.md)
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
