#!/usr/bin/env python3
from pathlib import Path
import os
import re
import sys


HEADER_CANDIDATES = [
    "include/smartpin.h",
    "source/lib/include/smartpin.h",
]
P2_NATIVE_SOURCE = Path("port/p2/overrides/be_p2lib_p2.c")


def read_smartpin_header(catalina_dir):
    for candidate in HEADER_CANDIDATES:
        path = catalina_dir / candidate
        if path.is_file():
            return path, path.read_text(encoding="utf-8", errors="replace")
    expected = ", ".join(str(catalina_dir / candidate) for candidate in HEADER_CANDIDATES)
    print(f"error: Catalina smartpin.h not found; checked {expected}", file=sys.stderr)
    return None, None


def catalina_names(header_text):
    return [
        match.group(1).lower()
        for match in re.finditer(r"^\s*#\s*define\s+P_([A-Z0-9_]+)\b", header_text, re.M)
    ]


def berry_names(source_text):
    match = re.search(
        r"static const p2_named_int p2_smart_constants\[\] = \{(.*?)\n\};",
        source_text,
        re.S,
    )
    if not match:
        print("error: p2_smart_constants table not found", file=sys.stderr)
        return []
    return re.findall(r'\{\s*"([^"]+)"\s*,', match.group(1))


def main():
    catalina_dir = Path(os.environ.get("CATALINA_DIR", "../Catalina"))
    header_path, header_text = read_smartpin_header(catalina_dir)
    if header_text is None:
        return 1
    if not P2_NATIVE_SOURCE.is_file():
        print(f"error: missing native P2 source: {P2_NATIVE_SOURCE}", file=sys.stderr)
        return 1

    expected = catalina_names(header_text)
    exposed = berry_names(P2_NATIVE_SOURCE.read_text(encoding="utf-8", errors="replace"))
    missing = [name for name in expected if name not in exposed]
    extra = [name for name in exposed if name not in expected]

    for name in missing:
        print(f"error: missing p2.smart constant for Catalina P_{name.upper()}", file=sys.stderr)
    for name in extra:
        print(f"error: extra p2.smart constant not in {header_path}: {name}", file=sys.stderr)
    if missing or extra:
        return 1

    print(
        f"ok: {len(expected)} Catalina smartpin.h P_ constants match "
        f"{len(exposed)} p2.smart constants from {header_path}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
