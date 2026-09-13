#!/usr/bin/env python3
"""Build the source-pinned Catalina SDK; never load firmware or access a device."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess

SOURCE_URL = "https://github.com/rosshigson/Catalina.git"
SOURCE_TAG = "v8.8.9"
SOURCE_COMMIT = "a6f714c539f749c5fc80fa2179f6193622d39c0c"
REQUIRED_TOOLS = ("catalina", "lcc", "cake", "p2asm", "spinnaker",
                  "catoptimize", "cmmoptimize")


def checked_output(argv, **kwargs):
    return subprocess.check_output(argv, text=True, **kwargs).strip()


def prepare_source(destination):
    if not destination.exists():
        subprocess.run([
            "git", "-c", "core.hooksPath=/dev/null", "clone", "--depth", "1",
            "--branch", SOURCE_TAG, "--single-branch", SOURCE_URL,
            str(destination),
        ], check=True)
    actual = checked_output(["git", "-C", str(destination), "rev-parse", "HEAD"])
    if actual != SOURCE_COMMIT:
        raise RuntimeError(f"SDK source mismatch: expected {SOURCE_COMMIT}, got {actual}")
    # The distribution loses executable bits. Do not use its permissions script:
    # that script makes the entire SDK world-writable, which is unnecessary.
    for directory in (destination / "source", destination / "bin"):
        for path in directory.rglob("*"):
            if path.is_file() and not path.is_symlink():
                with path.open("rb") as stream:
                    is_script = stream.read(2) == b"#!"
                if is_script:
                    path.chmod(stat.S_IMODE(path.stat().st_mode) | stat.S_IXUSR)


def verify_tools(destination):
    tools = {}
    optimizer_names = [f"catopt_{i}" for i in range(14)]
    optimizer_names += [f"cmmopt_{i}" for i in range(15)]
    for name in (*REQUIRED_TOOLS, *optimizer_names):
        path = destination / "bin" / name
        if not path.is_file() or not os.access(path, os.X_OK):
            raise RuntimeError(f"SDK build did not produce executable {path}")
        content = path.read_bytes()
        if not content.startswith(b"\x7fELF"):
            raise RuntimeError(f"Not a native Linux executable: {path}")
        tools[name] = hashlib.sha256(content).hexdigest()
    return tools


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path, help="new or pinned Catalina checkout")
    args = parser.parse_args()
    destination = args.destination.resolve()
    prepare_source(destination)
    environment = dict(os.environ)
    environment["LCCDIR"] = str(destination)
    environment["PATH"] = str(destination / "bin") + os.pathsep + environment["PATH"]
    log_path = destination / "berry-bootstrap.log"
    patch_path = Path(__file__).with_name("patches") / "catalina-linux64.patch"
    apply = ["git", "-C", str(destination), "apply"]
    probe = subprocess.run(apply + ["--check", str(patch_path)], capture_output=True)
    if probe.returncode == 0:
        subprocess.run(apply + [str(patch_path)], check=True)
    else:
        subprocess.run(apply + ["--reverse", "--check", str(patch_path)], check=True)
    with log_path.open("w") as log:
        for component in ("catalina", "cake", "catoptimize", "p2asm_src", "lcc", "openspin"):
            directory = destination / "source" / component
            log.write(f"\nBUILD {component}\n")
            log.flush()
            subprocess.run(["bash", "./build_all"], cwd=directory, env=environment,
                           stdout=log, stderr=subprocess.STDOUT, check=True)
            if component == "catoptimize":
                # Upstream copy_all unnecessarily invokes sudo in an owned SDK.
                names = ["catoptimize", "cmmoptimize"]
                names += [f"catopt_{i}" for i in range(14)]
                names += [f"cmmopt_{i}" for i in range(15)]
                for name in names:
                    shutil.copy2(directory / name, destination / "bin" / name)
    # Upstream build_binaries does not fail fast. Its exit status is insufficient;
    # every compiler/optimizer must exist, and the consuming P2 build is another gate.
    tools = verify_tools(destination)
    receipt = {"source_url": SOURCE_URL, "source_tag": SOURCE_TAG,
               "source_commit": SOURCE_COMMIT, "tools_sha256": tools,
               "host_patch_sha256": hashlib.sha256(patch_path.read_bytes()).hexdigest(),
               "log": str(log_path), "scope": "SDK build only; no target execution"}
    receipt_path = destination / "berry-bootstrap.json"
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({"receipt": str(receipt_path), **receipt}, indent=2))


if __name__ == "__main__":
    main()
