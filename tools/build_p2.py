#!/usr/bin/env python3
"""Compile the standard LARGE/XMM p2edge32 image on Linux/x86-64, never load it.

The original checkout may be read-only. All Berry generation/compilation happens
in a fresh source snapshot under --output-dir. --sdk-dir must be a separate,
owned SDK: bootstrap and the required repository library patch MODIFY that SDK.
Only public pinned source is fetched; --offline forbids SDK bootstrap entirely.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shlex
import shutil
import stat
import subprocess
import sys
import time

# Importing our parent-owned bootstrap must not create source-tree bytecode.
sys.dont_write_bytecode = True
import bootstrap_catalina as bootstrap

SDK_COMMIT = "a6f714c539f749c5fc80fa2179f6193622d39c0c"
IMAGE_RELATIVE = Path("build/p2/catalina/xmm/berry_p2.binary")
MIN_IMAGE_BYTES = 65536
MAX_IMAGE_BYTES = 16777216
ROOT = Path(__file__).resolve().parents[1]

# Positive workspace boundary: do not copy neighbouring projects, SDKs, evidence,
# editor state or arbitrary root files. Discover CURRENT inputs, not git archive:
# untracked additions in these source trees are just as important as tracked C.
INPUT_TREES = ("src", "default", "mk", "port/p2", "scripts", "modules", "tests",
               "tools/coc", "tools/p2", "tools/patches", "tools/tests", "tools/container")
INPUT_FILES = ("Makefile", "testall.be", "tools/build_p2.py", "tools/bootstrap_catalina.py",
               "tools/test_p2_heap.py", "tools/test_p2_clock.py",
               "tools/test_p2_vm_state.py", "tools/test_exception_storage.py",
               "tools/test_p2_cog_handles.py", "tools/test_p2_module_config.py",
               "tests/json_test_cases.json")
EXCLUDED_DIRS = {"build", "generate", "__pycache__", "node_modules", "catalina",
                 "flexprop", "sdk", "sdks", "cache", "caches", "secrets", "credentials"}
INPUT_SUFFIXES = {".c", ".h", ".mk", ".py", ".sh", ".ps1", ".be", ".patch",
                  ".spin", ".spin2", ".pasm", ".t", ".inc", ".md", ".txt"}
INPUT_NAMES = {"Makefile", "Dockerfile", "coc"}


class BuildError(Exception):
    def __init__(self, message, code=1):
        super().__init__(message)
        self.code = code


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def overlap(left, right):
    return left.is_relative_to(right) or right.is_relative_to(left)


def validate_paths(source, sdk, output):
    if platform.system() != "Linux" or platform.machine() not in ("x86_64", "AMD64"):
        raise BuildError("Supported host required: Linux/x86-64 (not a skipped/pass result)", 2)
    # The inherited Make/Catalina shell recipes cannot safely represent all POSIX
    # pathnames. Reject, rather than normalize or interpolate shell-sensitive ones.
    for label, path in (("SDK", sdk), ("output", output)):
        if not re.fullmatch(r"/[A-Za-z0-9_./+\-]+", str(path)):
            raise BuildError(f"{label} path must use only letters, digits, / . _ + -", 2)
    if not (source / "Makefile").is_file() or not (source / "src").is_dir():
        raise BuildError("Source checkout is missing Makefile or src", 2)
    if overlap(sdk, source) or overlap(sdk, output):
        raise BuildError("SDK must be separate from source and output; use an owned SDK", 2)
    # Ignored build/ is the sole supported in-repo evidence destination.
    if overlap(output, source) and not output.is_relative_to(source / "build"):
        raise BuildError("Output overlaps source inputs; use external output or source/build/NAME", 2)
    if output == source / "build":
        raise BuildError("Use a new subdirectory of build/, not build/ itself", 2)
    if output.exists() and (not output.is_dir() or any(output.iterdir())):
        raise BuildError("Output must be new or empty; refusing to reuse stale artifacts/results", 2)


def snapshot_source(source, destination):
    """Copy selected regular inputs byte-for-byte; fail closed on source symlinks.

    No hard links: configuration generators and compiler writes cannot affect the
    checkout. Neither ignored/generated headers nor .p2.local.mk are inputs.
    This helper also supplies the isolated source for the host CI checks.
    """
    destination.mkdir(parents=True, exist_ok=False)
    hashes = {}

    def reject_symlinks(path):
        # Checking only the leaf misses e.g. a symlinked port/ above port/p2.
        for part in (path, *path.parents):
            if part == source:
                break
            if part.is_symlink():
                raise BuildError(f"Source path is a symlink: {part.relative_to(source)}")

    def copy(path):
        relative = path.relative_to(source)
        reject_symlinks(path)
        if not path.is_file():
            raise BuildError(f"Input is not a regular file: {relative}")
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        # Hash the exact bytes staged, and verify against the live input below.
        shutil.copyfile(path, target)
        target.chmod(stat.S_IMODE(path.stat().st_mode) | stat.S_IWUSR)
        hashes[relative.as_posix()] = sha256(target)

    for name in INPUT_FILES:
        path = source / name
        if path.exists() or path.is_symlink():
            copy(path)
    for name in INPUT_TREES:
        root = source / name
        reject_symlinks(root)
        if not root.exists():
            continue
        for directory, dirs, files in os.walk(root, followlinks=False):
            dirs[:] = sorted(d for d in dirs if not d.startswith(".")
                             and d.lower() not in EXCLUDED_DIRS)
            for child in dirs:
                if (Path(directory) / child).is_symlink():
                    raise BuildError(f"Source directory is a symlink: {Path(directory) / child}")
            for filename in sorted(files):
                path = Path(directory) / filename
                lower = filename.lower()
                if (filename.startswith(".") or "credential" in lower or "secret" in lower
                        or lower.startswith(("id_rsa", "id_ed25519"))):
                    continue
                if path.suffix in INPUT_SUFFIXES or filename in INPUT_NAMES:
                    copy(path)
    if not hashes:
        raise BuildError("No source inputs discovered")
    verify_source(source, hashes)
    return hashes


def verify_source(source, hashes):
    for name, expected in hashes.items():
        path = source / name
        if path.is_symlink() or not path.is_file() or sha256(path) != expected:
            raise BuildError(f"Source changed during the build: {name}; retry with a stable checkout")


class BuildRun:
    def __init__(self, output, result):
        self.output, self.result = output, result
        (output / "logs").mkdir()
        (output / "home").mkdir()
        # No inherited Make flags, compiler overrides, git credentials, Python
        # imports, shell startup files or active Catalina environment.
        self.env = {"PATH": "/usr/local/bin:/usr/bin:/bin", "HOME": str(output / "home"),
                    "LANG": "C.UTF-8", "LC_ALL": "C.UTF-8", "TZ": "UTC",
                    "PYTHONDONTWRITEBYTECODE": "1", "GIT_CONFIG_NOSYSTEM": "1",
                    "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_TERMINAL_PROMPT": "0",
                    "GIT_OPTIONAL_LOCKS": "0"}  # git status must not refresh the source index.
        result["environment"] = dict(self.env)

    def command(self, name, argv, cwd):
        argv = list(map(str, argv))
        log = Path("logs") / (name + ".log")
        record = {"name": name, "argv": argv, "cwd": str(cwd), "log": str(log),
                  "started_at": utc_now(), "returncode": None}
        self.result["commands"].append(record)
        print("+ " + shlex.join(argv), flush=True)
        with (self.output / log).open("w") as stream:
            try:
                proc = subprocess.run(argv, cwd=cwd, env=self.env, stdin=subprocess.DEVNULL,
                                      stdout=stream, stderr=subprocess.STDOUT, text=True)
                record["returncode"] = proc.returncode
            except OSError as error:
                stream.write(str(error) + "\n")
                record["returncode"] = 127
        record["finished_at"] = utc_now()
        record["log_sha256"] = sha256(self.output / log)
        if record["returncode"]:
            code = record["returncode"]
            raise BuildError(f"{name} failed (exit {code}); see {self.output / log}",
                             code if code > 0 else 128 - code)
        return (self.output / log).read_text(errors="replace")

    def git(self, name, directory, *arguments):
        return self.command(name, ["git", "-c", f"safe.directory={directory}",
                                  "-c", "core.fsmonitor=false", "-C", directory,
                                  *arguments], directory).strip()


def prepare_sdk(run, sdk, snapshot, offline):
    def check_commit(name):
        actual = run.git(name, sdk, "rev-parse", "HEAD")
        if actual != SDK_COMMIT or bootstrap.SOURCE_COMMIT != SDK_COMMIT:
            raise BuildError(f"SDK commit mismatch: expected {SDK_COMMIT}, got {actual}")
        run.result["sdk_commit"] = actual

    def check_bootstrap():
        receipt = json.loads((sdk / "berry-bootstrap.json").read_text())
        tools = bootstrap.verify_tools(sdk)
        if (receipt["source_commit"] != SDK_COMMIT
                or receipt["host_patch_sha256"] != sha256(snapshot / "tools/patches/catalina-linux64.patch")
                or receipt["tools_sha256"] != tools):
            raise BuildError("SDK bootstrap receipt/host patch/tool hashes do not match")
        return tools

    ready = False
    if sdk.exists():
        check_commit("sdk-head-before")  # Never repair a different SDK revision.
        try:
            tools = check_bootstrap()
            ready = True
        except (OSError, ValueError, KeyError, RuntimeError, BuildError):
            pass
    if not ready:
        if offline:
            raise BuildError("Offline: missing or unprepared pinned SDK; network/bootstrap forbidden", 2)
        run.command("sdk-bootstrap", [sys.executable, snapshot / "tools/bootstrap_catalina.py", sdk], snapshot)
        check_commit("sdk-head")
        tools = check_bootstrap()
    run.result["sdk_tools_sha256"] = tools
    run.result["sdk_status_before_patch"] = run.git("sdk-status-before", sdk, "status", "--porcelain", "--untracked-files=normal")
    # Host bootstrap alone is insufficient: these real XMM libraries must export
    # the repository SD diagnostics. This script compiles libraries, not hardware.
    run.command("sdk-patch", ["bash", snapshot / "tools/p2/bootstrap/patch-catalina-p2.sh",
                              sdk, "P2_EDGE", "LARGE", "cx", "direct"], snapshot)
    run.result["sdk_status_after_patch"] = run.git("sdk-status-after", sdk, "status", "--porcelain", "--untracked-files=normal")
    run.result["sdk_inputs_sha256"] = {
        str(path.relative_to(sdk)): sha256(path)
        for tree in ("include", "target/p2", "lib/p2/xmm")
        for path in sorted((sdk / tree).rglob("*")) if path.is_file() and not path.is_symlink()
    }


def compile_image(run, sdk, snapshot):
    image = snapshot / IMAGE_RELATIVE
    if image.exists() or image.is_symlink():
        raise BuildError("Image existed before compilation; refusing stale target")
    started_ns = time.time_ns()
    run.result["target_started_ns"] = started_ns
    run.command("target-build", ["make", "p2", "TOOLCHAIN=catalina", f"CATALINA_DIR={sdk}",
        "P2_PROFILE=xmm", "P2_BOARD=p2edge32", "CATALINA_PLATFORM=P2_EDGE",
        "CATALINA_MODEL=LARGE", "CATALINA_CLIB=-lcx", "CATALINA_SERIAL_LIB=-lpsram",
        "P2_LOCAL_CONFIG=/dev/null", f"PYTHON={sys.executable}", "V=1"], snapshot)
    if image.is_symlink() or not image.is_file():
        raise BuildError("Compiler returned success without a new regular image")
    info = image.stat()
    if not MIN_IMAGE_BYTES < info.st_size <= MAX_IMAGE_BYTES:
        raise BuildError(f"Invalid image size: {info.st_size}; require 64 KiB < image <= 16 MiB")
    # Allow filesystem whole-second timestamp resolution. The empty snapshot and
    # pre-compilation absence check, not timestamps alone, establish freshness.
    if info.st_mtime_ns < (started_ns // 1_000_000_000) * 1_000_000_000:
        raise BuildError("Image timestamp predates this compilation")
    return {"image_path": str(image), "image_bytes": info.st_size,
            "image_sha256": sha256(image), "image_mtime_ns": info.st_mtime_ns}


def main(argv=None, *, source_root=ROOT):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sdk-dir", required=True, type=Path, help="separate, owned pinned SDK (will be prepared)")
    parser.add_argument("--output-dir", required=True, type=Path, help="new or empty evidence directory")
    parser.add_argument("--offline", action="store_true", help="reject network and SDK bootstrap; still prepare P2 libraries")
    args = parser.parse_args(argv)
    source, sdk, output = Path(source_root).resolve(), args.sdk_dir.resolve(), args.output_dir.resolve()
    result = {"schema_version": 1, "status": "failed", "scope": "target compilation only; HIL not performed",
              "started_at": utc_now(), "source_root": str(source), "sdk_dir": str(sdk),
              "sdk_url": bootstrap.SOURCE_URL, "sdk_tag": bootstrap.SOURCE_TAG,
              "offline": args.offline, "host": {"system": platform.system(), "machine": platform.machine(),
                                                "python": platform.python_version()},
              "commands": []}
    initialized, code = False, 1
    try:
        validate_paths(source, sdk, output)
        output.mkdir(parents=True, exist_ok=True)
        initialized = True
        run = BuildRun(output, result)
        result["source_head"] = run.git("source-head", source, "rev-parse", "HEAD")
        if not re.fullmatch(r"[0-9a-f]{40}", result["source_head"]):
            raise BuildError("Cannot obtain source HEAD from the original checkout")
        result["source_status"] = run.git("source-status", source, "status", "--porcelain", "--untracked-files=normal")
        result["source_dirty"] = bool(result["source_status"])
        snapshot = output / "source"
        result["input_sha256"] = snapshot_source(source, snapshot)
        result["snapshot_path"] = str(snapshot)
        prepare_sdk(run, sdk, snapshot, args.offline)
        image = compile_image(run, sdk, snapshot)
        verify_source(source, result["input_sha256"])
        if run.git("source-head-after", source, "rev-parse", "HEAD") != result["source_head"]:
            raise BuildError("Source HEAD changed during the build")
        result.update(image)
        result.update(status="success", source_inputs_unchanged=True)
        code = 0
    except (BuildError, OSError, ValueError, KeyError, RuntimeError) as error:
        result["error"] = str(error)
        code = error.code if isinstance(error, BuildError) else 1
        print("error: " + str(error), file=sys.stderr, flush=True)
    finally:
        if initialized:
            # Bootstrap component output lives in the SDK. Retain it even when
            # a failed ephemeral builder is removed; never invent missing logs.
            for name in ("berry-bootstrap.log", "berry-bootstrap.json"):
                path = sdk / name
                if path.is_file() and not path.is_symlink():
                    shutil.copyfile(path, output / "logs" / name)
            result.update(finished_at=utc_now(), exit_code=code)
            temporary = output / "result.json.tmp"
            temporary.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
            temporary.replace(output / "result.json")
            print(f"{result['status']}: {output / 'result.json'}", flush=True)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
