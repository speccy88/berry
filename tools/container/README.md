# Linux/x86-64 Berry/P2 builder (compile only)

This environment is for host regression tests and Catalina target compilation,
not target execution. It is not a TinyGo/LLVM migration. Clang 19 is a host test
compiler; Catalina compiles the P2 image.

The parent-owned `Dockerfile` pins Debian's base-image digest and installs GCC,
real 32-bit multilib/libc, Clang 19, ASan/UBSan runtimes, bison/flex, Boost,
Python 3 and Git. Debian package versions are not snapshot-pinned. The separate
parent-owned `tools/bootstrap_catalina.py` pins public Catalina `v8.8.9` to
`a6f714c539f749c5fc80fa2179f6193622d39c0c` and applies the Linux host patch.

On an independent CI/development host, build the environment with:

```sh
docker build --platform linux/amd64 -t berry-p2-ci \
  -f tools/container/Dockerfile tools/container
```

In the current workspace the parent has already provisioned
`local/berry-p2-dev:cat8.8.9`. Use that existing image; do not rebuild, replace
or retag it, or alter the primary `propeller2` container. The locally verified
image ID is recorded in [the verification report](../../docs/P2_BUILD_VERIFICATION.md).

## Entrypoint

From the original Git checkout on Linux/x86-64:

```sh
python3 tools/build_p2.py --sdk-dir /tmp/Catalina --output-dir /proof
```

`--sdk-dir` must be a separate, owned SDK path. A nonexistent directory is
source-bootstrapped automatically. Existing checkouts must have the pinned HEAD;
the bootstrap receipt, host-patch hash and executable hashes are checked. An
unprepared pinned SDK can be bootstrapped unless `--offline` is set. Do not point
this wrapper at the parent's active `/work/propeller2/Catalina`: SDK preparation
writes into the SDK. A prepared SDK is not immutable either, because the required
repository P2 library patch runs before every target build (its own stamp may
make that operation a no-op).

```sh
python3 tools/build_p2.py --sdk-dir /tmp/Catalina \
  --output-dir /another-empty-proof --offline
```

Offline means no SDK bootstrap or fetch, even for a present-but-unprepared SDK.
P2 library preparation and compilation still run. Use `--network none` as an
additional container boundary when reusing a separately provisioned SDK.

The wrapper always runs the real `make p2` target with `TOOLCHAIN=catalina`,
`P2_PROFILE=xmm`, `P2_BOARD=p2edge32`, `CATALINA_MODEL=LARGE`, `-lcx` and `-lpsram`.
These are compile-time settings, not PSRAM or device access. It neither runs a
loader nor falls back to a stub/minimal runtime. The SDK library preparation is
`tools/p2/bootstrap/patch-catalina-p2.sh SDK P2_EDGE LARGE cx direct`;
 omitting it leaves unresolved SD diagnostic symbols.

## Container boundaries and paths

Mount the original checkout read-only at `/repo` and an empty writable evidence
directory at `/proof`. Run as UID/GID `10000:10000`, with capabilities dropped
and `no-new-privileges`. The source repository must retain readable Git metadata
so its actual HEAD can be recorded, but no credentials should be mounted.
Only the public SDK clone requires network access. Never map serial/USB devices,
the Docker socket or credentials, and never use privileged mode or a device
runner. All example commands are foreground and compile-only.

Docker bind sources are daemon-host paths, not necessarily client paths. In the
current workspace, verified with `docker inspect propeller2 --format '{{json .Mounts}}'`:

- Client repository: `/opt/data/propeller2/berry`.
- Daemon repository: `/DATA/AppData/hopeful_renaud/propeller2/berry`.
- Existing primary-container parent mount: `/work/propeller2`.

Exact locally executed Docker commands are retained under
`build/build-ci-candidate-retry/workflow-*.sh`; the verification report gives
reproduction details. On ordinary GitHub runners the client and daemon workspace
paths coincide; `.github/workflows/c-cpp.yml` uses that layout explicitly.

## Isolation and receipts

The output directory must be new or empty; failure never overwrites an old
successful receipt. Berry source files are copied, not linked, to `/proof/source`.
All configuration headers (including `../generate`), objects and images are
created there. Neither `.p2.local.mk` nor inherited Make/compiler/Git settings
can override the fixed build profile. Git's optional index refresh is disabled.

The positive input boundary is declared in `INPUT_TREES`, `INPUT_FILES` and
`INPUT_SUFFIXES` in `tools/build_p2.py`. It includes current tracked and untracked
source, runtime files, generators and host tests, including the JSON test fixture.
It excludes original build/generated files, `.git`, hidden state, caches,
SDK directories, private-key formats, named secrets/credentials and unrelated
root directories. Source symlinks are rejected, including symlink ancestors.
This is not a generic workspace backup: extend the boundary deliberately when
adding a new build-input directory or fixture format. Do not keep secrets in
ordinary source files; filenames cannot classify arbitrary sensitive content.

`result.json` records commands and exit statuses, logs with SHA-256, source HEAD
and dirty status, exact copied-input hashes, SDK identity/tool/library hashes,
profile command and, only on verified success, image path/size/SHA-256. Source
hashes and HEAD are checked again after compilation. Images must be fresh regular
files with `64 KiB < size <= 16 MiB`; the repository Make target also enforces its
XMM size gate. A failed compiler cannot publish a successful image receipt even
if it leaves a binary behind. Bootstrap component logs are copied into the output
before an ephemeral SDK disappears.

Unsupported hosts, unsafe Make pathnames, missing prerequisites and failed tests
are errors, never successful skips. Python 3.9+ is required (`Path.is_relative_to`);
the tested Docker environment supplies Python 3.13. Paths used by Make/Catalina
must contain only letters, digits, `/`, `.`, `_`, `+` and `-`.

## CI and limitations

The push/PR workflow has explicit `contents: read`, checkout credential
persistence disabled, separate host and target jobs, and failure-time log
artifacts. It executes the full language suite, all `tests/p2/host_*.be` scripts,
allocator/clock/VM-state/exception-storage regressions on native and real 32-bit
host ABIs, and a fresh-SDK target build. It never deploys or runs HIL.

The no-small-pools VM-state diagnostic currently exposes an out-of-scope runtime
allocator defect and intentionally keeps the native CI jobs red. The other
native suites are still executed and logged; no failure is suppressed. See the
verification report for exact passing and failing results. A successful compile
is not proof of runtime safety, PSRAM capacity, boot, parallel VMs or hardware.
The build embeds a wall-clock timestamp, so this is a reproducible procedure and
pinned SDK, not a claim of byte-for-byte deterministic firmware or OS packages.
