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

These helpers validate board-reserved pins through the shared P2 bus validation layer.
Use `p2smart.raw_smartpin_probe(pin)` for a result-shaped raw helper diagnostic
that exercises zeroed `wrpin`/`wxpin`/`wypin`, `akpin`, `rdpin`, `rqpin`,
normal-mode `start`, and `clear`.

`p2.smart` also exposes lower-case Catalina `smartpin.h` constants with the
`P_` prefix removed, for example `normal`, `pwm_triangle`, `pwm_sawtooth`,
`nco_duty`, `count_rises`, `counter_periods`, `adc_ext`, `adc_scope`,
`dac_600r_2v`, `usb_pair`, and `async_rx`. The `p2smart` source fallback keeps
the same positive-valued names available when the grouped native table is not
present. `P_INVERT_A` is not exposed yet because the current raw API rejects
bit-31 values through the signed Berry integer path.

`tests/p2/smoke_smartpins_loopback.be` is the current hardware-oriented smoke.
It assumes jumpers between pins `0-1`, `2-3`, `4-5`, and `6-7`, checks GPIO
wrapper loopback in both directions, exercises the raw smart-pin helpers, checks
repository mode on every jumper pin, and stages PWM triangle/sawtooth/SMPS,
NCO frequency, NCO-duty diagnostics, pulse, transition, rise/high counter loopback,
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
protocol helpers, not a receive FIFO. Buffered receive behavior remains open.
ADC/DAC smoke currently verifies setup, integer readback, and sampled jumper diagnostics. `p2smart.dac_adc_probe(...)`
adds a result-shaped diagnostic for a DAC pin jumpered to an ADC pin: it reports
`low_raw`, `high_raw`, signed `delta`, absolute `abs_delta`, `threshold`, `ok`,
and `reason`, then clears both pins. `p2smart.dac_adc_sampled_probe(...)`,
`p2smart.dac_variant_adc_sampled_probe(...)`, and
`p2smart.adc_variant_dac_sampled_probe(...)`, plus
`p2smart.adc_dac_variants_sampled_probe(...)`, repeat that check over multiple
low/high ADC samples and report sample lists, min/max, averages,
signed/absolute average delta, and polarity labels while still marking
`polarity_verified` and `calibrated_voltage` false. These diagnostics use
absolute delta because observed hardware direction can be board/mode dependent,
and the hardware smoke permits flat readings. The sampled helper statuses are
tracked as `verified`; `p2-smoke-smartpins-adc-dac-diag` is the focused
diagnostic-only entrypoint for this path. On the current `0-1` jumper it can
report a flat sampled observation (`low avg 0`, `high avg 0`, `delta 0`,
`polarity flat`), so calibrated voltage scaling and stable polarity/low-high
voltage assertions remain open under `adc_dac_delta`.

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
  the hardware-safe `["count_highs"]`, and reports per-mode failures. Pass an
  explicit mode list for setup/diagnostic probes such as `["count_rises"]`;
  current hardware validation for `count_rises` remains open.
- `p2smart.normal_pin(pin, mode, value)` returns a setup-only `NormalPin` that
  explicitly starts smart-pin normal mode, then uses the normal GPIO read/write
  helpers. Use `read_result()` and `write_result(value)` for result-shaped normal-pin diagnostics.
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
- `p2smart.nco(pin, bit_period, increment, mode)` returns an `NCO`.
  Use `set_increment_result(increment, settle_us=nil)` for result-shaped frequency-step diagnostics.
- `p2smart.nco_counter_probe(out_pin, in_pin, bit_period, increment, settle_us)`
  returns a result-shaped NCO-output to rise-counter jumper diagnostic.
- `p2smart.nco_duty(pin, bit_period, duty, mode)` returns a setup-only `NCODuty`.
  Use `set_duty_result(duty, settle_us=nil)` for result-shaped NCO duty diagnostics.
- `p2smart.nco_duty_counter_probe(out_pin, in_pin, bit_period, duty, settle_us)`
  returns a result-shaped NCO-duty output to rise-counter jumper diagnostic.
  `p2-smoke-smartpins-nco-duty-diag` is the focused diagnostic-only entrypoint;
  on the current `0-1` jumper it reports `P2_SMOKE_NCO_DUTY_DIAG false 0 0 0`,
  so waveform-shape validation remains open.
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
  jumpers. It validates synthetic forward and reverse motion with deltas
  `8` and `-8`, proving direction handling without a mechanical encoder.
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
- `p2smart.sync_serial_pair(tx_pin, rx_pin, baud, bits, tx_mode, rx_mode)` returns a staged `SyncSerialPair`. Use `transfer_result(value, wait_us, clock=nil)` or `transfer_results(values, wait_us, clock=nil)` for result-shaped sync-serial probes; pass a `p2smart.Pulse` clock when the receive side needs a triggered external clock.
- `p2smart.sync_serial_probe(tx_pin, rx_pin, values, wait_us, baud, bits)`
  returns a staged start/transfer/clear diagnostic using the default sync TX/RX modes.
- `p2smart.sync_serial_clocked_probe(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin, values, wait_us, baud, bits)`
  returns a staged diagnostic for data and clock jumper pairs such as data `0-1`
  plus clock `2-3`; sync probes include `ready_count` and `matched_count`.
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
implemented, direct smart-pin sample and bounded drain helpers remain the safe
receive path, and cleanup is required after use. `p2smart.adc_dac_delta_policy()`
returns the current analog boundary: DAC-to-ADC sampled jumper probes are
available and statused as verified sampled-loopback coverage, but calibrated
voltage, polarity, and threshold assertions remain unverified. Backed
jumper-verified helpers report `verified`; setup-only or explicitly open areas
such as `sync_serial_receive`, `adc_dac_delta`, `async_serial_buffer`, and
`usb_pair` report `unverified` or `unsupported`, while sync-serial transfer
diagnostics report `staged`. `p2smart.status_report()`
groups the same facts into `verified`, `staged`, and `open` lists for
diagnostics.

The wrappers provide `start()`, `clear()`, and `info()` methods, plus
GPIO read/write/toggle helpers, GPIO loopback probes, and result diagnostics, setup-only normal-pin helpers, counter mode helpers, counter read/query/ack, named counter sample probes, GPIO-high counter probes, repository read/write/probe helpers, quadrature sample probes, PWM mode helpers, named-PWM/NCO/NCO-duty/pulse/transition-to-counter probes, PWM/NCO/NCODuty/pulse/transition update
helpers, ADC mode helpers, ADC read/query/ack helpers, named ADC sample probes, DAC `set(value)` plus named DAC mode and DAC-variant-to-ADC probe helpers, async serial probe/send/query/read-byte helpers including
`send_bytes(values, inter_byte_us)`, `read_result()`, `read_byte_after(wait_us)`,
`read_result_after(wait_us)`, `exchange_bytes_after(values, wait_us)`, and
`exchange_results_after(values, wait_us)`, and staged sync serial
setup/send/raw-read helpers including `read_result()`, `sync_serial_probe(...)`,
`sync_serial_clocked_probe(...)`, `sync_serial_clocked_jumper_probes(...)`,
`sync_serial_default_clocked_probe(...)`, `read_result_after(wait_us)`,
`transfer_result(value, wait_us, clock=nil)`, and
`transfer_results(values, wait_us, clock=nil)` diagnostics. Pass `nil` for optional
arguments to use the conservative defaults. They are thin setup helpers, not a
claim that every smart-pin mode family is finished.

Synchronous serial is still staged. The P2 ROM notes describe sync serial as
`A=data, B=clock`; a simple two-pin TX/RX jumper is not enough to prove receive
data. `p2smart.sync_serial_receive_policy()` reports the current boundary:
matched receive words are not supported yet, unclocked probes can report a
constant raw sample, and the bounded clocked four-pin probe returns cleanly but
has not produced ready received data. The default sync diagnostic smoke covers
that policy, the bounded single-group result, and safe setup/readiness and
clock-mode planning checks.
Variant helpers report normal and inverted clock-sampling/output modes and
return `execution_deferred` instead of running the unbounded aggregate TX/RX
path by default. Validated sync/SPI received-data loopback remains open until a
bounded native probe or timeout-safe wrapper can show matched receive words.

## Mode-family roadmap

The TODO list still requires researched wrappers and tests for the remaining
smart-pin mode families and depth: dumb pin, ADC scaling/filtering/delta
assertions, DAC noise/random/mode variants and calibration, PWM sawtooth/SMPS,
quadrature, register counters, USB pair modes, and broader serial TX/RX modes.

## Policy

Do not fake smart-pin mode coverage. A mode family is done only when the constants, wrapper behavior, docs, and smoke/hardware coverage are present or the limitation is explicitly documented.
