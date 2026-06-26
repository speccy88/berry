#!/usr/bin/env python3
from pathlib import Path
import re
import sys


SEARCH_ROOTS = [
    "AGENTS.md",
    "README.md",
    "docs",
    "mk",
    "scripts",
    "tools/p2",
    "Makefile",
    ".github",
    "port/p2/TODO.md",
]

FORBIDDEN = [
    ("CATALINA_USE_DOCKER", re.compile(r"CATALINA_USE_DOCKER")),
    ("Docker Catalina reference", re.compile(r"\bdocker\b", re.IGNORECASE)),
    (".third_party_cache/catalina", re.compile(r"\.third_party_cache/catalina")),
    ("CATALINA_DIR=.third_party_cache", re.compile(r"CATALINA_DIR\s*=\s*\.third_party_cache")),
    ("/opt/catalina", re.compile(r"/opt/catalina")),
    ("catalina-speccy88", re.compile(r"catalina-speccy88")),
]

SKIP_SUFFIXES = {
    ".pyc",
    ".png",
    ".jpg",
    ".jpeg",
    ".gif",
    ".bin",
    ".binary",
    ".o",
    ".a",
}


def iter_files():
    self_path = Path(__file__).resolve()
    for root_name in SEARCH_ROOTS:
        root = Path(root_name)
        if not root.exists():
            continue
        if root.is_file():
            if root.resolve() != self_path:
                yield root
            continue
        for path in sorted(root.rglob("*")):
            if (
                path.is_file()
                and path.resolve() != self_path
                and path.suffix.lower() not in SKIP_SUFFIXES
            ):
                yield path


def main():
    problems = []
    for path in iter_files():
        text = path.read_text(encoding="utf-8", errors="replace")
        for lineno, line in enumerate(text.splitlines(), 1):
            for label, pattern in FORBIDDEN:
                if pattern.search(line):
                    problems.append((path, lineno, label, line.strip()))

    for path, lineno, label, line in problems:
        print(f"{path}:{lineno}: forbidden {label}: {line}", file=sys.stderr)
    if problems:
        return 1

    print("ok: active P2 docs/tooling use sibling Catalina path and no Docker Catalina references")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
