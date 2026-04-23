# Berry on Propeller 2: Porting Status

This note is the handoff for the next P2 porting session.

## Where the Port Is

- The repository layout is now cleaned up so P2 work lives under `port/p2/`, `mk/`, and `tools/p2/`.
- A repo-local P2 environment file can now be written with `make configure`, so repeated `TOOLCHAIN`, `PORT`, and silicon flags are no longer required once the machine is configured.
- The P2 build interface is now:
  - `make configure`
  - `make show-config`
  - `make p2 TOOLCHAIN=flexc`
  - `make p2 TOOLCHAIN=catalina`
  - `make p2-run TOOLCHAIN=flexc PORT=...`
  - `make p2-run TOOLCHAIN=catalina PORT=...`
  - `make p2-ram`
  - `make p2-flash`
- P2 silicon selection still supports:
  - `P2_SILICON=a` -> `-2a`
  - `P2_SILICON=latest|b|c` -> `-2`
- The primary focus path is now macOS + Catalina + `P2_EDGE` + latest silicon (Rev C / current silicon path).
- Other build paths should stay available, but this macOS Catalina path is the first one to validate.

## What Was Last Verified

On the current macOS Catalina P2 Edge path (latest silicon / Rev C focus):

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
- the current exposed P2 helpers are live-verified through `prop2_*` globals, including:
  - clock and counter helpers such as `prop2_clock_freq()`, `prop2_ticks()`, `prop2_ticks64()`
  - wait/sleep helpers such as `prop2_wait_ticks()` and `prop2_sleep_ms()`
  - cog helpers such as `prop2_cog_states()`, `prop2_cog_check()`, `prop2_cog_stop()`
  - raw cog program startup via `prop2_cog_start_hex()`
  - lock helpers such as `prop2_lock_new()`, `prop2_lock_try()`, `prop2_lock_check()`
  - CORDIC helpers such as `prop2_rotxy()`, `prop2_xypol()`, `prop2_polxy()`
  - pin helpers such as `prop2_pin_output()`, `prop2_pin_write()`, `prop2_pin_read()`
  - smart-pin helpers such as `prop2_smartpin_write_mode()`, `prop2_smartpin_query()`, `prop2_smartpin_start()`
- reserved pin map on the tested no-PSRAM P2 Edge path is now treated more narrowly:
  - pins `58..61` are the SD card interface
  - pins `62..63` are the serial console
  - pins `56..57` are intentionally left available for Berry GPIO use because they are exposed as LEDs on the tested board
- REPL input cleanup is improved enough that backspace now sends the normal erase sequence and prompts/newlines are no longer drifting the way they did earlier
- interactive quit on the macOS Catalina path is now verified:
  - `Ctrl-C` or `Ctrl-D` at an empty `berry>` prompt makes Berry print `bye`
  - the loader wrapper disconnects automatically after that, so `make p2-ram` returns cleanly
  - `Ctrl-]` still disconnects immediately if a manual escape is needed
  - if the current bump-heap REPL runs out of memory, it now prints the OOM error and exits automatically instead of leaving a dead prompt behind
- flash programming on the current macOS path is now verified with:
  - `make p2-flash`
  - `make p2-flash-run`
  - Catalina flash uses Catalina's `flshload.t` wrapper, generated as `build/p2/catalina/berry_p2_flash_loader.binary`
  - `make p2-flash` loads the wrapper to RAM and waits until the flashed Berry image reboots to `berry>`
  - direct `loadp2 -SPI build/p2/catalina/berry_p2.binary` is not the Catalina path and should not be used for Berry
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

- not every standard library module has been re-verified interactively yet on the cached-runtime-module path; `string` and `math` are verified, and the rest still need a focused pass
- `prop2_cog_start_c()` now builds but still needs a focused Berry FFI validation pass on hardware
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
   - `make configure TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp P2_SILICON=latest CATALINA_PLATFORM=P2_EDGE CATALINA_MODEL=COMPACT`
3. Start with:
   - `make p2-run`
   - or `make p2-ram`
4. Re-verify:
   - `print(1+2)`
   - `a=6`
   - `print(a*7)`
   - `print(prop2_clock_freq())`
   - `print(prop2_pin_read(38))`
   - `Ctrl-C` at an empty prompt should print `bye` and return cleanly to the shell
5. Keep the secondary paths buildable:
   - FlexC
   - Windows / `COM6`
   - older silicon selection where possible
6. Next engineering focus:
   - keep checking for heap regressions under longer REPL sessions now that blank-line OOM is fixed
   - decide whether to add a non-destructive automated P2 smoke test for the verified `string` / `math` / `json` / `bytes` / `os` path
   - decide whether `prop2_*` should remain prefixed globals or move into a proper Berry-side namespace/module wrapper
   - continue Windows validation on `COM6` after the macOS Catalina path is stable enough

## What to Say Next Time

When asked to continue porting Berry to P2, start by summarizing:

- where the port currently is
- what was last verified on hardware
- that the primary focus is macOS + Catalina + `P2_EDGE` + latest silicon
- that the usual board port is `/dev/cu.usbserial-P97cvdxp`
- that the first command to try is `make p2-run`
