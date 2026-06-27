# PSRAM Loader and Cache Model

## Current model

On `edge32`, Catalina exposes PSRAM as a bounded block-transfer API. Berry keeps live VM heap, active bytecode, stacks, prototypes, and GC-managed objects in Hub RAM. PSRAM is used as an inactive storage/cache tier through explicit reads and writes.

On `xmm`, Catalina owns the lower PSRAM window as transparent external heap. Berry leaves the upper window available for explicit block/cache use.

## What is safe today

- `p2.psram_info()` reports available PSRAM tier details.
- `p2.psram_test()` smoke-tests bounded block transfer.
- `libstore.cache_source(name)` mirrors source text into the safe PSRAM block/cache window.
- `libstore.cached_source(name)` materializes cached source back into active VM RAM before compilation.
- `p2mem.stats()`, `p2mem.stats_result()`, `p2mem.cache()`, `p2mem.cache_result()`, and `p2mem.evict()` report and reset the current source-cache facade. Result helpers wrap lower diagnostic failures in an `ok/error/message` map for tooling. `p2mem.cache()["items"]` includes both the compatibility `chunks` count and explicit `chunk_count` field for source-cache entries.

## What remains open

- Direct execution from PSRAM.
- Live GC object storage in PSRAM on COMPACT profiles.
- P2-compatible preferred `.bec` cache loading, plus `.be` to `.bec` cache emission in saver-enabled builds. Current hardware verifies that host-ABI `.bec` files and matching-size bytecode with mismatched builtin counts are rejected as incompatible, and normal `libstore.load()` falls back to source.
- Real module hit/miss/refcount/last-used metadata.
- Low-memory and eviction stress behavior.

## Rule of thumb

Hub RAM is for active execution. PSRAM is for inactive/cache data unless a future implementation proves safe pointer-like access with tests.
