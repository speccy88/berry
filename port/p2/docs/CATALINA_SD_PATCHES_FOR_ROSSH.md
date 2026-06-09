# Catalina P2 Edge/XMM SD changes for RossH

Date: 2026-06-07

This note only records the Catalina-repo changes that were needed to make the P2 Edge32 SD card path reliable for Berry on both normal Edge32 and standalone XMM builds.

Berry-side loader/build fixes, historical failed experiments, raw diagnostic helpers, and project roadmap items are intentionally excluded from this file.

## Repository under test

Local Catalina fork:

```text
/Users/fred/Documents/Code/catalina-speccy88
```

Berry validation repo:

```text
/Users/fred/Documents/Code/berry
```

Board:

```text
P2 Edge32 on /dev/cu.usbserial-P97cvdxp
```

## Final hardware evidence

After the Catalina changes below were built into Berry:

- `make p2-edge32-ram TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88 PORT=/dev/cu.usbserial-P97cvdxp`
  - reached `[edge32 profile]`
  - imported `p2` and `os`
  - `p2.fs_info("/")` returned `mount_result_name='ok'`, `sd_response=0`, `partition_start=2048`
  - `os.listdir("/")` returned `[]`

- `make p2-edge32-flash TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88 PORT=/dev/cu.usbserial-P97cvdxp`
  - reached `[edge32 profile]`
  - full Berry `file`, `os`, and `os.path` checklist passed on SD
  - test file and directory were removed and root returned to `[]`

- `make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88 CATALINA_PLAIN_SD=1 PORT=/dev/cu.usbserial-P97cvdxp`
  - reached `[xmm profile]`
  - banner reported `image 769408 B`, `code 636504 B`
  - `p2.fs_info("/")` returned `mount_result_name='ok'`, `sd_response=0`, `partition_start=2048`, FAT32
  - full Berry `file`, `os`, and `os.path` checklist passed on SD
  - test file and directory were removed and root returned to `[]`

The SD card was not corrupted during the final normal API validation passes.

## Catalina source changes that matter

### 1. `target/p2/cogsd.t`: P2 Edge shared flash/SD bus handling

Problem:

- P2 Edge shares pins `58..61` between the boot flash and SD card.
- The flash and SD use the same physical pins with flash clock/select crossing SD select/clock:
  - `FLASH_DO = _SD_DO`
  - `FLASH_DI = _SD_DI`
  - `FLASH_CK = _SD_CS`
  - `FLASH_CS = _SD_CK`
- In standalone XMM boot, the boot flash has just been used heavily before Catalina starts SD access.
- If flash is not put into deep power-down, or if the shared pins are left in the wrong order/state, SD initialization can see only `0xff` responses or fail later sector reads.

Required changes:

- Add P2 Edge/P2 custom flash constants in `cogsd.t`:

```spin
#if defined(P2_EDGE) || defined(P2_CUSTOM)
FLASH_DO       = _SD_DO
FLASH_DI       = _SD_DI
FLASH_CK       = _SD_CS
FLASH_CS       = _SD_CK
FLASH_RESET_ENABLE = $66
FLASH_RESET_MEMORY = $99
FLASH_DEEP_POWER_DOWN = $B9
#endif
```

- Call `_Flash_Sleep` when the SD service cog starts and again before `_SDcard_Init`:

```spin
#if defined(P2_EDGE) || defined(P2_CUSTOM)
          call    #_Flash_Sleep
#endif
```

- Leave the SD service uninitialized at cog startup and initialize on the first real SD request:

```spin
          mov     sd_initialized,#0
```

- In `.SD_Read` and `.SD_Write`, initialize on demand, and reinitialize if `_SD_Ready` reports the card is not ready.

- Add a bounded first-request settle/init wrapper:

```spin
_SDcard_Init_Retry
                tjnz    sd_startup_wait_done,#.do_init
                mov     sd_startup_wait_done,#1
                mov     sd_init_retries,  #10
.settle         waitx   ##delay1s
                djnz    sd_init_retries,  #.settle
.do_init        call    #_SDcard_Init
                ret
```

- Add state variables near the other SD state:

```spin
sd_initialized  long    0
sd_init_retries long    0
sd_startup_wait_done long 0
```

- Add `_Flash_Sleep`, `_Flash_Command`, and `_Flash_SendByte`.

The important ordering rule is the part that fixed the intermittent/all-`0xff` behavior:

```spin
_Flash_Command
                drvh    #FLASH_CS
                drvh    #FLASH_CK
                drvl    #FLASH_DI
                fltl    #FLASH_DO
                waitx   ##delay5us
                drvl    #FLASH_CS
                drvl    #FLASH_CK
                call    #_Flash_SendByte
                drvh    #FLASH_CK                         ' SD /CS=1 while flash is idle
                drvh    #FLASH_CS
                drvh    #FLASH_DI
        _RET_   waitx   ##delay5us
```

Because `FLASH_CK == _SD_CS` and `FLASH_CS == _SD_CK`, the ordering avoids asserting SD `/CS` while SD clock is high during flash-management commands.

At the end of `_Flash_Sleep`, leave both shared devices deselected:

```spin
                drvh    #_SD_CS                         ' SD /CS=1 (flash CK high)
                drvh    #_SD_CK                         ' SD CLK=1 (flash /CS high; both chips deselected)
                drvh    #_SD_DI                         ' SD DI=1
        _RET_   fltl    #_SD_DO                         ' SD DO=input
```

Why it mattered:

- Before this, standalone XMM SD init often failed before FAT parsing with all-high responses such as `sd_response=255`.
- After the shared-pin ordering fix, XMM standalone mounted the FAT32 card at sector `2048` and passed read/write file tests.

### 2. `source/lib/catalina/secread.c`: bounded service request and Hub bounce buffer for LARGE

Problem:

- In XMM/LARGE, caller buffers and automatic/local storage may not be suitable for the SD service cog's sector transfer expectations.
- Unbounded service waits could wedge Berry if the SD service did not complete a request.

Required changes:

- Use a bounded `sd_service_2_timed()` helper instead of waiting forever.
- Acquire the Catalina service lock with `_locktry()` and fail cleanly if busy.
- Clear the request and return a timeout error if the service does not finish.
- For `__CATALINA_LARGE`, allocate the sector bounce buffer and service parameter block in Hub RAM with `hub_malloc()`:

```c
#ifdef __CATALINA_LARGE
#include <hmalloc.h>
#endif
```

```c
#ifdef __CATALINA_LARGE
static char *sd_sector_read_buffer;
static volatile long *sd_service_params;
#endif
```

The read path then calls the SD service using the Hub bounce buffer and copies data back to the caller buffer:

```c
retval = sd_service_2_timed(SVC_SD_READ, (long)bounce, sector);
for (i = 0; i < __CATALINA_SECTOR_SIZE; i++) {
   buffer[i] = bounce[i];
}
return retval;
```

Why it mattered:

- This made XMM SD failures return to the caller instead of wedging the REPL.
- It also prevents the SD service from being handed unsuitable XMM/LARGE buffers for 512-byte sector I/O.

### 3. `source/lib/catalina/secwrite.c`: bounded service request and Hub bounce buffer for LARGE

Problem:

- The write path has the same LARGE/XMM buffer and unbounded-wait hazards as the read path.

Required changes:

- Use the same bounded `sd_service_2_timed()` pattern as `secread.c`.
- For `__CATALINA_LARGE`, allocate Hub RAM bounce buffer and service parameter block with `hub_malloc()`.
- Copy from the caller buffer into the Hub bounce buffer before `SVC_SD_WRITE`:

```c
for (i = 0; i < __CATALINA_SECTOR_SIZE; i++) {
   bounce[i] = buffer[i];
}
retval = sd_service_2_timed(SVC_SD_WRITE, (long)bounce, sector);
return retval;
```

Why it mattered:

- XMM SD write/create tests stopped hanging and passed the normal Berry file API validation after the bus-handoff issue was also fixed.

### 4. `source/lib/io/dwrite.c`: write-result assignment precedence

Problem:

- `DFS_WriteSector()` must retry based on the real result of `sectwrite()`.
- The local Catalina source was corrected so assignment happens before comparison.

Required form:

```c
if ((result = sectwrite((char *)buffer, sector)) == 0) {
   break;
}
```

and for counted writes:

```c
if ((result = sectwrite((char *)(buffer + 512*i), sector + i)) == 0) {
   break;
}
```

Why it mattered:

- This preserves the actual SD write return code for retry/error handling instead of collapsing it through the comparison expression.

## Required library rebuild/install step

Changing the Catalina C sources is not enough. The P2/LARGE libraries used by Berry XMM must be regenerated and installed into the Catalina fork's library tree.

At minimum, after changing the SD service/DOSFS sources, rebuild the relevant P2 LARGE `cx` assembly objects and refresh `catalina.idx` in:

```text
/Users/fred/Documents/Code/catalina-speccy88/lib/p2/xmm/cx
```

Objects involved in this repair/testing included:

```text
secread.s
secwrite.s
dwrite.s
```

Earlier testing was misleading when stale installed XMM `cx` objects were still being linked, even though the source files had been edited.

## What is intentionally not part of the RossH request

These were useful during diagnosis but should not be presented as required Catalina SD fixes:

- Berry's standalone XMM flash loader/stage1 handoff changes.
- Berry `p2.fs_info()` diagnostics and raw SD probe helpers.
- Slow generic SPI timing experiments.
- Longer CMD0 timeout experiments.
- Temporary staged diagnostic return-code bands such as `0x600`, `0x700`, and `0x800` unless RossH wants a documented diagnostic API.
- Patch-script machinery from the Berry repo.
- Berry module/file/os implementation details.

## Current upstream-facing summary

The SD-card issue was ultimately not FAT layout alone. The card's FAT32 volume starts at sector `2048`, and Catalina/Berry can mount it correctly once sector I/O is reliable.

The Catalina-side fixes needed for reliable SD service behavior on this P2 Edge32/XMM configuration are:

1. Handle the P2 Edge shared boot-flash/SD pins in `target/p2/cogsd.t`.
2. Put the boot flash into deep power-down before SD initialization.
3. Preserve safe shared-pin ordering because flash `CLK` is SD `/CS` and flash `/CS` is SD `CLK`.
4. Initialize/reinitialize the SD card on demand instead of assuming startup init remains valid.
5. Use bounded SD service waits instead of infinite spins.
6. Use Hub-resident sector bounce buffers and parameter blocks for LARGE/XMM service calls.
7. Preserve real write error results in `DFS_WriteSector()`.
8. Rebuild/install the generated P2/XMM library objects so the fixed sources are actually linked.
