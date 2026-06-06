# P2 Debugging

## Current query-based diagnostics

Use structured query APIs instead of noisy boot-time prints where possible:

- `p2.status_info()` and `p2.debug_snapshot()` for build/runtime overview.
- `p2.fs_info()` for SD/FAT/path diagnostics.
- `p2.psram_info()` and `p2.psram_test()` for PSRAM tier diagnostics.
- `p2mem.stats()`, `p2mem.modules()`, `p2mem.cache()`, `p2mem.gc()`, and `p2mem.evict()` for memory/cache diagnostics.
- `p2.debug.heap()`, `gc()`, `cogs()`, `memory_map()`, `pins()`, `smartpin(pin)`, and `registers(cog=nil)` for backed debug snapshots.

## Debug build and trace flags

The flags `BE_P2_DEBUG`, `BE_P2_TRACE_IMPORTS`, `BE_P2_TRACE_GC`, `BE_P2_TRACE_COGS`, and `BE_P2_TRACE_TASKS` are documented policy gates. Their future implementations must default off and avoid perturbing serial, memory, and timing unless explicitly enabled.

## Open debugger features

Breakpoints, trace controls, Berry source stack traces, native error detail, module-cache internals, task internals, lock/channel internals, and PASM single-step support remain open.
