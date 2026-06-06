#!/usr/bin/env python3
"""Fail a P2 build if the generated image exceeds its configured limit."""

from __future__ import annotations

import argparse
import pathlib
import sys


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", required=True)
    parser.add_argument("--max-bytes", type=int, required=True)
    parser.add_argument("--label", default="P2 image")
    parser.add_argument("--limit-name", default="P2 Hub RAM limit")
    parser.add_argument(
        "--hint",
        default=(
            "use a smaller Catalina profile for RAM loading "
            "(currently COMPACT with no -lpsram), or reduce the image size."
        ),
    )
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
            f"{args.limit_name} of {args.max_bytes} bytes by {over} bytes.",
            file=sys.stderr,
        )
        if args.hint:
            print(f"error: {args.hint}", file=sys.stderr)
        try:
            image.unlink()
            print(f"error: removed oversized {args.label}: {image}", file=sys.stderr)
        except OSError as exc:
            print(f"error: could not remove oversized {args.label}: {exc}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
