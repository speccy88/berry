#!/usr/bin/env python3
"""Execute production registry and managed-cog consumers with real host Berry.

Only platform intrinsics/physical allocation are host seams. Source slices are
verbatim, hashed in the receipt, with #line provenance; no Berry API is mocked.
The default runs every case in 32- and 64-bit Berry integer configurations,
with both unsafe gates and Hub-pointer mailbox layout compiled and tested.
No Docker, SDK, serial, hardware or skipped tests in this command.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cc", default="gcc")
    parser.add_argument("--sanitize", action="store_true")
    args = parser.parse_args()
    if not shutil.which(args.cc):
        parser.error("compiler unavailable: " + args.cc)
    (ROOT / "build").mkdir(exist_ok=True)
    out = Path(tempfile.mkdtemp(prefix="p2-cog-handles-", dir=ROOT / "build"))
    records, hashes = [], {}
    env = dict(os.environ, ASAN_OPTIONS="detect_leaks=1:halt_on_error=1",
               UBSAN_OPTIONS="halt_on_error=1:print_stacktrace=1")

    def run(name, argv):
        log = out / (name + ".log")
        # Compilers can be CPU-throttled; keep runtime regressions tightly bounded.
        budget = 600 if name.startswith("compile") else 60
        with log.open("w") as output:
            try:
                proc = subprocess.run(list(map(str, argv)), cwd=ROOT, env=env,
                                      stdout=output, stderr=subprocess.STDOUT, timeout=budget)
                code = proc.returncode
            except subprocess.TimeoutExpired:
                code = 124
        text = log.read_text(errors="replace")
        records.append(dict(name=name, argv=list(map(str, argv)), returncode=code, timeout_seconds=budget))
        if code:
            raise RuntimeError(f"{name}: exit {code}\n{text}")
        if name.startswith("run"):
            print(text.strip(), flush=True)

    ok = False
    try:
        snap = out / "snapshot"
        files = []
        for directory in ("src", "default", "tools/coc", "port/p2/include", "tests/native/p2_cog_host"):
            files += [p for p in (ROOT / directory).rglob("*") if p.is_file() and "__pycache__" not in str(p)]
        files += [ROOT / p for p in (
            "port/p2/runtime/p2_vm_state.c", "port/p2/runtime/p2_cog_registry.c",
            "port/p2/overrides/be_p2lib_p2.c", "tests/native/test_p2_cog_registry.c",
            "tests/native/test_p2_cog_handles.c", "tools/test_p2_cog_handles.py")]
        for path in files:
            rel = path.relative_to(ROOT)
            data = path.read_bytes()
            hashes[str(rel)] = hashlib.sha256(data).hexdigest()
            dest = snap / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(data)
        source = (snap / "port/p2/overrides/be_p2lib_p2.c").read_text()

        slices = []

        def section(start, end):
            if source.count(start) != 1 or source.count(end) != 1:
                raise RuntimeError("production slice boundary changed: " + start)
            begin = source.index(start)
            finish = source.index(end, begin)
            if any(begin < previous_end and previous_begin < finish
                   for previous_begin, previous_end in slices):
                raise RuntimeError("overlapping production slice: " + start)
            slices.append((begin, finish))
            return '#line %d "port/p2/overrides/be_p2lib_p2.c"\n' % (source[:begin].count("\n") + 1) + source[begin:finish]

        # Compile verbatim production declarations/functions, excluding unrelated
        # SD/PSRAM/diagnostic module registration. Fail closed if boundaries drift.
        consumer = section("enum {\n    P2_CLOSURE_COG_MAX", "static void p2_module_set_func")
        consumer += section("static bint p2_require_int_arg", "#if BE_P2_ENABLE_ROADMAP_NATIVE_FACADES\nstatic uint32_t p2_require_u32_arg")
        consumer += section("static void p2_map_set_int", "static int p2_sd_probe_swap_cs_clk;")
        consumer += section("typedef struct p2_child_vm_cog_once_job", "static int p2_child_vm_runtime_lock_enter(void);")
        consumer += section("enum {\n    P2_NATIVE_BLINK_STATUS", "static const uint32_t p2_cog_marker_pasm")
        consumer += section("static int p2_child_vm_runtime_lock = -2;", "typedef struct p2_child_vm_cog_job")
        consumer += section("static void p2_child_vm_runtime_lock_init(void)", "typedef struct p2_closure_cog_slot")
        consumer += section("typedef struct p2_closure_cog_slot", "static void p2_child_vm_handles_init(void)")
        (snap / "managed_consumer.inc").write_text(consumer)
        worker = section("static void p2_child_vm_prepare_source", "static void p2_child_vm_runtime_lock_init(void)")
        (snap / "source_worker.inc").write_text(worker)
        common = [args.cc, "-std=c99", "-O1", "-g", "-Wall", "-Wextra",
                  "-Werror=implicit-function-declaration", "-Wno-unused-function", "-Wno-unused-variable",
                  "-fno-pie", "-no-pie"]
        if args.sanitize:
            common += ["-fsanitize=address,undefined", "-fno-sanitize-recover=all", "-fno-omit-frame-pointer"]
        includes = ["-I" + str(snap), "-I" + str(snap / "src"),
                    "-I" + str(snap / "port/p2/include"), "-I" + str(snap / "tests/native/p2_cog_host")]
        registry = [snap / "port/p2/runtime/p2_cog_registry.c", snap / "tests/native/p2_cog_host/registry_lock.c"]
        run("compile-registry", common + includes + [snap / "tests/native/test_p2_cog_registry.c"] + registry + ["-o", out / "registry"])
        run("run-registry", [out / "registry"])
        conf_base = (snap / "default/berry_conf.h").read_text()
        for bits, unsafe, large in ((32, 0, 0), (64, 0, 1), (32, 1, 1)):
            name = f"bint{bits}-unsafe{unsafe}-large{large}"
            conf = conf_base
            changes = {
                "#define BE_EXPLICIT_MALLOC              malloc": "#define BE_EXPLICIT_MALLOC              test_malloc",
                "#define BE_EXPLICIT_REALLOC             realloc": "#define BE_EXPLICIT_REALLOC             test_realloc",
                "#define BE_EXPLICIT_FREE                free": "#define BE_EXPLICIT_FREE                test_free",
            }
            if bits == 32:
                changes["#define BE_INTGER_TYPE                  2"] = "#define BE_INTGER_TYPE                  0"
            for old, new in changes.items():
                if conf.count(old) != 1:
                    raise RuntimeError("configuration prerequisite changed: " + old)
                conf = conf.replace(old, new)
            conf += "\n#include <stddef.h>\nvoid *test_malloc(size_t);\nvoid *test_realloc(void *, size_t);\nvoid test_free(void *);\n"
            (snap / "berry_conf.h").write_text(conf)
            (snap / "generate").mkdir(exist_ok=True)
            run("prebuild-" + name, [sys.executable, snap / "tools/coc/coc", "-o", snap / "generate",
                                    snap / "src", snap / "default", "-c", snap / "berry_conf.h"])
            flags = ["-D__CATALINA_P2", f"-DBE_P2_ENABLE_UNSAFE_SHARED_VM_COG={unsafe}"]
            if large:
                flags += ["-D__CATALINA_LARGE"]
            sources = [snap / "tests/native/test_p2_cog_handles.c", snap / "port/p2/runtime/p2_vm_state.c"] + registry
            sources += sorted((snap / "src").glob("*.c"))
            sources += [snap / "default/be_port.c", snap / "default/be_modtab.c"]
            binary = out / name
            run("compile-" + name, common + includes + flags + sources + ["-lm", "-ldl", "-o", binary])
            run("run-" + name, [binary])
        ok = all(hashlib.sha256((ROOT / p).read_bytes()).hexdigest() == digest for p, digest in hashes.items())
    except (RuntimeError, OSError, subprocess.TimeoutExpired) as error:
        print("FAIL:", error, flush=True)
    (out / "results.json").write_text(json.dumps(dict(success=ok, records=records, source_sha256=hashes), indent=2) + "\n")
    print(f"Managed cog host gates: success={ok}; evidence={out}")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
