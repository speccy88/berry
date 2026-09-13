# P2 collection API compatibility — implementation candidate

This is a bounded **host-only script migration candidate**, not completion or delivery of the P2 port. Work stayed in `/opt/data/propeller2/berry` on `fix/p2-stability`. The parent owns core C, native timing, build configuration, SDK, hardware, integration and final delivery. No commit/push, hardware/serial access, background jobs, controller/profile changes or delegation were used.

The repair found the preceding candidate's script changes and evidence intact but this required report absent. It added the report and tightened two remaining legacy audit-result alternatives; it did not undo the parent's restored `be_typename`, live `sys.path()` or standard import-cache lookup.

## Contract and migration

`type(value)` reports Berry's value kind, not a collection's class name. Public list/map objects, their subclasses and unrelated user objects all have value kind `"instance"`. Use class identity for collection APIs:

```berry
assert(type([]) == "instance")
assert(type({}) == "instance")
assert(isinstance([], list))
assert(isinstance({}, map))
assert(!isinstance({}, list))
```

A list-only argument guard is `if !isinstance(value, list)`, not a comparison with `"list"`, `"instance"`, or `classname(value)`. Actual subclasses are accepted; an unrelated class merely named `list` or `map` is not. Scalar/function/module dispatch still uses `type()` where appropriate. A diagnostic type name remains a diagnostic, not an object validator.

Changes include:

- `modules/libstore.be:1180`: replace cached `data_type == "map" || data_type == "instance"` with `isinstance(data, map)` for the decoded JSON object. Arbitrary user instances are not valid decoded manifest maps. Both outer and nested build-status maps are checked at `:1266`.
- `modules/math.be:28`: CORDIC capability probing accepts genuine map results, including subclasses.
- `modules/p2compat.be:256-267,381,538,633,648`: explicit outer/nested map guards and list-copy decisions. Non-list policy payloads still pass through unchanged.
- `modules/p2mem.be:19,34,362,1019,1037`: map diagnostics and list-of-module-name validation, including the two old `classname(names)` guards.
- `modules/p2smart.be:2385-3500`: all list guards, including nested pair/group validation and the `failed_checks` result list at `:2972`. Scalar pin/count checks are unchanged.
- Cached type variables in P2 fixtures now check the original value directly. `maplike`/`listlike` test helpers require the actual collection class rather than accepting every instance.
- `tests/p2/host_p2ipc.be:301-302` and `smoke_p2ipc.be:114-115` expect diagnostic `payload_type == "instance"` and separately assert the payload's list class.
- `tests/p2/host_libstore_chunk.be` explicitly registers its host-only `p2` and `libstore` stubs with `introspect.setmodule`. This adapts the fixture to standard import lookup; production import lookup was not changed.
- `tests/p2/host_source_modules.be` runs the new focused fixture at the end, so the existing host gate exercises it without editing the Makefile or its nine-fixture list.
- `tests/p2/smoke_cog_policy_min.be:75` and `smoke_pasm_policy_min.be:105` now require `isinstance(audit, map)` unconditionally. Removed their legacy string-success alternatives; retained the field and copy-isolation assertions. Read-only confirmation: `port/p2/overrides/be_p2lib_p2.c:4129-4157` and `:1574-1596` construct map audit results. These target smoke scripts were syntax-checked, not run on native P2 hardware.

## Inventory reconciliation and reviewed counts

Read `/opt/data/propeller2/berry-stabilization/stdlib/INVENTORY.md` and the relevant `inventory.json` dependency inventory, then checked actual source and the persisted pre-migration scripts in `build/p2-collection-tests/before/`.

The original inventory reports 62 equality and 16 inequality dependencies. Counting actual call comparisons in the saved source gives **79 direct comparisons on 78 source lines: 63 equality and 16 inequality occurrences**. `libstore.build_features` has two map comparisons on one line. The migration also covers cached type comparisons and name-based guards that a direct `type(...)` search alone misses.

Current review covers **10 production module files and 142 P2 script files** (141 existing P2 files plus the new focused fixture). The full file list is below. Five production files and 26 P2 files differ from the pre-migration snapshot: 25 existing P2 files changed and one new fixture.

Production migration counts, listed as direct `type` comparisons / cached collection comparisons / `classname` guards:

- `modules/libstore.be`: 2 / 1 / 0.
- `modules/math.be`: 1 / 0 / 0.
- `modules/p2compat.be`: 8 / 0 / 0.
- `modules/p2mem.be`: 3 / 0 / 2.
- `modules/p2smart.be`: 17 / 0 / 0.
- Total: 31 direct comparisons, 1 cached comparison and 2 name guards; **34 production collection decisions** migrated.
- Reviewed unchanged: `modules/binary_heap.be`, `configstore.be`, `p2ipc.be`, `task.be`, `wifi.be` (all paths under `modules/`).

Changed existing P2 files, with direct / cached collection-comparison counts from the saved source:

- `tests/p2/host_libstore_chunk.be`: 0 / 0; explicit host cache registration.
- `tests/p2/host_p2ipc.be`: 0 / 0; diagnostic value kind plus strict payload class.
- `tests/p2/host_source_modules.be`: 0 / 0; focused fixture integration.
- `tests/p2/impcache.be`: 0 / 2.
- `tests/p2/impchurn.be`: 0 / 2.
- `tests/p2/smoke_bec_fallback.be`: 6 / 0.
- `tests/p2/smoke_cog_closure.be`: 0 / 2.
- `tests/p2/smoke_cog_policy_min.be`: 1 / 0; additionally remove string-result alternative.
- `tests/p2/smoke_conversions.be`: 2 / 0; assert both standard value kind and collection class.
- `tests/p2/smoke_import_all_libs.be`: 2 / 1.
- `tests/p2/smoke_import_cache.be`: 0 / 1.
- `tests/p2/smoke_import_churn.be`: 1 / 1.
- `tests/p2/smoke_libraries.be`: 0 / 2.
- `tests/p2/smoke_map_core.be`: 1 / 0.
- `tests/p2/smoke_math_parity.be`: 1 / 0.
- `tests/p2/smoke_math_perf_min.be`: 1 / 0.
- `tests/p2/smoke_module_inventory.be`: 14 / 0.
- `tests/p2/smoke_modules.be`: 5 / 0.
- `tests/p2/smoke_p2_api.be`: 3 / 0.
- `tests/p2/smoke_p2ipc.be`: 0 / 0; diagnostic value kind plus strict payload class.
- `tests/p2/smoke_pasm_policy_min.be`: 2 / 0; additionally remove string-result alternative.
- `tests/p2/smoke_sd.be`: 2 / 0.
- `tests/p2/smoke_sd_min.be`: 1 / 0.
- `tests/p2/smoke_smartpins_sync_diag.be`: 2 / 0.
- `tests/p2/smoke_xmm_heap.be`: 4 / 0.
- Existing-fixture total: 48 direct and 11 cached collection comparisons.
- New: `tests/p2/host_collection_types.be`.

The audit tokenizes source, excludes comments, balances `type`/`classname` calls, checks comparisons in either order, records cached-identity assignment candidates and reviews every remaining collection-name literal. It is a bounded source audit, not a general data-flow analyzer. Source review distinguishes true cached type names from assignments of boolean/scalar dispatch results.

Reproducible audit command:

```sh
python3 build/p2-collection-tests/audit.py
```

Retained result: `build/p2-collection-tests/repair-final-source-audit/`, exit 0. No direct or cached collection type-string comparison remains anywhere in the owned scripts, and no production collection classname comparison remains. Per-file counts and source/line listings are in its `output.log`. Occurrence/line reconciliation is retained in `repair-inventory-counts-final/` (exit 0).

## Deliberately retained checks and user-object support

- `modules/math.be:38-39`: cached `t = type(x)` dispatches only `"int"`/`"real"`. It is not a collection discriminator.
- Scalar/function/module guards throughout all ten modules stay intact. Examples include `modules/libstore.be:1330` (save-function availability), `modules/task.be:1945` (integer event flags), and `modules/wifi.be:356` (module configuration). The first two are cached-expression candidates in the audit but do not cache a collection name.
- `modules/p2ipc.be:17,1192`: `payload_type` and invalid-object `kind` remain standard diagnostic type names. In-VM IPC intentionally carries arbitrary user instances by reference, without serialization or ownership transfer. `lifecycle_result` still dispatches an object's method rather than requiring a collection.
- `modules/task.be:238-255,1027-1035`: task/wait object protocols and diagnostic fallback `type(obj)` remain unchanged. These APIs intentionally support protocol-bearing user objects, not just collections.
- `modules/p2compat.be:363`: the `"list"` and `"map"` literals are members of the documented child-VM rejection-policy vocabulary, not runtime classification. These are the only two exact collection-name string literals left in production source outside comments. Policy tests in `host_source_modules.be` and `smoke_import_all_libs.be` intentionally query/mutate copies of that vocabulary.
- `tests/p2/p2compvm.be:29-30,58,77,98` and `smoke_p2ipc.be:118`: `kind`, `first_rejected_kind` and `copyable_kind` test the native transfer-policy diagnostic labels, not Berry `type()`. Read-only source confirmation: `be_p2lib_p2.c:6518-6553` explicitly produces `"list"`/`"map"` after actual list/map checks. No native behavior is inferred from host stubs.
- `tests/p2/smoke_collections.be:74-75`: an intentional `type(m) == "instance"` / `classname(m) == "map"` reflection assertion on a literal map, not an API guard.
- `tests/p2/host_collection_types.be:39-40`: classname assertions prove that the rejection fixtures really are named `list`/`map`; subsequent strict class checks prove the names confer no collection identity. Literal `"list"` inputs are deliberate scalar rejection cases.
- `tests/p2/smoke_cog_closure.be:221`: pre-existing exception-payload type alternatives are retained. They classify caught error payloads, not collections; changing native exception contracts is outside this migration. The collection helpers in that file are strict.
- Other `type(...) == "instance"` assertions in class/operator/compatibility tests remain value-kind assertions. Root core tests were not edited or weakened by this milestone.

## Focused positive and rejection coverage

`tests/p2/host_collection_types.be` executes real Berry script logic with explicitly host-only module seams. It checks:

- Built-in lists/maps and true subclasses have kind `instance`, have the correct collection class, and fail cross-collection checks.
- Nil, booleans, integers, strings, ordinary user instances, collection class objects, and unrelated user classes named `map`/`list` are not collections.
- Map-only memory/build/runtime diagnostics, nested build maps, GC reports and math capability detection accept real maps/subclasses and reject non-maps.
- Module-name lists accept list subclasses and reject other values with the documented error/result shape.
- Policy getters copy actual lists but preserve arbitrary instance/scalar payloads unchanged.
- IPC retains arbitrary user objects and reports `payload_type == "instance"` without claiming serialization or cross-VM transfer.
- Smart-pin aggregate list/sublist guards accept real subclasses, filter an invalid `failed_checks` object to the documented empty list, and reject non-list values and malformed pair/group entries with exact exception kinds/messages.

The host seams are not target output. The focused fixture prints only `P2_HOST_PASS collection_types (host-only)` after its assertions pass. It runs independently and through the existing `host_source_modules.be` fixture.

## Real execution evidence

All evidence is under the Git-ignored directory:

`/opt/data/propeller2/berry/build/p2-collection-tests`

Each execution directory contains `result.json` (exact argv, shell-quoted command, cwd, return code, timestamps and duration) and `output.log` (unmodified merged stdout/stderr). `run.py` captures real subprocess output; empty fixture logs mean no output, not missing evidence. Host commands use Docker user `10000:10000` and container workdir `/work/propeller2/berry`.

### RED before the original migration

The saved `before/` scripts and `baseline*` execution logs predate the migration. This repair inspected those records rather than reverting passing scripts or fabricating a new failure.

```sh
/usr/bin/docker exec --user 10000:10000 --workdir /work/propeller2/berry propeller2 make test-p2-host CC=clang TEST_FLAGS= USE_READLINE=0
```

`baseline/`: **exit 2**, first failing fixture `host_libstore_chunk.be:59`:

```text
import_error: module 'p2' not found
stack traceback:
    modules/libstore.be:11: in function `main`
    <native>: in native function
    tests/p2/host_libstore_chunk.be:59: in function `main`
make: *** [mk/common.mk:59: test-p2-host] Error 1
```

All nine fixtures were also run individually, with `./berry tests/p2/host_<name>.be` after the same Docker prefix. Saved `baseline-host_*` results: `libstore_chunk`, `p2ipc`, `source_modules`, `libstore_bec`, `p2smart` exit 1; `task`, `import_cache`, `libstore_cache_errors`, `p2mem_native_cache` exit 0. Thus five failed and four passed.

`baseline-host_p2smart/`: **exit 1**, actual output:

```text
type_error: values must be a list
stack traceback:
    modules/p2smart.be:2387: in function `_anonymous_`
    tests/p2/host_p2smart.be:820: in function `main`
```

The handoff's advertised `host_p2smart.be:39` failure did **not** reproduce in this source state. The actual RED locations above are preserved verbatim in the logs. Line 39 of the saved fixture assigns a smart-pin constant.

### Passing repair runs

Final required gate, same exact command as the RED command above:

- `repair-final-host-suite/`: **exit 0**. All nine fixtures executed in the Makefile's existing order; the nested focused fixture printed its host-only pass marker.
- Compiler output includes the existing unused `baselib_trace` warning in `src/be_baselib.c:33`; no warning suppression or core change was made.

Individually executed existing host fixtures, each using the same Docker prefix followed by `./berry` and the exact file below:

- `tests/p2/host_libstore_chunk.be`: exit 0, empty output; `repair-host_libstore_chunk/`.
- `tests/p2/host_task.be`: exit 0, empty output; `repair-host_task/`.
- `tests/p2/host_p2ipc.be`: exit 0, empty output; `repair-host_p2ipc/`.
- `tests/p2/host_source_modules.be`: exit 0, `P2_HOST_PASS collection_types (host-only)`; `repair-host_source_modules/`.
- `tests/p2/host_libstore_bec.be`: exit 0, empty output; `repair-host_libstore_bec/`.
- `tests/p2/host_import_cache.be`: exit 0, empty output; `repair-host_import_cache/`.
- `tests/p2/host_libstore_cache_errors.be`: exit 0, empty output; `repair-host_libstore_cache_errors/`.
- `tests/p2/host_p2mem_native_cache.be`: exit 0, empty output; `repair-host_p2mem_native_cache/`.
- `tests/p2/host_p2smart.be`: exit 0, empty output; `repair-host_p2smart/`.

Root suite:

```sh
/usr/bin/docker exec --user 10000:10000 --workdir /work/propeller2/berry propeller2 env TZ=UTC ./berry testall.be
```

`repair-final-root-testall/`: **exit 0**. Actual summary:

```text
test results: 58 total, 0 failed (all tests passed).
coverage tools not found; skipping lcov/genhtml report
```

The missing tools affect only the coverage report; testcases still ran. The output includes the original `map.be`, `class.be`, `module.be`, `list.be`, `be_api.be`, `walrus.be` and parent's additional type/import/path regressions. The full enumeration is preserved in the log.

Independent focused fixture:

```sh
/usr/bin/docker exec --user 10000:10000 --workdir /work/propeller2/berry propeller2 ./berry tests/p2/host_collection_types.be
```

`repair-final-focused/`: **exit 0**, `P2_HOST_PASS collection_types (host-only)`.

All **31 changed/new scripts** also compiled to host bytecode without execution; all returned 0 with empty output. Exact commands and artifacts are under `repair-compile-*`. The command shape is the Docker prefix followed by `./berry -c <source> -o build/p2-collection-tests/repair-compile-<source-with-dashes>/syntax.bec`. This is a host syntax check, not a Catalina build or native P2 runtime test.

`repair-scoped-diff-check/` records `git diff --check -- modules tests/p2 CHECKPOINT.md docs/P2_COLLECTION_TYPES.md`, exit 0. `repair-parent-before/` and `repair-parent-after/` contain identical parent-owned tracked diffs after excluding the owned paths. Existing parent changes were preserved.

### Other retained failures and limits

- `migrated-host-suite/` (earlier candidate): exit 2 at `host_libstore_bec.be:304`, because an earlier RED run left a generated source file. The exact generated directory was preserved as `red-bec-fixture/` before rerunning; no summary-count assertion was weakened. `preserve-red-bec-fixture/` records the move; later individual and suite runs pass.
- `focused-first/` and `focused-second/`: initial focused-fixture development failures, exit 1. Final tests avoid treating map equality as deep equality and avoid chaining list `push()` as if it returned the list. The failures remain available; only the final passing fixture is the candidate.
- `host-safe-collection-smokes/`: an optional earlier host run passed `smoke_conversions.be`, `smoke_map_core.be` and `smoke_collections.be`, then failed unchanged `smoke_subobject.be:32` (`assert(sublist[0] == 4)`). This is not one of the nine named host fixtures and has no migrated collection-string guard. It was not weakened, skipped in a passing claimed suite, or represented as a target pass. Parent follow-up must examine its subclass initialization/indexing expectation before broader smoke claims.
- `repair-inventory-counts/`: an auxiliary counting command failed with `KeyError: 'reviewed'`; corrected to the auditor's actual `reports` structure in `repair-inventory-counts-final/`, exit 0. This did not modify production or test source.
- No Catalina build, SD deployment, native pin/clock behavior, cog concurrency, PSRAM or hardware acceptance was performed. Parent-owned verification remains required, including execution of the stricter native audit smoke assertions.

No blocker remains for the named host acceptance command. `CHECKPOINT.md` records the handoff; the next step is independent acceptance and parent integration, **not an overall-project completion claim**.

## Full reviewed file list

All 10 production files:

```text
modules/binary_heap.be
modules/configstore.be
modules/libstore.be
modules/math.be
modules/p2compat.be
modules/p2ipc.be
modules/p2mem.be
modules/p2smart.be
modules/task.be
modules/wifi.be
```

All 142 P2 files below are relative to `tests/p2/`. Review means collection-classification source review; it does not mean every target smoke was executed.

```text
host_collection_types.be
host_import_cache.be
host_libstore_bec.be
host_libstore_cache_errors.be
host_libstore_chunk.be
host_p2ipc.be
host_p2mem_native_cache.be
host_p2smart.be
host_source_modules.be
host_task.be
impcache.be
impchurn.be
intro.be
ismeth.be
p2compvm.be
smoke_all.be
smoke_allocator.be
smoke_app_paths.be
smoke_assignment.be
smoke_be_api_edges.be
smoke_bec_fallback.be
smoke_bec_fallback_min.be
smoke_bec_load_min.be
smoke_bool.be
smoke_bytes.be
smoke_bytes_b64_fixed.be
smoke_bytes_extra.be
smoke_call.be
smoke_class_const.be
smoke_classes.be
smoke_closure.be
smoke_closure_blinker.be
smoke_closure_blinker_descriptor_return.be
smoke_closure_blinker_setup_return.be
smoke_cog_closure.be
smoke_cog_closure_min.be
smoke_cog_descriptor_varargs.be
smoke_cog_ping.be
smoke_cog_policy_min.be
smoke_cog_spawn_source_blinker.be
smoke_cog_spawn_task_blinker.be
smoke_cog_task_source_blinker.be
smoke_collections.be
smoke_compat.be
smoke_compile_module.be
smoke_compiler_parser.be
smoke_compound.be
smoke_cond_expr.be
smoke_configstore.be
smoke_conversions.be
smoke_core.be
smoke_debug.be
smoke_divzero.be
smoke_edge32.be
smoke_edge32_all.be
smoke_errors.be
smoke_example_paths.be
smoke_exception_assert.be
smoke_for_loop.be
smoke_function_capture.be
smoke_global.be
smoke_import_alias.be
smoke_import_all_libs.be
smoke_import_cache.be
smoke_import_churn.be
smoke_import_cwd.be
smoke_import_layout.be
smoke_import_missing.be
smoke_import_native_first.be
smoke_import_order.be
smoke_int_numeric.be
smoke_introspect.be
smoke_introspect_ismethod.be
smoke_json.be
smoke_json_advanced.be
smoke_json_stack.be
smoke_lexer.be
smoke_libraries.be
smoke_libraries_lazy_min.be
smoke_libstore_paths.be
smoke_list_core.be
smoke_map_core.be
smoke_map_keys.be
smoke_math_parity.be
smoke_math_perf_min.be
smoke_member_indirect.be
smoke_module_attrs.be
smoke_module_inventory.be
smoke_module_system.be
smoke_modules.be
smoke_operator_overload.be
smoke_p2_api.be
smoke_p2compat.be
smoke_p2ipc.be
smoke_package_paths.be
smoke_pasm_layout.be
smoke_pasm_policy_min.be
smoke_range.be
smoke_reference.be
smoke_relop.be
smoke_sd.be
smoke_sd_main.be
smoke_sd_min.be
smoke_smartpins_adc_dac_native.be
smoke_smartpins_adc_variant_matrix.be
smoke_smartpins_async_buffer_boundary.be
smoke_smartpins_async_rx.be
smoke_smartpins_counter_modes.be
smoke_smartpins_counter_timer_matrix.be
smoke_smartpins_loopback.be
smoke_smartpins_normal_pin.be
smoke_smartpins_output_modes.be
smoke_smartpins_quadrature_motion.be
smoke_smartpins_quadrature_static.be
smoke_smartpins_sync_diag.be
smoke_solidify.be
smoke_static_classes.be
smoke_static_decls.be
smoke_static_super_member.be
smoke_stdlib.be
smoke_stdlib_min.be
smoke_strict.be
smoke_string.be
smoke_string_format_extra.be
smoke_subobject.be
smoke_suffix.be
smoke_super.be
smoke_syntax.be
smoke_sys.be
smoke_sys_path_add.be
smoke_task.be
smoke_time.be
smoke_vararg.be
smoke_virtual_members.be
smoke_virtual_setmember.be
smoke_vm_cog.be
smoke_vm_cog_once.be
smoke_vm_error_paths.be
smoke_vm_ops.be
smoke_walrus_edges.be
smoke_xmm_gc_stress.be
smoke_xmm_heap.be
```
