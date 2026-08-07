#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import pathlib
import re
import statistics
import sys
from collections.abc import Sequence
from dataclasses import dataclass


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

_ALLOWED_SCENARIOS = {"idle", "hover", "stability"}


@dataclass(frozen=True)
class ProcessSample:
    cpu_percent: float
    rss_kib: int
    thread_count: int


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


def parse_ps_sample(line: str) -> ProcessSample:
    fields = line.split()
    if len(fields) != 3:
        raise ValueError("process sample must contain exactly CPU, RSS KiB, and thread count")

    cpu_text, rss_text, thread_text = fields
    if "," in cpu_text:
        raise ValueError("CPU percentage must use a dot decimal separator")

    try:
        cpu_percent = float(cpu_text)
        rss_kib = int(rss_text, 10)
        thread_count = int(thread_text, 10)
    except ValueError as error:
        raise ValueError("invalid process sample numeric value") from error

    if not math.isfinite(cpu_percent) or cpu_percent < 0:
        raise ValueError("CPU percentage must be finite and non-negative")
    if rss_kib < 0:
        raise ValueError("RSS KiB must be non-negative")
    if thread_count <= 0:
        raise ValueError("thread count must be positive")

    return ProcessSample(cpu_percent=cpu_percent, rss_kib=rss_kib, thread_count=thread_count)


def count_ps_thread_rows(output: str) -> int:
    lines = [line for line in output.splitlines() if line.strip()]
    if len(lines) < 2:
        raise ValueError("Darwin ps -M output must contain a header and at least one thread row")
    thread_count = len(lines) - 1
    if thread_count <= 0:
        raise ValueError("thread count must be positive")
    return thread_count


def summarize_samples(samples: Sequence[ProcessSample]) -> dict[str, float | int]:
    if not samples:
        raise ValueError("at least one process sample is required")

    cpu_values = [sample.cpu_percent for sample in samples]
    rss_values = [sample.rss_kib for sample in samples]
    thread_values = [sample.thread_count for sample in samples]

    return {
        "sampleCount": len(samples),
        "cpuMedianPercent": statistics.median(cpu_values),
        "cpuMaxPercent": max(cpu_values),
        "rssMedianKiB": statistics.median(rss_values),
        "rssMaxKiB": max(rss_values),
        "threadMedian": statistics.median(thread_values),
        "threadMax": max(thread_values),
    }


def _first_quartile(values: Sequence[int]) -> float:
    if not values:
        raise ValueError("at least one value is required")
    if len(values) == 1:
        return float(values[0])
    return float(statistics.quantiles(values, n=4, method="inclusive")[0])


def summarize_stability_samples(samples: Sequence[ProcessSample]) -> dict[str, float | int]:
    if not samples:
        raise ValueError("at least one process sample is required")

    rss_values = [sample.rss_kib for sample in samples]
    thread_values = [sample.thread_count for sample in samples]

    return {
        "rssStartKiB": rss_values[0],
        "rssEndKiB": rss_values[-1],
        "rssFirstQuartileKiB": _first_quartile(rss_values),
        "threadStart": thread_values[0],
        "threadEnd": thread_values[-1],
        "threadFirstQuartile": _first_quartile(thread_values),
    }


def validate_config(
    scenario: str,
    warmup_seconds: float,
    duration_seconds: float,
    interval_seconds: float,
    app: pathlib.Path | None,
    attach_pid: int | None,
) -> None:
    if scenario not in _ALLOWED_SCENARIOS:
        raise ValueError(f"unsupported scenario: {scenario}")
    for name, value in (
        ("warmup_seconds", warmup_seconds),
        ("duration_seconds", duration_seconds),
        ("interval_seconds", interval_seconds),
    ):
        if not math.isfinite(float(value)):
            raise ValueError(f"{name} must be finite")
    if warmup_seconds < 0:
        raise ValueError("warmup_seconds must be non-negative")
    if duration_seconds <= 0:
        raise ValueError("duration_seconds must be positive")
    if interval_seconds <= 0:
        raise ValueError("interval_seconds must be positive")
    if interval_seconds > duration_seconds:
        raise ValueError("interval_seconds cannot exceed duration_seconds")
    if (app is None) == (attach_pid is None):
        raise ValueError("provide exactly one of app or attach_pid")
    if attach_pid is not None and attach_pid <= 0:
        raise ValueError("attach_pid must be positive")


def _metric_number(mapping: dict[str, object], key: str, label: str) -> float:
    if key not in mapping:
        raise ValueError(f"{label} is missing metric {key}")
    value = mapping[key]
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f"{label} metric {key} must be numeric")
    numeric = float(value)
    if not math.isfinite(numeric) or numeric < 0:
        raise ValueError(f"{label} metric {key} must be finite and non-negative")
    return numeric


def compare_summary_to_budget(summary: dict[str, object], budget: dict[str, object]) -> list[str]:
    if not budget:
        raise ValueError("budget must contain at least one metric")

    violations: list[str] = []
    for key in sorted(budget):
        limit = _metric_number(budget, key, "budget")
        actual = _metric_number(summary, key, "summary")
        if actual > limit:
            violations.append(f"{key}: actual {actual:g} exceeds budget {limit:g}")
    return violations


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


def _write_json(data: object, output: pathlib.Path | None) -> None:
    text = json.dumps(data, sort_keys=True, indent=2) + "\n"
    if output is None:
        sys.stdout.write(text)
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(text, encoding="utf-8")


def _summarize_command(input_path: pathlib.Path, output: pathlib.Path | None) -> int:
    try:
        samples = [
            parse_ps_sample(line)
            for line in input_path.read_text(encoding="utf-8").splitlines()
            if line.strip()
        ]
        _write_json(summarize_samples(samples), output)
    except (OSError, UnicodeError, ValueError) as error:
        print(f"Performance summary failed: {error}", file=sys.stderr)
        return 1
    return 0


def _check_budget_command(summary_path: pathlib.Path, budget_path: pathlib.Path) -> int:
    try:
        summary = json.loads(summary_path.read_text(encoding="utf-8"))
        budget = json.loads(budget_path.read_text(encoding="utf-8"))
        if not isinstance(summary, dict) or not isinstance(budget, dict):
            raise ValueError("summary and budget must be JSON objects")
        violations = compare_summary_to_budget(summary, budget)
    except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as error:
        print(f"Performance budget check failed: {error}", file=sys.stderr)
        return 1

    if violations:
        for violation in violations:
            print(violation, file=sys.stderr)
        return 1

    print("Performance budget checks passed.")
    return 0


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="NotchHub deterministic performance policy")
    subparsers = parser.add_subparsers(dest="command", required=True)

    audit_parser = subparsers.add_parser("audit", help="audit runtime Swift sources")
    audit_parser.add_argument("root", type=pathlib.Path)

    summarize_parser = subparsers.add_parser("summarize", help="summarize raw ps samples")
    summarize_parser.add_argument("--input", required=True, type=pathlib.Path)
    summarize_parser.add_argument("--output", type=pathlib.Path)

    budget_parser = subparsers.add_parser("check-budget", help="compare a summary JSON object to a budget JSON object")
    budget_parser.add_argument("--summary", required=True, type=pathlib.Path)
    budget_parser.add_argument("--budget", required=True, type=pathlib.Path)

    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    if args.command == "audit":
        return _audit_command(args.root)
    if args.command == "summarize":
        return _summarize_command(args.input, args.output)
    if args.command == "check-budget":
        return _check_budget_command(args.summary, args.budget)
    raise AssertionError(f"Unhandled command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())
