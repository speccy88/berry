#!/usr/bin/env python3
import argparse
from collections import Counter
from pathlib import Path
import re
import sys


WARNING_RE = re.compile(r"\bwarning\b", re.IGNORECASE)
HIGH_RISK_RE = re.compile(
    r"(target[- ]width|pointer.*integer|integer.*pointer|"
    r"incompatible pointer|implicit declaration|cast.*different size)",
    re.IGNORECASE,
)
REVIEW_RE = re.compile(
    r"(overflow in converting constant expression|unsigned operand of unary -)",
    re.IGNORECASE,
)


def classify(line):
    lowered = line.lower()
    if HIGH_RISK_RE.search(line):
        return "high_risk_width_or_abi"
    if REVIEW_RE.search(line):
        return "reviewed_constant_width"
    if "missing return value" in lowered:
        return "missing_return"
    if "expression with no effect" in lowered:
        return "no_effect"
    if "static function" in lowered and "not used" in lowered:
        return "unused_static"
    if "assignment to array parameter" in lowered:
        return "array_parameter_assignment"
    if "hides previous declaration" in lowered:
        return "hides_declaration"
    if re.match(r"\s*0 errors \d+ warnings", line):
        return "compiler_summary"
    return "other"


def warning_lines(path):
    for lineno, line in enumerate(path.read_text(errors="replace").splitlines(), 1):
        if WARNING_RE.search(line):
            yield lineno, line


def main():
    parser = argparse.ArgumentParser(
        description="Audit Catalina P2 build logs for high-risk warning classes."
    )
    parser.add_argument(
        "logs",
        nargs="*",
        default=[str(path) for path in sorted(Path("build/p2/catalina").glob("*/p2_build.log"))],
        help="Build log files to audit. Defaults to build/p2/catalina/*/p2_build.log.",
    )
    args = parser.parse_args()

    paths = [Path(log) for log in args.logs]
    missing = [str(path) for path in paths if not path.is_file()]
    if missing:
        for path in missing:
            print(f"error: missing build log: {path}", file=sys.stderr)
        return 1
    if not paths:
        print("error: no Catalina build logs found", file=sys.stderr)
        return 1

    total = 0
    high_risk = []
    counts = Counter()
    per_log = {}
    for path in paths:
        log_count = 0
        for lineno, line in warning_lines(path):
            category = classify(line)
            counts[category] += 1
            total += 1
            log_count += 1
            if category == "high_risk_width_or_abi":
                high_risk.append((path, lineno, line))
        per_log[path] = log_count

    print("Catalina warning audit:")
    for path in paths:
        print(f"  {path}: {per_log[path]} warning lines")
    print(f"  total_warning_lines: {total}")
    for category, count in sorted(counts.items()):
        print(f"  {category}: {count}")

    if high_risk:
        print("error: high-risk target-width or pointer/integer warnings found", file=sys.stderr)
        for path, lineno, line in high_risk:
            print(f"{path}:{lineno}: {line}", file=sys.stderr)
        return 1

    print("ok: no target-width or pointer/integer ABI warning lines found")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
