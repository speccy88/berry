# P2 Coverage Matrix

Date: 2026-06-06

Legend:

| Status | Meaning |
| --- | --- |
| Verified | Implemented and live-verified on the documented P2 path. |
| Partial | Some implementation exists, but coverage, API shape, tests, or docs are incomplete. |
| Planned | Goal exists, but current implementation evidence is missing. |
| Unsupported | Currently not supported and should fail or be documented honestly. |
| Needs run | Test or smoke suite exists, but current evidence says it needs a fresh run. |

## Summary

| Area | Status | Current evidence | Remaining work |
| --- | --- | --- | --- |
| Build system | Partial | Catalina make targets, profile selection, Docker cache path, image size guards, Edge32 and XMM commands exist and are documented. `make test-host`, `make test-p2`, and `make soak-p2` now exist as repeatable test entrypoints. | Keep no-PSRAM Edge and Edge32/XMM paths green while features are added; expand test coverage behind the new entrypoints. |
| Boot on selected board | Verified | `p2-edge32-flash` boots from SPI flash on P2 Edge 32 MB. `p2-xmm-flash` boots after the expected copy delay. | Keep re-verifying after substantial firmware changes. |
| REPL core behavior | Partial | Arithmetic, strings, maps, lists, ranges, blank input, and quit behavior are live-verified. | Convert smoke notes into repeatable automated coverage. |
| Berry language feature coverage | Partial | Core interactive syntax and collection checks exist. | Cover all built-ins listed in `goal.md`, including tests and docs. |
| Berry standard-library coverage | Partial | `string`, SD-backed `math`, `json`, `bytes`, `os`, and file operations have live P2 coverage. | Verify all included upstream modules and add normal, SD import, repeated import/cache, PSRAM-cache, and low-memory tests where relevant. |
| Berry expansion-module coverage | Partial | Native `i2c`, `spi`, `rtos`, `spin2`, WiFi import surface, and `taskspin.be` are documented. | Finish hardware validation and document unsupported host-like features. |
| SD loader coverage | Partial | `/modules` lazy import root works. FAT fallback to sector `2048` works. `/modules/math.be` imports from SD. | Run full scripted SD smoke suite; add `.bec`, cache freshness, configured `sys.path`, and full layout coverage. |
| PSRAM cache coverage | Partial | `p2.psram_info()`, `p2.psram_test()`, bounded read/write, chunked `libstore` source-cache round trips, and `p2mem` diagnostics/eviction facade are covered by smoke/host regressions. | Complete inactive bytecode/module cache tier, hashes, hit/miss accounting, refcounts, last-used timestamps, and low-memory behavior. |
| P2 primitive API coverage | Partial | Current flat `p2.*` helpers cover pieces of clock/counter, wait, cog, pins, CORDIC, smart pins, PSRAM, filesystem, and diagnostics. Grouped `p2.clock`, `p2.cog`, `p2.lock`, `p2.pin`, `p2.cordic`, `p2.math`, and `p2.rng` aliases now exist with P2 smoke coverage. Low-level negative integer, cog, lock, pin, and reserved-pin validation paths have smoke coverage. | Run hardware smoke for the grouped API and continue toward high-level wrappers. |
| Smart pin mode coverage | Partial | Raw smart pin helper surfaces exist. Grouped raw aliases exist under `p2.smart`. | Research and cover all requested mode families and high-level wrappers. |
| High-level hardware wrapper coverage | Planned | Some native bus APIs exist through `i2c` and `spi`. | Add friendly GPIO, PWM, ADC, DAC, timer, quadrature, UART, SPI, and USB wrappers. |
| PASM/assembly integration | Partial | Raw cog program startup via `p2.cog_start_hex()` exists. Safe `p2.asm` aliases now expose `getrnd`, `getct`, `waitx`, and `hubset` with smoke coverage. | Add PASM blob loading, cog launcher, function bridge, ABI docs, and unsafe build flag. |
| Multicog Berry VM coverage | Partial | `rtos.newcog("name", ...int_args)` works through current child VM backend. | Implement requested `p2.cog.spawn(closure, ...args)` semantics with safe capture behavior and deterministic cleanup. |
| Closure-in-cog coverage | Planned | Captured closures are intentionally guarded. | Implement real closure launch into another cog or explicitly reject unsupported captures with tests. |
| IPC coverage | Partial | `rtos` channels, queues, flags, timers, locks, callbacks, and debug helpers are documented as working for current cases. Importing `p2ipc` now attaches cooperative `p2.channel`, `p2.mailbox`, `p2.shared.Buffer`, and `p2.mutex` APIs with host and P2 smoke coverage; mutexes use `p2.lock` hardware locks when available. | Add cross-VM/cross-cog wakeups, cog attention integration, serialization rules, and stress/soak coverage. |
| Cooperative task coverage | Partial | `modules/taskspin.be` provides a 32-slot Spin2-shaped cooperative task API from SD. `modules/task.be` now exposes the lower-case roadmap API, 32 fixed slots, first-free behavior, halt masks/all-halted state, host/P2 smoke coverage, and cooperative Semaphore/Mutex/Queue/EventFlags/Timer primitives. | Independent Berry call stacks/coroutines, true Spin2/PASM switching, non-callback stackful execution, and broader stress/soak testing remain open. |
| Debug feature coverage | Partial | `p2.fs_info()`, `p2.status_info()`, `p2.debug_snapshot()`, `p2mem`, heap, module, cache, and PSRAM diagnostics exist. `p2.debug` now exposes backed heap, GC, cog, memory-map, pin, smart-pin, and current-cog register diagnostics with smoke coverage. | Add breakpoints, trace controls, source stack traces, task/module/lock/channel internals, broader registers, and PASM debug support. |
| Example coverage | Partial | Interactive examples are documented in P2 docs and handoffs. | Add explicit example files requested in `goal.md`. |
| Host test coverage | Partial | `make test-host` runs the existing host suite plus fake-PSRAM `libstore`, `taskspin`, and lower-case `task` facade regressions. | Add host tests for fake SD, `.bec`, import cache, eviction, errors, closure serialization, and broader low-memory behavior. |
| P2 hardware test coverage | Needs run | `make p2-smoke`, `make p2-smoke-quick`, `make p2-smoke-edge32`, and `make test-p2` exist. | Run full scripted SD smoke suite after provisioning and keep extending hardware coverage. |
| Soak/performance coverage | Partial | `make soak-p2` repeats the selected P2 smoke suite for a duration. | Add `docs/performance.md`, benchmark hooks, explicit eviction/GC/cog/channel/GPIO/smart-pin stress, and leak reporting. |
| VGA/video | Planned | Goal requires support or staged implementation notes. | Implement demo or document staged plan. |
| USB keyboard/mouse/HID | Planned | Goal requires support or staged implementation notes. | Implement demos or document staged plan. |
| WiFi/AirLift | Partial | `import wifi` compiles/imports when module is present; ESP32-C6 hardware detection still pending READY/BUSY troubleshooting. | Complete hardware detection and examples if retained in scope. |

## Standard library snapshot

| Module/feature | Status | Notes |
| --- | --- | --- |
| `print` | Verified | Basic REPL prints documented. Needs automated test coverage. |
| `list` | Verified | `x=list(); x.push(42); print(x.size())` documented. Needs automated test coverage. |
| `map` | Verified | Insert/find and map iteration documented. Needs automated test coverage. |
| `range` | Verified | `for i:0..3 print(i) end` documented. Needs automated test coverage. |
| `string` | Verified | `toupper` and `find` documented. Needs automated test coverage. |
| `math` | Verified | SD-backed import and `sqrt(81)` documented on Edge32 and XMM flash. Other functions also have prior coverage notes. Needs full module test coverage. |
| `json` | Verified | `json.load` and `json.dump` documented. Needs automated test coverage. |
| `bytes` | Verified | Construction, indexing, `fromstring`, and `tohex` documented. Needs automated test coverage. |
| `file` / `open` | Verified | SD read/write examples documented. Needs broader mode/error tests. |
| `os` | Verified | `listdir`, `mkdir`, `chdir`, `getcwd`, `remove`, `rename` documented. Needs automated test coverage. |
| `os.path` | Verified | `isdir`, `isfile`, `join`, `split`, `splitext`, `exists` documented. Needs automated test coverage. |
| Other built-ins/modules from `goal.md` | Planned | Must be audited against the exact included Berry version. |

## Board and hardware snapshot

| Hardware area | Status | Notes |
| --- | --- | --- |
| P2 Edge no-PSRAM pins | Verified | LEDs `56` and `57`; SD `58..61`; serial `62..63`. |
| P2 Edge 32 MB pins | Verified | LEDs `38` and `39`; PSRAM reserves `40..57`; SD `58..61`; serial `62..63`. |
| I2C | Verified | BMP180 on `SCL=25`, `SDA=24`; scan finds `0x77`; chip ID read returns `0x55`. |
| SPI | Partial | Initialization and one-byte raw read documented; full JEDEC validation needs known attached target. |
| GPIO | Partial | No-PSRAM LED checks documented; final high-level API still open. |
| PSRAM block API | Verified | `p2.psram_test()`, bounded read/write, and cache source round trip documented. |
| SD filesystem | Verified | Mount fallback and SD file operations documented. Full smoke suite still needs fresh run. |
### Current top-level example coverage

Implemented top-level examples now cover LED blink, SD REPL/startup handoff, library import sweep, JSON-on-SD, basic SD file I/O, cog/channel messaging, cooperative task scheduling, CORDIC/math helpers, PSRAM cache diagnostics, and debug snapshot reporting. Hardware-loopback and peripheral-specific examples such as ADC, DAC, PWM, UART, SPI, quadrature, VGA, USB HID, cog closure, and direct PASM remain open in `port/p2/TODO.md`.
### Berry compatibility smoke additions

`tests/p2/smoke_compat.be` now provides scripted P2 smoke coverage for the safe non-interactive core builtins and modules: `print`, `classname`, `classof`, `str`, `number`, `int`, `real`, `bool`, `type`, `size`, `super`, `assert`, `compile`, `module`, `issubclass`, `isinstance`, `call`, `list`, `map`, `range`, `bytes`, `time`, `global`, `introspect`, `solidify`, and `strict`. `input` remains open because the serial smoke runner must not block on interactive input.

`tests/p2/smoke_sd.be` now covers SD-backed `file`, `os`, and `os.path` behavior through create/read/rename/remove checks plus path helper checks. This is coverage for the current SD-card filesystem mapping, not a claim that all host-like OS behavior exists on bare metal.
### Safe p2.asm facade

`p2.asm` now exposes safe PASM-adjacent intrinsics for random, counter, wait, and hubset access by aliasing existing validated native helpers. Arbitrary assembly text, PASM blob loading, function bridging, and unsafe execution remain open and should stay gated or unsupported until the safety model is explicit.
### Structured p2.debug facade

`p2.debug` now exposes only backed diagnostics: `snapshot`, `heap`, `gc`, `cogs`, `memory_map`, `pin`, `pins`, `smartpin`, and `registers`. Breakpoints, tracing, source stack traces, module cache internals, task/lock/channel internals, and PASM single-step remain open rather than silently stubbed.
### Lower-case task facade

`modules/task.be` wraps the backed `taskspin` scheduler with the requested lower-case API and cooperative primitives. This completes the source-level step-closure scheduler facade, not the still-open independent-stack or true Spin2/PASM task-switching work.
### Documentation set expansion

The P2 documentation set now includes getting-started, building, board-support, SD layout, PSRAM loader, Berry compatibility, P2 API, smart pins, cogs, tasks, PASM, debugging, performance plan, hardware-test guide, and limitations documents. These docs intentionally separate backed features from planned or unsupported work.
### Cooperative p2 IPC facade

`modules/p2ipc.be` attaches cooperative Hub-memory `p2.channel`, `p2.mailbox`, `p2.shared.Buffer`, and `p2.mutex` helpers to the native `p2` module. This completes the current-VM API surface with host/P2 smoke coverage, while cross-cog attention, cross-VM serialization, and stress/soak behavior remain open.

