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
hardware modules, and grow the multicog model in small safe layers.

- `print()`
- variable assignment
- simple arithmetic
- `for` loops over ranges, lists, and maps
- `import string`
- `import math`
- `import json`
- `import bytes`
- `import os`
- `import p2`
- `import rtos`
- `import i2c`
- `import spi`
- `import spin2`
- `import wifi` when `modules/wifi.be` is available on the SD card or module path
- SD card backed file and directory access through `open()` and `os`
- reliable serial interaction without prompt drift or blank-line heap loss
- tiny REPL line editing with three-command history and arrow-key navigation
- RTOS-owned second-cog Berry worker jobs through Hub-RAM mailboxes

Current Catalina status on P2 Edge / latest silicon:

- the default build targets the no-PSRAM P2 Edge: `CATALINA_MODEL=COMPACT`, `CATALINA_CLIB=-lcx`, with no `-lpsram`
- the default feature profile is `P2_PROFILE=full`; `make p2-minimal` builds the core-language/string-only footprint profile, and `make p2-edge32` builds the P2 Edge 32 MB RAM profile with Catalina `-lpsram`
- `make p2-run TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp` reaches a working REPL with a `523904` byte full-profile image
- `print()`, assignment, and basic arithmetic are live-verified
- `for i:0..3`, `for e:list`, `for v:map`, and `for k:map.keys()` are live-verified
- `import string`, SD-loaded `import math`, `import json`, `import bytes`, and `import os` are live-verified
- `import p2`, `import rtos`, `import i2c`, `import spi`, and `import spin2` are now live-verified
- `import rtos` exposes process-style tasks, locks, queues, event flags, timers, deferred callbacks, and debug helpers
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
- process-style task/cog startup and queues are exposed as `rtos.*`
- Spin2/PASM binary loading scaffolding is exposed as `spin2.*`
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
- `import rtos; rtos.channel("a"); rtos.put("a",123); print(rtos.get("a", 10))` -> `123`
- `rtos.load_file("/examples/rtos/workers/counter_task.be"); cog=rtos.newcog("counter_task",7)` starts an explicitly loaded child-VM function on the process cog
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

Child-VM methods are loaded explicitly before `rtos.newcog()`, `rtos.spawn()`,
or `rtos.cog_start()`:

```berry
rtos.channel("rx_packets")
rtos.load_file("/examples/rtos/workers/packet_reader.be")
rtos.newcog("packet_reader", 50)
print(rtos.get("rx_packets", 250))
```

`rtos.load_file(path)` is the recommended form because the child task stays in a
normal `.be` file. `rtos.load_str(source)` is still available for generated
source strings, and `rtos.load(source)` remains as the compatibility alias for
`rtos.load_str(source)`. Child code runs in its own Berry VM. Direct
`rtos.newcog(function, ...)` works for named zero-upvalue Berry functions after
the child VM has loaded a function with the same name; captured closures are
still rejected until the runtime can safely serialize or recompile function
state into the target VM.

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

## RTOS Module

The `rtos` module is a Berry-friendly concurrency layer over the P2 port's
verified primitives. It is inspired by small RTOS APIs, but it stays safe for
the current Catalina COMPACT build: Berry callbacks are dispatched only from
normal Berry code via `rtos.irq_poll()`, never directly from an interrupt
service routine.

Current limitation: this implementation supports the main VM plus one child
process VM/cog. The queue, event, timer, and lock objects are shared Hub-RAM
state and are written so additional child VMs can use the same API once the P2
heap layer grows multiple process arenas.

Task helpers:

- `rtos.load_file(path)`: load and run a Berry source file in the child VM. Put task functions in that file, then launch them by name.
- `rtos.load_str(source)`: load Berry source text into the child VM. `rtos.load(source)` is a compatibility alias.
- `rtos.newcog(name, ...int_args) -> int`: start the process cog if needed and run a loaded child-VM function by name with up to eight integer arguments.
- `rtos.process(name, ...int_args)`, `rtos.thread(name, ...int_args)`, and `rtos.new(name, ...int_args)`: aliases for `rtos.newcog()`.
- `rtos.spawn(name, ...int_args) -> int`: compatibility spelling for named child-VM launch.
- `rtos.cog_start(name, ...int_args) -> int`: alias for `rtos.spawn()`.
- `rtos.process_info()` / `rtos.task_info()`: inspect the current backend model,
  child cog, and whether direct closure launch is available.
- `rtos.stop()`, `rtos.state()`, `rtos.error()`: inspect or stop the process task cog.
- `rtos.yield()` / `rtos.task_yield()`: cooperative yield.
- `rtos.sleep_ms(ms)`: sleep the current cog, with Ctrl-C checks on the main VM.
- `rtos.cog_id() -> int`: current cog number.

Locks:

- `rtos.new_lock() -> int`: allocate one of the P2 hardware semaphore bits.
- `rtos.lock(id)`, `rtos.try_lock(id) -> bool`, `rtos.unlock(id)`, `rtos.delete_lock(id)`.

Queues:

- `rtos.channel(name) -> string`: create or fetch a fixed queue.
- `rtos.put(name, value)`: enqueue an integer or short string.
- `rtos.get(name, timeout_ms=nil) -> value or nil`: wait for a message; `timeout_ms=0` polls once.

Events, timers, and callbacks:

- `rtos.event_set(mask)`, `rtos.event_clear(mask)`, `rtos.event_wait(mask, timeout_ms=nil) -> bool`, `rtos.event_flags() -> int`.
- `rtos.ticks_per_ms() -> int`, `rtos.delay_ms(ms)`, `rtos.timer_start(ms) -> int`, `rtos.timer_expired(id) -> bool`, `rtos.timer_wait(id)`.
- `rtos.irq_enable(channel, handler_name)`, `rtos.irq_poll() -> int`, `rtos.irq_disable(channel)`. Channels `0..15` are deferred callback slots; setting event bit `1 << channel` marks that callback pending. Channel `rtos.IRQ_ATN` also polls P2 cog-attention.

Debug helpers:

- `rtos.debug_tasks() -> list`: maps with `cog`, `state`, and `stack_free` keys.
- `rtos.debug_regs(cog) -> map`: counter and selected current-cog P2 registers. Other cogs are reported as not directly readable from C.
- `p2.status_info()` / `p2.debug_snapshot()`: structured build, runtime,
  clock, heap, PSRAM, and cog diagnostics for tests and REPL inspection.

RTOS examples live in `../../../examples/rtos/`:

- `queue_worker_producer.be`: child process cog produces packet IDs into a queue consumed by the main VM.
- `event_worker_signal.be`: child process cog signals the main VM with an event bit after queueing data.
- `lock_serial_request.be`: child process cog requests main-cog serial output through a queue guarded by a lock.
- `timer_worker_heartbeat.be`: child process cog uses RTOS timers to send heartbeat messages.
- `sleep_ms_worker_blink.be`: child process cog blinks a pin with `rtos.sleep_ms()`.
- `cog_start_worker_loop.be`: `rtos.cog_start()` launches an explicitly loaded child-VM function.
- `debug_tasks.be`: inspect cog/task state while a child process task is running.
- `newcog_process_info.be`: use the new process spelling and inspect backend
  limits.
- `load_str_inline.be`: compatibility example for loading generated source strings into the child VM.

Files under `examples/rtos/workers/` are loaded by the main examples with
`rtos.load_file()`. They intentionally define one worker-side function each so
the code remains readable and the cross-cog boundary is explicit.

## SD Library Store

P2 configures `/modules` as a default import root during VM startup. This keeps
optional Berry libraries on SD and loads them lazily when code imports them,
without enabling the larger upstream `sys` module just to mutate `sys.path()`.

`modules/math.be` and `modules/taskspin.be` are SD-loaded libraries.
`modules/libstore.be` reports the current SD-first library-store model:

```berry
import libstore
print(libstore.status())
print(libstore.exists("binary_heap"))
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

`modules/taskspin.be` is also SD-loaded. It implements a Spin2-shaped
cooperative task API (`TASKSPIN`, `TASKNEXT`, `TASKSTOP`, `TASKHALT`,
`TASKCONT`, `TASKCHK`, `TASKID`, and `TASKHLT`) for closure-based state
machines in the current VM. Task slots keep `stack_address` metadata and expose
per-task diagnostics, so Berry examples can use the Spin2 vocabulary while the
lower-level cog-local switcher design matures. This keeps the API experiment
out of the Hub image.

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
