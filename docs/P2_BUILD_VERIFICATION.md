# Berry/P2 Linux build and CI candidate verification

## Scope and status

This is a bounded tooling candidate, not whole-project completion or delivery.
The wrapper compiles the real standard Berry runtime for LARGE/XMM `p2edge32`.
Host execution, P2 compilation and unperformed hardware-in-the-loop (HIL) are
separate claims. No remote GitHub Actions run has been verified.

Changed source-controlled candidate paths:

- `tools/build_p2.py`
- `tools/tests/test_build_p2.py`
- `.github/workflows/c-cpp.yml`
- `tools/container/README.md`
- `docs/P2_BUILD_VERIFICATION.md`

`CHECKPOINT.md` and `build/` evidence are temporary/ignored. Parent-owned runtime,
Makefiles, SDK bootstrap script and Dockerfile were not edited. No Git commit or
push, active SDK/container mutation, hardware, serial, flash, PSRAM operation,
external-service write, credentials or controller changes were performed.

## Environment and evidence root

Local executions below ran on 2026-09-13 UTC. Evidence root, abbreviated `E` below:

`/opt/data/propeller2/berry/build/build-ci-candidate-retry`

- Original source HEAD: `4c5241c6fc065e3036cff9545bf8608f54319b42`.
- Original working tree: dirty, including parent untracked runtime and test files.
  Exact status is in target `result.json` and `logs/source-status.log`.
- Builder: existing `local/berry-p2-dev:cat8.8.9`, Linux/amd64.
- Image ID: `sha256:d5c75a1f7388fa90a312d5b1779408fb04339dde035da6c87277b42d75d443bc`.
- Catalina: public `v8.8.9`, commit
  `a6f714c539f749c5fc80fa2179f6193622d39c0c`.
- Read-only source mount: daemon-host
  `/DATA/AppData/hopeful_renaud/propeller2/berry` to `/repo`.
  This mapping was read from `docker inspect propeller2`, not guessed.
- Containers ran foreground, UID/GID `10000:10000`, `--cap-drop ALL`,
  `--security-opt no-new-privileges`, without devices, socket or credentials.
  Host jobs had `--network none`; the fresh SDK target job had `--network bridge`.

The local workflow reproduction reused the parent's existing image rather than
rebuilding/retagging it. The Actions workflow builds the same parent-owned pinned
Dockerfile on ordinary isolated GitHub runners. Debian's base digest and SDK
commit are pinned; apt package versions are not snapshot-pinned.

## TDD and wrapper verification

Executed from `/opt/data/propeller2/berry`:

```sh
/opt/hermes/.venv/bin/python -m unittest discover \
  -s tools/tests -p test_build_p2.py
```

- `E/unit-before.log`: 22 tests, one failure exposing a missing JSON fixture.
- `E/tdd-red.log`: 24 tests, three failures, before fixes for the fixture,
  symlinked source-directory ancestors and overwritten SDK command logs.
- `E/tdd-green.log`: all 24 tests pass after those fixes.
- `E/git-readonly-red.log`: added an assertion that Git optional writes are
  disabled; it failed before adding `GIT_OPTIONAL_LOCKS=0`.
- `E/unit-final.log`: all 24 tests pass with that assertion intact.

Tests cover required arguments, unsupported hosts, path/source/SDK overlap and
unsafe paths, occupied outputs, offline missing/unprepared SDKs, SDK commit and
receipt/tool hash mismatches, bootstrap/library-patch/command/compiler failures,
missing/empty/undersized/oversized/stale images, symlink escapes, exact source
copying (including untracked sources and JSON data), original configuration
isolation, mid-build source changes, environment isolation and distinct command
logs. A real subprocess test verifies stderr and exit 23 retention. Fake compiler
subprocesses in unit tests are explicitly seams, not target compilation proof.

## Reproduced workflow jobs

The temporary local driver reads actual `run` blocks from the workflow, writes
exact shell scripts, runs them with Bash `-euo pipefail`, and records exit codes.
It substitutes only the already-provisioned image, Docker daemon/client bind-path
difference and matrix values. It does not alter or suppress any test command.
These were executed independently in foreground containers:

```sh
/opt/hermes/.venv/bin/python build/build-ci-candidate-retry/reproduce_workflow.py host
/opt/hermes/.venv/bin/python build/build-ci-candidate-retry/reproduce_workflow.py native
/opt/hermes/.venv/bin/python build/build-ci-candidate-retry/reproduce_workflow.py 32
/opt/hermes/.venv/bin/python build/build-ci-candidate-retry/reproduce_workflow.py target
```

For each mode, `E/workflow-MODE.sh` preserves the exact shell block,
`E/workflow-MODE-execution.log` preserves combined output, and
`E/workflow-MODE-receipt.json` preserves command environment, image identity and
exit status. Evidence output directories are intentionally single-use; use a new
output root for another reproduction, rather than deleting/overwriting receipts.

Host language/P2 job: exit 0, Clang 19 with fatal ASan/UBSan and leak detection.

- Wrapper unit tests in the builder: 24 passed.
- `make test`: 58 language tests passed, zero failures. This includes
  `checkspace.be`, `map.be`, `lexer.be`, `module.be`, `class.be` and `walrus.be`.
- `make test-p2-host`: all 10 current `tests/p2/host_*.be` scripts passed,
  including the new collection-types regression.
- Exact output: `E/workflow-host/berry-host/host.log`.
- The JSON fixture omission found in the previous attempt was a wrapper copy bug,
  not a reason to disable `json.be`. The fixture is now copied and that test passes.
- lcov/genhtml HTML reporting was not installed; the upstream runner prints that
  optional coverage-report skip. Language tests and ASan/UBSan were actually run.

Native jobs: both exit 1, intentionally retaining the real failure described below.
Clang 19 ran the native ABI; GCC with actual multilib/libc ran `--abi 32` / `-m32`.
ASan/UBSan were fatal in both. Per ABI:

- P2 allocator: 124/124 cases passed across its four build configurations.
- Clock: 2/2 host binaries passed.
- Default VM-state (`bint=64`, small pools enabled): 9/9 cases passed.
- VM-state (`--bint 32 --no-small-pools`): 5/9 cases passed; job remains failed.
- Exception-vector allocator routing with the complete Berry VM, plus Hub heap
  locking logic with host shims: passed. These commands run even after the failed
  VM-state diagnostic; the aggregate exit status remains nonzero.

Full native receipts are under:

- `E/workflow-native/berry-native/source/build/*/results.json`
- `E/workflow-32/berry-native/source/build/*/results.json`

The exact invocations are in the workflow and `E/workflow-{native,32}.sh`.
Every native suite also has its own compile/run logs beside its receipt.

## Concrete parent-owned blocker (not repaired here)

The no-small-pools diagnostic reproduces the existing allocator defect documented
in `docs/P2_VM_STATE_TESTING.md`. Both ABIs fail `scheduler_isolation`,
`scheduler_gc`, `rng_boundaries` and `scheduler_reset` under ASan. The 32-bit
`scheduler_gc` trace reports a four-byte write immediately after an eight-byte
allocation, in `be_vector_push` (`src/be_vector.c:69`), allocated through
`malloc_from_pool` / `be_realloc` (`src/be_mem.c:286` / `:191`).

Exact current failure evidence:

- `E/workflow-32/berry-native/source/build/p2-vm-state-rv1xn8hv/scheduler_gc.log`
- `E/workflow-32/berry-native/source/build/p2-vm-state-rv1xn8hv/results.json`
- `E/workflow-native/berry-native/source/build/p2-vm-state-jzkw833u/results.json`

This is not an unsupported-host skip or a wrapper failure. Runtime repair belongs
to the parent. The workflow has no `continue-on-error`, expected-failure wrapper
or test deletion. A green whole-CI claim is blocked until the parent repairs and
independently re-verifies this defect. Successful target compilation does not
waive it.

## Clean target build proof

The workflow target job ran this required entrypoint with nonexistent SDK
`/tmp/Catalina` and read-only original source:

```sh
python3 tools/build_p2.py --sdk-dir /tmp/Catalina --output-dir /proof
```

The wrapper first used the unchanged pinned SDK bootstrap script and then ran:

```sh
bash /proof/source/tools/p2/bootstrap/patch-catalina-p2.sh \
  /tmp/Catalina P2_EDGE LARGE cx direct
make p2 TOOLCHAIN=catalina CATALINA_DIR=/tmp/Catalina \
  P2_PROFILE=xmm P2_BOARD=p2edge32 CATALINA_PLATFORM=P2_EDGE \
  CATALINA_MODEL=LARGE CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram \
  P2_LOCAL_CONFIG=/dev/null PYTHON=/usr/bin/python3 V=1
```

The required repository P2 SDK library patch is essential: the host bootstrap
alone leaves unresolved SD diagnostic symbols. Neither SDK bootstrap nor this
library preparation accesses SD/serial/PSRAM hardware. The real Make target uses
the current standard runtime, including parent-added clock, VM-state, Hub heap
and exception-storage sources. No parent Make rule or runtime source was edited.

First clean proof in this retry, exit 0:

- Receipt: `E/workflow-target/berry-target/proof/result.json`.
- Image: `E/workflow-target/berry-target/proof/source/build/p2/catalina/xmm/berry_p2.binary`.
- Bytes: `1209184` (greater than 64 KiB, within the 16 MiB XMM gate).
- SHA-256: `f8d96f48f96cf4028c56440b8f660535a12619b079c5fd8ea675d2815bd6e829`.
- Recorded build start/end: `2026-09-13T04:16:44.005999+00:00` /
  `2026-09-13T04:17:59.486505+00:00`.
- `source_inputs_unchanged=true`; 419 actual copied input hashes were recorded.
- SDK commit and source HEAD match the identities above.
- Independent local rehash of the actual image, every command log and every
  copied input passed; receipt: `E/image-independent-check.json`.

Logs under that proof directory include `logs/sdk-bootstrap.log`,
`logs/sdk-components.log`, `logs/sdk-patch.log`, `logs/target-build.log` and
`source/build/p2/catalina/xmm/p2_build.log`. The `.bin`, `.binary`, generated
profile header, build-info header and configuration stamp are retained. The
current normal Make target emits compiler section-size diagnostics, not a
standalone linker map; no map or target execution result is invented.

The image embeds a build date/time via `scripts/gen-p2-build-info.py` (unchanged),
so separate successful builds can have different SHA-256 values. This evidence
proves a pinned, repeatable build procedure and the specific bytes produced, not
bit-for-bit determinism. This first target proof preceded the final read-only Git
environment assertion and the new documentation; input hashes describe exactly
what was copied at that time, not a later source snapshot.

### Final wrapper and real offline-path recheck

After the final wrapper change and container README were present, executed:

```sh
bash -euo pipefail build/build-ci-candidate-retry/final-target.sh
```

Exact foreground Docker commands are in `E/final-target.sh`; combined output is
`E/final-target-execution.log`. The shell command exited 0 after checking all
three real paths (no unit subprocess substitutes):

- A nonexistent SDK with `--offline` in a `--network none` container exited 2,
  wrote a failed receipt and never invoked bootstrap. Receipt:
  `E/final-target/missing-proof/result.json`.
- A new container with nonexistent `/tmp/Catalina`, network for the public clone,
  read-only `/repo` and writable `/proof` ran the exact required entrypoint.
  Receipt: `E/final-target/proof/result.json`; status success.
  Image: `E/final-target/proof/source/build/p2/catalina/xmm/berry_p2.binary`.
  Bytes: `1209184`; SHA-256:
  `e8b0a20eaf9d278e78f138f3d4f208ee6226ef58149ae25248c9d8f0e160663e`.
  Start/end: `2026-09-13T04:26:46.473294+00:00` /
  `2026-09-13T04:28:01.888853+00:00`.
- The same container then reused its owned SDK with `--offline` and a separate
  empty `/offline-proof`. Receipt: `E/final-target/offline-proof/result.json`;
  status success, no bootstrap command. Its freshly built image was also
  `1209184` bytes, SHA-256
  `b04a4d71b9c696050c46d65c9ae09931ff7e71903794aa0f7ca4d366e473c5d9`.
  This prepared-SDK run retained the container's bridge network; the wrapper's
  recorded command list proves bootstrap was not called. The missing-SDK case
  above separately exercised the enforced network-none boundary.

Both successful final receipts have 420 input hashes, the required pinned SDK
commit and original source HEAD, `source_inputs_unchanged=true`, and
`GIT_OPTIONAL_LOCKS=0`. Independent local rehashes of both images, every command
log and every copied input passed. Exact results and resolved local image paths:
`E/final-image-independent-check.json`. Timestamp-dependent hash differences are
expected, not silently treated as reproducible bytes. Parent-input preservation
was also checked against `E/parent-inputs-before.json`: no changes to the recorded
588 non-secret, non-owned repository files.

## CI security and independent acceptance

Push and pull-request checks have explicit `contents: read`; checkout uses
`persist-credentials: false`. Host and native jobs are network-isolated; the
compile job uses only a public SDK clone. All use the pinned parent Dockerfile,
no self-hosted/device runner, no deployment and no privileged container.
Artifacts retain logs on failure. Native suite aggregation executes all suites
but exits nonzero for any failure. Unsupported environments are errors.

Real upstream action refs were queried locally, not invented:

```sh
git ls-remote https://github.com/actions/checkout.git refs/tags/v4.2.2
# 11bd71901bbe5b1630ceea73d27597364c9af683 refs/tags/v4.2.2
git ls-remote https://github.com/actions/upload-artifact.git refs/tags/v4.6.2
# ea165f8d65b6e75b540449e92b4886f43607fa02 refs/tags/v4.6.2
```

The independent parent-owned build gate is not edited or represented as having
run here. It must execute separately after this candidate exits, alongside the
unit command. No remote Actions run, HIL, boot/flash recovery, actual PSRAM size,
SD diagnostic behavior, hardware scheduler timing or parallel-VM proof is claimed.
