#!/usr/bin/env python3
"""VM-owned P2 native state tests: stdlib runner, real Berry, host-only seams.

No Docker dependency by default. --builder is explicit and derives its source
mount from docker inspect (or --docker-host-root). All generated files and real
command/output/hash receipts stay in ignored build/ snapshots.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
CASES = ["scheduler_reset", "rng_isolation", "rng_sequence", "scheduler_isolation",
         "scheduler_gc", "rng_boundaries", "lifecycle", "allocation_failures",
         "allocation_reentry", "interrupt_isolation", "cooperative_cancel"]
INPUTS = ["tools/test_p2_vm_state.py", "tests/native/test_p2_vm_state.c",
          "port/p2/overrides/be_tasklib_p2.c",
          "port/p2/overrides/be_math_stringlib_p2.c",
          "port/p2/runtime/p2_clock.c", "port/p2/include/p2_clock.h",
          "port/p2/runtime/p2_vm_state.c", "port/p2/include/p2_vm_state.h",
          "tools/coc/coc"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cc", default="gcc")
    parser.add_argument("--sanitize", action="store_true")
    parser.add_argument("--abi", choices=["native", "32"], default="native")
    parser.add_argument("--bint", choices=["64", "32"], default="64")
    parser.add_argument("--no-small-pools", action="store_true",
                        help="exercise the existing direct P2 allocator configuration")
    parser.add_argument("--builder", help="explicit isolated Docker builder image")
    parser.add_argument("--docker-host-root", help="explicit daemon-side repo path")
    args = parser.parse_args()
    if not shutil.which("docker" if args.builder else args.cc):
        parser.error("missing executable: " + ("docker" if args.builder else args.cc))
    (ROOT / "build").mkdir(exist_ok=True)
    out = Path(tempfile.mkdtemp(prefix="p2-vm-state-", dir=ROOT / "build"))
    hashes, records, results = {}, [], []
    prefix = []
    env = dict(os.environ, ASAN_OPTIONS="detect_leaks=1:halt_on_error=1",
               UBSAN_OPTIONS="halt_on_error=1:print_stacktrace=1")

    def execute(label, command, local=False):
        argv = ([] if local else prefix) + list(map(str, command))
        try:
            proc = subprocess.run(argv, cwd=ROOT, env=env, capture_output=True,
                                  text=True, timeout=240)
            code, stdout, stderr = proc.returncode, proc.stdout, proc.stderr
        except (OSError, subprocess.TimeoutExpired) as error:
            code, stdout, stderr = 125, "", str(error)
        (out / (label + ".log")).write_text(
            "$ " + shlex.join(argv) + "\n" + stdout + "\nSTDERR\n" + stderr + f"\nexit={code}\n")
        records.append(dict(name=label, argv=argv, returncode=code))
        if code:
            print(f"FAIL {label}: exit {code}\n{stdout}{stderr}", flush=True)
        return code, stdout

    failure = None
    try:
        paths = INPUTS + [str(p.relative_to(ROOT)) for directory in ["src", "default"]
                          for p in sorted((ROOT / directory).iterdir()) if p.suffix in (".c", ".h")]
        paths += [str(p.relative_to(ROOT)) for p in sorted((ROOT / "tools/coc").glob("*.py"))]
        snap = out / "snapshot"
        for path in paths:
            data = (ROOT / path).read_bytes()
            hashes[path] = hashlib.sha256(data).hexdigest()
            target = snap / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        conf = (snap / "default/berry_conf.h").read_text()
        def configure(old, new):
            nonlocal conf
            if conf.count(old) != 1:
                raise RuntimeError("configuration prerequisite changed: " + old)
            conf = conf.replace(old, new)

        if args.bint == "32":
            configure("#define BE_INTGER_TYPE                  2",
                      "#define BE_INTGER_TYPE                  0")
        # Real allocator with deterministic failure injection via its supported
        # BE_EXPLICIT_* configuration, not a replacement Berry allocator/API.
        configure("#define BE_EXPLICIT_MALLOC              malloc",
                  "#define BE_EXPLICIT_MALLOC              test_malloc")
        configure("#define BE_EXPLICIT_FREE                free",
                  "#define BE_EXPLICIT_FREE                test_free")
        configure("#define BE_EXPLICIT_REALLOC             realloc",
                  "#define BE_EXPLICIT_REALLOC             test_realloc")
        conf += ("\n#include <stddef.h>\nvoid *test_malloc(size_t);\n"
                 "void test_free(void *);\nvoid *test_realloc(void *, size_t);\n")
        (snap / "berry_conf.h").write_text(conf)
        (snap / "generate").mkdir()
        # Only declarations for the labelled host clock/cog seam. CORDIC calls
        # abort in the fixture; no simulated math/hardware success is supplied.
        registers = ("#ifndef TEST_PROP2_H\n#define TEST_PROP2_H\n#include <stdint.h>\n"
                     "uint32_t _cnth(void);\nuint32_t _cnt(void);\nuint32_t _clockfreq(void);\n"
                     "int _cogid(void);\nvoid _waitms(int);\n"
                     "typedef struct { uint32_t r, t; } polar_t;\n"
                     "typedef struct { int32_t x, y; } cartesian_t;\n"
                     "cartesian_t _polxy(polar_t);\npolar_t _xypol(cartesian_t);\n#endif\n")
        (snap / "propeller2.h").write_text(registers)
        (snap / "prop2.h").write_text(registers)
        target_out = out
        if args.builder:
            host_root = args.docker_host_root
            if not host_root:
                code, text = execute("docker-inspect", ["docker", "inspect", "propeller2",
                                                        "--format", "{{json .Mounts}}"], local=True)
                if code:
                    raise RuntimeError("cannot derive daemon source mount")
                mounts = json.loads(text)
                host_root = str(Path(next(m["Source"] for m in mounts
                                          if m["Destination"] == "/work/propeller2")) / "berry")
            out.chmod(0o777)
            target_out = Path("/evidence")
            prefix = ["docker", "run", "--rm", "--network", "none", "--user", "10000:10000",
                      "--cap-drop", "ALL", "--security-opt", "no-new-privileges",
                      "--mount", f"type=bind,src={Path(host_root) / out.relative_to(ROOT)},dst={target_out}",
                      "--workdir", str(target_out), "--env", "ASAN_OPTIONS=" + env["ASAN_OPTIONS"],
                      "--env", "UBSAN_OPTIONS=" + env["UBSAN_OPTIONS"], args.builder]
        code, _ = execute("prebuild", [sys.executable, snap / "tools/coc/coc", "-o",
                          snap / "generate", snap / "src", snap / "default", "-c", snap / "berry_conf.h"], local=True)
        if code:
            raise RuntimeError("core prebuild failed")
        ts = target_out / "snapshot"
        flags = ["-std=c99", "-O1", "-g", "-Wall", "-Wextra", "-D__CATALINA_P2",
                 "-DBE_P2_ENABLE_MAIN_INTERRUPT=1",
                 "-I" + str(ts), "-I" + str(ts / "src"), "-I" + str(ts / "port/p2/include")]
        if args.abi == "32":
            flags += ["-m32"]
        if args.no_small_pools:
            flags += ["-DBE_P2_NO_SMALL_POOLS=1"]
        if args.sanitize:
            flags += ["-fsanitize=address,undefined", "-fno-sanitize-recover=all",
                      "-fno-omit-frame-pointer", "-fno-pie", "-no-pie"]
        sources = [ts / "tests/native/test_p2_vm_state.c", ts / "port/p2/runtime/p2_clock.c",
                   ts / "port/p2/runtime/p2_vm_state.c"]
        sources += [ts / "src" / p.name for p in sorted((snap / "src").glob("*.c"))
                    if p.name not in ("be_mathlib.c", "be_stringlib.c")]
        sources += [ts / "default/be_port.c", ts / "default/be_modtab.c"]
        binary = target_out / "test-vm-state"
        code, _ = execute("compiler-version", [args.cc, "--version"])
        if code:
            raise RuntimeError("compiler unavailable")
        code, _ = execute("compile", [args.cc] + flags + sources + ["-lm", "-ldl", "-o", binary])
        if code:
            raise RuntimeError("compiler/linker failure")
        for case in CASES:
            code, text = execute(case, [binary, case])
            if code:
                continue
            row = json.loads(text.strip().splitlines()[-1])
            if row["case"] != case or row["checks"] <= 0 or row["failures"] != 0:
                raise RuntimeError("invalid test receipt")
            if row["bint_bits"] != int(args.bint) or row["pointer_bits"] not in (32, 64):
                raise RuntimeError("unexpected ABI")
            if args.abi == "32" and row["pointer_bits"] != 32:
                raise RuntimeError("not a real ABI32 run")
            results.append(row)
    except (OSError, ValueError, KeyError, IndexError, StopIteration, RuntimeError) as error:
        failure = str(error)
        print("FAIL: " + failure, flush=True)
    unchanged = all((ROOT / p).exists() and hashlib.sha256((ROOT / p).read_bytes()).hexdigest() == h
                    for p, h in hashes.items())
    success = len(results) == len(CASES) and not failure and unchanged
    receipt = dict(success=success, source_unchanged=unchanged, source_sha256=hashes,
                   expected_cases=CASES, results=results, records=records, error=failure,
                   options=vars(args), invocation=[sys.executable] + sys.argv,
                   binary_sha256=hashlib.sha256((out / "test-vm-state").read_bytes()).hexdigest()
                   if (out / "test-vm-state").is_file() else None)
    (out / "results.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(f"VM state: {len(results)}/{len(CASES)} cases passed; "
          f"{sum(r['checks'] for r in results)} checks in passed cases; success={success}")
    print("Evidence: " + str(out / "results.json"))
    return 0 if success else 1


if __name__ == "__main__":
    raise SystemExit(main())
