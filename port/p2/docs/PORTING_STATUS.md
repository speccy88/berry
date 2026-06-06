# Berry on Propeller 2: Porting Status

This note is the handoff for the next P2 porting session.

## Where the Port Is

- The repository layout is now cleaned up so P2 work lives under `port/p2/`, `mk/`, and `tools/p2/`.
- A repo-local P2 environment file can now be written with `make configure`, so repeated `TOOLCHAIN`, `PORT`, and silicon flags are no longer required once the machine is configured.
- The P2 build interface is now:
  - `make configure`
  - `make show-config`
  - `make p2 TOOLCHAIN=catalina`
  - `make p2-run TOOLCHAIN=catalina PORT=...`
  - `make p2-ram`
  - `make p2-flash`
  - `make p2-edge32`
  - `make p2-edge32-flash`
- P2 silicon selection still supports:
  - `P2_SILICON=a` -> `-2a`
  - `P2_SILICON=latest|b|c` -> `-2`
- The primary focus path is now macOS + Catalina + `P2_EDGE` + latest silicon (Rev C / current silicon path).
- Other build paths should stay available as legacy/debugging support, but do not spend normal bring-up time trying to compile Berry with FlexC. Catalina is the verified path and the first one to validate.

## What Was Last Verified

On the current macOS Catalina P2 Edge path (latest silicon / Rev C focus):

- `make p2 TOOLCHAIN=catalina CATALINA_USE_DOCKER=1 CATALINA_DIR=.third_party_cache/catalina-v8.8.9-build` builds a RAM image with Catalina 8.8.9:
  - image: `494304` bytes
  - code: `248128` bytes
  - const: `18220` bytes
  - init: `7360` bytes
  - data: `210420` bytes
- `make p2-edge32 CATALINA_USE_DOCKER=1 CATALINA_DIR=.third_party_cache/catalina-v8.8.9-build` builds the P2 Edge 32 MB RAM profile:
  - image: `485024` bytes
  - code: `250464` bytes
  - const: `18508` bytes
  - init: `7440` bytes
  - data: `194036` bytes
- `make p2-edge32-flash PORT=/dev/cu.usbserial-P97cvdxp CATALINA_USE_DOCKER=1 CATALINA_DIR=.third_party_cache/catalina-v8.8.9-build` flashed and booted from flash on the P2 Edge 32 MB RAM board. The boot banner reported `P2_EDGE, PSRAM`, `[edge32 profile]`, `131072 B` heap, and `33554432 B` PSRAM block API.
- `make p2-run TOOLCHAIN=catalina CATALINA_USE_DOCKER=1 CATALINA_DIR=.third_party_cache/catalina-v8.8.9-build PORT=/dev/cu.usbserial-P97cvdxp` RAM-loads and reaches the Berry prompt
- Non-destructive SD smoke tests now live under `tests/p2/` and can be driven
  from the host with `make p2-smoke`, `make p2-smoke-quick`, and
  `make p2-smoke-edge32` once that directory and `modules/` have been copied to
  the SD card.
- P2 VMs add `/modules` as a default lazy import root, so optional `.be`
  libraries can live on SD. `modules/libstore.be` reports the SD-first model and
  can mirror source text into PSRAM on edge32 while keeping live Berry objects in
  Hub RAM.
- `modules/math.be` now provides the P2 `math` smoke-test surface from SD,
  avoiding the Catalina/P2 native math path and saving Hub image space.
- `modules/taskspin.be` provides a 32-slot Spin2-shaped cooperative task API
  from SD, keeping this experiment out of the Hub firmware image.
- P2 cached module loading is live-verified after the Catalina const native function hang fix:
  - `import p2`; `print(p2.cogid())` -> `0`
  - `p2.psram_info()`, `p2.psram_test()`, bounded `p2.psram_read()` /
    `p2.psram_write()`, and `libstore.cache_source()` are now exposed for the P2
    Edge 32 MB RAM profile and live-verified on the P2 Edge 32 MB board
  - `make p2-edge32-flash PORT=/dev/cu.usbserial-P97cvdxp ...` boots from flash,
    and the quick REPL smoke passes: `print(6*7)` -> `42`, string concat ->
    `abcdef`, map lookup -> `7`, and SD-loaded `math.sqrt(81)` -> `9`
  - direct edge32 PSRAM/library-cache REPL checks pass:
    `p2.psram_test()["ok"]` -> `true`,
    `p2.psram_read(29*1024*1024, 5)` after writing `"cache"` -> `cache`, and
    `libstore.cache_source("binary_heap")` / `libstore.cached_source(...)`
    round-trip `1565` bytes
  - `import i2c`; `i2c.init(25,24,400)` returns to the prompt
  - `import spi`; `spi.init(10,11,12,13,0,1000)` returns to the prompt
  - `import rtos`; locks, queues, flags, timers, callbacks, debug helpers, and process-style `rtos.newcog("name", ...int_args)` launch work through the current child VM backend
  - `import spin2`; `print(spin2.path())` -> `/spin2`
  - `import wifi` compiles and imports when `modules/wifi.be` is present on SD/module path; hardware detection on the ESP32-C6 AirLift board is still pending READY/BUSY troubleshooting
- P2 pins on the no-PSRAM P2 Edge path:
  - `p2.pinmode(56,p2.OUTPUT); p2.low(56); print(p2.read(56))` -> `0`
  - `p2.high(56); print(p2.read(56))` -> `1`
  - pin `57` must be tested with `CATALINA_MODEL=COMPACT`, `CATALINA_CLIB=-lcx`, and no `-lpsram`; Catalina PSRAM builds reserve it as memory chip-select
- BMP180 on `SCL=25`, `SDA=24`:
  - `i2c.init(25,24,400)`
  - `print(i2c.scan())` -> `[119]`
  - `print(i2c.present(0x77))` -> `true`
  - `print(i2c.writeread(0x77,"\xD0",1))` -> `U` (`0x55`, BMP180 chip id)
- RTOS path:
  - `import rtos`; `print(rtos.cog_id())` -> `0`
  - `rtos.channel("a"); rtos.put("a",123); print(rtos.get("a",10))` -> `123`
  - `rtos.event_set(1); print(rtos.event_wait(1,10)); rtos.event_clear(1)` -> `true`
  - `t=rtos.timer_start(10); rtos.timer_wait(t); print(rtos.timer_expired(t))` -> `true`
  - deferred callback dispatch with `rtos.irq_enable(0,"on_rtos")`, `rtos.event_set(1)`, `print(rtos.irq_poll())` -> `1`
  - `rtos.load(source); cog=rtos.newcog("worker_fn",7)` starts explicitly loaded child-VM code on the process cog; direct `rtos.newcog(function, ...)` is intentionally guarded until safe closure transfer exists
- `spin2.path()` returns `/spin2`; `spin2.list()` returned `[]` when no compatible binaries were present on the SD-visible path
- `os.listdir("/")` returns the current SD root after filtering stale/non-printable DOSFS entries; the latest card listed `SPIN2`, `HELLO.TXT`, `NEWTEST.BIN`, `INDEX.TXT`, `SPN2`, `SPN3`, `SPN4`, `SPT0`, `SPT1`, `SPT2`, `SPT3`, `EXAMPLES`, `WIFI.BE`, and `DETECT.BE`
- SD write/read/remove was live-verified with `/BERRYTMP.TXT`; the file and directory handles now use fixed P2 pools instead of Catalina libc `malloc`
- `spi.read(1)` returns a one-byte raw string after `spi.init(10,11,12,13,0,1000)`; full JEDEC validation still needs a known attached SPI target
- `make p2-run TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp` loads and reaches the Berry prompt
- startup banner is now a single Berry-style banner instead of the old duplicated `Berry on Propeller 2` / `Berry on P2`
- basic REPL usage is live-verified:
  - `print(1+2)` -> `3`
  - `a=6`
  - `print(a*7)` -> `42`
- standard interactive pieces now live-verified:
  - repeated blank `Enter` presses no longer run the REPL out of memory
  - `x=list(); x.push(42); print(x.size())` -> `1`
  - `m=map(); m.insert("a", 7); print(m.find("a"))` -> `7`
  - `m={'a':1,'b':2}; for v:m print(v) end` -> `1`, `2`
  - `for k:m.keys() print(k,m.find(k)) end` -> `a 1`, `b 2`
  - `for i:0..3 print(i) end` -> `0`, `1`, `2`, `3`
  - `import string`
  - `print(string.toupper("abc"))` -> `ABC`
  - `print(string.find("banana", "na"))` -> `2`
  - `import math`
  - `print(math.pi)` -> `3.14159`
  - `print(math.abs(-3))` -> `3`
  - `print(math.sqrt(81))` -> `9`
  - `print(math.min(5,2,9))` -> `2`
  - `print(math.max(5,2,9))` -> `9`
  - `import json`
  - `print(json.load('{"a":1,"b":[2,3]}')['b'][1])` -> `3`
  - `print(json.dump({'x':1,'y':[2,3]}))` -> valid JSON text
  - `import bytes`
  - `import i2c`
  - `import spi`
  - `print(bytes('1122'))` -> `bytes('1122')`
  - `print(bytes('1122')[1])` -> `34`
  - `b=bytes().fromstring('AB'); print(b.tohex())` -> `4142`
  - `print(open('/HELLO.TXT','r').readbytes().tohex())` -> `48454C4C4F21776F726C64`
  - `import os`
  - `print(os.listdir('/'))` lists the SD card root
  - `print(open('/HELLO.TXT','r').read())` -> `HELLO!world`
  - `print(os.mkdir('/TMPD'))` -> `true`
  - `print(os.path.isdir('/TMPD'))` -> `true`
  - `f=open('/TMPD/TEST.TXT','w'); f.write('hello from berry'); f.close()` creates a file on SD
  - `print(open('/TMPD/TEST.TXT','r').read())` -> `hello from berry`
  - `print(os.path.isfile('/TMPD/TEST.TXT'))` -> `true`
  - `print(os.getcwd())` / `print(os.chdir('/TMPD'))` / `print(os.getcwd())` are live-verified
  - `print(os.path.join('/TMPD','TEST.TXT'))` -> `/TMPD/TEST.TXT`
  - `print(os.path.split('/TMPD/TEST.TXT'))` -> `['/TMPD', 'TEST.TXT']`
  - `print(os.path.splitext('/TMPD/TEST.TXT'))` -> `['/TMPD/TEST', '.TXT']`
  - `print(os.path.exists('/TMPD/TEST.TXT'))` -> `true`
  - `print(os.remove('/TMPD/TEST.TXT'))` -> `true`
  - `print(os.path.exists('/TMPD/TEST.TXT'))` -> `false`
  - `print(os.rename('/HELLO2.TXT','/HELLO.TXT'))` -> `true` was live-verified during SD card recovery
- native bus modules are now live on the current Catalina path:
  - `i2c.init(25, 24, 100); print(i2c.scan())` -> `[119]`
  - `print(i2c.writeread(0x77, "\xD0", 1))` -> `U` (`0x55`, BMP180 chip id)
  - `spi.init(10, 11, 12, 13, 0, 1000)` is live-verified
- `i2c.read()`, `i2c.writeread()`, `spi.read()`, and `spi.transfer()` use bounded stack buffers instead of Catalina libc heap allocation
- the current exposed P2 helpers are available through `p2.*`, including:
  - clock and counter helpers such as `p2.clock_freq()`, `p2.ticks()`, `p2.ticks64()`
  - wait helpers such as `p2.wait_ticks()`; millisecond task sleep is `rtos.sleep_ms()`
  - cog helpers such as `p2.cog_states()`, `p2.cog_check()`, `p2.cog_stop()`
  - raw cog program startup via `p2.cog_start_hex()`
  - hardware lock helpers live under `rtos`, such as `rtos.new_lock()` and `rtos.try_lock()`
  - CORDIC helpers such as `p2.rotxy()`, `p2.xypol()`, `p2.polxy()`
  - pin helpers such as `p2.pin_output()`, `p2.pin_write()`, `p2.pin_read()`
  - smart-pin helpers such as `p2.smartpin_write_mode()`, `p2.smartpin_query()`, `p2.smartpin_start()`
- reserved pin map on the tested no-PSRAM P2 Edge path is now treated more narrowly:
  - pins `58..61` are the SD card interface
  - pins `62..63` are the serial console
  - pins `56..57` are intentionally left available for Berry GPIO use because they are exposed as LEDs on the tested board
  - PSRAM P2 Edge builds reserve pins `40..57`
- REPL input cleanup is improved enough that backspace now sends the normal erase sequence and prompts/newlines are no longer drifting the way they did earlier
- interactive quit on the macOS Catalina path is now verified:
  - `Ctrl-C` or `Ctrl-D` at an empty `berry>` prompt makes Berry print `bye`
  - the loader wrapper disconnects automatically after that, so `make p2-ram` returns cleanly
  - `Ctrl-]` still disconnects immediately if a manual escape is needed
  - if the current bump-heap REPL runs out of memory, it now prints the OOM error and exits automatically instead of leaving a dead prompt behind
- flash programming on the current macOS path is now verified with:
  - `make p2-flash`
  - `make p2-flash-run`
  - Catalina flash uses Catalina's `flshload.t` wrapper, generated as `build/p2/catalina/full/berry_p2_flash_loader.binary`
  - `make p2-flash` loads the wrapper to RAM and waits until the flashed Berry image reboots to `berry>`
  - direct `loadp2 -SPI build/p2/catalina/full/berry_p2.binary` is not the Catalina path and should not be used for Berry
- P2 Edge flash boot details to preserve:
  - for development with serial attach after reset, use `FLASH=ON, △=OFF, ▽=OFF`
  - for flash-only fast boot, use `FLASH=ON, △=OFF, ▽=ON`
  - Catalina `P2_EDGE` serial uses `230400` right now, so regular terminals must connect at that baud
  - `make p2-attach` now opens a serial terminal without doing a RAM download
- flash boot was verified after reset with `print(6*7)` -> `42` and map lookup/math `m={"a":2,"b":5}; print(m["a"]+m["b"])` -> `7`

Current machine focus to preserve:

- host: macOS
- toolchain: Catalina
- board profile: `P2_EDGE`
- silicon path: `P2_SILICON=latest`
- normal serial port: `/dev/cu.usbserial-P97cvdxp`

Known limitation:

- not every standard library module has been re-verified interactively yet on the cached-runtime-module path; `string`, SD-loaded `math`, `json`, `bytes`, `os`, and the P2 hardware modules have current or prior hardware coverage, but longer mixed-module sessions still need stress testing
- `P2_PROFILE=edge32` enables Catalina `-lpsram` and PSRAM block access. Berry exposes bounded `p2.psram_read()` / `p2.psram_write()` wrappers and `libstore` can use them as a source-cache backend, but Berry's object heap remains in Hub RAM. Catalina's COMPACT PSRAM API is transfer-based, not ordinary C pointer-addressable memory; moving the GC/object heap to external RAM would require an XMM/large-memory object representation or a handle/cache layer.
- `make p2-smoke-edge32` still depends on `/tests/p2` being present on the SD
  card. The quick REPL smoke passes, but the temporary serial SD loader wedged
  while creating or writing the nested `/tests/p2` tree; direct REPL checks were
  used instead for the edge32 PSRAM/libstore path.
- The new `scripts/p2/repl_smoke.py` runner uses direct PySerial access with
  selectable line endings. Use `--no-wait-start` after `p2-edge32-flash`, because
  the flash helper has usually already consumed the boot prompt.
- `p2.cog_start_c()` now builds but still needs a focused Berry FFI validation pass on hardware
- `spin2.call()` needs an SD-card run with a copied compatible `berry_mailbox_demo.bin`; `make spin2` is build-verified, but the current live SD-visible `/spin2` path had no binaries
- WiFiNINA/AirLift support is a Berry SPI transport skeleton. The ESP32-C6 board flashed with firmware `3.3.0` did not assert READY/BUSY during the last probe, so `wifi.firmware_version()` is not live-verified yet.
- pin 57 must be tested with the no-PSRAM Catalina profile (`CATALINA_MODEL=COMPACT`, `CATALINA_CLIB=-lcx`, no `-lpsram`); PSRAM builds use pin 57 as chip-select and will hold it under the memory interface
- `../tests/fs_probe.c` is intentionally destructive and mutates the SD card; keep it for Catalina DOSFS debugging only

## Relevant Files

- [`../runtime/main_p2.c`](../runtime/main_p2.c)
- [`../runtime/berry_port.c`](../runtime/berry_port.c)
- [`../runtime/p2_heap.c`](../runtime/p2_heap.c)
- [`../include/berry_conf_p2.h`](../include/berry_conf_p2.h)
- [`../overrides/be_libs_p2.c`](../overrides/be_libs_p2.c)
- [`../../../src/be_mem.c`](../../../src/be_mem.c)
- [`../../../src/be_string.c`](../../../src/be_string.c)
- [`../../../src/be_vm.c`](../../../src/be_vm.c)

## Next Steps

1. Continue first on macOS with Catalina and `P2_EDGE`.
2. Keep the local environment configured with:
   - `make configure TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp P2_SILICON=latest CATALINA_PLATFORM=P2_EDGE CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=`
3. Start with:
   - `make p2-run`
   - or `make p2-ram`
   - for the 32 MB RAM board, `make p2-edge32-flash PORT=/dev/cu.usbserial-P97cvdxp`
4. Re-verify:
   - `print(1+2)`
   - `a=6`
   - `print(a*7)`
   - `import p2; print(p2.clock_freq())`
   - on the 32 MB RAM board: `import p2; print(p2.psram_info()); print(p2.psram_test()); p2.psram_write(29*1024*1024, "ok"); print(p2.psram_read(29*1024*1024, 2))`
   - `print(p2.pin_read(38))`
   - `Ctrl-C` at an empty prompt should print `bye` and return cleanly to the shell
5. Keep the secondary paths buildable:
   - FlexC
   - Windows / `COM6`
   - older silicon selection where possible
6. Next engineering focus:
   - keep checking for heap regressions under longer REPL sessions now that blank-line OOM is fixed
   - run the new non-destructive `tests/p2/` smoke suite on both full and edge32 hardware images
   - decide when to retire or hide compatibility `prop2_*` globals from full profiles
   - continue Windows validation on `COM6` after the macOS Catalina path is stable enough

## What to Say Next Time

When asked to continue porting Berry to P2, start by summarizing:

- where the port currently is
- what was last verified on hardware
- that the primary focus is macOS + Catalina + `P2_EDGE` + latest silicon
- that the usual board port is `/dev/cu.usbserial-P97cvdxp`
- that the first command to try is `make p2-run`
