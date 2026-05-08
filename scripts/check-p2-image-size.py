#!/usr/bin/env python3
"""Fail a P2 build if the generated image cannot fit in Hub RAM."""

from __future__ import annotations

import argparse
import pathlib
import sys


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", required=True)
    parser.add_argument("--max-bytes", type=int, required=True)
    parser.add_argument("--label", default="P2 image")
    args = parser.parse_args()

    image = pathlib.Path(args.image)
    if not image.is_file():
        print(f"error: missing {args.label}: {image}", file=sys.stderr)
        return 1

    size = image.stat().st_size
    print(f"[Size] {args.label}: {size} / {args.max_bytes} bytes", flush=True)
    if size > args.max_bytes:
        over = size - args.max_bytes
        print(
            f"error: {args.label} is {size} bytes, which exceeds the "
            f"P2 Hub RAM limit of {args.max_bytes} bytes by {over} bytes.",
            file=sys.stderr,
        )
        print(
            "error: use a smaller Catalina profile for RAM loading "
            "(currently COMPACT with no -lpsram), or reduce the image size.",
            file=sys.stderr,
        )
        try:
            image.unlink()
            print(f"error: removed oversized {args.label}: {image}", file=sys.stderr)
        except OSError as exc:
            print(f"error: could not remove oversized {args.label}: {exc}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
