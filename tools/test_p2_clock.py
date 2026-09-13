#!/usr/bin/env python3
"""Exact host regressions for the production P2 clock and cooperative scheduler.

Stdlib only. No hardware, SDK, generated source-tree headers or build-rule writes.
The optional isolated builder uses real Linux libc/multilib and sanitizer runtimes.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import random
import shlex
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MASK = (1 << 32) - 1
HALF = 1 << 31
SOURCES = ["port/p2/runtime/p2_clock.c", "port/p2/include/p2_clock.h",
           "port/p2/runtime/p2_vm_state.c", "port/p2/include/p2_vm_state.h",
           "port/p2/overrides/be_tasklib_p2.c", "tests/native/test_p2_clock.c",
           "tools/test_p2_clock.py", "default/berry_conf.h",
           "default/be_port.c", "default/be_modtab.c"]


def vectors(path):
    rng = random.Random(0xF2C10C)
    frequencies = [1, 2, 3, 999, 1000, 1001, 200000000, 240000000,
                   300000000, 199999999, 240000001, 300000007,
                   HALF - 1, HALF, HALF + 1, MASK]
    words = [0, 1, 0xffff, 0xffff0000, HALF - 1, HALF, MASK - 1, MASK]
    ticks = [(hi, lo, hz) for hz in frequencies for hi in words for lo in words]
    # Raw low-counter rollover, long delays, and modular millisecond rollover.
    for hz in frequencies:
        for boundary in [1 << 32, ((1 << 32) * hz) // 1000,
                         60000 * hz // 1000, 86400000 * hz // 1000]:
            for delta in [-hz, -1, 0, 1, hz]:
                tick = (boundary + delta) & ((1 << 64) - 1)
                ticks.append((tick >> 32, tick & MASK, hz))
    for _ in range(16000):
        ticks.append((rng.getrandbits(32), rng.getrandbits(32),
                      rng.choice(frequencies) if rng.randrange(2) else rng.randint(1, MASK)))
    delays = [0, 1, 16, 30000, 60000, 86400000, HALF - 1, HALF, HALF + 1, MASK]
    deadlines = []
    for now in words:
        for delay in delays:
            for elapsed in [0, max(0, delay - 1), delay, delay + 1, delay + HALF]:
                for armed in [0, 1]:
                    deadlines.append((now, delay, (now + elapsed) & MASK, armed))
    # Explicit wrap-to-zero arms, including a zero immediate deadline at now=0.
    for delay in [0, 1, 16, 60000, HALF - 1]:
        for probe in [MASK, 0, 1]:
            deadlines.append(((-delay) & MASK, delay, probe, 0))
    for _ in range(8000):
        now, delay, probe = (rng.getrandbits(32) for _ in range(3))
        deadlines.append((now, delay, probe, rng.randrange(2)))
    with path.open("w") as stream:
        for hi, lo, hz in ticks:
            tick = (hi << 32) | lo
            q, rem = divmod(tick, hz)
            millis = (tick * 1000 // hz) & MASK
            stream.write(f"T {hi} {lo} {hz} {q & MASK} {rem} {millis}\n")
        for now, delay, probe, armed in deadlines:
            valid = int(delay < HALF)
            at = (now + delay) & MASK
            reached = int(((probe - at) & MASK) < HALF)
            remaining = 0 if reached else (at - probe) & MASK
            stream.write(f"D {now} {delay} {probe} {valid} {at} {reached} {remaining} {armed}\n")
    return {"tick_cases": len(ticks), "deadline_cases": len(deadlines)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cc", default="gcc", help="compiler executable; default gcc")
    parser.add_argument("--abi", choices=["native", "32"], default="native")
    parser.add_argument("--sanitize", action="store_true", help="enable ASan and UBSan, fatal on error")
    parser.add_argument("--builder", help="isolated Docker image, e.g. local/berry-p2-dev:cat8.8.9")
    parser.add_argument("--docker-host-root", default="/DATA/AppData/hopeful_renaud/propeller2/berry",
                        help="daemon-side repository path (not the Hermes mount path)")
    args = parser.parse_args()
    executable = "docker" if args.builder else args.cc
    if shutil.which(executable) is None:
        parser.error("executable not found: " + executable)
    (ROOT / "build").mkdir(exist_ok=True)
    output = Path(tempfile.mkdtemp(prefix="p2-clock-", dir=ROOT / "build"))
    target_root = Path("/work/berry") if args.builder else ROOT
    target_output = target_root / output.relative_to(ROOT)
    prefix = []
    if args.builder:
        output.chmod(0o777)
        prefix = ["docker", "run", "--rm", "--network", "none", "--user", "10000:10000",
                  "--cap-drop", "ALL", "--security-opt", "no-new-privileges",
                  "--mount", f"type=bind,src={args.docker_host_root},dst={target_root},readonly",
                  "--mount", f"type=bind,src={Path(args.docker_host_root) / output.relative_to(ROOT)},dst={target_output}",
                  "--workdir", str(target_root),
                  "--env", "ASAN_OPTIONS=detect_leaks=1:halt_on_error=1",
                  "--env", "UBSAN_OPTIONS=halt_on_error=1:print_stacktrace=1", args.builder]
    environment = dict(os.environ, ASAN_OPTIONS="detect_leaks=1:halt_on_error=1",
                       UBSAN_OPTIONS="halt_on_error=1:print_stacktrace=1")
    records, results = [], []
    hashes = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in SOURCES}
    expected = vectors(output / "vectors.txt")
    # Test-only register declarations, NOT a replacement stdint/libc or SDK.
    registers = ("#include <stdint.h>\nuint32_t _cnth(void);\nuint32_t _cnt(void);\n"
                 "uint32_t _clockfreq(void);\nvoid _waitms(int ms);\n")
    (output / "prop2.h").write_text(registers)
    (output / "propeller2.h").write_text(registers)
    # Berry's generated includes are ../generate relative to its core files.
    # Stage byte-identical core sources so coc never writes root/generate.
    # Clock and task implementation are compiled directly from the real paths.
    core = output / "src"
    core.mkdir()
    for source in sorted((ROOT / "src").iterdir()):
        if source.suffix in (".c", ".h"):
            shutil.copyfile(source, core / source.name)
            hashes[str(source.relative_to(ROOT))] = hashlib.sha256(source.read_bytes()).hexdigest()
    (output / "berry_conf.h").write_bytes((ROOT / "default/berry_conf.h").read_bytes())
    (output / "generate").mkdir()

    def execute(label, command, local=False):
        argv = ([] if local else prefix) + [str(arg) for arg in command]
        print("+ " + shlex.join(argv), flush=True)
        try:
            result = subprocess.run(argv, cwd=ROOT, env=environment, capture_output=True,
                                    text=True, timeout=240)
            code, stdout, stderr = result.returncode, result.stdout, result.stderr
        except (OSError, subprocess.TimeoutExpired) as error:
            code, stdout, stderr = 125, "", str(error)
        (output / (label + ".log")).write_text(
            "$ " + shlex.join(argv) + "\n" + stdout + "\nSTDERR\n" + stderr + f"\nexit={code}\n")
        records.append({"name": label, "argv": argv, "returncode": code})
        if stdout:
            print(stdout, end="" if stdout.endswith("\n") else "\n", flush=True)
        if stderr:
            print(stderr, end="" if stderr.endswith("\n") else "\n", flush=True)
        return code, stdout

    flags = ["-O1", "-g", "-Wall", "-Wextra"]
    if args.abi == "32":
        flags += ["-m32"]
    if args.sanitize:
        flags += ["-fsanitize=address,undefined", "-fno-sanitize-recover=all",
                  "-fno-omit-frame-pointer", "-fno-pie", "-no-pie"]
    code, _ = execute("core-prebuild", [sys.executable, ROOT / "tools/coc/coc",
        "-o", output / "generate", core, ROOT / "default", "-c", output / "berry_conf.h"], local=True)
    if code:
        print("Core prebuild failed; evidence: " + str(output))
        return 1
    failed = 0
    for mode in ["portable", "scheduler"]:
        binary = target_output / ("test-" + mode)
        command = [args.cc] + flags + ["-I" + str(target_output),
                   "-I" + str(target_root / "port/p2/include")]
        if mode == "portable":
            command += ["-std=c89", "-pedantic-errors", "-Werror"]
        else:
            command += ["-std=c99", "-D__CATALINA_P2", "-DTEST_P2_TASK",
                        "-I" + str(target_output / "src")]
        command += [target_root / "tests/native/test_p2_clock.c",
                    target_root / "port/p2/runtime/p2_clock.c"]
        if mode == "scheduler":
            command += [target_root / "port/p2/runtime/p2_vm_state.c"]
            command += [target_output / "src" / p.name for p in sorted(core.glob("*.c"))]
            command += [target_root / "default/be_port.c", target_root / "default/be_modtab.c", "-lm", "-ldl"]
        command += ["-o", binary]
        code, _ = execute(mode + "-compile", command)
        if code:
            failed += 1
            continue
        code, stdout = execute(mode + "-run", [binary, target_output / "vectors.txt"])
        if code:
            failed += 1
            continue
        try:
            actual = json.loads(stdout.strip().splitlines()[-1])
            for key, value in expected.items():
                if actual[key] != value:
                    raise ValueError(f"{key}: expected {value}, got {actual[key]}")
            if actual["long_bits"] != actual["pointer_bits"] or actual["pointer_bits"] not in (32, 64):
                raise ValueError("unexpected host ABI")
            if args.abi == "32" and actual["pointer_bits"] != 32:
                raise ValueError("-m32 did not exercise a real 32-bit ABI")
            if mode == "scheduler" and (actual["sampler_cases"] != 3 or actual["task_cases"] != 67):
                raise ValueError("scheduler/sampler coverage missing")
            results.append({"mode": mode, **actual})
        except (ValueError, KeyError, IndexError) as error:
            print("FAIL summary: " + str(error), flush=True)
            failed += 1
    unchanged = hashes == {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in hashes}
    success = len(results) == 2 and not failed and unchanged
    summary = {"scope": "host logic only; injected registers, real Berry scheduler and Linux libc",
               "success": success, "failures": failed, "source_unchanged": unchanged,
               "source_sha256": hashes, "expected_per_binary": expected,
               "results": results, "records": records}
    (output / "results.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(f"Clock tests: {len(results)}/2 binaries passed; {failed} failures; success={success}")
    for row in results:
        print(f"  {row['mode']}: {row['pointer_bits']}-bit ABI; "
              f"{row['tick_cases']} exact tick pairs, {row['deadline_cases']} deadlines, "
              f"{row['sampler_cases']} sampler and {row['task_cases']} scheduler scenarios; "
              f"{row['checks']} C checks")
    print("Evidence: " + str(output / "results.json"))
    return 0 if success else 1


if __name__ == "__main__":
    raise SystemExit(main())
