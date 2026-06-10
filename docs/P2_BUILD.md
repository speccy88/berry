# P2 Build

## Supported Interface

```sh
make configure
make show-config
make p2 TOOLCHAIN=catalina
make p2-minimal
make p2-full
make p2-edge32
make p2-edge32-flash
make p2-xmm
make p2-xmm-run
make p2-xmm-flash
make p2-run TOOLCHAIN=catalina PORT=COM5
make p2-ram TOOLCHAIN=catalina PORT=/dev/ttyUSB0
make p2-flash TOOLCHAIN=catalina PORT=/dev/ttyUSB0
make p2-stop
make p2-clean
make p2-tools TOOLCHAIN=catalina
make p2-prebuild
```

Catalina is the preferred and verified toolchain for compiling Berry on P2.
The FlexC targets remain in the makefiles as legacy/debugging support, but the
normal workflow should not try to build Berry with FlexC unless that is the
specific task.

## Required Variables

- `TOOLCHAIN=catalina`
- `PORT=...`
- `P2_PROFILE=minimal|full|edge32|xmm` when not using a convenience profile target
- `P2_BOARD=auto|p2edge|p2edge32` for the physical board pinout. `auto`
 maps `full`/`minimal` to `p2edge` and `edge32`/`xmm` to `p2edge32`.
- `P2_SILICON=a|latest|b|c` for old silicon versus current B/C silicon
 code generation.
- `CATALINA_DIR=...`
- `LOADP2=...` for the loader from FlexProp

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

- `minimal`: core language and standard classes plus the `string` module. It disables filesystem, JSON, math, OS, P2 hardware modules, retired worker/RTOS/Spin2 helpers, and low-level `prop2_*` globals. Current verified image: `426624` bytes with a `192 KiB` main heap.
- `full`: the current no-PSRAM P2 Edge build. Current verified image: `494624` bytes with the existing `128 KiB` main heap, SD-backed `open()`/`os`, P2 hardware modules, native `task`, native `math`, and WiFiNINA helpers available as optional source. The older `rtos`, `worker`, `threads`, and `taskspin` APIs are retired from the active surface.
- `edge32`: P2 Edge 32 MB RAM profile for the P2-EC32MB-style board. It enables Catalina `-lpsram`, reserves pins `40..57` for the memory interface, keeps Berry's object heap in Hub RAM, and exposes bounded PSRAM block transfers plus an SD-library source cache for runtime smoke testing. Current verified image: `506080` bytes with a `128 KiB` main heap and `16 KiB` worker heap, leaving Hub RAM room for the PSRAM plugin.
- `xmm`: experimental P2 Edge 32 MB RAM profile using Catalina `LARGE` plus `-lpsram` and `-C PSRAM`. This is the first clean unified-memory experiment: Berry still calls the same `p2_heap_malloc()` allocator, but the Catalina XMM memory model places the backing C data arena in external RAM so the VM does not need separate Hub-vs-PSRAM object rules. Catalina can use the lower `16 MiB` of P2 Edge PSRAM as XMM memory today; Berry keeps the upper `16 MiB` exposed as the explicit PSRAM block/cache window. Current hardware-verified image: `726432` bytes with a `15728640` byte Berry heap and `Berry heap in PSRAM` at runtime.

Library loading policy (`modules/libstore.be`) on P2:

- `libstore.POLICY_SD_LAZY` (`sd_only`): keep library execution SD-file-first, no PSRAM cache.
- `libstore.POLICY_SD_CACHE_PSRAM` (`sd_cache_psram`): mirror SD module source into PSRAM cache on demand before execution.
- `libstore.POLICY_SD_PRELOAD_PSRAM` (`sd_preload_psram`): same strategy, with optional eager preload.

At runtime:

- `libstore.policy()` reports the active policy.
- `libstore.set_policy(libstore.POLICY_SD_PRELOAD_PSRAM, true)` can request preload caching.

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
make p2-xmm-run PORT=/dev/cu.usbserial-P97cvdxp TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88
```

Install the experimental XMM image for standalone SPI-flash boot:

```sh
make p2-xmm-flash PORT=/dev/cu.usbserial-P97cvdxp TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88
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
make p2 TOOLCHAIN=catalina P2_PROFILE=minimal P2_BOARD=p2edge CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=
```

P2 Edge 32 MB RAM explicit form:

```sh
make p2 TOOLCHAIN=catalina P2_PROFILE=edge32 P2_BOARD=p2edge32 CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram
```

Experimental unified-memory XMM explicit form:

```sh
make p2 TOOLCHAIN=catalina P2_PROFILE=xmm P2_BOARD=p2edge32 CATALINA_MODEL=LARGE CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram CATALINA_CONFIG_FLAGS="-C P2_EDGE -C LARGE -C SIMPLE -C VT100 -C NO_ARGS -C PSRAM"
```

## Local Environment Defaults

You can save your current P2 environment once and stop repeating the same
flags on every command:

```sh
make configure \
 TOOLCHAIN=catalina \
 PORT=/dev/cu.usbserial-P97cvdxp \
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
- `berry_p2.binary` is checked against the P2 Hub RAM limit of `524288` bytes; oversized builds fail before the target image is published
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
tio -b 230400 /dev/cu.usbserial-P97cvdxp
```

For a P2 Edge Rev D with the 32 MB RAM module:

```sh
make p2-edge32-flash PORT=/dev/cu.usbserial-P97cvdxp CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88
tio -b 230400 /dev/cu.usbserial-P97cvdxp
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
make p2-sd-sync PORT=/dev/cu.usbserial-P97cvdxp
```

Use `make p2-sd-modules ...` when you only need to refresh `/modules`, or
`make p2-sd-tests ...` when you only need to refresh `/tests/p2`. These targets
expect Berry to be at the REPL prompt and the SD card to be mounted writable.

After Berry is running at the `berry>` prompt, the host can drive the suite over
serial with:

```sh
make p2-smoke PORT=/dev/cu.usbserial-P97cvdxp
```

The smoke suite covers:

- core arithmetic, strings, maps, lists, ranges, and closures
- `string`, native `math`, native `task`, `json`, `bytes`, and `p2` module basics,
 including structured `p2.status_info()` diagnostics
- lazy SD library import from `/modules`, including `binary_heap` and
 `libstore`; on edge32, `libstore` also smoke-tests chunked PSRAM source-cache
 round trips, discovered-module `cache_all()` warmup, and loading SD modules
 back from the PSRAM cache
- `p2.heap_info()`/`p2.sbrk()` allocator accounting: allocate transient objects,
 verify free-space drops, then GC and assert free-space is reclaimed
- Native cooperative `task` scheduler examples and `p2.cog` native-handle diagnostics
- SD create/read/readbytes/remove using only `/P2SMOKE.TXT`
- Current cooperative primitives under `task` and native cog-handle examples under `p2.cog`

For the original short REPL check set:

```sh
make p2-smoke-quick PORT=/dev/cu.usbserial-P97cvdxp
```

For the P2 Edge 32 MB RAM profile after `make p2-edge32-flash`, use:

```sh
make p2-smoke-edge32 PORT=/dev/cu.usbserial-P97cvdxp
```

That target runs `/tests/p2/smoke_edge32_all.be`, which includes the general
suite plus `p2.psram_info()`, `p2.psram_test()`, raw `p2.psram_read()` /
`p2.psram_write()`, chunked `libstore.cache_source()` assertions,
`libstore.cache_all()` for discovered SD modules, and `libstore.load("math")`
from the PSRAM source cache.

Current flash note:

- direct `loadp2 -SPI build/p2/catalina/full/berry_p2.binary` is not the Catalina flash path; Catalina binaries need the `flshload.t` wrapper generated by `make p2-flash`
- `make p2-flash` was verified on P2 Edge Rev D / P2 silicon rev G with `FLASH=ON, △=OFF, ▽=OFF`
- after flashing, reset or power-cycle the board and attach with `tio -b 230400 /dev/cu.usbserial-P97cvdxp`

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
make p2 TOOLCHAIN=catalina CATALINA_DIR=/opt/catalina
make p2-run TOOLCHAIN=catalina PORT=/dev/ttyUSB0 LOADP2=/opt/flexprop/bin/loadp2
```

Bootstrap-managed cache examples:

```sh
make p2-tools TOOLCHAIN=catalina CATALINA_DIR=.third_party_cache/catalina
```

Notes:

- FlexProp is still used for loader tools such as `loadp2`
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
make p2 TOOLCHAIN=catalina CATALINA_DIR=C:\tools\catalina
make p2-run TOOLCHAIN=catalina PORT=COM6 LOADP2=C:\tools\flexprop\bin\loadp2.exe
```

If you already have external installations, point the Make variables at them. If not, use the bootstrap helpers in `tools/p2/bootstrap/`.

Notes:

- the PowerShell FlexProp bootstrap expects either an existing `FLEXPROP_DIR` or a `FLEXPROP_ZIP_URL`
- the PowerShell Catalina bootstrap expects either an existing `CATALINA_DIR` or `CATALINA_REPO`

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
