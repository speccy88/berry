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

## Mode-family roadmap

The TODO list still requires researched constants and tests for the smart-pin mode families: dumb pin, repository mode, DAC modes, pulse/cycle, transition, NCO, PWM, quadrature, counters, ADC, USB pair modes, and serial TX/RX modes.

## Policy

Do not fake smart-pin mode coverage. A mode family is done only when the constants, wrapper behavior, docs, and smoke/hardware coverage are present or the limitation is explicitly documented.
