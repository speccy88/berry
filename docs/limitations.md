# Current P2 Limitations

This file is intentionally direct. It is better to document an unsupported feature than to ship a stub that silently pretends to work.

## Not complete yet

- Full upstream Berry language and module coverage is not complete.
- `input()` is still an interactive serial operation, but the scripted `compat`
  smoke covers prompt/response behavior.
- `try/except` execution can hang the current normal P2 image. The user-facing
  `examples/core/exception.be` file reports this limitation and exits instead
  of exercising the unsafe path.
- Line-start `for` iterator loops can hang the current normal P2 image in some
  file/list/range paths. User-facing examples use bounded indexed `while`
  loops instead, and `make p2-example-safety-audit` rejects new example-level
  `for` loops.
- P2 rejects host-generated `.bec` files as `incompatible_bytecode_vm` because the host VM uses different integer/float sizes than the P2 VM, and it rejects matching-size bytecode with a mismatched builtin table as `incompatible_bytecode_builtins`. Preferred `.bec` loading on P2 still needs P2-compatible bytecode generation, and default P2 builds still cannot emit `.be` to `.bec` cache files because bytecode saving is disabled.
- COMPACT Edge32 does not store arbitrary live Berry GC objects in PSRAM.
- Real module cache hit/miss, refcount, pinned, hash, mtime, and last-used metadata remain open.
- Some smart-pin mode-family constants and hardware validation paths remain open.
- Calibrated ADC/DAC behavior, calibrated timer/counter interpretation, mechanical quadrature encoder behavior, and true UART RX buffering remain open. Synthetic quadrature motion/direction and bounded clocked synchronous-serial receive are covered with the documented jumpers. `p2smart.adc_dac_calibrated_probe(...)`, `p2smart.quadrature_mechanical_encoder(...)`, and the matching policy helpers report those explicit unsupported/unverified boundaries instead of faking calibrated behavior.
- VGA/video output and USB keyboard/mouse/HID support are explicitly unsupported in the current default build. `p2compat` reports `video_output`, `vga_demo`, `usb_hid`, and `usb_demo` as unsupported, and the matching examples report that status instead of faking demos.
- PASM blobs, arbitrary assembly, and PASM function bridges remain open.
- Real closure-based cog spawning with independent VM/heap/GC semantics remains open. `p2compat.child_vm_transfer_policy()` and `p2compat.child_vm_live_object_transfer(...)` make live-object child-VM transfer an explicit unsupported boundary. `p2compat.child_vm_partition_policy()` exposes runtime `p2.heap_info()` partition diagnostics for sizing work, but still reports `production_count_selected == false`; production partition counts and isolated child-VM cog execution are not complete.
- `p2.channel`, `p2.mailbox`, `p2.shared.Buffer`, and `p2.mutex` are current-VM cooperative helpers only; result maps for channel/mailbox payload operations report current-VM-reference/no-serialization ownership policy. `p2ipc.contract()` reports channel/mailbox snapshot/peek diagnostics, clear/close cleanup, and shared-buffer clear support, `p2ipc.cross_cog_channel_policy()` reports the explicit unsupported cross-cog channel boundary, `p2ipc.audit_ok()` checks that the advertised IPC contract is internally consistent, and `p2ipc.self_test_result(iterations)` runs a bounded current-VM cleanup diagnostic. Cross-cog wakeups, cross-VM serialization, ownership transfer, and long stress/soak coverage remain open.
- Stackful cooperative tasks or proven coroutine/continuation mechanisms remain open.
- Breakpoints, tracing, source stack traces, and PASM single-step remain open.

## Board caveats

- Pin `57` is an LED only on the no-PSRAM P2 Edge profile. It is PSRAM chip-select on PSRAM builds.
- Pins `58..61` are SD-card pins.
- Pins `62..63` are serial-console pins.
- Pins `40..57` are reserved in PSRAM builds.

## Policy

No stub should silently pretend to work. Unsupported APIs should be absent, documented, or raise clear errors.
