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
from decimal import Decimal


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
_SIZE_METRICS = ("appSizeBytes", "dmgSizeBytes", "executableSizeBytes")
_BASELINE_SCHEMA_VERSION = 1
_FEATURE_SIZE_BUDGET_SCHEMA_VERSION = 1
_FEATURE_SIZE_BUDGET_KEYS = {
    "schemaVersion",
    "featureId",
    "baselineId",
    "evidence",
    "allowanceBytes",
}
_FEATURE_SIZE_EVIDENCE_KEYS = {
    "sourceCommit",
    "workflowRunId",
    "artifactId",
    "summary",
}


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


def _metric_integer(mapping: dict[str, object], key: str, label: str) -> int:
    if key not in mapping:
        raise ValueError(f"{label} is missing metric {key}")
    value = mapping[key]
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise ValueError(f"{label} metric {key} must be a non-negative integer")
    return value


def _mapping_value(mapping: dict[str, object], key: str, label: str) -> dict[str, object]:
    if key not in mapping or not isinstance(mapping[key], dict):
        raise ValueError(f"{label} must contain object {key}")
    return mapping[key]  # type: ignore[return-value]


def _require_exact_size_metrics(mapping: dict[str, object], label: str) -> None:
    if set(mapping) != set(_SIZE_METRICS):
        raise ValueError(f"{label} must contain exactly the required size metrics")
    for key in _SIZE_METRICS:
        _metric_integer(mapping, key, label)


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


def compare_size_summary_to_baseline(
    summary: dict[str, object], baseline: dict[str, object]
) -> list[str]:
    schema_version = baseline.get("schemaVersion")
    if isinstance(schema_version, bool) or not isinstance(schema_version, int):
        raise ValueError("baseline schemaVersion must be an integer")
    if schema_version != _BASELINE_SCHEMA_VERSION:
        raise ValueError(
            f"unsupported baseline schemaVersion {schema_version}; expected {_BASELINE_SCHEMA_VERSION}"
        )

    size = _mapping_value(baseline, "size", "baseline")
    baseline_summary = _mapping_value(size, "summary", "baseline size")
    budget = _mapping_value(size, "budget", "baseline size")
    ceilings = _mapping_value(budget, "absoluteCeilingBytes", "baseline size budget")

    expected_metrics = set(_SIZE_METRICS)
    if set(baseline_summary) != expected_metrics:
        raise ValueError("baseline size summary must contain exactly the required size metrics")
    if set(ceilings) != expected_metrics:
        raise ValueError("baseline size absolute ceilings must contain exactly the required size metrics")

    relative_metrics_value = budget.get("relativeRegressionMetrics")
    if not isinstance(relative_metrics_value, list) or not relative_metrics_value:
        raise ValueError("baseline size relativeRegressionMetrics must be a non-empty array")
    if any(not isinstance(value, str) for value in relative_metrics_value):
        raise ValueError("baseline size relativeRegressionMetrics must contain only metric names")
    relative_metrics = set(relative_metrics_value)
    if len(relative_metrics) != len(relative_metrics_value):
        raise ValueError("baseline size relativeRegressionMetrics must not contain duplicates")
    if not relative_metrics.issubset(expected_metrics):
        raise ValueError("baseline size relativeRegressionMetrics contains an unknown metric")

    regression_value = budget.get("maxRegressionPercent")
    if isinstance(regression_value, bool) or not isinstance(regression_value, (int, float)):
        raise ValueError("baseline size maxRegressionPercent must be numeric")
    regression_float = float(regression_value)
    if not math.isfinite(regression_float) or regression_float < 0:
        raise ValueError("baseline size maxRegressionPercent must be finite and non-negative")
    regression_percent = Decimal(str(regression_value))

    violations: list[str] = []
    for key in _SIZE_METRICS:
        actual = _metric_integer(summary, key, "size summary")
        baseline_bytes = _metric_integer(baseline_summary, key, "baseline size summary")
        absolute_ceiling = _metric_integer(ceilings, key, "baseline size absolute ceilings")
        if baseline_bytes <= 0:
            raise ValueError(f"baseline size summary metric {key} must be positive")
        if absolute_ceiling < baseline_bytes:
            raise ValueError(f"baseline size absolute ceiling for {key} cannot be below baseline")

        if actual > absolute_ceiling:
            violations.append(
                f"{key}: actual {actual} exceeds absolute ceiling {absolute_ceiling}"
            )

        if key in relative_metrics:
            relative_ceiling = (
                Decimal(baseline_bytes)
                * (Decimal(100) + regression_percent)
                / Decimal(100)
            )
            if Decimal(actual) > relative_ceiling:
                violations.append(
                    f"{key}: actual {actual} exceeds {regression_value:g}% regression allowance "
                    f"from baseline {baseline_bytes}"
                )

    return violations


def compare_size_summary_to_feature_budget(
    summary: dict[str, object],
    baseline: dict[str, object],
    feature_budget: dict[str, object],
) -> list[str]:
    if set(feature_budget) != _FEATURE_SIZE_BUDGET_KEYS:
        raise ValueError("feature size budget must contain exactly the required top-level keys")

    schema_version = feature_budget.get("schemaVersion")
    if isinstance(schema_version, bool) or not isinstance(schema_version, int):
        raise ValueError("feature size budget schemaVersion must be an integer")
    if schema_version != _FEATURE_SIZE_BUDGET_SCHEMA_VERSION:
        raise ValueError(
            "unsupported feature size budget schemaVersion "
            f"{schema_version}; expected {_FEATURE_SIZE_BUDGET_SCHEMA_VERSION}"
        )

    feature_id = feature_budget.get("featureId")
    if not isinstance(feature_id, str) or not feature_id.strip():
        raise ValueError("feature size budget featureId must be a non-empty string")

    baseline_id = baseline.get("baselineId")
    if not isinstance(baseline_id, str) or not baseline_id:
        raise ValueError("baseline baselineId must be a non-empty string")
    feature_baseline_id = feature_budget.get("baselineId")
    if not isinstance(feature_baseline_id, str) or feature_baseline_id != baseline_id:
        raise ValueError("feature size budget baselineId must match the immutable baseline")

    baseline_schema = baseline.get("schemaVersion")
    if isinstance(baseline_schema, bool) or not isinstance(baseline_schema, int):
        raise ValueError("baseline schemaVersion must be an integer")
    if baseline_schema != _BASELINE_SCHEMA_VERSION:
        raise ValueError(
            f"unsupported baseline schemaVersion {baseline_schema}; expected {_BASELINE_SCHEMA_VERSION}"
        )

    size = _mapping_value(baseline, "size", "baseline")
    baseline_summary = _mapping_value(size, "summary", "baseline size")
    baseline_policy = _mapping_value(size, "budget", "baseline size")
    ceilings = _mapping_value(
        baseline_policy,
        "absoluteCeilingBytes",
        "baseline size budget",
    )
    _require_exact_size_metrics(baseline_summary, "baseline size summary")
    _require_exact_size_metrics(ceilings, "baseline size absolute ceilings")
    _require_exact_size_metrics(summary, "size summary")

    for key in _SIZE_METRICS:
        baseline_bytes = _metric_integer(baseline_summary, key, "baseline size summary")
        absolute_ceiling = _metric_integer(ceilings, key, "baseline size absolute ceilings")
        if baseline_bytes <= 0:
            raise ValueError(f"baseline size summary metric {key} must be positive")
        if absolute_ceiling < baseline_bytes:
            raise ValueError(f"baseline size absolute ceiling for {key} cannot be below baseline")

    allowance = _mapping_value(feature_budget, "allowanceBytes", "feature size budget")
    _require_exact_size_metrics(allowance, "feature size allowance")

    evidence = _mapping_value(feature_budget, "evidence", "feature size budget")
    if set(evidence) != _FEATURE_SIZE_EVIDENCE_KEYS:
        raise ValueError("feature size evidence must contain exactly the required keys")

    source_commit = evidence.get("sourceCommit")
    if not isinstance(source_commit, str) or re.fullmatch(r"[0-9a-f]{40}", source_commit) is None:
        raise ValueError("feature size evidence sourceCommit must be a 40-character lowercase SHA")

    for key in ("workflowRunId", "artifactId"):
        value = evidence.get(key)
        if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
            raise ValueError(f"feature size evidence {key} must be a positive integer")

    evidence_summary = _mapping_value(evidence, "summary", "feature size evidence")
    _require_exact_size_metrics(evidence_summary, "feature size evidence summary")

    for key in _SIZE_METRICS:
        adjusted_ceiling = _metric_integer(
            ceilings,
            key,
            "baseline size absolute ceilings",
        ) + _metric_integer(allowance, key, "feature size allowance")
        evidence_actual = _metric_integer(
            evidence_summary,
            key,
            "feature size evidence summary",
        )
        if evidence_actual > adjusted_ceiling:
            raise ValueError(
                f"feature size evidence {key} {evidence_actual} exceeds "
                f"feature-adjusted ceiling {adjusted_ceiling}"
            )

    violations: list[str] = []
    for key in _SIZE_METRICS:
        actual = _metric_integer(summary, key, "size summary")
        adjusted_ceiling = _metric_integer(
            ceilings,
            key,
            "baseline size absolute ceilings",
        ) + _metric_integer(allowance, key, "feature size allowance")
        if actual > adjusted_ceiling:
            violations.append(
                f"{key}: actual {actual} exceeds feature-adjusted ceiling {adjusted_ceiling}"
            )

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


def _check_size_budget_command(summary_path: pathlib.Path, baseline_path: pathlib.Path) -> int:
    try:
        summary = json.loads(summary_path.read_text(encoding="utf-8"))
        baseline = json.loads(baseline_path.read_text(encoding="utf-8"))
        if not isinstance(summary, dict) or not isinstance(baseline, dict):
            raise ValueError("size summary and baseline must be JSON objects")
        violations = compare_size_summary_to_baseline(summary, baseline)
    except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as error:
        print(f"Release size budget check failed: {error}", file=sys.stderr)
        return 1

    if violations:
        for violation in violations:
            print(violation, file=sys.stderr)
        return 1

    print("Release size budget checks passed.")
    return 0


def _check_size_feature_budget_command(
    summary_path: pathlib.Path,
    baseline_path: pathlib.Path,
    feature_budget_path: pathlib.Path,
) -> int:
    try:
        summary = json.loads(summary_path.read_text(encoding="utf-8"))
        baseline = json.loads(baseline_path.read_text(encoding="utf-8"))
        feature_budget = json.loads(feature_budget_path.read_text(encoding="utf-8"))
        if (
            not isinstance(summary, dict)
            or not isinstance(baseline, dict)
            or not isinstance(feature_budget, dict)
        ):
            raise ValueError("size summary, baseline, and feature budget must be JSON objects")
        violations = compare_size_summary_to_feature_budget(summary, baseline, feature_budget)
    except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as error:
        print(f"Feature size budget check failed: {error}", file=sys.stderr)
        return 1

    if violations:
        for violation in violations:
            print(violation, file=sys.stderr)
        return 1

    print("Feature size budget checks passed.")
    return 0


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="NotchHub deterministic performance policy")
    subparsers = parser.add_subparsers(dest="command", required=True)

    audit_parser = subparsers.add_parser("audit", help="audit runtime Swift sources")
    audit_parser.add_argument("root", type=pathlib.Path)

    summarize_parser = subparsers.add_parser("summarize", help="summarize raw ps samples")
    summarize_parser.add_argument("--input", required=True, type=pathlib.Path)
    summarize_parser.add_argument("--output", type=pathlib.Path)

    budget_parser = subparsers.add_parser(
        "check-budget", help="compare a summary JSON object to a budget JSON object"
    )
    budget_parser.add_argument("--summary", required=True, type=pathlib.Path)
    budget_parser.add_argument("--budget", required=True, type=pathlib.Path)

    size_budget_parser = subparsers.add_parser(
        "check-size-budget",
        help="compare release artifact sizes to the canonical baseline",
    )
    size_budget_parser.add_argument("--summary", required=True, type=pathlib.Path)
    size_budget_parser.add_argument("--baseline", required=True, type=pathlib.Path)

    feature_size_budget_parser = subparsers.add_parser(
        "check-size-feature-budget",
        help="compare release artifact sizes to an additive reviewed feature budget",
    )
    feature_size_budget_parser.add_argument("--summary", required=True, type=pathlib.Path)
    feature_size_budget_parser.add_argument("--baseline", required=True, type=pathlib.Path)
    feature_size_budget_parser.add_argument(
        "--feature-budget",
        required=True,
        type=pathlib.Path,
    )

    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    if args.command == "audit":
        return _audit_command(args.root)
    if args.command == "summarize":
        return _summarize_command(args.input, args.output)
    if args.command == "check-budget":
        return _check_budget_command(args.summary, args.budget)
    if args.command == "check-size-budget":
        return _check_size_budget_command(args.summary, args.baseline)
    if args.command == "check-size-feature-budget":
        return _check_size_feature_budget_command(
            args.summary,
            args.baseline,
            args.feature_budget,
        )
    raise AssertionError(f"Unhandled command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())
