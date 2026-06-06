# Current P2 Limitations

This file is intentionally direct. It is better to document an unsupported feature than to ship a stub that silently pretends to work.

## Not complete yet

- Full upstream Berry language and module coverage is not complete.
- `input()` needs non-blocking or manual serial coverage.
- `.bec` bytecode loading, freshness checks, and compile-to-cache behavior remain open.
- COMPACT Edge32 does not store arbitrary live Berry GC objects in PSRAM.
- Real module cache hit/miss, refcount, pinned, hash, mtime, and last-used metadata remain open.
- Smart-pin mode-family constants and high-level wrappers remain open.
- High-level ADC, DAC, PWM, timer, quadrature, UART, SPI, and USB wrappers remain open.
- VGA/video and USB keyboard/mouse demos are planned, not faked.
- PASM blobs, arbitrary assembly, and PASM function bridges remain open.
- Real closure-based cog spawning with independent VM/heap/GC semantics remains open.
- `p2.channel`, `p2.mailbox`, `p2.shared.Buffer`, and `p2.mutex` remain open.
- Stackful cooperative tasks or proven coroutine/continuation mechanisms remain open.
- Breakpoints, tracing, source stack traces, and PASM single-step remain open.

## Board caveats

- Pin `57` is an LED only on the no-PSRAM P2 Edge profile. It is PSRAM chip-select on PSRAM builds.
- Pins `58..61` are SD-card pins.
- Pins `62..63` are serial-console pins.
- Pins `40..57` are reserved in PSRAM builds.

## Policy

No stub should silently pretend to work. Unsupported APIs should be absent, documented, or raise clear errors.
