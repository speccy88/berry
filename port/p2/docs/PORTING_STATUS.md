# Berry on Propeller 2: Porting Status

This note is the handoff for the next P2 porting session.

## Where the Port Is

- The repository layout is now cleaned up so P2 work lives under `port/p2/`, `mk/`, and `tools/p2/`.
- The P2 build interface is now:
  - `make p2 TOOLCHAIN=flexc`
  - `make p2 TOOLCHAIN=catalina`
  - `make p2-run TOOLCHAIN=flexc PORT=...`
  - `make p2-run TOOLCHAIN=catalina PORT=...`
- P2 silicon selection still supports:
  - `P2_SILICON=a` -> `-2a`
  - `P2_SILICON=latest|b|c` -> `-2`
- The next focus should be B/C silicon on Windows PowerShell using `PORT=COM6`.

## What Was Last Verified

On Rev A:

- small serial probes load and run
- small allocator probes load and run
- the Berry image reaches early VM startup
- the last confirmed trace before reset was:
  - `Berry on Propeller 2`
  - `[boot] before vm_new`
  - `[vm] start`
  - `[vm] alloc`
  - `[vm] gc`
  - `[str] grow`
  - `[mem] simple-alloc`

That means the current hard blocker was after serial and loader bring-up, during early VM allocation work.

## Relevant Files

- [`../runtime/main_p2.c`](../runtime/main_p2.c)
- [`../runtime/berry_port.c`](../runtime/berry_port.c)
- [`../runtime/p2_heap.c`](../runtime/p2_heap.c)
- [`../include/berry_conf_p2.h`](../include/berry_conf_p2.h)
- [`../overrides/be_libs_p2.c`](../overrides/be_libs_p2.c)
- [`../../../src/be_mem.c`](../../../src/be_mem.c)
- [`../../../src/be_string.c`](../../../src/be_string.c)
- [`../../../src/be_vm.c`](../../../src/be_vm.c)

## Next Steps

1. Continue on Windows PowerShell.
2. Use B/C or current silicon.
3. Use `PORT=COM6`.
4. Start with:
   - `make p2-run TOOLCHAIN=flexc P2_SILICON=latest PORT=COM6`
5. If FlexC on Windows still needs translation-unit workarounds, compare against:
   - `make p2-run TOOLCHAIN=catalina P2_SILICON=latest PORT=COM6`
6. Aim for the first usable milestone:
   - `print(1+2)`
   - `a=3`
   - `print(a*4)`
7. If Berry still resets before the prompt on B/C, keep tracing focused on the first allocation failure during VM startup.

## What to Say Next Time

When asked to continue porting Berry to P2, start by summarizing:

- where the port currently is
- what was last verified on hardware
- that the next focus is B/C silicon on Windows PowerShell
- that the expected board port is `COM6`
- that the first command to try is `make p2-run TOOLCHAIN=flexc P2_SILICON=latest PORT=COM6`
