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
| Build system | Partial | Catalina make targets, profile selection, native Catalina path, image size guards, Edge32 and XMM commands exist and are documented. `make test-host`, `make test-p2`, and `make soak-p2` now exist as repeatable test entrypoints. | Keep no-PSRAM Edge and Edge32/XMM paths green while features are added; expand test coverage behind the new entrypoints. |
| Boot on selected board | Verified | `p2-edge32-flash` boots from SPI flash on P2 Edge 32 MB. `p2-xmm-flash` boots after the expected copy delay. | Keep re-verifying after substantial firmware changes. |
| REPL core behavior | Partial | Arithmetic, strings, maps, lists, ranges, blank input, and quit behavior are live-verified. | Convert smoke notes into repeatable automated coverage. |
| Berry language feature coverage | Partial | Core interactive syntax, compiler/parser regression shapes including call-argument ternary, ternary-result suffix, call-result chained suffix, and chained-suffix parsing, built-ins including `call()` non-callable rejection, bytes length truthiness through `bool()`, range type classification and numeric parser edges, numeric passthrough conversions, and custom conversion edge values, safe Berry-level C API edge probes including reflection member replacement and map copy isolation, collection checks including dedicated list-core `size()` API shape, iterator exhaustion, index-list ordering, reverse in-place behavior, and copy isolation, map values, range method API shape, range increment/setrange/positive and negative iterator isolation including independent iterator exhaustion plus retargeted-range iterator preservation and exhaustion, and plain-map behavior coverage including `keys()`/`values()` API shape, keys/values snapshot isolation, mixed-type key distinction, nil-value presence, and nil-valued insert preservation, closures including returned-closure function classification, dedicated escaped-closure and factory returned-function classification, parameter/local capture, shared-upvalue multi-closure and group-independence, nested upvalue-chain, captured mutable-object independence, and upvalue mutation coverage, varargs including direct, direct rest-list freshness, closure, escaped rest-list capture and mutation persistence, method packing, method rest-list freshness, and vararg-list mutation isolation, loop control including empty-range iteration, class iterator closure isolation, list-iteration break/continue, nested break/continue isolation plus outer-break coverage, and dedicated for-loop recursion coverage, byte behavior including base64 one-byte padding, two-byte padding, single- and multi-quantum no-padding quanta, fixed-size bytes, and fromstring shortened replacement/copy isolation, compact VM operator/full-span negative slicing/comparison-result typing/operator-overload checks including derived inequality including callable instances plus callable-instance list-lookup invocation and binary instance-result class identity and chained binary instance-result overloads, focused VM runtime, named-global cleanup, invalid comparison, and shift-operator error paths, integer conversion/negative `toint()`/lowercase and uppercase hex/bitwise/positive shift/variable shift counts/zero-shift identity and signed right-shift checks, lexer literal/block- and line-comment-adjacent token parsing/hex escape boundary/malformed-token checks, class/static/indirect-member checks including instance class identity, instance-method static-member reads including post-construction static updates, computed class/instance method-name calls, dynamic static writes, and chained indirect updates, static initializer/mutable static object sharing/`_class`/nested static class first-class identity checks, static member/function-member reassignment and scalar compound update checks including mutable static-object sharing and inherited static readback, legacy/grouped static declaration checks including mutable static list/map values plus method-visible and cross-instance shared static fields, subclass-from-module-member static checks including inherited method live static fallback and child/base static mutation separation, module creation/same-name module object and member-table independence/injected-module identity/replacement/cache monkey-patch/restore checks plus compiled module-member mutation, module attribute-dispatch including function-valued virtual members plus real-attribute and post-virtual shadow precedence without hook checks, constructor chaining, external and leveled super-proxy method calls, chained super argument passing, plus auto/leveled `super()` checks, builtin list/map subclass method/storage including map-subclass keys snapshot isolation, subclass instance fields, builtin method preservation, and subobject relationship checks, map instance-key/hash/equivalent-key replacement/removal/collision checks, `undefined` sentinel plus virtual `member()` computed-name reads including function-valued module reads and real-member precedence, plus `setmember()` repeated assignment replacement, computed-name scalar and function-valued assignment, and computed-name/real-member dispatch checks, f-string indexed-expression including computed map keys and computed-width formatting plus walrus syntax checks including builtin shadowing/sequential value-expression/local call-argument value-expression and map-literal assignment-expression edges, conditional-expression selected-branch side-effect, condition-operand single-evaluation, and collection-truthiness checks, compound-assignment computed-index, computed map-key sibling isolation, and computed-member update checks, nested suffix-assignment, computed map-key/member assignment with sibling isolation, and computed-member checks, cyclic list/map plus shared-child reference stringification checks, suffix/list-append expression, method-chain indexing including negative indexes, and method-chain slicing checks, boolean/truthiness/short-circuit checks including skipped/executed branch side effects, truthy non-bool, and falsey collection operands including OR branch execution, relational/equality checks including list order sensitivity, map order/nested-map order/nil equality and bytes equality, literal and computed-denominator division-by-zero exception checks plus negative non-zero division/modulo sign behavior, and compact exception/error-path checks including key-error handling, function- and method-propagated raise and assert-failure exception capture across default-message assert, loop, function-call, method-call, and closure-call propagation cases exist. | Cover all built-ins listed in `goal.md`, including tests and docs. |
| Berry standard-library coverage | Partial | `string` including module/API shape, SD-backed `math`, `json` including module/API shape, compact parse-freshness and dump-state, advanced parser, and generated stack/growth cases including matrices, `bytes`, `os`, file operations, `time` including compact dump snapshot-freshness, `global` including API shape, `sys` including module/API shape, `introspect` including module/API shape, `solidify` including introspected helper discovery, `debug` including API shape and helper discovery, and `strict` including branch-condition lookup checks have P2 smoke coverage or prior live checks. SD `math` now exposes `math.accel_info()` for its guarded P2 CORDIC trig/polar backend and pure-Berry fallback. Bounded import/GC churn and import-all coverage now exists for the current SD module set, and `libstore.info()` / `libstore.inventory()` now expose per-module coverage metadata for behavior, SD import, repeated import/cache, PSRAM source-cache, low-memory churn, metadata, and hardware-deferred cases, with smoke coverage that returned inventory and compiled-summary snapshots are isolated from caller mutation and inventory source metadata matches `source_stats()`. | Verify all included upstream modules and add normal, SD import, repeated import/cache, PSRAM-cache, and low-memory tests where relevant. |
| Berry expansion-module coverage | Partial | Native `i2c`, `spi`, `spin2`, WiFi import surface, `task.be`, and declarative `p2compat.be` capability metadata are documented. `p2compat` now reports supported package-style SD imports, supported native `sys` module path helpers, staged `.bec` manifests, bytecode cache emission, bytecode validator policy, discoverable valid status names, capability-name lists, a compact report snapshot, self-audit results, and concise audit-problem names separately from unsupported host-like APIs; its smoke also checks summary/inventory consistency, status-filtered capability queries, name-list queries, report consistency, audit consistency, returned-list mutation isolation, returned-record mutation isolation, summary and report nested-summary snapshot mutation isolation, and bytecode snapshot mutation isolation. | Finish hardware validation and keep unsupported host-like features explicit. |
| SD loader coverage | Partial | `/modules` lazy import root works. FAT fallback to sector `2048` works. `/modules/math.be` imports from SD. Source-level support now exists for import aliases including repeated SD alias cache identity and source-path/info diagnostics, missing-import failure/retry recovery, native-module-first precedence and repeated native import identity across `/berry/lib` and `/berry/app` shadows, module-root order including `/modules` before `/berry/lib` before `/berry/app` with matching source-path/info diagnostics, current-directory imports with cwd-before-root precedence and cached alias re-import identity checks, additive `sys.path_add()` import roots with source-path/info diagnostics, scoped `libstore.path_add()` custom-root source-path/info diagnostics, optional `/berry/main.be` staging/run/cleanup path checks, `/berry/lib/*.be` including nested package source layout and source-path/info diagnostics, `/berry/app/*.be` including dotted nested app helpers and missing-app path/existence/run fallback checks, `/berry/config/*.json`, nested package file lookup for string imports such as `import "pkg.mod" as mod`, bare dotted imports such as `import pkg.mod`, comma-separated dotted imports such as `import pkg.mod, pkg.other`, `.bec` path detection with source fallback, `.bec` sidecar freshness manifest metadata, opt-in bytecode-saver-gated `.be` to `.bec` cache emission helper coverage, repeated import/cache smoke coverage, and opt-in `/berry/...` provisioning targets. | Run full scripted SD smoke suite; add `.bec` execution, path removal/reordering only if a real safe semantics is defined, and full layout coverage. |
| PSRAM cache coverage | Partial | `p2.psram_info()`, `p2.psram_test()`, bounded read/write, chunked `libstore` source-cache round trips, and `p2mem` diagnostics/eviction facade are covered by smoke/host regressions. `/tests/p2/smoke_xmm_gc_stress.be` passed on standalone XMM, proving retained Berry lists/maps/strings/closures survive GC in the external heap, temporary churn is reclaimed, and the heap stays inside the pointer-addressable lower PSRAM window. | Complete inactive bytecode/module cache tier, hashes, hit/miss accounting, refcounts, last-used timestamps, and broader low-memory/soak behavior. |
| P2 primitive API coverage | Partial | Current flat `p2.*` helpers cover pieces of clock/counter, wait, cog, pins, CORDIC, smart pins, PSRAM, filesystem, and diagnostics. Grouped `p2.clock`, `p2.cog`, `p2.lock`, `p2.pin`, `p2.cordic`, `p2.math`, and `p2.rng` aliases now exist with P2 smoke coverage. Low-level negative integer, cog, lock, pin, and reserved-pin validation paths have smoke coverage. | Run hardware smoke for the grouped API and continue toward high-level wrappers. |
| Smart pin mode coverage | Partial | Raw smart pin helper surfaces exist. Grouped raw aliases exist under `p2.smart`. | Research and cover all requested mode families and high-level wrappers. |
| High-level hardware wrapper coverage | Planned | Some native bus APIs exist through `i2c` and `spi`. | Add friendly GPIO, PWM, ADC, DAC, timer, quadrature, UART, SPI, and USB wrappers. |
| PASM/assembly integration | Partial | Raw cog program startup via `p2.cog_start_hex()` exists. Safe `p2.asm` aliases now expose `getrnd`, `getct`, `waitx`, and `hubset` with smoke coverage. | Add PASM blob loading, cog launcher, function bridge, ABI docs, and unsafe build flag. |
| Multicog Berry VM coverage | Partial | Interim `p2.cog.spawn(closure, ...primitive_args)` accepts a live Berry closure and returns stoppable integer handles. The verified p38/p39 LED use case is the GPIO-specific `native_blink` fast path for `spawn(closure, pin, rate_ms)`: it invokes the passed closure once during setup, uses the positive integer return value as the period, runs a native pin loop on the spawned cogs with a 2048-byte stack, and reports `model == "native_blink"` plus `native_blink == true` in handle diagnostics. The default firmware now rejects unsupported closure-cog shapes instead of running the unsafe shared-VM dispatcher; that dispatcher is diagnostic-only behind `BE_P2_ENABLE_UNSAFE_SHARED_VM_COG`. | Evolve toward independent per-cog VM/GC isolation before claiming arbitrary closure execution. |
| Closure-in-cog coverage | Partial | Captured closures are no longer only guarded: the interim shared-VM closure-cog path keeps the closure rooted in a VM registry and calls it with primitive args from another cog while REPL execution is paused. | Replace the REPL-idle shared-VM proof with true independent VM closure launch or explicit capture serialization/rejection rules. |
| IPC coverage | Partial | Importing `p2ipc` now attaches cooperative `p2.channel`, `p2.mailbox`, `p2.shared.Buffer`, and `p2.mutex` APIs with host and P2 smoke coverage; mutexes use `p2.lock` hardware locks when available. | Add cross-VM/cross-cog wakeups, cog attention integration, serialization rules, and stress/soak coverage. |
| Cooperative task coverage | Partial | `modules/task.be` exposes the P5 cooperative scheduler API, 16 fixed slots, host/P2 smoke coverage, and cooperative Semaphore/Mutex/Queue/EventFlags/Timer primitives. | Independent Berry call stacks/coroutines, true Spin2/PASM switching, non-callback stackful execution, and broader stress/soak testing remain open. |
| Debug feature coverage | Partial | `p2.fs_info()`, `p2.status_info()`, `p2.debug_snapshot()`, `p2mem`, heap, module, cache, and PSRAM diagnostics exist. `p2.debug` now exposes backed heap, GC, cog, memory-map, pin, smart-pin, and current-cog register diagnostics with smoke coverage. | Add breakpoints, trace controls, source stack traces, task/module/lock/channel internals, broader registers, and PASM debug support. |
| Example coverage | Partial | Interactive examples are documented in P2 docs and handoffs. | Add explicit example files requested in `goal.md`. |
| Host test coverage | Partial | `make test-host` runs the existing host suite plus fake-PSRAM `libstore` and `task` scheduler regressions. | Add host tests for fake SD, `.bec`, import cache, eviction, errors, closure serialization, and broader low-memory behavior. |
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
| `range` | Partial | Literal ranges plus `range()` increments, descending ranges, accessors, string forms, `setrange()`, independent iterator exhaustion, retargeted iterator preservation, iteration, and selected value errors have P2 smoke coverage or prior live checks. The non-precompiled range registration table now exports `incr()` after P2 RAM smoke found it missing; re-run is pending. |
| `string` | Verified | `toupper` and `find` documented. Needs automated test coverage. |
| `math` | Verified | SD-backed import and `sqrt(81)` documented on Edge32 and XMM flash. P2 smoke now covers finite trig/log/pow helpers, rounding helpers, angle conversion, `nan`/`inf` constants and JSON dumping, `min`/`max` value/type/error behavior, no-argument fallbacks, deterministic `srand`/`rand`, core constants, and invalid-result nil behavior. Needs full hardware module test coverage. |
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
| GPIO | Partial | No-PSRAM LED checks documented; final high-level API still open. |
| PSRAM block API | Verified | `p2.psram_test()`, bounded read/write, and cache source round trip documented. |
| SD filesystem | Verified | Mount fallback and SD file operations documented. Full smoke suite still needs fresh run. |
### Current top-level example coverage

Implemented top-level examples now cover LED blink, SD REPL/startup handoff, library import sweep, JSON-on-SD, basic SD file I/O, cog/channel messaging, cooperative task scheduling, CORDIC/math helpers, PSRAM cache diagnostics, and debug snapshot reporting. Hardware-loopback and peripheral-specific examples such as ADC, DAC, PWM, UART, SPI, quadrature, VGA, USB HID, cog closure, and direct PASM remain open in `port/p2/TODO.md`.
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
is present.

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

`tests/p2/smoke_sd.be` now covers SD-backed `file`, `os`, and `os.path` behavior through create/write/append/`r+` update/`w+`/`a+`/flush/tell/size/seek/read/readbytes/readlines/rename/remove checks, missing-path negatives, temporary directory mkdir/chdir/getcwd/isdir/listdir cleanup, cwd-relative file creation/removal, plus basename/dirname/join/split/splitext helper-shape checks including local no-extension paths. This is coverage for the current SD-card filesystem mapping, not a claim that all host-like OS behavior exists on bare metal.

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

`tests/p2/smoke_import_churn.be` adds a bounded low-memory/import regression
that also checks `libstore.info()` / `source_stats()` source size/hash parity
check. It allocates a modest temporary batch, forces `p2.gc()`, then verifies
that repeated imports of the current SD module set plus native `json` still
preserve module identity and safe behavior.

`tests/p2/smoke_import_all_libs.be` imports the current SD module set and checks behavior-smoke metadata plus source size/hash parity plus
safe non-probing behavior for each module. It deliberately avoids WiFi hardware
detection and peripheral transactions.

`tests/p2/smoke_import_alias.be` checks `import name as alias` for native and
SD-loaded modules, including `string`, `json`, `math`, `libstore`, and
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
filename-only validation. Hardware execution of the expanded full smoke remains
pending.

`tests/p2/smoke_stdlib.be` adds a compact standard-library compatibility smoke
for `string`, `json`, `time`, `global`, `solidify`, and `strict`. It samples
stable upstream behavior including string search/split/escape/format/replace,
prefix/suffix checks, string multiplication, JSON scalar/nested/invalid/pretty-
dump cases, deterministic fixed-epoch time dumps, compact `time.dump()` snapshot freshness, and invalid scalar including bool-false/empty and non-empty collection time input,
global module compile lookup, and strict-mode compile errors without pulling in
the larger host-only stress tests.

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
`math`, `p2compat`, `p2ipc`, `p2mem`, `task`, and `wifi`.
`p2mem.module(name)` exposes the same metadata as a single-module lookup for
diagnostics and tests, and `tests/p2/smoke_libraries.be` checks that returned
`p2mem.stats()`, `p2mem.module(name)`, `p2mem.modules()`, `p2mem.cache()` status/item-list, `p2mem.gc()`, and `p2mem.evict()` diagnostics snapshots are isolated from caller mutation, with cache-item shape checked on a fresh post-mutation snapshot.

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
`libstore.pasm_path/pasm_exists/pasm_info` detect staged `/berry/pasm/*.bin`
files, including dotted nested blob paths and missing-blob path/existence/info behavior, while keeping PASM execution deferred.
### Safe p2.asm facade

`p2.asm` now exposes safe PASM-adjacent intrinsics for random, counter, wait, and hubset access by aliasing existing validated native helpers. Arbitrary assembly text, PASM blob loading, function bridging, and unsafe execution remain open and should stay gated or unsupported until the safety model is explicit.
### Structured p2.debug facade

`p2.debug` now exposes only backed diagnostics: `snapshot`, `heap`, `gc`, `cogs`, `memory_map`, `pin`, `pins`, `smartpin`, and `registers`. Breakpoints, tracing, source stack traces, module cache internals, task/lock/channel internals, and PASM single-step remain open rather than silently stubbed.
### Lower-case task facade

`modules/task.be` is now the active cooperative scheduler API with cooperative primitives. This completes the source-level step scheduler, not the still-open independent-stack or true Spin2/PASM task-switching work.
### Documentation set expansion

The P2 documentation set now includes getting-started, building, board-support, SD layout, PSRAM loader, Berry compatibility, P2 API, smart pins, cogs, tasks, PASM, debugging, performance plan, hardware-test guide, and limitations documents. These docs intentionally separate backed features from planned or unsupported work.
### Cooperative p2 IPC facade

`modules/p2ipc.be` attaches cooperative Hub-memory `p2.channel`, `p2.mailbox`, `p2.shared.Buffer`, and `p2.mutex` helpers to the native `p2` module. This completes the current-VM API surface with host/P2 smoke coverage, while cross-cog attention, cross-VM serialization, and stress/soak behavior remain open.
