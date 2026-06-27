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
    "port/p2/docs/README.md",
    "port/p2/docs/PORTING_STATUS.md",
]

SKIP_PATHS = {
    "docs/P2_TODO.md",
}

SKIP_PARTS = {
    "releases",
}

FORBIDDEN = [
    ("CATALINA_USE_DOCKER", re.compile(r"CATALINA_USE_DOCKER")),
    ("Docker Catalina reference", re.compile(r"\bdocker\b", re.IGNORECASE)),
    (".third_party_cache/catalina", re.compile(r"\.third_party_cache/catalina")),
    ("CATALINA_DIR=.third_party_cache", re.compile(r"CATALINA_DIR\s*=\s*\.third_party_cache")),
    ("/opt/catalina", re.compile(r"/opt/catalina")),
    ("catalina-speccy88", re.compile(r"catalina-speccy88")),
    ("old macOS serial port", re.compile(r"/dev/cu\.usbserial-P97cvdxp")),
]

CATALINA_MAKE_COMMAND = re.compile(
    r"(^|[`'\"]|\s)(make|\$\(MAKE\))\s+[^\n]*TOOLCHAIN=catalina"
)
P2_PORT_USAGE = re.compile(r"usage:\s+make\s+[^\n]*PORT=/dev/ttyUSB0")
P2_MAKE_PORT_COMMAND = re.compile(r"(^|[`'\"]|\s)make\s+[^\n]*PORT=/dev/ttyUSB0")

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
                and path.as_posix() not in SKIP_PATHS
                and not any(part in SKIP_PARTS for part in path.parts)
            ):
                yield path


def logical_lines(text):
    start_lineno = 1
    current = ""
    for lineno, line in enumerate(text.splitlines(), 1):
        stripped = line.rstrip()
        if current:
            current += " " + stripped.rstrip("\\").strip()
        else:
            start_lineno = lineno
            current = stripped.rstrip("\\").strip()
        if stripped.endswith("\\"):
            continue
        yield start_lineno, current
        current = ""
    if current:
        yield start_lineno, current


def main():
    problems = []
    for path in iter_files():
        text = path.read_text(encoding="utf-8", errors="replace")
        for lineno, line in enumerate(text.splitlines(), 1):
            for label, pattern in FORBIDDEN:
                if pattern.search(line):
                    problems.append((path, lineno, label, line.strip()))
        for lineno, line in logical_lines(text):
            if CATALINA_MAKE_COMMAND.search(line) and "CATALINA_DIR=" not in line:
                problems.append((
                    path,
                    lineno,
                    "Catalina make command without CATALINA_DIR",
                    line.strip(),
                ))
            if P2_PORT_USAGE.search(line) and "CATALINA_DIR=" not in line:
                problems.append((
                    path,
                    lineno,
                    "P2 make usage without CATALINA_DIR",
                    line.strip(),
                ))
            if (
                P2_MAKE_PORT_COMMAND.search(line)
                and "CATALINA_DIR=" not in line
                and "TOOLCHAIN=flexc" not in line
            ):
                problems.append((
                    path,
                    lineno,
                    "P2 make command with PORT=/dev/ttyUSB0 without CATALINA_DIR",
                    line.strip(),
                ))

    for path, lineno, label, line in problems:
        print(f"{path}:{lineno}: forbidden {label}: {line}", file=sys.stderr)
    if problems:
        return 1

    print("ok: active P2 docs/tooling and make usage use sibling Catalina path, /dev/ttyUSB0 guidance, and no Docker Catalina references")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
