# P2 Hardware Test Guide

## Required board variant notes

Always record the board and profile before running hardware tests:

- `P2_BOARD=p2edge`, no PSRAM, LEDs on pins `56` and `57`.
- `P2_BOARD=p2edge32`, 32 MB RAM, LEDs on pins `38` and `39`, PSRAM pins `40..57` reserved.
- `P2_PROFILE=full`, `edge32`, or `xmm`.
- `P2_SILICON=latest`, `b`, `c`, or `a`.

Current focused hardware work normally uses `/dev/ttyUSB0` at `230400` baud
with the native sibling Catalina checkout:

```sh
make <target> PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
```

Do not use pins reserved by the active profile. The current Catalina XMM P2
Edge 32 MB profile reserves pins `40..57` for PSRAM, keeps the user LED
examples on pins `38` and `39`, and leaves pins `0..7` available for the
documented smart-pin loopback harness.

## Reserved pins

- SD: pins `58..61`.
- Serial console: pins `62..63`.
- PSRAM builds: pins `40..57`.

Tests must skip or fail clearly when a requested test pin is reserved by the selected board.

## Loopback wiring

Use short jumpers and document exact pins for each loopback test:

- Current smart-pin jumper harness: connect `0-1`, `2-3`, `4-5`, and `6-7`
  with short direct jumpers. These pairs are used by the focused smart-pin
  smokes for GPIO, normal smart-pin mode, counters, PWM/NCO/pulse/transition
  output into counters, async serial, bounded clocked sync serial diagnostics, and
  DAC-output to ADC-input diagnostics.
- Current sync-serial diagnostic groups: use `0-1` as the data pair with
  `2-3` as the clock pair, and `4-5` as the data pair with `6-7` as the clock
  pair.
- UART loopback: connect TX to RX through a short jumper on non-reserved pins.
- SPI loopback: connect MOSI to MISO for raw transfer smoke, or document the attached SPI device and expected response.
- I2C: use pull-ups suitable for the bus voltage; existing BMP180 coverage uses `SCL=25`, `SDA=24`.
- Quadrature: document the encoder or signal source and pin pair.

## Required resistors and electrical notes

- I2C requires pull-ups unless the attached board provides them.
- LEDs need current limiting unless they are onboard LEDs.
- The current `0-1`, `2-3`, `4-5`, and `6-7` digital loopback smokes assume
  direct jumpers with no series resistors. They must configure only one side as
  a driven output at a time and clear/float pins during cleanup.
- DAC-to-ADC diagnostics may reuse the same direct jumpers, but they are
  diagnostic only: they record integer samples and polarity metadata, and do
  not prove calibrated voltage, stable polarity, or nonzero low/high movement.
- Avoid direct contention between two driven outputs.
- Confirm voltage compatibility for attached modules.

## Skipped tests

When hardware is unavailable, record the skip with board, missing wiring/device, and the exact test that was skipped. Do not mark a hardware feature verified from a skipped test.

Current intentional diagnostic-only or skipped smart-pin areas:

- ADC/DAC calibrated voltage scaling and stable polarity remain unverified on
  the current direct-jumper setup. The focused native ADC/DAC smoke does verify
  nonzero raw low/high movement on jumper `0-1`.
- NCO-duty calibrated waveform shape remains outside this harness. The focused
  native output-mode smoke does verify uncalibrated high-time movement by
  comparing low and high duty values on jumper `0-1`.
- Quadrature setup/read/clear is covered with a static jumper, and synthetic
  motion/direction is covered by driving pins `0` and `2` into inputs `1` and
  `3`; mechanical encoder behavior remains open.
- Sync serial setup and bounded transfer diagnostics include a matched one-word
  clocked receive proof on the `0-1` data and `2-3` clock jumpers. Broader SPI
  framing remains open.
- USB/HID and VGA examples report unsupported or setup-only status unless
  matching hardware and a real implementation are present.

## Runnable entrypoints

```sh
export PORT=/dev/ttyUSB0
export TOOLCHAIN=catalina
export CATALINA_DIR=../Catalina

make test-p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0 BOARD=p2edge32
make soak-p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0 BOARD=p2edge32 HOURS=1
```

These are the standard scripted smoke/soak entrypoints once the board is already at a Berry prompt and the serial port is known.

For current focused smart-pin checks, prefer the narrow targets instead of the
broad suite:

```sh
make p2-smoke-smartpins-normal-pin PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
make p2-smoke-smartpins-counter-modes PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
make p2-smoke-smartpins-counter-timer-matrix PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
make p2-smoke-smartpins-adc-variant-matrix PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
make p2-smoke-smartpins-adc-dac-diag PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
make p2-smoke-smartpins-async-rx PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
make p2-smoke-smartpins-async-buffer-boundary PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
make p2-smoke-smartpins-sync-diag PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
make p2-smoke-smartpins-quadrature-static PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
make p2-smoke-smartpins-quadrature-motion PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
make p2-smoke-smartpins-quadrature-diag PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
make p2-smoke-smartpins-nco-duty-diag PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina
```
