# Propeller 2 Port TODO

This TODO blends the current P2 Berry port notes into one implementation backlog. It is intentionally a planning document only: do not treat every API below as implemented yet.

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

- P2 native modules are registered through `port/p2/overrides/be_modtab_p2.c`.
- Existing P2 native modules and overrides should be used as templates:
  - `port/p2/overrides/be_prop2lib.c`
  - `port/p2/overrides/be_i2clib_p2.c`
  - `port/p2/overrides/be_spilib_p2.c`
  - `port/p2/overrides/be_workerlib_p2.c`
  - `port/p2/overrides/be_libs_p2.c`
- Native functions use the Berry C API style: `int fn(bvm *vm)`, extract args with `be_toint()` / `be_tostring()`-style helpers, push returns with `be_pushint()` / `be_pushstring()` / lists, then return via the repo's existing convention.

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

- Keep Catalina `v8.8.9` support working in Docker.
- Preserve the fix that maps `-lcix` to `cix` when patching Catalina P2 libraries.
- Keep `bmapkey` bit-fields C-standard compatible for Cake 0.13.24.
- Add a documented command for building against a source-built Catalina cache:
  ```sh
  make p2 TOOLCHAIN=catalina CATALINA_USE_DOCKER=1 CATALINA_DIR=.third_party_cache/catalina-v8.8.9-build
  ```
- Add a repeatable helper script for building Catalina `v8.8.9` binaries and P2 COMPACT libraries from source, if we decide this should become supported workflow.

## Phase 1: Digital I/O `p2` Module

Goal: make the P2 module comparable to Catalina Lua's `propeller` basics.

- `p2.high(pin)`: set pin output high.
- `p2.low(pin)`: set pin output low.
- `p2.toggle(pin)`: toggle pin state.
- `p2.read(pin)`: return current pin state as integer/bool.
- `p2.pinmode(pin, mode)`: configure input, output, or open-drain.
- `p2.sleep_ms(ms)`: millisecond delay.
- `p2.delay_us(us)`: microsecond delay.
- `p2.cogid()`: return current cog ID.
- `p2.locknew()`: allocate a hardware lock.
- `p2.lockset(lock)`: set/acquire hardware lock.
- `p2.lockclr(lock)`: clear/release hardware lock.
- `p2.sbrk()`: report available heap or closest meaningful heap-space estimate.
- Ensure pins 56 and 57 are accessible on P2 Edge boards without PSRAM.
- Add examples:
  ```berry
  import p2
  while true
      p2.high(56)
      p2.sleep_ms(250)
      p2.low(56)
      p2.sleep_ms(250)
  end
  ```

## Phase 2: I2C Module

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

## Phase 4: Worker And Cog Management

Goal: evolve the current `worker` prototype into a clean P2 cog/concurrency layer.

- Keep rule: one Berry VM must never be used concurrently by more than one cog.
- Worker VM heap/state must live in Hub RAM.
- Use Hub RAM mailboxes for cross-cog requests.
- Do not transfer Berry closures or VM-owned object references across cogs.
- Continue name-based dispatch for v1: function name + integer args.
- `worker.start()`: launch a second cog with its own Berry VM.
- `worker.exec(name, ...int_args)`: send integer-only job to worker VM.
- Ensure worker-side script/function environment is explicit.
- Make `blink(pin, delay_ms)` demo reliable:
  ```berry
  import worker
  worker.start()
  worker.exec("blink", 56, 250)
  ```
- Add future `p2.cog_start(fn, args...)` only after the VM ownership and function-loading model is clear.
- Add `p2.cog_stop(cog_id)` once we can safely track cog ownership and cleanup.

## Phase 5: Threads And Channels

Goal: a simplified Berry equivalent inspired by Catalina Lua threads, not a full scheduler.

- Start small with a fixed number of worker/mailbox slots.
- `threads.workers(n)`: configure worker pool if feasible.
- `threads.new(fn)`: launch work on an available worker/cog.
- `threads.channel(name)`: create or fetch a named channel.
- `threads.put(name, value)`: send integer/string value initially.
- `threads.get(name)`: receive value, blocking or timeout-based.
- `threads.output(str)`: safe shared serial output.
- `threads.msleep(ms)`: sleep helper for worker code.
- `threads.update(key, value)`: shared data update, initially integer/string only.
- Use P2 locks or atomic mailbox state for synchronization.
- Document limitations: no object serialization, no closure transfer between VMs, limited value types at first.

## Phase 6: Spin2 Build Directory

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

Goal: dynamic loading of compiled Spin2/P2 binaries from SD and launching them in cogs.

- Create the module under the P2-native location, probably `port/p2/overrides/be_spin2lib_p2.c`, unless a better repo convention emerges.
- Register `spin2` in `port/p2/overrides/be_modtab_p2.c`.
- `spin2.list(path="/sd/spin2")`: return `.bin`, `.binary`, and `.p2` files.
- `spin2.start(file, par=0)`: load binary from SD into Hub RAM and launch with `COGINIT`.
- Return a handle that tracks cog ID, Hub code base, binary size, mailbox, method table, and ownership.
- `spin2.call(handle, method_id, ...int_args)`: integer-only v1 call through a Hub mailbox.
- `spin2.stop(handle)`: `COGSTOP` and free owned Hub resources.
- Validate file existence, binary size, method count, method index, argument count, and cog availability.
- Raise Berry errors for invalid handles and resource exhaustion.

## Phase 8: Spin2 Calling Convention

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

- Smart pin helpers for PWM.
- Smart pin helpers for ADC/DAC.
- Frequency measurement.
- Counter/timestamp functions.
- `p2.beep(pin, freq, ms)` or `p2.beep(freq, ms)` once pin ownership is settled.
- Keep these behind small, focused APIs rather than a giant hardware abstraction layer.

## Phase 10: Examples And Mini Tutorials

Add examples as each feature becomes real:

- `examples/p2_blink.be`: LED blink on pins 56/57.
- `examples/p2_i2c_scan.be`: BMP180/I2C scan on SDA 24, SCL 25.
- `examples/p2_spi_jedec.be`: SPI flash JEDEC ID read.
- `examples/p2_worker_blink.be`: second-cog worker blink.
- `examples/p2_threads_channel.be`: simple channel put/get.
- `examples/p2_spin2_list.be`: list Spin2 binaries on SD.
- `examples/p2_spin2_smartserial.be`: start/call/stop SmartSerial-style object.

## Phase 11: Tests And Hardware Verification

- Always build with Catalina Docker before claiming success.
- Verify both RAM and flash-loader binaries:
  ```sh
  make p2 TOOLCHAIN=catalina CATALINA_USE_DOCKER=1
  make build/p2/catalina/berry_p2_flash_loader.binary TOOLCHAIN=catalina CATALINA_USE_DOCKER=1
  ```
- On hardware, test:
  - Pin 56 and 57 high/low/toggle/read.
  - `os` SD-card file operations.
  - `i2c.scan()` with BMP180 on SDA 24 / SCL 25.
  - SPI transfer with a known JEDEC-ID device.
  - Worker cog blink does not hang main REPL.
  - Spin2 binary can load, start, call, and stop.

## Open Design Decisions

- Whether cog/concurrency APIs live in `p2`, `worker`, `threads`, or all three with clear layering.
- Whether `spin2.start()` returns a Berry object, integer handle, or map-like opaque handle.
- Whether Spin2 binaries should use a Berry-defined call-table ABI or external manifest files.
- Whether SD paths should use `/sd/spin2`, `/SPIN2`, or the existing P2 filesystem path style.
- How much Catalina Lua behavior should be copied directly versus exposed as Berry-native idioms.

