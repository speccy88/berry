# SD Layout for P2 Berry

## Current working layout

The current P2 runtime configures `/modules`, `/berry/lib`, and `/berry/app`
as lazy SD source import roots. `/modules` remains first for compatibility with
the known-good deployed layout, while `/berry/lib` and `/berry/app` stage the
long-term layout without eager-loading libraries into Hub RAM. The
`/tests/p2/smoke_import_order.be` smoke stages the same module name in all three
roots and verifies `/modules` still wins.

```text
/berry/main.be
/modules/*.be
/berry/lib/*.be
/berry/app/*.be
/tests/p2/*.be
/examples/*.be
```

If `/berry/main.be` exists, the P2 startup path attempts to run it once after
the VM is created and before entering the REPL. Missing `/berry/main.be` is
treated as normal and falls through to `berry>` with no error. A script error
prints a warning and still falls through to the REPL; `os.exit()` keeps the
existing clean exit behavior.

The SD smoke path provisions `modules/` and `tests/p2/` from the repository to the SD card through the REPL uploader.

The long-form `/berry/...` layout is provisioned separately so ordinary smoke
syncs stay conservative:

```sh
make p2-sd-berry-dirs PORT=/dev/cu.usbserial-P97cvdxp
make p2-sd-berry-lib PORT=/dev/cu.usbserial-P97cvdxp
make p2-sd-berry-examples PORT=/dev/cu.usbserial-P97cvdxp
make p2-sd-berry-sync PORT=/dev/cu.usbserial-P97cvdxp
```

`p2-sd-berry-dirs` creates the empty `/berry/cache`, `/berry/config`, and
`/berry/pasm` directories without uploading placeholder files.

`modules/configstore.be` provides a small JSON helper for `/berry/config`:

```berry
import configstore
configstore.save("app", {"enabled": true})
print(configstore.load("app", {})["enabled"])
print(configstore.list())
```

Config names are file names, not paths. The helper appends `.json` when needed,
preserves an existing `.json` suffix, rejects path separators, and stores files
under `/berry/config`.

## Requested long-term layout

The goal layout is staged as:

```text
/berry/main.be
/berry/lib/*.be
/berry/lib/*.bec
/berry/app/*.be
/berry/app/*.bec
/berry/cache/*.bec
/berry/config/*.json
/berry/examples/*
/berry/pasm/*
```

These paths are documented here so future loader work can converge on one target layout. Not every path is implemented yet.

## Import resolution policy

The intended import order is:

1. Native module first.
2. Current directory or current script context.
3. Configured module paths such as `/modules` and future `/berry/lib`.
4. Future bytecode cache paths when `.bec` support is implemented.

Current verified behavior covers native modules and `/modules/*.be` lazy source imports. Source-level smoke coverage now exists for native-module-first precedence, current-directory SD imports, `/berry/main.be`, `/berry/lib/*.be`, `/berry/app/*.be`, and `/berry/config/*.json`; hardware execution of that expanded smoke remains part of the next full P2 SD smoke run. `.bec` path detection and deterministic size/hash metadata are staged through `libstore.compiled_path(name)` and `libstore.compiled_stats(name)`. `.bec` sidecar freshness manifests are now staged as `<module>.bec.json`, but `.bec` execution and compile-to-cache emission remain open. Until then, `.be` source is the explicit fallback.

`libstore.path_add(path)`, `libstore.path_remove(path)`, and
`libstore.path_list()` configure the SD source paths used by `libstore`
diagnostics/cache/loading. `libstore.path_add(path)` also appends the path to
the VM import roots through `sys.path_add(path)` when available, while
`path_remove()` remains local to `libstore` because native path removal and
reordering do not have safe bare-metal semantics yet.

`libstore` also resolves dotted module names to nested SD paths for its own
diagnostics/cache/loading helpers. For example, `libstore.load("pkg.mod")`
looks for `pkg/mod.be` under the configured source roots. The native importer
uses the same nested filesystem lookup for string imports such as
`import "pkg.mod" as mod` and bare dotted imports such as `import pkg.mod`.
Bare dotted imports bind the last segment by default, so `import pkg.mod`
stores the loaded module in variable `mod`; use `as alias` when a different
binding name is clearer.

`libstore.resolve(name)` reports the selected load path and reason. Today `.bec`
files are detected and hashed but unsupported for execution. When source,
bytecode, and a matching `<module>.bec.json` sidecar are present,
`libstore.compiled_freshness(name)` can report `fresh == true` and
`comparable == true`. Default firmware still reports `usable == false` with
reason `compiled_execution_unavailable`; opt-in loader builds are reported
through `p2.status_info()["build"]["bytecode_loader"]` and
`libstore.compiled_execution_probe()`. `libstore.compiled_validation(name)`
separates fresh sidecar metadata from the default-off safe bytecode
execution policy. A matching `.be` source file remains selected with reason
`compiled_unsupported_source_fallback` unless the opt-in loader build,
freshness check, and `BE_P2_ENABLE_BYTECODE_EXECUTION` policy make the staged
bytecode usable.
`libstore.compiled_load_plan(name)` and `libstore.load_compiled(name)` expose
the future `.bec` execution hook explicitly; default builds raise
`unsupported_error` with the plan reason instead of silently executing or
silently falling back.
`libstore.compiled_status(name)` bundles the staged bytecode freshness,
validation, load, and emit state for tooling that needs one diagnostics map.
`libstore.compiled_status_text(name)` exports the same bundle as JSON text for
scripts that need to persist or compare diagnostics.
`libstore.compiled_inventory()` and `libstore.compiled_inventory_text()` expose
the same diagnostics across every discovered SD module.
`libstore.compiled_summary()` and `libstore.compiled_summary_text()` expose
aggregate readiness counts plus load/emit blocker-reason histograms for scripts
and provisioning checks.
`libstore.compiled_loadable()`, `libstore.compiled_emittable()`, and
`libstore.compiled_blocked()` expose filtered candidate lists for future
provisioning tools.
Their `_text()` companions export those candidate lists as JSON text.
`libstore.compiled_provision_plan()` and
`libstore.compiled_provision_plan_text()` package summary, candidates, blocked
state, and a conservative recommendation into one diagnostics object.

`libstore.compile_cache_plan(name)` reports the intended `.be` to `.bec` cache
target path plus source/compiled metadata. Default firmware keeps `can_emit`
`false` with reason `bytecode_emit_unavailable`; opt-in builds can enable the
writer with `BE_P2_ENABLE_BYTECODE_SAVER`, and `libstore.compile_cache_emit(name)`
writes the `.bec` plus sidecar manifest only when that saver is present.
`libstore.compile_cache_plan_many()`, `compile_cache_plan_all()`,
`compile_cache_plan_many_text()`, `compile_cache_plan_all_text()`,
`compile_cache_emit_many()`, and `compile_cache_emit_all()` provide explicit
bulk planning/emission helpers and dry-run JSON exports for future
provisioning. They are never invoked by default import resolution.
Bulk planning includes blocker-reason histograms so provisioning scripts can
distinguish missing sources from unavailable bytecode saver support.
`compile_cache_provision_plan()` and its `_text()` / `_all()` variants package
bulk dry-run emit state and conservative recommendations for provisioning tools.
`compile_cache_emittable()` / `compile_cache_blocked()` and their `_all()`
variants expose filtered dry-run emit candidates without writing cache files.
Their `_text()` companions export the dry-run candidate filters as JSON text.

`libstore.app_path(name)`, `libstore.app_exists(name)`, and
`libstore.run_app(name)` provide explicit `/berry/app` source application
helpers. They run `.be` application files lazily from SD and return `nil` when
an app is absent.

`libstore.example_path(name)`, `libstore.example_exists(name)`, and
`libstore.run_example(name)` provide the same source-file helper pattern for
`.be` examples under `/berry/examples`.

`libstore.pasm_path(name)`, `libstore.pasm_exists(name)`, and
`libstore.pasm_info(name)` detect staged `/berry/pasm/*.bin` files without
executing them. PASM launching remains a later unsafe/ABI-gated feature.

## Config files

JSON config files should live under `/berry/config/*.json` once that directory is part of the deployed SD layout. Until then examples use safe fallbacks when `/berry/config` is absent.
