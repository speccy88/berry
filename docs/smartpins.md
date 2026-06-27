# P2 Smart Pins

## Current implementation

The P2 port exposes raw smart-pin helpers through `p2.smart`:

- `wrpin(pin, mode)`
- `wxpin(pin, x)`
- `wypin(pin, y)`
- `akpin(pin)`
- `rdpin(pin)`
- `rqpin(pin)`
- `start(pin, mode, x, y)`
- `clear(pin)`

These helpers use the shared P2 bus pin validation path. Positive hardware
coverage stays on documented non-reserved jumper pins. A direct reserved-pin
negative smoke for raw `p2.smart` calls hung on the current XMM image, so that
specific proof is deferred instead of being included in the routine focused
smart-pin path. `p2smart.raw_smartpin_reserved_pin_policy()` records that
deferred boundary for status tools. Use `p2smart.raw_smartpin_probe(pin)` for a
result-shaped raw helper diagnostic that exercises zeroed `wrpin`/`wxpin`/
`wypin`, `akpin`, `rdpin`, `rqpin`, normal-mode `start`, and `clear` on safe
pins.

`p2.smart` also exposes all current lower-case `P_` constants from the sibling
Catalina `../Catalina/include/smartpin.h`, with the prefix removed. Examples
include `normal`, `pwm_triangle`, `pwm_sawtooth`, `nco_duty`, `count_rises`,
`counter_periods`, `adc_ext`, `adc_scope`, `dac_600r_2v`, `usb_pair`, and
`async_rx`. The `p2smart` source fallback keeps the same names available when
the grouped native table is not present.
`P_INVERT_A` is exposed as signed `invert_a == -2147483648`; raw smart-pin mode
helpers pass that signed bit pattern through as the intended 32-bit mode word.

Quick user-facing examples use native `import p2` / `p2.pin` / `p2.smart`
directly so normal P2 users can exercise GPIO, PWM, ADC, DAC, and NCO counter
loopback without source-loading the larger `p2smart` wrapper. Run them with
`make p2-smoke-examples-quick TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0`.
The broader native `smartpin_diagnostics.be` example runs GPIO, rise-count,
high-ticks, and async-byte checks across the documented four jumper pairs
through `make p2-smoke-examples-smartpin-diagnostics TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0`.
Focused `p2smart` wrapper diagnostic targets remain available when wrapper
behavior itself is the thing under test.

`tests/p2/smoke_smartpins_loopback.be` is the current hardware-oriented smoke.
It assumes jumpers between pins `0-1`, `2-3`, `4-5`, and `6-7`, checks GPIO
wrapper loopback in both directions, exercises the raw smart-pin helpers, checks
repository mode on every jumper pin, and stages PWM triangle/sawtooth/SMPS,
NCO frequency, NCO-duty counter-visible output, pulse, transition, rise/high counter loopback,
DAC-output to ADC-input setup/readback, and async serial TX/RX setup/send/query
checks on every pair.

`tests/p2/smoke_smartpins_async_rx.be` is the focused async receive-byte proof.
It verifies `p2smart.AsyncSerialPair.read_byte()`, `read_result()`,
`read_result_after(wait_us)`, paced byte-list exchange helpers, and `clear()`
cleanup on the physically jumped `0-1`, `2-3`, `4-5`, and `6-7` pairs in both
directions for `0x00`, `0x55`, `0xa5`, and `0xff`. For `0x00`,
`read_result_after(2000)` uses a timed raw sample and reports `ready=true`,
`value=0`, and `event=nil` because `available()` / `rqpin` can be zero for a
valid zero byte. The raw word can still contain lower smart-pin state bits; use
`value` for the decoded byte. The byte-list helpers are paced one-byte-at-a-time
protocol helpers, not a receive FIFO. The focused smoke also sends `0x12` then
`0x34` without an intervening receive on the `0-1` jumper and verifies the
single sampled RX value is the latest byte, `0x34`, making the no-FIFO boundary
explicit. Buffered receive behavior remains open.
ADC/DAC smoke currently verifies setup, integer readback, and sampled jumper diagnostics. `tests/p2/smoke_smartpins_adc_dac_native.be`
is the routine native `p2.smart` path for the documented `0-1` jumper: it
starts ADC on pin `1`, DAC output on pin `0`, samples low/high DAC settings,
reports average delta and polarity, clears both pins, and requires nonzero
uncalibrated movement for the default DAC/ADC path plus the named
`600r_2v`/`dither_rnd` DAC path. The same smoke records named ADC variant
diagnostics for `adc_ext` and `3x` forms, but the current jumper harness reports
flat raw readings for those modes, so named ADC analog validation remains open.
`p2-smoke-smartpins-adc-dac-native` stages only that file and is
included in the focused Priority 2 smart-pin path. `p2-smoke-smartpins-adc-variant-matrix`
is the on-demand native diagnostic matrix for ADC variant work; it is not part
of the routine focused aggregate. Current hardware on `0-1` shows `1x`/`adc`
with `32` sample ticks moving strongly, `1x`/`adc` with `256` sample ticks
flat, `3x` and `10x` flat even with smaller DAC ranges, `adc_ext` flat in both
`0->1` and `1->0` directions, and `adc_scope` only a one-count diagnostic.
`p2smart.dac_adc_probe(...)`
adds a result-shaped diagnostic for a DAC pin jumpered to an ADC pin: it reports
`low_raw`, `high_raw`, signed `delta`, absolute `abs_delta`, `threshold`, `ok`,
and `reason`, then clears both pins. `p2smart.dac_adc_sampled_probe(...)`,
`p2smart.dac_variant_adc_sampled_probe(...)`, and
`p2smart.adc_variant_dac_sampled_probe(...)`, plus
`p2smart.adc_dac_variants_sampled_probe(...)`, repeat that check over multiple
low/high ADC samples and report sample lists, min/max, averages,
signed/absolute average delta, and polarity labels while still marking
    `polarity_verified` and `calibrated_voltage` false. These diagnostics use
absolute delta because observed hardware direction can be board/mode dependent.
The native smoke now uses a responsive ADC sample interval (`32` ticks) and
requires nonzero raw movement on the current `0-1` jumper for the default
ADC/DAC path and named-DAC path, while calibrated voltage scaling, named ADC
variant scaling/filtering, and stable polarity/low-high voltage assertions
remain open under `adc_dac_delta`. Default and named-DAC sampled helpers are
tracked as `verified`; named-ADC sampled helpers are tracked as diagnostics;
`p2-smoke-smartpins-adc-dac-diag` is the focused diagnostic-only entrypoint for
this path.

Import `p2smart` for conservative wrapper classes around the raw helpers:

- `p2smart.counter(pin, mode)` returns a `Counter`.
  Use `sample_after(wait_us)` for result-shaped before/after counter diagnostics.
- `p2smart.high_counter_probe(out_pin, in_pin, high_us, settle_us)` returns a
  result-shaped GPIO-high to count-highs jumper diagnostic.
- `p2smart.counter_mode(name)` builds a setup-only counter/timer mode word from
  `count_rises`, `count_highs`, `state_ticks`, `high_ticks`, `events_ticks`,
  `periods_ticks`, `periods_highs`, `counter_ticks`, `counter_highs`,
  `counter_periods`, `reg_up`, or `reg_up_down`.
- `p2smart.counter_variant(pin, mode_name)` returns a `Counter` with a named
  setup-only counter/timer mode.
- `p2smart.counter_variant_sample_probe(pin, mode_name, wait_us)` returns a
  result-shaped sample diagnostic for a named counter/timer mode.
- `p2smart.counter_variant_drive_probe(out_pin, in_pin, mode_name, high_us, settle_us)`
  returns a result-shaped GPIO-drive to named-counter jumper diagnostic.
- `p2smart.counter_variant_drive_modes_probe(out_pin, in_pin, modes, high_us, settle_us)`
  runs `counter_variant_drive_probe(...)` for a named mode list, defaulting to
  the hardware-safe `["count_highs"]`, and reports per-mode failures. The
  focused native counter smoke verifies both `count_highs` and single-edge
  `count_rises` loopback on all documented jumper directions, plus limited
  `high_ticks` advancement on the `0-1` jumper in both directions. It also
  records a diagnostic zero-parameter four-pulse train plus a selected-input
  four-pulse proof using `minus1_a`, `X=4`, and `Y=1` for `state_ticks`,
  `events_ticks`, `periods_ticks`, `periods_highs`, `counter_ticks`,
  `counter_highs`, and `counter_periods`. Current hardware shows signed/wrapped
  `state_ticks` movement and positive selected-input event/period/counter
  results. `p2-smoke-smartpins-counter-timer-matrix` is the on-demand native
  diagnostic matrix for selected-input timer work; it repeats the same
  state/event/period/counter family over 50/100/200 us pulse groups. Current
  hardware reports stable positive observations but no useful scaling between
  those pulse widths with the current `minus1_a`, `X=pulses`, `Y=1` setup, so
  calibrated timing interpretation remains open.
- `p2smart.counter_timer_calibration_policy()` returns the explicit timer-family
  calibration boundary: raw selected-input observations are diagnostic, but
  microsecond scaling, absolute frequency, mode-to-unit mapping, and jitter
  bounds are not implemented.
- `p2smart.counter_timer_calibrated_probe(out_pin, in_pin, mode_name, pulse_us, pulses)`
  validates pins, mode name, pulse width, and pulse count, then raises
  `unsupported_error` so code cannot accidentally treat raw timer-family
  samples as calibrated measurements.
- `p2smart.normal_pin(pin, mode, value)` returns a setup-only `NormalPin` that
  explicitly starts smart-pin normal mode, then uses the normal GPIO read/write
  helpers. Use `read_result()` and `write_result(value)` for result-shaped normal-pin diagnostics.
- `p2-smoke-smartpins-normal-pin` is the quick hardware normal-mode check. It
  stages only `tests/p2/smoke_smartpins_normal_pin.be`, uses native `p2.smart`
  directly, and verifies high/low readback over the documented `0-1` jumper
  without source-loading `modules/p2smart.be`.
- `p2smart.gpio_input(pin)` returns a `GPIOInput`.
  Use `read_result()` for result-shaped GPIO input diagnostics.
- `p2smart.gpio_output(pin, value)` returns a `GPIOOutput`.
  Use `write_result(value)` and `toggle_result()` for result-shaped GPIO output diagnostics.
- `p2smart.gpio_loopback_probe(out_pin, in_pin, values, settle_us)` returns a
  result-shaped diagnostic for a GPIO output-to-input jumper check.
- `p2smart.jumper_pair_probe(out_pin, in_pin)` returns a compact diagnostic
  bundle for one physically jumped pair: raw helper probes on both pins, GPIO
  loopback, high-counter, pulse-counter, transition-counter, async serial
  setup/query, and bounded async serial drain. It reports `count`, `ok_count`,
  `checks`, `failed_count`, and `failed_checks`; if a sub-check raises, that
  sub-result is returned as an error map with `cleanup_attempted`, both pins are
  cleared/floated, and the remaining sub-checks still run.
- `p2smart.jumper_pair_checks()` returns the current ordered sub-check names
  used by `jumper_pair_probe(...)` without touching hardware.
- `p2smart.jumper_pairs_probe(pairs)` runs `jumper_pair_probe(...)` across a
  list of two-pin lists, such as `[[0, 1], [2, 3], [4, 5], [6, 7]]`, and
  reports `count`, `ok_count`, `failed_count`, `failed_pairs`, and per-pair
  `failures` with pair-level counts and failed sub-check names. Missing fields
  in a failed pair result are normalized to stable defaults.
- `p2smart.default_jumper_pairs()` returns a fresh copy of the documented
  diagnostic jumper pairs `[[0, 1], [2, 3], [4, 5], [6, 7]]`.
- `p2smart.default_jumper_directions()` returns a fresh bidirectional direction
  list for the documented jumper pairs without running probes.
- `p2smart.default_clocked_jumper_groups()` returns a fresh list of four-pin
  sync-serial diagnostic groups for the documented jumpers: data `0-1` with
  clock `2-3`, and data `4-5` with clock `6-7`.
- `p2smart.default_jumper_pairs_probe()` runs the one-way aggregate probe across
  the documented jumper set.
- `p2smart.jumper_pairs_bidirectional_probe(pairs)` expands each pair into both
  directions before running `jumper_pairs_probe(...)`.
- `p2smart.default_jumper_pairs_bidirectional_probe()` runs the bidirectional
  aggregate probe across the documented jumper set.
- `p2smart.repository(pin, value, mode)` returns a `Repository`.
  Use `read_result()` and `write_result(value, settle_us=nil)` for result-shaped
  repository diagnostics, or `repository_probe(pin, first_value, second_value, settle_us)`
  for a start/read/write/read/clear probe.
- `p2smart.pwm(pin, frame, duty, divisor, mode)` returns a `PWM`.
  Use `set_duty_result(duty, settle_us=nil)` for result-shaped duty update diagnostics.
- `p2smart.pwm_counter_probe(out_pin, in_pin, frame, duty, divisor, settle_us)`
  returns a result-shaped PWM-output to rise-counter jumper diagnostic.
- `p2smart.pwm_mode(name)` builds a setup-only PWM mode word from
  `triangle`, `sawtooth`, or `smps`.
- `p2smart.pwm_variant(pin, frame, duty, divisor, mode_name)` returns a `PWM`
  with a named setup-only PWM mode.
- `p2smart.pwm_variant_counter_probe(out_pin, in_pin, frame, duty, divisor, mode_name, settle_us)`
  returns a result-shaped named-PWM-mode output to rise-counter jumper diagnostic.
- `p2smart.pwm_duty_shape_probe(out_pin, in_pin, frame, low_duty, high_duty, divisor, mode_name, sample_us, settle_us)`
  compares low/high PWM duty settings through a `count_highs` jumper measurement.
  `mode_name` may be `triangle`, `sawtooth`, or `smps`.
- `p2-smoke-smartpins-output-modes` is the quick native `p2.smart` output-mode
  hardware check. It stages only `tests/p2/smoke_smartpins_output_modes.be` and
  proves counter-visible PWM triangle/sawtooth/SMPS, NCO frequency, pulse, and
  transition output on the documented `0-1` jumper, and compares low/high duty
  settings for PWM triangle, sawtooth, and SMPS with `count_highs`. The same smoke now proves
  counter-visible NCO-duty output with the ROM-correct `X=1`,
  `Y=0x40000000` setup, reports `P2_SMOKE_NCO_DUTY_NATIVE <positive delta>`,
  and compares `0x20000000` versus `0x60000000` duty settings with
  `count_highs`, expecting the high-duty sample to count higher.
- `p2smart.nco(pin, bit_period, increment, mode)` returns an `NCO`.
  Use `set_increment_result(increment, settle_us=nil)` for result-shaped frequency-step diagnostics.
- `p2smart.nco_counter_probe(out_pin, in_pin, bit_period, increment, settle_us)`
  returns a result-shaped NCO-output to rise-counter jumper diagnostic.
- `p2smart.nco_duty(pin, prescaler, duty, mode)` returns a verified `NCODuty`.
  Use `set_duty_result(duty, settle_us=nil)` for result-shaped NCO duty diagnostics.
  `info()` also includes compatibility `bit_period` and `value` fields matching
  the prescaler and duty value.
- `p2smart.nco_duty_counter_probe(out_pin, in_pin, prescaler, duty, settle_us)`
  returns a result-shaped NCO-duty output to rise-counter jumper diagnostic.
- `p2smart.nco_duty_waveform_probe(out_pin, in_pin, prescaler, low_duty, high_duty, sample_us, settle_us)`
  returns a result-shaped high-counter comparison for two duty values. It is an
  uncalibrated waveform-shape diagnostic: it proves the duty setting changes
  measured high time on a jumper, not oscilloscope-grade pulse shape.
  `p2-smoke-smartpins-nco-duty-diag` is the focused source-wrapper entrypoint;
  with prescaler `1` and duty `0x40000000`, the current `0-1` jumper path is
  expected to report a positive delta.
- `p2smart.quadrature(pin_a, pin_b, mode)` returns a setup-only `Quadrature`.
  Use `sample_after(wait_us)` for before/after position, movement, and direction diagnostics.
- `p2smart.quadrature_sample_probe(pin_a, pin_b, mode, wait_us)` returns a
  result-shaped quadrature sample diagnostic with setup and cleanup.
  `p2-smoke-smartpins-quadrature-diag` is the focused diagnostic-only
  entrypoint; on the current `0-1` jumper it reports
  `P2_SMOKE_QUADRATURE_DIAG 0 0 0 0 false setup_only`, so static one-pair
  checks stay honest.
- `p2-smoke-smartpins-quadrature-motion` drives pins `0` and `2` into
  quadrature inputs `1` and `3` using the documented `0-1` and `2-3`
  jumpers. The quick smoke uses native `p2.smart` directly, validates synthetic
  forward and reverse motion with deltas `8` and `-8`, and proves direction
  handling without source-loading `modules/p2smart.be` or using a mechanical
  encoder.
- `p2smart.quadrature_mechanical_policy()` reports the explicit real-encoder
  boundary. `p2smart.quadrature_mechanical_encoder(pin_a, pin_b, mode)`
  validates the same pin/mode shape as `quadrature(...)`, then raises
  `unsupported_error` until debounce/noise/missed-step behavior is validated
  with actual mechanical encoder hardware.
- `p2smart.pulse(pin, high_ticks, low_ticks, count, mode)` returns a `Pulse`.
- `p2smart.transition(pin, width, count, mode)` returns a `Transition`.
  Use `trigger_result(count, settle_us=nil)` on either wrapper for result-shaped trigger diagnostics.
- `p2smart.pulse_counter_probe(out_pin, in_pin, high_ticks, low_ticks, count, settle_us)`
  and `p2smart.transition_counter_probe(out_pin, in_pin, width, count, settle_us)`
  return result-shaped output-to-rise-counter jumper diagnostics.
- `p2smart.adc(pin, mode, sample_ticks)` returns an `ADC`.
  Use `read_result()` or `sample_after(wait_us)` for readiness plus raw-value diagnostics.
- `p2smart.adc_mode(source, family)` builds a setup-only ADC mode word from
  sources/gains `1x`, `gio`, `vio`, `float`, `3x`, `10x`, `30x`, `100x` and
  families `adc`, `adc_ext`, or `adc_scope`.
- `p2smart.adc_variant(pin, source, family, sample_ticks)` returns an `ADC`
  with a named setup-only ADC mode.
- `p2smart.adc_variant_sample_probe(pin, source, family, sample_ticks, wait_us)`
  returns a result-shaped sample diagnostic for a named ADC mode.
- `p2smart.adc_variant_dac_sampled_probe(out_pin, in_pin, low_value, high_value, source, family, sample_ticks, settle_us, threshold, samples, sample_interval_us)` returns a sampled DAC-to-named-ADC diagnostic with low/high sample statistics and uncalibrated polarity metadata.
- `p2smart.dac(pin, value, frame, mode)` returns a `DAC`.
  Use `set_result(value, settle_us=nil)` for result-shaped write diagnostics.
- `p2smart.dac_mode(resistor, dither)` builds a setup-only DAC mode word
  from named options: `990r_3v`, `600r_2v`, `124r_3v`, `75r_2v`, and
  `dither_pwm`, `dither_rnd`, `noise`, or `plain`.
- `p2smart.dac_variant(pin, value, frame, resistor, dither)` returns a `DAC`
  with a named setup-only DAC mode.
- `p2smart.dac_adc_probe(out_pin, in_pin, low_value, high_value, settle_us, threshold)` returns a diagnostic map for a DAC-to-ADC jumper check.
- `p2smart.dac_adc_sampled_probe(out_pin, in_pin, low_value, high_value, settle_us, threshold, samples, sample_interval_us)` returns a multi-sample DAC-to-ADC diagnostic with low/high sample statistics and uncalibrated polarity metadata.
- `p2smart.dac_variant_adc_probe(out_pin, in_pin, low_value, high_value, frame, resistor, dither, settle_us, threshold)` returns the same diagnostic shape for a named DAC mode.
- `p2smart.dac_variant_adc_sampled_probe(out_pin, in_pin, low_value, high_value, frame, resistor, dither, settle_us, threshold, samples, sample_interval_us)` returns the sampled diagnostic shape for a named DAC mode.
- `p2smart.adc_dac_variants_sampled_probe(out_pin, in_pin, low_value, high_value, source, family, sample_ticks, frame, resistor, dither, settle_us, threshold, samples, sample_interval_us)` returns the sampled diagnostic shape for combined named ADC and named DAC modes.
- `p2smart.async_serial_pair(tx_pin, rx_pin, baud, bits, tx_mode, rx_mode)` returns an `AsyncSerialPair`.
- `p2smart.async_serial_pair_ticks(tx_pin, rx_pin, bit_ticks, bits, tx_mode, rx_mode)` returns an `AsyncSerialPair`.
- `AsyncSerialPair.read_available_results(max_count=nil)` drains up to
  `max_count` currently-ready RX events, acknowledges each consumed event, and
  returns a result map with `values`, per-byte `results`, `count`, `acked`, and
  `stopped_reason`. `read_available(max_count=nil)` returns only the drained
  byte values. These helpers are bounded polling helpers, not a background FIFO.
- `p2smart.async_serial_probe(tx_pin, rx_pin, values, wait_us, baud, bits)`
  returns a conservative send/query/ack/clear diagnostic for async serial jumper checks,
  including `ready_count` across the sent bytes.
- `p2smart.async_serial_drain_probe(tx_pin, rx_pin, value, wait_us, baud, bits, max_count)`
  sends one byte, waits, drains currently-ready RX events with
  `read_available_results(max_count)`, clears the pins, and reports whether the
  first drained byte matched the sent byte.
- `p2smart.async_serial_burst_probe(tx_pin, rx_pin, values, wait_us, baud, bits)`
  sends byte values without inter-byte pacing, waits once, samples one RX value,
  and reports whether that value matches the latest byte. It is a diagnostic for
  the current single-sample/no-FIFO receive model, not a buffered receive API.
- `p2smart.async_serial_buffered_pair(tx_pin, rx_pin, baud, bits, depth)`
  validates the requested pins, serial format, and buffer depth, then raises
  `unsupported_error`. It exists so code that asks for true background RX
  buffering fails clearly instead of silently using latest-sample semantics.
- `p2smart.sync_serial_pair(tx_pin, rx_pin, baud, bits, tx_mode, rx_mode)` returns a verified clocked `SyncSerialPair`. Use `transfer_result(value, wait_us, clock=nil)` or `transfer_results(values, wait_us, clock=nil)` for result-shaped sync-serial probes; pass a `p2smart.Pulse` clock when the receive side needs a triggered external clock.
- `p2smart.sync_serial_probe(tx_pin, rx_pin, values, wait_us, baud, bits)`
  returns a staged start/transfer/clear diagnostic using the default sync TX/RX modes.
- `p2smart.sync_serial_clocked_probe(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin, values, wait_us, baud, bits)`
  returns a staged diagnostic for data and clock jumper pairs such as data `0-1`
  plus clock `2-3`; sync probes include `ready_count`, `matched_count`,
  `tx_mode`, `rx_mode`, `clock_mode`, `receive_status`, and `receive_policy`.
- `p2smart.sync_serial_clocked_variant_probe(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin, values, wait_us, baud, bits)`
  tries normal clocking plus inverted RX-clock and inverted clock-output
  variants, reporting the exact TX, RX, and clock modes used for every attempt.
- `p2smart.sync_serial_clocked_jumper_probes(groups, values, wait_us, baud, bits)`
  runs the four-pin sync-serial diagnostic across explicit groups and reports
  `count`, `ok_count`, `failed_count`, `failed_groups`, and per-group failures.
- `p2smart.sync_serial_clocked_jumper_variant_probes(groups, values, wait_us, baud, bits)`
  runs the multi-variant sync-serial diagnostic across explicit four-pin groups.
- `p2smart.sync_serial_default_clocked_probe(values, wait_us, baud, bits)` runs
  the four-pin sync-serial diagnostic across the default clocked jumper groups.
- `p2smart.sync_serial_default_clocked_variant_probe(values, wait_us, baud, bits)`
  runs the multi-variant diagnostic across the default clocked jumper groups.

`p2smart.capabilities()` returns a status map for the current wrapper surface.
`p2smart.statuses()` lists the valid status strings,
`p2smart.status_known(status)` checks one, `p2smart.status(name)` returns the
exact status for one capability name or `nil` for an unknown name, and
`p2smart.names()` / `p2smart.names_by_status(status)` enumerate capability
names. `p2smart.required_capability_keys()` returns the required smart-pin
metadata surface. `p2smart.items_by_status(status)` is the status-filtered
compatibility alias. `p2smart.audit()`, `audit_problems()`, and `audit_ok()`
provide a metadata self-check for duplicate capability names, unknown statuses,
missing required capability keys, and count consistency, and also verifies that
the `jumper_pair_probe(...)` sub-check list contains the required unique entries. `p2smart.async_serial_buffer_policy()` returns the explicit
current UART receive-buffer contract: no background FIFO/buffer ownership is
implemented, direct smart-pin sample, latest-byte burst diagnostics, and bounded
drain helpers remain the safe receive path, and cleanup is required after use.
`p2smart.async_serial_buffered_pair(...)` is the explicit unsupported entrypoint
for code that requires a true background FIFO.
The on-demand `p2-smoke-smartpins-async-buffer-boundary` target stages only the
native `tests/p2/smoke_smartpins_async_buffer_boundary.be` file and confirms
that paced bytes `17`, `34`, `51`, and `68` read back on jumper `0->1`; an
unpaced burst samples the latest value `68`, while bounded draining reports
diagnostic current-event behavior rather than a real FIFO.
`p2smart.adc_dac_delta_policy()`
returns the current analog boundary: DAC-to-ADC sampled jumper probes are
available and statused as verified sampled-loopback coverage, but calibrated
voltage, polarity, and threshold assertions remain unverified.
`p2smart.adc_dac_calibrated_probe(out_pin, in_pin, low_value, high_value, min_mv)`
validates the requested pins, DAC values, and minimum millivolt delta, then
raises `unsupported_error` until voltage/polarity calibration is backed by
hardware evidence.
`p2smart.counter_timer_calibration_policy()` returns the matching timer/counter
boundary: selected-input state/event/period/counter observations can be recorded,
but calibrated time or frequency conversion is not yet supported.
`p2smart.usb_pair_policy()` returns the explicit USB smart-pin boundary:
`p2.smart.usb_pair` is a raw mode constant only, and Berry does not yet own a
USB packet, HID, host, or device stack. `p2smart.usb_pair_probe(pin_a, pin_b)`
validates pin arguments and then raises `unsupported_error` instead of silently
pretending USB is implemented. Backed jumper-verified helpers report
`verified`; setup-only or explicitly open areas such as `sync_serial_receive`,
`adc_dac_delta`, `adc_dac_calibrated_probe`, `async_serial_buffer`,
`usb_pair`, and `usb_pair_probe` report `unverified` or `unsupported`,
while sync-serial transfer diagnostics report
`staged`. `p2smart.status_report()`
groups the same facts into `verified`, `staged`, and `open` lists for
diagnostics.

The wrappers provide `start()`, `clear()`, and `info()` methods, plus
GPIO read/write/toggle helpers, GPIO loopback probes, and result diagnostics, setup-only normal-pin helpers, counter mode helpers, counter read/query/ack, named counter sample probes, GPIO-high counter probes, repository read/write/probe helpers, quadrature sample probes, PWM mode helpers, named-PWM/NCO/NCO-duty/pulse/transition-to-counter probes, PWM/NCO/NCODuty/pulse/transition update
helpers, ADC mode helpers, ADC read/query/ack helpers, named ADC sample probes, DAC `set(value)` plus named DAC mode and DAC-variant-to-ADC probe helpers, async serial probe/send/query/read-byte helpers including
`send_bytes(values, inter_byte_us)`, `read_result()`, `read_byte_after(wait_us)`,
`read_result_after(wait_us)`, `exchange_bytes_after(values, wait_us)`, and
`exchange_results_after(values, wait_us)`, and bounded sync serial
setup/send/raw-read helpers including `read_result()`, `sync_serial_probe(...)`,
`sync_serial_clocked_probe(...)`, `sync_serial_clocked_jumper_probes(...)`,
`sync_serial_default_clocked_probe(...)`, `read_result_after(wait_us)`,
`transfer_result(value, wait_us, clock=nil)`, and
`transfer_results(values, wait_us, clock=nil)` diagnostics. Pass `nil` for optional
arguments to use the conservative defaults. They are thin setup helpers, not a
claim that every smart-pin mode family is finished.

Synchronous serial is validated for the clocked jumper path. The P2 ROM notes
describe sync serial as `A=data, B=clock`; a simple two-pin TX/RX jumper is not
enough to prove receive data. `p2smart.sync_serial_receive_policy()` reports the
current boundary: clocked receive is validated for the documented `0-1` data and
`2-3` clock jumpers using sync X `(bits-1)|0x20`. RX raw words are left-aligned,
so result helpers decode by shifting down `32-bits`. The focused native sync
diagnostic executes one normal clocked attempt plus one bounded observation for
each normal/inverted clock phase variant; current hardware reports
`P2_SMOKE_SYNC_CLOCKED 1 1 true` and three matched variants. The
user-facing `examples/sync_serial_loopback.be` uses native `p2.smart` constants
directly so it can show the documented `0-1` data and `2-3` clock mode plan
quickly without importing the large `p2smart` source module. The older
`examples/spi_loopback.be` name remains as a compatibility alias for the same
synchronous-serial jumper diagnostic. The clocked mode-planning helpers report
the exact TX/RX/clock smart-pin modes and policy/status fields used for
diagnostics. The default sync diagnostic smoke covers that policy,
safe setup/readiness, clock-mode planning, and the bounded native variant
observations.
Variant helpers report normal and inverted clock-sampling/output modes and
return `execution_deferred` with the same policy/status shape instead of
running the unbounded source-wrapper aggregate TX/RX path by default. Broader
SPI framing beyond the one-word clocked jumper proof remains open.

## Mode-family roadmap

The TODO list still requires researched wrappers and tests for the remaining
smart-pin mode depth: calibrated ADC scaling/filtering/delta assertions, DAC
noise/random/mode calibration, mechanical quadrature behavior, calibrated
register-counter interpretation, true buffered serial RX, and a future USB
stack if that becomes a supported target.

## Policy

Do not fake smart-pin mode coverage. A mode family is done only when the constants, wrapper behavior, docs, and smoke/hardware coverage are present or the limitation is explicitly documented.
