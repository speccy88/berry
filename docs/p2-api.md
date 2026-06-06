# P2 API Reference Snapshot

## Main native module

`p2` is the friendly hardware namespace. It exposes flat compatibility names and grouped submodules.

## Grouped APIs

- `p2.clock`: clock frequency/mode, counter reads, waits, and `hubset`.
- `p2.cog`: current cog, cog check/stop, and attention helpers.
- `p2.lock`: hardware lock allocation/check/release helpers.
- `p2.pin`: GPIO direction/output/input helpers with board-reserved pin validation.
- `p2.cordic`: `rotxy`, `polxy`, and `xypol` helpers.
- `p2.math`: low-level integer math helpers.
- `p2.rng`: random helper.
- `p2.smart`: raw smart-pin register helpers.
- `p2.asm`: safe PASM-adjacent intrinsics only: `getrnd`, `getct`, `waitx`, and `hubset`.
- `p2.debug`: backed diagnostics for heap, GC, cogs, memory map, pins, smart pins, registers, and snapshots.

## Filesystem and memory diagnostics

- `p2.fs_info(path="/", write_probe=false)` reports SD mount, FAT, root, path, and optional write-probe state.
- `p2.psram_info()`, `p2.psram_read()`, `p2.psram_write()`, and `p2.psram_test()` expose bounded PSRAM block access when available.
- `p2.heap_info()` reports current Hub/XMM heap counters.

## Error policy

Board-reserved pins, invalid cog IDs, invalid lock IDs, and negative unsigned low-level arguments should raise clear errors before touching hardware.

## Cooperative IPC facade

Import `p2ipc` to attach cooperative Hub-memory IPC helpers to `p2`:

- `p2.channel.new(depth=8)` returns an object with `send(value)`, `recv(timeout_ms=nil)`, `size()`, `free()`, and `close()`.
- `p2.mailbox.new()` returns a one-slot mailbox with `put(value)`, `get()`, `ready()`, and `close()`.
- `p2.shared.Buffer(size)` returns a bounded byte buffer with `read`, `write`, `fill`, `size`, and `aslist`.
- `p2.mutex.new()` returns a mutex that uses `p2.lock` hardware locks when available and falls back to a cooperative in-VM lock otherwise.

These objects are cooperative current-VM objects. They do not yet wake other cogs with cog attention or provide cross-VM serialization.
