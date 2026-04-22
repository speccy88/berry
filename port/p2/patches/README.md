# P2 Optional Patches

These files are maintenance exceptions.

They are not the preferred long-term design. They exist to isolate temporary or host-specific workarounds, especially for compiler issues that affect only one toolchain or one host environment.

Current use:

- `optional/` contains shadow-copy or split-tail workarounds that were previously mixed into the main `port/p2/` directory.
- The default goal is to shrink this set over time, not expand it.

Before promoting any file here into a permanent override, prefer:

1. using upstream Berry sources unchanged,
2. adding a small P2-only override under `port/p2/overrides/`,
3. documenting why the drift is still necessary.
