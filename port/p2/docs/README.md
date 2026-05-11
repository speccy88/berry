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
- `import worker`
- `import threads`
- `import rtos`
- `import i2c`
- `import spi`
- `import spin2`
- SD card backed file and directory access through `open()` and `os`
- reliable serial interaction without prompt drift or blank-line heap loss
- tiny REPL line editing with three-command history and arrow-key navigation
- second-cog Berry worker jobs through Hub-RAM mailboxes

Current Catalina status on P2 Edge / latest silicon:

- the default build targets the no-PSRAM P2 Edge: `CATALINA_MODEL=COMPACT`, `CATALINA_CLIB=-lcx`, with no `-lpsram`
- the default feature profile is `P2_PROFILE=full`; `make p2-minimal` builds the core-language/string-only footprint profile
- `make p2-run TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp` reaches a working REPL
- `print()`, assignment, and basic arithmetic are live-verified
- `for i:0..3`, `for e:list`, `for v:map`, and `for k:map.keys()` are live-verified
- `import string`, `import math`, `import json`, `import bytes`, and `import os` are live-verified
- `import p2`, `import worker`, `import threads`, `import i2c`, `import spi`, and `import spin2` are now live-verified
- `import rtos` is live-verified and exposes worker-backed tasks, locks, queues, event flags, timers, deferred callbacks, and debug helpers
- blank Enter presses no longer leak the REPL into an out-of-memory state
- Up/Down recall the last three REPL commands and Left/Right/Backspace edit the current line
- `bytes('1122')`, `bytes().fromstring('AB')`, `tohex()`, `asstring()`, `readbytes()`, and range slicing are live-verified
- `json.load()` and `json.dump()` are live-verified
- SD card access through `open('/HELLO.TXT','r')`, `os.listdir('/')`, `os.mkdir()`, `os.rename()`, `os.remove()`, `os.chdir()`, `os.getcwd()`, and `os.path.*` is live-verified
- P2 helpers are exposed as `p2.*` for clock, counter, pin, smart-pin, CORDIC, lock, attention, and cog operations
- legacy `prop2_*` globals remain available for compatibility
- `p2.status()` prints build size, heap usage bars, clock info, and all 8 cog states
- native bus helpers are exposed as `i2c.*` and `spi.*`
- the first worker VM path is exposed as `worker.*` and `p2.cog_start()`
- fixed v1 channels are exposed as `threads.*`
- higher-level RTOS helpers are exposed as `rtos.*`
- Spin2/PASM binary loading scaffolding is exposed as `spin2.*`

Current hardware verification examples:

- `import p2; print(p2.cogid())` -> `0`
- `p2.status()` prints the current P2 runtime status table
- `p2.pinmode(56,p2.OUTPUT); p2.low(56); print(p2.read(56))` -> `0`
- `p2.high(56); print(p2.read(56))` -> `1`
- `import i2c; i2c.init(25, 24, 400); print(i2c.scan())` -> `[119]`
- `print(i2c.writeread(0x77, "\xD0", 1))` -> `U` (`0x55`, BMP180 chip id)
- `import spi; spi.init(10, 11, 12, 13, 0, 1000)` is live-verified
- `import worker; print(worker.start())` -> `5`
- `worker.exec("blink", 56, 50); print(worker.state())` -> `running`
- `import threads; threads.channel("a"); threads.put("a",123); print(threads.get("a"))` -> `123`
- `import rtos; rtos.channel("a"); rtos.put("a",123); print(rtos.get("a", 10))` -> `123`
- `import spin2; print(spin2.path()); print(spin2.list())` -> `/spin2` and `[]` on the current SD-visible path

Worker-side blink method used for mailbox tests:

```berry
def blink(pin, sleep_ms)
    p2.pinmode(pin, p2.OUTPUT)

    while true
        p2.high(pin)
        p2.sleep_ms(sleep_ms)

        p2.low(pin)
        p2.sleep_ms(sleep_ms)
    end
end
```

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

Task helpers:

- `rtos.spawn(name, ...int_args) -> int`: start the worker cog if needed and run a worker-side function by name with up to eight integer arguments. The current worker VM has its own environment and preloads `noop` and `blink`; it cannot see functions defined in the main VM script.
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

RTOS examples live in `../../../examples/rtos/`:

- `smoke.be`: locks, queues, events, timers, deferred callbacks, and debug maps.
- `spawn_blink.be`: worker-backed LED blink through `rtos.spawn()`.
- `queue_timer.be`: queue draining and timer polling.

Reserved-pin note on the current Catalina `P2_EDGE` path:

- pins `58..61` are reserved by the SD card interface
- pins `62..63` are reserved by the serial console
- on the tested no-PSRAM board, pins `56` and `57` are exposed as LEDs and are left available for Berry GPIO use
- on PSRAM P2 Edge builds, pins `40..57` are reserved by the memory interface, and pin `57` is PSRAM chip-select
- Berry GPIO, `i2c`, and `spi` helpers should avoid the SD and serial pins

Primary development focus from now on:

- macOS
- Catalina / `lcc`
- `P2_EDGE`
- latest silicon path (`P2_SILICON=latest`, targeting your Rev C board)
- no-PSRAM P2 Edge defaults (`CATALINA_MODEL=COMPACT`, `CATALINA_CLIB=-lcx`, no `-lpsram`)
- profile defaults: `full` for normal work, `minimal` for footprint work, and `xmm` reserved for later PSRAM/XMM experiments

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
- [`../../../docs/P2_LAYOUT.md`](../../../docs/P2_LAYOUT.md)
