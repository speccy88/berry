#!/usr/bin/env python3
import argparse
from pathlib import Path
import re
import sys


MARKER_RE = re.compile(r"P2_SD_WRITE_AUDIT\s+max_write_opens=(\d+)")
WRITE_OPEN_RE = re.compile(
    r"\bopen\s*\([^,\n]+,\s*(['\"])(?:w|w\+|a|a\+|r\+)\1"
)
REMOVE_RE = re.compile(r"\bos\.remove\s*\(")
ABSENCE_RE = re.compile(
    r"assert\s*\(\s*!\s*(?:os\.path|configstore)\.exists\s*\("
)
CLEANUP_RE = re.compile(r"\b(?:os|configstore)\.remove\s*\(")


def audit_file(path):
    text = path.read_text(errors="replace")
    marker = MARKER_RE.search(text)
    if not marker:
        return []

    max_write_opens = int(marker.group(1))
    lines = text.splitlines()
    write_lines = [
        index
        for index, line in enumerate(lines, 1)
        if WRITE_OPEN_RE.search(line)
    ]
    problems = []
    if len(write_lines) > max_write_opens:
        problems.append(
            f"{path}: has {len(write_lines)} direct write opens, "
            f"budget is {max_write_opens}"
        )
    if not write_lines:
        problems.append(f"{path}: marked for SD write audit but has no direct write opens")
        return problems

    first_write = min(write_lines)
    before_first_write = "\n".join(lines[: first_write - 1])
    after_first_write = "\n".join(lines[first_write:])

    if REMOVE_RE.search(before_first_write):
        problems.append(f"{path}: calls os.remove() before the first write open")
    if not ABSENCE_RE.search(before_first_write):
        problems.append(
            f"{path}: does not assert os.path.exists() absence before first write"
        )
    if not CLEANUP_RE.search(after_first_write):
        problems.append(f"{path}: writes to SD but has no cleanup remove after first write")

    return problems


def main():
    parser = argparse.ArgumentParser(
        description="Audit marked P2 SD-writing smokes for small cleanup-oriented writes."
    )
    parser.add_argument(
        "paths",
        nargs="*",
        default=[str(path) for path in sorted(Path("tests/p2").glob("smoke_*.be"))],
    )
    args = parser.parse_args()

    marked = 0
    problems = []
    for item in args.paths:
        path = Path(item)
        if not path.is_file():
            problems.append(f"{path}: missing file")
            continue
        if MARKER_RE.search(path.read_text(errors="replace")):
            marked += 1
        problems.extend(audit_file(path))

    if problems:
        for problem in problems:
            print(f"error: {problem}", file=sys.stderr)
        return 1
    if marked == 0:
        print("error: no P2_SD_WRITE_AUDIT markers found", file=sys.stderr)
        return 1

    print(f"ok: {marked} marked SD-writing P2 smokes are small and cleanup-oriented")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
