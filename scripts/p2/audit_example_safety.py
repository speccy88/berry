#!/usr/bin/env python3
from pathlib import Path
import importlib.util
import re
import subprocess
import sys
import tempfile


EXAMPLE_DIR = Path("examples")
UNSAFE_LINE_RE = re.compile(r"^\s*(try|except|for)\b")
DONE_MARKER_RE = re.compile(r"print\(\s*['\"][^'\"]+\bdone['\"]")
SUPPORT_ONLY = {
    Path("examples/core/run_file.be"),
}
MAKE_TARGET_RE = re.compile(r"^([A-Za-z0-9_.-]+):")
TARGET_DIR_RE = re.compile(r'--target-dir\s+"([^"]+)"')
FILE_RE = re.compile(r'--file\s+"([^"]+)"')
TARGET_FILE_RE = re.compile(r'--target-file\s+"([^"]+)=([^"]+)"')
BINARY_TARGET_FILE_RE = re.compile(r'--binary-target-file\s+"([^"]+)=([^"]+)"')
RECURSIVE_DIRECTORY_RE = re.compile(r'--recursive-directory\s+"([^"]+)"')
RUN_FILE_RE = re.compile(r'run_file\("([^"]+)"\)')
FOCUSED_SUITE_STAGING_TARGETS = {
    "bec-abi-min": ("p2-sd-bec-abi-min-smoke",),
    "bec-fallback-min": ("p2-sd-bec-fallback-min-smoke",),
    "cog-closure": ("p2-sd-cog-closure-smoke",),
    "cog-closure-min": ("p2-sd-cog-closure-min-smoke",),
    "cog-policy-min": ("p2-smoke-cog-policy-min",),
    "core-builtins-min": ("p2-sd-core-builtins-min-smoke",),
    "ipc-policy-min": ("p2-smoke-ipc-policy-min",),
    "libraries-lazy-min": ("p2-smoke-libraries-lazy-min",),
    "p2-api": ("p2-sd-p2-api-smoke",),
    "p2compat": ("p2-sd-p2compat-smoke",),
    "p2ipc": ("p2-sd-ipc-smoke",),
    "p2mem-policy-min": ("p2-smoke-p2mem-policy-min",),
    "pasm-policy-min": ("p2-smoke-pasm-policy-min",),
    "priority1-4-min": ("p2-smoke-priority1-4-min",),
    "priority2": (
        "p2-sd-p2-api-smoke",
        "p2-smoke-smartpins-normal-pin",
        "p2-smoke-smartpins-counter-modes",
        "p2-smoke-smartpins-output-modes",
        "p2-smoke-smartpins-adc-dac-native",
        "p2-smoke-smartpins-quadrature-motion",
        "p2-smoke-smartpins-async-rx",
        "p2-smoke-smartpins-sync-diag",
    ),
    "priority3": ("p2-sd-pasm-layout-smoke", "p2-smoke-pasm-policy-min"),
    "priority4": (
        "p2-sd-p2compat-smoke",
        "p2-sd-cog-closure-min-smoke",
        "p2-sd-ipc-smoke",
    ),
    "sd-file-min": ("p2-smoke-sd-file-min",),
    "sd-file-core-min": ("p2-sd-file-core-min-smoke",),
    "stdlib-min": ("p2-sd-stdlib-min-smoke",),
    "smartpins-adc-dac-native": ("p2-smoke-smartpins-adc-dac-native",),
    "smartpins-adc-variant-matrix": ("p2-smoke-smartpins-adc-variant-matrix",),
    "smartpins-async-buffer-boundary": ("p2-smoke-smartpins-async-buffer-boundary",),
    "smartpins-async-rx": ("p2-smoke-smartpins-async-rx",),
    "smartpins-counter-modes": ("p2-smoke-smartpins-counter-modes",),
    "smartpins-counter-timer-matrix": ("p2-smoke-smartpins-counter-timer-matrix",),
    "smartpins-loopback": ("p2-smoke-smartpins-loopback",),
    "smartpins-normal-pin": ("p2-smoke-smartpins-normal-pin",),
    "smartpins-output-modes": ("p2-smoke-smartpins-output-modes",),
    "smartpins-quadrature-motion": ("p2-smoke-smartpins-quadrature-motion",),
    "smartpins-quadrature-static": ("p2-smoke-smartpins-quadrature-static",),
    "smartpins-sync-diag": ("p2-smoke-smartpins-sync-diag",),
    "task": ("p2-sd-task-smoke",),
}


def fat83_key(path_text: str) -> str:
    name = Path(path_text).name.upper()
    if "." in name:
        stem, ext = name.rsplit(".", 1)
    else:
        stem, ext = name, ""
    return f"{stem[:8]}.{ext[:3]}"


def target_path(target_dir: str, remote: str) -> str:
    if remote.startswith("/"):
        return remote
    return "/" + "/".join(part for part in [target_dir.strip("/"), remote.strip("/")] if part)


def is_literal_repo_path(path_text: str) -> bool:
    return "$(" not in path_text and not path_text.startswith("/")


def is_focused_p2_staging_target(name: str) -> bool:
    if name.startswith("p2-sd-examples-"):
        return True
    if name.startswith("p2-sd-") and "smoke" in name:
        return True
    return name.startswith("p2-smoke-")


def add_recursive_staging(staged: set[str], target_dir: str, source_dir: str) -> None:
    source_root = Path(source_dir)
    if not source_root.is_dir():
        return
    for path in source_root.rglob("*.be"):
        staged.add(target_path(target_dir, str(path.relative_to(source_root))))


def collect_focused_p2_staging(problems: list[str]) -> dict[str, set[str]]:
    makefile = Path("mk/p2.mk")
    targets: dict[str, set[str]] = {}
    if not makefile.is_file():
        problems.append("mk/p2.mk: missing makefile for focused P2 staging audit")
        return targets

    current_target: str | None = None
    current_target_dir: str | None = None
    staged_for_collision: dict[tuple[str, str], tuple[str, str]] = {}

    for lineno, raw_line in enumerate(makefile.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw_line.strip()
        header = MAKE_TARGET_RE.match(line)
        if header:
            target_name = header.group(1)
            current_target = target_name if is_focused_p2_staging_target(target_name) else None
            current_target_dir = None
            staged_for_collision = {}
            if current_target is not None:
                targets.setdefault(current_target, set())
            continue
        if current_target is None:
            continue
        if line and not raw_line.startswith(("\t", " ")):
            current_target = None
            current_target_dir = None
            staged_for_collision = {}
            continue

        target_dir_match = TARGET_DIR_RE.search(line)
        if target_dir_match:
            current_target_dir = target_dir_match.group(1)
        if current_target_dir is None:
            continue

        recursive_directory_match = RECURSIVE_DIRECTORY_RE.search(line)
        if recursive_directory_match:
            source_dir = recursive_directory_match.group(1)
            if is_literal_repo_path(source_dir) and not Path(source_dir).is_dir():
                problems.append(
                    f"mk/p2.mk:{lineno}: {current_target} stages missing source directory {source_dir}; "
                    "remove the recursive upload or fix the source path before running the focused P2 target"
                )
            elif is_literal_repo_path(source_dir):
                add_recursive_staging(targets[current_target], current_target_dir, source_dir)
            continue

        remote_name: str | None = None
        source_name: str | None = None
        binary_target_file_match = BINARY_TARGET_FILE_RE.search(line)
        target_file_match = binary_target_file_match or TARGET_FILE_RE.search(line)
        if target_file_match:
            source_name = target_file_match.group(1)
            remote_name = target_path(current_target_dir, target_file_match.group(2))
        else:
            file_match = FILE_RE.search(line)
            if file_match:
                source_name = file_match.group(1)
                remote_name = target_path(current_target_dir, Path(source_name).name)

        if remote_name is None or source_name is None:
            continue
        targets[current_target].add(remote_name)
        if (
            binary_target_file_match is None
            and is_literal_repo_path(source_name)
            and not Path(source_name).is_file()
        ):
            problems.append(
                f"mk/p2.mk:{lineno}: {current_target} stages missing source file {source_name}; "
                "remove the upload or fix the source path before running the focused P2 target"
            )
        directory = str(Path(remote_name).parent)
        key = (directory, fat83_key(remote_name))
        if key in staged_for_collision:
            prior_source, prior_remote = staged_for_collision[key]
            problems.append(
                f"mk/p2.mk:{lineno}: {current_target} stages {source_name} as {remote_name}, "
                f"which collides with {prior_source} as {prior_remote} under focused P2 target "
                f"directory {directory} 8.3 key {key[1]}; use distinct --target-file aliases"
            )
        else:
            staged_for_collision[key] = (source_name, remote_name)

    return targets


def audit_focused_p2_staging(problems: list[str]) -> None:
    collect_focused_p2_staging(problems)


def example_staging_target_for_suite(suite_name: str) -> str:
    return "p2-sd-examples-" + suite_name.removeprefix("examples-") + "-smoke"


def load_repl_smoke_suites(problems: list[str]) -> dict[str, list[tuple]]:
    path = Path("scripts/p2/repl_smoke.py")
    if not path.is_file():
        problems.append("scripts/p2/repl_smoke.py: missing runner for focused example suite audit")
        return {}
    spec = importlib.util.spec_from_file_location("p2_repl_smoke_audit", path)
    if spec is None or spec.loader is None:
        problems.append("scripts/p2/repl_smoke.py: cannot load runner for focused example suite audit")
        return {}
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    suites = getattr(module, "SUITES", None)
    if not isinstance(suites, dict):
        problems.append("scripts/p2/repl_smoke.py: SUITES is missing or not a map")
        return {}
    return suites


def audit_focused_example_suite_staging(
    problems: list[str],
    staged_by_target: dict[str, set[str]] | None = None,
) -> None:
    if staged_by_target is None:
        staged_by_target = collect_focused_p2_staging(problems)
    suites = load_repl_smoke_suites(problems)
    for suite_name, commands in suites.items():
        if not suite_name.startswith("examples-"):
            continue
        target_name = example_staging_target_for_suite(suite_name)
        staged_paths = staged_by_target.get(target_name)
        if staged_paths is None:
            problems.append(
                f"scripts/p2/repl_smoke.py: suite {suite_name} has no matching {target_name} staging target"
            )
            continue
        for command in commands:
            if not command:
                continue
            command_text = command[0]
            if not isinstance(command_text, str):
                continue
            match = RUN_FILE_RE.search(command_text)
            if match is None:
                continue
            remote_path = match.group(1)
            if remote_path.startswith("/berry/examples/") and remote_path not in staged_paths:
                problems.append(
                    f"scripts/p2/repl_smoke.py: suite {suite_name} runs {remote_path}, "
                    f"but {target_name} does not stage that target path"
                )


def run_file_paths(commands: list[tuple]) -> list[str]:
    paths = []
    for command in commands:
        if not command:
            continue
        command_text = command[0]
        if not isinstance(command_text, str):
            continue
        for match in RUN_FILE_RE.finditer(command_text):
            paths.append(match.group(1))
    return paths


def audit_focused_test_suite_staging(
    problems: list[str],
    staged_by_target: dict[str, set[str]] | None = None,
) -> None:
    if staged_by_target is None:
        staged_by_target = collect_focused_p2_staging(problems)
    suites = load_repl_smoke_suites(problems)
    for suite_name, target_names in FOCUSED_SUITE_STAGING_TARGETS.items():
        commands = suites.get(suite_name)
        if commands is None:
            problems.append(
                f"scripts/p2/repl_smoke.py: focused staging audit maps missing suite {suite_name}"
            )
            continue
        staged_paths = set()
        missing_targets = []
        for target_name in target_names:
            target_paths = staged_by_target.get(target_name)
            if target_paths is None:
                missing_targets.append(target_name)
            else:
                staged_paths.update(target_paths)
        if missing_targets:
            problems.append(
                f"scripts/p2/repl_smoke.py: suite {suite_name} maps to missing focused staging "
                f"target(s) {', '.join(missing_targets)}"
            )
            continue
        for remote_path in run_file_paths(commands):
            if remote_path.startswith(("/tests/p2/", "/modules/")) and remote_path not in staged_paths:
                problems.append(
                    f"scripts/p2/repl_smoke.py: suite {suite_name} runs {remote_path}, "
                    f"but focused staging target(s) {', '.join(target_names)} do not stage that path"
                )


def main() -> int:
    problems = []
    checked = 0

    example_paths = sorted(EXAMPLE_DIR.rglob("*.be"))
    with tempfile.TemporaryDirectory(prefix="p2-example-compile.") as tmp:
        tmpdir = Path(tmp)
        for path in example_paths:
            output = tmpdir / (str(path).replace("/", "__") + ".bec")
            result = subprocess.run(
                ["./berry", "-c", str(path), "-o", str(output)],
                check=False,
                capture_output=True,
                text=True,
            )
            if result.returncode != 0:
                detail = (result.stderr or result.stdout).strip().splitlines()
                suffix = f": {detail[-1]}" if detail else ""
                problems.append(f"{path}: host compile failed{suffix}")

    for path in example_paths:
        checked += 1
        text = path.read_text(encoding="utf-8")
        for lineno, line in enumerate(text.splitlines(), start=1):
            match = UNSAFE_LINE_RE.match(line)
            if match:
                problems.append(f"{path}:{lineno}: current P2 image unsafe example syntax: {match.group(1)}")
        if path not in SUPPORT_ONLY and not DONE_MARKER_RE.search(text):
            problems.append(f"{path}: missing explicit final done marker")

    staged_by_target = collect_focused_p2_staging(problems)
    audit_focused_example_suite_staging(problems, staged_by_target)
    audit_focused_test_suite_staging(problems, staged_by_target)

    for problem in problems:
        print(f"error: {problem}", file=sys.stderr)
    if problems:
        return 1

    runnable = checked - len(SUPPORT_ONLY)
    print(
        f"ok: {checked} P2 examples compile locally; {runnable} runnable examples avoid "
        "current-image-unsafe try/except/for syntax, have final done markers, "
        "and focused P2 staging uses existing sources, matches mapped runner suites, "
        "and avoids direct 8.3 collisions"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
