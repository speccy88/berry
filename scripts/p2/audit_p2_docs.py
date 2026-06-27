#!/usr/bin/env python3
from pathlib import Path
import re
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

AMBIGUOUS_PRIORITY_SHORTHAND = re.compile(r"\b[Pp]([013456789])\b")
TRACKING_DOCS = [
    "port/p2/TODO.md",
    "port/p2/DONE.md",
]


def main():
    missing = []
    empty = []
    ambiguous = []
    for name in REQUIRED_DOCS:
        path = Path(name)
        if not path.is_file():
            missing.append(name)
        elif path.stat().st_size == 0:
            empty.append(name)

    for name in REQUIRED_DOCS + TRACKING_DOCS:
        path = Path(name)
        if not path.is_file():
            continue
        for lineno, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            match = AMBIGUOUS_PRIORITY_SHORTHAND.search(line)
            if match:
                ambiguous.append((name, lineno, match.group(0), line.strip()))

    for name in missing:
        print(f"error: missing required P2 doc: {name}", file=sys.stderr)
    for name in empty:
        print(f"error: empty required P2 doc: {name}", file=sys.stderr)
    for name, lineno, shorthand, line in ambiguous:
        print(
            f"error: ambiguous priority shorthand {shorthand!r} in P2 doc: {name}:{lineno}: {line}",
            file=sys.stderr,
        )
    if missing or empty or ambiguous:
        return 1

    print(
        f"ok: {len(REQUIRED_DOCS)} required P2 docs exist and are non-empty; "
        "no ambiguous compact non-P2 priority shorthand in active P2 docs"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
