#!/usr/bin/env python3
from __future__ import annotations

import argparse
import pathlib
import re
import sys
from collections.abc import Sequence


_RUNTIME_RULES: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("unbounded busy loop", re.compile(r"\bwhile\s+true\b")),
    ("scheduled Timer", re.compile(r"\bTimer\s*\.\s*scheduledTimer\b")),
    ("Timer publisher", re.compile(r"\bTimer\s*\.\s*publish\b")),
    ("dispatch timer source", re.compile(r"\bDispatchSource\s*\.\s*makeTimerSource\b")),
    ("Task.sleep", re.compile(r"\bTask\s*\.\s*sleep\s*\(")),
    ("Thread.sleep", re.compile(r"\bThread\s*\.\s*sleep\s*\(")),
    ("usleep", re.compile(r"(?<![A-Za-z0-9_.])usleep\s*\(")),
    ("sleep", re.compile(r"(?<![A-Za-z0-9_.])sleep\s*\(")),
    ("CVDisplayLink", re.compile(r"\bCVDisplayLink\w*")),
    ("CADisplayLink", re.compile(r"\bCADisplayLink\b")),
)


def find_runtime_policy_violations(root: pathlib.Path) -> list[str]:
    root = root.resolve()
    violations: list[str] = []

    if not root.exists():
        raise ValueError(f"runtime source root does not exist: {root}")
    if not root.is_dir():
        raise ValueError(f"runtime source root is not a directory: {root}")

    for path in sorted(root.rglob("*.swift")):
        if not path.is_file():
            continue
        relative = path.relative_to(root)
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            for rule_name, pattern in _RUNTIME_RULES:
                if pattern.search(line):
                    violations.append(f"{relative}:{line_number}: {rule_name}")

    return sorted(violations)


def _audit_command(root: pathlib.Path) -> int:
    try:
        violations = find_runtime_policy_violations(root)
    except (OSError, UnicodeError, ValueError) as error:
        print(f"Performance policy audit failed: {error}", file=sys.stderr)
        return 1

    if violations:
        for violation in violations:
            print(violation, file=sys.stderr)
        return 1

    print("Performance policy checks passed.")
    return 0


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="NotchHub deterministic performance policy")
    subparsers = parser.add_subparsers(dest="command", required=True)

    audit_parser = subparsers.add_parser("audit", help="audit runtime Swift sources")
    audit_parser.add_argument("root", type=pathlib.Path)

    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    if args.command == "audit":
        return _audit_command(args.root)
    raise AssertionError(f"Unhandled command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())
