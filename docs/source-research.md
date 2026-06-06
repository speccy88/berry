# P2 Source Research

Date: 2026-06-06

Scope: research notes for the Berry-on-Propeller-2 roadmap in `port/p2/goal.md`.

Primary references:

- [Berry reference manual](https://berry.readthedocs.io/en/latest/source/en/Reference.html)
- [Berry libraries and modules](https://berry.readthedocs.io/en/latest/source/en/Chapter-7.html)
- [Berry advanced features](https://berry.readthedocs.io/en/latest/source/en/Chapter-8.html)
- [Berry FFI example](https://berry.readthedocs.io/en/latest/source/en/FFI-Example.html)
- [Berry memory requirements](https://berry.readthedocs.io/en/latest/source/en/Memory-Requirements.html)
- [Catalina `prop2.h` at requested commit](https://github.com/rosshigson/Catalina/blob/339ee1df83b4639cf8c1d71c6ace9757587afd75/include/prop2.h)
- [Parallax Propeller 2 hardware manual](https://docs.alexrp.com/propeller/propeller_2_arch.pdf)
- [Parallax Propeller 2 datasheet](https://www.mouser.com/datasheet/2/321/Propeller2_P2X8C4M64P_Datasheet_20210709-3006917.pdf)
- [P2 smart pin online documentation](https://p2docs.github.io/pin.html)
- [uC/OS-II repository](https://github.com/weston-embedded/uC-OS2)

This note is implementation guidance, not proof that any feature is implemented. Implementation status belongs in `docs/coverage-matrix.md`, `port/p2/TODO.md`, and `port/p2/DONE.md`.

## Berry language and VM implications

Berry is designed as a compact embedded scripting language with a compiler and register-based virtual machine. The reference manual explicitly frames Berry around microcontrollers and small-memory systems, not desktop assumptions.

Implementation implications for P2:

- Keep the VM small and avoid eager loading.
- Preserve upstream semantics before adding P2-specific acceleration.
- Treat optional libraries and expansion modules as deployable features that can live outside the core firmware image.
- Use the register-VM model as the starting point for optimization; do not add complex P2 acceleration before measurement.
- Keep the compiler available where possible because `.be` source loading, `.bec` generation, and cache invalidation depend on it.

## Berry built-ins, libraries, and modules

Berry Chapter 7 identifies the basic library and expansion modules that the P2 port must audit. Relevant categories include:

- Built-in functions: `print`, `input`, `classname`, `classof`, `str`, `number`, `int`, `real`, `bool`, `type`, `size`, `super`, `assert`, `compile`, `module`, `issubclass`, `isinstance`, and `call`.
- Basic classes: `list`, `map`, `file`, `range`, and `bytes`.
- Expansion modules: `json`, `math`, `time`, `string`, `os`, `os.path`, `global`, `introspect`, and `solidify`.

Implementation implications for P2:

- Each built-in and module needs a P2 coverage row and a test path.
- `file`, `os`, and `os.path` must be SD-card filesystem APIs on bare metal.
- Host-like behaviors such as process execution, desktop environment assumptions, or unsupported time/filesystem semantics must be documented and should raise clear unsupported errors instead of pretending to work.
- `bytes` is important as the safe bridge type for binary hardware buffers, SPI/UART transfers, PASM blobs, and PSRAM cache chunks.

## Berry import, packages, and cache behavior

Berry Chapter 8 describes import behavior that matters directly for the SD/PSRAM loader:

- Imports use a global module cache. If a module was already imported, the cached value is returned.
- Import search order starts with native modules embedded in firmware.
- Filesystem search starts at the current directory and continues through `sys.path`.
- File lookup includes raw name, compiled bytecode `.bec`, and source `.be`.
- Loaded code executes and should return the object exported by the module.
- If the returned object is a module with an `init` member, that `init` is called once during first import and its return value replaces the cached value.

Implementation implications for P2:

- The requested native-module-first, current-directory, `sys.path`, `.bec`, `.be`, and global-cache behavior matches upstream Berry and should be treated as compatibility-critical.
- SD-backed lazy import should wrap or extend Berry's existing import behavior, not replace it with unrelated semantics.
- `.bec` support should validate freshness and correctness before source fallback.
- Repeated import/cache tests are mandatory because upstream Berry's module cache semantics are observable behavior.
- PSRAM source or bytecode cache entries must not bypass `init` semantics or mutate the global module cache incorrectly.

## Berry solidification and compiled artifacts

Berry solidification captures compiled structures and code into C/firmware objects to reduce runtime memory use. The solidify module is not compiled by default and has size cost. It can dump functions, classes, and modules.

Implementation implications for P2:

- Solidification can reduce Hub RAM/flash pressure for stable core libraries, but it conflicts with the goal of keeping broad libraries SD-card resident and lazy.
- Use solidification selectively for minimal boot-critical or hardware-critical modules.
- Keep SD-loaded `.be` and `.bec` paths as first-class runtime behavior.
- If `solidify` is exposed to Berry users on P2, document its memory cost and output-file expectations.

## Berry FFI/native function model

Berry native functions interact with the VM through a stack-based C API. Arguments are read by stack index, values are type-checked with `be_is*` helpers, return values are pushed, and native functions return with `be_return` or `be_return_nil`.

Implementation implications for P2:

- Every native hardware binding must validate argument count, type, integer range, pin range, cog range, lock range, and board-specific reserved pins.
- Native functions should return Berry-native structures such as maps, lists, bytes, bools, ints, or strings instead of exposing unsafe C pointers.
- `be_pushcomptr` or equivalent pointer bridges should be treated as unsafe unless ownership, lifetime, cog affinity, and transfer rules are fully documented.
- Native functions should raise clear errors for unsupported build/board combinations.

## Berry memory requirements

Berry's documented memory requirements are small by desktop standards: extreme RAM around 4 KB, low around 8 KB, and recommended RAM at least 16 KB; ROM/flash guidance is 64 KB extreme, 128 KB low, and 256 KB recommended.

Implementation implications for P2:

- The P2 has enough RAM for serious Berry work, but the current Hub image is near the 512 KiB image limit, so module placement still matters.
- The memory problem is not just "can Berry run"; it is "can full Berry plus P2 hardware modules, SD loader, caches, docs/examples/tests, and multicog support fit cleanly."
- Keep active VM heap and GC-managed objects in safe memory.
- Use SD and PSRAM to avoid bloating Hub RAM with inactive modules.

## Catalina P2 API surface

Catalina's `prop2.h` provides a useful C/PASM-facing P2 primitive map. Relevant APIs include:

- Clock/system: `_hubset`, `_clkset`, `_clockfreq`, `_clockmode`.
- Cogs: `_cognew`, `_cogstart_PASM`, `_cogstart_C`, `_cogstop`, `_cogchk`, `_cogid`.
- Locks and attention: `_locknew`, `_lockret`, `_locktry`, `_lockrel`, `_lockchk`, `_cogatn`, `_pollatn`, `_waitatn`.
- CORDIC/math/random: `_rotxy`, `_polxy`, `_xypol`, `_rnd`, `_rev`, `_encod`, `_isqrt`, `_muldiv64`.
- Counter/wait: `_cnt`, `_cnth`, `_cnthl`, `_waitcnt`, `_waitx`, `_waitus`, `_waitms`, `_waitsec`.
- Pins: `_dirl`, `_dirh`, `_pinw`, `_pinl`, `_pinh`, `_pinnot`, `_pinrnd`, `_pinf`, `_pinr`.
- Smart pins: `_wrpin`, `_wxpin`, `_wypin`, `_akpin`, `_rdpin`, `_rqpin`, `_pinstart`, `_pinclear`.

Implementation implications for P2:

- The requested `p2.clock`, `p2.cog`, `p2.lock`, `p2.pin`, `p2.smart`, `p2.cordic`, `p2.math`, and `p2.rng` APIs can map cleanly to Catalina primitives.
- Catalina naming is not the final Berry API. Keep Berry user-facing names idiomatic and grouped, while using Catalina underneath.
- `_cogstart_C` is especially relevant for child VM experiments, but Berry closure transfer needs explicit serialization/copy/sharing rules.
- `_cogstart_PASM` and `_cognew` are relevant for the PASM blob launcher and unsafe assembly bridge.

## Propeller 2 architecture

The P2 has eight cogs. Each cog can run independently and simultaneously, while sharing Hub RAM, locks, I/O pins, the system counter, and the CORDIC solver. Each cog has its own Register RAM and Lookup RAM, and the chip has 512 KB of shared Hub RAM.

Key hardware facts for this project:

- There are 64 I/O pins with digital, analog, and smart-pin capabilities.
- Each cog can access all I/O pins; final pin state is collective and needs coordination.
- Hub RAM access is time-sliced/multiplexed among cogs.
- Hub RAM is byte/word/long addressable and can be executed from in hub-exec modes.
- Cogs can communicate through Hub RAM, locks, cog attention, Lookup RAM mechanisms, and external I/O.
- The Hub provides CORDIC math services.

Implementation implications for P2:

- Real multicog Berry work should use actual cogs, not host-style worker queues.
- Shared state must be explicit and lock/channel protected.
- Hub RAM is the natural place for live shared VM metadata and IPC structures.
- Cog RAM/LUT RAM are optimization targets for hot runtime or PASM routines, not a first-pass requirement.
- CORDIC-backed math helpers should expose P2 acceleration where it is correct and measurable.

## Smart pins

The P2 smart pin system covers a large set of autonomous pin modes. The hardware manual lists families including normal pin mode, repository, DAC modes, pulse/transition output, NCO output, PWM, quadrature, counters/timers, ADC internal/external/scope modes, USB pair mode, synchronous serial TX/RX, and asynchronous serial TX/RX.

The P2 online smart-pin documentation is useful for wrapper design, but some entries are incomplete or marked TODO. Cross-check final implementation against the Parallax hardware manual and tested hardware behavior.

Implementation implications for P2:

- Raw smart pin functions should expose `WRPIN`, `WXPIN`, `WYPIN`, `AKPIN`, `RDPIN`, `RQPIN`, start, and clear semantics.
- High-level wrappers must compute mode/X/Y values safely and document pin pairing, adjacent-pin, baud, sample-period, and board-reservation constraints.
- PWM wrappers need period/frame/duty validation.
- ADC wrappers need sampling/filter-mode validation and clear voltage-scaling assumptions.
- USB wrappers must enforce even/odd pin pairs and host/device/full-speed/low-speed constraints.
- Serial wrappers should expose async TX/RX baud/word-size behavior but avoid promising complete UART buffering until tested.

## PASM2 and unsafe execution

The P2 hardware manual focuses hardware examples on PASM2. Catalina exposes PASM cog-start helpers and direct P2 primitives. PASM is powerful but unsafe when arbitrary user code can run with direct hub, cog, pin, and clock access.

Implementation implications for P2:

- Safe native intrinsics should be separated from arbitrary PASM execution.
- PASM blob launching must define argument passing, return values, hub pointers, PSRAM pointers, clobbers, stack/cog RAM/LUT RAM use, and cleanup.
- Arbitrary assembly compilation/execution should stay behind `BE_P2_ENABLE_UNSAFE_ASM`.
- PASM examples should include small, bounded, hardware-visible tests before generalizing into a function bridge.

## uC/OS-II inspiration

uC/OS-II is a preemptive, portable real-time kernel. Its source tree includes classic RTOS primitives such as semaphores, queues, mutexes, and event flags. The semaphore implementation shows patterns worth studying: event control blocks, counted resources, accept/non-blocking behavior, pend with timeout, deletion rules, ISR restrictions, scheduler interaction, and explicit error codes.

Implementation implications for P2:

- Use uC/OS-II as conceptual inspiration, not copied code.
- Berry `task` primitives should expose clear object lifetimes, wait semantics, timeouts, error states, and debug visibility.
- The current Berry task goal is cooperative inside a cog, not a preemptive RTOS. Do not import preemption assumptions unless the VM/runtime can support them safely.
- Semaphores, mutexes, queues, event flags, and timers should have deterministic cleanup and should not hide blocking behavior.
- ISR/cog-attention interactions must be explicit because Berry VM execution and GC are not safe in arbitrary interrupt contexts unless proven.

## Research-driven implementation priorities

1. Preserve upstream Berry import/cache semantics before adding P2-specific cache tiers.
2. Finish repeatable tests for currently verified SD and standard-library behavior.
3. Implement `.bec` support and cache freshness using Berry's documented import expectations.
4. Map Catalina `prop2.h` primitives into grouped Berry APIs with strong validation.
5. Treat smart pins as two layers: raw register-level access first, friendly wrappers second.
6. Keep live VM objects out of COMPACT Edge32 block PSRAM.
7. Use XMM as the current allocator-backed external-memory experiment, while preserving explicit block-cache windows.
8. Make multicog execution real, but define value transfer and sharing rules before accepting closures.
9. Keep unsafe PASM explicitly gated and documented.
10. Keep coverage honest: unsupported or untested features belong in `TODO.md` and `docs/coverage-matrix.md`, not behind silent stubs.

