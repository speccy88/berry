# P2 API Reference Snapshot

## Main native module

`p2` is the friendly hardware namespace. It exposes flat compatibility names and grouped submodules.

## Grouped APIs

- `p2.clock`: clock frequency/mode, counter reads, waits, and `hubset`.
- `p2.cog`: current cog, cog check/stop, and attention helpers. Use
  `wait_attention_result(timeout_us)` when code needs bounded attention waits;
  raw `wait_attention()` remains the blocking hardware primitive.
- `p2.lock`: hardware lock allocation/check/release helpers.
- `p2.pin`: GPIO `dir_low`, `dir_high`, `write`, `low`, `high`, `toggle`, `float`, and `read` helpers with board-reserved pin validation.
- `p2.cordic`: `rotxy`, `polxy`, and `xypol` helpers.
- `p2.math`: low-level integer math helpers.
- `p2.rng`: random helper.
- `p2.smart`: raw smart-pin register helpers.
- `p2.asm`: safe PASM-adjacent intrinsics, PASM blob loading into `bytes`, marker-fixture launch probes, and queryable ABI/capability diagnostics.
- `p2.debug`: backed diagnostics for heap, GC, cogs, memory map, pins, smart pins, registers, and snapshots.

Hardware status: the grouped modules are exposed on the flashed Catalina XMM
image tested on `/dev/ttyUSB0`. The full `/tests/p2/smoke_p2_api.be` hardware
smoke now passes on the flashed Catalina XMM image, covering clock waits,
cog/lock basics, LED GPIO, CORDIC/math/RNG/asm reads, debug maps/registers,
64-pin snapshots, and negative diagnostics.

## PASM

`p2.asm` currently exposes:

- `getrnd()`, `getct()`, `waitx(cycles)`, and `hubset(value)` as safe
  PASM-adjacent intrinsics over existing native helpers.
- `load(path)` to read a non-empty 4-byte-aligned PASM blob file into `bytes`.
- `cognew(blob, arg=nil, cog=nil)`, `cogstop(cog)`, and `cogcheck(cog)` over the
  existing low-level PASM cog path. These are not a claim that arbitrary blobs
  have a safe public ABI; `raw_cognew_policy` reports that distinction.
- `marker_blob()`, `launch_probe(target_cog=nil)`, and
  `launch_loaded_probe(blob, target_cog=nil)` for the exact known-good marker
  fixture only.
- `capabilities()` and `abi()` so Berry code can see that the current launch
  policy is `exact_marker_fixture_only` and that the unsafe assembly gate
  `BE_P2_ENABLE_UNSAFE_ASM` defaults off with no unsafe module exposed.

Arbitrary SD blob launch, inline assembly, unsafe assembly, and PASM function
bridges remain unsupported in normal builds. The ABI map reports
`arbitrary_blob_policy == "unsupported_exact_marker_fixture_only"`,
`function_bridge_policy == "unsupported_no_calling_convention"`, and
`inline_assembler_policy == "unsupported_no_parser_or_safety_contract"` until
argument, return, timeout, cog-reuse, cleanup, parser, code-generation, clobber,
label, relocation, source-mapping, optimizer, and safety rules are defined.

## Filesystem and memory diagnostics

- `p2.fs_info(path="/", write_probe=false)` reports SD mount, FAT, root, path, and optional write-probe state.
- `p2.psram_info()`, `p2.psram_read()`, `p2.psram_write()`, and `p2.psram_test()` expose bounded PSRAM block access when available.
- `p2.heap_info()` reports current Hub/XMM heap counters.

## Error policy

Board-reserved pins, invalid cog IDs, invalid lock IDs, and negative unsigned low-level arguments should raise clear errors before touching hardware.

## Smart Pins

The current public smart-pin surface is raw:

- `p2.smart.wrpin(pin, mode)`
- `p2.smart.wxpin(pin, x)`
- `p2.smart.wypin(pin, y)`
- `p2.smart.akpin(pin)`
- `p2.smart.rdpin(pin)`
- `p2.smart.rqpin(pin)`
- `p2.smart.start(pin, mode, x, y)`
- `p2.smart.clear(pin)`

The module also exposes lower-case smart-pin constants from Catalina's
`smartpin.h`, with the `P_` prefix removed, such as `normal`, `pwm_triangle`,
`pwm_sawtooth`, `nco_duty`, `count_rises`, `counter_periods`, `adc_ext`,
`adc_scope`, `dac_600r_2v`, `usb_pair`, and `async_rx`. The bit-31
`P_INVERT_A` selector is not exposed through the current signed-integer raw API
yet.

`tests/p2/smoke_smartpins_loopback.be` assumes jumpers between pins `0-1`,
`2-3`, `4-5`, and `6-7`. It verifies `p2smart` GPIO wrapper out/in behavior in both directions
on each pair, exercises every currently exposed raw smart-pin helper, checks
invalid pin/value diagnostics, and stages PWM-output to rise-counter loopback
plus GPIO-driven high-counter loopback, NCO, pulse, transition, repository,
DAC-output to ADC-input setup/readback, and async serial TX/RX setup/send/query
coverage in both directions on each jumper pair. A focused async RX smoke now
proves byte readback for `0x00`, `0x55`, `0xa5`, and `0xff` on jumpers `0-1`,
`2-3`, `4-5`, and `6-7` in both directions. Zero-byte readiness semantics,
buffering, calibrated ADC/DAC scaling or delta assertions, and remaining
mode-family coverage still need researched hardware execution.

`p2smart.default_jumper_pairs()` and `default_jumper_directions()` expose the
documented jumper wiring as fresh lists. `default_jumper_pairs_probe()` and
`default_jumper_pairs_bidirectional_probe()` provide aggregate result maps for
one-way and both-direction diagnostics over those pairs, including failed-pair
and failed-sub-check summaries.

Import `p2smart` for conservative high-level helpers over the raw smart-pin
surface:

- `p2smart.counter(pin, mode)` for rise/high/etc. counter modes.
- `p2smart.gpio_input(pin)` and `p2smart.gpio_output(pin, value)` for GPIO setup/read/write helpers.
- `p2smart.repository(pin, value, mode)` for repository-mode read/write checks.
- `p2smart.pwm(pin, frame, duty, divisor, mode)` for PWM setup.
- `p2smart.nco(pin, bit_period, increment, mode)` for NCO setup.
- `p2smart.pulse(pin, high_ticks, low_ticks, count, mode)` for pulse/cycle setup.
- `p2smart.transition(pin, width, count, mode)` for transition output setup.
- `p2smart.adc(pin, mode, sample_ticks)` for conservative ADC setup/readback.
- `p2smart.dac(pin, value, frame, mode)` for conservative DAC setup/update.
- `p2smart.async_serial_pair(tx_pin, rx_pin, baud, bits, tx_mode, rx_mode)` for async TX/RX setup over physically wired pins.
- `p2smart.jumper_pair_probe(out_pin, in_pin)` and
  `p2smart.jumper_pairs_probe(pairs)` for aggregate jumper diagnostics.
- `p2smart.sync_serial_pair(tx_pin, rx_pin, baud, bits, tx_mode, rx_mode)` for
  staged sync serial setup/send/raw-read probing plus `read_result()` /
  `read_result_after(wait_us)` diagnostics. Sync serial received-data loopback
  is not yet validated.

These wrappers stage correct raw register calls and validate simple integer
ranges. Pass `nil` for optional arguments to use conservative defaults. They
do not yet claim calibrated ADC voltage scaling, DAC calibration, or full
mechanical quadrature encoder coverage. Synthetic quadrature motion/direction
is covered by driving pins `0` and `2` into inputs `1` and `3` through the
documented jumpers. USB/HID remains explicitly unsupported in the current
default build through `p2compat.status("usb_hid")`.

## Cooperative IPC facade

Import `p2ipc` to attach cooperative Hub-memory IPC helpers to `p2`:

- `p2ipc.capabilities()` returns the current IPC capability map, and
  `p2ipc.capability(name)` returns one value or `nil` for an unknown name.
- `p2ipc.attention_policy()` reports bounded native cog-attention availability
  and the explicit no-channel/no-mailbox-wakeup contract;
  `p2ipc.attention_policy_value(name)` returns one policy value or `nil`.
- `p2ipc.contract()` returns the current-VM IPC boundary, and
  `p2ipc.contract_value(name)` returns one contract value or `nil`.
- `p2.channel.new(depth=8)` returns an object with `send(value)`, `send_result(value)`, `recv(timeout_ms=nil)`, `recv_result(timeout_ms=nil)`, `snapshot_result()`, `size()`, `free()`, `close()`, `close_result()`, and `info()`.
- `p2.mailbox.new()` returns a one-slot mailbox with `put(value)`, `put_result(value)`, `get()`, `get_result()`, `peek_result()`, `ready()`, `close()`, `close_result()`, and `info()`.
- `p2.shared.Buffer(size)` returns a bounded byte buffer with `read`, `read_result`, `write`, `write_result`, `fill`, `fill_result`, `size`, `aslist`, and `info()`.
- `p2.mutex.new()` returns a mutex with `lock()`, `lock_result()`, `unlock()`, `unlock_result()`, `close()`, `close_result()`, `id()`, and `info()`. It uses `p2.lock` hardware locks when available and falls back to a cooperative in-VM lock otherwise.

The result-shaped methods preserve the old simple method behavior while distinguishing empty/full/busy/not-locked/closed/error states from valid `nil` payloads. `close()` is idempotent and marks channels, mailboxes, and mutexes closed so later operations fail instead of silently reusing released resources. These objects are cooperative current-VM objects. Imported channels and mailboxes can be used with `task.wait()` for current-VM readiness polling (`recv`/`send` and `get`/`put`), and `p2ipc.capabilities()` reports that through `task_wait_integration`, `task_wait_channel`, and `task_wait_mailbox`. `p2ipc.attention_policy()` reports whether bounded native cog-attention waits are available, but IPC channels and mailboxes do not yet wake other cogs with attention or provide cross-VM serialization.
