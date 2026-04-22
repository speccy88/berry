# Berry on Propeller 2: Porting Status

This note is here so the next porting session can resume quickly.

## Current status

- The P2 build supports both:
  - `P2_SILICON=a` -> `-2a`
  - `P2_SILICON=latest|b|c` -> `-2`
- The Makefile now selects Windows host tools automatically on `Windows_NT`:
  - `tools/flexprop/bin/flexcc.exe`
  - `tools/flexprop/bin/loadp2.exe`
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

## Files most relevant to continue from

- `Makefile`
- `port/p2/main_p2.c`
- `port/p2/berry_conf_p2.h`
- `port/p2/berry_port.c`
- `port/p2/p2_heap.c`
- `src/be_baselib.c`
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
4. Do not rely on `./tools/p2/fetch-flexprop-tools.sh` from PowerShell; that helper is for macOS/Linux bootstrap.
5. Run the current tree on B/C with:
   - `make p2-run P2_SILICON=latest P2_PORT=COM6`
6. Keep the one-connection workflow while testing.
7. Check whether B/C gets past VM startup and reaches:
   - boot chunk execution
   - `print("Berry on P2")`
   - `berry>` prompt
8. If B/C reaches the REPL, verify at least:
   - `print(1+2)`
   - `a=3`
   - `print(a*4)`
9. If B/C still fails, strip the startup trace noise back down and isolate the first failing allocator/VM step there too.
10. Once B/C works, keep the B/C path as the reference port and only then come back to Rev A-specific workarounds.

## Guidance for the next session

When asked to continue porting Berry to P2, start by summarizing:

- where the port currently is
- what was last verified on hardware
- that the next focus is B/C silicon bring-up on Windows PowerShell
- that the next expected board port is `COM6`
- the immediate next command to run: `make p2-run P2_SILICON=latest P2_PORT=COM6`

Then continue from that point instead of restarting the investigation from scratch.
