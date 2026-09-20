# P2 Build

For the current human-readable P2 status, including the normal board, profile,
and focused validation commands, start with [port status](P2_PORT_STATUS.md).
The [2026-09-20 interactive preview](P2_INTERACTIVE_PREVIEW.md) identifies the
accepted LARGE/XMM RAM image and source/CI evidence. Other profiles and the flash
targets below are not covered by that interactive acceptance.

## Supported Interface

```sh
make configure
make show-config
make p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
make p2-minimal
make p2-full
make p2-edge32
make p2-edge32-flash
make p2-xmm
make p2-xmm-run
make p2-xmm-flash
make p2-run TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-ram TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
make p2-stop
make p2-clean
make p2-tools TOOLCHAIN=catalina CATALINA_DIR=../Catalina
make p2-prebuild
```

Catalina is the preferred and verified toolchain for compiling Berry on P2.
The FlexC targets remain in the makefiles as legacy/debugging support, but the
normal workflow should not try to build Berry with FlexC unless that is the
specific task.

By default the makefiles use the sibling Catalina install in the parent
directory:

```sh
make p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
```

The default `CATALINA_DIR` is `../Catalina`; override it only when validating a
different explicit Catalina checkout.

## Required Variables

- `TOOLCHAIN=catalina`
- `PORT=...`
- `P2_PROFILE=minimal|full|edge32|xmm` when not using a convenience profile target
- `P2_BOARD=auto|p2edge|p2edge32` for the physical board pinout. `auto`
 maps `full`/`minimal` to `p2edge` and `edge32`/`xmm` to `p2edge32`.
- `P2_SILICON=a|latest|b|c` for old silicon versus current B/C silicon
 code generation.
- `CATALINA_DIR=...` when overriding the default sibling install
- `LOADP2=...` only when overriding the loader. On Linux Catalina builds,
  the makefile defaults to `loadp2` found on `PATH` before falling back to the
  FlexProp cache path.

## Release Targets And Pins

Keep the three release identities distinct:

- old silicon: set `P2_SILICON=a`. This selects the old P2 codegen path
 (`-2a`). Board pinout is still selected separately with `P2_BOARD`.
- P2 Edge no-RAM: use `P2_BOARD=p2edge`, normally through `make p2-full`.
 On this board profile, onboard LEDs are `LED0=56` and `LED1=57`.
- P2 Edge 32 MB RAM: use `P2_BOARD=p2edge32`, normally through
 `make p2-edge32` or `make p2-xmm`. On this board profile, onboard LEDs are
 `LED0=38` and `LED1=39`; pins `40..57` are reserved for PSRAM, with pin `57`
 used as PSRAM chip-select.

The makefile generates these runtime macros in the P2 config header:

- `BE_P2_BOARD_NAME`
- `BE_P2_BOARD_HAS_PSRAM`
- `BE_P2_BOARD_LED0_PIN`
- `BE_P2_BOARD_LED1_PIN`
- `BE_P2_SILICON_NAME`

Future board helpers, such as an onboard LED module, must use those generated
macros instead of hard-coding pins `56/57` or `38/39`.

## Build Profiles

The P2 profile layer lives in `port/p2/include/berry_conf_p2.h`. It controls
the Berry module feature macros, P2-native module caching, heap sizes, stack
slot limit, and maximum `bytes()` size.

- `minimal`: core language and standard classes plus `string`. It disables
  filesystem, JSON, math, OS, P2 hardware modules, retired worker/RTOS/Spin2
  helpers, and low-level `prop2_*` globals. Historical verified image:
  `426624` bytes with a `192 KiB` main heap.
- `full`: the current no-PSRAM P2 Edge build. It includes SD-backed
  `open()`/`os`, P2 hardware modules, native `task`, native `math`, and optional
  WiFiNINA helpers. Historical verified image: `494624` bytes with a `128 KiB` main
  heap. The older `rtos`, `worker`, `threads`, and `taskspin` APIs are retired.
- `edge32`: P2 Edge 32 MB RAM profile with Catalina `-lpsram`. It reserves
  pins `40..57` for PSRAM, keeps Berry's object heap in Hub RAM, and exposes
  bounded PSRAM block transfers plus SD-library source-cache experiments.
  Historical verified image: `518304` bytes with a `92 KiB` main heap and
  `8 KiB` worker heap.
- `xmm`: P2 Edge 32 MB RAM profile using Catalina `LARGE`, `-lpsram`, and
  `-C PSRAM`. Catalina places the backing C arena in the lower PSRAM/XMM
  window, so Berry can use a large allocator-backed heap while the upper
  `16 MiB` stays available for explicit PSRAM block/cache use. The
  [2026-09-20 accepted RAM image](P2_INTERACTIVE_PREVIEW.md) is `1230976` bytes;
  its actual UART banner reports a `15728640` byte Berry heap and
  `Berry heap external`. These are image/configuration values, not a completed
  stress-tested resource budget. Historical COMPACT sizes above were not
  revalidated by the XMM interactive milestone.

Library loading policy (`modules/libstore.be`) on P2:

- `libstore.POLICY_SD_LAZY` (`sd_only`): keep library execution SD-file-first, no PSRAM cache.
- `libstore.POLICY_SD_CACHE_PSRAM` (`sd_cache_psram`): mirror SD module source into PSRAM cache on demand before execution.
- `libstore.POLICY_SD_PRELOAD_PSRAM` (`sd_preload_psram`): same strategy, with optional eager preload.

At runtime:

- `libstore.policy()` reports the active policy.
- `libstore.set_policy(libstore.POLICY_SD_PRELOAD_PSRAM, true)` can request preload caching.
- `libstore.cache_all_report()` reports bulk preload results, including modules
  skipped because the current PSRAM cache window is too small.
- `libstore.cache_many_report(name, ...)` gives the same non-aborting
  diagnostics for an explicit selected preload list, including missing or
  invalid module names.

Operational note:

- On `edge32`, PSRAM is block-only (`p2.psram_read`/`p2.psram_write`), so this is a **source-cache strategy** and does not change where Berry VM objects are allocated.
- On `xmm`, Catalina's XMM memory model is the path that can move allocator-backed VM storage onto PSRAM.

Convenience targets pin the intended Catalina board profile:

```sh
make p2-minimal
make p2-full
make p2-edge32
make p2-xmm
```

Run the experimental XMM image through Catalina's serial XMM loader:

```sh
make p2-xmm-run TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
```

Install the experimental XMM image for standalone SPI-flash boot:

```sh
make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
```

The XMM flash target creates a complete bootable flash image and writes it with
FlexProp `loadp2`'s high-memory flash path:

```sh
loadp2 -HIMEM=flash @80000000=build/p2/catalina/xmm/berry_p2_xmm_flash.binary
```

The flash image layout is:

- `0x00000`: 1024-byte P2 ROM bootable stage-1 block
- `0x10000`: size-prefixed stage-2 flash-to-PSRAM loader
- `0x40000`: size-prefixed Berry Catalina XMM image

After reset or power-cycle, standalone XMM flash boot shows an
`Initializing PSRAM` spinner and then a Berry VM startup spinner. The sparse
stage-2 loader copies only populated image records into PSRAM; current captures
reach `berry>` about 3 seconds after attach.

Equivalent explicit form:

```sh
make p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina P2_PROFILE=minimal P2_BOARD=p2edge CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=
```

P2 Edge 32 MB RAM explicit form:

```sh
make p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina P2_PROFILE=edge32 P2_BOARD=p2edge32 CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram
```

Experimental unified-memory XMM explicit form:

```sh
make p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina P2_PROFILE=xmm P2_BOARD=p2edge32 CATALINA_MODEL=LARGE CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram CATALINA_CONFIG_FLAGS="-C P2_EDGE -C LARGE -C SIMPLE -C VT100 -C NO_ARGS -C PSRAM"
```

## Local Environment Defaults

You can save your current P2 environment once and stop repeating the same
flags on every command:

```sh
make configure \
 TOOLCHAIN=catalina \
 CATALINA_DIR=../Catalina \
 PORT=/dev/ttyUSB0 \
 P2_SILICON=latest \
 P2_BOARD=p2edge \
 CATALINA_PLATFORM=P2_EDGE \
 CATALINA_MODEL=COMPACT \
 CATALINA_CLIB=-lcx \
 CATALINA_SERIAL_LIB=
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

- the default P2 Edge build targets the no-PSRAM board: `CATALINA_MODEL=COMPACT`, `CATALINA_CLIB=-lcx`, with no `-lpsram`
- the default P2 feature profile is `P2_PROFILE=full`
- on that no-PSRAM board, `P2_BOARD=p2edge` and pins `56` and `57` are LEDs and are available for Berry GPIO
- keep `COMPACT` for `make p2-ram`; `NATIVE` builds are larger than the Hub RAM load path can reliably start
- `berry_p2.binary` is checked against the P2 Hub RAM limit of `524288` bytes; oversized builds fail before the target image is published. Catalina flash-loader wrapper images are also checked against the same Hub RAM limit before `make p2-flash` can program the board.
- SD file and directory handles use small fixed pools in the P2 runtime (`4` files and `2` directory iterators). Avoiding Catalina libc heap allocation here is required for the full image near the Hub RAM limit.
- for the PSRAM P2 Edge, use `make p2-edge32` or build explicitly with `P2_PROFILE=edge32 P2_BOARD=p2edge32 CATALINA_MODEL=COMPACT CATALINA_SERIAL_LIB=-lpsram`; that profile uses onboard LEDs on pins `38` and `39` and reserves pins `40..57` for memory, including pin `57` as PSRAM chip-select
- Catalina's COMPACT `-lpsram` path gives Berry bounded block access to the 32 MB PSRAM through `p2.psram_read()` and `p2.psram_write()`, backed by Catalina's `psram_read()` and `psram_write()`. It does not make PSRAM ordinary C pointer-addressable storage, so Berry's GC/object heap remains in Hub RAM on this profile.
- `make p2-xmm` builds an experimental Catalina `LARGE` image for the same P2 Edge 32 MB RAM board. That path is intended to make Hub/PSRAM invisible to Berry by putting the unified memory decision below Berry's allocator instead of adding PSRAM-specific object handling to the VM. Catalina's documented P2 Edge XMM support uses only the lower `16 MiB` of the `32 MiB` PSRAM as transparent XMM memory; Berry reserves that lower window from `p2.psram_read()` / `p2.psram_write()` and leaves the upper `16 MiB` for explicit block/cache use. It is guarded by `P2_XMM_IMAGE_MAX_BYTES`, not by the 512 KiB Hub image limit, because an XMM image includes external-memory program content. Use `p2-xmm-run` for serial XMM loading or `p2-xmm-flash` for standalone SPI-flash boot.
- For `edge32`, `libstore` defaults to `sd_cache_psram` and exposes the `.be` module source text cache window; for no-PSRAM profiles, `libstore` falls back to `sd_only`.
- `make p2-ram` is the normal interactive RAM-load command
- `make p2-flash` now builds Catalina's `flshload.t` flash-programmer image, loads that to RAM, and waits until Berry boots back from SPI flash
- `make p2-flash-run` uses the same Catalina flash-programmer image but keeps the terminal attached
- `make p2-attach` opens a serial terminal using the configured P2 baud rate without loading RAM
- on Catalina `P2_EDGE`, the current terminal baud is `230400`, so a plain `tio /dev/...` at `115200` will not show readable output
- for P2 Edge development with serial attach after reset, use boot DIP setting `FLASH=ON, △=OFF, ▽=OFF`
- for P2 Edge flash-only fast boot, use boot DIP setting `FLASH=ON, △=OFF, ▽=ON`
- with a regular terminal, use:

```sh
tio -b 230400 /dev/ttyUSB0
```

For a P2 Edge Rev D with the 32 MB RAM module:

```sh
make p2-edge32-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
tio -b 230400 /dev/ttyUSB0
```

Basic REPL smoke tests for that image:

```berry
print(6*7)
s="abc"; print(s+"def")
m={"a":2,"b":5}; print(m["a"]+m["b"])
import math; print(math.sqrt(81))
import p2; print(p2.psram_info()); print(p2.psram_test())
```

If SD-backed imports or provisioning fail, inspect the mounted card from the
REPL:

```berry
import p2
print(p2.fs_info())
print(p2.fs_info(true)) # creates, reads, and removes /P2FSPROB.TXT
```

Useful fields are `mount_result_name`, `sector0_signature`,
`raw_sector0_result_name`, `dfs_sector0_result_name`, `sd_init_result_name`,
`partition_start`, `volinfo_result_name`, and the `sd_service_*` values. A
formatted FAT card usually reports boot signature `0xaa55` (`43605`) at sector
0. If sector 0 is invalid but a FAT boot sector is present at a common offset
such as `2048`, Berry falls back to that volume start; in that case
`mount_result_name` is `ok` and `partition_start` reports the selected sector.
If no candidate has a valid signature, SD calls return diagnostics instead of
hanging. Native firmware modules such as `math`, `string`, and `task` still
import without SD; optional SD libraries require the card to be formatted and
provisioned.

## P2 SD Smoke Suite

The non-destructive on-target smoke tests live under `tests/p2/`. Copy that
directory and `modules/` to the SD card root so the target sees paths such as
`/tests/p2/smoke_all.be` and optional SD libraries such as
`/modules/libstore.be`.

To provision those Berry libraries and tests through a running Berry REPL:

```sh
make p2-sd-sync TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
```

Use `make p2-sd-modules ...` when you only need to refresh `/modules`, or
`make p2-sd-tests ...` when you only need to refresh `/tests/p2`. These targets
expect Berry to be at the REPL prompt and the SD card to be mounted writable.

After Berry is running at the `berry>` prompt, the host can drive the suite over
serial with:

```sh
make p2-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
```

The smoke suite covers:

- core arithmetic, strings, maps, lists, ranges, and closures
- `string`, native `math`, native `task`, `json`, `bytes`, and grouped `p2`
 API coverage, including structured `p2.status_info()`, clock, cog, lock,
 pin, CORDIC/math, RNG, debug, ASM, and smart-pin basics
- lazy SD library import from `/modules`, including `binary_heap` and
 `libstore`; on edge32, `libstore` also smoke-tests chunked PSRAM source-cache
 round trips, discovered-module `cache_all()` warmup, and loading SD modules
 back from the PSRAM cache
- `p2.heap_info()`/`p2.sbrk()` allocator accounting: allocate transient objects,
 verify free-space drops, then GC and assert free-space is reclaimed
- Native cooperative `task` scheduler examples and `p2.cog` native-handle diagnostics
- SD create/read/readbytes/remove using only `/P2SMOKE.TXT`
- Current cooperative primitives under `task` and native cog-handle examples under `p2.cog`
- Smart-pin loopback coverage for the documented jumper pairs, including raw helper,
  GPIO, counter, PWM/NCO/pulse/transition, DAC/ADC, serial diagnostics, and
  aggregate one-way/bidirectional jumper summaries through `p2smart`

For the original short REPL check set:

```sh
make p2-smoke-quick TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
```

For the P2 Edge 32 MB RAM profile after `make p2-edge32-flash`, use:

```sh
make p2-smoke-edge32 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
```

That target runs `/tests/p2/smoke_edge32_all.be`, which includes the general
suite plus `p2.psram_info()`, `p2.psram_test()`, raw `p2.psram_read()` /
`p2.psram_write()`, chunked `libstore.cache_source()` assertions,
`libstore.cache_all()` for discovered SD modules, and `libstore.load("math")`
from the PSRAM source cache.

Current flash note:

- direct `loadp2 -SPI build/p2/catalina/full/berry_p2.binary` is not the Catalina flash path; Catalina binaries need the `flshload.t` wrapper generated by `make p2-flash`
- `make p2-flash` was verified on P2 Edge Rev D / P2 silicon rev G with `FLASH=ON, △=OFF, ▽=OFF`
- after flashing, reset or power-cycle the board and attach with `tio -b 230400 /dev/ttyUSB0`

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
make p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
make p2-run TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0
```

Sibling Catalina install example:

```sh
make p2-tools TOOLCHAIN=catalina CATALINA_DIR=../Catalina
```

This validates the external Catalina checkout layout and required compiler
tools. It does not download, clone, or patch Catalina.

Notes:

- FlexProp is still used for loader tools such as `loadp2`
- Catalina is not bootstrapped by this repository; set `CATALINA_DIR=../Catalina`
  or another explicit external Catalina checkout

## Windows PowerShell

Install:

- Git for Windows
- Python 3
- GNU Make

Recommended board port for the next session:

- `PORT=COM6`

Examples:

```powershell
make p2 TOOLCHAIN=catalina CATALINA_DIR=C:\tools\catalina
make p2-run TOOLCHAIN=catalina CATALINA_DIR=C:\tools\catalina PORT=COM6 LOADP2=C:\tools\flexprop\bin\loadp2.exe
```

Point the Make variables at external installations. The bootstrap helpers in
`tools/p2/bootstrap/` are only for FlexProp loader tooling.

Notes:

- the PowerShell FlexProp bootstrap expects either an existing `FLEXPROP_DIR` or a `FLEXPROP_ZIP_URL`
- Catalina is not bootstrapped by this repository; set `CATALINA_DIR` to an
  explicit external Catalina checkout

## Silicon Selection

Legacy FlexC commands, for old-toolchain debugging only:

```sh
make p2 TOOLCHAIN=flexc P2_SILICON=latest
make p2 TOOLCHAIN=flexc P2_SILICON=a
make p2-run TOOLCHAIN=flexc P2_SILICON=latest PORT=COM6
```

These FlexC commands are retained for old-toolchain debugging only. For normal
Berry P2 work, select silicon through the Catalina configuration and build with
`TOOLCHAIN=catalina`.

## Output Layout

P2 outputs are written under:

```text
build/p2/<toolchain>/<profile>/
```

Examples:

```text
build/p2/flexc/full/berry_p2.binary
build/p2/catalina/minimal/berry_p2.binary
build/p2/catalina/full/berry_p2.binary
```

## Current Primary Focus

The maintained day-to-day bring-up path is now:

- macOS
- `TOOLCHAIN=catalina`
- `CATALINA_PLATFORM=P2_EDGE`
- latest P2 silicon (Rev C / current silicon path)

Other paths remain available, but this is the one that should be used first
for ongoing Berry port work.
