#!/usr/bin/env python3
from pathlib import Path
import re
import sys


MODULE_DIR = Path("modules")


CAPABILITIES_DEF = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\.capabilities = def\(\)")
KEY_RE = re.compile(r'"([^"]+)"\s*:')
STRING_RE = re.compile(r'"([^"]+)"')


def find_function_body(lines, start_index):
    body = []
    for line in lines[start_index + 1 :]:
        if line.strip() == "end":
            return body
        body.append(line)
    return body


def keys_from_body(body):
    keys = []
    for line in body:
        match = KEY_RE.search(line)
        if match:
            keys.append(match.group(1))
    return keys


def strings_from_body(body):
    keys = []
    for line in body:
        keys.extend(STRING_RE.findall(line))
    return keys


def audit_file(path):
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    problems = []

    for index, line in enumerate(lines):
        match = CAPABILITIES_DEF.match(line)
        if not match:
            continue

        module_name = match.group(1)
        capability_keys = keys_from_body(find_function_body(lines, index))
        helper_name = f"{module_name}.required_capability_keys = def()"
        helper_index = text.find(helper_name)
        if helper_index < 0:
            problems.append(f"{path}: missing {module_name}.required_capability_keys()")
            continue

        helper_line_index = text[:helper_index].count("\n")
        helper_keys = strings_from_body(find_function_body(lines, helper_line_index))
        missing = [key for key in capability_keys if key not in helper_keys]
        extra = [key for key in helper_keys if key not in capability_keys]
        if missing:
            problems.append(
                f"{path}: {module_name}.required_capability_keys() misses: {', '.join(missing)}"
            )
        if extra:
            problems.append(
                f"{path}: {module_name}.required_capability_keys() has unknown keys: {', '.join(extra)}"
            )

        if "missing_capability_keys" not in text:
            problems.append(f"{path}: audit does not report missing_capability_keys")

    return problems


def main():
    problems = []
    checked = 0
    for path in sorted(MODULE_DIR.glob("*.be")):
        file_problems = audit_file(path)
        if f".capabilities = def()" in path.read_text(encoding="utf-8"):
            checked += 1
        problems.extend(file_problems)

    for problem in problems:
        print(f"error: {problem}", file=sys.stderr)
    if problems:
        return 1

    print(f"ok: {checked} source modules expose required capability metadata")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
