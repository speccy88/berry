#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess


MANIFEST_FORMAT = "berry-p2-bec-manifest-v1"


def berry_hash(data: bytes) -> int:
    h = 0
    for byte in data:
        h = (h * 33 + byte) % 2147483647
    return h


def main() -> int:
    parser = argparse.ArgumentParser(description="Build a tiny .bec fixture and matching libstore sidecar.")
    parser.add_argument("--berry", default="./berry")
    parser.add_argument("--source", required=True)
    parser.add_argument("--module", required=True)
    parser.add_argument("--out-dir", required=True)
    args = parser.parse_args()

    source = Path(args.source)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    bec = out_dir / f"{args.module}.bec"
    manifest = out_dir / f"{args.module}.jsn"

    subprocess.run([args.berry, "-c", str(source), "-o", str(bec)], check=True)

    source_bytes = source.read_bytes()
    compiled_bytes = bec.read_bytes()
    data = {
        "format": MANIFEST_FORMAT,
        "module": args.module,
        "source_size": len(source_bytes),
        "source_hash": berry_hash(source_bytes),
        "compiled_size": len(compiled_bytes),
        "compiled_hash": berry_hash(compiled_bytes),
    }
    manifest.write_text(json.dumps(data, separators=(",", ":")), encoding="utf-8")
    print(f"[p2-bec-fixture] {source} -> {bec} + {manifest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
