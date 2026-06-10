<p align="center">
  <h1 align="center">Berry for the Propeller 2</h1>
  <p align="center">A Propeller 2-first Berry environment for pins, cogs, SD cards, PSRAM, hardware modules, and live scripting from a friendly REPL.</p>
</p>

## What is this?

This repo is focused on making Berry feel native on the Propeller 2. The center
of gravity is the P2 board: serial REPL, GPIO, counters, cogs, SD files, native
modules, PSRAM/XMM profiles, and a growing set of hardware helpers.

The goal is simple: power up a Propeller 2, get a `berry>` prompt, and make the
chip do interesting things without rebuilding firmware for every experiment.

## Current P2 State, In Plain English

Berry on P2 is already useful for bring-up, experiments, and small embedded
programs.

You can:

- use an interactive serial REPL with history and basic line editing
- run core Berry language features: functions, closures, classes, maps, lists,
  ranges, loops, strings, numbers, exceptions, and modules
- import native firmware modules such as `p2`, `task`, `string`, full `math`,
  `json`, `bytes`, `os`, `i2c`, and `spi`
- toggle pins, read counters, wait on hardware time, inspect cogs, query heap,
  and print a useful `p2.status()` report
- read and write files on SD with `open()` and `os`
- lazily import optional `.be` libraries from `/modules` on SD
- use P2 CORDIC-backed math helpers where appropriate through native `math`
- run cooperative same-VM tasks with the native `task` scheduler
- launch supported native cog-backed work through `p2.cog` handles, including
  stoppable LED blinkers
- use P2 Edge 32 MB PSRAM either as block-transfer storage or, in the XMM
  profile, as Catalina external heap storage
- boot the XMM flash image with visible startup progress: an `Initializing PSRAM`
  spinner, a Berry VM startup spinner, and a current hardware capture around
  3 seconds from attach to `berry>`

The current concurrency split is intentional:

- use `task` for cooperative work inside the current Berry VM
- use `p2.cog` for supported native cog-backed handles
- arbitrary Berry bytecode closures in isolated cogs are still future work

## Five-Minute Hardware Taste

At the REPL:

```berry
import p2

print("hello from cog", p2.cogid())
print("clock", p2.clock_freq())
p2.status()
```

Blink a no-PSRAM P2 Edge LED on pin `56`:

```berry
import p2

p2.pinmode(56, p2.OUTPUT)
for i: 0..5
    p2.toggle(56)
    p2.waitms(150)
end
```

Blink the two P2 Edge 32 MB LEDs on pins `38` and `39` using cooperative tasks:

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

task.stop(h38)
task.stop(h39)
```

Launch supported native blinker work on other cogs and keep handles you can stop
later:

```berry
import p2

def blinker(pin, ms)
    return p2.cog.blinker(pin, ms)
end

h38 = p2.cog.spawn(blinker, 38, 250)
h39 = p2.cog.spawn(blinker, 39, 700)

print(p2.cog.info(h38))
print(p2.cog.info(h39))

p2.cog.stop(h38)
p2.cog.stop(h39)
```

`p2.cog.spawn(blinker, 38, 250)` passes the function entity. Do not write
`blinker(38, 250)` unless you mean to call the function immediately on the REPL
cog.

## Quick Start

Build Berry for Propeller 2 with Catalina:

```sh
make p2 TOOLCHAIN=catalina
make p2-minimal
make p2-full
make p2-run TOOLCHAIN=catalina PORT=COM5
```

Catalina is the preferred and verified P2 toolchain. FlexC targets remain in the
tree for historical/debugging work, but normal P2 validation should use Catalina.

P2 Edge flash install with Catalina:

```sh
make configure TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp P2_SILICON=latest CATALINA_PLATFORM=P2_EDGE CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=
make p2-flash
tio -b 230400 /dev/cu.usbserial-P97cvdxp
```

For the verified P2 Edge Rev D path, use boot switches
`FLASH=ON, triangle=OFF, inverted-triangle=OFF`. Catalina flash uses a generated
`flshload.t` programmer image; do not flash `build/p2/catalina/full/berry_p2.binary`
directly with `loadp2 -SPI`.

The default Catalina P2 Edge profile targets the no-PSRAM board, where pins `56`
and `57` are LEDs. Do not add `-lpsram` for that board; Catalina's PSRAM profile
uses pin `57` as chip-select. Keep `CATALINA_MODEL=COMPACT` for `make p2-ram`;
`NATIVE` builds are too large for the Hub RAM load path.

## Build Profiles

P2 build profiles are selected with `P2_PROFILE` or with convenience targets:

- `make p2-minimal` builds the smallest practical REPL profile: core language,
  standard classes, and `string`, with filesystem, JSON, math, OS, P2 hardware
  modules, and `prop2_*` globals disabled.
- `make p2-full` builds the current no-PSRAM P2 Edge profile with the active
  modules enabled.
- `make p2-edge32` builds the P2 Edge 32 MB RAM profile with Catalina `-lpsram`.
  This enables PSRAM block-transfer support and reserves pins `40..57`; Berry's
  object heap remains in Hub RAM because COMPACT PSRAM is not ordinary C
  pointer-addressable storage.
- `make p2-xmm` builds the Catalina `LARGE`/XMM profile for the P2 Edge 32 MB
  RAM board. It uses the lower `16 MiB` PSRAM window for Catalina XMM/external
  heap storage and leaves the upper `16 MiB` as an explicit block/cache window.
- `make p2-xmm-flash` creates a sparse standalone flash image with visible PSRAM
  initialization. The current hardware-verified boot reaches `berry>` in about
  3 seconds after attach.

XMM flash startup skips the optional `/berry/main.be` auto-run probe by default
so REPL boot does not block on SD lookup. Builds that need startup scripts can
opt back in with `BE_P2_RUN_SD_MAIN=1`.

P2 app images are checked against the 512 KiB Hub RAM limit. Oversized builds
fail before `berry_p2.binary` is published.

Windows PowerShell example:

```powershell
make p2 TOOLCHAIN=catalina CATALINA_DIR=C:\tools\catalina
make p2-run TOOLCHAIN=catalina PORT=COM6 LOADP2=C:\tools\flexprop\bin\loadp2.exe
```

## Release Binaries

Catalina releases for the Propeller 2 ship two normal binaries:

- `berry_p2.binary`: the normal Berry application image for RAM loading with
  `make p2-run` or `make p2-ram`
- `berry_p2_flash_loader.binary`: a Catalina flash-programmer wrapper generated
  from `berry_p2.binary` for `make p2-flash` and `make p2-flash-run`

Important Catalina flash note:

- `berry_p2.binary` is the Berry app image
- `berry_p2_flash_loader.binary` is the temporary flash-programmer wrapper
- do not flash `berry_p2.binary` directly with `loadp2 -SPI` on the Catalina path

RAM load:

```sh
make p2 TOOLCHAIN=catalina
make p2-run TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp
```

Flash install:

```sh
make p2 TOOLCHAIN=catalina
make p2-flash TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp
tio -b 230400 /dev/cu.usbserial-P97cvdxp
```

## Berry in 20 Minutes, Propeller Style

This section is inspired by the official Berry "in 20 minutes" tutorial, but the
examples live on a Propeller bench instead of greeting random people. Try these
at the REPL or paste them as small `.be` files.

### Hello, Board

```berry
print("Hello, Propeller 2")
print("Berry is running on cog", 0)
```

Berry compiles each command to bytecode and runs it in the VM. You do not need
semicolons; whitespace is enough to separate statements.

### Calculator at the Workbench

```berry
print(180_000_000 / 1_000_000)  # MHz when the board is at 180 MHz
print(3 / 2)                    # integer division
print(3.0 / 2)                  # floating point division

import math
print(math.sqrt(81))
print(math.sin(math.pi / 2))
```

On P2, `math` is native firmware and uses CORDIC-backed helpers where it makes
sense.

### Functions and Function Entities

Functions are small reusable pieces of behavior. They can return values, accept
arguments, and be passed around as values.

```berry
def clamp(value, low, high)
    if value < low return low end
    if value > high return high end
    return value
end

print(clamp(120, 0, 63))
```

A hardware-flavored function can wrap a repeated pin action:

```berry
def pulse(pin, ms)
    import p2
    p2.high(pin)
    p2.waitms(ms)
    p2.low(pin)
end

pulse(56, 100)
print(pulse)       # the function entity itself
```

Calling a function uses parentheses. Passing a function to another API, such as
`task.start()` or `p2.cog.spawn()`, uses the function entity without calling it
first.

```berry
import task
h = task.start(pulse, 56, 50)
task.run(1)
task.stop(h)
```

### Nil Means No Signal

`nil` is Berry's "nothing here" value. It is useful for optional reads and
missing map entries.

```berry
last_packet = nil
if last_packet == nil
    print("radio quiet")
end

def maybe_pin_name(pin)
    if pin == 56 return "LED1" end
    if pin == 57 return "LED2" end
    return nil
end

print(maybe_pin_name(56))
print(maybe_pin_name(12))
```

### Strings and Formatting

```berry
import string
import p2

pin = 56
state = p2.pin_read(pin)
print(string.format("pin %d reads %d", pin, state))
print(string.toupper("propeller"))
```

Strings are ordinary Berry values, so you can store them in maps, lists, files,
or task arguments.

### Lists: Pin Banks and Scan Results

Lists keep ordered values. They are perfect for batches of pins, device
addresses, filenames, and test steps.

```berry
leds = [38, 39]
leds.push(56)

print("first LED", leds[0])
print("number of LEDs", leds.size())

for pin: leds
    print("configured pin", pin)
end
```

Lists can hold mixed Berry values too:

```berry
bringup = ["mount sd", "scan i2c", "blink led", 42, true]
for step: bringup
    print("step", step)
end
```

### Maps: Board Configuration and Key/Value Data

Maps store key/value pairs. They are useful for board profiles, sensor readings,
lookup tables, and runtime configuration.

```berry
board = {
    "name": "P2 Edge 32MB",
    "leds": [38, 39],
    "sd": [58, 59, 60, 61],
    "serial": [62, 63],
    "has_psram": true
}

print(board["name"])
print(board["leds"][0])
print(board.find("wifi", "not fitted"))
```

You can update values, add keys, check whether a key exists, and loop through
keys.

```berry
reading = {"sensor": "bmp180", "addr": 0x77, "ok": true}
reading["temp_c"] = 23.5
reading["samples"] = reading.find("samples", 0) + 1

if reading.contains("temp_c")
    print("temperature", reading["temp_c"])
end

for key: reading.keys()
    print(key, reading[key])
end
```

### If, For Loops, While Loops, and Ranges

```berry
import p2

pin = 56
p2.pinmode(pin, p2.OUTPUT)

for i: 0..9
    if i % 2 == 0
        p2.high(pin)
    else
        p2.low(pin)
    end
    p2.waitms(50)
end
```

Ranges such as `0..9` are compact and convenient for quick hardware sweeps.
Use `while` when the loop depends on changing state.

```berry
count = 0
while count < 4
    print("tick", count)
    count += 1
end
```

### Classes: Tiny Hardware Objects

Classes let you bundle state and behavior. This LED object remembers which pin
it owns.

```berry
class Led
    var pin

    def init(pin)
        import p2
        self.pin = pin
        p2.pinmode(pin, p2.OUTPUT)
    end

    def on()
        import p2
        p2.high(self.pin)
    end

    def off()
        import p2
        p2.low(self.pin)
    end

    def blink(ms)
        import p2
        self.on()
        p2.waitms(ms)
        self.off()
    end
end

led = Led(56)
led.blink(100)
```

`init()` is the constructor. Instance fields are declared with `var` and are
accessed through `self` inside methods.

Classes do not have to touch hardware directly. They can also organize data:

```berry
class SensorReading
    var name
    var values

    def init(name)
        self.name = name
        self.values = []
    end

    def add(value)
        self.values.push(value)
    end

    def latest()
        if self.values.size() == 0 return nil end
        return self.values[self.values.size() - 1]
    end
end

r = SensorReading("temperature")
r.add(22.8)
r.add(23.1)
print(r.name, r.latest())
```

### Subclasses: Active-Low LEDs

Some boards wire LEDs active-low. A subclass can flip the behavior without
rewriting the whole object.

```berry
class ActiveLowLed : Led
    def on()
        import p2
        p2.low(self.pin)
    end

    def off()
        import p2
        p2.high(self.pin)
    end
end

led = ActiveLowLed(56)
led.blink(100)
```

### Closures: Remembering a Pin

Closures let a function remember values from the scope where it was created.

```berry
def make_toggler(pin)
    import p2
    p2.pinmode(pin, p2.OUTPUT)

    def toggle_once()
        p2.toggle(pin)
    end

    return toggle_once
end

toggle_led = make_toggler(56)
toggle_led()
toggle_led()
```

This is great inside one VM. For other cogs, use the current `p2.cog` supported
native-handle shapes rather than assuming arbitrary captured Berry state can be
shared across cogs.

### Variable Arguments

```berry
def log(prefix, *items)
    for item: items
        print(prefix, item)
    end
end

log("sensor", "bmp180", 0x77, "ok")
```

Varargs are useful for REPL helpers and diagnostics where the number of values
changes as you debug.

### Modules: Native and SD-Loaded

```berry
import p2
import math
import string
import os

print(math.sqrt(144))
print(string.split("sck,mosi,miso,cs", ","))
print(os.listdir("/"))
```

Core P2-facing modules are native in firmware. Optional source libraries can
live on SD under `/modules` and be imported lazily.

### Files on SD

```berry
import os

f = open("/LOG.TXT", "w")
f.write("boot ok\n")
f.close()

print(open("/LOG.TXT", "r").read())
print(os.listdir("/"))
```

The P2 runtime includes SD-backed `open()` and common `os` helpers for practical
on-board scripts.

### Cooperative Tasks

Tasks run one step at a time and return a scheduler instruction.

```berry
import p2
import task

def heartbeat(pin, ms)
    p2.toggle(pin)
    return task.sleep(ms)
end

h = task.start(heartbeat, 56, 250)
task.run(20)
task.stop(h)
```

Useful helpers include `task.start()`, `task.next()`, `task.run()`,
`task.sleep()`, `task.wait()`, `task.signal()`, `task.stop()`, `task.pause()`,
`task.resume()`, `task.status()`, `task.list()`, and `task.info()`.

### Events and Timers

```berry
import task

def waiter()
    if task.woke_by_timeout()
        print("button timeout")
        return task.done
    end

    if task.woke_by_event("button")
        print("button event")
        return task.done
    end

    return task.wait("button", 3000)
end

h = task.start(waiter)
task.run(5)
task.signal("button")
task.run(5)
```

On P2, task sleep uses the hardware counter. The special event name
`"attention"` maps to P2 cog attention.

### I2C: Ask a Sensor Who It Is

```berry
import i2c

i2c.init(25, 24, 400)
print(i2c.scan())
print(i2c.writeread(0x77, "\xD0", 1))
```

The BMP180 smoke setup returns address `0x77` and chip ID `0x55`, shown as `U`.

### SPI: Nudge a Device

```berry
import spi

spi.init(10, 11, 12, 13, 0, 1000)
spi.select()
id = spi.transfer("\x9F\x00\x00\x00")
spi.deselect()
print(id)
```

The SPI module keeps explicit chip-select control so flash, EEPROM, ADC, and
sensor bring-up scripts stay readable.

### Bytes: Packets and Registers

```berry
packet = bytes().fromstring("P2")
print(packet.tohex())

rx = bytes("010203")
print(rx)
```

`bytes` is useful for bus traffic, packet dumps, binary files, and small protocol
helpers.

### Errors Are Part of Bring-Up

```berry
def require_pin(pin)
    if pin < 0 || pin > 63
        raise "bad pin"
    end
    return pin
end

print(require_pin(38))
```

During hardware work, clear failures beat silent weirdness. The P2 modules try
to return diagnostics or raise errors instead of hanging where practical.

## P2 Feature Reference

### `p2` Hardware Module

`p2` is the friendly hardware namespace for day-to-day P2 work: GPIO,
low-level counter/timing helpers, cog ID/state inspection, heap reporting,
smartpin helpers, CORDIC helpers, lock helpers, attention, filesystem
diagnostics, and status reporting.

```berry
import p2

print(p2.clock_freq())
print(p2.ticks())
print(p2.cogid())
print(p2.sbrk())
p2.status()
```

### `task` Cooperative Scheduler

`task` is native-backed and cooperative. It does not provide preemptive
multitasking or independent Berry call stacks. It is designed for easy, explicit
state-machine style work inside one VM.

```berry
import task
print(task.info())
```

### `p2.cog` Native Handles

`p2.cog` exposes supported native cog-backed work with integer handles that can
be inspected and stopped.

```berry
import p2
print(p2.cog.capabilities())
```

The current blinker path runs the actual toggle loop in native/PASM code after a
Berry setup function returns its descriptor.

### Native `i2c` Module

```berry
import i2c

i2c.init(25, 24, 400)
print(i2c.scan())
```

Supported API:

- `i2c.init(scl_pin, sda_pin, khz, pullup=false)`
- `i2c.write(addr, data)`
- `i2c.read(addr, count)`
- `i2c.writeread(addr, txdata, rxcount)`
- `i2c.present(addr)`
- `i2c.wait(addr, timeout_ms=1000)`
- `i2c.start()` / `i2c.stop()`
- `i2c.scan()`

### Native `spi` Module

```berry
import spi

spi.init(10, 11, 12, 13, 0, 1000)
print(spi.read(1))
```

Supported API:

- `spi.init(clk_pin, mosi_pin, miso_pin, cs_pin, mode, khz)`
- `spi.select()`
- `spi.deselect()`
- `spi.write(data)`
- `spi.read(count, filler=0xFF)`
- `spi.transfer(data)`
- `spi.stop()`

### WiFiNINA / AirLift Skeleton

`modules/wifi.be` is the first Berry-side WiFiNINA/AirLift transport layer for
ESP32 coprocessors flashed with Adafruit firmware. It handles configured P2
pins, reset pulse, SPI framing, firmware-version request, and connection-status
request. It is still bring-up work; READY/BUSY hardware detection needs more
validation before higher-level network APIs are promised.

```berry
import wifi

wifi.init({
    "sck": 16, "mosi": 17, "miso": 18, "cs": 19,
    "busy": 20, "reset": 21, "irq": 22
})

print(wifi.firmware_version())
print(wifi.status())
```

### `spin2` Loader Prototype

`spin2` is the first path for running Spin2/PASM binaries from Berry. Binaries
live on the SD card under `/spin2` by default. Berry-callable binaries use the
documented integer mailbox convention. Raw standalone PASM images can be started
with `PTRA == nil`; high-level FlexSpin images are detected and rejected because
their `.BIN` payloads contain absolute Hub addresses and are not relocatable
from Berry's heap loader.

```berry
import spin2

print(spin2.list())
handle = spin2.start("MBOXDEMO.BIN")
print(spin2.info(handle))
print(spin2.call(handle, 1, 123))
spin2.stop(handle)
```

Build bundled Spin2 examples with:

```sh
make spin2
```

Copy the demo to SD with an 8.3 filename, for example `/spin2/MBOXDEMO.BIN`.

## SD, PSRAM, and XMM Notes

The P2 runtime adds `/modules` to the default lazy import path. Optional source
libraries such as `binary_heap.be`, `wifi.be`, `p2mem.be`, and `libstore.be` can
be imported from SD without baking every helper into the firmware image.

The `task`, `math`, and `string` modules are native in firmware, so they do not
need SD files.

On P2 Edge 32 MB:

- COMPACT + `-lpsram` exposes PSRAM as block-transfer storage through helpers
  such as `p2.psram_info()` and `p2.psram_test()`
- XMM/LARGE uses the lower `16 MiB` PSRAM window for Catalina external heap
  storage and leaves the upper `16 MiB` for explicit block/cache use

Verify PSRAM support from the REPL:

```berry
import p2
print(p2.psram_info())
print(p2.psram_test())
```

## Repeatable Smoke Tests

Repeatable SD smoke tests live under `tests/p2/`. Copy that directory and
`modules/` to the SD card root, start Berry, then run:

```sh
make p2-smoke PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke-edge32 PORT=/dev/cu.usbserial-P97cvdxp
```

The edge32 target includes the general smoke suite plus PSRAM block-access
assertions.

## Documentation Map

The active Propeller 2 docs are split by purpose:

- [`docs/getting-started.md`](./docs/getting-started.md): first build, flash,
  and smoke path
- [`docs/building.md`](./docs/building.md): Catalina profiles, board/profile
  flags, and P2 trace/debug/unsafe-ASM flag policy
- [`docs/board-support.md`](./docs/board-support.md): supported board profiles
  and reserved pins
- [`docs/sd-layout.md`](./docs/sd-layout.md): current `/modules` layout and
  target `/berry/...` layout
- [`docs/psram-loader.md`](./docs/psram-loader.md): Hub/PSRAM/XMM cache model
- [`docs/berry-compatibility.md`](./docs/berry-compatibility.md): Berry
  compatibility coverage and bare-metal host-like limitations
- [`docs/p2-api.md`](./docs/p2-api.md): current `p2` API snapshot
- [`docs/smartpins.md`](./docs/smartpins.md): raw smart-pin API and remaining
  mode-family roadmap
- [`docs/cogs.md`](./docs/cogs.md): current cog model and closure-transfer
  policy
- [`docs/tasks.md`](./docs/tasks.md): cooperative `task` module
- [`docs/pasm.md`](./docs/pasm.md): safe `p2.asm` facade and future PASM ABI
  rules
- [`docs/debugging.md`](./docs/debugging.md): query-based diagnostics and debug
  flag policy
- [`docs/performance.md`](./docs/performance.md): benchmark plan and reporting
  format
- [`docs/hardware-tests.md`](./docs/hardware-tests.md): pins, wiring, resistors,
  board variants, skips, and runnable hardware-test entrypoints
- [`docs/limitations.md`](./docs/limitations.md): explicit unsupported/open
  areas
- [`docs/P2_MODULES.md`](./docs/P2_MODULES.md): fuller P2 module API reference
- [`docs/P2_SYSTEM_ROADMAP.md`](./docs/P2_SYSTEM_ROADMAP.md): longer-term P2
  system plan

## Repository Layout

The main P2 areas are:

- [`mk/`](./mk)
- [`port/p2/`](./port/p2)
- [`tools/p2/`](./tools/p2)
- [`docs/`](./docs)
- [`modules/`](./modules)
- [`tests/p2/`](./tests/p2)

The core VM lives under `src/`, while the Propeller 2 runtime, overrides,
probes, and status notes live under `port/p2/`. P2 build logic lives under
`mk/`. Tool bootstrap and loader helpers live under `tools/p2/`. Downloaded
toolchains belong in `.third_party_cache/` or user-provided paths, not in git.

## Toolchain Model

Catalina is the preferred and verified compiler flow for Berry on P2:

```sh
make p2 TOOLCHAIN=catalina CATALINA_DIR=/opt/catalina
make p2 TOOLCHAIN=catalina P2_PROFILE=minimal CATALINA_DIR=/opt/catalina
make p2-run TOOLCHAIN=catalina LOADP2=/opt/flexprop/bin/loadp2 PORT=/dev/ttyUSB0
```

Local managed caches are supported and ignored by git:

- `.third_party_cache/catalina/`
- `.third_party_cache/flexprop/` for loader tools such as `loadp2`

The old `TOOLCHAIN=flexc` path remains in the tree for historical/debugging
work, but do not use it for normal Berry P2 builds.

## P2 Silicon Selection

The P2 build keeps explicit silicon selection:

- `P2_SILICON=latest` uses `-2`
- `P2_SILICON=b` uses `-2`
- `P2_SILICON=c` uses `-2`
- `P2_SILICON=a` uses `-2a`

Example:

```sh
make configure TOOLCHAIN=catalina P2_SILICON=latest
make p2
```

## Board Pin Reminders

On the tested no-PSRAM P2 Edge setup, keep Berry GPIO and bus examples off the
SD pins `58..61` and serial pins `62..63`. Pins `56` and `57` are available as
LEDs on that board.

On P2 Edge 32 MB, onboard LEDs are pins `38` and `39`; pins `40..57` are
reserved for the memory interface, including pin `57` as PSRAM chip-select.

## Berry References

Berry is an ultra-lightweight dynamically typed embedded scripting language
designed for constrained systems. The interpreter core is ANSI C99 and uses a
one-pass compiler plus a register-based VM.

Reference material:

- [Berry documentation](https://berry.readthedocs.io/)
- [Berry in 20 minutes](https://berry.readthedocs.io/en/latest/source/en/Berry-in-20-minutes.html)
- [Short manual PDF](https://github.com/berry-lang/berry_doc/blob/master/pdf/berry_short_manual.pdf)
- [`tools/grammar/berry.ebnf`](./tools/grammar/berry.ebnf)

## Notes

- The repo no longer vendors full P2 toolchain distributions.
- `build/` is output-only.
- Optional P2 workaround files that shadow upstream Berry sources live under
  `port/p2/patches/optional/` and are documented as maintenance exceptions, not
  normal source layout.
