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
| Build system | Partial | Catalina make targets, profile selection, native Catalina path, image size guards, Edge32 and XMM commands exist and are documented. `make test-host`, `make test-p2`, `make soak-p2`, and non-hardware `make p2-baseline-guards` now exist as repeatable test entrypoints. The baseline guard bundle checks the Catalina build-log pipefail path, Edge32/XMM profile invariants, sibling Catalina XMM `cx` object/index sync, Catalina warning classes, bounded cleanup-oriented SD-writing smoke discipline, required P2 documentation presence, source-module capability metadata contracts, and active Catalina path policy without rebuilding firmware. The Catalina flash-loader wrapper image is now size-guarded against the P2 Hub RAM limit. | Keep no-PSRAM Edge and Edge32/XMM paths green while features are added; expand test coverage behind the new entrypoints and keep the guard bundle cheap enough to run before larger P2 edits. |
| Boot on selected board | Verified | `p2-edge32-ram`, `p2-edge32-flash`, and `p2-xmm-flash` were hardware-verified on `/dev/ttyUSB0` with `CATALINA_DIR=../Catalina`. `p2-edge32-flash` boots from SPI flash on P2 Edge 32 MB. `p2-xmm-flash` boots through the sparse fast loader with visible PSRAM/VM startup spinners. | Keep re-verifying after substantial firmware changes. |
| REPL core behavior | Partial | Arithmetic, strings, maps, lists, ranges, blank input, and quit behavior are live-verified. | Convert smoke notes into repeatable automated coverage. |
| Berry language feature coverage | Partial | Core interactive syntax, compiler/parser regression shapes including call-argument ternary, ternary-result suffix, call-result chained suffix, and chained-suffix parsing, built-ins including `call()` non-callable rejection, `input()` on P2 serial, bytes length truthiness through `bool()`, range type classification and numeric parser edges, numeric passthrough conversions, and custom conversion edge values, safe Berry-level C API edge probes including reflection member replacement and map copy isolation, collection checks including dedicated list-core `size()` API shape, iterator exhaustion, index-list ordering, reverse in-place behavior, and copy isolation, map values, range method API shape, range increment/setrange/positive and negative iterator isolation including independent iterator exhaustion plus retargeted-range iterator preservation and exhaustion, and plain-map behavior coverage including `keys()`/`values()` API shape, keys/values snapshot isolation, mixed-type key distinction, nil-value presence, and nil-valued insert preservation, closures including returned-closure function classification, dedicated escaped-closure and factory returned-function classification, parameter/local capture, shared-upvalue multi-closure and group-independence, nested upvalue-chain, captured mutable-object independence, and upvalue mutation coverage, varargs including direct, direct rest-list freshness, closure, escaped rest-list capture and mutation persistence, method packing, method rest-list freshness, and vararg-list mutation isolation, loop control including empty-range iteration, class iterator closure isolation, list-iteration break/continue, nested break/continue isolation plus outer-break coverage, and dedicated for-loop recursion coverage, byte behavior including base64 one-byte padding, two-byte padding, single- and multi-quantum no-padding quanta, fixed-size bytes, and fromstring shortened replacement/copy isolation, compact VM operator/full-span negative slicing/comparison-result typing/operator-overload checks including derived inequality including callable instances plus callable-instance list-lookup invocation and binary instance-result class identity and chained binary instance-result overloads, focused VM runtime, named-global cleanup, invalid comparison, and shift-operator error paths, integer conversion/negative `toint()`/lowercase and uppercase hex/bitwise/positive shift/variable shift counts/zero-shift identity and signed right-shift checks, lexer literal/block- and line-comment-adjacent token parsing/hex escape boundary/malformed-token checks, class/static/indirect-member checks including instance class identity, instance-method static-member reads including post-construction static updates, computed class/instance method-name calls, dynamic static writes, and chained indirect updates, static initializer/mutable static object sharing/`_class`/nested static class first-class identity checks, static member/function-member reassignment and scalar compound update checks including mutable static-object sharing and inherited static readback, legacy/grouped static declaration checks including mutable static list/map values plus method-visible and cross-instance shared static fields, subclass-from-module-member static checks including inherited method live static fallback and child/base static mutation separation, module creation/same-name module object and member-table independence/injected-module identity/replacement/cache monkey-patch/restore checks plus compiled module-member mutation, module attribute-dispatch including function-valued virtual members plus real-attribute and post-virtual shadow precedence without hook checks, constructor chaining, external and leveled super-proxy method calls, chained super argument passing, plus auto/leveled `super()` checks, builtin list/map subclass method/storage including map-subclass keys snapshot isolation, subclass instance fields, builtin method preservation, and subobject relationship checks, map instance-key/hash/equivalent-key replacement/removal/collision checks, `undefined` sentinel plus virtual `member()` computed-name reads including function-valued module reads and real-member precedence, plus `setmember()` repeated assignment replacement, computed-name scalar and function-valued assignment, and computed-name/real-member dispatch checks, f-string indexed-expression including computed map keys and computed-width formatting plus walrus syntax checks including builtin shadowing/sequential value-expression/local call-argument value-expression and map-literal assignment-expression edges, conditional-expression selected-branch side-effect, condition-operand single-evaluation, and collection-truthiness checks, compound-assignment computed-index, computed map-key sibling isolation, and computed-member update checks, nested suffix-assignment, computed map-key/member assignment with sibling isolation, and computed-member checks, cyclic list/map plus shared-child reference stringification checks, suffix/list-append expression, method-chain indexing including negative indexes, and method-chain slicing checks, boolean/truthiness/short-circuit checks including skipped/executed branch side effects, truthy non-bool, and falsey collection operands including OR branch execution, relational/equality checks including list order sensitivity, map order/nested-map order/nil equality and bytes equality, literal and computed-denominator division-by-zero exception checks plus negative non-zero division/modulo sign behavior, and compact exception/error-path checks including key-error handling, function- and method-propagated raise and assert-failure exception capture across default-message assert, loop, function-call, method-call, and closure-call propagation cases exist. | Cover all built-ins listed in `goal.md`, including tests and docs. |
| Berry standard-library coverage | Partial | `string` including module/API shape, native `math`, native `task`, `json` including module/API shape, compact parse-freshness and dump-state, advanced parser, and generated stack/growth cases including matrices, `bytes`, `os`, file operations, `time` including compact dump snapshot-freshness, `global` including API shape, `sys` including module/API shape, `introspect` including module/API shape and normal-XMM hardware verification through short aliases, `solidify` including introspected helper discovery, `debug` including API shape and helper discovery, `strict` including branch-condition lookup checks, and `configstore` JSON config result diagnostics including valid JSON `null` versus malformed JSON have P2 smoke coverage or prior live checks. Native P2 `math` now has hardware-verified CORDIC-backed trig/inverse-trig helpers where appropriate plus NaN/Inf, invalid-result, rounding, deterministic random, and parity-smoke coverage. Bounded import/GC churn and import-all coverage now exists for the current SD module set, and `libstore.info()` / `libstore.inventory()` now expose per-module coverage metadata for behavior, SD import, repeated import/cache, PSRAM source-cache, low-memory churn, metadata, and hardware-deferred cases, with smoke coverage that returned inventory and compiled-summary snapshots are isolated from caller mutation and inventory source metadata matches `source_stats()`. `p2-smoke-libraries-lazy-min` now provides a smaller hardware-verified lazy-loading policy check for normal progress work, `p2-smoke-p2mem-policy-min` covers `p2mem` capability/audit/GC-result metadata, `p2-smoke-p2mem-native-cache-min` covers native upper-PSRAM cache reset, verified put, verified get, and entry accounting, and `p2-smoke-bec-fallback-min` covers the `.bec` source-fallback decision without running broader import suites. | Verify all included upstream modules and add normal, SD import, repeated import/cache, PSRAM-cache, and low-memory tests where relevant. |
| Berry expansion-module coverage | Partial | Native `i2c`, `spi`, `spin2`, WiFi import surface, `task.be`, conservative `p2smart.be` smart-pin/GPIO wrappers, and declarative `p2compat.be` capability metadata are documented. `p2smart` now exposes `capabilities()`, direct `status(name)` lookup, `required_capability_keys()`, and `status_report()` so verified, setup-only, unverified, and unsupported smart-pin wrapper areas are queryable and required metadata drift is caught by `audit()`; host/import coverage checks the map, required keys, exact status lookup, and snapshot isolation. `p2smart` has host coverage for generated GPIO, normal-pin, counter/counter-variant/repository/PWM/PWM-variant/NCO/NCO-duty/pulse/transition/ADC/ADC-variant/DAC/DAC-variant/async-serial call sequences and staged loopback smoke use; `p2compat` now reports supported package-style SD imports, supported native `sys` module path helpers, staged `.bec` manifests, bytecode cache emission, bytecode validator policy, discoverable valid status names, status-report diagnostics, required capability-name metadata, required child-VM policy-key metadata, a compact report snapshot, self-audit results, and concise audit-problem names separately from unsupported host-like APIs; its smoke and host coverage also check summary/inventory consistency, status-filtered capability queries, name-list queries, report consistency, audit consistency, missing required metadata checks, returned-list mutation isolation, returned-record mutation isolation, summary, nested report summary/status-list/bytecode, audit-map/list, audit-problem, and bytecode snapshot mutation isolation, and safe source-fallback bytecode policy when native `p2.status_info()` fails. A focused `p2-smoke-p2compat` hardware target now uploads only `modules/p2compat.be` and `/tests/p2/smoke_p2compat.be` and verifies the native `p2.vm_copyable()` VM-boundary copy/reject diagnostics. | Finish hardware validation and keep unsupported host-like features explicit. |
| SD loader coverage | Partial | `/modules` lazy import root works for optional SD libraries. FAT fallback to sector `2048` works. `math`, `string`, and `task` import as native firmware modules. Source-level support now exists for import aliases including repeated SD alias cache identity and source-path/info diagnostics, missing-import failure/retry recovery, native-module-first precedence and repeated native import identity across `/berry/lib` and `/berry/app` shadows, module-root order including `/modules` before `/berry/lib` before `/berry/app` with matching source-path/info diagnostics, current-directory imports with cwd-before-root precedence and cached alias re-import identity checks, additive `sys.path_add()` import roots with source-path/info diagnostics, scoped `libstore.path_add()` and `path_remove()` custom-root diagnostics, optional `/berry/main.be` staging/run/cleanup path checks, `/berry/lib/*.be` including nested package source layout and source-path/info diagnostics, `/berry/app/*.be` including dotted nested app helpers and missing-app path/existence/run fallback checks, `/berry/config/*.json`, nested package file lookup for string imports such as `import "pkg.mod" as mod`, bare dotted imports such as `import pkg.mod`, comma-separated dotted imports such as `import pkg.mod, pkg.other`, `.bec` path detection with source fallback, 8.3-safe `.jsn` sidecar freshness manifest metadata, opt-in bytecode-saver-gated `.be` to `.bec` cache emission helper coverage, repeated import/cache smoke coverage, and opt-in `/berry/...` provisioning targets. Focused 8.3-safe hardware runs now verify the source-layout, import-resolution, documented layout-location slices, and `.bec` fallback paths through `/tests/p2/ilayout.be`, `/tests/p2/iorder.be`, `/tests/p2/pkgpath.be`, `/tests/p2/infirst.be`, `/tests/p2/icwd.be`, `/tests/p2/lpaths.be`, `/tests/p2/syspath.be`, `/tests/p2/cfgstore.be`, `/tests/p2/expath.be`, `/tests/p2/pasmly.be`, `make p2-smoke-bec-fallback-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`, and the broader `/tests/p2/becfall.be` alias run with `P2_SMOKE_PASS bec_fallback`. | Run full scripted SD smoke suite only when broad evidence is needed; add `.bec` execution and path reordering only if a real safe semantics is defined. |
| PSRAM cache coverage | Partial | `p2.psram_info()`, `p2.psram_test()`, bounded read/write, chunked `libstore` source-cache round trips, source-cache no-op/error paths, constrained bulk preload skipped-module reporting through `cache_all_report()`, selected-list preload reporting through `cache_many_report()`, source-cache reset/recache behavior after source changes, `libstore` cache/status/info diagnostic snapshot isolation for path lists, cached entries, and coverage records, `p2mem` stats/module/cache/gc/evict diagnostics snapshot isolation, and Berry-level `p2mem` native-cache owner/warm/release/result-wrapper/write-failure cleanup, verify-failure cleanup, non-destructive replace, and failed batch-warm rollback planning are covered by smoke/host regressions. `/tests/p2/smoke_xmm_gc_stress.be` passed on standalone XMM, proving retained Berry lists/maps/strings/closures survive GC in the external heap, temporary churn is reclaimed, and the heap stays inside the pointer-addressable lower PSRAM window. | Complete inactive bytecode/module cache tier, hashes, hit/miss accounting, refcounts, last-used timestamps, native C cache bounds/release errors, and broader low-memory/soak behavior. |
| P2 primitive API coverage | Partial | Current flat `p2.*` helpers cover pieces of clock/counter, wait, cog, pins, CORDIC, smart pins, PSRAM, filesystem, and diagnostics. Grouped `p2.clock`, `p2.cog`, `p2.lock`, `p2.pin`, `p2.cordic`, `p2.math`, `p2.rng`, `p2.asm`, and `p2.debug` aliases now exist with P2 smoke coverage. `p2.clock` smoke coverage includes frequency/mode aliases, counter reads, waits, and non-destructive negative-argument validation for `waitx`, `waitus`, `waitms`, `waitsec`, `set()`, and `hubset()`. `p2.cog` smoke coverage includes id/check, function-shape checks for stop/attention/raw wait_attention, a no-op attention signal, bounded `wait_attention_result(timeout_us)` timeout and pre-signaled result-map behavior, public-list `cog_states()`, and invalid stop/attention diagnostics. `p2.lock` smoke coverage stages `new`, `ret`, `try`, `release`, and `check`, including invalid-range diagnostics for each operation that takes a lock ID. `p2.pin` smoke coverage now stages `dir_low`, `dir_high`, `write`, `low`, `high`, `toggle`, `float`, `read`, bool/int writes, invalid pin/value diagnostics across read/write/direction/output/toggle/float, and PSRAM-reserved pin read/write/direction/float rejection on the current XMM board profile. `p2.cordic`/`p2.math`/`p2.rng` smoke coverage stages public-map result-shape checks, deterministic `isqrt`/`muldiv64`/`rev`/`encod` assertions, RNG type coverage, and unsigned-argument diagnostics. `p2.asm`/`p2.debug` smoke coverage stages safe intrinsic reads/waits, backed diagnostic maps/lists including the 64-pin snapshot, current-cog register fields, and negative diagnostics for unsafe/invalid arguments. Low-level negative integer, cog, lock, pin, and reserved-pin validation paths have hardware smoke coverage on `/dev/ttyUSB0`. | Continue toward high-level wrappers and broader hardware stress. |
| Smart pin mode coverage | Partial | Raw smart pin helper surfaces exist. Grouped raw aliases exist under `p2.smart`, lower-case Catalina constants are exposed for the signed raw API, and `p2smart` wraps GPIO input/output, setup-only explicit normal-pin mode, counter with setup-only named timer/counter variants, repository, triangle PWM plus setup-only PWM mode variants, NCO frequency, setup-only NCO duty, pulse/cycle, transition, ADC with setup-only named source/family variants, DAC, setup-only DAC mode variants, and async-serial setup with host-tested call sequences. The jumper suite now passes on hardware for pins `0-1`, `2-3`, `4-5`, and `6-7`, covering GPIO wrappers, raw helpers, repository calls, triangle and named PWM/NCO-frequency/pulse/transition-to-counter, NCO-duty setup/diagnostic shape, GPIO-driven high-counter loopback, DAC-output to ADC-input setup/readback, and async setup/send/query/ack; focused minimal smokes also verify normal-pin output/input on `0-1`, static quadrature setup/sample/ack/clear plus the staged-only quadrature diagnostic result `P2_SMOKE_QUADRATURE_DIAG 0 0 0 0 false setup_only`, synthetic quadrature motion with pins `0` and `2` driving inputs `1` and `3` for forward delta `8` and reverse delta `-8`, and named `count_highs` counter drive across all documented jumper directions. Default, named-DAC, named-ADC, and combined named ADC/DAC sampled jumper probes are tracked as verified sampled-loopback coverage. Broader waveform/timing/analog validation is still open. `p2smart.dac_adc_probe()`, `dac_adc_sampled_probe()`, `dac_variant_adc_probe()`, `dac_variant_adc_sampled_probe()`, `adc_variant_dac_sampled_probe()`, and `adc_dac_variants_sampled_probe()` give result-shaped DAC-to-ADC jumper diagnostics with signed and absolute delta reporting; current hardware smoke records integer ADC samples and permits flat `0->1` readings, so calibrated polarity/voltage claims remain open. A focused async RX smoke also proves `AsyncSerialPair.read_byte()`, readiness-query `read_result()`, timed-sample `read_result_after(wait_us)`, and wrapper cleanup on jumper pairs `0-1`, `2-3`, `4-5`, and `6-7` in both directions for `0x00`, `0x55`, `0xa5`, and `0xff`; the zero-byte path reports `value=0` even when `available()` / `rqpin` is zero and raw lower state bits are nonzero. | Research/cover ADC variant hardware validation/filtering/scaling, PWM sawtooth/SMPS waveform validation, DAC variant hardware validation/calibration, count-rises/timer-counter timing validation, NCO-duty waveform validation, mechanical quadrature encoder behavior, USB pair, synchronous serial receive, buffering, and remaining smart-pin mode families. |
| High-level hardware wrapper coverage | Partial | Native bus APIs exist through `i2c` and `spi`; `p2smart` now provides conservative GPIO, setup-only explicit normal-pin mode, PWM with setup-only named mode helpers, ADC with setup-only named mode helpers, DAC with setup-only named variant helpers, timer/counter with setup-only named mode helpers, NCO frequency, setup-only NCO duty, pulse/transition, repository, quadrature with synthetic motion/direction proof, and async-serial pair setup/read-byte/result wrappers including `read_result_after(wait_us)` for zero-byte-safe timed reads plus paced byte-list send/exchange helpers and explicit no-FIFO buffer policy metadata. Result-shaped diagnostics now include raw smart-pin, GPIO loopback, repository, GPIO-high counter, named counter drive aggregate, named counter drive, named counter sample, quadrature static and synthetic-motion probes, and ADC sample probes, triangle/named PWM/NCO/NCO-duty/pulse/transition-to-counter, default/sampled/named/named-sampled/named-ADC-sampled/combined-named DAC-to-ADC, explicit DAC/ADC delta policy metadata, conservative async-serial probes, and aggregate jumper-pair diagnostics for the documented `0-1`, `2-3`, `4-5`, and `6-7` wiring in one-way and bidirectional forms, with examples and focused host/import coverage. The staged sync-serial wrapper now uses the ROM-documented `sync_io` mode bit by default, preserves `invert_b` in the source fallback, has result-shaped transfer diagnostics, and exposes normal/inverted clock-sampling/output mode plans across the default four-pin groups; hardware execution of the clocked TX/RX helper can currently run past the focused smoke timeout, so received-data loopback is not yet hardware-validated. | Add validated SPI/synchronous serial receive, USB, true buffered UART/FIFO behavior, ADC variant validation, PWM sawtooth/SMPS waveform validation, timer/counter timing validation, NCO-duty waveform validation, mechanical quadrature encoder behavior, and deeper calibrated analog wrappers. |
| PASM/assembly integration | Partial | Raw cog program startup via `p2.cog_start_hex()` exists. Safe `p2.asm` aliases now expose `getrnd`, `getct`, `waitx`, `hubset`, SD blob loading into `bytes`, grouped `cognew/cogstop/cogcheck` shape, queryable `capabilities()` / `required_capability_keys()` / `abi()` / `required_abi_keys()` diagnostics, `audit()` / `audit_problems()` / `audit_ok()` policy-consistency and missing-key checks, a hardware-verified `launch_probe()` known-good marker/stop fixture, and an exact SD-staged marker fixture through `marker_blob()` plus `launch_loaded_probe()`. `examples/pasm_direct.be` now hardware-runs to `pasm direct done`, demonstrating the safe intrinsics, policy metadata, clean audit helper status, and marker fixture launch/stop path without claiming arbitrary PASM execution. | Add public arbitrary PASM ABI, broader fixture coverage, function bridge, full ABI docs, and unsafe build flag. |
| Multicog Berry VM coverage | Partial | Interim `p2.cog.spawn(closure, ...primitive_args)` accepts a live Berry closure and returns stoppable integer handles. The verified p38/p39 LED use case is the GPIO-specific `native_blink` fast path for `spawn(closure, pin, rate_ms)`: it invokes the passed closure once during setup, uses the positive integer return value as the period, runs a native pin loop on the spawned cogs with a 2048-byte stack, and reports `model == "native_blink"` plus `native_blink == true` in handle diagnostics. `p2.cog.capabilities()` / `required_capability_keys()` expose the current `native_blink_info_stop_only` handle model: `id(handle)`, `info(handle)`, `status(handle)`, non-blocking `join(handle)` with result/error fields, `result(handle)`, `error(handle)`, `stop(handle)`, and `kill(handle)` are backed handle APIs, and stop/kill result maps report cleanup policy, slot release, and post-stop handle invalidation; `p2.cog.audit()` reports missing capability-key metadata without spawning cogs. Blocking result waits/cross-cog exception propagation remain unsupported. The default firmware rejects unsupported closure-cog shapes instead of running the unsafe shared-VM dispatcher; that dispatcher is diagnostic-only behind `BE_P2_ENABLE_UNSAFE_SHARED_VM_COG`. | Evolve toward independent per-cog VM/GC isolation before claiming arbitrary closure execution. |
| Closure-in-cog coverage | Partial | Captured closures are no longer only guarded: the interim shared-VM closure-cog path keeps the closure rooted in a VM registry and calls it with primitive args from another cog while REPL execution is paused. `p2compat` now documents the child-VM transfer boundary and exposes it through `child_vm_transfer_policy()`: nil/bool/int/bounded-string copies are partial support, non-captured closure-name selection is staged, captured closures plus live object graphs are unsupported, and ownership/resource transfer is explicitly false. Direct helpers `child_vm_policy(name)`, `child_vm_copyable_type(name)`, and `child_vm_rejected_type(name)` let tooling query policy fields and type-policy lists without parsing the returned map; `required_child_vm_policy_keys()` and `audit()` now make missing transfer-policy metadata explicit. Native `p2.vm_copyable()` hardware smoke coverage verifies nil/bool/int/string copyable diagnostics, list/map/function rejection diagnostics, and no-argument rejection on the flashed XMM profile. | Replace the REPL-idle shared-VM proof with true independent VM closure launch and broader hardware-verified serialization/rejection rules. |
| IPC coverage | Partial | Importing `p2ipc` now attaches cooperative `p2.channel`, `p2.mailbox`, `p2.shared.Buffer`, and `p2.mutex` APIs with host and P2 smoke coverage; mutexes use `p2.lock` hardware locks when available and fall back to an in-VM cooperative lock when not available or allocation fails. `p2ipc.capabilities()` / `capability(name)` report the current-VM IPC contract, result diagnostics, optional hardware-lock backend, fallback mutex support, reusable clear cleanup for channels/mailboxes/shared buffers, close-time payload release, non-consuming channel snapshot and mailbox peek diagnostics, payload-contract result diagnostics, bounded `self_test_result()` cleanup diagnostics, bounded native cog-attention wait availability, and no cross-VM support; `p2ipc.attention_policy()` / `attention_policy_value(name)` explicitly report that native `p2.cog.wait_attention_result()` is available on current P2 images but not wired to channel/mailbox wakeups yet. `p2ipc.contract()` makes the no-cross-cog-wakeup, no-serialization, no-ownership-transfer, snapshot/peek diagnostics, clear-cleanup, close-cleanup, self-test policy, attention policy, and current-VM-reference payload boundary queryable. `p2ipc.required_capability_keys()` and `p2ipc.required_contract_keys()` expose the expected metadata fields, while `p2ipc.audit()` / `audit_problems()` / `audit_ok()` self-check that the capability and contract maps agree on those boundaries and report missing required keys explicitly. Host coverage now includes capability-map/direct lookup checks, required-key metadata checks, contract and audit snapshot checks, bounded self-test success/failure shape, attention-policy direct lookup and snapshot checks, payload-contract result fields for channel/mailbox send/receive/snapshot/peek, clear-with-payload, buffer-zeroing, and close-with-payload release checks, lock-failure, blocked-lock, default-depth, invalid-depth, buffer snapshot-isolation, invalid buffer input paths, compact `info()` diagnostics for channel/mailbox/buffer/mutex state with returned-map mutation checks, idempotent close/closed-state behavior, and result-shaped channel/mailbox/buffer/mutex diagnostics that distinguish valid `nil` payloads from empty/full/busy/not-locked/closed/error states. `examples/cog_channel.be` now hardware-runs with scalar current-VM channel/mailbox/buffer diagnostics and reaches `cog channel example done`. | Add actual cross-VM/cross-cog wakeups, serialization rules, and longer stress/soak coverage. |
| Cooperative task coverage | Partial | `modules/task.be` exposes the cooperative scheduler API tracked as Priority 4 backlog work with 32 fixed slots; the older native P2 compatibility `import task` path can still report its native 16-slot limit, so callers should use `task.info()["max_tasks"]` / `task.capability("max_tasks")` for the active backend. The source module has host/P2 smoke coverage, queryable `capabilities()` / `capability(name)`, `attention_policy()` / `attention_policy_value(name)`, `execution_model()` / `execution_model_value(name)`, `contract()` / `contract_value(name)`, `primitive_capabilities()` / `primitive_capability(name)`, required-key metadata diagnostics, and required attention-policy key diagnostics, Spin2-style cooperative lifecycle names (`spin`, `halt`/`hlt`, `cont`, `chk`, `id`, `tasks`), event diagnostics/cleanup through `events()` and `clear_all()`, bounded `self_test_result()` cleanup diagnostics, and cooperative Semaphore/Mutex/Queue/EventFlags/Timer primitives. The current non-stackful contract is queryable as `scheduler_policy == "current_vm_callback_step"` with an unsupported-reason string for independent stacks, preemption, and true Spin2/PASM switching; `task.attention_policy()` reports bounded native cog-attention wait availability when present while keeping attention as a current-VM cooperative event with no cross-cog task wakeup claim; `task.audit()` / `audit_problems()` / `audit_ok()` self-check that scheduler, execution-model, attention policy, contract, primitive metadata, attention-policy required keys are present, and required metadata keys remain consistent; `examples/task_scheduler.be` now hardware-runs with a source-module preload, prints that contract explicitly, runs two cooperative tasks to free status, and reaches `task scheduler example done`. Host coverage includes capacity, first-free/fixed-slot `spin`, pause/resume/stop plus lifecycle aliases, result-shaped start/stop/pause/resume diagnostics for invalid functions, over-wide argument lists, slot exhaustion, invalid/free handles, and state transitions, Queue result helpers for full/empty/nil-payload diagnostics, capability snapshot isolation and direct capability lookup, direct attention-policy lookup, direct execution-model lookup, direct contract lookup, attention-policy direct lookup and snapshot isolation, audit snapshot isolation, bounded self-test success/failure shape, event snapshot isolation and clear-all behavior, task function error state, malformed wait descriptor containment, wait-object polling failure containment, timeout wakeups, invalid primitive constructor/mask/timer inputs, and wait descriptors for the cooperative primitives. The P2 task smoke now also covers `spin`, lifecycle aliases, `capabilities()`, direct capability lookup, direct attention-policy lookup, direct execution-model lookup, direct contract lookup, attention policy, contract/audit helpers, `self_test_result()`, Queue result helpers, repeated hardware cog-attention polling into `task.wait("attention")`, `events()` snapshot isolation, and `clear_all()` on `/dev/ttyUSB0`; import/cache/churn smokes accept either known backend limit while requiring capability metadata to match `task.info()`. `examples/task_primitives.be` now hardware-runs with an explicit source-module preload and prints scalar Queue/EventFlags/Timer result diagnostics. | Independent Berry call stacks/coroutines, true Spin2/PASM switching, non-callback stackful execution, broader hardware timing validation, and stress/soak testing remain open. |
| Debug feature coverage | Partial | `p2.fs_info()`, `p2.status_info()`, `p2.debug_snapshot()`, `p2mem`, heap, module, cache, and PSRAM diagnostics exist. `p2.debug` now exposes backed heap, GC, cog, memory-map, single-pin, 64-pin, smart-pin, and current-cog register diagnostics with smoke coverage. | Add breakpoints, trace controls, source stack traces, task/module/lock/channel internals, broader registers, and PASM debug support. |
| Example coverage | Partial | Interactive examples are documented in P2 docs and handoffs. Focused hardware verification now includes `examples/blink.be`, `examples/adc_read.be`, `examples/dac_write.be`, `examples/gpio_loopback.be`, `examples/nco_counter_loopback.be`, `examples/task_primitives.be`, `examples/task_scheduler.be`, `examples/cordic_demo.be`, `examples/debug_report.be`, `examples/psram_cache_stats.be`, `examples/file_sd.be`, `examples/json_sd.be`, `examples/repl_sd.be`, `examples/cog_channel.be`, and the narrowed quick SD import sweep in `examples/import_all_libs.be`; `examples/blink.be` hardware-runs to `blink done` on LED pin 38; `examples/adc_read.be` hardware-runs to `adc done` with scalar ADC sample diagnostics; `examples/dac_write.be` hardware-runs to `dac done` with scalar DAC write diagnostics; `examples/task_scheduler.be` hardware-runs with a source-module preload, reaches `task scheduler example done`, and reports two cooperative tasks finishing to free status; `examples/cordic_demo.be` hardware-runs to `cordic demo done` with scalar grouped CORDIC/math helper output; `examples/debug_report.be` hardware-runs to `debug report done` with compact backed `p2.debug` and p2mem policy/audit output; `examples/psram_cache_stats.be` hardware-runs to `psram cache stats done` with native read-only PSRAM and native cache stats; `examples/file_sd.be` hardware-runs to `file sd example done` with bounded write/read/remove cleanup; `examples/json_sd.be` hardware-runs to `json sd example done` with bounded JSON write/read/remove cleanup; `examples/repl_sd.be` hardware-runs to `repl sd helper done` with read-only SD mount/list diagnostics; the import sweep reaches `import all libs example done` for `binary_heap`, `configstore`, `math`, `p2compat`, `p2ipc`, the active `task` backend, and metadata-only `wifi`; heavier direct import-chain probes separately pass through `p2mem` and `p2smart`. | Add explicit example files requested in `goal.md`; keep user-facing examples quick while heavier import-chain coverage stays in focused probes. |
| Host test coverage | Partial | `make test-host` passes locally: it runs the 54-test desktop Berry suite, then `make test-p2-host` runs P2-specific host regressions for fake-PSRAM `libstore`, task, `p2ipc` happy and edge paths including invalid channel/buffer inputs, IPC diagnostic snapshots, idempotent close/closed-state behavior, and result-shaped nil-payload/full/busy/not-locked/closed/error diagnostics, `binary_heap` including sort empty/singleton behavior and caller-array preservation when comparators raise, `p2compat` including status-report diagnostics, nested report/audit snapshot isolation, and child-VM copy-boundary capability metadata, `configstore` including load-result diagnostics, `.bec` manifest/fallback/planning behavior, file-backed SD-style import/cache behavior including source metadata and path removal, `libstore` source-cache no-op/error/reset/churn paths plus cache/status/info diagnostic snapshot isolation, `p2mem` stats/module/cache/gc/evict diagnostics snapshot isolation including invalid single-module lookups, and the Berry-level `p2mem` native-cache facade including native-cache info/entry enumeration failure diagnostics, reset/get result wrappers, invalid reservation/payload/index/range result wrappers, owner lookup/history failures, owner-level status/get/verify/release failures, verified put/replace verify exceptions, single and bulk module-source invalid-name diagnostics, module-source native-cache-unavailable planning, write-failure cleanup including cleanup-release failure diagnostics, verify-failure cleanup, non-destructive replace, and failed batch-warm rollback. | Add host tests for native C cache eviction/errors, hardware-backed closure serialization, and broader low-memory behavior. |
| P2 hardware test coverage | Partial | `make p2-smoke`, `make p2-smoke-quick`, `make p2-smoke-edge32`, and `make test-p2` exist for broader runs. Focused targets now cover the normal progress path without broad suites: `p2-smoke-core-builtins-min`, `p2-smoke-sd-file-min`, `p2-smoke-libraries-lazy-min`, `p2-smoke-p2mem-policy-min`, `p2-smoke-p2mem-native-cache-min`, `p2-smoke-bec-fallback-min`, `p2-smoke-smartpins-normal-pin`, `p2-smoke-smartpins-quadrature-static`, `p2-smoke-smartpins-quadrature-motion`, `p2-smoke-smartpins-quadrature-diag`, `p2-smoke-smartpins-adc-dac-diag`, `p2-smoke-smartpins-nco-duty-diag`, `p2-smoke-pasm-policy-min`, `p2-smoke-cog-policy-min`, `p2-smoke-task-policy-min`, and `p2-smoke-ipc-policy-min`. The normal XMM image has recent `/dev/ttyUSB0` verification for these minimal smokes plus selected focused API/math/smart-pin checks with jumpers `0-1`, `2-3`, `4-5`, and `6-7`. | Run full scripted SD smoke suite only when broad regression evidence is needed; keep extending focused hardware coverage for new work. |
| Soak/performance coverage | Partial | `make soak-p2` repeats the selected P2 smoke suite for a duration. `docs/performance.md` now defines the required benchmark areas and reporting format without claiming measurements. | Add benchmark hooks, measured results, explicit eviction/GC/cog/channel/GPIO/smart-pin stress, and leak reporting. |
| VGA/video | Unsupported | `p2compat` marks `video_output` and `vga_demo` unsupported in the current default build. `examples/vga_test_pattern.be` hardware-runs to `vga test pattern done` on the current native-Catalina XMM image after reporting those unsupported records instead of faking a pattern. | Implement real video output only behind backed hardware/build support. |
| USB keyboard/mouse/HID | Unsupported | `p2compat` marks `usb_hid` and `usb_demo` unsupported in the current default build. `examples/usb_keyboard_mouse.be` hardware-runs to `usb keyboard mouse done` on the current native-Catalina XMM image after reporting those unsupported records instead of faking input. | Implement real USB support only behind backed hardware/build support. |
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

Implemented top-level examples now cover LED blink, SD REPL/startup handoff, library import sweep with current IPC/task contract reporting, JSON-on-SD, basic SD file I/O, GPIO loopback, smart-pin diagnostics, ADC, DAC, PWM, NCO-to-counter loopback, UART, SPI, quadrature, closure-cog native blink, current-VM channel/mailbox/buffer IPC messaging and cleanup diagnostics, cooperative task scheduling, cooperative task/IPC waits, task primitives, PASM-adjacent intrinsics plus safe marker-fixture launch and unsupported bridge/blob policy reporting, CORDIC/math helpers, PSRAM cache diagnostics, and debug snapshot reporting. The GPIO loopback example is now hardware-run on the documented `0-1` jumper and reaches `gpio loopback done`; the NCO-to-counter example is now hardware-run on the same jumper and reports fast/slow counter deltas `41` and `21`; `uart_loopback.be` is now hardware-run on the same jumper and reaches `uart loopback done` with send/query readiness plus bounded drain values; `smartpin_diagnostics.be` is now hardware-run across the documented `0-1`, `2-3`, `4-5`, and `6-7` jumpers and reaches `smartpin diagnostics done`, reporting all four pairs as `ok true`, `8 / 8` checks, GPIO loopback, high-counter deltas, pulse/transition counts, async serial, and async drain matches; `cog_closure.be` is now hardware-run for the native-blink closure-cog shape on pins `38` and `39`, reports handles/results, stops/kills both handles, and reaches `cog closure example done`; `pasm_direct.be` is now hardware-run for safe PASM-adjacent intrinsics and marker-fixture launch policy, reaching `pasm direct done`; `task_primitives.be` is now hardware-run with a source-module preload and reaches `task primitives example done`; `task_ipc.be` is now hardware-run with a source-module preload and reaches `task ipc example done`, demonstrating cooperative task waits on p2ipc channel receive/send and mailbox get/put; `cog_channel.be` is now hardware-run for current-VM channel/mailbox/buffer cleanup diagnostics and reaches `cog channel example done`. The dedicated smart-pin smoke suites also cover bidirectional aggregate jumper diagnostics for the documented pairs. VGA and USB example files now explicitly report unsupported `p2compat` records instead of faking demos.

`examples/pwm_fade.be` is now hardware-run on the current native-Catalina XMM image and reaches `pwm fade done` after scalar duty updates for values `0`, `40`, `80`, `120`, `160`, and `200`.

`examples/quadrature_counter.be` is now hardware-run on the current native-Catalina XMM image and reaches `quadrature counter done` using two jumper pairs: pins `0` and `2` drive quadrature inputs `1` and `3`, forward motion reports delta `8` / direction `1`, and reverse motion reports delta `-8` / direction `-1`.

`examples/spi_loopback.be` is now hardware-run on the current native-Catalina XMM image and reaches `sync serial probe done` with bounded scalar diagnostics. It reports synchronous-serial receive policy as unverified, the first clocked word as `not_ready`, and default variant execution as deferred; matched receive-data loopback remains open.

`examples/vga_test_pattern.be` and `examples/usb_keyboard_mouse.be` are now hardware-run on the current native-Catalina XMM image and reach their explicit final markers while reporting backed `p2compat` unsupported records instead of faking VGA or USB behavior.

`examples/nco_counter_loopback.be` now hardware-runs with scalar output on the current native-Catalina XMM image and reports counter deltas `41` and `20` for the two NCO increments before reaching `nco counter loopback done`.

`examples/cog_closure_blink.be` now hardware-runs on the current native-Catalina XMM image and reaches `cog closure blink done` after stopping/killing the native-blink handles and floating pins `38` and `39`.

The legacy `examples/p2/` helper examples now also have focused hardware evidence on the current native-Catalina XMM image: bounded LED blink, pin helpers, smart-pin helpers, timing helpers, scalar low-level hardware helpers, native-blink closure cleanup, and source-backed cog unsupported-policy reporting all reach explicit final markers.

`examples/wifi/detect.be` now hardware-runs on the current native-Catalina XMM image as a metadata-only WiFi/AirLift diagnostic and reaches `wifi detect done` without initializing the peripheral.

`examples/import_all_libs.be` now includes metadata-only `wifi` in its quick import sweep and hardware-runs to `import all libs example done`; `p2mem` and `p2smart` remain excluded from that user-facing example because they make the sweep slow, while separate direct import-chain probes pass through both modules.
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

`tests/p2/smoke_strict.be` adds dedicated native `strict` module coverage for
strict compiler-mode activation, method-body plus branch-, loop-, and conditional-expression global lookup, expression-without-side-effect rejection,
missing-global rejection including function-scope lookups, accepted side-effect
expressions, known-global compile visibility including function-scope lookups,
and cleanup after `global.undef()`.

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

`tests/p2/smoke_errors.be` adds compact exception/error-path coverage for normal
`try`, custom `raise`, function- and method-propagated raise, nested handling and rethrow propagation, syntax errors, key errors,
type errors, and bytes index errors.

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
`.bec` execution and host-like APIs separate. `tests/p2/smoke_p2compat.be`
verifies the current capability table.

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

`tests/p2/smoke_libraries.be` also guards the lazy-loader policy: SD remains
the library home, source loading stays lazy, direct PSRAM execution is false, status/policy/strategy/module-list diagnostic snapshots are isolated from caller mutation,
and source fallback is only reported when a staged `.bec` candidate actually
exists.
It also covers `binary_heap.sort()` empty/singleton inputs and preserves the
caller array if a comparison callback raises during heap construction/removal;
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
`p2mem.module(name)` exposes the same metadata as a single-module lookup for
diagnostics and tests, and `tests/p2/smoke_libraries.be` checks that returned
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

`p2.debug` now exposes only backed diagnostics: `snapshot`, `heap`, `gc`, `cogs`, `memory_map`, `pin`, `pins`, `smartpin`, and `registers`. Breakpoints, tracing, source stack traces, module cache internals, task/lock/channel internals, and PASM single-step remain open rather than silently stubbed.

Hardware status: the flashed Catalina XMM image exposes all grouped modules
(`p2.clock`, `cog`, `lock`, `pin`, `cordic`, `math`, `rng`, `smart`, `asm`,
and `debug`). The full `/tests/p2/smoke_p2_api.be` run passed on
`/dev/ttyUSB0` with image `959808 / 16777216` bytes, covering clock waits,
cog/lock basics, LED pin I/O, CORDIC/math/RNG/asm reads, debug maps/registers,
64-pin snapshots, and negative diagnostics.
### Lower-case task facade

`modules/task.be` is now the active cooperative scheduler API with cooperative primitives and Spin2-style lifecycle aliases over the source-level scheduler. This completes the source-level step scheduler surface, not the still-open independent-stack or true Spin2/PASM task-switching work.
### Documentation set expansion

The P2 documentation set now includes getting-started, building, board-support, SD layout, PSRAM loader, Berry compatibility, P2 API, smart pins, cogs, tasks, PASM, debugging, performance plan, hardware-test guide, and limitations documents. These docs intentionally separate backed features from planned or unsupported work.
### Cooperative p2 IPC facade

`modules/p2ipc.be` attaches cooperative Hub-memory `p2.channel`, `p2.mailbox`, `p2.shared.Buffer`, and `p2.mutex` helpers to the native `p2` module. `p2ipc.capabilities()`, `p2ipc.capability(name)`, `p2ipc.attention_policy()` / `p2ipc.attention_policy_value(name)`, `p2ipc.contract()`, and `p2ipc.contract_value(name)` make the current-VM/no-cross-VM contract queryable, including the current lack of cross-cog wakeups, serialization, and ownership transfer. The attention policy records that bounded native cog-attention waits are available through `p2.cog.wait_attention_result()` on current P2 images, but not wired into IPC channel/mailbox wakeups yet. `p2ipc.required_capability_keys()` and `p2ipc.required_contract_keys()` expose the required metadata fields, and `p2ipc.audit()` reports missing capability or contract keys instead of letting contract drift hide in separate maps. Channels and mailboxes can expose non-consuming diagnostics through `snapshot_result()` and `peek_result()`, can clear queued/stored payload references while remaining reusable, and also release those references on close; shared buffers can be explicitly zeroed with `clear()` / `clear_result()`. Channel and mailbox objects now expose task-readable object kinds so `task.wait()` can poll current-VM receive/send or get/put readiness after `p2ipc` is imported; `task_wait_integration`, `task_wait_channel`, and `task_wait_mailbox` make that queryable without implying cross-cog IPC wakeup. `p2ipc.self_test_result(iterations)` provides a bounded current-VM cleanup diagnostic over channel, mailbox, buffer, and mutex paths. The host regression covers capability diagnostics, required-key metadata checks, contract direct lookup and snapshot diagnostics, attention-policy snapshot diagnostics, bounded self-test diagnostics, task-readable channel/mailbox object kinds and metadata, channel snapshot and mailbox peek diagnostics, clear-with-payload, buffer zeroing, and close-with-payload release, hardware-lock use, fallback-lock use, hardware-lock allocation failure, blocked-lock sends/receives, default and invalid channel depths, invalid buffer sizes, invalid byte offsets/values, buffer snapshot isolation, compact `info()` diagnostics for channel/mailbox/buffer/mutex state, idempotent close/closed-state behavior, channel/mailbox/mutex close-result maps, and result-shaped `send_result()` / `recv_result()` / `put_result()` / `get_result()` / mutex / buffer diagnostics that distinguish valid `nil` payloads from empty/full/busy/not-locked/closed/error states. This completes the current-VM API surface with host/P2 smoke coverage, while actual cross-cog attention wakeups, cross-VM serialization, and longer stress/soak behavior remain open.
