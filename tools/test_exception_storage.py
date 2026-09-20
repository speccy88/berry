#!/usr/bin/env python3
"""Host test of exception-vector allocator routing, using the complete Berry VM."""
import argparse
import hashlib
import json
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cc", default="gcc")
    parser.add_argument("--cflags", default="")
    parser.add_argument("--sanitize", action="store_true")
    args = parser.parse_args()
    compiler = shutil.which(args.cc)
    if compiler is None:
        parser.error("C compiler is required; no skipped test")
    (ROOT / "build").mkdir(exist_ok=True)
    out = Path(tempfile.mkdtemp(prefix="exception-storage-", dir=ROOT / "build"))
    tracked = sorted(str(p.relative_to(ROOT)) for folder in
                     ('src', 'default', 'tools/coc', 'tests/native', 'port/p2')
                     for p in (ROOT / folder).rglob('*')
                     if p.is_file() and p.suffix in ('.c', '.h', '.py'))
    tracked += ['tools/coc/coc', 'tools/test_exception_storage.py']
    source_hashes = {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
                     for name in tracked}
    ignore = shutil.ignore_patterns("*.o", "*.d", "*.gcda", "*.gcno", "__pycache__")
    shutil.copytree(ROOT / "src", out / "src", ignore=ignore)
    shutil.copytree(ROOT / "default", out / "default", ignore=ignore)
    (out / "generate").mkdir()
    records = []

    def run(name, argv, timeout):
        result = subprocess.run(argv, cwd=out, text=True, capture_output=True,
                                timeout=timeout)
        (out / (name + ".log")).write_text(
            "+ " + shlex.join(argv) + "\n" + result.stdout + "\n" + result.stderr)
        records.append({"name": name, "argv": argv, "returncode": result.returncode})
        print(name, "exit", result.returncode)
        if result.stdout:
            print(result.stdout, end="")
        if result.stderr:
            print(result.stderr, end="", file=sys.stderr)
        return result.returncode

    coc = [sys.executable, str(ROOT / "tools/coc/coc"), "-o", str(out / "generate"),
           str(out / "src"), str(out / "default"), "-c", str(out / "default/berry_conf.h")]
    code = run("generate", coc, 90)
    sources = sorted((out / "src").glob("*.c"))
    sources += [out / "default/be_port.c", out / "default/be_modtab.c",
                ROOT / "tests/native/test_exception_storage.c",
                ROOT / "tests/native/test_vm_special_storage.c",
                ROOT / "port/p2/runtime/p2_exception_memory.c"]
    command = [compiler, "-std=c99", "-O1", "-g", "-Wall", "-Wextra",
               "-I" + str(out / "default"), "-I" + str(out / "src"),
               "-I" + str(ROOT / "port/p2/include"), "-D__CATALINA_LARGE",
               "-DBE_EXCEPTSTACK_REALLOC=be_p2_realloc_exceptstack"]
    command += shlex.split(args.cflags)
    if args.sanitize:
        command += ["-fsanitize=address,undefined", "-fno-sanitize-recover=all",
                    "-fno-omit-frame-pointer", "-fno-pie", "-no-pie"]
    command += ["-UNDEBUG"] + [str(p) for p in sources]
    command += ["-lm", "-ldl", "-o", str(out / "test-exception-storage")]
    if code == 0:
        code = run("compile", command, 180)
    if code == 0:
        code = run("execute", [str(out / "test-exception-storage")], 45)
    if code == 0:
        shim = out / "hub-shim"
        shim.mkdir()
        (shim / "prop2.h").write_text(
            "int _locknew(void);\n"
            "int _locktry(int);\n"
            "void _lockrel(int);\n")
        (shim / "hmalloc.h").write_text(
            "#include <stddef.h>\nvoid *hub_realloc(void *, size_t);\n"
            "void hub_free(void *);\n")
        hub_command = [compiler, "-std=c89", "-pedantic-errors", "-Wall", "-Wextra",
                       "-Werror", "-D__CATALINA_LARGE", "-I" + str(shim),
                       "-I" + str(ROOT / "port/p2/include")]
        hub_command += shlex.split(args.cflags)
        if args.sanitize:
            hub_command += ["-fsanitize=address,undefined", "-fno-sanitize-recover=all",
                            "-fno-omit-frame-pointer", "-fno-pie", "-no-pie"]
        hub_command += ["-UNDEBUG", str(ROOT / "tests/native/test_p2_hub_heap.c"),
                        str(ROOT / "port/p2/runtime/p2_hub_heap.c"),
                        "-o", str(out / "test-hub-heap")]
        code = run("hub-compile", hub_command, 60)
        if code == 0:
            code = run("hub-execute", [str(out / "test-hub-heap")], 20)
    unchanged = all(hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == digest
                    for name, digest in source_hashes.items())
    if not unchanged:
        code = 1
    receipt = {"passed": code == 0, "source_unchanged": unchanged,
               "scope": "host allocator-routing and real VM tests, not Hub hardware proof",
               "commands": records, "source_sha256": source_hashes}
    (out / "results.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print("Evidence:", out / "results.json")
    return 0 if code == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
