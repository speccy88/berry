# P2 Coverage Matrix

Date: 2026-06-06

This is the detailed evidence matrix. For a readable current-status page,
start with `docs/P2_PORT_STATUS.md`; use this file when you need exact coverage
claims, gaps, or proof paths.

The table below intentionally preserves detailed evidence, so some rows are
long. Current user instructions should come from `docs/P2_PORT_STATUS.md`,
`docs/getting-started.md`, `docs/P2_BUILD.md`, and `docs/testing.md`.

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
| Build system | Partial | Catalina make targets, profile selection, native Catalina path, image size guards, Edge32 and XMM commands exist and are documented. `make test-host`, `make test-p2`, `make soak-p2`, and non-hardware `make p2-baseline-guards` now exist as repeatable test entrypoints. The baseline guard bundle checks the Catalina build-log pipefail path, Edge32/XMM profile invariants, sibling Catalina XMM `cx` object/index sync, Catalina warning classes, bounded cleanup-oriented SD-writing smoke discipline, required P2 documentation presence, source-module capability metadata contracts, user-facing example local compilation/safety/final-marker contracts, focused P2 smoke/example staging source-existence, focused example and mapped test-suite runner/staging alignment, and 8.3 collision checks, and active Catalina path policy including make usage strings without rebuilding firmware. The Catalina flash-loader wrapper image is now size-guarded against the P2 Hub RAM limit. | Keep no-PSRAM Edge and Edge32/XMM paths green while features are added; expand test coverage behind the new entrypoints and keep the guard bundle cheap enough to run before larger P2 edits. |
| Boot on selected board | Verified | `p2-edge32-ram`, `p2-edge32-flash`, and `p2-xmm-flash` were hardware-verified on `/dev/ttyUSB0` with `CATALINA_DIR=../Catalina`. `p2-edge32-flash` boots from SPI flash on P2 Edge 32 MB. `p2-xmm-flash` boots through the sparse fast loader with visible PSRAM/VM startup spinners. | Keep re-verifying after substantial firmware changes. |
| REPL core behavior | Partial | Arithmetic, strings, maps, lists, ranges, blank input, and quit behavior are live-verified. | Convert smoke notes into repeatable automated coverage. |
| Berry language feature coverage | Partial | Core interactive syntax, compiler/parser regression shapes including call-argument ternary, ternary-result suffix, call-result chained suffix, and chained-suffix parsing, built-ins including `call()` non-callable rejection, `input()` on P2 serial, bytes length truthiness through `bool()`, range type classification and numeric parser edges, numeric passthrough conversions, and custom conversion edge values, safe Berry-level C API edge probes including reflection member replacement and map copy isolation, collection checks including dedicated list-core `size()` API shape, iterator exhaustion, index-list ordering, reverse in-place behavior, and copy isolation, map values, range method API shape, range increment/setrange/positive and negative iterator isolation including independent iterator exhaustion plus retargeted-range iterator preservation and exhaustion, and plain-map behavior coverage including `keys()`/`values()` API shape, keys/values snapshot isolation, mixed-type key distinction, nil-value presence, and nil-valued insert preservation, closures including returned-closure function classification, dedicated escaped-closure and factory returned-function classification, parameter/local capture, shared-upvalue multi-closure and group-independence, nested upvalue-chain, captured mutable-object independence, and upvalue mutation coverage, varargs including direct, direct rest-list freshness, closure, escaped rest-list capture and mutation persistence, method packing, method rest-list freshness, and vararg-list mutation isolation, loop control including empty-range iteration, class iterator closure isolation, list-iteration break/continue, nested break/continue isolation plus outer-break coverage, and dedicated for-loop recursion coverage, byte behavior including base64 one-byte padding, two-byte padding, single- and multi-quantum no-padding quanta, fixed-size bytes, and fromstring shortened replacement/copy isolation, compact VM operator/full-span negative slicing/comparison-result typing/operator-overload checks including derived inequality including callable instances plus callable-instance list-lookup invocation and binary instance-result class identity and chained binary instance-result overloads, focused VM runtime, named-global cleanup, invalid comparison, and shift-operator error paths, integer conversion/negative `toint()`/lowercase and uppercase hex/bitwise/positive shift/variable shift counts/zero-shift identity and signed right-shift checks, lexer literal/block- and line-comment-adjacent token parsing/hex escape boundary/malformed-token checks, class/static/indirect-member checks including instance class identity, instance-method static-member reads including post-construction static updates, computed class/instance method-name calls, dynamic static writes, and chained indirect updates, static initializer/mutable static object sharing/`_class`/nested static class first-class identity checks, static member/function-member reassignment and scalar compound update checks including mutable static-object sharing and inherited static readback, legacy/grouped static declaration checks including mutable static list/map values plus method-visible and cross-instance shared static fields, subclass-from-module-member static checks including inherited method live static fallback and child/base static mutation separation, module creation/same-name module object and member-table independence/injected-module identity/replacement/cache monkey-patch/restore checks plus compiled module-member mutation, module attribute-dispatch including function-valued virtual members plus real-attribute and post-virtual shadow precedence without hook checks, constructor chaining, external and leveled super-proxy method calls, chained super argument passing, plus auto/leveled `super()` checks, builtin list/map subclass method/storage including map-subclass keys snapshot isolation, subclass instance fields, builtin method preservation, and subobject relationship checks, map instance-key/hash/equivalent-key replacement/removal/collision checks, `undefined` sentinel plus virtual `member()` computed-name reads including function-valued module reads and real-member precedence, plus `setmember()` repeated assignment replacement, computed-name scalar and function-valued assignment, and computed-name/real-member dispatch checks, f-string indexed-expression including computed map keys and computed-width formatting plus walrus syntax checks including builtin shadowing/sequential value-expression/local call-argument value-expression and map-literal assignment-expression edges, conditional-expression selected-branch side-effect, condition-operand single-evaluation, and collection-truthiness checks, compound-assignment computed-index, computed map-key sibling isolation, and computed-member update checks, nested suffix-assignment, computed map-key/member assignment with sibling isolation, and computed-member checks, cyclic list/map plus shared-child reference stringification checks, suffix/list-append expression, method-chain indexing including negative indexes, and method-chain slicing checks, boolean/truthiness/short-circuit checks including skipped/executed branch side effects, truthy non-bool, and falsey collection operands including OR branch execution, relational/equality checks including list order sensitivity, map order/nested-map order/nil equality and bytes equality, literal and computed-denominator division-by-zero exception checks plus negative non-zero division/modulo sign behavior, and compact exception/error-path checks including key-error handling, function- and method-propagated raise and assert-failure exception capture across default-message assert, loop, function-call, method-call, and closure-call propagation cases exist. | Cover all built-ins listed in `goal.md`, including tests and docs. |
| Berry standard-library coverage | Partial | `string` including module/API shape, native `math`, native `task`, `json` including module/API shape, compact parse-freshness and dump-state, advanced parser, and generated stack/growth cases including matrices, `bytes`, `os`, file operations, `time` including compact dump snapshot-freshness, `global` including API shape, `sys` including module/API shape, `introspect` including module/API shape and normal-XMM hardware verification through short aliases, `solidify` including introspected helper discovery, `debug` including API shape and helper discovery, `strict` including branch-condition lookup checks, and `configstore` JSON config result diagnostics including valid JSON `null` versus malformed JSON have P2 smoke coverage or prior live checks. Native P2 `math` now has hardware-verified CORDIC-backed trig/inverse-trig helpers where appropriate plus NaN/Inf, invalid-result, rounding, deterministic random, parity-smoke coverage, and a focused `p2-smoke-math-perf-min` timing hook that records empty-loop, CORDIC-backed `sin`/`cos`, and software-fallback `sqrt` loop ticks without claiming a statistical speedup. `p2-smoke-stdlib-min` now provides a focused normal-image standard-library smoke that stages one file, verifies common `string`, `json`, and `solidify.compact()` behavior, and reports clean skips for absent optional `time`, `global`, and `strict` modules instead of requiring the extended-module image. `p2-smoke-sd-file-core-min` now provides the routine SD/file slice for Priority 1, staging one small no-`for`/`try`/`except` file that verifies mount metadata, common file modes, path helpers, directory create/chdir/remove, rename, and cleanup. Bounded import/GC churn and import-all coverage now exists for the current SD module set, and `libstore.info()` / `libstore.inventory()` now expose per-module coverage metadata for behavior, SD import, repeated import/cache, PSRAM source-cache, low-memory churn, metadata, and hardware-deferred cases, with smoke coverage that returned inventory and compiled-summary snapshots are isolated from caller mutation and inventory source metadata matches `source_stats()`. `p2-smoke-libraries-lazy-min` now provides a smaller hardware-verified lazy-loading policy check for normal progress work, `p2mem.memory_pressure_policy()` is host-pinned as queryable low-memory/PSRAM metadata while the current XMM image defers routine `p2mem` source-load hardware proof, `p2-smoke-p2mem-native-cache-min` covers native upper-PSRAM cache reset, verified put, verified get, and entry accounting, and `p2-smoke-bec-fallback-min` covers the `.bec` source-fallback decision without running broader import suites. | Verify all included upstream modules and add normal, SD import, repeated import/cache, PSRAM-cache, and low-memory tests where relevant. |
| Berry expansion-module coverage | Partial | Native `i2c`, `spi`, WiFi import surface, archived/opt-in `spin2` boundary, `task.be`, conservative `p2smart.be` smart-pin/GPIO wrappers, and declarative `p2compat.be` capability metadata are documented. The default firmware does not provide `import spin2`; the Spin2 examples now detect that through `introspect.module("spin2")` and hardware-run to stable done markers after reporting `module archived`. `p2smart` now exposes `capabilities()`, direct `status(name)` lookup, `required_capability_keys()`, and `status_report()` so verified, setup-only, unverified, and unsupported smart-pin wrapper areas are queryable and required metadata drift is caught by `audit()`; host/import coverage checks the map, required keys, exact status lookup, and snapshot isolation. `p2smart` has host coverage for generated GPIO, normal-pin, counter/counter-variant/repository/PWM/PWM-variant/NCO/NCO-duty/pulse/transition/ADC/ADC-variant/DAC/DAC-variant/async-serial call sequences and staged loopback smoke use; `p2compat` now reports supported package-style SD imports, supported native `sys` module path helpers, staged `.bec` manifests, bytecode cache emission, bytecode validator policy, board/profile compatibility policy metadata, board pin reserved-policy helpers, child-VM transfer policy metadata, child-VM partition-sizing diagnostics from `p2.heap_info()`, discoverable valid status names, status-report diagnostics, required capability-name metadata, required board-profile policy-key metadata, required child-VM policy-key metadata, a compact report snapshot, self-audit results, and concise audit-problem names separately from unsupported host-like APIs. `p2compat.be` now avoids current-image-unsafe line-start `for` / `try` / `except` syntax, so the focused source smoke can run on the normal XMM image. Host/source/hardware coverage checks summary/inventory consistency, status-filtered capability queries, name-list queries, board/profile policy fields, reserved-pin ranges and allowed/reserved pin decisions, child-VM transfer and partition policy fields, report consistency, audit consistency, missing required metadata checks, returned-list mutation isolation, returned-record mutation isolation, summary, nested report summary/status-list/bytecode/board-profile/child-VM-partition data, audit-map/list, audit-problem, and bytecode snapshot mutation isolation. A focused `p2-smoke-p2compat` hardware target uploads `modules/p2compat.be`, `/tests/p2/smoke_p2compat.be`, and `/tests/p2/p2compvm.be`, runs short native metadata probes including compact `P2_COMPAT_VM_PARTITION_POLICY`, verifies the source p2compat policy smoke, and checks native `p2.vm_copyable()` single-value and `p2.vm_copyable_args()` batch VM-boundary copy/reject diagnostics plus child-VM heap partition capacity/free-capacity/parent-selection invariants. | Finish hardware validation and keep unsupported host-like features explicit. |
| SD loader coverage | Partial | `/modules` lazy import root works for optional SD libraries. FAT fallback to sector `2048` works. `math`, `string`, and `task` import as native firmware modules. Source-level support now exists for import aliases including repeated SD alias cache identity and source-path/info diagnostics, missing-import failure/retry recovery, native-module-first precedence and repeated native import identity across `/berry/lib` and `/berry/app` shadows, module-root order including `/modules` before `/berry/lib` before `/berry/app` with matching source-path/info diagnostics, current-directory imports with cwd-before-root precedence and cached alias re-import identity checks, additive `sys.path_add()` import roots with source-path/info diagnostics, scoped `libstore.path_add()` and `path_remove()` custom-root diagnostics, optional `/berry/main.be` staging/run/cleanup path checks, `/berry/lib/*.be` including nested package source layout and source-path/info diagnostics, `/berry/app/*.be` including dotted nested app helpers and missing-app path/existence/run fallback checks, `/berry/config/*.json`, nested package file lookup for string imports such as `import "pkg.mod" as mod`, bare dotted imports such as `import pkg.mod`, comma-separated dotted imports such as `import pkg.mod, pkg.other`, `.bec` path detection with source fallback, 8.3-safe `.jsn` sidecar freshness manifest metadata, opt-in bytecode-saver-gated `.be` to `.bec` cache emission helper coverage, repeated import/cache smoke coverage, and opt-in `/berry/...` provisioning targets. Focused 8.3-safe hardware runs now verify the source-layout, import-resolution, documented layout-location slices, and `.bec` fallback paths through `/tests/p2/ilayout.be`, `/tests/p2/iorder.be`, `/tests/p2/pkgpath.be`, `/tests/p2/infirst.be`, `/tests/p2/icwd.be`, `/tests/p2/lpaths.be`, `/tests/p2/syspath.be`, `/tests/p2/cfgstore.be`, `/tests/p2/expath.be`, `/tests/p2/pasmly.be`, `make p2-smoke-bec-fallback-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and the broader `/tests/p2/becfall.be` alias run with `P2_SMOKE_PASS bec_fallback`. | Run full scripted SD smoke suite only when broad evidence is needed; add `.bec` execution and path reordering only if a real safe semantics is defined. |
| PSRAM cache coverage | Partial | `p2.psram_info()`, `p2.psram_test()`, bounded read/write, chunked `libstore` source-cache round trips, source-cache no-op/error paths, constrained bulk preload skipped-module reporting through `cache_all_report()`, selected-list preload reporting through `cache_many_report()`, source-cache reset/recache behavior after source changes, `libstore` cache/status/info diagnostic snapshot isolation for path lists, cached entries, and coverage records, `p2mem` stats/module/cache/gc/evict diagnostics snapshot isolation, `p2mem.memory_pressure_policy()` low-memory/PSRAM accounting metadata with explicit no-high-water-instrumentation status, and Berry-level `p2mem` native-cache owner/warm/release/result-wrapper/write-failure cleanup, verify-failure cleanup, non-destructive replace, and failed batch-warm rollback planning are covered by smoke/host regressions. `/tests/p2/smoke_xmm_gc_stress.be` passed on standalone XMM, proving retained Berry lists/maps/strings/closures survive GC in the external heap, temporary churn is reclaimed, and the heap stays inside the pointer-addressable lower PSRAM window. | Complete inactive bytecode/module cache tier, hashes, hit/miss accounting, refcounts, last-used timestamps, native C cache bounds/release errors, real heap high-water instrumentation, and broader low-memory/soak behavior. |
| P2 primitive API coverage | Partial | Current flat `p2.*` helpers cover pieces of clock/counter, wait, cog, pins, CORDIC, smart pins, PSRAM, filesystem, and diagnostics. Grouped `p2.clock`, `p2.cog`, `p2.lock`, `p2.pin`, `p2.cordic`, `p2.math`, `p2.rng`, `p2.asm`, and `p2.debug` aliases now exist with P2 smoke coverage. `p2.clock` smoke coverage includes frequency/mode aliases, counter reads, waits, and non-destructive negative-argument validation for `waitx`, `waitus`, `waitms`, `waitsec`, `set()`, and `hubset()`. `p2.cog` smoke coverage includes id/check, function-shape checks for stop/attention, a no-op attention signal, direct self-attention delivery through `poll_attention()`, bounded `wait_attention_result(timeout_us)` timeout and pre-signaled result-map behavior, interruptible `wait_attention()` pre-signaled mask return, public-list `cog_states()`, invalid stop/attention diagnostics including current-cog self-stop rejection, and safe non-current `p2.cog.stop(cog_id)` execution through a native-blink child fixture. `p2.lock` smoke coverage stages `new`, `ret`, `try`, `release`, and `check`, including invalid-range diagnostics for each operation that takes a lock ID. `p2.pin` smoke coverage now stages `dir_low`, `dir_high`, `write`, `low`, `high`, `toggle`, `float`, `read`, bool/int writes, invalid pin/value diagnostics across read/write/direction/output/toggle/float, and PSRAM-reserved pin read/write/direction/float rejection on the current XMM board profile. Raw `p2.smart` positive hardware coverage stays on non-reserved jumper pins; a tiny reserved-pin negative smoke hung on the current image after `run_file(...)`, so that direct proof is explicitly deferred. `p2.cordic`/`p2.math`/`p2.rng` smoke coverage stages public-map result-shape checks, deterministic `isqrt`/`muldiv64`/`rev`/`encod` assertions, RNG type coverage, and unsigned-argument diagnostics. `p2.asm`/`p2.debug` smoke coverage stages safe intrinsic reads/waits, backed diagnostic maps/lists including the 64-pin snapshot, current-cog register fields, and negative diagnostics for unsafe/invalid arguments. Low-level negative integer, cog, lock, GPIO pin, and GPIO reserved-pin validation paths have hardware smoke coverage on `/dev/ttyUSB0`. | Continue toward high-level wrappers and broader hardware stress. |
| Smart pin mode coverage | Partial | Raw smart pin helper surfaces exist. Grouped raw aliases exist under `p2.smart`, lower-case Catalina constants are exposed for the signed raw API, and `p2smart` wraps GPIO input/output, setup-only explicit normal-pin mode, counter with setup-only named timer/counter variants, repository, triangle PWM plus setup-only PWM mode variants, NCO frequency, verified counter-visible NCO duty, pulse/cycle, transition, ADC with setup-only named source/family variants, DAC, setup-only DAC mode variants, and async-serial setup with host-tested call sequences. The jumper suite now passes on hardware for pins `0-1`, `2-3`, `4-5`, and `6-7`, covering GPIO wrappers, raw helpers, repository calls, triangle and named PWM/NCO-frequency/pulse/transition-to-counter, NCO-duty counter-visible output, GPIO-driven high-counter loopback, DAC-output to ADC-input setup/readback, and async setup/send/query/ack; focused minimal smokes also verify normal-pin output/input on `0-1`, static quadrature setup/sample/ack/clear plus the staged-only quadrature diagnostic result `P2_SMOKE_QUADRATURE_DIAG 0 0 0 0 false setup_only`, synthetic quadrature motion with pins `0` and `2` driving inputs `1` and `3` for forward delta `8` and reverse delta `-8`, native `p2.smart` `count_highs` duration counting plus single-edge `count_rises` loopback across all documented jumper directions, limited `high_ticks` advancement on `0-1` in both directions, selected-input four-pulse observations for the state/event/period/counter timer family using `minus1_a`, `X=4`, and `Y=1`, an on-demand `p2-smoke-smartpins-counter-timer-matrix` target showing stable positive selected-input observations but no useful 50/100/200 us scaling under the current setup, and uncalibrated NCO-duty high-time shape by comparing `0x20000000` and `0x60000000` duty values with `count_highs`. Default ADC/DAC and named-DAC sampled jumper probes are tracked as verified sampled-loopback coverage; named-ADC and combined named ADC/DAC probes remain diagnostic because focused native hardware observed flat readings for sampled `adc_ext` and `3x` variants on the current jumper harness. The on-demand `p2-smoke-smartpins-adc-variant-matrix` target records the ADC boundary more directly: `1x`/`adc` moves with `32` sample ticks, `1x`/`adc` at `256` ticks is flat, `3x` and `10x` remain flat across smaller DAC ranges, `adc_ext` is flat in both jumper directions, and `adc_scope` is only a one-count diagnostic. PWM triangle/sawtooth/SMPS low-high duty-shape checks, a compact routine ADC/DAC low-vs-high jumper delta, and NCO-duty high-time shape are verified through focused native smokes; broader calibrated waveform/timing/analog validation is still open. The focused async RX smoke now uses native `p2.smart` directly for quick normal-image verification while preserving the same async TX/RX timing as `p2smart.AsyncSerialPair`; it proves byte readback on jumper pairs `0-1`, `2-3`, `4-5`, and `6-7` in both directions for `0x00`, `0x55`, `0xa5`, and `0xff`, plus a paced exchange, latest-sample burst boundary (`0x12` then `0x34` samples as `0x34`), and bounded drain/ack path on `0-1`. The on-demand async buffer-boundary smoke proves paced readback for `0x11`, `0x22`, `0x33`, and `0x44`, then records the unpaced latest-sample/no-background-FIFO boundary where the sampled value is `0x44` and bounded draining remains diagnostic. The zero-byte path reports decoded `value=0` through a timed raw sample even when event readiness is ambiguous. The focused sync diagnostic smoke now uses native `p2.smart` directly for quick normal-image verification, uses the ROM-correct sync X value `(bits-1)|0x20`, decodes left-aligned receive words, and hardware-verifies matched clocked receive on the `0-1` data plus `2-3` clock jumpers with `P2_SMOKE_SYNC_CLOCKED 1 1 true`; bounded phase observations currently match three of four variants. `p2smart.usb_pair_policy()` and unsupported `p2smart.usb_pair_probe(...)` now make the USB smart-pin boundary explicit: the raw `usb_pair` constant is exposed, but no USB packet/HID/host/device stack is implemented. | Research/cover ADC variant hardware validation/filtering/scaling, calibrated state/event/period/counter timer interpretation, mechanical quadrature encoder behavior, true async RX buffering/FIFO, and remaining smart-pin mode families; implement USB only as a future backed stack. |
| High-level hardware wrapper coverage | Partial | Native bus APIs exist through `i2c` and `spi`; `p2smart` now provides conservative GPIO, setup-only explicit normal-pin mode, PWM with setup-only named mode helpers, ADC with setup-only named mode helpers, DAC with setup-only named variant helpers, timer/counter with setup-only named mode helpers, NCO frequency, verified counter-visible NCO duty, pulse/transition, repository, quadrature with synthetic motion/direction proof, and async-serial pair setup/read-byte/result wrappers including `read_result_after(wait_us)` for zero-byte-safe timed reads plus paced byte-list send/exchange helpers, latest-sample burst diagnostics, and explicit no-FIFO buffer policy metadata. Result-shaped diagnostics now include raw smart-pin, GPIO loopback, repository, GPIO-high counter, named counter drive aggregate, named counter drive, named counter sample, quadrature static and synthetic-motion probes, and ADC sample probes, triangle/named PWM/NCO/NCO-duty/pulse/transition-to-counter, `pwm_duty_shape_probe(...)` for PWM triangle/sawtooth/SMPS duty-shape checks, compact routine ADC/DAC low-vs-high jumper proof, NCO-duty high-time shape comparison, default/sampled/named/named-sampled/named-ADC-sampled/combined-named DAC-to-ADC, explicit DAC/ADC delta policy metadata, conservative async-serial probes, and aggregate jumper-pair diagnostics for the documented `0-1`, `2-3`, `4-5`, and `6-7` wiring in one-way and bidirectional forms, with examples and focused host/import coverage. The sync-serial wrapper now uses the ROM-documented `sync_io` mode bit by default, preserves `invert_b` in the source fallback, uses sync X `(bits-1)|0x20`, decodes left-aligned receive words, and has result-shaped transfer diagnostics. The focused hardware smoke verifies bounded matched data/clock receive through native `p2.smart` without loading the large wrapper, and now executes one bounded observation for each normal/inverted clock phase variant; current hardware reports `P2_SMOKE_SYNC_CLOCKED 1 1 true` and `P2_SMOKE_SYNC_VARIANTS_MATCHED 3`. Aggregate source-wrapper variant diagnostics still remain execution-deferred so broad phase sweeps do not wedge the board. | Add USB, true buffered UART/FIFO behavior, ADC variant validation, broader state/event/period/counter timer validation, mechanical quadrature encoder behavior, and deeper calibrated analog wrappers. |
| PASM/assembly integration | Partial | Raw cog program startup via `p2.cog_start_hex()` exists. Safe `p2.asm` aliases now expose `getrnd`, `getct`, `waitx`, `hubset`, SD blob loading into `bytes`, grouped `cognew/cogstop/cogcheck` shape, queryable `capabilities()` / direct `capability(name)` / `required_capability_keys()` / `abi()` / direct `abi_value(name)` / `required_abi_keys()` diagnostics, `audit()` with structured list-valued diagnostics plus `audit_problems()` / `audit_ok()` policy-consistency and missing-key checks, a hardware-verified `launch_probe()` known-good marker/stop fixture, an exact SD-staged marker fixture through `marker_blob()` plus `launch_loaded_probe()`, and fixed `fixture_call(operation, lhs, rhs)` PASM mailbox argument/return proofs for `add`, `sub`, `xor`, `and`, and `or`, generated from `tools/p2/pasm/fixture_call.pasm`. `examples/pasm_direct.be` now hardware-runs to `pasm direct done`, demonstrating the safe intrinsics, policy metadata, clean audit helper status, marker fixture launch/stop, and named fixture call result paths without claiming arbitrary PASM execution or a general function bridge. The focused `make p2-smoke-pasm-policy-min` smoke passes on the current native-Catalina XMM image. The staged Priority 3 aggregate uses 8.3-safe aliases `/tests/p2/pasmly.be` and `/tests/p2/pasmpol.be` to avoid FAT long-name collisions and now hardware-verifies both layout/marker-fixture coverage and compact policy/fixture-call coverage. | Add public arbitrary PASM ABI, broader fixture coverage, general function bridge, full ABI docs, and unsafe build flag. |
| Multicog Berry VM coverage | Partial | Interim `p2.cog.spawn(closure, ...primitive_args)` accepts a live Berry closure and returns stoppable integer handles. The verified pin 38 / pin 39 LED use case is the GPIO-specific `native_blink` fast path for `spawn(closure, pin, rate_ms)`: it invokes the passed closure once during setup, uses the positive integer return value as the period, runs a native pin loop on the spawned cogs with a 2048-byte stack, and reports `model == "native_blink"` plus `native_blink == true` in handle diagnostics. `p2.cog.capabilities()` / direct `capability(name)` / `required_capability_keys()` expose the current `native_blink_info_stop_only` handle model: `id(handle)`, `info(handle)`, `status(handle)`, non-blocking `join(handle)` with result/error fields, `result(handle)`, `error(handle)`, `stop(handle)`, `kill(handle)`, and aggregate `cleanup_result()` are backed handle APIs; stop/kill result maps report cleanup policy, slot release, and post-stop handle invalidation, while `cleanup_result()` stops and releases every spawned closure-cog slot and reports released handles, stopped raw cogs, floated pins, and resource counters. `p2.cog.audit()` returns structured diagnostics without spawning cogs. `make p2-smoke-cog-closure` hardware-verifies actual spawned-handle join/result/error, aggregate cleanup of two live native-blink handles, cleanup after a raw `p2.cog.stop(cog_id)` of a safe native-blink child cog, a bounded three-iteration spawn/join/kill lifecycle loop with an empty registry after each cleanup, and failed spawn cleanup for unsupported shape, setup exception, and unsupported live-object argument paths. `make p2-smoke-cog-closure-min` is the routine Priority 4 hardware leg and verifies the native-blink handle, info, nonblocking join/result/error helpers, kill cleanup, pin float, and empty registry without the heavier regression probes. `make p2-smoke-cog-policy-min` verifies the metadata-only contract including direct capability lookup. Blocking result waits/cross-cog exception propagation remain unsupported. The default firmware rejects unsupported closure-cog shapes instead of running the unsafe shared-VM dispatcher; that dispatcher is diagnostic-only behind `BE_P2_ENABLE_UNSAFE_SHARED_VM_COG`. | Evolve toward independent per-cog VM/GC isolation before claiming arbitrary closure execution. |
| Closure-in-cog coverage | Partial | Captured closures are no longer only guarded: the interim shared-VM closure-cog path keeps the closure rooted in a VM registry and calls it with primitive args from another cog while REPL execution is paused. `p2compat` now documents the child-VM transfer boundary and exposes it through `child_vm_transfer_policy()`: nil/bool/int/bounded-string copies are partial support, non-captured closure-name selection is staged, captured closures plus live object graphs are unsupported, and ownership/resource transfer is explicitly false. Direct helpers `child_vm_policy(name)`, `child_vm_copyable_type(name)`, and `child_vm_rejected_type(name)` let tooling query policy fields and type-policy lists without parsing the returned map; `required_child_vm_policy_keys()` and `audit()` now make missing transfer-policy metadata explicit. `p2compat.child_vm_partition_policy()` exposes `p2.heap_info()` `vm_partition_*` diagnostics for runtime-derived child-VM heap sizing, but keeps `production_count_selected == false` and records that routine priority work should stop here unless the native partition allocator or isolated child-VM cog runtime changes. Native `p2.vm_copyable()` hardware smoke coverage verifies nil/bool/int/string copyable diagnostics, list/map/function rejection diagnostics, and no-argument rejection on the flashed XMM profile; `p2.vm_copyable_args()` now verifies empty/pass/reject planned argument-list preflights with first rejected index/kind diagnostics, and focused hardware coverage pins positive child-VM partition bytes, partition capacity, free-capacity bounds, and parent heap-context selection before child calls. `p2.vm_call(...)`, `p2.vm_call_once(...)`, and `p2.vm_invoke(...)` now use that primitive-copy boundary and expose `ok` / `status` fields for successful primitive child calls and bad live-object arguments before selecting child VM runtime state. Persistent child-VM lifecycle helpers `p2.vm_open/eval/get/close` now expose the same scalar status shape for normal lifecycle steps, inactive slots, missing globals, unsupported child values, partition failures, and release failures; `p2.vm_info(slot)` adds a non-mutating slot-state summary for inactive/active/cog-running state, child handle presence, partition readiness, cog state, and runtime-lock availability. `p2.cog.capabilities()` now exposes an explicit `isolated_child_vm_cog_policy` and reason string for the current unsupported Catalina XMM child-VM-cog boundary. | Replace the REPL-idle shared-VM proof with true independent VM closure launch and broader hardware-verified serialization/rejection rules. |
| IPC coverage | Partial | Importing `p2ipc` now attaches cooperative `p2.channel`, `p2.mailbox`, `p2.shared.Buffer`, and `p2.mutex` APIs with host and P2 smoke coverage; mutexes use `p2.lock` hardware locks when available and fall back to an in-VM cooperative lock when not available or allocation fails. `p2ipc.capabilities()` / `capability(name)` report the current-VM IPC contract, result diagnostics, optional hardware-lock backend, fallback mutex support, non-mutating channel/mailbox `ready_result()` readiness diagnostics, non-mutating object `lifecycle_result()` / generic `p2ipc.lifecycle_result(obj)` resource diagnostics, reusable clear cleanup for channels/mailboxes/shared buffers, close-time payload release, non-consuming channel snapshot and mailbox peek diagnostics, payload-contract result diagnostics, standalone `p2ipc.payload_result(value)` current-VM reference/copyability diagnostics, bounded `self_test_result()` cleanup diagnostics, bounded native cog-attention wait availability, and no cross-VM support; `p2ipc.attention_policy()` / `attention_policy_value(name)` explicitly report that native `p2.cog.wait_attention_result()` is available on current P2 images but not wired to channel/mailbox wakeups yet. `p2ipc.contract()` makes the no-cross-cog-wakeup, no-serialization, no-ownership-transfer, lifecycle-result, readiness-result, snapshot/peek diagnostics, clear-cleanup, close-cleanup, self-test policy, attention policy, payload-copy policy, and current-VM-reference payload boundary queryable. `p2ipc.required_capability_keys()` and `p2ipc.required_contract_keys()` expose the expected metadata fields, while `p2ipc.audit()` / `audit_problems()` / `audit_ok()` self-check that the capability and contract maps agree on those boundaries and report missing required keys explicitly. Host coverage now includes capability-map/direct lookup checks, required-key metadata checks, contract and audit snapshot checks, bounded self-test success/failure shape, attention-policy direct lookup and snapshot checks, standalone payload-result checks, payload-contract result fields for channel/mailbox send/receive/snapshot/peek, readiness diagnostics for empty/full/closed/invalid-mode channel and mailbox states, lifecycle diagnostics for live/closed channel/mailbox/mutex objects plus shared buffers, clear-with-payload, buffer-zeroing, and close-with-payload release checks, lock-failure, blocked-lock, default-depth, invalid-depth, buffer snapshot-isolation, invalid buffer input paths, compact `info()` diagnostics for channel/mailbox/buffer/mutex state with returned-map mutation checks, idempotent close/closed-state behavior, and result-shaped channel/mailbox/buffer/mutex diagnostics that distinguish valid `nil` payloads from empty/full/busy/not-locked/closed/error states. `examples/cog_channel.be` now hardware-runs with scalar current-VM channel/mailbox/buffer diagnostics, including full/empty channel and mailbox readiness plus live/full/closed lifecycle state, and reaches `cog channel example done`; the focused `make p2-smoke-ipc` hardware smoke now stages only `modules/p2ipc.be` and runs compact direct REPL probes covering `payload_result()`, a nil-payload channel path, mailbox peek/get, buffer clear, mutex lock/unlock/close, and metadata. | Add actual cross-VM/cross-cog wakeups, serialization rules, and longer stress/soak coverage. |
| Cooperative task coverage | Partial | Native P2 `import task` is now the practical hardware task path: it exposes the compact current-VM cooperative scheduler, reports its 16-slot backend through `task.info()["max_tasks"]` and `task.capability("max_tasks")`, supports Spin2-style aliases (`spin`, fixed-slot startup, `halt`/`hlt`, `cont`, `chk`, `id`), native event inspection/cleanup/readiness helpers (`events`, `clear_all`, string-event `ready_result`), native primitive-object `task.ready_result(...)` for Semaphore/Mutex/Queue/EventFlags/Timer readiness, native cooperative waits over Queue get/put, Semaphore take, Mutex lock, EventFlags any/all masks, and Timer expiry, native `p2ipc` channel/mailbox `task.ready_result(...)` delegation to the source readiness maps, native cooperative waits over current-VM `p2ipc` channel recv/send and mailbox get/put objects including close wakeups, native `Semaphore`, `Mutex`, `Queue`, `EventFlags`, and `Timer` primitives with result diagnostics, including Queue nil-payload/full/empty diagnostics, Semaphore unavailable diagnostics, Mutex busy/not-locked diagnostics, EventFlags invalid-mask/not-ready diagnostics, and Timer not-expired/expired/cancel/restart/remaining diagnostics, result-shaped scheduler diagnostics (`start_result`, `next_result`, `run_result`, `stop_result`, `pause_result`, `resume_result`, `reset_result`, `lifecycle_result`), and queryable `capabilities()`, `capability(name)`, `attention_policy()` / `attention_policy_value(name)`, `execution_model()` / `execution_model_value(name)`, `contract()` / `contract_value(name)`, `required_capability_keys()`, and `audit_ok()` metadata. `make p2-smoke-task-policy-min` hardware-verifies that native surface on the current sibling-Catalina XMM image while uploading only `modules/p2ipc.be` for the current-VM IPC probes and without source-loading `modules/task.be`. `modules/task.be` remains the richer source-level scheduler with 32 fixed slots, Queue/Semaphore/Mutex/EventFlags/Timer helpers, p2ipc wait integration, and host coverage; it is non-default regression coverage because the large source module is not reliable as a routine P2 source-load path on the current XMM image. Host coverage includes capacity, first-free/fixed-slot `spin`, pause/resume/stop plus lifecycle aliases, result-shaped scheduler step/run/reset cleanup diagnostics, lifecycle diagnostics for waiting/free/invalid task handles, closed p2ipc channel/mailbox wait wakeups, capability/contract/audit snapshot checks, bounded self-test success/failure shape, event cleanup, task function error state, malformed wait descriptor containment, timeout wakeups, invalid primitive constructor/mask/timer inputs, and wait descriptors for cooperative primitives. | Independent Berry call stacks/coroutines, true Spin2/PASM switching, cross-cog IPC wakeups, broader hardware timing validation, and stress/soak testing remain open. |
| Debug feature coverage | Partial | `p2.fs_info()`, `p2.status_info()`, `p2.debug_snapshot()`, `p2mem`, heap, module, cache, and PSRAM diagnostics exist. `p2.debug` now exposes backed heap, GC, cog, memory-map, single-pin, 64-pin, smart-pin, and current-cog register diagnostics with smoke coverage. | Add breakpoints, trace controls, source stack traces, task/module/lock/channel internals, broader registers, and PASM debug support. |
| Example coverage | Partial | Interactive examples are documented in P2 docs and handoffs. `make p2-example-safety-audit` locally compiles all `57` example `.be` files, confirms the `56` runnable examples avoid current-image-unsafe line-start `try` / `except` / `for` syntax, and requires explicit final `done` markers while allowing only `examples/core/run_file.be` as support-only input for `run_file_demo.be`. `make p2-smoke-examples-core PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` stages only `examples/core` and passes all core-example final-marker checks including scripted input for `guess_number.be` and `repl.be`; `make p2-smoke-examples-quick PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` stages only board LED blink plus the six native quick smart-pin examples and passes their final-marker checks; `make p2-smoke-examples-smartpin-diagnostics PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` stages only the broader native four-pair smart-pin diagnostic and passes its final marker; `make p2-smoke-examples-bus PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` stages only the I2C scan and SPI JEDEC examples and passes their final-marker checks on the current bus harness; `make p2-smoke-examples-serial PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` stages only the native UART and synchronous-serial loopback examples and passes their final-marker checks; `make p2-smoke-examples-system PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` stages only the CORDIC, PSRAM-cache, REPL-SD, file-SD, and JSON-SD examples and passes their final-marker checks; `make p2-smoke-examples-runtime PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` stages only native task, full closure-cog, closure-cog blink, and PASM examples and passes their final-marker checks; `make p2-smoke-examples-debug PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` stages only the native debug report example and passes its final marker. Focused hardware verification now includes `examples/blink.be`, native `p2.smart` quick examples for `examples/adc_read.be`, `examples/dac_write.be`, `examples/gpio_loopback.be`, `examples/pwm_fade.be`, `examples/nco_counter_loopback.be`, and `examples/quadrature_counter.be`, native `examples/smartpin_diagnostics.be`, `examples/i2c/scan.be`, `examples/spi/jedec.be`, `examples/sync_serial_loopback.be`, all runnable `examples/core` files through `p2-smoke-examples-core`, `examples/task_primitives.be`, `examples/task_scheduler.be`, `examples/task_ipc.be`, `examples/cog_closure.be`, `examples/cordic_demo.be`, `examples/debug_report.be`, `examples/psram_cache_stats.be`, `examples/file_sd.be`, `examples/json_sd.be`, `examples/repl_sd.be`, `examples/cog_channel.be`, and the narrowed quick SD import sweep in `examples/import_all_libs.be`; `examples/blink.be` hardware-runs to `blink done` on LED pin 38 through the quick target; `examples/adc_read.be` hardware-runs to `adc done` with scalar native ADC sample diagnostics; `examples/dac_write.be` hardware-runs to `dac done` with scalar native DAC write diagnostics; `examples/gpio_loopback.be` hardware-runs to `gpio loopback done` with four matching native pin loopback samples on the `0-1` jumper; `examples/pwm_fade.be` hardware-runs to `pwm fade done` with native PWM duty updates; `examples/nco_counter_loopback.be` hardware-runs to `nco counter loopback done` with native counter deltas `34` and `17`; `examples/quadrature_counter.be` hardware-runs to `quadrature counter done` with native `p2.smart` synthetic forward/reverse motion on the documented `0-1` and `2-3` jumpers, reporting directions `1` and `-1`; `examples/smartpin_diagnostics.be` hardware-runs to `smartpin diagnostics done` with native GPIO, count-rises, high-ticks, and async serial byte checks across jumpers `0-1`, `2-3`, `4-5`, and `6-7`; `examples/i2c/scan.be` hardware-runs to `i2c scan done` on the BMP180 harness, reporting scan count `1`, address `0x77` present, chip id `U`, and chip-id match `true`; `examples/spi/jedec.be` hardware-runs to `spi jedec done` after native SPI init/select/transfer/deselect/stop, reporting a four-byte raw response without claiming a specific attached SPI flash ID; `examples/sync_serial_loopback.be` hardware-runs to `sync serial loopback done` through native `p2.smart` constants and asserts the decoded clocked receive byte on the documented `0-1` data plus `2-3` clock jumpers, while `examples/spi_loopback.be` remains a compatibility-named alias for the same synchronous-serial jumper diagnostic; the core target covers run-file path resolution, bounded listing, bounded loop, recursion, floating-point Pi, JSON, anonymous closures, deterministic quicksort, lambda/Y-combinator output, initialized binary tree output, stable string/format output, explicit exception-skip boundary, real serial `input()` in `guess_number.be`, and the bounded mini-REPL quit path; `examples/task_scheduler.be`, `examples/task_primitives.be`, and `examples/task_ipc.be` now hardware-run directly through native `import task` without source-loading `modules/task.be`, covering cooperative task lifecycle, native Queue/EventFlags/Timer primitive diagnostics, native primitive scheduler waits, and native current-VM p2ipc channel/mailbox waits including closed-object wakeups; `examples/cordic_demo.be` hardware-runs to `cordic demo done` with scalar grouped CORDIC/math helper output; `examples/debug_report.be` hardware-runs to `debug report done` with compact backed `p2.debug`, filesystem, PSRAM runtime output, and debug capability/policy fields without source-loading `p2mem`; `examples/psram_cache_stats.be` hardware-runs to `psram cache stats done` with native read-only PSRAM and native cache stats; `examples/file_sd.be` hardware-runs to `file sd example done` with bounded write/read/remove cleanup; `examples/json_sd.be` hardware-runs to `json sd example done` with bounded JSON write/read/remove cleanup; `examples/repl_sd.be` hardware-runs to `repl sd helper done` with read-only SD mount/list diagnostics; the import sweep reaches `import all libs example done` for `binary_heap`, `configstore`, `math`, `p2compat`, `p2ipc`, the active `task` backend, and metadata-only `wifi`; heavier direct import-chain probes separately pass through `p2mem` and `p2smart`. | Add explicit example files requested in `goal.md`; keep user-facing examples quick while heavier import-chain coverage stays in focused probes. |
| Host test coverage | Partial | `make test-host` passes locally: it runs the 54-test desktop Berry suite, then `make test-p2-host` runs P2-specific host regressions for fake-PSRAM `libstore`, task, `p2ipc` happy and edge paths including invalid channel/buffer inputs, IPC diagnostic snapshots, idempotent close/closed-state behavior, and result-shaped nil-payload/full/busy/not-locked/closed/error diagnostics, `binary_heap` including sort empty/singleton behavior and caller-array preservation when comparators raise, `p2compat` including status-report diagnostics, nested report/audit snapshot isolation, and child-VM copy-boundary capability metadata, `configstore` including load-result diagnostics, `.bec` manifest/fallback/planning behavior, file-backed SD-style import/cache behavior including source metadata and path removal, `libstore` source-cache no-op/error/reset/churn paths plus cache/status/info diagnostic snapshot isolation, `p2mem` stats/module/cache/gc/evict diagnostics snapshot isolation including invalid single-module lookups, and the Berry-level `p2mem` native-cache facade including native-cache info/entry enumeration failure diagnostics, reset/get result wrappers, invalid reservation/payload/index/range result wrappers, owner lookup/history failures, owner-level status/get/verify/release failures, verified put/replace verify exceptions, single and bulk module-source invalid-name diagnostics, module-source native-cache-unavailable planning, write-failure cleanup including cleanup-release failure diagnostics, verify-failure cleanup, non-destructive replace, and failed batch-warm rollback. | Add host tests for native C cache eviction/errors, hardware-backed closure serialization, and broader low-memory behavior. |
| P2 hardware test coverage | Partial | `make p2-smoke`, `make p2-smoke-quick`, `make p2-smoke-edge32`, and `make test-p2` exist for broader runs. Focused targets now cover the normal progress path without broad suites, including focused `p2-smoke-priority1`, upload-capable `p2-smoke-priority2`, `p2-smoke-priority3`, composed `p2-smoke-priority1-4`, and minimal `p2-smoke-priority1-4-min`, plus staged variants for already-staged cards. Focused targets include `p2-smoke-core-builtins-min`, `p2-smoke-stdlib-min`, `p2-smoke-sd-file-core-min`, `p2-smoke-sd-file-min`, `p2-smoke-libraries-lazy-min`, `p2-smoke-p2mem-native-cache-min`, `p2-smoke-bec-fallback-min`, `p2-smoke-smartpins-focused`, `p2-smoke-smartpins-normal-pin`, `p2-smoke-smartpins-quadrature-static`, `p2-smoke-smartpins-quadrature-motion`, `p2-smoke-smartpins-quadrature-diag`, `p2-smoke-smartpins-counter-modes`, `p2-smoke-smartpins-output-modes`, `p2-smoke-smartpins-adc-dac-native`, `p2-smoke-smartpins-adc-dac-diag`, `p2-smoke-smartpins-nco-duty-diag`, `p2-smoke-pasm-policy-min`, `p2-smoke-cog-policy-min`, `p2-smoke-cog-closure-min`, `p2-smoke-task-policy-min`, `p2-smoke-ipc`, `p2-smoke-ipc-policy-min`, and `p2-smoke-debug-capabilities-min`; `p2-smoke-p2mem-policy-min` exists as a source-load policy target but is not a routine progress target on the current XMM image after the latest focused attempt timed out while source-loading `p2mem`. The normal XMM image has recent `/dev/ttyUSB0` verification for these minimal smokes plus selected focused API/math/smart-pin checks with jumpers `0-1`, `2-3`, `4-5`, and `6-7`. The `priority1-4-min` aggregate now also includes focused SD/file proof through `smoke_sd_min.be`, focused normal-image stdlib proof through `smoke_stdlib_min.be`, a bounded lazy SD library policy proof through `smoke_libraries_lazy_min.be`, a native XMM/PSRAM runtime-shape check through `p2.heap_info()`, `p2.psram_info()`, and `p2.psram_cache_info()`, direct native smart-pin high-counter, PWM-output, and ADC/DAC low-vs-high proofs on jumper `0->1`, a compact native async latest-sample proof where unpaced `0x12` then `0x34` samples as `0x34`, safe fixed PASM fixture-call proofs for add/sub/xor/and/or, child-VM live-object argument rejection before runtime selection, a real one-shot child-VM call returning `42` with partition release, a persistent child-VM open/eval/get/close lifecycle proof, explicit isolated-child-VM-cog unsupported policy evidence, native cog cleanup empty-registry evidence, compact `p2ipc` capability/contract/audit metadata, p2ipc payload-result copyability/rejection diagnostics, tiny channel/mailbox payload checks, shared-buffer fill/clear/read coverage, mutex lock/unlock/close coverage, native task scheduler policy evidence, a real native task spin/next completion check, minimal Queue/Semaphore/Mutex/EventFlags/Timer primitive checks, and a real native-blink closure-cog spawn/join/kill cleanup proof, so routine health checks cover real Priority 1 SD/file, stdlib, and lazy-import policy, real Priority 2 smart-pin signal, output, and analog behavior, real Priority 3 PASM fixture-call behavior, and real Priority 4 VM lifecycle and VM-cog boundary policy, IPC, task scheduler policy, primitive, and multicog behavior without broad runtime. The focused `p2-smoke-priority1` aggregate runs inline core built-in, collection, and one-line SD file checks, then uploads only the small SD-file-core and stdlib-min smokes instead of the large source-module set; `p2-smoke-priority1-staged` remains the already-staged import/cache/churn/library aggregate. The focused `p2-smoke-priority1-4` target composes the current focused Priority 1, 2, 3, and 4 make targets; `p2-smoke-priority1-4-staged` remains the broader already-staged serial regression. The focused `p2-smoke-priority4` aggregate and already-staged `priority4` serial suite now pass through p2compat native VM-boundary probes, `cog-closure-min`, native task policy, and compact real IPC behavior on the current sibling-Catalina XMM image. The focused Priority 2 smart-pin path now uses native `p2.smart` smokes for normal-pin, counter-modes, counter-visible output modes, ADC/DAC sampled shape, quadrature-motion, async RX, and sync diagnostics, avoiding the currently too-heavy full `p2smart` source import during routine priority validation. | Run full scripted SD smoke suite only when broad regression evidence is needed; keep extending focused hardware coverage for new work. |
| Soak/performance coverage | Partial | `make soak-p2` repeats the selected P2 smoke suite for a duration. `docs/performance.md` now defines the required benchmark areas and reporting format without claiming measurements. | Add benchmark hooks, measured results, explicit eviction/GC/cog/channel/GPIO/smart-pin stress, and leak reporting. |
| VGA/video | Unsupported | `p2compat` marks `video_output` and `vga_demo` unsupported in the current default build. `examples/vga_test_pattern.be` hardware-runs to `vga test pattern done` on the current native-Catalina XMM image after reporting those unsupported records instead of faking a pattern; `make p2-smoke-examples-unsupported PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` keeps this boundary repeatable. | Implement real video output only behind backed hardware/build support. |
| USB keyboard/mouse/HID | Unsupported | `p2compat` marks `usb_hid` and `usb_demo` unsupported in the current default build. `examples/usb_keyboard_mouse.be` hardware-runs to `usb keyboard mouse done` on the current native-Catalina XMM image after reporting those unsupported records instead of faking input; `make p2-smoke-examples-unsupported PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina` keeps this boundary repeatable. | Implement real USB support only behind backed hardware/build support. |
| WiFi/AirLift | Partial | `import wifi` compiles/imports when module is present; `wifi.capabilities()` / `capability(name)`, `required_capability_keys()`, `default_config()`, and metadata-only `audit()` / `audit_problems()` / `audit_ok()` expose the SPI transport, hardware-deferred status, request-init boundary, import-time init no-op, default pins, status-name table, and missing capability-key reporting without touching hardware. `examples/wifi/detect.be` now hardware-runs to `wifi detect done` on the current native-Catalina XMM image as a metadata-only diagnostic after staging the current `/modules/wifi.be`; it reports deferred SPI transport, audit policy, pins `16..22`, and status names without calling `wifi.init()`. ESP32-C6 hardware detection still pending READY/BUSY troubleshooting. | Complete hardware detection if retained in scope. |

## Standard library snapshot

| Module/feature | Status | Notes |
| --- | --- | --- |
| `print` | Verified | Basic REPL prints documented. Needs automated test coverage. |
| `list` | Verified | `x=list(); x.push(42); print(x.size())` documented. Needs automated test coverage. |
| `map` | Verified | Insert/find and map iteration documented. Needs automated test coverage. |
| `range` | Partial | Literal ranges plus `range()` increments, descending ranges, accessors, string forms, `setrange()`, independent iterator exhaustion, retargeted iterator preservation, iteration, and selected value errors have P2 smoke coverage. The non-precompiled range registration table exports `incr()` after P2 RAM smoke found it missing; the focused `/tests/p2/smoke_range.be` re-run now passes on the current native-Catalina XMM image. Broader low-memory and full-suite coverage remain open. |
| `string` | Verified | `toupper` and `find` documented. Needs automated test coverage. |
| `math` | Verified | Native P2 `math` is hardware-verified on the normal XMM image for finite trig/log/pow helpers, CORDIC-backed trig/inverse-trig contract through `accel_info()`, rounding helpers, angle conversion, `nan`/`inf` constants and JSON dumping, non-finite string/comparison behavior, `min`/`max` value/type/error behavior, no-argument fallbacks, deterministic `srand`/`rand`, core constants, and invalid-result nil behavior. Source-level `math.capabilities()` / `capability(name)`, `required_capability_keys()`, and `audit()` / `audit_problems()` / `audit_ok()` now expose and self-check the finite fallback, invalid-domain, non-number fallback, constant, rounding, min/max, angle conversion, missing capability-key reporting, and CORDIC/non-CORDIC backend contract. |
| `json` | Verified | `json.load` and `json.dump` documented. Needs automated test coverage. |
| `bytes` | Verified | Construction, `size()` API shape, indexing, `fromstring`, `tohex`, add/get/resize/copy/append/range/mutation behavior have P2 smoke coverage or prior live checks. P2 smoke covers construction, mutation, conversion, extra method API shape, base64 API shape including one-, two-, four-, and five-byte padding plus three- and six-byte no-padding quanta, fixed-size bytes, float packing, fromhex/tohex, setbytes source preservation, reverse, length-based truthiness, fromstring/copy isolation, appendb64, and selected errors. Needs mapped-pointer and broader low-memory coverage. |
| `file` / `open` | Verified | SD read/write examples documented. P2 smoke now covers write, append, `r+`, `w+`, and `a+` read/write modes, flush/tell/size/seek/read/readbytes/readlines, rename, and remove on tiny cleanup-oriented files. Needs broader error tests. |
| `os` | Verified | `listdir`, `mkdir`, `chdir`, `getcwd`, `remove`, `rename` documented. Needs automated test coverage. |
| `os.path` | Verified | `isdir`, `isfile`, `exists`, missing-path negatives, and basename/dirname/join/split/splitext helper shapes including local no-extension paths have P2 smoke coverage. Needs broader edge-case coverage. |
| Other built-ins/modules from `goal.md` | Planned | Must be audited against the exact included Berry version. |

## Board and hardware snapshot

| Hardware area | Status | Notes |
| --- | --- | --- |
| P2 Edge no-PSRAM pins | Verified | LEDs `56` and `57`; SD `58..61`; serial `62..63`. |
| P2 Edge 32 MB pins | Verified | LEDs `38` and `39`; PSRAM reserves `40..57`; SD `58..61`; serial `62..63`. |
| I2C | Verified | BMP180 on `SCL=25`, `SDA=24`; scan finds `0x77`; chip ID read returns `0x55`. |
| SPI | Partial | Initialization and one-byte raw read documented; full JEDEC validation needs known attached target. |
| GPIO | Partial | No-PSRAM LED checks documented. `p2smart.GPIOInput` / `GPIOOutput` now have host call-sequence coverage, wired loopback hardware coverage across pins `0-1`, `2-3`, `4-5`, and `6-7`, and hardware-run `examples/gpio_loopback.be` coverage for the documented `0-1` jumper pair. |
| PSRAM block API | Verified | `p2.psram_test()`, bounded read/write, and cache source round trip documented. |
| SD filesystem | Verified | Mount fallback and SD file operations documented. Full smoke suite still needs fresh run. |
### Current top-level example coverage

Implemented top-level examples now cover LED blink, SD REPL/startup handoff, library import sweep with current IPC/task contract reporting, JSON-on-SD, basic SD file I/O, native quick GPIO loopback, native smart-pin diagnostics, native ADC, native DAC, native PWM, native NCO-to-counter loopback, UART, native SPI, synchronous serial, quadrature, closure-cog native blink, current-VM channel/mailbox/buffer IPC messaging, readiness, lifecycle, and cleanup diagnostics, cooperative task scheduling, native cooperative task/IPC waits, native task primitives, PASM-adjacent intrinsics plus safe marker-fixture launch, fixed named-operation fixture mailbox calls, and unsupported general bridge/blob policy reporting, CORDIC/math helpers, PSRAM cache diagnostics, and debug snapshot reporting. The GPIO loopback example is now hardware-run through native `p2.pin` on the documented `0-1` jumper and reaches `gpio loopback done`; the NCO-to-counter example is now hardware-run through native `p2.smart` on the same jumper and reports fast/slow counter deltas `34` and `17`; `uart_loopback.be` now uses native `p2.smart` directly so it does not source-load the large wrapper, hardware-runs on the same jumper, and reaches `uart loopback done` with samples `65`, `66`, `67`, latest-sample burst `52`, and drain value `68`; `sync_serial_loopback.be` hardware-runs on data jumper `0-1` plus clock jumper `2-3`, uses native `p2.smart` directly, and reaches `sync serial loopback done` after asserting the received byte matches `0x12`; `smartpin_diagnostics.be` now uses native `p2.smart` directly and hardware-runs across the documented `0-1`, `2-3`, `4-5`, and `6-7` jumpers to `smartpin diagnostics done`, checking GPIO low/high, one counted rise, positive high-ticks, and one async serial byte on each pair; `cog_closure.be` is now hardware-run for the native-blink closure-cog shape on pins `38` and `39`, reports handles/results, stops/kills both handles, and reaches `cog closure example done`; `pasm_direct.be` is now hardware-run for safe PASM-adjacent intrinsics, marker-fixture launch policy, fixture add result `42`, fixture sub result `42`, and fixture xor result `90`, reaching `pasm direct done`; `task_scheduler.be`, `task_primitives.be`, and `task_ipc.be` now hardware-run directly with native `import task`, no source scheduler preload, covering lifecycle diagnostics, Queue/EventFlags/Timer primitive diagnostics, native primitive waits, current-VM p2ipc channel receive/send and mailbox get/put waits, and closed channel/mailbox wakeups; `cog_channel.be` is now hardware-run for current-VM channel/mailbox/buffer readiness, lifecycle, and cleanup diagnostics and reaches `cog channel example done`. The dedicated smart-pin smoke suites also cover bidirectional aggregate jumper diagnostics for the documented pairs. VGA and USB example files now explicitly report unsupported `p2compat` records instead of faking demos.

`examples/pwm_fade.be` is now a native `p2.smart` example hardware-run on the current native-Catalina XMM image and reaches `pwm fade done` after scalar duty updates for values `0`, `40`, `80`, `120`, `160`, and `200`.

`examples/quadrature_counter.be` is now hardware-run on the current native-Catalina XMM image and reaches `quadrature counter done` using two jumper pairs: pins `0` and `2` drive quadrature inputs `1` and `3`, forward motion reports delta `8` / direction `1`, and reverse motion reports delta `-8` / direction `-1`.

`examples/sync_serial_loopback.be` is now the canonical hardware-run synchronous-serial jumper example on the current native-Catalina XMM image and reaches `sync serial loopback done` through native `p2.smart` constants only, without importing the large `p2smart` source module. It reports the bounded clocked receive policy as verified for the documented `0-1` data and `2-3` clock jumpers, prints the normal clocked TX/RX/clock mode-plan values, and records the native one-word receive proof. `examples/spi_loopback.be` remains a compatibility-named alias for that synchronous-serial proof; broader SPI framing is covered separately by the native `examples/spi/jedec.be` diagnostic.

`examples/vga_test_pattern.be` and `examples/usb_keyboard_mouse.be` are now hardware-run on the current native-Catalina XMM image through the focused `p2-smoke-examples-unsupported` target and reach their explicit final markers while reporting backed `p2compat` unsupported records instead of faking VGA or USB behavior.

`examples/nco_counter_loopback.be` now hardware-runs through native `p2.smart` with scalar output on the current native-Catalina XMM image and reports counter deltas `34` and `17` for the two NCO increments before reaching `nco counter loopback done`.

`examples/cog_closure_blink.be` now hardware-runs on the current native-Catalina XMM image and reaches `cog closure blink done` after stopping/killing the native-blink handles and floating pins `38` and `39`.

The legacy `examples/p2/` helper examples now also have focused hardware evidence on the current native-Catalina XMM image through `make p2-smoke-examples-p2 PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`: bounded LED blink, pin helpers, smart-pin helpers, timing helpers, scalar low-level hardware helpers, native-blink closure cleanup, and source-backed cog unsupported-policy reporting all reach explicit final markers.

`examples/wifi/detect.be` now hardware-runs on the current native-Catalina XMM image as a metadata-only WiFi/AirLift diagnostic and reaches `wifi detect done` without initializing the peripheral.

`examples/import_all_libs.be` now includes metadata-only `wifi` in its quick import sweep and has prior hardware evidence to `import all libs example done`; a narrow focused target attempt staged its module/example inputs but timed out before the final marker on the current XMM image, so that aggregate is not a routine retry path. `p2mem` and `p2smart` remain excluded from that user-facing example because they make the sweep slow, while separate direct import-chain probes pass through both modules.
### Berry compatibility smoke additions

`tests/p2/smoke_compat.be` now provides scripted P2 smoke coverage for the safe non-interactive core builtins and modules: `print`, `classname`, `classof`, `str`, `number`, `int`, `real`, `bool`, `type`, `size`, `super`, `assert`, `compile`, `module`, `issubclass`, `isinstance`, `call`, `list`, `map`, `range`, `bytes`, `time`, `global`, `introspect`, `solidify`, and `strict`. It also samples closures/upvalues, loop-variable closure capture, loop `break`/`continue`, varargs, richer `call()` argument expansion including explicit nil terminal-list arguments and bound methods, expanded `list`/`map`/`range` mutation, values snapshot isolation, broad compat values, and iteration behavior, and expanded `bytes` mutation/conversion behavior. The serial `scripts/p2/repl_smoke.py --suite compat` harness now covers `input()` with an explicit prompt/response handshake so the check does not block unattended execution.

`tests/p2/smoke_call.be` adds dedicated compact builtin `call()` coverage for
fixed-argument functions, captured closures, varargs functions, varargs-only
functions, terminal list expansion including explicit nil arguments and nested-list preservation, non-terminal list preservation, native
function calls, moderate argument-list expansion, and class constructor calls including terminal-list expansion.

`tests/p2/smoke_compile_module.be` adds dedicated compact core `assert`,
`compile`, and `module` coverage for assert pass/fail behavior, compile
success/failure, compiled closure return/capture and retained-state behavior, compiled local list/map collection mutation, compiled global lookup, compiled closure retained state, module member mutation, and
introspect-assisted module metadata.

`tests/p2/smoke_conversions.be` adds dedicated compact core conversion and type
coverage including range type classification for `str`, `number`, `int`, `real`, `bool`, `type`, `size`, custom
conversion hooks, invalid `int`/`real` conversion fallbacks, `classname`,
`classof`, `super`, `issubclass`, and
`isinstance`.

`tests/p2/smoke_collections.be` adds dedicated compact builtin collection
coverage for list method API shape including `size()`, indexing/slicing/iteration including iterator exhaustion/mutation/copy/concat/find/clear, bidirectional copy isolation, list-of-indices selection, keys, negative-index mutation,
map method API shape including `keys()`/`values()`, lookup/insert/remove/keys/values including post-mutation snapshots and keys/values snapshot isolation, boolean keys, value iteration, stringification, bulk removal, and selected key errors, plus range iteration, accessors, advanced increments, positive and negative-increment `setrange()`, string forms, and selected value errors. P2 RAM feedback fixed the non-precompiled range method table so `incr()` is exported alongside `lower()` and `upper()`.

`tests/p2/smoke_bytes.be` adds dedicated compact builtin `bytes` coverage for
`size()` API shape, method API shape, construction, add/get endianness, resize/clear, equality/concat/append,
empty-append no-op behavior, appendhex, indexing/ranges, range-slice copy isolation, mutation/index errors, bidirectional copy isolation, string
conversion, and hex conversion.

`tests/p2/smoke_introspect.be` adds dedicated native `introspect` module
coverage for module/class/instance member lookup and mutation, method
classification including focused `ismethod()` saved-bound-member, saved function-valued member, saved inherited lookup, and inherited lookup edge cases, pointer conversion and same-VM round-trip behavior,
`solidified()`, `members()` edge cases, fallback reads, and missing-module
handling.

`tests/p2/smoke_global.be` adds dedicated native `global` module coverage for
API/helper shape, contains/listing/member lookup, compile visibility of created globals, mutation,
list- and map-valued globals, non-string edge cases including bool and nil, idempotent undef cleanup, global
table view after create/remove, and cleanup-oriented undef/redefine behavior.

`tests/p2/smoke_string.be` adds dedicated compact native `string` module
coverage for module/API shape, API shape, find/count including empty-subject boundaries, no-match and adjacent multi-character behavior/split, escape/translate/replace including adjacent-match and expanding replacement semantics, format conversions, additional format conversion edges including repeated `%i`/`%c` custom conversion-hook invocation, adjacent literals,
range indexing, prefix/suffix helpers including empty-subject negatives, and string multiplication including selected invalid cases.

`tests/p2/smoke_json.be` adds dedicated compact native `json` module coverage
for API shape, scalar and exponent parsing, escape and Unicode decoding, empty container load/dump behavior, malformed input and trailing-token rejection, compact advanced Unicode/control-character cases including escaped object-key and multi-entry array-value decoding, nested object/list parsing, whitespace-tolerant object/list/top-level array and scalar parsing, formatted dumps including nested-list indentation, map subclass dumps, and
round trips.

`tests/p2/smoke_json_stack.be` adds compact generated JSON coverage for a
128-key object, a generated list of nested objects, and that generated list embedded under an object key, exercising parser
growth/stack behavior without turning the smoke into a large memory stress.

`tests/p2/smoke_time.be` adds dedicated native `time` module coverage for
module/API shape, `clock()`, deterministic `dump()` map shape and fixed epochs, integer dump-field
shape, dump-map mutation isolation, invalid scalar including bool-false and empty/non-empty collection dump inputs, and `time()` /
`dump(time())` consistency without assuming a real RTC date.
On normal XMM images where optional `time` is absent, the smoke now emits
`P2_SMOKE_SKIP time` and then `P2_SMOKE_PASS time`; opt-in extended diagnostic
images still execute the full time checks.

`tests/p2/smoke_solidify.be` adds dedicated low-noise native `solidify` module
coverage including introspected helper discovery for API shape, no-argument behavior, invalid-type errors for dump and compact, repeated compact idempotence, compacting a
tiny class, inherited method behavior after compaction, static member/method
read and mutation behavior after compaction, and optional `nocompact()` behavior including invalid inputs when that helper
is present. The focused smoke now passes on the normal P2 XMM image; P2 keeps
instance-constant emission for list/map/bytes constants unsupported rather than
pulling extra generated class objects into the compact build.

`tests/p2/smoke_debug.be` adds dedicated native `debug` module coverage for
API shape, introspected helper discovery, `attrdump()` no-crash behavior on a class and instance, and `caller()` zero-depth boundary plus stack introspection
with direct, wrapped, and nested names resolved through `introspect.name()`.
On normal XMM images where optional `debug` is absent, the smoke now emits
`P2_SMOKE_SKIP debug` and then `P2_SMOKE_PASS debug`; opt-in extended diagnostic
images still execute the full debug checks.

`tests/p2/smoke_strict.be` adds dedicated native `strict` module coverage for
strict compiler-mode activation, method-body plus branch-, loop-, and conditional-expression global lookup, expression-without-side-effect rejection,
missing-global rejection including function-scope lookups, accepted side-effect
expressions, known-global compile visibility including function-scope lookups,
and cleanup after `global.undef()`.
On normal XMM images where optional `strict` or `global` is absent, the smoke
now emits `P2_SMOKE_SKIP strict` and then `P2_SMOKE_PASS strict`; opt-in
extended diagnostic images still execute the full strict checks.

`tests/p2/smoke_global.be` and `tests/p2/smoke_sys.be` also keep their full
extended-image module checks while emitting `P2_SMOKE_SKIP global` /
`P2_SMOKE_SKIP sys` and pass markers on normal XMM images where those optional
modules are absent.

`tests/p2/smoke_vm_ops.be` adds compact VM operator coverage for arithmetic,
bitwise operations, comparisons, string/list slicing, and class operator
overloads.

`tests/p2/smoke_vm_error_paths.be` adds focused VM runtime edge coverage for
unary/binary/call type errors, invalid string repetition, instance operator
overloads for subtraction/multiply/divide/modulo/unary operations, default
instance truthiness, invalid comparison result types, instance/class attribute
errors, and named-global reads/writes through the `global` module.

`tests/p2/smoke_be_api_edges.be` adds safe Berry-level coverage for selected C
API edge paths using closures, builtin list/map instance checks, pointer
conversion, missing module-member lookup, no-op non-object member setting, list
copy isolation, closure upvalues, comparisons, inheritance, and function type
checks.

`tests/p2/smoke_function_capture.be` adds focused function/closure returned-function classification and lifetime
coverage for an escaped closure stored in a global-like variable and independent
factory closures that keep separate mutable captured state.

`tests/p2/smoke_errors.be`, `tests/p2/smoke_exception_assert.be`, and
`tests/p2/smoke_divzero.be` currently emit explicit `P2_SMOKE_SKIP ...`
markers and then pass on the normal P2 image, because that image can hang on
`try/except` execution. The earlier exception, assert, and divzero capture
coverage remains source-level reference material until that runtime path is
fixed.

`tests/p2/smoke_classes.be` adds compact class/object coverage for class
iteration, invoking a class stored in a module member, static fields/methods including post-construction static updates,
and indirect member access with `.(name)`, including dedicated module/class/instance indirect member read/write/call including module function calls/chained-update coverage including computed static method dispatch.

`tests/p2/smoke_static_super_member.be` adds focused class/static regression
coverage for subclassing from a superclass stored in a module member while
declaring static members on the subclass.

`tests/p2/smoke_static_decls.be` adds focused class/static declaration coverage
for legacy `static name` declarations, grouped `static var` declarations,
class-vs-instance attribute errors, instance reads of static values, and
function-valued static members.

`tests/p2/smoke_virtual_setmember.be` adds focused virtual-member write coverage
for class `setmember()` dispatch, virtual attribute assignment, rejected virtual
assignment, and the upstream regression shape where function values assigned
through `setmember()` must remain callable.

`tests/p2/smoke_syntax.be` adds compact syntax coverage for f-strings including indexed expressions with computed map keys and computed-width formatting and the
walrus operator across locals, loops, globals, list indexes, and instance
members.

`tests/p2/smoke_walrus_edges.be` adds focused walrus regression coverage for
local builtin-name shadowing, global/member/index walrus expressions returning
the assigned value, and cleanup of temporary global-module state.

`tests/p2/smoke_sd.be` now begins with read-only `p2.fs_info("/")`
mount evidence for the current FAT32 baseline (`mount_result_name == "ok"`,
`partition_start == 2048`, `volinfo_result_name == "ok"`, `sd_response == 0`
when reported, and FAT32 `filesystem_type == 2` when reported), then covers
SD-backed `file`, `os`, and `os.path` behavior through
create/write/append/`r+` update/`w+`/`a+`/flush/tell/size/seek/read/readbytes/readlines/rename/remove checks, missing-path negatives, temporary directory mkdir/chdir/getcwd/isdir/listdir cleanup, cwd-relative file creation/removal, plus basename/dirname/join/split/splitext helper-shape checks including local no-extension paths. This is coverage for the current SD-card filesystem mapping, not a claim that all host-like OS behavior exists on bare metal.

`tests/p2/smoke_sd_main.be` stages `/berry/main.be` source-path coverage by
creating a tiny main script, running it explicitly, and removing it so future
boots are not changed by the smoke. Startup auto-run still needs a hardware
boot test before it should be marked verified.

`tests/p2/smoke_import_cache.be` adds read-only repeated-import coverage for
native and SD-loaded modules. It checks that repeated imports keep the same
module identity for the current SD module set plus native `json`, verifies the
repeated-import/cache/SD-import/low-memory metadata anchors for each current SD module, checks `libstore.info()` / `source_stats()` source size/hash parity, and exercises
`libstore.cache_source(name)` / `libstore.cached_source(name)` for the full
current SD module set only when the active policy reports PSRAM source-cache
support.
`libstore.capabilities()` / `capability(name)`, `required_capability_keys()`,
and metadata-only `audit()` / `audit_problems()` / `audit_ok()` now expose and
self-check the curated module coverage table, policy constants, default path
roots, `.bec` fallback metadata, valid module-name rules, and missing
capability-key reporting without scanning SD or mutating cache state.

`tests/p2/smoke_import_churn.be` adds a bounded low-memory/import regression
that also checks `libstore.info()` / `source_stats()` source size/hash parity
check. It allocates a modest temporary batch, forces `p2.gc()`, then verifies
that repeated imports of the current SD module set plus native `json` still
preserve module identity and safe behavior.

`tests/p2/smoke_import_all_libs.be` imports the current SD module set and checks behavior-smoke metadata plus source size/hash parity plus
safe non-probing behavior for each module. It deliberately avoids WiFi hardware
detection and peripheral transactions.

`tests/p2/smoke_import_alias.be` checks `import name as alias` for native and
SD-loaded modules, including native `string`/`math` plus SD `json`, `libstore`, and
`p2compat`.

The import-layout smoke keeps the staged `/berry/lib` and `/berry/app` source
checks cleanup-oriented by removing its temporary modules after import.
Temporary-file layout smokes assert their temp paths are absent before staging
files instead of pre-deleting possible pre-existing user content. They remove
the files they create, and remove temporary directories only when the smoke
created those directories.
The compact file/config smokes follow the same preservation rule for their
temporary files and config entries, including checking that a missing-config
negative test path is absent before calling `remove`.

`tests/p2/smoke_import_missing.be` checks that a missing module does not import, reports missing compiled-status metadata, and reports recovered source metadata after staging
silently, that `libstore` reports explicit missing source/compiled metadata,
and that a failed import does not poison the cache when the previously missing
module is staged under `/berry/app` and imported later.

`tests/p2/smoke_import_order.be` stages the same temporary module under
`/modules`, `/berry/lib`, and `/berry/app` to verify the compatibility
`/modules` root remains first. It refuses to pre-delete pre-existing temp
module paths before staging this check.

`modules/p2compat.be` records supported, staged, partial, and unsupported
bare-metal capabilities so host-like APIs are documented explicitly instead of
being represented by silent stubs. The capability table includes supported
package-style SD imports and staged `.bec` sidecar manifests, while keeping
`.bec` execution and host-like APIs separate. It also exposes child-VM transfer
and partition-sizing policies so tooling can query primitive copy rules,
rejected live-object types, and runtime `vm_partition_*` capacity diagnostics
without implying production partition sizing is complete. The focused
`p2compat` serial suite verifies the current capability table with short direct
metadata probes.

`modules/configstore.be` and `tests/p2/smoke_configstore.be` add source-level
coverage for `/berry/config/*.json`, including case-insensitive suffix
normalization, using normal `json`, `open`, `os`, and SD
paths, including suffix normalization, missing fallbacks/removes, listing, and
filename-only validation. `configstore.capabilities()` / `capability(name)`,
`required_capability_keys()`, and `configstore.audit()` / `audit_problems()` /
`audit_ok()` make the root path, result helpers, JSON-null handling, FAT `.JSO`
listing support, diagnostic metadata consistency, and missing capability-key
reporting queryable. Host coverage also pins `configstore.load_result()`
for missing, valid, malformed JSON, and invalid filename diagnostics,
`configstore.save_result()` success and invalid filename diagnostics,
`configstore.remove_result()` missing, successful, and invalid filename
diagnostics, `configstore.list_result()` present-root and missing-root
diagnostics, capability-map/direct-lookup/required-key isolation, and audit
problem-list snapshot isolation. Hardware execution of
the expanded full smoke remains pending.

`tests/p2/smoke_stdlib.be` adds a compact standard-library compatibility smoke
for `string`, `json`, `time`, `global`, `solidify`, and `strict`. It samples
stable upstream behavior including string search/split/escape/format/replace,
prefix/suffix checks, string multiplication, JSON scalar/nested/invalid/pretty-
dump cases, deterministic fixed-epoch time dumps, compact `time.dump()` snapshot freshness, and invalid scalar including bool-false/empty and non-empty collection time input,
global module compile lookup, `solidify.compact()` on a tiny class, and strict-mode
compile errors without pulling in the larger host-only stress tests.

`tests/p2/smoke_math_parity.be` adds adapted upstream math coverage for
`nan`/`inf` string/JSON behavior, `round`, `abs`, `min`/`max` value/type/error
behavior, no-argument fallbacks, deterministic `srand`/`rand`, and core
constants while preserving the P2 module's documented `nil` invalid-domain
behavior.

`libstore.compiled_path(name)` and `libstore.compiled_stats(name)` detect staged
`.bec` candidates under `/berry/cache`, `/berry/lib`, and `/berry/app`, including
deterministic size/hash metadata. Default firmware keeps `compiled_supported`
false; `libstore.compiled_execution_probe()` has snapshot-isolation smoke coverage, and opt-in loader builds plus the default-off bytecode execution policy are
reported through `p2.status_info()["build"]` and
`libstore.compiled_execution_probe()`, but the opt-in execution path still needs
build and hardware validation.
`libstore.compile_cache_plan(name)` reports the future cache target, sidecar
manifest target, manifest format, required validator/execution support, and
explicit `emit_blocked_reason` instead of silently pretending compile-to-cache
works.
`BE_P2_ENABLE_BYTECODE_SAVER` gates opt-in `.be` to `.bec` emission through
`libstore.compile_cache_probe()` / `libstore.compile_cache_emit(name)`, while
default builds continue to report `bytecode_emit_unavailable`.
Bulk helpers `compile_cache_plan_many()`, `compile_cache_plan_many_text()`,
`compile_cache_plan_all()`, `compile_cache_plan_all_text()`,
`compile_cache_emit_many()`, and `compile_cache_emit_all()` expose explicit
provisioning workflows and dry-run JSON exports without changing default import
behavior.
Bulk emit planning includes blocker-reason histograms for provisioning
diagnostics.
`compile_cache_provision_plan()` and its text/all variants package bulk dry-run
emit state and conservative recommendations for provisioning tools.
`compile_cache_emittable()` / `compile_cache_blocked()` and their all-module
variants expose filtered dry-run emit candidates without writing cache files.
Their `_text()` companions export the dry-run candidate filters as JSON text.
When both source and staged bytecode exist, the plan also exposes a
manifest-template map that shows the exact sidecar payload a future writer would
emit, and `libstore.compiled_manifest_text(name)` previews that payload as JSON
without writing it.
`libstore.info()` / `libstore.inventory()` and `p2mem.module()` expose the same
compile-cache plan summary fields plus manifest-template availability/reason,
so module diagnostics and future tooling see why `.bec` emission is blocked
without invoking a separate planner.
`libstore.resolve(name)` also reports `compiled_preferred` and
`compiled_blocked_reason` so a fresh `.bec` sidecar can be distinguished from a
bytecode file that is actually executable.
`libstore.compiled_manifest(name)` validates staged sidecars for the expected
format, optional matching module name, and required source/compiled hashes.
`libstore.compiled_freshness(name)` reports staged bytecode as not usable when
the sidecar manifest is missing, structurally invalid, mismatched, stale, or
fresh but the opt-in bytecode loader or validator/execution policy is
unavailable.
`libstore.compiled_validation(name)` reports the validator boundary separately
from freshness, so tooling can see fresh staged bytecode without mistaking it
for safe executable bytecode.
`libstore.compiled_load_plan(name)` and loud-failing `load_compiled(name)` make
the future `.bec` execution hook explicit while default builds continue source
fallback.
`libstore.compiled_status(name)` bundles freshness, validation, load, and emit
metadata so diagnostics do not need to infer `.bec` state from separate maps.
`libstore.compiled_status_text(name)` exports the same diagnostics bundle as
JSON for tooling and smoke comparisons.
Invalid module names are rejected before SD or cache path probing:
`module_file()` raises `value_error`, path helpers return `nil`, and `.bec`
freshness/load/emit plans report `invalid_module_name` as the blocker.
`libstore.compiled_inventory()` and `libstore.compiled_inventory_text()` expose
the same `.bec` status surface across all discovered SD modules.
`libstore.compiled_summary()` and `libstore.compiled_summary_text()` expose
aggregate `.bec` readiness counts plus load/emit blocker-reason histograms for
diagnostics and provisioning checks.
`libstore.compiled_loadable()`, `libstore.compiled_emittable()`, and
`libstore.compiled_blocked()` expose filtered `.bec` candidate lists for future
provisioning tools.
Their `_text()` companions export those candidate lists as JSON text for tools
that cannot directly consume Berry maps/lists.
`libstore.compiled_provision_plan()` and
`libstore.compiled_provision_plan_text()` package `.bec` summary and candidate
state into one diagnostics map for future provisioning scripts.
`tests/p2/smoke_bec_fallback.be` creates a dummy `.bec` and matching `.be`
and checks staged `info()` parity against `source_stats()` and `compiled_stats()`;
source file, then checks that metadata reports default bytecode execution as
unsupported and the source fallback still loads. It also checks invalid JSON, invalid format,
module mismatch, missing hashes, stale-manifest, compiled-only, and
fully-missing negative cases so `libstore.resolve(name)`,
`libstore.compile_cache_plan(name)`,
and `libstore.compiled_freshness(name)` report precise reasons instead of vague
missing state.
The same smoke also covers the opt-in saver path when present, without enabling
default `.bec` execution.

`libstore.source_stats(name)`, `libstore.compiled_stats(name)`, and
`libstore.compiled_freshness(name)` now report size, deterministic rolling
hashes, and explicit unusable/freshness reasons for SD source and staged
bytecode files.

`sys.path_add(path)` appends deliberate runtime import roots to the VM module
search path using the same native module-path API as P2 startup. `tests/p2/smoke_sys.be`
now covers direct native path append, importing a tiny module from the appended
root, returned-path fresh-list identity, path-list copy isolation, and invalid argument errors including nil and list inputs. `libstore` bridges
`path_add(path)` to this native append path while avoiding duplicate VM roots on
repeated calls, and `tests/p2/smoke_sys_path_add.be` stages a tiny source module
under a new root, verifies duplicate-safe append behavior, and imports it
through the normal importer. Path removal/reordering remains unsupported to
preserve the native-module-first startup ordering.

`tests/p2/smoke_libraries.be` also guards the lazy-loader policy and now passes
as a focused normal-XMM P2 smoke: SD remains the library home, source loading
stays lazy, direct PSRAM execution is false, status/policy/strategy/module-list
diagnostic snapshots are isolated from caller mutation, and source fallback is
only reported when a staged `.bec` candidate actually exists.
It also covers `binary_heap.sort()` normal, empty, and singleton inputs. The
host-only exception-preservation audit still verifies that the caller array is
preserved if a comparison callback raises, while the default P2 audit avoids
forcing `try/except` on current normal images where that path can hang.
`binary_heap.capabilities()` / `capability(name)`, `required_capability_keys()`,
and `audit()` / `audit_problems()` / `audit_ok()` expose and self-check that
tiny in-memory contract, including missing capability-key reporting, without
touching hardware.
`libstore` also tracks source-cache hit and miss counts for the current PSRAM
source-cache path. This gives the future `.bec` freshness/cache path real
metadata without enabling bytecode execution in default builds.
`tests/p2/smoke_libraries.be` checks that returned `libstore.status()`,
`libstore.strategy()` module-path list contents, `libstore.info()`,
`libstore.source_stats()`, and `libstore.compiled_stats()` diagnostics are
snapshot-isolated from caller mutation, using parser-safe policy/strategy
assertion shapes for the P2 target parser.

`libstore.inventory()` returns a metadata record for every discovered SD module,
including source, compiled-bytecode, fallback, and cache accounting fields. The
P2 smoke suite checks this inventory, inventory/source_stats source metadata parity, and compiled-summary snapshots through `tests/p2/smoke_module_inventory.be`,
including the current SD module set: `binary_heap`, `configstore`, `libstore`,
`math`, `p2compat`, `p2ipc`, `p2mem`, `p2smart`, `task`, and `wifi`.
`p2mem.module(name)` exposes a lightweight single-module status summary for
routine diagnostics without forcing large source hashes on the normal P2 image,
and `tests/p2/smoke_libraries.be` checks that returned
`p2mem.stats()`, `p2mem.module(name)`, `p2mem.modules()`, `p2mem.cache()` status/item-list, `p2mem.gc()`, and `p2mem.evict()` diagnostics snapshots are isolated from caller mutation, with cache-item shape including explicit `chunk_count` checked on a fresh post-mutation snapshot and the normal eviction path asserting `ok == true`. `p2mem.capabilities()` / `capability(name)`, `required_capability_keys()`, and metadata-only `audit()` / `audit_problems()` / `audit_ok()` now expose the expected result wrappers, native-cache helper categories, invalid-module-name diagnostics, snapshot-diagnostic contract, and missing capability-key reporting without mutating cache state. Host coverage also verifies `p2mem.stats_result()` wraps a forced `p2.status_info()` failure, `p2mem.module_result(name)` distinguishes missing modules from invalid module names including slash and dot-dot names, `p2mem.modules_result()`, `p2mem.module_result(name)`, and `p2mem.cache_result()` wrap forced source-cache report failures, `p2mem.gc_result()` wraps a normal GC report, and a fake `p2.psram_info()` failure during eviction makes `p2mem.evict()` return `ok == false` diagnostics instead of throwing.

`libstore.path_add/remove/list` stage configured SD source-path behavior for
`libstore` diagnostics/cache/loading with path-list snapshot isolation, and `path_add()` also bridges to
`sys.path_add()` when available so deliberate new roots can participate in
native imports.
`libstore` maps dotted module names such as `pkg.mod` and `pkg.other` to nested source paths
such as `pkg/mod.be` and `pkg/other.be` for its own loading/metadata helpers, and the native
importer maps string imports such as `import "pkg.mod" as mod`, bare dotted
imports such as `import pkg.mod`, and comma-separated dotted imports such as
`import pkg.mod, pkg.other` to the same nested filesystem paths.
The package-path smoke also checks that string and dotted forms reuse the same
cached module object.
`libstore.app_path/app_exists/run_app` provide explicit `/berry/app` source
application helpers, including missing-app path/existence/run fallbacks.
`libstore.example_path/example_exists/run_example` provide explicit
`/berry/examples` source example helpers, including dotted nested example paths and missing-example path/existence/run behavior.
`libstore.pasm_path/pasm_exists/pasm_info/pasm_load/pasm_load_result` detect
and read staged `/berry/pasm/*.bin` files, including dotted nested blob paths
and missing/invalid-name behavior, while keeping PASM execution deferred.
### Safe p2.asm facade

`p2.asm` now exposes safe PASM-adjacent intrinsics for random, counter, wait,
and hubset access by aliasing existing validated native helpers. It also exposes
`load(path)` for non-empty 4-byte-aligned PASM blob files, grouped
`cognew/cogstop/cogcheck` API shape over the existing `_cogstart_PASM` path,
`launch_probe()` as a known-good launch/marker/stop hardware proof, and
`marker_blob()` plus `launch_loaded_probe()` to prove write-to-SD, reload, exact
fixture launch, mailbox marker, stop cleanup, and non-marker blob rejection.
Arbitrary assembly text, validated arbitrary SD blob launch, function bridging,
and unsafe execution remain open and should stay gated or unsupported until the
safety model and ABI are explicit.
### Structured p2.debug facade

`p2.debug` now exposes backed diagnostics: `snapshot`, `heap`, `gc`, `cogs`, `memory_map`, `pin`, `pins`, `smartpin`, and `registers`. It also exposes `capabilities()` and `capability(name)` so tooling can distinguish supported snapshot diagnostics from unsupported debugger controls. Breakpoints, tracing, source stack traces, native error detail, module cache internals, task/lock/channel internals, and PASM single-step remain open rather than silently stubbed.

Hardware status: the flashed Catalina XMM image exposes all grouped modules
(`p2.clock`, `cog`, `lock`, `pin`, `cordic`, `math`, `rng`, `smart`, `asm`,
and `debug`). The previous grouped `/tests/p2/smoke_p2_api.be` run passed on
`/dev/ttyUSB0` with image `959808 / 16777216` bytes for the earlier clock waits,
cog/lock basics, LED pin I/O, CORDIC/math/RNG/asm reads, debug maps/registers,
64-pin snapshots, and negative diagnostics. The newer queryable debug capability
surface was built and flashed in image `1168384 / 16777216` bytes and is covered
by focused direct REPL probes plus `p2-smoke-debug-capabilities-min`; the broader
grouped API source smoke is non-routine until its current `run_file()` stall is
debugged.
### Lower-case task facade

Native P2 `import task` is now the practical cooperative scheduler API for hardware. It exposes Spin2-style lifecycle aliases, native event inspection/cleanup/readiness diagnostics, native Semaphore/Mutex/Queue/EventFlags/Timer helpers, native `task.ready_result(...)` for primitive and current-VM p2ipc channel/mailbox targets, native `task.wait(...)` scheduler waits for primitive and current-VM p2ipc targets, close-wakeup behavior, direct `task.contract_value(...)` / `attention_policy_value(...)` / `execution_model_value(...)` metadata lookups, and result-shaped scheduler/lifecycle diagnostics without source-loading the large `modules/task.be` file. `modules/task.be` remains the richer source-level regression path with the full 32-slot cooperative scheduler surface and host/non-default regression coverage. This still completes only the current-VM step scheduler surface, not the still-open independent-stack or true Spin2/PASM task-switching work.
### Documentation set expansion

The P2 documentation set now includes getting-started, building, board-support, SD layout, PSRAM loader, Berry compatibility, P2 API, smart pins, cogs, tasks, PASM, debugging, performance plan, hardware-test guide, and limitations documents. These docs intentionally separate backed features from planned or unsupported work.
### Cooperative p2 IPC facade

`modules/p2ipc.be` attaches cooperative Hub-memory `p2.channel`, `p2.mailbox`, `p2.shared.Buffer`, and `p2.mutex` helpers to the native `p2` module. `p2ipc.capabilities()`, `p2ipc.capability(name)`, `p2ipc.attention_policy()` / `p2ipc.attention_policy_value(name)`, `p2ipc.contract()`, and `p2ipc.contract_value(name)` make the current-VM/no-cross-VM contract queryable, including the current lack of cross-cog wakeups, serialization, and ownership transfer. The attention policy records that bounded native cog-attention waits are available through `p2.cog.wait_attention_result()` on current P2 images, but not wired into IPC channel/mailbox wakeups yet. `p2ipc.required_capability_keys()` and `p2ipc.required_contract_keys()` expose the required metadata fields, and `p2ipc.audit()` reports missing capability or contract keys instead of letting contract drift hide in separate maps. Channels and mailboxes can report non-mutating readiness through `ready_result(mode)`, can report scheduler readiness through `wait_ready(mode)`, can report resource/cleanup state through `lifecycle_result()` and `p2ipc.lifecycle_result(obj)`, can expose non-consuming diagnostics through `snapshot_result()` and `peek_result()`, can clear queued/stored payload references while remaining reusable, and also release those references on close; shared buffers can be explicitly zeroed with `clear()` / `clear_result()`. Channel and mailbox objects expose task-readable object kinds so native `task.ready_result(...)` and `task.wait(...)` can poll current-VM receive/send or get/put readiness after `p2ipc` is imported; `task_wait_integration`, `task_wait_channel`, and `task_wait_mailbox` make that queryable without implying cross-cog IPC wakeup. `p2ipc.self_test_result(iterations)` provides a bounded current-VM cleanup diagnostic over channel, mailbox, buffer, and mutex paths. The host regression covers capability diagnostics, required-key metadata checks, contract direct lookup and snapshot diagnostics, attention-policy snapshot diagnostics, bounded self-test diagnostics, task-readable channel/mailbox object kinds and metadata, channel/mailbox readiness diagnostics, lifecycle diagnostics, channel snapshot and mailbox peek diagnostics, clear-with-payload, buffer zeroing, and close-with-payload release, hardware-lock use, fallback-lock use, hardware-lock allocation failure, blocked-lock sends/receives, default and invalid channel depths, invalid buffer sizes, invalid byte offsets/values, buffer snapshot isolation, compact `info()` diagnostics for channel/mailbox/buffer/mutex state, idempotent close/closed-state behavior, channel/mailbox/mutex close-result maps, and result-shaped `send_result()` / `recv_result()` / `put_result()` / `get_result()` / mutex / buffer diagnostics that distinguish valid `nil` payloads from empty/full/busy/not-locked/closed/error states. `examples/task_ipc.be` now hardware-runs directly with native `import task` and the current `modules/p2ipc.be`, printing scalar readiness transitions around cooperative channel/mailbox waits plus closed channel/mailbox wakeups. This completes the current-VM API surface with host/P2 smoke coverage, while actual cross-cog attention wakeups, cross-VM serialization, and longer stress/soak behavior remain open.
