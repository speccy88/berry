# P2 Edge 32 MB SD/XMM Handoff

Date: 2026-06-06

## Current Update

- SD/module loading is now live-verified on the P2 Edge 32 MB RAM board.
- Latest root cause: the SD card answered raw SPI reads, but sector 0 was not a
 valid MBR/FAT boot sector (`sector0_signature == 65535`). A valid FAT boot
 sector was found at sector `2048`.
- Berry now falls back to common FAT volume starts when sector 0 is invalid.
 `p2.fs_info("/")` reports `mount_result_name == "ok"`,
 `partition_start == 2048`, and `volinfo_result_name == "ok"`.
- `import math; print(math.sqrt(81))` prints `9` from both RAM-loaded `edge32`
 and standalone flash-booted `edge32`.
- Catalina patch stamp is now `berry-p2-patch-v23`; the direct-SD profile also
 disables Catalina's auto-started `-lcx` SD plugin with
 `-C BERRY_P2_DIRECT_SD_IO`.

## What Changed

- Fixed the SD/import hang path for Catalina P2 Edge builds.
- `tools/p2/bootstrap/patch-catalina-p2.sh` is now at patch stamp
 `berry-p2-patch-v23`.
- Catalina DOSFS is patched to use direct Hub bounce-buffer SD I/O instead of
 the PSRAM SD sector cache.
- The patched `sd_sectread()` / `sd_sectwrite()` stubs now compile with the
 active `CATALINA_MODEL`.
 - This was the root issue for the COMPACT `edge32` hang: compiling these
 stubs unconditionally as `LARGE` made raw `sd_sectread()` never return.
 - XMM still compiles them as `LARGE` because the XMM profile sets
 `CATALINA_MODEL=LARGE`.
- The patched SD service wrapper now fails fast on a held service lock instead
 of spinning forever.
- Berry no longer calls Catalina `_mount()` directly. It performs the same
 partition/volume setup with one static sector buffer and updates Catalina
 `__pstart` / `__vi`, avoiding extra stack pressure in the near-full Hub image.
- `p2.fs_info()` now exposes useful SD diagnostics without noisy trace prints.

## Verified Hardware Results

Hardware:

- P2 Edge 32 MB board on `/dev/cu.usbserial-P97cvdxp`
- native macOS Catalina/lcc:
 `/Users/fred/Documents/Code/catalina-speccy88`

Verified `edge32` flash:

```sh
make p2-edge32-flash PORT=/dev/cu.usbserial-P97cvdxp TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88
```

- Boots from SPI flash.
- Current image: `499008` bytes.
- Basic REPL checks pass:
 - `print(6*7)` -> `42`
 - `s="abc"; print(s+"def")` -> `abcdef`
 - `m={"a":2,"b":5}; print(m["a"]+m["b"])` -> `7`
- SD-backed `import math; print(math.sqrt(81))` now prints `9`.

Verified standalone XMM flash:

```sh
make p2-xmm-flash PORT=/dev/cu.usbserial-P97cvdxp TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88
```

- Boots from SPI flash after the expected roughly 25-30 second copy delay.
- Current image: `1225376` bytes.
- Banner reports `[xmm profile]`, `Berry heap external`, `XMM 16777216 B`, and
 `block 16777216 B @ 16777216`.
- `p2.heap_info()` reports `external_heap: true`.
- `p2.c_allocator_test(262144)` returns `ok: true`.
- Basic REPL checks pass.

## Current SD Card Diagnosis

On the current P2 Edge 32 MB card/image:

```berry
import p2
f = p2.fs_info("/")
print(f["mount_result_name"], f["partition_start"], f["volinfo_result_name"])
import math
print(math.sqrt(81))
```

returns:

```text
ok 2048 ok
9
```

Meaning:

- The SD card answers raw SPI and has a valid FAT boot sector at sector `2048`.
- Sector 0 is not a valid MBR/FAT boot sector, so Berry uses its common-start
 fallback and mounts at sector `2048`.
- `/modules/math.be` is visible and imports from SD.

## Problems Found

- Catalina's PSRAM SD sector cache conflicts with Berry's intended PSRAM block
 window, so XMM/PSRAM builds need direct SD I/O through Hub bounce buffers.
- The first patched sector stubs were compiled as `LARGE` for every profile.
 That was wrong for COMPACT `edge32` and caused raw `sd_sectread()` to hang.
- Heavy `printf()` tracing inside low-level SD sector stubs produced a bad boot
 image; diagnostics belong in `p2.fs_info()`, not inside the sector service.
- Catalina `_mount()` allocates another sector buffer on the C stack. The P2 Hub
 image is close enough to the 512 KiB limit that Berry now avoids that path and
 uses a static mount scratch buffer.
- Catalina `-lcx` auto-started its SD plugin. Berry's direct-SD build now passes
 `-C BERRY_P2_DIRECT_SD_IO`, and the Catalina patch gates that auto-plugin off
 for this profile.
- The current SD card has no usable sector-0 partition table, but a valid FAT
 boot sector at `2048`; Berry now falls back to common FAT starts.

## Next Step

Run the full scripted SD smoke suite against the provisioned card:

```berry
import p2
print(p2.fs_info("/"))
import math
print(math.sqrt(81))
```

Expected when the card is good:

- `mount_result_name` should be `ok`.
- `partition_start` should be a valid FAT start for the card, currently `2048`
 on the swapped card.
- `volinfo_result_name` should be `ok`.
- `import math; print(math.sqrt(81))` should print `9`.
