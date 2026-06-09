You are Codex working on a Propeller 2 + Berry language integration repository.

Your mission is to build the most complete, serious, production-quality Berry system for the Parallax Propeller 2 possible. The goal is not a small demo or a thin binding layer. The goal is to create a Berry-on-Propeller-2 environment that can eventually rival MicroPython-class projects, while taking full advantage of the unique architecture of the Propeller 2.

I want a complete Berry integration with:

- Full support for the included/upstream Berry language features and Berry libraries.
- Berry programs stored on SD card as `.be` files.
- Support for compiled Berry bytecode/cache files where possible, such as `.bec`.
- Lazy loading of Berry libraries from SD card.
- PSRAM used aggressively as a cache/storage tier for libraries, bytecode, source cache, compiled cache, large buffers, and inactive modules, to preserve precious P2 hub RAM.
- Berry VM using internal hub RAM efficiently for active execution.
- Safe staging of active code/data from PSRAM into hub RAM only when needed.
- Multiple Berry VMs running in different P2 cogs.
- Real multicore execution where a Berry closure can be launched into another cog, not a fake worker queue.
- Direct low-level access to all important Propeller 2 hardware functions.
- High-level friendly Berry wrappers around Propeller 2 hardware features.
- Raw smart pin access.
- High-level smart pin wrappers for ADC, DAC, PWM, USB, timers, counters, UART, SPI/synchronous serial, quadrature, pulse measurement, frequency generation, and other smart pin capabilities.
- P2 assembly / PASM2 integration through native functions, FFI, or a safe PASM blob/function bridge.
- Catalina-like Propeller 2 feature coverage, including VGA/video output and USB keyboard/mouse where possible.
- Cooperative multitasking inside a cog inspired by Spin2 v47 `TASKSPIN`, `TASKNEXT`, `TASKSTOP`, `TASKHALT`, `TASKCONT`, `TASKCHK`, and `TASKID`.
- RTOS-inspired synchronization primitives inspired by uC/OS-II, but do not blindly copy code.
- Propeller 2-specific debugging features, including VM debug, cog debug, task debug, memory debug, smart pin debug, and hardware debug where possible.
- Complete tests, examples, documentation, and honest coverage tracking.

Important: preserve the current architecture where libraries sit on the SD card, are lazy-loaded, and can go to PSRAM to save hub RAM. Do not replace this architecture with eager hub-RAM loading.

Reference material to inspect before implementing:

- Berry reference:
  https://berry.readthedocs.io/en/latest/source/en/Reference.html#

- Berry libraries/modules:
  https://berry.readthedocs.io/en/latest/source/en/Chapter-7.html

- Berry import/package/solidify/advanced features:
  https://berry.readthedocs.io/en/latest/source/en/Chapter-8.html

- Berry FFI example:
  https://berry.readthedocs.io/en/latest/source/en/FFI-Example.html

- Berry memory requirements:
  https://berry.readthedocs.io/en/latest/source/en/Memory-Requirements.html

- Catalina Propeller 2 API reference:
  https://github.com/rosshigson/Catalina/blob/339ee1df83b4639cf8c1d71c6ace9757587afd75/include/prop2.h

- Catalina project:
  https://github.com/rosshigson/Catalina

- Propeller 2 documentation / datasheet / architecture:
  https://www.mouser.com/datasheet/2/321/Propeller2_P2X8C4M64P_Datasheet_20210709-3006917.pdf
  https://docs.alexrp.com/propeller/propeller_2_arch.pdf

- P2 smart pin documentation:
  https://p2docs.github.io/pin.html

- uC/OS-II inspiration:
  https://github.com/weston-embedded/uC-OS2

Before changing code, inspect the repository carefully. Create or update these documentation files first:

- `docs/architecture-current.md`
- `docs/source-research.md`
- `docs/coverage-matrix.md`
- `docs/roadmap.md`

`docs/architecture-current.md` must describe:

- Current build system.
- Current Berry port state.
- Current SD loader behavior.
- Current PSRAM behavior.
- Current Propeller 2 hardware bindings.
- Current tests.
- Current examples.
- Current memory map.
- Current known limitations.

`docs/source-research.md` must summarize what matters from Berry, Catalina, P2 docs, smart pin docs, and uC/OS-II for this project.

`docs/coverage-matrix.md` must track:

- Berry language feature coverage.
- Berry standard-library coverage.
- Berry expansion-module coverage.
- SD loader coverage.
- PSRAM cache coverage.
- P2 primitive API coverage.
- Smart pin mode coverage.
- High-level hardware wrapper coverage.
- PASM/assembly integration coverage.
- Multicog Berry VM coverage.
- Closure-in-cog coverage.
- Cooperative task coverage.
- Debug feature coverage.
- Example coverage.
- Test coverage.

`docs/roadmap.md` must explain the implementation phases, risks, dependencies, and tests.

Do not start with broad rewrites. First understand the repo.

Hard constraints:

1. Preserve SD-card library storage.
2. Preserve lazy loading.
3. Do not load every Berry library into hub RAM at boot.
4. Use PSRAM as the preferred cache/storage tier for inactive modules, compiled bytecode, source cache, and large buffers.
5. Keep active VM heap, active stacks, currently executing bytecode/pages, and live GC-managed objects in memory that is safe for Berry’s VM and GC.
6. Do not assume PSRAM can directly hold arbitrary live Berry GC objects unless the current hardware/driver truly supports safe pointer-like random access and this is proven by tests.
7. Default design: live VM heap in hub RAM, active bytecode/prototypes staged in hub RAM, inactive modules/cache/source/large buffers in PSRAM, persistent files on SD card.
8. No fake APIs. If a function is declared, it must either work and be tested or raise a clear “not implemented on this build/board” error.
9. Unsafe raw hardware and assembly access must be behind explicit modules or build flags.
10. Do not break upstream Berry semantics.
11. Do not implement concurrency as a fake worker queue. I want real closures launched into other cogs where possible.
12. Every feature needs tests, examples, and docs.

Berry compatibility requirements:

Support all included/upstream Berry libraries available in this Berry version.

At minimum verify and test:

- `print`
- `input`
- `classname`
- `classof`
- `str`
- `number`
- `int`
- `real`
- `bool`
- `type`
- `size`
- `super`
- `assert`
- `compile`
- `module`
- `issubclass`
- `isinstance`
- `call`
- `list`
- `map`
- `file`
- `range`
- `bytes`
- `json`
- `math`
- `time`
- `string`
- `os`
- `os.path`
- `global`
- `introspect`
- `solidify`
- `strict`
- any other included Berry modules in this repository/version.

For each Berry module:

- Add a test.
- Add SD import test.
- Add repeated import/cache test.
- Add PSRAM-cache import test if relevant.
- Add low-memory behavior test if possible.
- Document unsupported host-like features honestly if a bare-metal target cannot provide them.

`file`, `os`, and `os.path` must map cleanly to the SD-card filesystem. They must not assume a desktop OS.

Default SD layout should support something like:

- `/berry/main.be`
- `/berry/lib/*.be`
- `/berry/lib/*.bec`
- `/berry/app/*.be`
- `/berry/app/*.bec`
- `/berry/cache/*.bec`
- `/berry/config/*.json`
- `/berry/examples/*`
- `/berry/pasm/*`

The Berry import system should support:

- native modules first
- current directory
- configured `sys.path`
- `.bec` preferred over `.be` when valid and newer
- `.be` fallback when `.bec` is missing, invalid, or stale
- optional compile-to-cache behavior
- global module cache
- lazy loading
- PSRAM-backed inactive module/cache storage where safe

Expose diagnostics like:

```berry
import p2mem

print(p2mem.stats())
print(p2mem.modules())
print(p2mem.cache())
p2mem.gc()
p2mem.evict()
````

Memory/cache metadata should track:

* module name
* source path
* compiled path
* storage tier
* source hash
* compiled hash
* mtime if available
* hub bytes used
* PSRAM bytes used
* cache hit count
* cache miss count
* refcount/pinned state
* last-used timestamp

Propeller 2 hardware API:

Create a native module named `p2`, with submodules as appropriate.

Target APIs should include low-level and high-level layers.

Clock/system:

```berry
import p2

p2.clock.freq()
p2.clock.mode()
p2.clock.set(mode, freq)
p2.clock.cnt()
p2.clock.cnth()
p2.clock.waitx(cycles)
p2.clock.waitus(us)
p2.clock.waitms(ms)
p2.clock.waitsec(sec)
p2.clock.waitcnt(tick)
p2.clock.hubset(value)
```

Cogs:

```berry
p2.cog.id()
p2.cog.check(cog_id)
p2.cog.stop(cog_id)
p2.cog.attention(mask)
p2.cog.poll_attention()
p2.cog.wait_attention()
```

Locks:

```berry
p2.lock.new()
p2.lock.ret(lock_id)
p2.lock.try(lock_id)
p2.lock.release(lock_id)
p2.lock.check(lock_id)
```

GPIO:

```berry
p2.pin.dir_low(pin)
p2.pin.dir_high(pin)
p2.pin.write(pin, value)
p2.pin.low(pin)
p2.pin.high(pin)
p2.pin.toggle(pin)
p2.pin.float(pin)
p2.pin.read(pin)
```

CORDIC/math/random:

```berry
p2.cordic.rotxy(x, y, theta)
p2.cordic.polxy(r, theta)
p2.cordic.xypol(x, y)
p2.math.isqrt(x)
p2.math.muldiv64(a, b, divisor)
p2.math.rev(x)
p2.math.encod(x)
p2.rng.rnd()
```

Raw smart pin access:

```berry
p2.smart.wrpin(pin, mode)
p2.smart.wxpin(pin, x)
p2.smart.wypin(pin, y)
p2.smart.akpin(pin)
p2.smart.rdpin(pin)
p2.smart.rqpin(pin)
p2.smart.start(pin, mode, x, y)
p2.smart.clear(pin)
```

All low-level APIs must validate:

* pin range `0..63`
* cog range
* lock range
* integer bounds
* board-specific reserved pins
* unsupported feature/build combinations

Smart pin coverage:

Research all smart pin modes and create constants/wrappers for mode families including:

* normal/dumb pin
* repository mode
* DAC noise
* DAC random dither
* DAC PWM dither
* pulse/cycle output
* transition output
* NCO frequency output
* NCO duty output
* PWM triangle
* PWM sawtooth
* PWM SMPS
* quadrature encoder
* register up counter
* register up/down counter
* count rises
* count highs
* state ticks
* high ticks
* event ticks
* period ticks
* period highs
* counter ticks
* counter highs
* counter periods
* ADC internal
* ADC external
* ADC scope/capture
* USB pin pair modes
* synchronous serial TX
* synchronous serial RX
* asynchronous serial TX
* asynchronous serial RX

High-level wrappers should include:

```berry
import p2

led = p2.gpio.Output(56)
led.high()
led.low()
led.toggle()

button = p2.gpio.Input(3, pull="up")
print(button.read())

pwm = p2.pwm.open(pin=0, freq=1000, duty=0.5, mode="sawtooth")
pwm.duty(0.25)
pwm.freq(2000)
pwm.close()

adc = p2.adc.open(pin=1, bits=14, filter="sinc3")
print(adc.raw())
print(adc.volts())
adc.close()

dac = p2.dac.open(pin=2, bits=16, mode="dither_pwm")
dac.raw(32768)
dac.volts(1.65)
dac.close()

timer = p2.timer.periodic_us(1000)
timer.wait()
timer.close()

quad = p2.quadrature.open(pin_a=4, pin_b=5)
print(quad.position())
print(quad.velocity())
quad.close()

uart = p2.uart.open(tx=8, rx=9, baud=115200)
uart.write("hello")
print(uart.read(5))
uart.close()

spi = p2.spi.open(clk=10, mosi=11, miso=12, cs=13, baud=1_000_000)
spi.transfer(bytes("abc"))
spi.close()

usb = p2.usb.open_pair(dm=16, dp=17, mode="host", speed="full")
usb.close()
```

Video/USB/Catalina-class support:

Support, or create a staged implementation plan for, at least:

* serial console
* SD filesystem
* VGA test output
* streamer-based video output if supported
* USB keyboard input
* USB mouse input
* USB HID examples
* timer/counter APIs
* CORDIC API
* GPIO
* smart pins
* multicog APIs
* locks and IPC
* debug/monitor hooks
* optional audio DAC example
* optional PS/2 keyboard/mouse compatibility if useful

Do not fake VGA or USB support. If not implemented yet, document it clearly in the coverage matrix.

PASM2 / assembly integration:

Create a `p2.asm` or `p2.unsafe.asm` module.

Implement layers:

Layer 1: safe native intrinsics.

```berry
import p2

p2.asm.getrnd()
p2.asm.getct()
p2.asm.waitx(cycles)
p2.asm.hubset(value)
```

Layer 2: PASM blob launcher.

```berry
blob = p2.asm.load("/berry/pasm/blinker.bin")
cog = p2.asm.cognew(blob, arg)
```

Layer 3: PASM function bridge.

```berry
fn = p2.asm.load_function("/berry/pasm/fast_crc32.bin",
                          args=["ptr", "int"],
                          returns="int")
crc = fn(buffer, size(buffer))
```

Layer 4: optional inline assembler if reasonable.

```berry
fast = p2.asm.compile("""
        mov result, arg0
        rev result
        ret
""")
print(fast(0x12345678))
```

Do not allow unsafe arbitrary assembly execution in normal builds. Put it behind:

* `BE_P2_ENABLE_UNSAFE_ASM`

Document the PASM ABI:

* argument passing
* return value
* clobbered registers
* hub pointer rules
* PSRAM pointer rules
* cog RAM/LUT rules
* interrupt assumptions
* stack assumptions
* cleanup rules

Multicore Berry closures:

Implement real closure-based cog spawning.

Target API:

```berry
import p2

def worker(name, count)
  for i: 0..count
    print(name, i)
    p2.clock.waitms(100)
  end
  return count
end

handle = p2.cog.spawn(worker, "A", 10)
print(handle.id())
print(handle.status())
print(handle.join())
```

This must not be a fake worker queue. A closure passed to `p2.cog.spawn()` should run in another cog, ideally in a separate Berry VM hosted by that cog.

Required semantics:

* `p2.cog.spawn(closure, ...args)` launches a Berry closure on another cog.
* Each cog-hosted Berry process has its own VM state, stack, heap, and GC.
* Read-only code/prototypes/modules may be shared only when safe.
* Mutable captured values must have defined behavior:

  * copy-by-value by default, or
  * explicit rejection if not serializable, or
  * explicit sharing through `p2.shared`.
* Native pointers must not be blindly transferred.
* File handles must not be blindly transferred.
* Hardware resources must be claimed through a resource manager.
* Parent receives a handle.
* Child can return a value or error.
* Errors propagate to `join()`.
* Child VM cleanup must be deterministic.

Target API:

```berry
handle = p2.cog.spawn(fn, ...args, stack=..., heap=..., cog=-1, name="worker")
handle.id()
handle.status()
handle.join()
handle.stop()
handle.kill()
handle.result()
handle.error()
```

IPC primitives:

```berry
ch = p2.channel.new(depth=8)
ch.send(value)
value = ch.recv(timeout_ms=1000)

mb = p2.mailbox.new()
mb.put(value)
value = mb.get()

shared = p2.shared.Buffer(1024)

mutex = p2.mutex.new()
mutex.lock()
mutex.unlock()
```

Use P2 locks, hub memory, channels/mailboxes, and cog attention where appropriate.

Cooperative task scheduler:

Implement cooperative multitasking inside a cog, inspired by Spin2 v47.

Target module:

```berry
import task
```

Target API:

```berry
id = task.spin(task_id, closure, ...args, stack=nil)
task.next()
task.stop(task_id)
task.halt(task_id)
task.cont(task_id)
status = task.chk(task_id)
id = task.id()
```

Semantics to implement:

* Up to 32 tasks per cog where memory allows.
* `task.spin(-1, closure, args...)` uses first free task slot.
* Fixed task IDs `0..31` are supported.
* Returns task ID or `-1` if no task slot is free.
* `task.next()` yields to the next unhalted task.
* If only one task remains, `task.next()` has no effect.
* `task.stop(-1)` stops current task.
* Top-level return from a task acts like `task.stop(-1)`.
* `task.halt(id)` halts a task.
* If a task halts itself, scheduler automatically yields.
* `task.cont(id)` resumes a halted task.
* `task.chk(id)` returns:

  * `0` free
  * `1` running
  * `2` halted
* `task.id()` returns current task ID.
* If all tasks are halted, scheduler waits for an interrupt/event/explicit continuation if available.
* If Spin2/PASM halt bits or equivalent runtime support is available, map to it. Otherwise implement an equivalent scheduler-local halt mask.
* Tasks need independent Berry call stacks or a proven safe coroutine/continuation mechanism.
* Do not implement this as simple callback polling.

RTOS-inspired primitives:

```berry
sem = task.Semaphore(count=1)
mutex = task.Mutex()
queue = task.Queue(depth=8)
flags = task.EventFlags()
timer = task.Timer(period_ms=10, repeat=true)
```

Debugging:

Create a `p2.debug` module and debug build mode.

Target API:

```berry
import p2

p2.debug.breakpoint()
p2.debug.trace(true)
p2.debug.stack()
p2.debug.heap()
p2.debug.gc()
p2.debug.cogs()
p2.debug.tasks()
p2.debug.modules()
p2.debug.memory_map()
p2.debug.pins()
p2.debug.smartpin(pin)
p2.debug.registers()
p2.debug.locks()
p2.debug.channels()
```

Debug output should include:

* Berry stack trace with source file/line where possible.
* Native error info where possible.
* VM heap stats.
* GC stats.
* Module cache stats.
* SD/PSRAM/hub tier placement.
* Cog state.
* Task state.
* Lock state.
* Channel/mailbox state.
* Smart pin state snapshot.
* Pin direction/output/input state.
* Optional PASM breakpoint/single-step/hardware debug support if feasible.

Build flags:

* `BE_P2_DEBUG=0/1`
* `BE_P2_TRACE_IMPORTS=0/1`
* `BE_P2_TRACE_GC=0/1`
* `BE_P2_TRACE_COGS=0/1`
* `BE_P2_TRACE_TASKS=0/1`
* `BE_P2_ENABLE_UNSAFE_ASM=0/1`

Performance investigation:

Create `docs/performance.md`.

Measure or prepare measurement hooks for:

* baseline Berry VM speed
* import latency from SD
* import latency from PSRAM cache
* hub RAM high-water mark
* PSRAM usage
* GC pause time
* cog spawn latency
* task switch latency
* channel latency
* smart-pin wrapper overhead
* native/PASM speedup
* video/streamer throughput if relevant
* SD read throughput
* PSRAM read/write throughput

Investigate whether:

* Berry bytecode dispatch can benefit from LUT RAM tables.
* Hot VM dispatch code can live in cog RAM.
* P2 custom-bytecode/execution features can help Berry dispatch.
* CORDIC can accelerate Berry math.
* Streamer can accelerate video/audio/buffer movement.
* Smart pins can offload timing-heavy protocols.
* PSRAM cache improves import time without hurting active execution.

Do not add complicated acceleration unless benchmarks prove value.

Testing:

Create a repeatable test system.

Host tests:

```sh
make test-host
```

Should cover:

* Berry standard libraries.
* Loader behavior using fake SD.
* PSRAM cache behavior using fake PSRAM.
* Import cache behavior.
* Module eviction.
* Error paths.
* Closure serialization/copy rules.
* Task scheduler logic if host-simulatable.

P2 hardware tests:

```sh
make test-p2 PORT=/dev/ttyUSB0 BOARD=p2edge
```

Should cover:

* boot
* REPL or main program launch
* SD mount
* PSRAM detection
* `.be` load from SD
* `.bec` load from SD/cache
* import all standard Berry modules
* GPIO
* raw smart pin
* PWM
* ADC
* DAC
* UART loopback
* SPI/sync serial loopback where wired
* timer/counter
* CORDIC
* locks
* cog spawn
* cog join
* channel IPC
* cooperative task scheduler
* VGA/video demo if hardware available
* USB keyboard/mouse if hardware available
* PASM blob launcher
* debug stats

Add long-run stability test:

```sh
make soak-p2 PORT=/dev/ttyUSB0 HOURS=1
```

The soak test should repeatedly:

* import modules
* evict modules
* run GC
* use SD
* use PSRAM
* spawn/stop cogs
* use channels
* run cooperative tasks
* exercise GPIO/smart pins
* report memory leaks or failures

Hardware test docs must clearly say:

* which pins to connect
* required loopback wiring
* required resistors
* required board variant
* which tests are skipped without hardware

Examples to include:

* `examples/blink.be`
* `examples/repl_sd.be`
* `examples/import_all_libs.be`
* `examples/json_sd.be`
* `examples/file_sd.be`
* `examples/adc_read.be`
* `examples/dac_write.be`
* `examples/pwm_fade.be`
* `examples/uart_loopback.be`
* `examples/spi_loopback.be`
* `examples/quadrature_counter.be`
* `examples/vga_test_pattern.be`
* `examples/usb_keyboard_mouse.be`
* `examples/cog_closure.be`
* `examples/cog_channel.be`
* `examples/task_scheduler.be`
* `examples/pasm_direct.be`
* `examples/cordic_demo.be`
* `examples/psram_cache_stats.be`
* `examples/debug_report.be`

Documentation to create/update:

* `README.md`
* `docs/getting-started.md`
* `docs/building.md`
* `docs/board-support.md`
* `docs/sd-layout.md`
* `docs/psram-loader.md`
* `docs/berry-compatibility.md`
* `docs/p2-api.md`
* `docs/smartpins.md`
* `docs/cogs.md`
* `docs/tasks.md`
* `docs/pasm.md`
* `docs/debugging.md`
* `docs/testing.md`
* `docs/performance.md`
* `docs/limitations.md`

Public API style:

Keep the Berry API clean, simple, and idiomatic.

Low-level example:

```berry
import p2

p2.pin.high(56)
p2.clock.waitms(500)
p2.pin.low(56)
```

High-level hardware example:

```berry
import p2

pwm = p2.pwm.open(0, freq=1000, duty=0.5)
pwm.duty(0.1)
pwm.close()
```

Multicore example:

```berry
import p2

def job(n)
  return n * 2
end

h = p2.cog.spawn(job, 21)
print(h.join())
```

Task example:

```berry
import task
import p2

def blink()
  while true
    p2.pin.toggle(56)
    p2.clock.waitms(250)
    task.next()
  end
end

task.spin(-1, blink)
```

Acceptance criteria:

The project is successful only when:

1. Firmware builds cleanly.
2. It boots on the selected P2 board.
3. A Berry program can run from SD card.
4. `.be` programs can be loaded from SD card.
5. `.bec` files can be loaded when present.
6. Berry imports are lazy.
7. Inactive libraries/modules are cached or staged through PSRAM where safe.
8. Hub RAM usage is measured and reported.
9. All included Berry standard libraries are present or honestly documented.
10. Berry standard libraries have tests.
11. `file`, `os`, and `os.path` work against SD card.
12. P2 low-level hardware functions equivalent to Catalina-style coverage are exposed or explicitly documented as unsupported.
13. Raw smart pin access works.
14. High-level wrappers exist for ADC, DAC, PWM, timers/counters, serial, quadrature, and USB building blocks where possible.
15. VGA/video and USB keyboard/mouse have working demos or clear staged implementation notes.
16. PASM blobs can be loaded and launched.
17. Safe native/PASM intrinsics are exposed.
18. A Berry closure can run in a new cog with its own VM or a clearly documented safe VM model.
19. Multiple Berry VMs can run across multiple cogs.
20. Inter-cog channel/mailbox communication works.
21. Cooperative tasks work inside a cog with the requested Spin2-like API.
22. Debug APIs report VM, memory, module, cog, task, and pin state.
23. Tests cover every implemented API.
24. Hardware tests are documented and runnable.
25. Examples are included.
26. No stub silently pretends to work.
27. `docs/coverage-matrix.md` honestly shows remaining gaps.

Implementation milestones:

Milestone 1: Audit and baseline

* Inspect repo.
* Create architecture docs.
* Create coverage matrix.
* Create roadmap.
* Make current build/test process reliable.

Milestone 2: Berry compatibility

* Verify upstream Berry language/library behavior.
* Fix missing built-ins/modules.
* Add SD-backed `file`, `os`, and `os.path`.
* Add standard-library tests.

Milestone 3: SD/PSRAM lazy loader

* Implement or improve tiered loader.
* Add `.be` and `.bec` support.
* Add PSRAM cache.
* Add module diagnostics.
* Add import/eviction tests.

Milestone 4: P2 primitive module

* Implement `p2.clock`, `p2.cog`, `p2.lock`, `p2.pin`, `p2.cordic`, `p2.rng`.
* Add tests and examples.

Milestone 5: Smart pins

* Implement constants and raw smart pin functions.
* Implement high-level ADC, DAC, PWM, timer/counter, serial, quadrature wrappers.
* Add loopback/hardware tests.

Milestone 6: PASM integration

* Implement safe intrinsics.
* Implement PASM blob loading.
* Implement cog launcher.
* Add PASM ABI docs and tests.

Milestone 7: Multicore Berry closures

* Implement closure spawn into cog-hosted VM.
* Implement handles, join, stop, error propagation.
* Implement IPC.
* Add stress tests.

Milestone 8: Cooperative task scheduler

* Implement 32-slot task scheduler where memory allows.
* Implement task API.
* Implement queue/mutex/semaphore/event/timer primitives.
* Add tests.

Milestone 9: Video, USB, debug

* Add VGA/video demo.
* Add USB keyboard/mouse demo.
* Add debug module.
* Add performance docs.

Milestone 10: Polish

* Full examples.
* Full docs.
* Soak tests.
* Benchmarks.
* API review.
* Final coverage report.

Final instruction:

Be ambitious, but be honest. Implement real features, not impressive-looking stubs. Preserve the SD-card lazy-loading and PSRAM-cache architecture. Keep hub RAM for active execution and use PSRAM intelligently for inactive/cache data. When a feature is not finished, document it clearly in the coverage matrix and make the API fail loudly instead of pretending to work.
