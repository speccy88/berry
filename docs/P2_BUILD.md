# P2 Build

## Supported Interface

```sh
make configure
make show-config
make p2 TOOLCHAIN=flexc
make p2 TOOLCHAIN=catalina
make p2-run TOOLCHAIN=flexc PORT=/dev/ttyUSB0
make p2-run TOOLCHAIN=catalina PORT=COM5
make p2-ram TOOLCHAIN=catalina PORT=/dev/ttyUSB0
make p2-flash TOOLCHAIN=catalina PORT=/dev/ttyUSB0
make p2-stop
make p2-clean
make p2-tools TOOLCHAIN=flexc
make p2-tools TOOLCHAIN=catalina
make p2-prebuild
```

## Required Variables

- `TOOLCHAIN=flexc|catalina`
- `PORT=...`
- `FLEXPROP_DIR=...`
- `CATALINA_DIR=...`
- `LOADP2=...`

## Local Environment Defaults

You can save your current P2 environment once and stop repeating the same
flags on every command:

```sh
make configure \
  TOOLCHAIN=catalina \
  PORT=/dev/cu.usbserial-P97cvdxp \
  P2_SILICON=latest \
  CATALINA_PLATFORM=P2_EDGE \
  CATALINA_MODEL=COMPACT
```

This writes a local `.p2.local.mk` file in the repo root. It is ignored by git,
so it is safe to keep machine-specific settings there.

Useful helpers:

```sh
make show-config
make configure-reset
```

After configuring, the short commands work as expected:

```sh
make p2-ram
make p2-flash
make p2-run
make p2-attach
make p2-stop
```

Current macOS Catalina notes:

- `make p2-ram` is the normal interactive RAM-load command
- `make p2-flash` programs SPI flash and returns; it is intentionally non-interactive
- `make p2-attach` opens a serial terminal using the configured P2 baud rate without loading RAM
- on the current macOS + P2 Edge path, `p2-flash` uses `loadp2 -FLASH -SINGLE` because the default chip-mode flash path timed out at the end of programming
- on Catalina `P2_EDGE`, the current terminal baud is `230400`, so a plain `tio /dev/...` at `115200` will not show readable output
- for P2 Edge boot-from-flash, use boot DIP setting `FLASH=ON, △=OFF, ▽=ON` for flash-only fast boot
- with a regular terminal, use:

```sh
tio -b 230400 /dev/cu.usbserial-P97cvdxp
```

Interactive quit behavior on the current macOS Catalina path:

- press `Ctrl-C` or `Ctrl-D` at an empty `berry>` prompt to ask Berry to quit
- the wrapper now disconnects automatically after Berry prints `bye`
- if the current bump-heap build runs out of memory, the REPL now prints the OOM error and exits automatically
- press `Ctrl-]` to leave the serial terminal immediately without asking Berry to quit
- if a stale loader session is left behind, `make p2-stop` clears it

## Linux

Install:

- `git`
- `make`
- `python3`
- a C compiler for the host build

Examples:

```sh
make p2 TOOLCHAIN=flexc
make p2-run TOOLCHAIN=flexc PORT=/dev/ttyUSB0
make p2 TOOLCHAIN=catalina CATALINA_DIR=/opt/catalina
make p2-run TOOLCHAIN=catalina PORT=/dev/ttyUSB0 LOADP2=/opt/flexprop/bin/loadp2
```

Bootstrap-managed cache examples:

```sh
make p2-tools TOOLCHAIN=flexc FLEXPROP_DIR=.third_party_cache/flexprop
make p2-tools TOOLCHAIN=catalina CATALINA_DIR=.third_party_cache/catalina
```

Notes:

- the FlexProp shell bootstrap can fetch a cache directly on Unix-like hosts
- the Catalina shell bootstrap expects either `CATALINA_DIR` to point at an existing installation or `CATALINA_REPO` to be set for a shallow clone

## Windows PowerShell

Install:

- Git for Windows
- Python 3
- GNU Make

Recommended board port for the next session:

- `PORT=COM6`

Examples:

```powershell
make p2 TOOLCHAIN=flexc
make p2-run TOOLCHAIN=flexc PORT=COM6
make p2 TOOLCHAIN=catalina CATALINA_DIR=C:\tools\catalina
make p2-run TOOLCHAIN=catalina PORT=COM6 LOADP2=C:\tools\flexprop\bin\loadp2.exe
```

If you already have external installations, point the Make variables at them. If not, use the bootstrap helpers in `tools/p2/bootstrap/`.

Notes:

- the PowerShell FlexProp bootstrap expects either an existing `FLEXPROP_DIR` or a `FLEXPROP_ZIP_URL`
- the PowerShell Catalina bootstrap expects either an existing `CATALINA_DIR` or `CATALINA_REPO`

## Silicon Selection

Examples:

```sh
make p2 TOOLCHAIN=flexc P2_SILICON=latest
make p2 TOOLCHAIN=flexc P2_SILICON=a
make p2-run TOOLCHAIN=flexc P2_SILICON=latest PORT=COM6
```

## Output Layout

P2 outputs are written under:

```text
build/p2/<toolchain>/
```

Examples:

```text
build/p2/flexc/berry_p2.binary
build/p2/catalina/berry_p2.binary
```

## Current Primary Focus

The maintained day-to-day bring-up path is now:

- macOS
- `TOOLCHAIN=catalina`
- `CATALINA_PLATFORM=P2_EDGE`
- latest P2 silicon (Rev C / current silicon path)

Other paths remain available, but this is the one that should be used first
for ongoing Berry port work.
