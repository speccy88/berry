# Next Chat Handoff: P2 Edge 32 MB XMM Flash Boot

Date: 2026-06-06

## Current Goal

Continue the Berry interpreter port to Parallax Propeller 2, focused on P2 Edge
with 32 MB PSRAM and Catalina/lcc.

## Current Working State

- Normal COMPACT P2 Edge 32 MB PSRAM Catalina flash path still works:
 - `make p2-edge32-flash PORT=/dev/cu.usbserial-P97cvdxp TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88`
 - Boots `[edge32 profile]` from SPI flash.
- XMM unified-memory path now works over serial:
 - `make p2-xmm-run PORT=/dev/cu.usbserial-P97cvdxp TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88`
- XMM unified-memory path now works from standalone SPI flash:
 - `make p2-xmm-flash PORT=/dev/cu.usbserial-P97cvdxp TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88`
 - Reset or power-cycle afterward. Boot takes about `25-30` seconds before the
 Berry banner while the stage-2 loader copies the XMM image from flash to
 PSRAM.

## XMM Flash Implementation

- `p2-xmm-flash` builds `build/p2/catalina/xmm/berry_p2_xmm_flash.binary`.
- Flash image layout:
 - `0x00000`: checksum-patched 1024-byte P2 ROM boot block
 - `0x10000`: size-prefixed stage-2 flash-to-PSRAM loader
 - `0x40000`: size-prefixed Berry Catalina XMM image
- It writes the composite image with stock FlexProp `loadp2` high-memory flash:
 - `loadp2 -HIMEM=flash @80000000=build/p2/catalina/xmm/berry_p2_xmm_flash.binary`
- Upstream `loadp2` PR opened for a friendlier alias:
 - `https://github.com/totalspectrum/loadp2/pull/10`
 - Adds `-FLASHRAW image.binary`, equivalent to writing a prebuilt bootable
 image directly to SPI flash offset 0.

## Verified On Hardware

Standalone XMM flash boot banner from the latest verified image:

```text
[Catalina] on Propeller 2 Edge (P2_EDGE, PSRAM) [xmm profile]
[image 1225376 B | code 543352 B | const 20636 B | init 7564 B | data 587768 B]
[heap 524288 B | stack 1024 slots | bytes max 4096 B]
[external 33554432 B PSRAM | XMM 16777216 B | block 16777216 B @ 16777216 | Berry heap external]
```

Standalone XMM flash REPL checks passed:

```berry
print(6*7) # 42
s="abc"; print(s+"def") # abcdef
m={"a":2,"b":5}; print(m["a"]+m["b"]) # 7
```

Runtime diagnostics passed:

```berry
import p2; print(p2.status_info()["build"]["profile"]) # xmm
import p2; print(p2.heap_info()) # external_heap true
import p2; print(p2.psram_info()) # access xmm+block
```

C allocator checks passed from standalone XMM flash boot:

```berry
import p2; print(p2.c_allocator_test(262144)) # ok true
import p2; print(p2.c_allocator_test(1048576)) # ok true
```

SD/module status from latest hardware verification:

```berry
import p2
f = p2.fs_info("/")
print(f["mount_result_name"], f["partition_start"], f["volinfo_result_name"])
import math; print(math.sqrt(81))
```

returns on the current P2 Edge 32 MB card/image:

```text
ok 2048 ok
9
```

The current SD card has an invalid sector 0 signature, but a valid FAT boot
sector at sector `2048`. Berry now falls back to common FAT starts when MBR
sector 0 is invalid. RAM-loaded `edge32` and standalone flash-booted `edge32`
both mount the card and load `/modules/math.be`.

## SD Root Cause Fixed In This Workstream

- `tools/p2/bootstrap/patch-catalina-p2.sh` patch stamp is
 `berry-p2-patch-v23`.
- Catalina DOSFS direct SD stubs are rebuilt with
 `__BERRY_P2_DIRECT_SD_IO=1`, avoiding Catalina's upper-PSRAM SD cache in
 PSRAM/XMM builds and avoiding the auto-started Catalina `-lcx` SD plugin in
 Berry's direct-SD profile.
- The replacement `sd_sectread()` / `sd_sectwrite()` stubs now compile with the
 active `CATALINA_MODEL`. This is critical: compiling them unconditionally as
 `LARGE` made the COMPACT `edge32` image hang on raw `sd_sectread()`.
- The low-level SD service lock now fails fast as `sd_busy` instead of spinning
 indefinitely on a stale/held lock.
- Berry avoids Catalina `_mount()` and performs the same partition/volume setup
 with one static sector buffer, reducing stack pressure in the near-full Hub
 image.
- Berry's mount path now validates FAT boot signatures and falls back to common
 volume starts (`2048`, `8192`, `32768`, `63`, `1`) when sector 0 is not a
 valid MBR/superfloppy boot sector.
- The flash deep-power-down call before SD activity is intentional. P2 Edge boot
 flash and microSD share pins `58..61`; putting flash to sleep before SD
 transfers prevents the flash chip from driving the shared MISO line.
- `p2.fs_info()` exposes SD service, raw sector, partition, and volume
 diagnostics without printing trace noise during normal use.

## Files Changed In This Workstream

- `mk/p2.mk`
- `tools/p2/loader/build-catalina-xmm-tools.sh`
- `tools/p2/loader/build-catalina-xmm-flash-image.sh`
- `tools/p2/loader/catalina_xmm_flash_loader.c`
- `tools/p2/loader/compose-catalina-xmm-flash.py`
- `tools/p2/loader/flshboot_xmm_stage1.t`
- `port/p2/overrides/be_p2lib_p2.c`
- `port/p2/include/berry_port.h`
- `port/p2/runtime/berry_port.c`
- `tests/p2/smoke_allocator.be`
- `tools/p2/bootstrap/patch-catalina-p2.sh`
- `docs/P2_BUILD.md`
- `port/p2/docs/PORTING_STATUS.md`
- `port/p2/docs/P2_EDGE32_SD_XMM_HANDOFF.md`

## Important Cautions

- Do not use FlexC for normal P2 validation; Catalina is the verified path.
- Keep `P2_BOARD` separate from `P2_PROFILE` and `P2_SILICON`:
 - `P2_BOARD=p2edge` is the no-PSRAM P2 Edge pinout with onboard LEDs on
 pins `56` and `57`.
 - `P2_BOARD=p2edge32` is the P2 Edge 32 MB RAM pinout with onboard LEDs on
 pins `38` and `39`; pins `40..57` are reserved for PSRAM.
 - Catalina's own `target/p2/P2EDGE.inc` documents the 32 MB PSRAM mapping:
 data bus starts at pin `40`, PSRAM clock is `56`, PSRAM chip-select is
 `57`, and `_DEBUG_PIN` is `38`.
 - Binary release builds should set `P2_BOARD` explicitly.
- Old silicon is selected with `P2_SILICON=a`; current B/C silicon uses
 `P2_SILICON=latest|b|c`.
- Do not break the normal `edge32` no-XMM flash target. It remains the recovery
 image.
- `P2_PROFILE=xmm` must keep Catalina `LARGE` and `-C PSRAM`; losing `-C P2_EDGE
 -C LARGE` causes an invalid/non-XMM layout.
- XMM flash boot is slow by design because it copies from SPI flash to PSRAM on
 every reset.
- Be careful with serial control during hardware tests: opening
 `/dev/cu.usbserial-P97cvdxp` with a generic serial client can toggle DTR/RTS
 and reset the board. Prefer one controlled `loadp2 -t` session, `tio` for
 attach, or a wrapper where `loadp2` owns the reset behavior.
