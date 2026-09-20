#!/usr/bin/env python3
"""Copy CI receipts from private build evidence into a collector-safe tree."""
import argparse
import os
from pathlib import Path
import shutil
import stat
import sys
import tempfile


class ExportError(Exception):
    pass


def regular(path):
    mode = path.lstat().st_mode
    if stat.S_ISLNK(mode):
        raise ExportError(f"symlink is not permitted: {path}")
    return stat.S_ISREG(mode)


def collect(source_build):
    if source_build.is_symlink() or not source_build.is_dir():
        raise ExportError("source build must be a real directory")
    files = []
    def walk_error(error):
        raise ExportError(f"cannot read source build: {error.filename}: {error.strerror}")

    for directory, names, filenames in os.walk(source_build, followlinks=False, onerror=walk_error):
        root = Path(directory)
        for name in names:
            child = root / name
            if child.is_symlink():
                raise ExportError(f"symlink is not permitted: {child}")
        for name in filenames:
            path = root / name
            if path.is_symlink():
                raise ExportError(f"symlink is not permitted: {path}")
            if name == "results.json" or name.endswith(".log"):
                if not regular(path):
                    raise ExportError(f"artifact is not a regular file: {path}")
                files.append(path)
    return sorted(files)


def validate_path(path, label):
    if ".." in path.parts:
        raise ExportError(f"{label} path traversal is not permitted")
    current = path
    while True:
        if current.is_symlink():
            raise ExportError(f"symlink is not permitted in {label} path: {current}")
        if current == current.parent:
            break
        current = current.parent
    return path.absolute()


def make_export_directory(path, temporary):
    path.mkdir(parents=True, exist_ok=True)
    while True:
        path.chmod(0o755)
        if path == temporary:
            break
        path = path.parent


def export(source_build, output_dir, required_results, required_logs):
    source_build = validate_path(source_build, "source build")
    output_dir = validate_path(output_dir, "output")
    if not source_build.exists():
        raise ExportError(f"source build does not exist: {source_build}")
    if output_dir == source_build or output_dir.is_relative_to(source_build):
        raise ExportError("output directory must be outside private source build")
    files = collect(source_build)
    results = [path for path in files if path.name == "results.json"]
    logs = [path for path in files if path.name.endswith(".log")]
    if len(results) < required_results:
        raise ExportError(f"required results.json artifacts missing: need {required_results}, found {len(results)}")
    if len(logs) < required_logs:
        raise ExportError(f"required log artifacts missing: need {required_logs}, found {len(logs)}")
    if output_dir.exists():
        raise ExportError(f"output directory already exists: {output_dir}")
    output_dir.parent.mkdir(parents=True, exist_ok=True)
    temporary = Path(tempfile.mkdtemp(prefix=".artifacts-", dir=output_dir.parent))
    try:
        for source in files:
            target = temporary / source.relative_to(source_build)
            make_export_directory(target.parent, temporary)
            shutil.copyfile(source, target)
            target.chmod(0o644)
        temporary.rename(output_dir)
    except BaseException:
        shutil.rmtree(temporary, ignore_errors=True)
        raise
    return len(results), len(logs)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-build", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--required-results", type=int, required=True)
    parser.add_argument("--required-logs", type=int, default=1)
    args = parser.parse_args(argv)
    if args.required_results < 1 or args.required_logs < 1:
        parser.error("required artifact counts must be positive")
    try:
        results, logs = export(args.source_build, args.output_dir,
                               args.required_results, args.required_logs)
    except (ExportError, OSError) as error:
        print(f"CI evidence export failed: {error}", file=sys.stderr)
        return 1
    print(f"Exported {results} results.json and {logs} log files to {args.output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
