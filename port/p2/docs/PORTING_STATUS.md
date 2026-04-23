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

On latest silicon / P2 Edge Rev D with Catalina:

- `make p2-run TOOLCHAIN=catalina PORT=/dev/cu.usbserial-P97cvdxp` loads and reaches the Berry prompt
- startup banner is now a single Berry-style banner instead of the old duplicated `Berry on Propeller 2` / `Berry on P2`
- basic REPL usage is live-verified:
  - `print(1+2)` -> `3`
  - `a=6`
  - `print(a*7)` -> `42`
- the current exposed P2 helpers are live-verified through `prop2_*` globals, including:
  - clock and counter helpers such as `prop2_clock_freq()`, `prop2_ticks()`, `prop2_ticks64()`
  - wait/sleep helpers such as `prop2_wait_ticks()` and `prop2_sleep_ms()`
  - pin helpers such as `prop2_pin_output()`, `prop2_pin_write()`, `prop2_pin_read()`
  - smart-pin helpers such as `prop2_smartpin_write_mode()`, `prop2_smartpin_query()`, `prop2_smartpin_start()`
- REPL input cleanup is improved enough that backspace now sends the normal erase sequence and prompts/newlines are no longer drifting the way they did earlier

Known limitation:

- the Catalina build still uses the simple bump allocator path, so very long REPL sessions will eventually run out of memory and need a reload
- `prop2_ticks64()` currently returns a `"high:low"` string rather than a structured Berry object

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
   - `make p2-run TOOLCHAIN=catalina P2_SILICON=latest PORT=COM6`
5. Re-verify:
   - `print(1+2)`
   - `a=6`
   - `print(a*7)`
   - `print(prop2_clock_freq())`
   - `print(prop2_pin_read(38))`
6. Next engineering focus:
   - replace the bump allocator with a reclaiming allocator that stays stable on latest silicon
   - decide whether `prop2_*` should remain prefixed globals or move into a proper Berry-side namespace/module wrapper
   - continue Windows validation on `COM6`

## What to Say Next Time

When asked to continue porting Berry to P2, start by summarizing:

- where the port currently is
- what was last verified on hardware
- that the next focus is B/C silicon on Windows PowerShell
- that the expected board port is `COM6`
- that the first command to try is `make p2-run TOOLCHAIN=catalina P2_SILICON=latest PORT=COM6`
