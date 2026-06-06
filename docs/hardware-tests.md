# P2 Hardware Test Guide

## Required board variant notes

Always record the board and profile before running hardware tests:

- `P2_BOARD=p2edge`, no PSRAM, LEDs on pins `56` and `57`.
- `P2_BOARD=p2edge32`, 32 MB RAM, LEDs on pins `38` and `39`, PSRAM pins `40..57` reserved.
- `P2_PROFILE=full`, `edge32`, or `xmm`.
- `P2_SILICON=latest`, `b`, `c`, or `a`.

## Reserved pins

- SD: pins `58..61`.
- Serial console: pins `62..63`.
- PSRAM builds: pins `40..57`.

Tests must skip or fail clearly when a requested test pin is reserved by the selected board.

## Loopback wiring

Use short jumpers and document exact pins for each loopback test:

- UART loopback: connect TX to RX through a short jumper on non-reserved pins.
- SPI loopback: connect MOSI to MISO for raw transfer smoke, or document the attached SPI device and expected response.
- I2C: use pull-ups suitable for the bus voltage; existing BMP180 coverage uses `SCL=25`, `SDA=24`.
- Quadrature: document the encoder or signal source and pin pair.

## Required resistors and electrical notes

- I2C requires pull-ups unless the attached board provides them.
- LEDs need current limiting unless they are onboard LEDs.
- Avoid direct contention between two driven outputs.
- Confirm voltage compatibility for attached modules.

## Skipped tests

When hardware is unavailable, record the skip with board, missing wiring/device, and the exact test that was skipped. Do not mark a hardware feature verified from a skipped test.

## Runnable entrypoints

```sh
make test-p2 PORT=/dev/cu.usbserial-P97cvdxp BOARD=p2edge32
make soak-p2 PORT=/dev/cu.usbserial-P97cvdxp BOARD=p2edge32 HOURS=1
```

These are the standard scripted smoke/soak entrypoints once the board is already at a Berry prompt and the serial port is known.
