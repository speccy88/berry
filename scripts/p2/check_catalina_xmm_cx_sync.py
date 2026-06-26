#!/usr/bin/env python3
import argparse
from pathlib import Path
import sys


REQUIRED = {
    "secread": {
        "source": "source/lib/catalina/secread.c",
        "generated": "lib/p2/xmm/cx/secread.s",
        "index_lines": [
            "sd_sectread secread.s",
            "_long_service_2 secread.s",
        ],
    },
    "secwrite": {
        "source": "source/lib/catalina/secwrite.c",
        "generated": "lib/p2/xmm/cx/secwrite.s",
        "index_lines": [
            "sd_sectwrite secwrite.s",
            "_long_service_2 secwrite.s",
        ],
    },
    "dwrite": {
        "source": "source/lib/io/dwrite.c",
        "generated": "lib/p2/xmm/cx/dwrite.s",
        "index_lines": [
            "DFS_WriteSector dwrite.s",
            "sd_sectwrite dwrite.s",
        ],
    },
}


def rel(root, path):
    try:
        return path.relative_to(root)
    except ValueError:
        return path


def fail(message):
    print(f"error: {message}", file=sys.stderr)
    return 1


def main():
    parser = argparse.ArgumentParser(
        description="Check that Catalina P2/XMM cx generated SD objects are synchronized."
    )
    parser.add_argument("--catalina-dir", default="../Catalina")
    args = parser.parse_args()

    root = Path(args.catalina_dir).resolve()
    if not root.is_dir():
        return fail(f"Catalina directory not found: {root}")

    index = root / "lib/p2/xmm/cx/catalina.idx"
    if not index.is_file():
        return fail(f"missing {rel(root, index)}")
    index_text = index.read_text(errors="replace")

    problems = []
    generated_paths = []
    for name, spec in REQUIRED.items():
        source = root / spec["source"]
        generated = root / spec["generated"]
        if not source.is_file():
            problems.append(f"missing source for {name}: {rel(root, source)}")
            continue
        if not generated.is_file():
            problems.append(f"missing generated object for {name}: {rel(root, generated)}")
            continue
        generated_paths.append(generated)
        if generated.stat().st_mtime + 1 < source.stat().st_mtime:
            problems.append(
                f"{rel(root, generated)} is older than {rel(root, source)}"
            )
        for line in spec["index_lines"]:
            if line not in index_text:
                problems.append(f"{rel(root, index)} missing index entry containing: {line}")

    if generated_paths:
        newest_generated = max(path.stat().st_mtime for path in generated_paths)
        if index.stat().st_mtime + 1 < newest_generated:
            problems.append(f"{rel(root, index)} is older than generated XMM cx objects")

    if problems:
        for problem in problems:
            print(f"error: {problem}", file=sys.stderr)
        return 1

    print("ok: Catalina P2/XMM cx generated SD objects and index are synchronized")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
