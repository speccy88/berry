# SD Layout for P2 Berry

## Current working layout

The current P2 runtime configures `/modules` as a default SD import root. This is the live-backed layout today:

```text
/modules/*.be
/tests/p2/*.be
/examples/*.be
```

The SD smoke path provisions `modules/` and `tests/p2/` from the repository to the SD card through the REPL uploader.

## Requested long-term layout

The goal layout is staged as:

```text
/berry/main.be
/berry/lib/*.be
/berry/lib/*.bec
/berry/app/*.be
/berry/app/*.bec
/berry/cache/*.bec
/berry/config/*.json
/berry/examples/*
/berry/pasm/*
```

These paths are documented here so future loader work can converge on one target layout. Not every path is implemented yet.

## Import resolution policy

The intended import order is:

1. Native module first.
2. Current directory or current script context.
3. Configured module paths such as `/modules` and future `/berry/lib`.
4. Future bytecode cache paths when `.bec` support is implemented.

Current verified behavior covers native modules and `/modules/*.be` lazy source imports. `.bec` freshness, fallback, and compile-to-cache behavior remain open.

## Config files

JSON config files should live under `/berry/config/*.json` once that directory is part of the deployed SD layout. Until then examples use safe fallbacks when `/berry/config` is absent.
