#!/usr/bin/env python3

from __future__ import annotations

import argparse
import datetime as dt
import pathlib
import re


SIZE_PATTERNS = {
    "code": re.compile(r"^code\s*=\s*(\d+)\s+bytes$", re.MULTILINE),
    "const": re.compile(r"^cnst\s*=\s*(\d+)\s+bytes$", re.MULTILINE),
    "init": re.compile(r"^init\s*=\s*(\d+)\s+bytes$", re.MULTILINE),
    "data": re.compile(r"^data\s*=\s*(\d+)\s+bytes$", re.MULTILINE),
    "file": re.compile(r"^file\s*=\s*(\d+)\s+bytes$", re.MULTILINE),
}


def read_text(path: pathlib.Path | None) -> str:
    if not path or not path.is_file():
        return ""
    return path.read_text(encoding="utf-8", errors="replace")


def parse_sizes(text: str) -> dict[str, int]:
    sizes: dict[str, int] = {key: 0 for key in SIZE_PATTERNS}
    for key, pattern in SIZE_PATTERNS.items():
        match = pattern.search(text)
        if match:
            sizes[key] = int(match.group(1))
    return sizes


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", required=True)
    parser.add_argument("--binary", required=True)
    parser.add_argument("--header", required=True)
    args = parser.parse_args()

    log_path = pathlib.Path(args.log) if args.log else None
    binary_path = pathlib.Path(args.binary) if args.binary else None
    header_path = pathlib.Path(args.header)

    sizes = parse_sizes(read_text(log_path))
    binary_size = 0
    if binary_path and binary_path.is_file():
        binary_size = binary_path.stat().st_size
    if not binary_size:
        binary_size = sizes["file"]

    now = dt.datetime.now()
    build_date = now.strftime("%b %d %Y")
    build_time = now.strftime("%H:%M:%S")

    header = f"""#ifndef P2_BUILD_INFO_H
#define P2_BUILD_INFO_H

#define P2_BUILD_DATE_STR "{build_date}"
#define P2_BUILD_TIME_STR "{build_time}"
#define P2_BUILD_BINARY_BYTES {binary_size}u
#define P2_BUILD_CODE_BYTES {sizes["code"]}u
#define P2_BUILD_CONST_BYTES {sizes["const"]}u
#define P2_BUILD_INIT_BYTES {sizes["init"]}u
#define P2_BUILD_DATA_BYTES {sizes["data"]}u

#endif
"""
    header_path.write_text(header, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
