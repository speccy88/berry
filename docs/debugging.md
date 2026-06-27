# P2 Debugging

## Current query-based diagnostics

Use structured query APIs instead of noisy boot-time prints where possible:

- `p2.status_info()` and `p2.debug_snapshot()` for build/runtime overview.
- `p2.fs_info()` for SD/FAT/path diagnostics.
- `p2.psram_info()` and `p2.psram_test()` for PSRAM tier diagnostics.
- `p2mem.stats()`, `p2mem.stats_result()`, `p2mem.modules()`, `p2mem.modules_result()`, `p2mem.module_result(name)`, `p2mem.cache()`, `p2mem.cache_result()`, `p2mem.gc()`, `p2mem.gc_result()`, and `p2mem.evict()` for memory/cache diagnostics. Use result helpers when tooling needs `ok/error/message` reporting instead of a thrown lower-level diagnostic failure. Cache item diagnostics expose source-cache byte counts, hit/miss counters, `last_used`, and `chunk_count`.
- `p2.debug.heap()`, `gc()`, `cogs()`, `memory_map()`, `pins()`, `smartpin(pin)`, and `registers(cog=nil)` for backed debug snapshots.
- `p2.debug.capabilities()` and `p2.debug.capability(name)` for the backed/unsupported debug boundary. Current backed entries are snapshot, heap, GC, cogs, memory map, pin snapshots, smart-pin snapshots, and current-cog register snapshots; breakpoints, trace controls, source stack traces, native error detail, module-cache internals, task/lock/channel internals, and PASM single-step report unsupported.

## Debug build and trace flags

The flags `BE_P2_DEBUG`, `BE_P2_TRACE_IMPORTS`, `BE_P2_TRACE_GC`, `BE_P2_TRACE_COGS`, and `BE_P2_TRACE_TASKS` are documented policy gates. Their future implementations must default off and avoid perturbing serial, memory, and timing unless explicitly enabled.

## Open debugger features

Breakpoints, trace controls, Berry source stack traces, native error detail, module-cache internals, task internals, lock/channel internals, and PASM single-step support remain open. Code that needs to branch on the current boundary should use `p2.debug.capability(name)` instead of probing for hidden stubs.
