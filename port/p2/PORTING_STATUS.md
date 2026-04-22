# Berry on Propeller 2: Porting Status

This note is here so the next porting session can resume quickly.

## Current status

- The P2 build supports both:
  - `P2_SILICON=a` -> `-2a`
  - `P2_SILICON=latest|b|c` -> `-2`
- The Makefile now selects Windows host tools automatically on `Windows_NT`:
  - `tools/flexprop/bin/flexcc.exe`
  - `tools/flexprop/bin/loadp2.exe`
- The Windows-host `make p2` / `make p2-run` flow no longer depends on POSIX `mkdir -p` or `[ ... ]` shell syntax.
- `p2` now fails early through `p2-tools` if the repo-local FlexProp executables are missing.
- The P2 build now supports both compiler paths:
  - `P2_COMPILER=flexc`
  - `P2_COMPILER=catalina`
- Catalina is staged locally under `tools/catalina/` and now builds and loads on Windows with:
  - `make p2-run P2_COMPILER=catalina P2_PORT=COM6`
- Windows FlexC 7.6.6 currently crashes on some full Berry translation units near EOF.
- The P2 build now works around that by using P2-only split copies for:
  - `be_api`
  - `be_baselib`
  - `be_class`
- Serial bring-up is working through the dedicated smart-pin backend in `port/p2/berry_port.c`.
- `make p2-run P2_SILICON=a P2_PORT=/dev/cu.usbserial-P2EEQZ7` is the right one-connection workflow for Rev A.
- The host-side FlexC crash from the earlier precompiled-object attempt is gone.
- The port is using a reduced precompiled builtin path intended for bring-up.

## What was verified on Rev A

- Small serial probe programs load and run.
- Small allocator probe programs load and run.
- The Berry image now loads and reaches VM startup.
- The last confirmed startup trace on Rev A is:
  - `Berry on Propeller 2`
  - `[boot] before vm_new`
  - `[vm] start`
  - `[vm] alloc`
  - `[vm] gc`
  - `[str] grow`
  - `[mem] simple-alloc`
- After that, the program resets and repeats.

## Current conclusion

The remaining blocker on Rev A is below normal Berry REPL logic. The failure happens during the very first dynamic allocation path used by VM/string-table initialization. Serial and loading are no longer the primary blockers.

This now looks more like a Rev A toolchain/runtime/codegen issue than a plain Berry language-port issue.

For current Windows B/C bring-up, there is also a host-side toolchain issue:

- `flexcc.exe` on Windows is crashing on some Berry `.c` files even before hardware loading.
- The current workaround is to split offending end-of-file functions into P2-only translation units under `port/p2/`.
- FlexC remains available, but Catalina is now the working Windows path for full builds.

## Files most relevant to continue from

- `Makefile`
- `port/p2/main_p2.c`
- `port/p2/berry_conf_p2.h`
- `port/p2/berry_port.c`
- `port/p2/p2_heap.c`
- `port/p2/be_api_p2.c`
- `port/p2/be_baselib_p2.c`
- `port/p2/be_class_p2.c`
- `src/be_baselib.c`
- `src/be_code.c`
- `src/be_mem.c`
- `src/be_string.c`
- `src/be_vm.c`

## Next steps

Focus next on B/C silicon, not Rev A.

1. Continue on Windows PowerShell.
2. Use B/C or current silicon on `COM6`.
3. Before running, make sure Windows has:
   - Git for Windows
   - Python 3
   - GNU Make
   - `tools/flexprop/bin/*.exe`
   - `tools/flexprop/include`
4. The old host-tool installation blocker is resolved if `tools/flexprop/bin` contains at least:
   - `flexcc.exe`
   - `loadp2.exe`
5. The recommended Windows build path is now Catalina:
   - `make p2-run P2_COMPILER=catalina P2_PORT=COM6`
6. FlexC is still available for comparison and debugging:
   - `make p2-run P2_COMPILER=flexc P2_PORT=COM6`
7. If continuing FlexC-specific work, use the current workaround pattern on Windows:
   - identify the crashing file
   - confirm it compiles when the last function or conditional tail is cut off
   - move that tail into a small `port/p2/*_p2.c` companion file
   - point `P2_SRCS` at the split P2 copy
8. Do not rely on `./tools/p2/fetch-flexprop-tools.sh` from PowerShell; that helper is for macOS/Linux bootstrap.
9. Run the current tree on B/C with:
   - `make p2-run P2_COMPILER=catalina P2_SILICON=latest P2_PORT=COM6`
10. Keep the one-connection workflow while testing.
11. Check whether B/C gets past VM startup and reaches:
   - boot chunk execution
   - `print("Berry on P2")`
   - `berry>` prompt
12. If B/C reaches the REPL, verify at least:
   - `print(1+2)`
   - `a=3`
   - `print(a*4)`
13. If B/C still fails, strip the startup trace noise back down and isolate the first failing allocator/VM step there too.
14. Once B/C works, keep the B/C path as the reference port and only then come back to Rev A-specific workarounds.

## Guidance for the next session

When asked to continue porting Berry to P2, start by summarizing:

- where the port currently is
- what was last verified on hardware
- that the next focus is B/C silicon bring-up on Windows PowerShell
- that the next expected board port is `COM6`
- the immediate next command to run: `make p2-run P2_SILICON=latest P2_PORT=COM6`

Then continue from that point instead of restarting the investigation from scratch.
