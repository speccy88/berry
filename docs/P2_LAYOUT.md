# P2 Layout

## Why the P2 Port Is Isolated

This fork keeps Berry itself as close to upstream layout as practical, while isolating Propeller 2 work in predictable places.

- `src/`, `default/`, `modules/`, `examples/`, and `tests/` remain the upstream-facing Berry areas.
- `port/p2/` contains the P2 runtime, configuration, probe programs, overrides, and port-specific status notes.
- `mk/` contains the P2 build fragments so the root `Makefile` stays thin.
- `tools/p2/` contains bootstrap and loader helpers instead of checked-in compiler distributions.

That structure keeps upstream merges easier to review because P2 changes are concentrated instead of scattered.

## Directory Map

```text
berry/
├── mk/
├── port/p2/
│   ├── include/
│   ├── runtime/
│   ├── overrides/
│   ├── patches/
│   ├── docs/
│   └── tests/
├── tools/p2/
│   ├── bootstrap/
│   └── loader/
├── scripts/
├── docs/
└── build/
```

## Migration Note

What moved:

- P2 runtime files moved from `port/p2/*.c` into `port/p2/runtime/`.
- P2 headers moved into `port/p2/include/`.
- P2 overrides moved into `port/p2/overrides/`.
- P2 probe programs moved into `port/p2/tests/`.
- P2 status docs moved into `port/p2/docs/`.
- P2 shadow-copy workaround files moved into `port/p2/patches/optional/`.
- P2 build logic moved out of the root `Makefile` into `mk/*.mk`.
- Tool bootstrap and loader helpers moved under `tools/p2/bootstrap/` and `tools/p2/loader/`.

What was deleted from source control:

- checked-in host binaries in `bin/`
- checked-in build outputs in `build/`
- vendored FlexProp drop under `tools/flexprop/`
- vendored Catalina distribution under `tools/catalina/`
- checked-in top-level `berry` executable

What still needs manual follow-up:

- validate the cleaned `TOOLCHAIN=catalina` path on real Windows hardware
- validate bootstrap flows against the exact FlexProp and Catalina distributions you plan to use
- continue Berry runtime bring-up on B/C silicon
