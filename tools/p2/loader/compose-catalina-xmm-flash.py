#!/usr/bin/env python3
import argparse
import json
import struct
from pathlib import Path


PROP_CHECKSUM = 0x706F7250
STAGE1_SIZE = 1024


def parse_int(text: str) -> int:
    return int(text, 0)


def patch_stage1_checksum(data: bytes) -> bytes:
    stage = bytearray(data)
    if len(stage) > STAGE1_SIZE:
        raise ValueError(f"stage1 is {len(stage)} bytes, expected at most {STAGE1_SIZE}")
    stage.extend(b"\x00" * (STAGE1_SIZE - len(stage)))
    words = list(struct.unpack("<256I", stage))
    checksum = sum(words) & 0xFFFFFFFF
    words[-1] = (words[-1] + ((PROP_CHECKSUM - checksum) & 0xFFFFFFFF)) & 0xFFFFFFFF
    return struct.pack("<256I", *words)


def put(blob: bytearray, offset: int, data: bytes) -> None:
    end = offset + len(data)
    if len(blob) < end:
        blob.extend(b"\xFF" * (end - len(blob)))
    blob[offset:end] = data


def main() -> int:
    parser = argparse.ArgumentParser(description="Compose a bootable P2 Catalina XMM flash image.")
    parser.add_argument("--stage1", required=True)
    parser.add_argument("--loader", required=True)
    parser.add_argument("--app", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--loader-addr", type=parse_int, default=0x10000)
    parser.add_argument("--app-addr", type=parse_int, default=0x40000)
    parser.add_argument("--metadata", default="")
    args = parser.parse_args()

    stage1 = patch_stage1_checksum(Path(args.stage1).read_bytes())
    loader = Path(args.loader).read_bytes()
    app = Path(args.app).read_bytes()

    if args.loader_addr < STAGE1_SIZE:
        raise ValueError("loader address overlaps stage1")
    loader_record = struct.pack("<I", len(loader)) + loader
    app_record = struct.pack("<I", len(app)) + app
    if args.loader_addr + len(loader_record) > args.app_addr:
        raise ValueError("loader record overlaps app record")

    image = bytearray()
    put(image, 0, stage1)
    put(image, args.loader_addr, loader_record)
    put(image, args.app_addr, app_record)

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(image)

    metadata = {
        "output": str(output),
        "total_size": len(image),
        "stage1_addr": 0,
        "stage1_size": len(stage1),
        "loader_addr": args.loader_addr,
        "loader_size": len(loader),
        "app_addr": args.app_addr,
        "app_size": len(app),
    }
    if args.metadata:
        Path(args.metadata).write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(metadata, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
