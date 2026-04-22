<p align="center">
  <h1 align="center">Berry with Propeller 2 Port</h1>
  <p align="center">Berry remains the main project here, with the Propeller 2 port isolated for maintainable upstream sync.</p>
</p>

## Overview

This repository stays clone-first for users who want Berry plus the Propeller 2 port.

- Upstream Berry source layout stays largely intact under `src/`, `default/`, `modules/`, `examples/`, and `tests/`.
- Propeller 2 runtime code, overrides, probes, and status notes now live under `port/p2/`.
- P2 build logic lives under `mk/`.
- Tool bootstrap and loader helpers live under `tools/p2/`.
- Downloaded toolchains belong in `.third_party_cache/` or in user-provided paths, not in git.

The long-term maintenance rule is simple: keep the fork easy to use, while keeping Berry upstream merges manageable.

## Quick Start

Standard Berry host build:

```sh
make
./berry
```

P2 build with FlexC:

```sh
make p2 TOOLCHAIN=flexc
make p2-run TOOLCHAIN=flexc PORT=/dev/ttyUSB0
```

P2 build with Catalina:

```sh
make p2 TOOLCHAIN=catalina
make p2-run TOOLCHAIN=catalina PORT=COM5
```

Windows PowerShell example:

```powershell
make p2 TOOLCHAIN=flexc
make p2-run TOOLCHAIN=flexc PORT=COM6
```

## P2 Toolchain Model

Two P2 compiler flows are supported:

- `TOOLCHAIN=flexc`
- `TOOLCHAIN=catalina`

Path overrides:

```sh
make p2 TOOLCHAIN=flexc FLEXPROP_DIR=/opt/flexprop
make p2 TOOLCHAIN=catalina CATALINA_DIR=/opt/catalina
make p2-run TOOLCHAIN=flexc LOADP2=/opt/flexprop/bin/loadp2 PORT=/dev/ttyUSB0
```

Local managed caches are supported and ignored by git:

- `.third_party_cache/flexprop/`
- `.third_party_cache/catalina/`

## P2 Silicon Selection

The P2 build keeps explicit silicon selection:

- `P2_SILICON=latest` uses `-2`
- `P2_SILICON=b` uses `-2`
- `P2_SILICON=c` uses `-2`
- `P2_SILICON=a` uses `-2a`

Examples:

```sh
make p2 TOOLCHAIN=flexc P2_SILICON=latest
make p2-run TOOLCHAIN=flexc P2_SILICON=a PORT=COM6
```

## Repository Layout

The main P2 areas are:

- [`mk/`](./mk)
- [`port/p2/`](./port/p2)
- [`tools/p2/`](./tools/p2)
- [`docs/P2_BUILD.md`](./docs/P2_BUILD.md)
- [`docs/P2_LAYOUT.md`](./docs/P2_LAYOUT.md)
- [`docs/UPSTREAM_SYNC.md`](./docs/UPSTREAM_SYNC.md)

## Berry

Berry is an ultra-lightweight dynamically typed embedded scripting language designed for constrained systems. The interpreter core is ANSI C99 and uses a one-pass compiler plus a register-based VM.

Reference material:

- [Berry documentation](https://berry.readthedocs.io/)
- [Short manual PDF](https://github.com/berry-lang/berry_doc/blob/master/pdf/berry_short_manual.pdf)
- [`tools/grammar/berry.ebnf`](./tools/grammar/berry.ebnf)

## Host Build

Host build requirements are unchanged:

1. Install a C compiler.
2. Install `readline` on Unix-like hosts if desired.
3. Run:

```sh
make
```

## Notes

- The repo no longer vendors full P2 toolchain distributions.
- `build/` is output-only.
- Optional P2 workaround files that shadow upstream Berry sources now live under `port/p2/patches/optional/` and are documented as maintenance exceptions, not normal source layout.
