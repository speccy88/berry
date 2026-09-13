#!/usr/bin/env python3
"""Build/run the real P2 allocator on a host; no hardware or PSRAM evidence.

Uses only Python's standard library. Each case gets its own process so a
baseline corruption/crash cannot hide later results. Logs/binaries are retained
under the repository's ignored build/ directory, never generated source files.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
CONTAINER_ROOT = Path("/work/propeller2/berry")
PROFILES = {
    "static": ["-DBE_P2_HEAP_USES_EXTERNAL_RAM=0"],
    "static-external": ["-DBE_P2_HEAP_USES_EXTERNAL_RAM=1",
                        "-DBE_P2_HEAP_STATIC_EXTERNAL_ARENA=1"],
    "external": ["-DBE_P2_HEAP_USES_EXTERNAL_RAM=1"],
    "external-window": [
        "-DBE_P2_HEAP_USES_EXTERNAL_RAM=1",
        "-DBE_P2_PSRAM_BLOCK_BASE=(UINTPTR_MAX-4095)",
    ],
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--container", help="run clang via docker exec --user 10000:10000")
    parser.add_argument("--cc", help="compiler executable (default: clang in container, cc on host)")
    parser.add_argument("--freestanding32", action="store_true",
                        help="Linux/i386 host execution without multilib libc; not P2 emulation")
    parser.add_argument("--cflags", default="", help="extra compiler/linker flags, e.g. --cflags=-m32")
    args = parser.parse_args()
    compiler = args.cc or ("clang" if args.container else os.environ.get("CC", "cc"))
    if not args.container and shutil.which(compiler) is None:
        parser.error("compiler not found: " + compiler)
    if args.container and shutil.which("docker") is None:
        parser.error("docker not found")

    build_root = ROOT / "build"
    build_root.mkdir(exist_ok=True)
    output = Path(tempfile.mkdtemp(prefix="p2-heap-", dir=build_root))
    if args.container:
        # Only this newly created scratch directory needs container write access.
        output.chmod(0o777)
    target_root = CONTAINER_ROOT if args.container else ROOT
    target_output = target_root / output.relative_to(ROOT)
    prefix = (["docker", "exec", "--user", "10000:10000", "--workdir",
               str(target_root), args.container] if args.container else [])
    records = []
    passed = failed = build_failures = 0
    source = ROOT / "port/p2/runtime/p2_heap.c"
    source_hash = hashlib.sha256(source.read_bytes()).hexdigest()

    def execute(label, command, timeout=30):
        argv = prefix + command
        if label.endswith("-compile"):
            print("+ " + shlex.join(argv), flush=True)
        try:
            result = subprocess.run(argv, cwd=ROOT, capture_output=True,
                                    text=True, timeout=timeout)
            stdout, stderr, code = result.stdout, result.stderr, result.returncode
        except (OSError, subprocess.TimeoutExpired) as error:
            stdout, stderr, code = "", str(error), 125
        log = "$ " + shlex.join(argv) + "\n" + stdout + "\nSTDERR\n" + stderr
        (output / (label + ".log")).write_text(log)
        if stdout and (code or not label.endswith("-list")):
            print(stdout, end="" if stdout.endswith("\n") else "\n", flush=True)
        if stderr:
            print(stderr, end="" if stderr.endswith("\n") else "\n", flush=True)
        records.append({"name": label, "argv": argv, "returncode": code})
        return code, stdout

    for profile, defines in PROFILES.items():
        binary = target_output / ("test-p2-heap-" + profile)
        command = [compiler, "-std=c99", "-O1", "-g", "-Wall", "-Wextra",
                   "-DBE_P2_HEAP_BYTES=8192", "-DBE_P2_WORKER_HEAP_BYTES=1024",
                   "-DBE_P2_VM_HEAP_PARTITION_BYTES=512",
                   "-DBE_P2_EXTERNAL_HEAP_MIN_BYTES=2048",
                   "-DBE_P2_EXTERNAL_HEAP_STEP_BYTES=256",
                   "-DBE_P2_EXTERNAL_HEAP_CHUNK_BYTES=1024",
                   "-I" + str(target_root / "tests/native"),
                   "-I" + str(target_root / "port/p2/include")]
        if args.freestanding32:
            command += ["-m32", "-ffreestanding", "-fno-builtin", "-fno-pie", "-no-pie",
                        "-nostdlib", "-fno-stack-protector", "-DTEST_P2_HEAP_FREESTANDING32",
                        "-I" + str(target_root / "tests/native/freestanding32")]
        command += defines + shlex.split(args.cflags)
        command += [str(target_root / "tests/native/test_p2_heap.c"), "-o", str(binary)]
        code, _ = execute(profile + "-compile", command, timeout=90)
        if code:
            build_failures += 1
            continue
        code, stdout = execute(profile + "-list", [str(binary), "--list"])
        names = stdout.splitlines()
        if code or not names or len(names) != len(set(names)):
            build_failures += 1
            continue
        for name in names:
            code, _ = execute(profile + "-" + name, [str(binary), name])
            if code:
                failed += 1
                print("FAIL " + profile + "/" + name + " exit=" + str(code), flush=True)
            else:
                passed += 1

    unchanged = source_hash == hashlib.sha256(source.read_bytes()).hexdigest()
    success = bool(passed) and not failed and not build_failures and unchanged
    summary = {"scope": "host-only production allocator execution",
               "source_sha256": source_hash, "source_unchanged": unchanged,
               "passed": passed, "failed": failed, "total": passed + failed,
               "build_failures": build_failures, "success": success,
               "records": records}
    (output / "results.json").write_text(json.dumps(summary, indent=2) + "\n")
    print("Allocator tests: {passed} passed, {failed} failed, {total} total; "
          "{build_failures} build/discovery failures".format(**summary), flush=True)
    print("Evidence: " + str(output / "results.json"), flush=True)
    return 0 if success else 1


if __name__ == "__main__":
    raise SystemExit(main())
