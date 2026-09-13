# P2 clock and deadline repair: host-logic milestone

Status: implementation candidate for parent review, not P2 delivery. The native
logic gates below passed. Catalina integration, timing/performance measurements,
and physical P2 HIL remain pending. No serial, flash, PSRAM, or device access was
used by this worker.

## Scope and implementation

The F2 candidate consists of:

- `port/p2/include/p2_clock.h`: explicit clock result and armed-deadline APIs.
- `port/p2/runtime/p2_clock.c`: portable pair arithmetic, deadline operations,
  and the Catalina-only high/low/high sampler.
- `port/p2/overrides/be_tasklib_p2.c`: clock error propagation, checked durations,
  all task wait deadlines, timer expiry/remaining/rearming, and lifecycle state.
- `tests/native/test_p2_clock.c`: execution of production code and real Berry VM.
- `tools/test_p2_clock.py`: Python-stdlib exact oracle, compilation, execution,
  coverage checks, and retained evidence.
- This document and `CHECKPOINT.md`.

The previous implementation attempt supplied the production repair. This repair
attempt corrected and extended its tests, tightened the runner's coverage check
and source hashes, and supplied the missing report. It did not replace or change
the parent's clock architecture or edit any production file outside this scope.

### Exact tick conversion

Catalina's SDK defines `uint64_t` as `unsigned long`, a 32-bit target type.
Production clock math uses neither that typedef nor `long long`; this report
does not infer compiler support or width for other C integer types. `p2_clock_divmod(high, low, divisor, &q, &r)` divides an
explicit pair of 32-bit words. It starts with `r = high % divisor`, shifts in
all 32 low-word bits, and subtracts on either the saved carry or `r >= divisor`.
The quotient is modulo 2^32 and the remainder is exact.

`p2_clock_ticks_to_millis` divides ticks by Hz to obtain modular seconds and the
remainder. It constructs `remainder * 1000` as another pair using 16-bit halves,
divides that pair by Hz, and adds the fractional milliseconds to modular
`seconds * 1000`. Thus the result is exactly `floor(ticks * 1000 / Hz) mod 2^32`,
even for frequencies not divisible by 1000. All wrap in this arithmetic is
intentional unsigned wrap; there is no floating-point or hidden 64-bit C math.

Both division/conversion APIs return success/failure and leave caller outputs
unchanged for a zero divisor/frequency. Result pointers must be valid.

Only under `__CATALINA_P2`, `p2_clock_millis_now(&ms)` includes `<prop2.h>`, reads
`_clockfreq()`, and repeats `_cnth()`, `_cnt()`, `_cnth()` until the two high
samples agree. It rejects zero Hz before reading the counter. There is no global
rollover accumulator or per-caller sampling-history dependency. The scheduler's
`p2_task_millis_now(bvm *vm)` returns `uint32_t` milliseconds or raises
`runtime_error: P2 clock frequency is not configured`. Every caller passes its
VM explicitly. Frequency must represent the counter's configured, stable rate;
runtime frequency changes are not normalized by an epoch/history accumulator.

### Deadline and compatibility rules

- `p2_deadline` stores `uint32_t at_ms` and a separate `armed` flag. Timestamp 0
  is valid, including a positive delay which wraps exactly to zero.
- `p2_deadline_arm` accepts 0 through 2147483647 ms and leaves both fields
  unchanged for invalid larger input. Zero delay is immediately reached.
- Cancel clears `armed`. Reached uses unsigned modular subtraction compared to
  `0x80000000`, never a host-width-dependent cast to `long`.
- A deadline must be observed within the signed half-range after expiry. Modular
  timestamps cannot order points separated by 2^31 ms or more. Remaining time
  is meaningful under that same polling/range contract.
- Event, queue get/put, semaphore, mutex, flags, Timer-object, IPC channel
  send/receive, and IPC mailbox put/get waits all share checked deadline arming.
  Negative/omitted wait timeouts disarm. Existing invalid-input coercion remains:
  negative sleep and negative/noninteger Timer constructor periods become zero.
  Nonnegative integer durations above the half-range are rejected before any
  narrowing, including edited Timer periods on restart/repeat and run idle time.
- Successful readiness still wins over a simultaneous timeout. Waking disarms
  the slot before its callback. Pause/resume (both APIs), done/free, stop/reset,
  slot reuse, and explicit missing/invalid-reference paths clear deadline state.
  Existing broader exception-handling and VM-ownership architecture is unchanged.
- Timer `active` is its armed flag. Remaining time, expiry and both repeat APIs
  use modular arithmetic. Repeating timers remain fixed-delay: consumption at a
  late `now` starts a fresh period at that `now`, not a catch-up schedule.
- Berry timestamp members/results preserve the target's signed 32-bit bit-pattern
  projection (upper-half timestamps appear negative). Internal ordering remains
  unsigned. `lifecycle_result(handle)['deadline_armed']` distinguishes inactive
  deadlines from a live deadline at zero. Diagnostic maps use `['key']`, not
  attribute access; Timer instance members still use attribute access.

## Run the host gates

From the repository root, the unchanged acceptance CLI is:

```sh
python3 tools/test_p2_clock.py --cc gcc
```

The exact independent-verifier interpreter was also exercised successfully:

```sh
/opt/hermes/.venv/bin/python tools/test_p2_clock.py --cc gcc
```

The optional isolated builder uses real GCC, Linux libc and multilib, not
freestanding or fake libc headers. No package downloads are needed:

```sh
python3 tools/test_p2_clock.py --cc gcc --builder local/berry-p2-dev:cat8.8.9 --sanitize
python3 tools/test_p2_clock.py --cc gcc --builder local/berry-p2-dev:cat8.8.9 --abi 32 --sanitize
```

The runner uses `docker run --rm --network none --user 10000:10000 --cap-drop ALL
--security-opt no-new-privileges`, without devices. It mounts the repository
read-only and only its unique `build/p2-clock-*` evidence directory read-write.
The daemon-side default source is
`/DATA/AppData/hopeful_renaud/propeller2/berry`, not Hermes's `/opt/data` path;
use `--docker-host-root` to override it on another installation. The image used
here was `sha256:d5c75a1f7388fa90a312d5b1779408fb04339dde035da6c87277b42d75d443bc`.

Each invocation builds two fresh binaries:

1. Portable: actual `p2_clock.c` and the C driver, with
   `-std=c89 -pedantic-errors -Wall -Wextra -Werror`.
2. Scheduler: actual clock and included task override, linked with byte-identical
   staged Berry core sources and the normal host configuration/port. Test-only
   `prop2.h`/`propeller2.h` declare injected register functions, not substitute
   arithmetic or libc. Host configuration uses host Berry integers, including
   values above the target signed half-range to test rejection before narrowing.

Only the core's generated includes and byte-identical source copies are staged
under `build/`; root `generate/`, configuration, modules, and build rules are not
written. ASan and UBSan use fatal errors, leak detection, and no recovery. The
runner exits nonzero for compilation, execution, numerical, ABI or coverage
failure, or a change to its hashed source inputs. Explicit `--abi 32` failure is
not reported as a passing skip.

### Exercised coverage

Every binary checks 17344 tick pairs against Python big-integer exact quotient,
remainder, and milliseconds, plus 8815 deadline vectors. Seed is `0xF2C10C`.
Cases include:

- 200/240/300 MHz, non-round frequencies, Hz 1 and UINT32_MAX, and zero rejection.
- Full high-word values, extreme low words, 16000 deterministic random tick
  pairs/frequencies, low-counter rollover, millisecond rollover and long times.
- Before/at/after deadlines, the half-range boundary, wrap-to-zero, cancellation,
  invalid arm preserving both prior states, and 100 fixed-delay rearm iterations.
- Three sampler scenarios: zero rejection without register reads, full high word,
  and two torn samples followed by a stable high/low/high sample.
- 67 scheduler scenario groups: 47 wait/timeout scenarios across all listed wait
  kinds (including full queue put); four Timer boundary/repeat groups; twelve
  raw-counter/60-second-repeat groups across 200/240/300 MHz; one simultaneous
  readiness group with four tasks; and three lifecycle/input/error groups.
  Individual groups contain multiple assertions and calls.

The C check totals are 158049 (portable) and 158478 (scheduler); these count C
checks, not every assertion inside the embedded Berry scripts. The scheduler
checks remaining/info/expiry diagnostics, lifecycle cancellation, signed
projections, missing-clock errors, and out-of-range input. IPC objects are test
readiness adapters: this does not validate actual IPC transport or other cogs.

## Recorded RED and GREEN evidence

All paths below are relative to this repository and ignored under `build/`.
The original audit directory was read only, never rerun or overwritten.

Before the first production edits, `python3 build/f2-clock-baseline/capture.py`
captured the then-current source and compiled its two timer helpers verbatim
with GCC C89. The capture process exited 0 after verifying the expected RED:
its probe exited 1, all three controls passed, and all three raw-wrap cases
failed. At 200/240/300 MHz the unreachable deadlines were 21524/17945/14366 ms
while the post-wrap clock returned 69 ms. See `build/f2-clock-baseline/results.json`,
`be_tasklib_p2.before.c`, `probe.c`, and compile/run logs. The saved helper SHA-256
matches the audit helper identity; this is actual pre-fix current-source evidence,
not a rerun against edited helpers.

Repair-start acceptance reproduced the verifier's actual failure (exit 1) in
`build/p2-clock-vy6n8nxs/results.json`: diagnostic map attribute access failed at
`deadline_armed`. Production already emitted that key. The test now uses proper
map indexing. Its wait Timer period also exceeds its separate timeout so that
readiness-first behavior does not invalidate the timeout-only assertion.

Final tested source, each command exit 0 and **2/2 binaries passed**:

- `/opt/hermes/.venv/bin/python tools/test_p2_clock.py --cc gcc`:
  `build/p2-clock-93of1i2x/results.json` (real 64-bit ABI).
- `python3 tools/test_p2_clock.py --cc gcc --builder local/berry-p2-dev:cat8.8.9 --sanitize`:
  `build/p2-clock-4hpkdgl7/results.json` (real 64-bit ABI, ASan/UBSan).
- `python3 tools/test_p2_clock.py --cc gcc --builder local/berry-p2-dev:cat8.8.9 --abi 32 --sanitize`:
  `build/p2-clock-bukq6pj8/results.json` (real 32-bit ABI, ASan/UBSan).

Each results file includes actual counts, source SHA-256 values, executed argv,
return codes and source-preservation status; adjacent logs retain stdout/stderr.
Both sanitized runs had no sanitizer findings. Existing out-of-scope core
warnings remain visible: unused `baselib_trace`, and on `-m32` the solidify
pointer-to-integer cast. They were not suppressed or repaired by this milestone.

An additional deliberately wrong oracle vector was passed to the final portable
binary, which exited 1 with `actual=0 expected=1`; see
`build/f2-clock-repair/mismatch-check.json`. It did not replace the real vectors.
`build/f2-clock-repair/preservation.json` verifies the original RED source/helper
hashes and unchanged protected dirty-file hashes from both saved snapshots
(58 original protected files; 49 repair-start protected files). New concurrent
parent changes to `port/p2/runtime/berry_port.c` and the untracked
`tools/test_p2_console_config.py` appeared during this repair and were left alone.

## Parent integration blocker and pending physical proof

`mk/p2.mk:199` explicitly lists `P2_RUNTIME_SRCS` and does not yet include
`$(P2_RUNTIME_DIR)/p2_clock.c`. The parent must add it before the target link.
This worker did not edit mk/Makefiles or attempt to hide the missing dependency
by including the runtime implementation inside production task code.

After that parent-owned integration, target validation must use the sibling
Catalina install, for example `make p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`.
This report makes no Catalina build or P2 execution claim. Parent follow-up owns
target compilation/link/map/image limits, actual high-word sampling, raw rollover
and long-delay HIL, cancellation/repeat timing, and performance/stack cost. No
assertion of project completion, flash deployment, PSRAM proof, VM isolation or
multicog delivery follows from these host results.
