# Propeller 2 Module Reference

This document covers the P2-specific Berry surface in the `full` profile. The
standard upstream modules (`string`, `math`, `json`, `bytes`, `os`, and the
core classes) keep their normal Berry behavior unless a P2 note below says
otherwise. On current P2 builds, `string`, `math`, and `task` are native
firmware modules, so they do not require SD files. The P2 VM adds `/modules` as a default lazy import root so optional
`.be` libraries can live on SD instead of consuming Hub image space. On edge32,
PSRAM is available as a block-transfer backing store/cache; current code keeps
the active Berry object heap in Hub RAM.

The normal board profile is the no-PSRAM P2 Edge build:

```sh
make configure TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp \
  P2_SILICON=latest P2_BOARD=p2edge CATALINA_PLATFORM=P2_EDGE \
  CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=
```

Avoid P2 pins `58..61` for user I/O because Catalina uses them for the SD card,
and avoid pins `62..63` because they are the serial console. `P2_BOARD=p2edge`
uses onboard LEDs on pins `56` and `57`. `P2_BOARD=p2edge32` uses onboard LEDs
on pins `38` and `39`; PSRAM builds reserve pins `40..57`.

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
low-level; cooperative scheduling lives under `task`, and native cog handle
experiments live under `p2.cog`.

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
- `p2.status_info() -> map`: return a structured runtime snapshot with build,
  runtime, clock, memory, PSRAM, and cog fields. This is the machine-readable
  companion to `p2.status()` for tests and diagnostics.
- `p2.debug_snapshot() -> map`: alias for `p2.status_info()`.
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

## `task`

`task` is the supported cooperative scheduler API for Berry work that should
share the current VM inside one cog. V1 is cooperative: each task function runs
one step and returns a scheduler instruction. It is not preemptive and does not
provide an independent Berry call stack per task.

Core helpers:

- `task.start(fn, ...args) -> handle`: start a cooperative task.
- `task.next() -> int`: run one scheduler step.
- `task.run(max_steps=nil, idle_ms=1) -> int`: run the scheduler loop.
- `task.stop(handle=-1) -> bool`: stop a task; `-1` means the current task.
- `task.pause(handle=-1) -> bool` / `task.resume(handle) -> bool`: pause or resume tasks.
- `task.status(handle) -> string`: return `free`, `ready`, `waiting`, `paused`, `done`, or `error`.
- `task.current() -> int`: current task handle, or `-1` outside a task.
- `task.list() -> list` and `task.info() -> map`: inspect scheduler state.
- `task.sleep(ms)`, `task.wait(event, timeout_ms=nil)`, `task.signal(event)`, and `task.clear(event)`: timing and event helpers.
- `task.millis()`, `task.woke_by_timeout()`, and `task.woke_by_event(event=nil)`: timing/status helpers for task code.

Return helpers:

- `task.again`: run again on a later scheduler turn.
- `task.done` or `nil`/`false`: finish the task.
- `task.pause`: pause the current task.
- `task.sleep(ms)`: wake after a hardware-counter delay.
- `task.wait(event, timeout_ms=nil)`: wake on an event or timeout.

Object helpers include `task.Semaphore(count=1)`, `task.Mutex()`,
`task.Queue(depth=8)`, `task.EventFlags(initial=0)`, and
`task.Timer(period_ms, repeat=true)`.

Example:

```berry
import p2
import task

def blink(pin, ms)
    p2.toggle(pin)
    return task.sleep(ms)
end

h38 = task.start(blink, 38, 250)
h39 = task.start(blink, 39, 700)

task.run()
```

## `p2.cog`

`p2.cog` is the native cog-handle namespace. It is separate from `task`: `task`
is cooperative scheduling inside the current Berry VM, while `p2.cog` launches
supported native work on another cog and returns a handle that can be inspected
or stopped.

Current helpers:

- `p2.cog.blinker(pin, ms)`: create a native blinker task descriptor.
- `p2.cog.spawn(function, ...args)`: pass a Berry function entity as the setup function; `spawn()` calls it on the current cog and launches the returned supported descriptor.
- `p2.cog.spawn(task_descriptor)`: launch an explicit descriptor directly.
- `p2.cog.stop(handle)`: stop a spawned native task.
- `p2.cog.info(handle)` / `p2.cog.info()`: inspect one handle or all active handles.
- `p2.cog.capabilities()`: report supported native task-handle features.

Example for the P2 Edge 32 MB board LEDs on pins `38` and `39`:

```berry
import p2

def blinker(pin, ms)
    return p2.cog.blinker(pin, ms)
end

h38 = p2.cog.spawn(blinker, 38, 250)
h39 = p2.cog.spawn(blinker, 39, 700)

p2.cog.stop(h38)
p2.cog.stop(h39)
```

Arbitrary Berry bytecode closure execution inside another isolated cog VM
remains future work. The current blinker path runs the actual toggle loop in a
native/PASM backend after the Berry setup function returns its descriptor.

## Retired `rtos` and `taskspin` APIs

The older `rtos` native module and Spin2-shaped `taskspin.be` source module are
retired from the active P2 API. New cooperative code should use `task`; native
cog handle experiments should use `p2.cog`.

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
- `libstore.status() -> map`: reports lazy SD loading, available library count,
  current heap role, PSRAM block/cache window, used/free cache bytes, and cached
  item count.
- `libstore.strategy() -> map`: reports the storage model: SD is the canonical
  library home, PSRAM is a transfer/cache backend when available, and the
  object heap is Hub or external depending on the active P2 profile.
- `libstore.module_name(entry) -> string or nil`: normalize an SD directory
  entry such as `MATH.BE` into the import name `math`, or return `nil` for
  non-source files.
- `libstore.scan() -> list`: discover available `.be` source modules under
  `libstore.paths`, preserving known module order and then adding SD entries.
- `libstore.modules() -> list`: return the currently available SD module names.
- `libstore.psram() -> map`: returns `p2.psram_info()`.
- `libstore.exists(name) -> bool`: true when `/modules/<name>.be` exists.
- `libstore.source_path(name) -> string or nil`: returns the SD source path.
- `libstore.compiled_path(name) -> string or nil`: returns a staged `.bec`
  candidate path if present. The current P2 port detects `.bec` files but does
  not execute them yet.
- `libstore.compiled_manifest_path(name) -> string or nil`: returns a staged
  `<module>.bec.json` freshness sidecar when present.
- `libstore.compile_cache_plan_many(names) -> map`: returns bulk `.bec` emit
  plans for an explicit module list, including emit blocker-reason counts.
- `libstore.compile_cache_plan_many_text(names) -> string`: returns bulk `.bec`
  emit plans for an explicit module list as JSON text.
- `libstore.compile_cache_plan_all() -> map`: returns bulk `.bec` emit plans for
  all discovered SD modules.
- `libstore.compile_cache_plan_all_text() -> string`: returns bulk `.bec` emit
  plans for all discovered SD modules as JSON text.
- `libstore.compile_cache_provision_plan(names) -> map`: returns a dry-run
  `.bec` emit provisioning plan for an explicit module list.
- `libstore.compile_cache_provision_plan_text(names) -> string`: returns the
  dry-run emit provisioning plan as JSON text.
- `libstore.compile_cache_provision_plan_all() -> map`: returns a dry-run
  `.bec` emit provisioning plan for all discovered SD modules.
- `libstore.compile_cache_provision_plan_all_text() -> string`: returns the
  all-module dry-run emit provisioning plan as JSON text.
- `libstore.compile_cache_emittable(names) -> list`: returns dry-run emit plans
  that can currently emit for an explicit module list.
- `libstore.compile_cache_emittable_text(names) -> string`: returns dry-run
  emittable plans as JSON text.
- `libstore.compile_cache_blocked(names) -> list`: returns dry-run emit plans
  currently blocked from emission for an explicit module list.
- `libstore.compile_cache_blocked_text(names) -> string`: returns dry-run
  blocked emit plans as JSON text.
- `libstore.compile_cache_emittable_all() -> list`: returns all discovered
  modules that can currently emit `.bec` cache output.
- `libstore.compile_cache_emittable_all_text() -> string`: returns all-module
  dry-run emittable plans as JSON text.
- `libstore.compile_cache_blocked_all() -> list`: returns all discovered
  modules currently blocked from `.bec` cache emission.
- `libstore.compile_cache_blocked_all_text() -> string`: returns all-module
  dry-run blocked emit plans as JSON text.
- `libstore.compile_cache_emit_many(names) -> map`: explicitly attempts `.be`
  to `.bec` emission for a module list and reports per-module success/failure.
- `libstore.compile_cache_emit_all() -> map`: explicitly attempts `.be` to
  `.bec` emission for all discovered SD modules.
- `libstore.compiled_validation(name) -> map`: reports whether a staged `.bec`
  candidate has comparable/fresh sidecar metadata and whether the current build
  has validator/execution support. Default builds report validator support as
  unavailable; opt-in builds must set both `BE_P2_ENABLE_BYTECODE_LOADER` and
  `BE_P2_ENABLE_BYTECODE_EXECUTION` before fresh metadata can be treated as
  executable bytecode.
- `libstore.compiled_load_plan(name) -> map`: reports whether a staged `.bec`
  can be loaded and, when it cannot, the exact blocked reason.
- `libstore.compiled_status(name) -> map`: returns one consolidated diagnostics
  bundle for staged `.bec` freshness, validation, load, and emit state.
- `libstore.compiled_status_text(name) -> string`: returns the consolidated
  diagnostics bundle as JSON text for tooling and smoke scripts.
- `libstore.compiled_inventory() -> list`: returns consolidated `.bec`
  diagnostics for all discovered SD modules.
- `libstore.compiled_inventory_text() -> string`: returns the compiled
  inventory as JSON text.
- `libstore.compiled_summary() -> map`: returns aggregate readiness counts for
  staged `.bec` source, manifests, loadability, emit support, and load/emit
  blocker reasons.
- `libstore.compiled_summary_text() -> string`: returns the compiled summary as
  JSON text.
- `libstore.compiled_loadable() -> list`: returns compiled-status records that
  can currently load.
- `libstore.compiled_loadable_text() -> string`: returns loadable candidate
  records as JSON text.
- `libstore.compiled_emittable() -> list`: returns compiled-status records that
  can currently emit `.bec` cache output.
- `libstore.compiled_emittable_text() -> string`: returns emittable candidate
  records as JSON text.
- `libstore.compiled_blocked() -> list`: returns compiled-status records blocked
  from load or emit.
- `libstore.compiled_blocked_text() -> string`: returns blocked candidate
  records as JSON text.
- `libstore.compiled_provision_plan() -> map`: returns one conservative
  provisioning diagnostics map with summary, candidate lists, blocked records,
  and a recommendation.
- `libstore.compiled_provision_plan_text() -> string`: returns the provisioning
  diagnostics map as JSON text.
- `libstore.load_compiled(name)`: future explicit `.bec` execution hook. Current
  default builds raise `unsupported_error` with the load-plan reason instead of
  silently pretending bytecode execution is available.
- `libstore.compiled_freshness(name) -> map`: compares staged source,
  bytecode, and optional sidecar metadata. Matching sidecars can prove
  `fresh == true`, but default `.bec` execution remains disabled until an
  opt-in `BE_P2_ENABLE_BYTECODE_LOADER` build plus
  `BE_P2_ENABLE_BYTECODE_EXECUTION` policy reports support.
- `libstore.resolve(name) -> map`: returns source/compiled candidates plus the
  selected path, selected kind, and decision reason. Current `.bec` candidates
  report source fallback when matching `.be` source is present.
- `libstore.info(name) -> map`: return SD path/cache metadata for one module,
  including `compiled_path`, `compiled_exists`, `compiled_supported`,
  `compiled_loader_supported`, `compiled_validator_supported`,
  `compiled_loader_reason`, and
  `selected_path`, `selected_kind`, `resolve_reason`, and `source_fallback`.
- `libstore.cached(name) -> bool`: true when the module source is already in
  the current PSRAM cache directory.
- `libstore.cache_window() -> map`: compute the safe PSRAM cache window from
  `p2.psram_info()`. On XMM profiles this avoids the Catalina-owned lower PSRAM
  region and allocates from the reported block window.
- `libstore.cache_source(name) -> map or nil`: copy one module's source text
  from SD into the safe PSRAM cache area when PSRAM is available. Sources are
  stored as PSRAM chunks, so the module can be larger than one Catalina transfer
  even though each individual read/write remains bounded by
  `p2.psram_info()["max_transfer"]`.
- `libstore.cached_source(name) -> string or nil`: read cached source text back
  from PSRAM into a temporary Hub string.
- `libstore.cache_reset()`: clear the in-memory cache directory and reset the
  PSRAM allocation pointer from the current safe cache window.
- `libstore.run_cached(name)`: compile and call a cached source module. This is
  mainly a diagnostic path; normal `import` still loads lazily from SD.
- `libstore.load(name)`: load by module name, using the PSRAM source cache when
  available and falling back to `run_file()` from SD otherwise.
- `libstore.cache_many(name, ...)`: cache a selected set of modules.
- `libstore.cache_all()`: cache all currently available modules under
  `libstore.paths`.
- `libstore.cache_report() -> map`: return current cache status and per-module
  chunk/address metadata.
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

`math` is a native P2 firmware module. It no longer requires
an SD-card `math.be` file. The P2 implementation exposes the full Berry
math surface and uses P2 CORDIC-backed helpers where appropriate.

Common checks:

```berry
import math
print(math.pi)
print(math.sqrt(81))
print(math.sin(math.pi / 2))
print(math.max(5, 2, 9))
```
