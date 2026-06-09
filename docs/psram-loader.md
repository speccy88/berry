# PSRAM Loader and Cache Model

## Current model

On `edge32`, Catalina exposes PSRAM as a bounded block-transfer API. Berry keeps live VM heap, active bytecode, stacks, prototypes, and GC-managed objects in Hub RAM. PSRAM is used as an inactive storage/cache tier through explicit reads and writes.

On `xmm`, Catalina owns the lower PSRAM window as transparent external heap. Berry leaves the upper window available for explicit block/cache use.

## What is safe today

- `p2.psram_info()` reports available PSRAM tier details.
- `p2.psram_test()` smoke-tests bounded block transfer.
- `libstore.cache_source(name)` mirrors source text into the safe PSRAM block/cache window.
- `libstore.cached_source(name)` materializes cached source back into active VM RAM before compilation.
- `p2mem.stats()`, `p2mem.cache()`, and `p2mem.evict()` report and reset the current source-cache facade.

## What remains open

- Direct execution from PSRAM.
- Live GC object storage in PSRAM on COMPACT profiles.
- `.bec` bytecode cache execution and compile-to-cache emission; sidecar freshness manifest metadata is staged but does not enable execution.
- Real module hit/miss/refcount/last-used metadata.
- Low-memory and eviction stress behavior.

## Rule of thumb

Hub RAM is for active execution. PSRAM is for inactive/cache data unless a future implementation proves safe pointer-like access with tests.
