# Berry on Propeller 2

This directory holds the P2-specific notes that sit closest to the runtime and bring-up work.

## Layout

- `../include/` contains the P2 configuration shim and small public headers.
- `../runtime/` contains the P2 entry point, serial backend, and heap implementation.
- `../overrides/` contains the small maintained override layer used by the port.
- `../patches/optional/` contains temporary or host-specific workaround files.
- `../tests/` contains tiny on-target probes for serial, loading, and allocation.

## Current Goal

Make Berry feel native on the Propeller 2: keep the REPL stable, expose useful
hardware modules, keep the XMM boot path fast, and provide simple task/cog APIs
that match what the hardware can safely do today.

Current active surface:

- core Berry REPL, collections, ranges, closures, and file-backed scripts
- native `string`, full native `math`, native `task`, `json`, `bytes`, `os`, `p2`, `i2c`, and `spi` modules
- SD card backed file and directory access through `open()` and `os`
- optional SD libraries under `/modules` for larger source-level helpers
- tiny REPL line editing with three-command history and arrow-key navigation
- native cooperative scheduling through `task.*`
- native cog-backed handles through `p2.cog.*` for supported functions such as blinkers
- retired `rtos`, `worker`, `threads`, and `taskspin` experiments are no longer the active API

Current Catalina status on P2 Edge / latest silicon:

- the default build targets the no-PSRAM P2 Edge: `CATALINA_MODEL=COMPACT`, `CATALINA_CLIB=-lcx`, with no `-lpsram`
- the default feature profile is `P2_PROFILE=full`; `make p2-minimal` builds the core-language/string-only footprint profile, and `make p2-edge32` builds the P2 Edge 32 MB RAM profile with Catalina `-lpsram`
- `make p2-run TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp` reaches a working REPL on the full-profile image
- `print()`, assignment, and basic arithmetic are live-verified
- `for i:0..3`, `for e:list`, `for v:map`, and `for k:map.keys()` are live-verified
- `import string`, native `import math`, native `import task`, `import json`, `import bytes`, and `import os` are live-verified
- `import p2`, `import task`, `import i2c`, and `import spi` are now live-verified; `spin2` source remains archived and is not compiled by default
- `import task` exposes cooperative scheduling, wait/signal, semaphore, mutex, queue, flags, and timer helpers
- blank Enter presses no longer leak the REPL into an out-of-memory state
- Up/Down recall the last three REPL commands and Left/Right/Backspace edit the current line
- `bytes('1122')`, `bytes().fromstring('AB')`, `tohex()`, `asstring()`, `readbytes()`, and range slicing are live-verified
- `json.load()` and `json.dump()` are live-verified
- SD card access through `open('/HELLO.TXT','r')`, `os.listdir('/')`, `os.mkdir()`, `os.rename()`, `os.remove()`, `os.chdir()`, `os.getcwd()`, and `os.path.*` is live-verified; file/directory handles now use fixed pools instead of Catalina libc heap allocation
- P2 helpers are exposed as `p2.*` for clock, counter, pin, smart-pin, CORDIC, lock, attention, and cog inspection
- legacy `prop2_*` globals remain available for compatibility
- `p2.status()` prints build size, heap usage bars, clock info, and all 8 cog states
- `p2.psram_info()` and `p2.psram_test()` are available on the P2 hardware module; on the `edge32` profile they report and smoke-test Catalina PSRAM block access
- native bus helpers are exposed as `i2c.*` and `spi.*`
- cooperative scheduling is exposed as `task.*`; native cog-backed handles are exposed as `p2.cog.*`
- Spin2/PASM binary loading scaffolding is archived behind the opt-in Spin2 build path and is not part of the default image
- WiFiNINA/AirLift SPI framing scaffolding is available in `modules/wifi.be`; ESP32-C6 firmware detection still needs hardware READY/BUSY bring-up

Current hardware verification examples:

- `import p2; print(p2.cogid())` -> `0`
- `p2.status()` prints the current P2 runtime status table
- `p2.pinmode(56,p2.OUTPUT); p2.low(56); print(p2.read(56))` -> `0`
- `p2.high(56); print(p2.read(56))` -> `1`
- `import i2c; i2c.init(25, 24, 400); print(i2c.scan())` -> `[119]`
- `print(i2c.writeread(0x77, "\xD0", 1))` -> `U` (`0x55`, BMP180 chip id)
- `import spi; spi.init(10, 11, 12, 13, 0, 1000)` is live-verified
- `import os; print(os.listdir('/'))` lists the current SD root after filtering stale/non-printable DOSFS entries
- `f=open('/BERRYTMP.TXT','w'); f.write('sd ok'); f.close(); print(open('/BERRYTMP.TXT','r').read()); os.remove('/BERRYTMP.TXT')` is live-verified
- `import task; print(task.info())` reports the native cooperative scheduler
- `import p2; h=p2.cog.spawn(p2.cog.blinker, 38, 250); print(p2.cog.info(h)); p2.cog.stop(h)` starts and stops a supported native cog-backed blinker
- `run_file("/examples/core/qsort.be")` runs a `.be` file from the current VM, including from the REPL
- `import spin2; print(spin2.path()); print(spin2.list())` -> `/spin2` and `[]` on the current SD-visible path

Repeatable smoke tests live in `../../../tests/p2/`. Copy that directory and
`../../../modules/` to the SD card root and run from the host while Berry is
sitting at `berry>`:

```sh
make p2-smoke PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-edge32 PORT=/dev/cu.usbserial-P97cvdxp
```

The target scripts print `P2_SMOKE_PASS ...` markers when complete. The general
suite creates and removes only `/P2SMOKE.TXT`; it also verifies lazy library
imports from `/modules`. The edge32 suite asserts Catalina PSRAM block access
through `p2.psram_info()` and `p2.psram_test()`.

Current task/cog examples use the native `task` scheduler for cooperative
work inside the main Berry VM and `p2.cog` handles for native cog-backed work:

```berry
import p2
import task

def blink(pin, ms)
    p2.toggle(pin)
    return task.sleep(ms)
end

h38 = task.start(blink, 38, 250)
h39 = task.start(blink, 39, 700)
task.run(100)

ch = p2.cog.spawn(p2.cog.blinker, 38, 250)
print(p2.cog.info(ch))
p2.cog.stop(ch)
```

The older child-VM `rtos` launch path has been retired from the active API.

Examples:

- `p2.clock_freq()`
- `p2.ticks()`
- `p2.ticks64()`
- `p2.pin_output(pin)`
- `p2.pin_write(pin, value)`
- `p2.pin_read(pin)`
- `p2.smartpin_write_mode(pin, mode)`
- `p2.smartpin_query(pin)`
- `p2.smartpin_start(pin, mode, x, y)`

The grouped low-level API from the long-term roadmap is also exposed as
compatibility submodules over the current native helpers:

- `p2.clock.freq()`, `p2.clock.mode()`, `p2.clock.set(mode, freq)`,
  `p2.clock.cnt()`, `p2.clock.cnth()`, `p2.clock.waitx(cycles)`,
  `p2.clock.waitus(us)`, `p2.clock.waitms(ms)`, `p2.clock.waitsec(sec)`,
  `p2.clock.waitcnt(tick)`, and `p2.clock.hubset(value)`
- `p2.cog.id()`, `p2.cog.check(cog_id)`, `p2.cog.stop(cog_id)`,
  `p2.cog.spawn(closure, ...primitive_args)`,
  `p2.cog.stop(handle)`, `p2.cog.info(handle)`, `p2.cog.info()`,
  `p2.cog.attention(mask)`, `p2.cog.poll_attention()`, and
  `p2.cog.wait_attention()`
- `p2.lock.new()`, `p2.lock.ret(lock_id)`, `p2.lock.try(lock_id)`,
  `p2.lock.release(lock_id)`, and `p2.lock.check(lock_id)`
- `p2.pin.dir_low(pin)`, `p2.pin.dir_high(pin)`, `p2.pin.write(pin, value)`,
  `p2.pin.low(pin)`, `p2.pin.high(pin)`, `p2.pin.toggle(pin)`,
  `p2.pin.float(pin)`, and `p2.pin.read(pin)`
- `p2.cordic.rotxy(x, y, theta)`, `p2.cordic.polxy(r, theta)`, and
  `p2.cordic.xypol(x, y)`
- `p2.math.isqrt(x)`, `p2.math.muldiv64(a, b, divisor)`, `p2.math.rev(x)`,
  and `p2.math.encod(x)`
- `p2.rng.rnd()`
- `p2.smart.wrpin(pin, mode)`, `p2.smart.wxpin(pin, x)`,
  `p2.smart.wypin(pin, y)`, `p2.smart.akpin(pin)`,
  `p2.smart.rdpin(pin)`, `p2.smart.rqpin(pin)`,
  `p2.smart.start(pin, mode, x, y)`, and `p2.smart.clear(pin)`

The existing flat names remain supported for current examples and compatibility.
The grouped API is covered by `/tests/p2/smoke_p2_api.be`.

`p2.cog.spawn()` is an interim closure-cog proof path. It stores the live Berry
closure in the main VM, starts a separate C cog, and calls the closure with the
provided primitive arguments while the REPL/main cog is idle at the prompt. The
closure must return quickly; returning an integer schedules the next call after
that many milliseconds, and returning `false`, `nil`, or a negative integer
stops the handle. This is intentionally not yet independent per-cog VM/GC
isolation. `p2.cog.info(handle)["model"]` reports `shared_vm_repl_idle` for
this proof path.

The hardware-verified p38/p39 LED form,
`p2.cog.spawn(closure, pin, rate_ms)`, is promoted to the safer native GPIO
blinker model when both arguments are positive integers and the pin is in
`0..63`. The closure is still invoked once on the main REPL cog during setup and
must return a positive integer delay; the spawned cog then runs a native toggle
loop with a 2048-byte stack. `p2.cog.info(handle)["model"]` reports
`native_blink` for this fast path.

Other closure-cog shapes are rejected by the default firmware because repeated
shared-VM Berry callbacks from multiple background cogs are not hardware-safe
yet. The legacy dispatcher is available only for diagnostics with the explicit
`BE_P2_ENABLE_UNSAFE_SHARED_VM_COG` build flag.

`p2.cog.capabilities()` reports the current closure-cog contract at runtime:
the native blinker shape is supported, unsupported shapes are rejected in the
default firmware, and isolated arbitrary closure execution is still reported as
not available.

`p2.cog.info()` returns all current closure-cog handles;
stopped handles remain inspectable until explicitly stopped or reclaimed before
a later spawn when slots are needed.

## Retired RTOS Module

The old experimental `rtos` and `taskspin` APIs have been removed from the current P2 path. Use the native `task` module for cooperative scheduling inside the Berry VM, and use `p2.cog` when you want native cog-backed handles such as LED blinkers.


## SD Library Store

P2 configures `/modules` as a default import root during VM startup. This keeps
optional Berry libraries on SD and loads them lazily when code imports them,
without enabling the larger upstream `sys` module just to mutate `sys.path()`.

`math`, `string`, and `task` are native firmware modules. Optional SD libraries such as `libstore.be` remain under `modules/`.
`modules/libstore.be` reports the current SD-first library-store model:

```berry
import libstore
import p2mem
print(libstore.status())
print(libstore.exists("binary_heap"))
print(p2mem.stats())
print(p2mem.modules())
print(p2mem.cache())
p2mem.gc()
p2mem.evict()
```

On edge32 and XMM-style profiles, `libstore.status()` reports PSRAM availability
and the current safe block/cache window. `libstore.cache_source(name)` mirrors
source text into that window as bounded chunks. `libstore.modules()` scans
available `.be` files under the configured module paths, and
`libstore.cache_all()` can warm every discovered source module into the safe
PSRAM cache. `libstore.load(name)` compiles a module after materializing cached
source back into active VM RAM. SD remains the canonical library store. On
COMPACT edge32, compiled/live Berry objects still use Hub RAM because Catalina
PSRAM is block-transfer storage rather than ordinary pointer-addressable heap.
On XMM profiles, Catalina owns the lower PSRAM window for transparent VM
memory, so `libstore` uses only the reported safe block window.

`modules/p2mem.be` is the diagnostics facade over the current memory and
library-cache model:

- `p2mem.stats()` returns heap, runtime memory, PSRAM, libstore, cache, module
  count, cache item count, and current GC allocation data.
- `p2mem.modules()` returns one metadata map per discovered SD module.
- `p2mem.cache()` returns current PSRAM source-cache status and cached-item
  records.
- `p2mem.gc()` runs Berry GC and reports before/after allocation counts.
- `p2mem.evict()` resets the current libstore PSRAM source cache and reports
  before/window/after state.

Current limitations are explicit in the returned metadata: compiled `.bec`
paths, hashes, mtimes, hit/miss counts, refcounts, and last-used timestamps are
reported as `nil` or `0` until the runtime starts tracking them.


The native `task` module is the current cooperative scheduler API. It provides
fixed-slot cooperative tasks plus `Semaphore`, `Mutex`, `Queue`, `EventFlags`,
and `Timer` helpers. Tasks run one scheduler step at a time and return helpers
such as `task.sleep(ms)`, `task.wait(event)`, `task.again`, or `task.done`.

The retired `modules/task.be` / `modules/taskspin.be` facade is no longer the
recommended path. Use `task` for cooperative work and `p2.cog` for supported
native cog-backed handles.


Reserved-pin note on the current Catalina `P2_EDGE` path:

- pins `58..61` are reserved by the SD card interface
- pins `62..63` are reserved by the serial console
- `P2_BOARD=p2edge` uses the no-PSRAM P2 Edge pinout, with onboard LEDs on pins `56` and `57`
- `P2_BOARD=p2edge32` uses the P2 Edge 32 MB RAM pinout, with onboard LEDs on pins `38` and `39`; pins `40..57` are reserved by the memory interface, and pin `57` is PSRAM chip-select
- Berry GPIO, `i2c`, and `spi` helpers should avoid the SD and serial pins

Primary development focus from now on:

- macOS
- Catalina / `lcc`
- `P2_EDGE`
- latest silicon path (`P2_SILICON=latest`, targeting your Rev C board)
- no-PSRAM P2 Edge defaults (`CATALINA_MODEL=COMPACT`, `CATALINA_CLIB=-lcx`, no `-lpsram`)
- profile defaults: `full` for normal no-PSRAM work, `minimal` for footprint work, `edge32` for verified P2 Edge boards with the 32 MB RAM module, and `xmm` for the experimental unified-memory image

P2 Edge 32 MB RAM notes:

- build with `make p2-edge32` or flash with `make p2-edge32-flash PORT=/dev/cu.usbserial-P97cvdxp`
- the profile uses `CATALINA_MODEL=COMPACT`, `CATALINA_CLIB=-lcx`, and `CATALINA_SERIAL_LIB=-lpsram`
- Catalina's COMPACT PSRAM support is a block-transfer API (`psram_read()` / `psram_write()`), so Berry's pointer-following GC/object heap remains in Hub RAM for now
- use `make p2-sd-sync PORT=/dev/cu.usbserial-P97cvdxp` at a running Berry prompt to copy repo `modules/` to `/modules` and `tests/p2/` to `/tests/p2` through the REPL uploader
- use `import p2; print(p2.fs_info()); print(p2.fs_info(true))` to inspect SD mount, root directory, and create/write/read/remove result codes when SD-backed imports fail
- use `import p2; print(p2.psram_info()); print(p2.psram_test())` as the quick runtime PSRAM smoke check; `make p2-smoke-edge32` also checks raw `p2.psram_read()` / `p2.psram_write()`, chunked `libstore` PSRAM source caching, and loading `math` from the PSRAM source cache
- build the experimental unified-memory image with `make p2-xmm`; it uses
  Catalina `LARGE` plus `-lpsram` and `-C PSRAM`, reports the Berry heap as
  external, and keeps the Hub/PSRAM distinction below Berry's allocator.
  Catalina's P2 Edge XMM support uses the lower `16 MiB` of PSRAM as transparent
  memory, while Berry leaves the upper `16 MiB` available for explicit
  PSRAM/block-cache use. Hardware boot/smoke is still pending because XMM
  images need Catalina's XMM loader utilities, so keep using `edge32` for
  verified board work.

Other toolchains and silicon paths should still be kept buildable, but this is
the first path to validate when continuing the port. In particular, do not
spend normal Berry bring-up time trying to compile with FlexC unless that
toolchain is the explicit task; Catalina is the path that works well.

Filesystem probe note:

- `../tests/fs_probe.c` is a destructive Catalina DOSFS probe. It mutates the
  mounted SD card and is meant for low-level debugging, not routine smoke
  testing.

## Main References

- [`PORTING_STATUS.md`](./PORTING_STATUS.md)
- [`../../../docs/P2_BUILD.md`](../../../docs/P2_BUILD.md)
- [`../../../docs/P2_MODULES.md`](../../../docs/P2_MODULES.md)
- [`../../../docs/P2_LAYOUT.md`](../../../docs/P2_LAYOUT.md)
- [`../../../docs/P2_SYSTEM_ROADMAP.md`](../../../docs/P2_SYSTEM_ROADMAP.md)
