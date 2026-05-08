#!/usr/bin/env python3
"""Build top-level Spin2 sources into uppercase 8.3 BIN names.

FlexSpin derives auxiliary names from the output basename.  This wrapper keeps
the SD-visible binaries DOSFS-friendly and moves generated .p2asm listings into
a separate folder so spin2/build stays focused on runnable payloads.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import shutil
import subprocess


VALID_83 = re.compile(r"^[A-Z0-9_~$%'-]{1,8}\.BIN$")
SAFE_CHARS = set("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_~$%'")
CUSTOM_STEMS = {
    "berry_mailbox_demo": "MBOXDEMO",
}


def sanitize(text: str) -> str:
    chars = []
    for ch in text.upper():
        if ch in SAFE_CHARS:
            chars.append(ch)
        elif ch in "-.":
            chars.append("_")
    return "".join(chars).strip("_") or "SPIN2"


def stem83(source: Path, used: set[str]) -> str:
    raw = source.stem
    if raw in CUSTOM_STEMS:
        candidate = CUSTOM_STEMS[raw]
    else:
        candidate = sanitize(raw)[:8]

    if not candidate:
        candidate = "SPIN2"
    if candidate not in used:
        used.add(candidate)
        return candidate

    base = sanitize(raw)[:6] or "SPIN2"
    for index in range(1, 100):
        suffix = str(index)
        candidate = f"{base[:8 - len(suffix)]}{suffix}"
        if candidate not in used:
            used.add(candidate)
            return candidate
    raise RuntimeError(f"could not make unique 8.3 name for {source}")


def clean_dir(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--flexspin", required=True)
    parser.add_argument("--src-dir", default="spin2")
    parser.add_argument("--bin-dir", default="spin2/build")
    parser.add_argument("--asm-dir", default="spin2/build/p2asm")
    parser.add_argument("--manifest", default="spin2/build/MANIFEST.TXT")
    args = parser.parse_args()

    src_dir = Path(args.src_dir)
    bin_dir = Path(args.bin_dir)
    asm_dir = Path(args.asm_dir)
    manifest = Path(args.manifest)

    clean_dir(bin_dir)
    asm_dir.mkdir(parents=True, exist_ok=True)

    used: set[str] = set()
    rows: list[tuple[str, str, str]] = []
    sources = sorted(src_dir.glob("*.spin2"))
    if not sources:
        raise RuntimeError(f"no .spin2 sources found in {src_dir}")

    for source in sources:
        out_stem = stem83(source, used)
        out_bin = bin_dir / f"{out_stem}.BIN"
        print(f"[Spin2] {source} -> {out_bin}")
        subprocess.run(
            [args.flexspin, "-2", "-b", "-o", str(out_bin), str(source)],
            check=True,
        )
        if not VALID_83.match(out_bin.name):
            raise RuntimeError(f"non-8.3 binary name generated: {out_bin.name}")

        generated_listing = out_bin.with_suffix(".p2asm")
        listing_name = f"{out_stem}.p2asm"
        if generated_listing.exists():
            shutil.move(str(generated_listing), asm_dir / listing_name)
        rows.append((source.name, out_bin.name, listing_name if (asm_dir / listing_name).exists() else ""))

    manifest.parent.mkdir(parents=True, exist_ok=True)
    with manifest.open("w", encoding="utf-8") as fp:
        fp.write("# Spin2 build manifest\n")
        fp.write("# source,bin,p2asm\n")
        for source, binary, listing in rows:
            fp.write(f"{source},{binary},{listing}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
