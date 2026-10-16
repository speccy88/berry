#!/usr/bin/env python3
"""Verify lossless recovery patches with a temporary Git index; execute no source."""
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / "experiments/lexar-20261004"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def git(*arguments, env=None):
    result = subprocess.run(["git", "-C", str(ROOT), *arguments], env=env,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if result.returncode:
        raise ValueError(result.stderr.decode("utf-8", errors="replace").strip())
    return result.stdout


def safe_relative(name):
    path = PurePosixPath(name)
    if (path.is_absolute() or ".." in path.parts or ".git" in path.parts or
            not path.parts or any("\\" in part or ":" in part for part in path.parts)):
        raise ValueError("unsafe archive path")
    return name


def verify():
    manifest = json.loads((ARCHIVE / "manifest.json").read_text(encoding="utf-8"))
    base = manifest["base_commit"]
    if not re.fullmatch(r"[0-9a-f]{40}", base):
        raise ValueError("base must be a full commit SHA")
    variants = manifest["variants"]
    if len(variants) != 55 or len({row["id"] for row in variants}) != 55:
        raise ValueError("expected 55 unique recovery variants")
    pairs = {(row["path"], row["recovered_sha256"]) for row in variants}
    if len(pairs) != len(variants):
        raise ValueError("duplicate recovered path/content")
    verified = []
    with tempfile.TemporaryDirectory(prefix="berry-variant-index-") as directory:
        env = os.environ.copy()
        env["GIT_INDEX_FILE"] = str(Path(directory) / "index")
        for row in variants:
            path = safe_relative(row["path"])
            patch_path = safe_relative(row["patch"])
            if not patch_path.startswith("patches/"):
                raise ValueError("patch must be under patches/")
            patch = ARCHIVE / patch_path
            if sha(patch.read_bytes()) != row["patch_sha256"]:
                raise ValueError(row["id"] + ": patch hash mismatch")
            if sha(git("show", base + ":" + path)) != row["base_sha256"]:
                raise ValueError(row["id"] + ": base hash mismatch")
            git("read-tree", base, env=env)
            git("apply", "--cached", "--whitespace=nowarn", str(patch), env=env)
            changed = git("diff", "--cached", "--name-only", base, env=env).decode().splitlines()
            if changed != [path]:
                raise ValueError(row["id"] + ": unexpected changed paths")
            payload = git("show", ":" + path, env=env)
            if sha(payload) != row["recovered_sha256"]:
                raise ValueError(row["id"] + ": reconstructed source hash mismatch")
            if path.endswith(".py"):
                compile(payload, path, "exec", dont_inherit=True)  # Parse only.
            verified.append(row["id"])
    return {"verified_variants": len(verified), "unique_source_paths": len({r['path'] for r in variants}),
            "base_commit": base, "patches_reconstruct_exact_sha256": True,
            "scope": "archive integrity and Python syntax only; no recovered code execution"}


if __name__ == "__main__":
    print(json.dumps(verify(), indent=2))
