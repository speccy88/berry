# Propeller 2 Module Reference

This document covers the P2-specific Berry surface in the `full` profile. The
standard upstream modules (`string`, `math`, `json`, `bytes`, `os`, and the
core classes) keep their normal Berry behavior unless a P2 note below says
otherwise. The P2 VM adds `/modules` as a default lazy import root so optional
`.be` libraries can live on SD instead of consuming Hub image space. On edge32,
PSRAM is available as a block-transfer backing store/cache; current code keeps
the active Berry object heap in Hub RAM.

The normal board profile is the no-PSRAM P2 Edge build:

```sh
make configure TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp \
  P2_SILICON=latest CATALINA_PLATFORM=P2_EDGE CATALINA_MODEL=COMPACT \
  CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=
```

Avoid P2 pins `58..61` for user I/O because Catalina uses them for the SD card,
and avoid pins `62..63` because they are the serial console. Pins `56` and `57`
are usable LEDs on the no-PSRAM P2 Edge profile. PSRAM builds reserve pins
`40..57`.

For a P2 Edge with the 32 MB RAM module, use the `edge32` profile:

```sh
make p2-edge32-flash PORT=/dev/cu.usbserial-P97cvdxp
```

This profile enables Catalina `-lpsram`. PSRAM is exposed to Berry as a
Catalina block-transfer device, while Berry's object heap remains in Hub RAM.

## Files, SD Card, And `os`

The P2 port wires Berry's normal file API to Catalina DOSFS. Paths are resolved
from the current Berry directory, with `/` as the SD-card root.

- `open(path, mode)`: open an SD file. Supported modes are `r`, `w`, `a`, and
  their `+` read/write forms. The current runtime keeps four file handles in a
  fixed pool.
- `run_file(path)`: compile and execute a `.be` source file in the current VM.
- `os.listdir(path)`: return a list of visible 8.3 directory names.
- `os.getcwd()` / `os.chdir(path)`: inspect or change Berry's current directory.
- `os.mkdir(path)`: create a directory. Existing directories are treated as
  success.
- `os.remove(path)`: remove a file or empty directory.
- `os.rename(from, to)`: rename a file or directory.
- `os.path.exists(path)`: true for an existing file or directory.
- `os.path.isfile(path)`: true for an existing file.
- `os.path.isdir(path)`: true for an existing directory.
- `os.path.join(a, b)`, `os.path.split(path)`, `os.path.splitext(path)`: normal
  path helpers using `/` separators.

Directory iteration uses two fixed directory slots. Catalina can return stale
raw 8.3 entries on some media, so `os.listdir()` filters hidden, volume, erased,
reserved, and non-printable names.

Example:

```berry
import os

print(os.listdir("/"))
f = open("/BERRYTMP.TXT", "w")
f.write("hello from berry")
f.close()
print(open("/BERRYTMP.TXT", "r").read())
print(os.remove("/BERRYTMP.TXT"))
```

## `p2`

`p2` is the direct Propeller 2 hardware helper module. It is intentionally
low-level; cooperative sleeps, process cogs, locks, and queues live under
`rtos`.

Constants:

- `p2.INPUT`, `p2.OUTPUT`, `p2.OPENDRAIN`: pin mode values for `p2.pinmode()`.

Clock, counter, and waits:

- `p2.clock_freq() -> int`: current system clock frequency in hertz.
- `p2.clock_mode() -> int`: current clock mode word.
- `p2.ticks() -> int`: low 32 bits of the P2 counter.
- `p2.ticks_high() -> int`: high 32 bits of the P2 counter.
- `p2.ticks64() -> int`: full counter value where the Berry integer width can
  represent it.
- `p2.wait_until(ticks)`: wait until the low counter reaches `ticks`.
- `p2.wait_ticks(ticks)`: wait for a relative number of counter ticks.
- `p2.delay_us(us)`: busy-wait for microseconds.

GPIO:

- `p2.pinmode(pin, mode)`: set input, output, or open-drain mode.
- `p2.high(pin)`, `p2.low(pin)`, `p2.toggle(pin)`: compatibility helpers for
  output state.
- `p2.read(pin) -> int`: read a pin as `0` or `1`.
- `p2.pin_input(pin)`, `p2.pin_output(pin)`, `p2.pin_float(pin)`: set direction.
- `p2.pin_write(pin, value)`, `p2.pin_low(pin)`, `p2.pin_high(pin)`,
  `p2.pin_toggle(pin)`: set or toggle output state.
- `p2.pin_read(pin) -> int`: read a pin as `0` or `1`.
- `p2.pin_randomize(pin)`: leave the pin in a randomized output state.

Cogs and attention:

- `p2.cogid()` / `p2.cog_id() -> int`: current cog ID.
- `p2.cog_start_c(fn, arg, stack_bytes) -> int`: start a C function on another
  cog. This is build-covered and still needs focused hardware validation.
- `p2.cog_start_pasm(addr, par=0) -> int`: start PASM from a Hub address.
- `p2.cog_start_hex(hex, par=0) -> int`: load a hex-encoded PASM blob and start
  it in another cog.
- `p2.cog_stop(cog)`: stop a cog through the safer P2 wrapper.
- `p2.cog_raw_stop(cog)`: direct low-level stop helper.
- `p2.cog_check(cog) -> bool`: true if a cog appears active.
- `p2.cog_states() -> list`: status for all eight cogs.
- `p2.cog_stack_bytes(cog) -> int`: stack reservation for known Berry-owned
  cogs.
- `p2.attention_signal(cog)`, `p2.attention_poll()`, `p2.attention_wait(mask)`:
  low-level P2 cog-attention helpers.

Math and smart pins:

- `p2.random() -> int`: P2 random value.
- `p2.reverse_bits(value) -> int`: reverse bit order.
- `p2.encode(value) -> int`: P2 encode helper.
- `p2.isqrt(value) -> int`: integer square root.
- `p2.muldiv64(a, b, c) -> int`: 64-bit multiply/divide helper.
- `p2.rotxy(x, y, angle) -> list`, `p2.xypol(x, y) -> list`,
  `p2.polxy(radius, angle) -> list`: CORDIC helpers.
- `p2.smartpin_write_mode(pin, mode)`, `p2.smartpin_write_x(pin, value)`,
  `p2.smartpin_write_y(pin, value)`: configure smart-pin registers.
- `p2.smartpin_ack(pin)`, `p2.smartpin_read(pin) -> int`,
  `p2.smartpin_query(pin) -> int`: inspect or acknowledge smart-pin state.
- `p2.smartpin_start(pin, mode, x, y)`, `p2.smartpin_clear(pin)`: start or clear
  smart-pin operation.

Runtime status:

- `p2.sbrk() -> int`: current heap-space estimate.
- `p2.heap_info() -> map`: heap details for diagnostics, including whether the
  Berry heap is external-RAM backed.
- `p2.psram_info() -> map`: report whether the image was built with Catalina
  PSRAM support, the expected external RAM size, the access mode, and the
  reserved pin range. On PSRAM builds the map includes `max_transfer`, the
  largest single bounded transfer exposed through the Berry wrapper.
- `p2.psram_write(address, data) -> map`: copy a Berry string or `bytes()` value
  from Hub RAM to PSRAM. This is available only on Catalina `-lpsram` builds.
- `p2.psram_read(address, size) -> string`: copy up to
  `p2.psram_info()["max_transfer"]` bytes from PSRAM into a Berry string in Hub
  RAM. PSRAM is not directly pointer-addressable by the Berry VM in the COMPACT
  profile.
- `p2.psram_test(address=nil) -> map`: on PSRAM builds, write and read a short
  pattern through Catalina's PSRAM block API. The default address is near the
  top of the 32 MB range.
- `p2.status()`: print image size, heap bars, clock info, and cog states.
- `p2.beep(pin, freq, ms)`: generate a simple tone on a pin.

## `i2c`

`i2c` is a module-global, bit-banged I2C master. It uses open-drain signaling
and expects external pull-ups for normal operation.

- `i2c.init(scl_pin, sda_pin, khz, pullup=false)`: configure bus pins and speed.
  Common values are `100`, `400`, and `1000` kHz.
- `i2c.write(addr, data) -> bool`: write raw bytes to a 7-bit address.
- `i2c.read(addr, count) -> string`: read `count` bytes.
- `i2c.writeread(addr, txdata, rxcount) -> string`: write a register/select
  prefix and read a response without releasing the bus in between.
- `i2c.scan() -> list`: scan `0x08..0x77` and return responding addresses.
- `i2c.present(addr) -> bool`: true when a 7-bit address ACKs.
- `i2c.wait(addr, timeout_ms=1000) -> bool`: wait for a device to ACK, useful
  after EEPROM-style internal writes.
- `i2c.start()`, `i2c.stop()`: expose low-level bus conditions for debugging.

Example:

```berry
import i2c

i2c.init(25, 24, 400)
print(i2c.scan())
print(i2c.writeread(0x77, "\xD0", 1))
```

## `spi`

`spi` is a module-global SPI master with explicit chip-select control. Transfers
are bounded by `BE_P2_BUS_MAX_XFER` so the driver can avoid Catalina libc heap
allocation on the full P2 image.

- `spi.init(clk_pin, mosi_pin, miso_pin, cs_pin, mode, khz)`: configure pins,
  SPI mode `0..3`, and clock speed in kHz.
- `spi.select()`: assert chip select.
- `spi.deselect()`: deassert chip select.
- `spi.write(data)`: transmit raw bytes and discard received bytes.
- `spi.read(count, filler=0xFF) -> string`: clock in bytes while transmitting
  the filler byte.
- `spi.transfer(data) -> string`: full-duplex transfer, returning one received
  byte per transmitted byte.
- `spi.stop()`: deassert CS and release configured pins.

Example:

```berry
import spi

spi.init(10, 11, 12, 13, 0, 1000)
spi.select()
print(spi.transfer("\x9F\x00\x00\x00"))
spi.deselect()
```

## `rtos`

`rtos` owns the public concurrency and synchronization API. The current full
profile supports the main VM plus one process VM/cog. Task source must be
loaded into the child VM before launch. `rtos.newcog("name", ...int_args)` is
the most explicit spelling for new code. `rtos.newcog(function, ...int_args)`
also works for named zero-upvalue Berry functions: the parent VM extracts the
function name and asks the child VM to run its own loaded copy. Captured
closures are still guarded until Berry functions can be serialized or
recompiled safely inside the target VM.

Process/cog task control:

- `rtos.load_file(path)`: load Berry source into the process VM from the SD card.
- `rtos.load_str(source)`: load Berry source text into the process VM.
- `rtos.load(source)`: compatibility alias for `rtos.load_str()`.
- `rtos.newcog(name, ...int_args) -> int`: run a loaded child-VM function by
  name on the process cog.
- `rtos.newcog(function, ...int_args) -> int`: run a named zero-upvalue Berry
  function object by launching the same function name in the child VM. The
  child VM must already have loaded a function with that name.
- `rtos.process(name, ...int_args)`, `rtos.thread(name, ...int_args)`, and
  `rtos.new(name, ...int_args)`: aliases for `rtos.newcog()`.
- `rtos.spawn(name, ...int_args) -> int`: compatibility spelling for named
  child-VM launch.
- `rtos.cog_start(name, ...int_args) -> int`: alias for `rtos.spawn()`.
- `rtos.stop()`: stop the process cog.
- `rtos.state() -> string`: current process VM state.
- `rtos.error() -> string or nil`: last child-VM error.
- `rtos.process_info() -> map`: current backend limits, process cog ID, and
  whether direct closure launch is available.
- `rtos.yield()` / `rtos.task_yield()`: cooperative yield.
- `rtos.sleep_ms(ms)`: sleep with Ctrl-C checks on the main VM.
- `rtos.cog_id() -> int`: current cog ID.

Locks:

- `rtos.new_lock() -> int`: allocate a P2 hardware lock.
- `rtos.lock(id)`: acquire a lock.
- `rtos.try_lock(id) -> bool`: attempt to acquire without blocking.
- `rtos.unlock(id)`: release a lock.
- `rtos.delete_lock(id)`: return a lock to the pool.

Queues and events:

- `rtos.channel(name) -> string`: create or fetch a named fixed queue.
- `rtos.put(name, value)`: enqueue an integer or short string.
- `rtos.get(name, timeout_ms=nil) -> value or nil`: receive, optionally with a
  timeout. `timeout_ms=0` polls once.
- `rtos.event_set(mask)`, `rtos.event_clear(mask)`: set or clear event bits.
- `rtos.event_wait(mask, timeout_ms=nil) -> bool`: wait for any matching event.
- `rtos.event_flags() -> int`: current event mask.

Timers and deferred callbacks:

- `rtos.ticks_per_ms() -> int`: counter ticks per millisecond.
- `rtos.delay_ms(ms)`: millisecond delay helper.
- `rtos.timer_start(ms) -> int`: allocate/start a one-shot timer.
- `rtos.timer_expired(id) -> bool`: true when a timer has expired.
- `rtos.timer_wait(id)`: wait until a timer expires.
- `rtos.irq_enable(channel, handler_name)`: register a deferred Berry callback.
- `rtos.irq_poll() -> int`: dispatch pending deferred callbacks.
- `rtos.irq_disable(channel)`: remove a deferred callback.

Debug constants and helpers:

- `rtos.IRQ_ATN`: deferred callback channel tied to P2 cog-attention polling.
- `rtos.IRQ_DEFERRED`: true on this implementation because callbacks are
  dispatched from Berry code, not from an interrupt service routine.
- `rtos.QUEUE_MAX`, `rtos.TIMER_MAX`: current fixed pool sizes.
- `rtos.debug_tasks() -> list`: maps with cog, state, and stack information.
- `rtos.debug_regs(cog) -> map`: selected register/counter diagnostics. Only
  the current cog's PTRA/PTRB/INA/INB/OUTA/OUTB/DIRA/DIRB are directly readable.

Example:

```berry
import rtos

rtos.channel("rx_packets")
rtos.load_file("/examples/rtos/workers/packet_reader.be")
rtos.newcog("packet_reader", 50)
print(rtos.get("rx_packets", 250))
rtos.stop()
```

Function-object launch for the safe subset:

```berry
import rtos

def packet_reader(period_ms) end       # parent-side launch handle

rtos.channel("rx_packets")
rtos.load_file("/examples/rtos/workers/packet_reader.be")
rtos.newcog(packet_reader, 50)         # launches child VM's packet_reader()
print(rtos.get("rx_packets", 250))
rtos.stop()
```

## `spin2`

`spin2` loads compiled Spin2/PASM binaries from the SD card. Mailbox-aware
binaries can be called from Berry with integer arguments. Raw standalone PASM
can be launched, but normal high-level FlexSpin images are not relocatable and
are rejected.

- `spin2.path(path=nil) -> string`: get or set the base SD directory. Default is
  `/spin2`.
- `spin2.list(path=nil) -> list`: list compatible binary filenames in a path.
- `spin2.start(file, par=0) -> handle`: load and start a binary.
- `spin2.call(handle, method_id, ...int_args) -> int`: call a mailbox method.
- `spin2.stop(handle)`: stop the launched cog and release owned memory.
- `spin2.info(handle) -> map`: report cog, size, ABI, and filename details.

Example:

```berry
import spin2

print(spin2.path())
print(spin2.list())
# handle = spin2.start("MBOXDEMO.BIN")
# print(spin2.call(handle, 1, 123))
# spin2.stop(handle)
```

## `wifi`

`wifi` is a Berry script module for WiFiNINA / AirLift SPI firmware. It is a
transport skeleton, not yet a verified network stack. On the current ESP32-C6
AirLift board, reset is fixed but firmware detection still needs hardware
bring-up because READY/BUSY was not asserted during the last probe.

Default P2 pin map:

| Function | Propeller 2 pin | ESP32-C6 pin |
| -------- | --------------- | ------------ |
| SPI SCK  | P16             | GPIO6        |
| SPI MOSI | P17             | GPIO7        |
| SPI MISO | P18             | GPIO2        |
| CS       | P19             | GPIO16       |
| BUSY     | P20             | GPIO5        |
| RESET    | P21             | GPIO4        |
| IRQ      | P22             | GPIO0        |

Functions:

- `wifi.init(cfg=nil) -> wifi`: configure P2 pins, reset the AirLift
  coprocessor, and initialize `spi`. `cfg` may override `sck`, `mosi`, `miso`,
  `cs`, `busy`, `reset`, `irq`, `khz`, or `mode`.
- `wifi.request(cmd, params=[], expected_params=nil) -> list`: send a raw
  WiFiNINA command frame and parse the response parameters.
- `wifi.firmware_version() -> string`: send `GET_FW_VERSION_CMD` (`0x37`).
- `wifi.status_code() -> int`: send `GET_CONN_STATUS_CMD` (`0x20`) and return
  the numeric firmware status.
- `wifi.status() -> string`: map the status code to a readable name.
- `wifi.last_response() -> list or nil`: return the last parsed raw response.
- `wifi.stop()`: release the SPI bus and mark the module uninitialized.

Example:

```berry
import wifi

wifi.init({
    "sck": 16, "mosi": 17, "miso": 18, "cs": 19,
    "busy": 20, "reset": 21, "irq": 22
})

print(wifi.firmware_version())
print(wifi.status())
```

## `libstore`

`libstore` is a Berry source module under `/modules/libstore.be`. It documents
and probes the current SD-first library store:

- `libstore.paths`: current SD library roots. The firmware adds `/modules` to
  Berry's import path at VM startup.
- `libstore.status() -> map`: reports lazy SD loading, Hub-heap execution, and
  whether PSRAM is available as a source-cache backend.
- `libstore.strategy() -> map`: reports the storage model: SD is the canonical
  library home, PSRAM is a transfer/cache backend when available, and live Berry
  objects still use the Hub heap.
- `libstore.modules() -> list`: return the known SD module names.
- `libstore.psram() -> map`: returns `p2.psram_info()`.
- `libstore.exists(name) -> bool`: true when `/modules/<name>.be` exists.
- `libstore.source_path(name) -> string or nil`: returns the SD source path.
- `libstore.info(name) -> map`: return SD path/cache metadata for one module.
- `libstore.cache_source(name) -> map or nil`: copy one module's source text
  from SD into the reserved PSRAM cache area when PSRAM is available.
- `libstore.cached_source(name) -> string or nil`: read cached source text back
  from PSRAM into a temporary Hub string.
- `libstore.cache_reset()`: clear the in-memory cache directory and reset the
  PSRAM allocation pointer.
- `libstore.run_cached(name)`: compile and call a cached source module. This is
  mainly a diagnostic path; normal `import` still loads lazily from SD.
- `libstore.run(path)`: calls `run_file(path)`.

Example:

```berry
import libstore
print(libstore.status())
print(libstore.strategy())
print(libstore.exists("binary_heap"))
print(libstore.info("binary_heap"))
```

## `math`

On P2, `math` is an SD-loaded Berry source module under `/modules/math.be`
instead of a native Hub-resident module. This keeps the image smaller and avoids
the Catalina/P2 native math-call path. The current SD module covers the P2 smoke
surface: `pi`, `imax`, `imin`, `abs`, `sqrt`, `min`, `max`, `floor`, `ceil`,
`round`, `pow` for positive integer exponents, `deg`, `rad`, `isnan`, `isinf`,
`srand`, and `rand`.

## `taskspin`

`taskspin` is a Berry source module under `/modules/taskspin.be`. It provides a
Spin2-shaped cooperative task vocabulary without adding to the P2 firmware
image. This is callback-step scheduling inside the current Berry VM, not
stackful frame switching: each task is a closure that retains its own state and
is called once by `TASKNEXT()`.

Constants:

- `taskspin.FREE`, `taskspin.RUNNING`, `taskspin.HALTED`: task status values.
- `taskspin.STOP`, `taskspin.RUN`, `taskspin.HALT`: return values a task step
  can use after being called by `TASKNEXT()`.
- `taskspin.MAX_TASKS`: fixed at `32`, matching the Spin2 task vocabulary.

Functions:

- `taskspin.TASKSPIN(task, step, state) -> int`: create a task. Use `task=-1`
  for the first free slot, or `0..31` for a fixed slot. `step(id, state)` is
  called by `TASKNEXT()`.
- `taskspin.TASKNEXT() -> int`: run the next unhalted task step and return its
  task ID, or `-1` if no task can run.
- `taskspin.TASKSTOP(task) -> bool`: stop/free a task. Use `-1` for current.
- `taskspin.TASKHALT(task) -> bool`: halt a task. Use `-1` for current.
- `taskspin.TASKCONT(task) -> bool`: continue a halted task.
- `taskspin.TASKCHK(task) -> int`: return `FREE`, `RUNNING`, or `HALTED`.
- `taskspin.TASKID() -> int`: current task ID, or `-1` before any task step.
- `taskspin.reset()`: clear all slots.
- `taskspin.info() -> map`: scheduler status and model information.

Example:

```berry
import taskspin

var state = {"n": 0}

def blink_step(id, state)
    state["n"] += 1
    # do one small piece of work here
    return state["n"] >= 10 ? taskspin.STOP : taskspin.RUN
end

taskspin.TASKSPIN(-1, blink_step, state)
while taskspin.TASKNEXT() >= 0
end
```
