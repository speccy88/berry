# Propeller 2 Port Status

This is the canonical current support summary. Begin with
[Getting Started](getting-started.md), use the [P2 API](p2-api.md) for names,
arguments/results and errors, and keep historical porting evidence separate.
This page does not declare the whole port or standard library complete.

## Current validation path

- Linux/x86-64, including the existing container; pinned Catalina 8.8.9 commit
  `a6f714c539f749c5fc80fa2179f6193622d39c0c`. See [build details](P2_BUILD.md).
- Identified P2 Edge with 32 MiB PSRAM; production LARGE/XMM profile,
  `make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina`.
- Volatile loading is sufficient. Flash installation is optional and requires
  verified board identity, private backup and recovery procedure.
- Console `/dev/ttyUSB0`, 230400 baud, one exclusive serial owner. USB serial
  identity is checked by the bench harness; the port name alone is not identity.
- Lower 16 MiB PSRAM window: Catalina XMM code/data/heap; upper 16 MiB:
  explicit block/cache use. Exception frames use explicit VM-owned Hub storage.
- The no-PSRAM Edge uses the separate COMPACT profile, `-lcx`, no `-lpsram`.
  Never apply PSRAM board pin assignments or XMM size limits to that profile.

## Supported interactive foundation

- Arithmetic/expression printing; multiline `def` and loops; ordinary Berry
  syntax/runtime exceptions returning to a usable prompt.
- Ctrl-C at empty, edited, continuation or running Berry bytecode returns to a
  fresh prompt with the same VM/global state. Already executed effects remain.
  Native-call polling latency is not a hard real-time cancellation guarantee.
- Explicit Ctrl-D/EOF behavior, including abandoning pending source. See the
  [single recovery contract](getting-started.md#functions-loops-and-recovery).
- `p2.help()` discovers live groups; `p2.help("pin")` discovers live members.
  Help returns metadata maps and reuses existing capability reporters; it does
  not drive pins, open buses or access storage. Bad types/topics raise normal
  Berry errors. See [discovery conventions](p2-api.md#discovery-and-conventions).
- Grouped hardware APIs are the preferred example style. Flat aliases remain
  compatible. Status/introspection examples need neither wiring nor an SD card.
- The [interactive example](../examples/p2/interactive.be) and
  [help smoke](../tests/p2/smoke_interactive_help.be) are executable, not transcripts
  pasted into replacement firmware.

## Experimental and unavailable

- **Unavailable:** production concurrent independent Berry VMs, arbitrary closure
  transfer across cogs, and public source-cog execution. Inspect
  `p2.cog.capabilities()["spawn_source"]` rather than assuming that registration
  or an internal diagnostic means support. Coherent source producer/reaper work
  is deferred, not completed or abandoned by this increment.
- **Experimental:** internal child-VM/cog diagnostics, interim native cog handles,
  exact PASM fixtures and PSRAM block/cache tooling. No new concurrency guarantee
  follows from single-VM interactive testing.
- **Unavailable in normal builds:** arbitrary PASM/inline assembly, cross-cog IPC,
  USB/VGA support and calibrated analog/timer claims beyond their reported
  capabilities. Query the relevant capability map and read its policy/reason.
- `.bec` import is ABI-gated; explicit source fallback remains important.
- SD-backed files and optional source libraries are separate workflows. They are
  not requirements for help or the first-prompt walkthrough. This increment does
  not claim complete standard-library coverage or retest every peripheral.

## Verification scopes

`python3 tools/test_repl.py --sanitize` executes the actual production REPL,
P2 editor/interrupt slice and help implementation with real host Berry VMs.
Its UART byte inputs and metadata fixture modules are **native unit tests**, not
board output. It checks reader/free ownership, continuation EOF, cancellation,
stack balance, global preservation, errors and help validation under ASan/UBSan.

The maintained VM-state, exception-storage, source-worker and language gates
remain required. Real hardware acceptance uses the normal production entry
point, source/image/loader hashes, an exclusive serial lease and raw UART bytes.
Clean Catalina compilation and local CI-body runs are build/host evidence, not
GitHub Actions or HIL. Remote Actions status must be read from the actual run.

For other hardware, read [testing](testing.md) and [wiring](hardware-tests.md)
before invoking a smoke target: some targets provision SD or drive wired pins.

## Historical material and deeper references

- [Architecture](architecture-current.md), [coverage details](coverage-matrix.md)
  and [build profiles](P2_BUILD.md) retain the broader port context.
- [TODO](../port/p2/TODO.md) is a work tracker, not a product support promise.
- [DONE](../port/p2/DONE.md) and old release/handoff captures are historical
  evidence tied to their images, boards and toolchains. Earlier warnings about
  `try` / `except` or line-start `for`, macOS-only/container restrictions, image
  sizes and flash boot timings are not current onboarding instructions.
