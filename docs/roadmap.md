# P2 Roadmap

Date: 2026-06-06

This roadmap preserves the full ambition in `port/p2/goal.md` while keeping implementation honest. Each phase should update `port/p2/TODO.md`, `port/p2/DONE.md`, and `docs/coverage-matrix.md` as work lands.

## Rules for all phases

- Preserve SD-card library storage and lazy loading.
- Do not eagerly load every Berry library into Hub RAM at boot.
- Keep live Berry VM objects in memory that the VM and GC can safely address.
- Use PSRAM for inactive/cache/source/large-buffer tiers unless a profile has proven safe allocator-backed external memory.
- Do not fake APIs. Implemented functions must work, be tested, or raise a clear unsupported error.
- Keep the no-PSRAM P2 Edge Catalina path working while Edge32 and XMM work continues.
- Use Catalina as the normal P2 validation toolchain.

## Phase 1: Baseline and tracking

Goal: keep the current system understandable and prevent accidental regressions.

Current progress:

- `docs/architecture-current.md` now snapshots the current architecture.
- `docs/coverage-matrix.md` now tracks current and missing coverage.
- This roadmap captures the implementation sequence.
- `port/p2/TODO.md` and `port/p2/DONE.md` are the live progress trackers.

Remaining work:

- Create `docs/source-research.md` after inspecting the external Berry, Catalina, P2, smart pin, and uC/OS-II references.
- Run the full scripted SD smoke suite against the provisioned card.
- Record smoke output for `p2.fs_info("/")`, `import math`, and `math.sqrt(81)`.
- Keep documentation current after every feature addition.

Risks:

- Existing docs contain a mix of older status and current status. Prefer the newest handoff and live evidence when they disagree.
- A narrow manual smoke does not prove broad standard-library coverage.

## Phase 2: Berry compatibility and SD filesystem

Goal: make Berry language and library behavior trustworthy on P2.

Work:

- Audit the exact included Berry version and module set.
- Add host tests where possible.
- Add P2 tests for built-ins and standard modules.
- Convert current manual coverage for `string`, `math`, `json`, `bytes`, `file`, `os`, and `os.path` into repeatable tests.
- Document unsupported host-like behavior clearly.
- Make `file`, `os`, and `os.path` consistently map to SD card semantics.

Acceptance evidence:

- Test artifacts prove each listed built-in and module behavior.
- Coverage matrix names unsupported features directly.
- SD file operations include success and error-path coverage.

## Phase 3: SD/PSRAM lazy loader

Goal: preserve the SD-first architecture while adding safe PSRAM-backed cache/storage tiers.

Work:

- Formalize the SD layout under `/berry` and `/modules`.
- Implement `.be` and `.bec` selection rules.
- Prefer valid and newer `.bec` files.
- Fall back to `.be` when compiled cache is missing, invalid, or stale.
- Add compile-to-cache behavior where feasible.
- Track module metadata, hashes, size, cache tier, hits, misses, pinning, and last use.
- Add eviction and low-memory behavior.
- Keep active execution staged in safe VM memory.

Acceptance evidence:

- Tests cover SD import, repeated import, cache hit/miss, stale cache fallback, eviction, and low-memory behavior.
- P2 diagnostics expose module/cache state.
- Edge32 block-cache behavior does not place live GC objects in non-pointer-addressable PSRAM.

## Phase 4: P2 primitive API

Goal: move from useful flat helpers to the clean low-level `p2` API requested in `goal.md`.

Work:

- Add or map `p2.clock`.
- Add or map `p2.cog`.
- Add or map `p2.lock`.
- Add or map `p2.pin`.
- Add or map `p2.cordic`.
- Add or map `p2.math`.
- Add or map `p2.rng`.
- Validate pins, cogs, locks, integer ranges, reserved pins, and unsupported board/build combinations.

Acceptance evidence:

- Each function has P2 tests or clear unsupported behavior.
- No silent stub pretends to work.
- Existing flat helpers remain compatible or are deliberately deprecated with docs.

## Phase 5: Smart pins and high-level hardware

Goal: expose raw smart pin power and friendly wrappers.

Work:

- Research all requested smart pin mode families.
- Add constants and raw smart pin operations.
- Add high-level wrappers for GPIO, PWM, ADC, DAC, timers/counters, UART, SPI/synchronous serial, quadrature, and USB pin pairs where possible.
- Add loopback and hardware wiring docs.

Acceptance evidence:

- Raw smart pin operations are tested.
- Each high-level wrapper has an example and hardware test or a documented skip condition.
- VGA/video and USB are documented honestly until implemented.

## Phase 6: PASM2 integration

Goal: allow safe low-level acceleration without opening unsafe execution by default.

Work:

- Add safe intrinsics.
- Add PASM blob loading.
- Add PASM cog launcher.
- Add PASM function bridge.
- Gate arbitrary assembly behind `BE_P2_ENABLE_UNSAFE_ASM`.
- Document ABI, clobbers, pointers, stack, cleanup, and PSRAM rules.

Acceptance evidence:

- PASM examples run.
- Unsafe paths are disabled unless explicitly enabled.
- Bad inputs fail loudly.

## Phase 7: Multicog Berry and IPC

Goal: implement real multicore Berry execution.

Work:

- Implement `p2.cog.spawn(closure, ...args)` or a proven equivalent.
- Run the child in another cog with a safe VM model.
- Define capture behavior.
- Reject unsafe native pointers and file handles.
- Add handles, join, stop, kill, result, and error propagation.
- Add channels, mailboxes, shared buffers, mutexes, and resource management.

Acceptance evidence:

- A Berry closure or explicitly supported callable runs in another cog.
- Child return values and errors propagate.
- Stress tests prove cleanup.
- Implementation is not a fake worker queue.

## Phase 8: Cooperative tasks and RTOS-inspired primitives

Goal: provide Spin2-shaped cooperative multitasking inside a cog.

Work:

- Harden `taskspin.be` or replace it with a proven VM-safe scheduler.
- Implement 32-slot task semantics where memory allows.
- Add independent stack/coroutine proof.
- Add semaphores, mutexes, queues, event flags, and timers.
- Add host-simulatable tests where possible.

Acceptance evidence:

- Scheduler semantics match `goal.md`.
- Task halt/continue/stop/status behavior is tested.
- All-halted behavior is documented and tested.

## Phase 9: Debug, video, USB, and performance

Goal: make the system observable and broaden Catalina-class hardware support.

Work:

- Create `p2.debug`.
- Report VM, heap, GC, modules, cogs, tasks, pins, smart pins, locks, channels, and memory maps.
- Add debug build flags.
- Add VGA/video demo or staged implementation notes.
- Add USB keyboard/mouse/HID demos or staged implementation notes.
- Create `docs/performance.md`.
- Measure VM speed, import latency, PSRAM cache, GC pauses, cog spawn, task switch, channel latency, smart-pin overhead, native/PASM speedup, SD throughput, and PSRAM throughput.

Acceptance evidence:

- Debug APIs return structured data.
- Performance docs contain measured numbers or clearly marked hooks.
- Unsupported video/USB pieces are not faked.

## Phase 10: Polish and completion audit

Goal: prove the full objective is achieved.

Work:

- Add the full requested examples set.
- Complete user-facing docs.
- Run host, P2, smoke, soak, and benchmark suites.
- Audit `port/p2/TODO.md` to zero open required items.
- Confirm `port/p2/DONE.md` has evidence for every moved item.
- Confirm `docs/coverage-matrix.md` honestly lists no hidden gaps for claimed features.

Completion evidence:

- Firmware builds and boots.
- SD programs and modules load lazily.
- `.be` and `.bec` behavior is proven.
- PSRAM cache/staging behavior is proven safe.
- Full Berry and P2 API coverage is documented, tested, or explicitly unsupported.
- Examples and docs are complete.
- No silent stubs remain.

