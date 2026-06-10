# Propeller 2 Port Roadmap And Status

This document started as the implementation backlog for matching and then surpassing Catalina Lua's P2 hardware surface. As of `v0.9.4`, the first working versions of the main items are implemented and the Catalina no-PSRAM P2 Edge workflow has been hardened; the remaining notes are the next expansion work.

Current note: the older `rtos`, `worker`, `threads`, and `taskspin` direction has been retired from the active P2 API. New cooperative work should target native `task`; native cog-backed work should target `p2.cog`.

## Current Repo Map

- Core Berry runtime lives in `src/`.
- P2 build rules live in `mk/p2.mk` and Catalina toolchain settings live in `mk/toolchain-catalina.mk`.
- P2 port code lives under `port/p2/`.
- P2 native module overrides are currently added under `port/p2/overrides/`.
- P2 runtime helpers live under `port/p2/runtime/`.
- P2 public port headers live under `port/p2/include/`.
- P2 examples live under `examples/`.
- P2 documentation lives under `docs/` and `port/p2/docs/`.

## Native Module Registration Path

- Standard const native modules still flow through `port/p2/overrides/be_modtab_p2.c`.
- P2 hardware modules are cached during `be_loadlibs()` in `port/p2/overrides/be_libs_p2.c` because Catalina/P2 currently hangs when some const native function attributes are called directly.
- Existing P2 native modules and overrides should be used as templates:
 - `port/p2/overrides/be_prop2lib.c`
 - `port/p2/overrides/be_p2lib_p2.c`
 - `port/p2/overrides/be_i2clib_p2.c`
 - `port/p2/overrides/be_spilib_p2.c`
 - `port/p2/overrides/be_workerlib_p2.c`
 - `port/p2/overrides/be_threadslib_p2.c`
 - `port/p2/overrides/be_spin2lib_p2.c`
 - `port/p2/overrides/be_libs_p2.c`
- Native functions use the Berry C API style: `int fn(bvm *vm)`, extract args with `be_toint()` / `be_tostring()`-style helpers, push returns with `be_pushint()` / `be_pushstring()` / lists, then return via the repo's existing convention.

## v0.9.4 Implementation Summary

- `p2`: implemented GPIO, delays, cog helpers, locks, heap reporting, and `beep`.
- `p2.status()`: added image/heap bars, clock info, and all 8 cog states.
- REPL: added 3-command history, cursor editing, and cooperative Ctrl-C/Ctrl-D interrupts for the main Berry VM.
- `i2c`: implemented module-global init/write/read/writeread/scan/present/wait/start/stop.
- `spi`: implemented module-global init/select/deselect/write/read/transfer/stop.
- `task`: owns the public cooperative scheduler API. `p2.cog` owns supported native cog-backed handles. The older `rtos` API is retired.
- `spin2`: implemented SD binary listing, Hub-RAM load/start, integer mailbox call, stop, info, and `make spin2` tooling.
- Build/release: Catalina 8.8.9 native Catalina build path works, FlexC is documented as non-preferred for Berry P2 builds, RAM image size is guarded against the 512 KiB Hub RAM limit, no-PSRAM P2 Edge pins 56/57 are usable as LEDs, and flash-loader binary generation remains available.

## Current Maintenance Notes

- SD card support is live-verified again on hardware. The failure mode was not
 the card: the full P2 image was relying on Catalina libc `malloc` for file and
 directory handles while running close to the Hub RAM limit. The runtime now
 uses fixed pools for `open()` and `os.listdir()`.
- Directory listing filters raw DOSFS entries so stale, erased, hidden, volume,
 reserved, and non-printable 8.3 names do not leak into Berry lists.
- `i2c` and `spi` transfer helpers avoid Catalina libc heap allocation for their
 bounded read/transfer buffers.
- P2 module APIs are documented in [`P2_MODULES.md`](./P2_MODULES.md). Keep that
 reference updated whenever a P2-facing function or method changes.
- `modules/wifi.be` and `examples/wifi/detect.be` contain the first
 WiFiNINA/AirLift SPI transport skeleton. ESP32-C6 READY/BUSY detection is
 still the next hardware step before higher-level WiFi APIs are added.

## Reference Sources

- Catalina repo/tag to compare against: `rosshigson/Catalina` around commit `a6f714c5` / tag `v8.8.9`.
- Catalina Lua P2 hardware APIs: `lua_p2.c` and Lua companion scripts.
- Catalina I2C driver examples:
 - `demos/catalyst/time/i2c_driver.c`
 - `demos/catalyst/time/rtc_driver.c`
- Catalina SPI references:
 - `include/spi.h`
 - `demos/spi/dump_eeprom.c`
 - `demos/spi/README.TXT`

## Phase 0: Toolchain And Build Hygiene

- Keep Catalina `v8.8.9` support working with native Catalina.
- Preserve the fix that maps `-lcix` to `cix` when patching Catalina P2 libraries.
- Keep `bmapkey` bit-fields C-standard compatible for Cake 0.13.24.
- Add a documented command for building against a source-built Catalina cache:
 ```sh
 make p2 TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88
 ```
- Add a repeatable helper script for building Catalina `v8.8.9` binaries and P2 COMPACT libraries from source, if we decide this should become supported workflow.

## Phase 1: Digital I/O `p2` Module

Status: first working version implemented in `v0.9.3`.

Goal: make the P2 module comparable to Catalina Lua's `propeller` basics.

- `p2.high(pin)`: set pin output high.
- `p2.low(pin)`: set pin output low.
- `p2.toggle(pin)`: toggle pin state.
- `p2.read(pin)`: return current pin state as integer/bool.
- `p2.pinmode(pin, mode)`: configure input, output, or open-drain.
- `task.sleep(ms)`: cooperative millisecond task delay.
- `p2.delay_us(us)`: microsecond delay.
- `p2.cogid()`: return current cog ID.
- `p2.lock.*` / `task.Mutex`: expose low-level and cooperative locking helpers.
- `p2.sbrk()`: report available heap or closest meaningful heap-space estimate.
- `p2.status()`: print build image size, heap bars, clock info, and all 8 cog states.
- Ensure pins 56 and 57 are accessible on P2 Edge boards without PSRAM.
- Add examples:
 ```berry
 import p2
 while true
 p2.high(56)
 task.sleep(250)
 p2.low(56)
 task.sleep(250)
 end
 ```

## Phase 2: I2C Module

Status: first working version implemented and live-verified with BMP180 in `v0.9.3`.

Goal: practical bus support first, with `i2c.scan()` especially reliable.

- Keep module-global bus state after `i2c.init()`.
- `i2c.init(scl_pin, sda_pin, khz, pullup=false)`: configure pins, speed, and optional pull-up behavior.
- Support common speeds: 100, 400, and 1000 kHz where practical.
- `i2c.write(addr, data)`: write raw bytes to a 7-bit address.
- `i2c.read(addr, count)`: return raw bytes as a Berry string.
- `i2c.writeread(addr, txdata, rxcount)`: register-style transaction.
- `i2c.present(addr)`: return true if address ACKs.
- `i2c.wait(addr)`: wait until a device ACKs after internal write.
- `i2c.scan()`: scan `0x08..0x77` and return list of integer addresses.
- Optional low-level API if needed: `i2c.start()` / `i2c.stop()`.
- Validate pins, addresses, counts, init state, and transfer sizes.
- Test target: BMP180 on SDA pin 24 and SCL pin 25.
- Add example:
 ```berry
 import i2c
 i2c.init(25, 24, 400)
 print(i2c.scan())
 ```

## Phase 3: SPI Module

Status: first working version implemented in `v0.9.3`; import/init/read smoke-tested on hardware.

Goal: full-duplex byte transfer with simple module-global state.

- Keep module-global bus state after `spi.init()`.
- `spi.init(clk_pin, mosi_pin, miso_pin, cs_pin, mode, khz)`: configure pins, mode `0..3`, and speed.
- `spi.select()`: assert CS.
- `spi.deselect()`: deassert CS.
- `spi.write(data)`: transmit bytes.
- `spi.read(count, filler=0xFF)`: clock in bytes using filler.
- `spi.transfer(data)`: return exactly one received byte per transmitted byte.
- `spi.stop()`: release bus if meaningful.
- Validate pins, mode, speed, init state, transfer size, and byte values.
- Optionally add future helpers for EEPROM/flash/SD based on Catalina `spi.h`.
- Add example:
 ```berry
 import spi
 spi.init(10, 11, 12, 13, 0, 1000)
 spi.select()
 id = spi.transfer("\x9F\x00\x00\x00")
 spi.deselect()
 print(id)
 ```

## Phase 4: Cooperative Task And Cog Handles

Status: old worker/RTOS path retired; current active APIs are native `task` and
`p2.cog`.

Goal: keep concurrency simple, safe, and honest about the P2 hardware model.

- `task.start(fn, *args)`: start a cooperative same-VM task.
- `task.run(max_steps=nil, idle_ms=1)` / `task.next()`: run scheduler steps.
- `task.sleep(ms)`, `task.wait(event, timeout_ms=nil)`, and `task.signal(event)`: timing and event helpers.
- `task.Semaphore`, `task.Mutex`, `task.Queue`, `task.EventFlags`, and `task.Timer`: cooperative primitives.
- `p2.cog.spawn(fn, ...args)`: return a native handle for supported cog-backed work.
- `p2.cog.stop(handle)` / `p2.cog.info(handle)`: inspect and stop native cog handles.
- Do not claim arbitrary isolated Berry closure execution until VM, heap, GC,
  capture, error, and ownership semantics are proven safe.

## Phase 6: Spin2 Build Directory

Status: implemented in `v0.9.3` with `spin2/`, `spin2/README.md`, sample source, and `make spin2`.

Goal: add repo support for Spin2 source assets without coupling it too tightly to the Berry runtime.

- Add top-level `spin2/` directory for `.spin2` sources.
- Add `spin2/build/` output directory, likely ignored except sample metadata.
- Add a helper script or Make target to compile:
 ```sh
 flexspin -2 -o spin2/build/Name.bin spin2/Name.spin2
 ```
- Decide whether sample Spin2 binaries are checked in or generated only.
- Add a sample Spin2 object using the Berry-compatible mailbox/call-table convention.
- Document expected SD-card deployment path, e.g. `/sd/spin2/` or `/SPIN2/`.

## Phase 7: `spin2` Native Module

Status: loader prototype implemented in `v0.9.3`; compatible mailbox binaries are required.

Goal: dynamic loading of compiled Spin2/P2 binaries from SD and launching them in cogs.

- Create the module under the P2-native location, probably `port/p2/overrides/be_spin2lib_p2.c`, unless a better repo convention emerges.
- Cache `spin2` from `port/p2/overrides/be_libs_p2.c`.
- `spin2.list(path="/spin2")`: return `.bin`, `.binary`, and `.p2` files.
- `spin2.start(file, par=0)`: load binary from SD into Hub RAM and launch with `COGINIT`.
- Return a handle that tracks cog ID, Hub code base, binary size, mailbox, method table, and ownership.
- `spin2.call(handle, method_id, ...int_args)`: integer-only v1 call through a Hub mailbox.
- `spin2.stop(handle)`: `COGSTOP` and free owned Hub resources.
- Validate file existence, binary size, method count, method index, argument count, and cog availability.
- Raise Berry errors for invalid handles and resource exhaustion.

## Phase 8: Spin2 Calling Convention

Status: v1 convention documented and implemented by the native module and sample source.

Goal: define a simple ABI we can implement and document.

- Binary header v1:
 - Long 0: method count.
 - Next longs: method entry offsets or Hub-relative addresses.
 - Optional later fields: ABI version, mailbox offset, method metadata offset.
- Mailbox v1:
 - State.
 - Method ID.
 - Argument count.
 - Integer arguments.
 - Integer result.
 - Error/status code.
- Synchronization:
 - Start with lock or volatile state polling.
 - Add `COGATN` if it proves reliable and worth the complexity.
- `spin2.call()` v1 limitations:
 - Integer args only.
 - Single integer return.
 - Blocking call by default.
 - Optional fire-and-forget for methods that never return.
- Future TODOs:
 - `spin2.list_methods(handle)`.
 - Parse method names and arity from a manifest.
 - Support strings/lists through shared buffers.
 - Async calls and timeouts.
 - Idiomatic wrappers for common objects like SmartSerial.

## Phase 9: Smart Pin And Optional P2 Features

Status: low-level helper coverage is now integrated into `p2.*`, including smart-pin, counter, CORDIC, lock, attention, and raw cog helpers. Legacy `prop2_*` globals remain available for compatibility.

- Friendly PWM examples on top of the smart-pin helpers.
- Friendly ADC/DAC examples on top of the smart-pin helpers.
- Frequency measurement.
- Additional counter/timestamp examples.
- `p2.beep(pin, freq, ms)` tuning once pin ownership is settled.
- Keep these behind small, focused APIs rather than a giant hardware abstraction layer.

## Phase 10: Examples And Mini Tutorials

Status: examples added for the implemented v1 APIs and organized by module.

- `examples/core/`: general Berry examples such as quicksort, REPL, and string handling.
- `examples/p2/blink.be`: LED blink on pins 56/57.
- `examples/p2/hardware_helpers.be`: clocks, counters, CORDIC, locks, attention, and cog status through `p2`.
- `examples/p2/pin_helpers.be`: raw pin helpers through `p2`.
- `examples/p2/smartpin_helpers.be`: smart-pin helper calls through `p2`.
- `examples/p2/timing_helpers.be`: low-level P2 timing plus `rtos.sleep_ms()`.
- `examples/i2c/scan.be`: BMP180/I2C scan on SDA 24, SCL 25.
- `examples/spi/jedec.be`: SPI flash JEDEC ID read.
- `examples/rtos/`: one-feature-at-a-time cross-cog RTOS examples.
- `examples/spin2/`: list Spin2 binaries and run mailbox/standalone suites from SD.

## Phase 11: Tests And Hardware Verification

- Always build with native Catalina before claiming success.
- Verify both RAM and flash-loader binaries:
 ```sh
 make p2 TOOLCHAIN=catalina
 make build/p2/catalina/full/berry_p2_flash_loader.binary TOOLCHAIN=catalina
 ```
- On hardware, test:
 - Pin 56 and 57 high/low/toggle/read on the no-PSRAM Catalina profile (`CATALINA_MODEL=COMPACT`, `CATALINA_CLIB=-lcx`, no `-lpsram`). Pin 57 is PSRAM chip-select on PSRAM builds.
 - `os` SD-card file operations.
 - `i2c.scan()` with BMP180 on SDA 24 / SCL 25.
 - SPI transfer with a known JEDEC-ID device.
 - Worker cog blink does not hang main REPL.
 - Spin2 binary can load, start, call, and stop from SD.

## Open Design Decisions

- Keep `worker`, `p2`, and `threads` as layered APIs or collapse them later.
- Decide if `spin2.start()` should continue returning integer handles or move to Berry objects when object support is worth the footprint.
- Decide whether Spin2 method metadata should stay in the binary call table or move to external manifests.
- Decide whether SD paths should remain `/spin2` or support aliases like `/sd/spin2` and `/SPIN2`.
- How much Catalina Lua behavior should be copied directly versus exposed as Berry-native idioms.
