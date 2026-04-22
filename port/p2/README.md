# Berry on Propeller 2

This fork is trying to make Berry run interactively on real Propeller 2 boards
using FlexProp/FlexC.

## Exact objective

1. Build a P2 image from this repository with `make p2`.
2. Load that image to board RAM with `loadp2`.
3. Reach a stable, usable Berry REPL over serial (`print(1+2)`, assignments, loops).
4. Keep the port minimal and explicit:
   - RAM-only execution
   - no host filesystem/dlopen/readline assumptions
   - clean separation of P2-specific code under `port/p2`

## Current state

- The P2 build target works and emits `build/berry_p2.binary`.
- Berry startup text can be reached.
- Main blocker is reliable sustained serial interaction after startup.

Build:

```sh
make p2
```

Load to RAM:

```sh
./bin/loadp2.mac -p /dev/cu.usbserial-P2EEQZ7 build/berry_p2.binary -t
```

Tool bootstrap (this repo is self-contained for tool setup):

```sh
./tools/p2/fetch-flexprop-tools.sh
```

Serial console notes:

- Default FlexProp terminal/stdio path
- `115200 8N1` is a sensible starting point for external terminals

Expected startup:

- `Berry on Propeller 2`
- `Berry on P2`
- `berry> `

Current scope:

- RAM-only load/run
- Serial REPL over stdin/stdout
- No readline, dynamic libraries, or host filesystem support
