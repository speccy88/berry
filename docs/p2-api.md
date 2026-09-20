# P2 API Reference

Follow [Getting Started](getting-started.md) for the executable first-prompt
walkthrough and cancellation/EOF behavior. [Port status](P2_PORT_STATUS.md) owns
the current support summary. This reference includes experimental diagnostics;
registration is not a promise of production support.

## Discovery and conventions

Prefer the grouped hardware API (`p2.clock.freq()`, `p2.cog.id()`, `p2.pin.read(pin)`).
Flat aliases remain backward-compatible. Profiles can expose different groups.

`p2.help()` (or `p2.help("p2")`) returns a map with `topic`, `groups`, `usage`,
`safety`, `support` and `examples`. `groups` is a list of live registered submodules.
`p2.help("pin")` returns the same metadata with `members` instead of `groups`:
a list of that module's public registered members, not a hardcoded API catalog.
List order is unspecified. Results are fresh snapshots, not mutable module tables.

For `cog`, `asm` and `debug`, the map also includes `capabilities`, obtained from
the existing native capability reporter. `false` means unavailable; experimental
flags and internal source-worker diagnostics do not enable production concurrency.
In particular, `p2.cog.capabilities()["spawn_source"]` is `false` in production.

- No argument, or one string naming an available group: returns a help map.
- Wrong argument type (including `nil`) or more than one argument: `type_error`.
- Unknown/unavailable group, empty string or embedded NUL: `value_error`.
- Help only reads metadata: no GPIO writes, bus opens, storage writes or SD lookup.
- Help does not call overridable module functions to obtain capability maps.

```berry
import p2
p2.help("pin")["members"]
p2.help("cog")["capabilities"]["spawn_source"]
p2.debug.snapshot()["runtime"]["memory_profile"]
import introspect
introspect.members(p2.pin)
```

These are expressions: the REPL prints non-`nil` results automatically. In scripts,
use `print(...)` when output is wanted. Berry errors are exceptions, not Python
syntax or ad-hoc success strings. Existing APIs retain their documented `nil`,
map/result and error conventions; this increment does not normalize every legacy
helper. The [interactive example](../examples/p2/interactive.be) and
[help smoke](../tests/p2/smoke_interactive_help.be) exercise the new surface without
external hardware operations.

## Main native module

`p2` is the friendly hardware namespace. It exposes grouped submodules and flat
compatibility names. Capability snapshots describe availability, not a permission
to drive pins: validate board reservations and wiring before hardware calls.

## Grouped APIs

- `p2.clock`: clock frequency/mode, counter reads, waits, and `hubset`.
- `p2.cog`: current cog, cog check/stop, attention helpers, and the interim
  native-blink closure-cog handle API. Use `wait_attention_result(timeout_us)`
  when code needs bounded attention waits; `wait_attention()` waits
  interruptibly and returns the next attention mask. `cleanup_result()` stops
  and releases all spawned closure-cog handles, which is useful after REPL
  experiments or examples. `capability(name)` returns one handle/cleanup policy
  field for compact checks.
- `p2.lock`: hardware lock allocation/check/release helpers.
- `p2.pin`: GPIO `dir_low`, `dir_high`, `write`, `low`, `high`, `toggle`, `float`, and `read` helpers with board-reserved pin validation.
- `p2.cordic`: `rotxy`, `polxy`, and `xypol` helpers.
- `p2.math`: low-level integer math helpers.
- `p2.rng`: random helper.
- `p2.smart`: raw smart-pin register helpers.
- `p2.asm`: safe PASM-adjacent intrinsics, PASM blob loading into `bytes`, marker-fixture launch probes, fixed named-operation mailbox fixture-call proofs, and queryable ABI/capability diagnostics.
- `p2.debug`: backed diagnostics for heap, GC, cogs, memory map, pins, smart pins, registers, snapshots, and queryable debug capability/policy metadata.

The LARGE/XMM production profile registers these groups. The interactive
walkthrough uses read-only calls, not the full peripheral smoke suite.
Earlier flashed-image `smoke_p2_api.be` captures are historical porting evidence;
they are not a fresh claim for every API on the current image.

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
- `fixture_call(operation, lhs, rhs, target_cog=nil)` for fixed built-in PASM
  mailbox operations. The current operation list is queryable as
  `fixture_call_ops` and includes `add`, `sub`, `xor`, `and`, and `or`.
- `fixture_add(lhs, rhs, target_cog=nil)` as the compatibility wrapper for the
  fixed `add` fixture operation.
- `capabilities()` and `abi()` so Berry code can see that the current launch
  policy is `exact_marker_fixture_only` and that the unsafe assembly gate
  `BE_P2_ENABLE_UNSAFE_ASM` defaults off with no unsafe module exposed.
- `capability(name)` and `abi_value(name)` for direct single-field metadata
  lookups that return `nil` for unknown or non-string names.

Arbitrary SD blob launch, inline assembly, unsafe assembly, and general PASM
function bridges remain unsupported in normal builds. The ABI map reports
`arbitrary_blob_policy == "unsupported_exact_marker_fixture_only"`,
`function_bridge_policy == "unsupported_no_calling_convention"`, and
`inline_assembler_policy == "unsupported_no_parser_or_safety_contract"` until
argument, return, timeout, cog-reuse, cleanup, parser, code-generation, clobber,
label, relocation, source-mapping, optimizer, and safety rules are defined.

## Filesystem and memory diagnostics

- `p2.fs_info(path="/", write_probe=false)` reports SD mount, FAT, root, path, and optional write-probe state.
- `p2.psram_info()`, `p2.psram_read()`, `p2.psram_write()`, and `p2.psram_test()` expose bounded PSRAM block access when available.
- `p2.heap_info()` reports current Hub/XMM heap counters.
- `p2mem.memory_pressure_policy()` is the source-module diagnostic for current
  low-memory/PSRAM accounting. It combines `p2.heap_info()`, `p2.psram_info()`,
  native upper-PSRAM cache status, and `libstore` source-cache status, and
  reports that heap high-water tracking is not instrumented yet. Its retry
  policy says routine priority work should move on unless native high-water
  instrumentation or cache allocator behavior is being changed.

## Child VM Boundary Diagnostics

- `p2.vm_copyable(value)` returns a map describing whether one value can cross
  the current child-VM boundary. Nil, bool, int, and bounded string values are
  copyable. Lists, maps, functions/closures, and other live objects are
  rejected with a kind and reason.
- `p2.vm_copyable_args(...values)` preflights a planned child-VM argument list.
  It returns `ok`, `count`, `copyable_count`, `rejected_count`,
  `first_rejected_index`, `first_rejected_kind`, `first_rejected_reason`, and
  policy flags such as `primitive_copy_only`, `bounded_string_copy`, no
  ownership transfer, no shared mutable state, and no resource transfer.
- `p2.vm_call(...)`, `p2.vm_call_once(...)`, and `p2.vm_invoke(...)` use the
  same primitive-copy preflight and return explicit `ok` / `status` fields. If
  a planned argument list contains a live object, the returned map reports
  `ok == false`, `status == "args_rejected"`, `args_copyable == false`,
  `arg_rejected_count`, `first_arg_rejected_index`,
  `first_arg_rejected_kind`, and `first_arg_rejected_reason` before selecting a
  child heap partition or running child code. Successful primitive calls report
  `ok == true` and `status == "ok"`.
- Persistent child-VM lifecycle helpers also report `ok` / `status`:
  `p2.vm_open(slot, bytes)`, `p2.vm_eval(slot, source)`,
  `p2.vm_get(slot, name)`, and `p2.vm_close(slot)`. These statuses let scripts
  distinguish normal operation from inactive slots, missing globals, unsupported
  result values, partition failures, child deletion failures, and release
  failures without parsing the raw diagnostic counters.
- `p2.vm_info(slot)` reports the current persistent child-VM slot state without
  changing it: `status` is `inactive`, `active`, or `cog_running`, with fields
  for `active`, `has_child`, `partition_ready`, heap byte counts, cog state,
  cog stack presence, and runtime-lock availability.

These diagnostics do not serialize live object graphs or transfer resources.
They are the public guardrail for code that wants to reject unsupported child-VM
arguments before attempting a child call. `p2compat.child_vm_transfer_policy()`
exposes the matching source-module policy, and
`p2compat.child_vm_live_object_transfer(value)` raises `unsupported_error` for
explicit live-object transfer requests.

`p2compat.child_vm_partition_policy()` exposes the `p2.heap_info()`
`vm_partition_*` fields as runtime-derived child-VM heap sizing metadata. It
reports partition bytes, capacity, free capacity, maximum partitions, created
partition count, current partition selection, and whether those values are
usable for child calls. This is a diagnostic policy, not a claim that production
partition counts are tuned: `production_count_selected` is currently `false`,
and the retry policy says routine priority work should stop here unless the
native partition allocator or isolated child-VM cog runtime is being changed.
`p2compat.child_vm_partition_value(name)` returns one policy field for compact
tools and tests.

## Board/Profile Compatibility Policy

`p2compat.board_profile_policy()` reports the current build-facing compatibility
contract for board/profile-sensitive code. The policy includes `board`,
`profile`, `catalina_model`, `memory_profile`, `psram_enabled`,
`reserved_pin_policy`, `reserved_pin_ranges`, the normal Catalina toolchain path
`../Catalina`, and the normal serial port `/dev/ttyUSB0`. It also records that
unsupported build or board/profile combinations must raise loudly or report
`unsupported` instead of being silently guessed.

`p2compat.board_profile_value(name)` returns one field from that policy and
copies list values, so tests and tools can query compact facts without mutating
the module state. `required_board_profile_policy_keys()` and `audit()` keep this
metadata present alongside the existing child-VM compatibility policy.
`p2compat.board_pin_policy(pin)` reports whether a pin is allowed by the active
board profile or reserved for PSRAM, SD, or serial use; `board_pin_allowed(pin)`
returns the boolean `ok` field for compact checks.

## Cog Capability Boundary

`p2.cog.capabilities()` and `p2.cog.capability(name)` expose the current
closure/cog contract. The default Catalina XMM profile reports
`isolated_child_vm_cog == false` plus
`isolated_child_vm_cog_policy == "unsupported_catalina_xmm_c_cog_runtime_not_safe"`
and an explanatory `isolated_child_vm_cog_reason`, so tooling can distinguish
the native-blink handle model from the still-open independent Berry VM runtime.

## Error policy

Board-reserved pins, invalid cog IDs, invalid lock IDs, and negative unsigned low-level arguments should raise clear errors before touching hardware.
GPIO reserved-pin rejection is hardware-smoked on the current XMM profile. Raw
`p2.smart` reserved-pin negative proof is deferred because a tiny direct smoke
hung on the current image; keep routine smart-pin tests on documented safe
jumper pins until that low-level negative path can be isolated without risking
SD, serial, or PSRAM pins.

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

The module also exposes all current lower-case `P_` smart-pin constants from the
sibling Catalina `../Catalina/include/smartpin.h`, with the prefix removed.
Examples include `normal`, `pwm_triangle`, `pwm_sawtooth`, `nco_duty`,
`count_rises`, `counter_periods`, `adc_ext`, `adc_scope`, `dac_600r_2v`,
`usb_pair`, and `async_rx`. The bit-31 `P_INVERT_A` selector is exposed as
signed `invert_a == -2147483648`; raw smart-pin mode helpers pass that signed
bit pattern through as the intended 32-bit mode word.

The quick user-facing smart-pin examples now use native `import p2` and
`p2.smart` directly. `make p2-smoke-examples-quick TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0`
stages only the GPIO, PWM, ADC, DAC, and NCO counter examples and avoids the
larger `p2smart` source wrapper unless wrapper diagnostics are explicitly under
test.

`tests/p2/smoke_smartpins_loopback.be` assumes jumpers between pins `0-1`,
`2-3`, `4-5`, and `6-7`. It verifies `p2smart` GPIO wrapper out/in behavior in both directions
on each pair, exercises every currently exposed raw smart-pin helper, checks
invalid pin/value diagnostics, and stages PWM-output to rise-counter loopback
plus GPIO-driven high-counter loopback, NCO, pulse, transition, repository,
DAC-output to ADC-input setup/readback, and async serial TX/RX setup/send/query
coverage in both directions on each jumper pair. Focused native smokes now
prove byte readback for `0x00`, `0x55`, `0xa5`, and `0xff` on jumpers `0-1`,
`2-3`, `4-5`, and `6-7` in both directions, zero-byte timed reads, latest-byte
async burst behavior, and bounded clocked sync receive on data `0-1` plus clock
`2-3`. True async FIFO buffering, calibrated ADC/DAC scaling, calibrated
timer/counter interpretation, and remaining mode-family coverage still need
researched hardware execution or explicit implementation.

`p2smart.default_jumper_pairs()` and `default_jumper_directions()` expose the
documented jumper wiring as fresh lists. `default_jumper_pairs_probe()` and
`default_jumper_pairs_bidirectional_probe()` provide aggregate result maps for
one-way and both-direction diagnostics over those pairs, including failed-pair
and failed-sub-check summaries.

Import `p2smart` for conservative high-level helpers over the raw smart-pin
surface:

- `p2smart.counter(pin, mode)` for rise/high/etc. counter modes.
- `p2smart.counter_timer_calibration_policy()` reports the explicit boundary
  between raw timer/counter observations and unsupported calibrated
  microsecond/frequency interpretation.
- `p2smart.counter_timer_calibrated_probe(out_pin, in_pin, mode_name, pulse_us, pulses)`
  validates its inputs, then raises `unsupported_error` until calibrated
  timer/counter conversion is implemented.
- `p2smart.gpio_input(pin)` and `p2smart.gpio_output(pin, value)` for GPIO setup/read/write helpers.
- `p2smart.repository(pin, value, mode)` for repository-mode read/write checks.
- `p2smart.pwm(pin, frame, duty, divisor, mode)` for PWM setup.
- `p2smart.nco(pin, bit_period, increment, mode)` for NCO setup.
- `p2smart.pulse(pin, high_ticks, low_ticks, count, mode)` for pulse/cycle setup.
- `p2smart.transition(pin, width, count, mode)` for transition output setup.
- `p2smart.adc(pin, mode, sample_ticks)` for conservative ADC setup/readback.
- `p2smart.dac(pin, value, frame, mode)` for conservative DAC setup/update.
- `p2smart.adc_dac_delta_policy()` reports the explicit uncalibrated analog
  boundary.
- `p2smart.adc_dac_calibrated_probe(out_pin, in_pin, low_value, high_value, min_mv)`
  validates its inputs, then raises `unsupported_error` until calibrated
  voltage/polarity interpretation is implemented.
- `p2smart.async_serial_pair(tx_pin, rx_pin, baud, bits, tx_mode, rx_mode)` for async TX/RX setup over physically wired pins.
- `p2smart.async_serial_buffer_policy()` reports the current direct-sample,
  no-background-FIFO receive model.
- `p2smart.async_serial_buffered_pair(tx_pin, rx_pin, baud, bits, depth)`
  validates its inputs, then raises `unsupported_error` until real background
  RX buffering/FIFO ownership exists.
- `p2smart.jumper_pair_probe(out_pin, in_pin)` and
  `p2smart.jumper_pairs_probe(pairs)` for aggregate jumper diagnostics.
- `p2smart.sync_serial_pair(tx_pin, rx_pin, baud, bits, tx_mode, rx_mode)` for
  sync serial setup/send/raw-read probing plus `read_result()` /
  `read_result_after(wait_us)` diagnostics. `sync_serial_clocked_probe(...)`
  runs one bounded data/clock jumper attempt using sync X `(bits-1)|0x20` and
  left-aligned receive-word decoding; current hardware verifies matched receive
  on data `0-1` plus clock `2-3`. The phase-variant helpers report
  `execution_deferred` planning records so broad diagnostics do not wedge the
  current smart-pin setup. The user-facing `examples/sync_serial_loopback.be`
  intentionally imports native `p2` and uses `p2.smart` constants directly so
  the documented synchronous-serial mode plan starts quickly without
  source-loading the large `p2smart` helper module. The older
  `examples/spi_loopback.be` name remains as a compatibility alias for the same
  synchronous-serial jumper diagnostic.

These wrappers stage correct raw register calls and validate simple integer
ranges. Pass `nil` for optional arguments to use conservative defaults. They do
not yet claim calibrated ADC voltage scaling, DAC calibration, calibrated
timer/counter interpretation, true async RX buffering, or full mechanical
quadrature encoder coverage. Synthetic quadrature motion/direction is covered
by driving pins `0` and `2` into inputs `1` and `3` through the documented
jumpers. `p2smart.adc_dac_delta_policy()` reports the uncalibrated analog
boundary, and `p2smart.adc_dac_calibrated_probe(...)` validates inputs before
raising `unsupported_error`. `p2smart.quadrature_mechanical_policy()` reports that explicit
boundary, and `p2smart.quadrature_mechanical_encoder(...)` validates inputs
before raising `unsupported_error`. USB/HID remains explicitly unsupported in the current
default build: `p2smart.usb_pair_policy()` reports the raw smart-pin constant
only and `p2smart.usb_pair_probe(...)` raises `unsupported_error`, while
`p2compat.status("usb_hid")` reports the higher-level USB/HID demo boundary.

## Cooperative IPC facade

Import `p2ipc` to attach cooperative Hub-memory IPC helpers to `p2`:

- `p2ipc.capabilities()` returns the current IPC capability map, and
  `p2ipc.capability(name)` returns one value or `nil` for an unknown name.
- `p2ipc.attention_policy()` reports bounded native cog-attention availability
  and the explicit no-channel/no-mailbox-wakeup contract;
  `p2ipc.attention_policy_value(name)` returns one policy value or `nil`.
- `p2ipc.contract()` returns the current-VM IPC boundary, and
  `p2ipc.contract_value(name)` returns one contract value or `nil`.
- `p2ipc.payload_result(value)` reports the payload boundary for one value:
  current-VM reference semantics, no serialization, no ownership transfer, and
  native `p2.vm_copyable()` diagnostics when available.
- `p2.channel.new(depth=8)` returns an object with `send(value)`, `send_result(value)`, `recv(timeout_ms=nil)`, `recv_result(timeout_ms=nil)`, `ready_result(mode=nil)`, `lifecycle_result()`, `snapshot_result()`, `size()`, `free()`, `close()`, `close_result()`, and `info()`.
- `p2.mailbox.new()` returns a one-slot mailbox with `put(value)`, `put_result(value)`, `get()`, `get_result()`, `ready()`, `ready_result(mode=nil)`, `lifecycle_result()`, `peek_result()`, `close()`, `close_result()`, and `info()`.
- `p2.shared.Buffer(size)` returns a bounded byte buffer with `read`, `read_result`, `write`, `write_result`, `fill`, `fill_result`, `clear_result`, `lifecycle_result`, `size`, `aslist`, and `info()`.
- `p2.mutex.new()` returns a mutex with `lock()`, `lock_result()`, `unlock()`, `unlock_result()`, `lifecycle_result()`, `close()`, `close_result()`, `id()`, and `info()`. It uses `p2.lock` hardware locks when available and falls back to a cooperative in-VM lock otherwise.

The result-shaped methods preserve the old simple method behavior while distinguishing empty/full/busy/not-locked/closed/error states from valid `nil` payloads. `ready_result()` is non-mutating and reports the same current-VM readiness modes used by `task.wait()`: channel `recv`/`send` plus aliases `get`/`put`, and mailbox `get`/`put` plus aliases `recv`/`send`. `lifecycle_result()` and `p2ipc.lifecycle_result(obj)` are non-mutating diagnostics for usable/closed state, pending payload references, held hardware-lock resources, cleanup policy, and the explicit current-VM/no-serialization/no-ownership-transfer boundary. `close()` is idempotent and marks channels, mailboxes, and mutexes closed so later operations fail instead of silently reusing released resources. These objects are cooperative current-VM objects. Imported channels and mailboxes can be used with `task.wait()` for current-VM readiness polling (`recv`/`send` and `get`/`put`), and `p2ipc.capabilities()` reports that through `task_wait_integration`, `task_wait_channel`, and `task_wait_mailbox`. `p2ipc.attention_policy()` reports whether bounded native cog-attention waits are available, but IPC channels and mailboxes do not yet wake other cogs with attention or provide cross-VM serialization.
