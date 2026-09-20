#!/usr/bin/env python3
"""Actual partition code with host cog/lock/sbrk boundaries; never hardware proof."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
FILES = ["tests/native/test_p2_partition.c", "port/p2/include/berry_conf_p2.h",
         "tests/native/propeller2.h", "port/p2/runtime/p2_heap.c",
         "port/p2/runtime/p2_partition.c", "port/p2/include/p2_partition.h",
         "port/p2/include/p2_heap.h", "port/p2/include/p2_heap_internal.h"]

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--cc", default="gcc")
    args = ap.parse_args()
    (ROOT / "build").mkdir(exist_ok=True)
    out = Path(tempfile.mkdtemp(prefix="p2-partition-", dir=ROOT / "build"))
    snap = out / "snapshot"
    hashes = {}
    for name in FILES:
        dst = snap / name
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / name, dst)
        hashes[name] = hashlib.sha256(dst.read_bytes()).hexdigest()
    records = []
    result = {"success": False, "source_sha256": hashes, "records": records,
              "scope": "Host ownership/failure tests; physical cache coherence NOT simulated"}
    try:
        for mode, extra in [("static", []), ("virgin-break", [
            "-DBE_P2_HEAP_USES_EXTERNAL_RAM=1", "-DBE_P2_EXTERNAL_HEAP_STEP_BYTES=8",
            "-DTEST_FRESH_BREAK"])]:
            exe = out / mode
            command = [args.cc, "-std=c99", "-O1", "-g", "-Wall", "-Wextra",
                       "-fsanitize=address,undefined", "-fno-sanitize-recover=all",
                       "-fno-pie", "-no-pie", "-DBE_P2_HEAP_BYTES=8192",
                       "-I" + str(snap / "tests/native"),
                       "-I" + str(snap / "port/p2/include"), *extra,
                       str(snap / FILES[0]), "-o", str(exe)]
            for name, argv, timeout in [(mode + "-build", command, 90),
                                         (mode + "-run", [str(exe)], 30)]:
                log = out / (name + ".log")
                with log.open("w") as output:
                    p = subprocess.run(argv, stdout=output, stderr=subprocess.STDOUT, timeout=timeout)
                records.append({"name": name, "argv": argv, "returncode": p.returncode,
                                "log": str(log), "log_sha256": hashlib.sha256(log.read_bytes()).hexdigest()})
                if p.returncode:
                    print(log.read_text())
                    return 1
                if name.endswith("-run"):
                    print(log.read_text().strip())
        result["success"] = True
        return 0
    finally:
        (out / "results.json").write_text(json.dumps(result, indent=2) + "\n")
        print("Evidence:", out / "results.json")

if __name__ == "__main__":
    raise SystemExit(main())
