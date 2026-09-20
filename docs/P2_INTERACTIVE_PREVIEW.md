# P2 interactive preview — accepted 2026-09-20

**Status: accepted single-VM, RAM-only interactive preview.** This closes the
interactive milestone, not the entire Propeller 2 port. No flash writes were
performed for this acceptance, and production public multicog execution remains
unavailable.

Start with [Getting Started](getting-started.md). The
[port status](P2_PORT_STATUS.md) remains the support summary; the
[P2 API](p2-api.md) owns signatures and error conventions. The
[interactive example](../examples/p2/interactive.be) needs no SD card or external
wiring. Berry retains its own syntax; this is not a Python interpreter.

## What was accepted

- Expression results, multiline functions and loops, and a usable prompt after
  ordinary syntax/runtime errors.
- Ctrl-C during editing, continuation or Berry bytecode execution, preserving
  the current VM and existing globals. Completed side effects are not rolled
  back; long native calls can delay interrupt polling.
- Ctrl-D on an empty input line, including continuation, exits the interpreter.
  The production entry point prints `[Berry interpreter exited]` and waits for
  explicit reset/reload rather than returning into startup. Ctrl-D on edited
  nonempty input is ignored; during running bytecode it retains the legacy
  interrupt behavior. See the [recovery contract](getting-started.md#functions-loops-and-recovery).
- Read-only `p2.help()` and topic help, with live group/member discovery and
  normal Berry errors for invalid arguments. Grouped APIs are preferred; flat
  aliases remain compatible.
- Consistent onboarding, API documentation and executable examples, plus the
  empty-map/GC sanitizer repairs and safe CI evidence export.

## Accepted revisions and artifact

- Interactive implementation:
  [`93f17c8`](https://github.com/speccy88/berry/commit/93f17c8c34687455543d0f9eeb6a3692b46fbd54).
- CI-only evidence-export follow-up:
  [`6876481`](https://github.com/speccy88/berry/commit/6876481357c7e35759d4dea03443b07d29c585a1).
- Target: identified P2 Edge with 32 MiB PSRAM, production Catalina LARGE/XMM
  profile on Linux/x86-64. Catalina 8.8.9 SDK commit:
  `a6f714c539f749c5fc80fa2179f6193622d39c0c`.
- Tested RAM application: `berry_p2.binary`, **1230976 bytes**.
- Image SHA-256:
  `d22f2f602fa46b0d033e443df26d91ab5a23e581fb01ecce5c215056d8f954f2`.

The separately distributed handoff archive is
`berry-p2-interactive-93f17c8.zip`, SHA-256
`052724ab1c5bf30835c62343cef4593020080271635d0452521152d982bccfab`.
It contains the tested image, instructions, example, actual UART walkthrough and
hash manifest; it contains no private flash backup or credentials. This page
does not announce a GitHub Release asset. Follow the [build guide](P2_BUILD.md)
when building from a checkout, and do not expect a fresh build's timestamped
binary to have the same hash as this preserved artifact.

The accepted build predates the implementation commit: production input hashes
were reconciled with the accepted code rather than inferred from its base Git
HEAD. A later change to the native-only terminal-exit test fixture was separately
verified; that fixture is not compiled into the P2 image. The CI follow-up changes
workflow/tooling/tests, not the board-tested runtime. Documentation closeout does
not constitute another hardware run.

## Verification record

These are distinct scopes, not interchangeable claims:

- **Actual board:** 125 checked UART steps in the full interactive walkthrough
  and two in the separate top-level EOF run: **127 steps passed**, not 127
  independent test programs. They
  cover the documented first session, help, multiline input, errors, globals
  surviving recovery, and Ctrl-C/Ctrl-D behavior. Both EOF runs observed three
  seconds after the exit marker without restart output. A separate two-case
  arithmetic/help readiness load passed and left the normal prompt available.
- **Host:** production REPL/editor/help/entry-point fixtures and the maintained
  native regression groups passed. An independent terminal-exit regression
  stress run passed 50 repetitions. Host UART inputs and fixture modules are
  unit-test data, not board output. See [testing](testing.md).
- **Tooling:** 31 combined build/export tests passed normally and with Python
  optimization. The collector test compared all 207 exported files byte-for-byte
  using distinct writer/collector UIDs and an unrelated-owned output parent;
  original private evidence permissions remained unchanged.
- **Remote CI at `6876481`:** all four jobs passed in
  [run 35543007587](https://github.com/speccy88/berry/actions/runs/35543007587):
  host language/P2 scripts, native sanitizer regressions, 32-bit native
  regressions, and real P2 compilation. All four nonempty evidence artifacts
  uploaded. This proves host/build behavior, **not hardware execution**.

Hardware acceptance retained exact source/image/loader identities, the exclusive
serial lease, raw received UART bytes and verifier receipts. Negative controls
rejected incomplete, echo-only, mismatched and otherwise invalid evidence; host
completion text alone was not accepted as device proof. The handoff walkthrough
contains actual received output, not a synthesized demonstration. The complete
bench records were retained separately; they are not installed by cloning this
repository. The dated CI link above remains the acceptance record for that
revision, not an assertion about every future commit.

## Deliberately outside this milestone

- Full standard-library coverage and a larger set of practical peripheral tools
  and examples. Passing the first session does not validate every API or board.
- Flash installation, cold boot, saved-program persistence, restore/recovery
  execution and complete measured resource budgets. RAM loading is volatile;
  reset or power loss does not make this preview a persistent installation.
- Safe public independent-VM/multicog lifecycle, shared-service ownership,
  cancellation/orphan cleanup and cross-VM isolation. Internal diagnostic cog
  tests do not establish production concurrency. `task` remains cooperative
  work in the current VM.

Historical no-PSRAM, peripheral and flash results remain tied to their own
images and wiring. Do not transfer this XMM acceptance to those profiles. Keep
one serial owner, respect reserved memory/console pins, and require verified
private backup and recovery controls before any future flash write.
