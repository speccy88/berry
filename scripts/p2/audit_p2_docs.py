#!/usr/bin/env python3
from pathlib import Path
import sys


REQUIRED_DOCS = [
    "docs/architecture-current.md",
    "docs/source-research.md",
    "docs/coverage-matrix.md",
    "docs/roadmap.md",
    "docs/getting-started.md",
    "docs/building.md",
    "docs/board-support.md",
    "docs/sd-layout.md",
    "docs/psram-loader.md",
    "docs/berry-compatibility.md",
    "docs/p2-api.md",
    "docs/smartpins.md",
    "docs/cogs.md",
    "docs/tasks.md",
    "docs/pasm.md",
    "docs/debugging.md",
    "docs/testing.md",
    "docs/hardware-tests.md",
    "docs/performance.md",
    "docs/limitations.md",
]


def main():
    missing = []
    empty = []
    for name in REQUIRED_DOCS:
        path = Path(name)
        if not path.is_file():
            missing.append(name)
        elif path.stat().st_size == 0:
            empty.append(name)

    for name in missing:
        print(f"error: missing required P2 doc: {name}", file=sys.stderr)
    for name in empty:
        print(f"error: empty required P2 doc: {name}", file=sys.stderr)
    if missing or empty:
        return 1

    print(f"ok: {len(REQUIRED_DOCS)} required P2 docs exist and are non-empty")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
