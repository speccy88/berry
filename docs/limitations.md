# Current P2 Limitations

This file is intentionally direct. It is better to document an unsupported feature than to ship a stub that silently pretends to work.

## Not complete yet

- Full upstream Berry language and module coverage is not complete.
- `input()` is still an interactive serial operation, but the scripted `compat`
  smoke covers prompt/response behavior.
- `.bec` bytecode execution and compile-to-cache behavior remain open; sidecar freshness manifest metadata is staged but does not enable execution.
- COMPACT Edge32 does not store arbitrary live Berry GC objects in PSRAM.
- Real module cache hit/miss, refcount, pinned, hash, mtime, and last-used metadata remain open.
- Some smart-pin mode-family constants and hardware validation paths remain open.
- Calibrated ADC/DAC behavior, broader timer/counter timing, mechanical quadrature encoder behavior, UART buffering, and synchronous-serial received-data validation remain open. Synthetic quadrature motion/direction is covered with the documented jumpers.
- VGA/video output and USB keyboard/mouse/HID support are explicitly unsupported in the current default build. `p2compat` reports `video_output`, `vga_demo`, `usb_hid`, and `usb_demo` as unsupported, and the matching examples report that status instead of faking demos.
- PASM blobs, arbitrary assembly, and PASM function bridges remain open.
- Real closure-based cog spawning with independent VM/heap/GC semantics remains open.
- `p2.channel`, `p2.mailbox`, `p2.shared.Buffer`, and `p2.mutex` are current-VM cooperative helpers only; result maps for channel/mailbox payload operations report current-VM-reference/no-serialization ownership policy. `p2ipc.contract()` reports channel/mailbox snapshot/peek diagnostics, clear/close cleanup, and shared-buffer clear support, `p2ipc.audit_ok()` checks that the advertised IPC contract is internally consistent, and `p2ipc.self_test_result(iterations)` runs a bounded current-VM cleanup diagnostic. Cross-cog wakeups, cross-VM serialization, ownership transfer, and long stress/soak coverage remain open.
- Stackful cooperative tasks or proven coroutine/continuation mechanisms remain open.
- Breakpoints, tracing, source stack traces, and PASM single-step remain open.

## Board caveats

- Pin `57` is an LED only on the no-PSRAM P2 Edge profile. It is PSRAM chip-select on PSRAM builds.
- Pins `58..61` are SD-card pins.
- Pins `62..63` are serial-console pins.
- Pins `40..57` are reserved in PSRAM builds.

## Policy

No stub should silently pretend to work. Unsupported APIs should be absent, documented, or raise clear errors.
