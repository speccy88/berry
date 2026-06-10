# Current P2 Architecture

Date: 2026-06-06

Scope: current Berry-on-Propeller-2 state for the P2 Edge and P2 Edge 32 MB RAM work.

Primary evidence:

- `docs/P2_BUILD.md`
- `port/p2/docs/PORTING_STATUS.md`
- `port/p2/docs/P2_EDGE32_SD_XMM_HANDOFF.md`
- `port/p2/TODO.md`
- `port/p2/DONE.md`

This document is a current-state snapshot. It is not the final desired architecture.

## Build system

The P2 build interface is make-based and routed through `mk/p2.mk` and `mk/toolchain-catalina.mk`. Catalina is the preferred and currently verified P2 toolchain. FlexC paths remain in the tree for legacy/debugging support, but normal P2 validation should stay on Catalina unless FlexC work is explicitly requested.

Common commands:

```sh
make configure
make show-config
make p2 TOOLCHAIN=catalina
make p2-ram
make p2-flash
make p2-edge32
make p2-edge32-flash
make p2-xmm
make p2-xmm-run
make p2-xmm-flash
```

The current verified native macOS Catalina path is:

```sh
make p2 TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88
```

Important profile split:

| Profile | Board | Catalina model | PSRAM use | Image limit |
| --- | --- | --- | --- | --- |
| `full` | `p2edge` | `COMPACT` | none | 512 KiB Hub RAM image |
| `edge32` | `p2edge32` | `COMPACT` | Catalina `-lpsram` block API | 512 KiB Hub RAM image |
| `xmm` | `p2edge32` | `LARGE` | Catalina XMM lower PSRAM window plus explicit upper block window | experimental XMM image limit |

The normal no-PSRAM P2 Edge profile keeps onboard LEDs on pins `56` and `57`. The P2 Edge 32 MB profile uses LEDs on pins `38` and `39` and reserves pins `40..57` for the memory interface, including pin `57` as PSRAM chip-select.

The build generates P2 board/profile macros for runtime code, including board identity, PSRAM presence, LED pins, and silicon identity.

## Current Berry port state

The P2 port lives mainly under `port/p2/`, `mk/`, `tools/p2/`, `modules/`, and `tests/p2/`.

Current verified capabilities include:

| Area | Current state |
| --- | --- |
| REPL | Basic arithmetic, strings, maps, lists, ranges, blank input handling, and interactive quit are live-verified on the Catalina P2 path. |
| Standard modules | `string`, native `math`, `task`, `json`, `bytes`, `os`, and SD-backed file operations have current or prior live P2 coverage. Full standard-library coverage is still open. |
| SD modules | P2 VMs add `/modules` as a default lazy import root for optional libraries. `math`, `string`, and `task` are native firmware modules; `modules/p2mem.be` reports heap/module/cache diagnostics over the current SD/PSRAM source-cache model. |
| Native P2 helpers | Current helpers are exposed as flat `p2.*` functions, including clock/counter, wait, cog, pin, CORDIC, smart pin, status, heap, PSRAM, and filesystem diagnostics. Grouped aliases now exist for the low-level `p2.clock`, `p2.cog`, `p2.lock`, `p2.pin`, `p2.cordic`, `p2.math`, `p2.rng`, and raw `p2.smart` API. High-level wrappers are still open. |
| Bus modules | Native `i2c` and `spi` modules are live on the current Catalina path. `i2c` has BMP180 smoke coverage. `spi` initialization and basic read/transfer surfaces are present, with full target validation still dependent on known attached hardware. |
| Cooperative tasking and cogs | Native `task` provides cooperative scheduler primitives in the current VM. `p2.cog` provides native cog-backed handles for supported functions such as blinkers. The older `rtos` and `taskspin` experiments are retired. |

## Current SD loader behavior

The current P2 SD path is SD-first and lazy. Libraries can live as `.be` files on SD and are not all loaded into Hub RAM at boot.

Current verified SD facts for the P2 Edge 32 MB board:

| Fact | Current result |
| --- | --- |
| Raw SPI SD response | Working |
| Sector 0 on current card | Not a valid MBR/FAT boot sector |
| FAT fallback | Berry tries common FAT volume starts when sector 0 is invalid |
| Current valid FAT start | Sector `2048` |
| `p2.fs_info("/")["mount_result_name"]` | `ok` |
| `p2.fs_info("/")["partition_start"]` | `2048` |
| `p2.fs_info("/")["volinfo_result_name"]` | `ok` |
| Native math smoke | `import math; print(math.sqrt(81))` prints `9` without SD module files |

Catalina `_mount()` is avoided on the Berry direct-SD path because it adds stack pressure in the near-full Hub image. Berry performs partition/volume setup with one static sector buffer and updates Catalina `__pstart` and `__vi`.

Catalina's auto-started `-lcx` SD plugin is disabled for the direct-SD profile with `-C BERRY_P2_DIRECT_SD_IO`. The Catalina patch stamp for this path is `berry-p2-patch-v24`; COMPACT Edge32 helper stubs are generated without unconditional `-C PSRAM`, while XMM/LARGE keeps `-C PSRAM`.

## Current PSRAM behavior

There are two PSRAM models in play:

| Profile | Behavior |
| --- | --- |
| `edge32` | Catalina `COMPACT` plus `-lpsram` exposes bounded block transfers through `p2.psram_read()` and `p2.psram_write()`. Berry live objects and bytecode remain in Hub RAM. `libstore` can use PSRAM as a chunked source-cache backend. |
| `xmm` | Catalina `LARGE` plus `-lpsram` and `-C PSRAM` puts allocator-backed C storage in external memory through Catalina XMM. Current standalone flash boot reports `Berry heap external` and `XMM 16777216 B`. Berry keeps the upper PSRAM window for explicit block/cache use. |

Important constraint: the COMPACT PSRAM API is block-transfer storage, not ordinary pointer-addressable memory. Do not place arbitrary live Berry GC objects in that block window without a proven handle/cache representation.

The current verified standalone XMM flash image boots through the sparse fast loader, shows PSRAM and VM startup spinners, reports `Berry heap in PSRAM`, and exposes a `15728640` byte main heap.

## Current Propeller 2 hardware bindings

Current bindings are useful but not yet the final API from `goal.md`.

Current exposed helpers include:

| Area | Current examples |
| --- | --- |
| Clock/counter | `p2.clock_freq()`, `p2.ticks()`, `p2.ticks64()`, `p2.wait_ticks()`, plus grouped `p2.clock.*` aliases. |
| Cog | `p2.cogid()`, `p2.cog_states()`, `p2.cog_check()`, `p2.cog_stop()`, `p2.cog_start_hex()`, plus grouped `p2.cog.*` aliases. |
| Pins | `p2.pin_output()`, `p2.pin_write()`, `p2.pin_read()`, plus grouped `p2.pin.*` aliases. |
| Smart pins | `p2.smartpin_write_mode()`, `p2.smartpin_query()`, `p2.smartpin_start()`, plus grouped raw `p2.smart.*` aliases. |
| CORDIC | `p2.rotxy()`, `p2.xypol()`, `p2.polxy()`, plus grouped `p2.cordic.*` aliases. |
| Locks/IPC | Current cooperative primitives are primarily under native `task`; low-level lock and cog helpers remain under `p2.*` / `p2.cog`. |
| Diagnostics | `p2.status_info()`, `p2.debug_snapshot()`, `p2.heap_info()`, `p2.psram_info()`, `p2.fs_info()`, `p2mem.stats()`, `p2mem.modules()`, `p2mem.cache()`, `p2mem.gc()`, `p2mem.evict()` |

Known board pin constraints are enforced more narrowly than early revisions:

| Board | Available LEDs | Reserved pins |
| --- | --- | --- |
| `p2edge` | `56`, `57` | `58..61` for SD, `62..63` for serial |
| `p2edge32` | `38`, `39` | `40..57` for PSRAM, `58..61` for SD, `62..63` for serial |

## Current tests

Current P2 smoke support is non-destructive and SD-backed.

Known test/provisioning commands:

```sh
make test-host
make test-p2 PORT=/dev/cu.usbserial-P97cvdxp BOARD=p2edge32
make soak-p2 PORT=/dev/cu.usbserial-P97cvdxp BOARD=p2edge32 HOURS=1
make p2-sd-sync PORT=/dev/cu.usbserial-P97cvdxp
make p2-smoke
make p2-smoke-quick
make p2-smoke-edge32
```

The smoke suite depends on `/tests/p2` and `/modules` being present on the SD card. The full scripted SD smoke suite still needs a fresh run against the provisioned card, even though manual SD mount and `math.sqrt(81)` checks are now live-verified.

The new `test-host`, `test-p2`, and `soak-p2` targets are repeatable entrypoints. They do not yet prove the full final test matrix from `goal.md`; remaining gaps are tracked in `docs/coverage-matrix.md` and `port/p2/TODO.md`.

## Current examples

Some example-style interactive checks are documented in existing P2 docs and handoffs, including REPL arithmetic, SD-backed module imports, file/os operations, I2C BMP180 access, SPI initialization, PSRAM reads/writes, and RTOS channels/events/timers.

The explicit example files requested in `port/p2/goal.md`, such as `examples/blink.be`, `examples/import_all_libs.be`, `examples/cog_closure.be`, and `examples/task_scheduler.be`, are still roadmap items unless separately added and verified.

## Current memory map

Current memory architecture:

| Region | Current use |
| --- | --- |
| P2 Hub RAM | Active VM state for normal/full/edge32 profiles, active stacks, live GC-managed objects, active bytecode/prototypes, near-full Hub image content. |
| P2 Edge 32 MB PSRAM lower 16 MiB | Catalina XMM memory on the `xmm` profile. Reserved from explicit block-cache use. |
| P2 Edge 32 MB PSRAM upper 16 MiB | Explicit block/cache window exposed through Berry P2 helpers and used by `libstore` style source-cache experiments. |
| SD card | Persistent `.be` modules, tests, user files, and module roots such as `/modules`. |
| SPI flash | Standalone boot images, including normal Edge32 flash and composed XMM flash images. |

Current verified image sizes from docs:

| Target | Image size |
| --- | --- |
| `p2` full no-PSRAM RAM image | `494624` bytes |
| `p2-edge32` | `506080` bytes |
| `p2-xmm` / standalone XMM flash payload | `726432` bytes |

## Current known limitations

- Full Berry standard-library coverage is not complete.
- Full `.bec` execution and compile-to-cache behavior are not complete; sidecar freshness manifest metadata is staged but does not enable bytecode execution.
- `libstore` currently proves a source-cache strategy, not a complete compiled bytecode/module cache tier.
- COMPACT `edge32` still keeps live Berry VM objects in Hub RAM.
- The low-level grouped `p2.clock`, `p2.cog`, `p2.lock`, `p2.pin`, `p2.smart`, `p2.cordic`, `p2.math`, and `p2.rng` API now exists as aliases over current helpers, but the high-level wrapper API requested in `goal.md` is not complete.
- Smart pin coverage is partial.
- VGA/video and USB keyboard/mouse are not complete and must not be faked.
- PASM2 blob/function bridge support is not complete.
- Real closure transfer into another cog is not complete; current RTOS child-VM launch supports process-style entry points and intentionally guards unsafe closure transfer.
- The cooperative task API exists as an SD module experiment, but full scheduler semantics, tests, and integration remain open.
- Full host, hardware, soak, and performance test systems remain open.
- The full scripted SD smoke suite still needs a fresh run against the provisioned card.
