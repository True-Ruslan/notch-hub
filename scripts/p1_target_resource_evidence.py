#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import pathlib
import sys
from collections.abc import Mapping, Sequence


_TARGET_PLATFORM = {"macOSVersion": "26.6", "modelIdentifier": "Mac16,8"}
_SCENARIO_CONFIGURATION = {
    "idle": {"warmup": 10.0, "duration": 60.0, "interval": 1.0, "sampleCount": 60},
    "hover": {"warmup": 10.0, "duration": 60.0, "interval": 1.0, "sampleCount": 60},
    "stability": {"warmup": 10.0, "duration": 600.0, "interval": 5.0, "sampleCount": 120},
}
_REPORT_KEYS = {
    "schemaVersion",
    "scenario",
    "sourceCommit",
    "measurementToolCommit",
    "platform",
    "measurementMode",
    "startedAt",
    "endedAt",
    "requestedWarmupSeconds",
    "requestedDurationSeconds",
    "sampleIntervalSeconds",
    "actualMeasurementSeconds",
    "sampleCount",
    "summary",
}
_SUMMARY_KEYS = {
    "sampleCount",
    "cpuMedianPercent",
    "cpuMaxPercent",
    "rssMedianKiB",
    "rssMaxKiB",
    "threadMedian",
    "threadMax",
}
_STABILITY_KEYS = {
    "rssStartKiB",
    "rssEndKiB",
    "rssFirstQuartileKiB",
    "threadStart",
    "threadEnd",
    "threadFirstQuartile",
}
_MANUAL_KEYS = {"schemaVersion", "sourceCommit", "platform", "idleWakeups", "energy", "compositor"}
_IDLE_WAKEUP_KEYS = {"method", "observationSeconds", "wakeupsPerSecond"}
_ENERGY_KEYS = {"method", "observationSeconds", "finding"}
_COMPOSITOR_KEYS = {"method", "interactionCycles", "finding"}
_FINDINGS = {"no-anomaly-observed", "anomaly-observed"}
_ENERGY_METHODS = {"instruments-power-profiler", "activity-monitor-energy"}


class EvidenceError(ValueError):
    pass


def _commit(value: object, label: str) -> str:
    if not isinstance(value, str) or len(value) != 40:
        raise EvidenceError(f"{label} must be a 40-character Git commit")
    if any(character not in "0123456789abcdefABCDEF" for character in value):
        raise EvidenceError(f"{label} must contain only hexadecimal characters")
    return value.lower()


def _mapping(value: object, label: str) -> Mapping[str, object]:
    if not isinstance(value, dict):
        raise EvidenceError(f"{label} must be an object")
    if any(not isinstance(key, str) for key in value):
        raise EvidenceError(f"{label} keys must be strings")
    return value


def _exact_keys(value: Mapping[str, object], expected: set[str], label: str) -> None:
    actual = set(value)
    if actual != expected:
        missing = sorted(expected - actual)
        extra = sorted(actual - expected)
        raise EvidenceError(f"{label} keys mismatch; missing={missing}, extra={extra}")


def _finite_number(value: object, label: str, *, minimum: float = 0.0) -> float | int:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise EvidenceError(f"{label} must be numeric")
    if not math.isfinite(float(value)) or float(value) < minimum:
        raise EvidenceError(f"{label} must be finite and >= {minimum}")
    return value


def _integer(value: object, label: str, *, minimum: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < minimum:
        raise EvidenceError(f"{label} must be an integer >= {minimum}")
    return value


def _platform(value: object, label: str) -> dict[str, str]:
    platform = _mapping(value, label)
    _exact_keys(platform, set(_TARGET_PLATFORM), label)
    normalized = {
        "macOSVersion": platform.get("macOSVersion"),
        "modelIdentifier": platform.get("modelIdentifier"),
    }
    if normalized != _TARGET_PLATFORM:
        raise EvidenceError(
            f"{label} must be exact target {_TARGET_PLATFORM!r}, got {normalized!r}"
        )
    return dict(_TARGET_PLATFORM)


def _summary(value: object, expected_count: int, label: str) -> dict[str, float | int]:
    summary = _mapping(value, label)
    _exact_keys(summary, _SUMMARY_KEYS, label)
    sample_count = _integer(summary.get("sampleCount"), f"{label}.sampleCount", minimum=1)
    if sample_count != expected_count:
        raise EvidenceError(f"{label}.sampleCount must equal {expected_count}")

    result: dict[str, float | int] = {"sampleCount": sample_count}
    for key in ("cpuMedianPercent", "cpuMaxPercent", "rssMedianKiB", "rssMaxKiB"):
        result[key] = _finite_number(summary.get(key), f"{label}.{key}")
    result["threadMedian"] = _finite_number(summary.get("threadMedian"), f"{label}.threadMedian", minimum=1)
    result["threadMax"] = _integer(summary.get("threadMax"), f"{label}.threadMax", minimum=1)
    return result


def _stability_summary(value: object, label: str) -> dict[str, float | int]:
    summary = _mapping(value, label)
    _exact_keys(summary, _STABILITY_KEYS, label)
    result: dict[str, float | int] = {}
    for key in ("rssStartKiB", "rssEndKiB", "rssFirstQuartileKiB"):
        result[key] = _finite_number(summary.get(key), f"{label}.{key}")
    result["threadStart"] = _integer(summary.get("threadStart"), f"{label}.threadStart", minimum=1)
    result["threadEnd"] = _integer(summary.get("threadEnd"), f"{label}.threadEnd", minimum=1)
    result["threadFirstQuartile"] = _finite_number(
        summary.get("threadFirstQuartile"),
        f"{label}.threadFirstQuartile",
        minimum=1,
    )
    return result


def _report(
    value: object,
    *,
    scenario: str,
    expected_source_commit: str,
    expected_tool_commit: str | None,
) -> tuple[dict[str, object], str]:
    report = _mapping(value, f"{scenario} report")
    expected_keys = set(_REPORT_KEYS)
    if scenario == "stability":
        expected_keys.add("stabilitySummary")
    _exact_keys(report, expected_keys, f"{scenario} report")

    if report.get("schemaVersion") != 1:
        raise EvidenceError(f"{scenario} report schemaVersion must equal 1")
    if report.get("scenario") != scenario:
        raise EvidenceError(f"{scenario} report scenario mismatch")
    source_commit = _commit(report.get("sourceCommit"), f"{scenario}.sourceCommit")
    if source_commit != expected_source_commit:
        raise EvidenceError(f"{scenario} report source commit mismatch")
    tool_commit = _commit(report.get("measurementToolCommit"), f"{scenario}.measurementToolCommit")
    if expected_tool_commit is not None and tool_commit != expected_tool_commit:
        raise EvidenceError(f"{scenario} report measurement tool commit mismatch")
    platform = _platform(report.get("platform"), f"{scenario}.platform")
    if report.get("measurementMode") != "attached":
        raise EvidenceError(f"{scenario} report must use attached measurement mode")
    if not isinstance(report.get("startedAt"), str) or not isinstance(report.get("endedAt"), str):
        raise EvidenceError(f"{scenario} report timestamps must be strings")

    expected = _SCENARIO_CONFIGURATION[scenario]
    for key, report_key in (
        ("warmup", "requestedWarmupSeconds"),
        ("duration", "requestedDurationSeconds"),
        ("interval", "sampleIntervalSeconds"),
    ):
        actual = _finite_number(report.get(report_key), f"{scenario}.{report_key}")
        if float(actual) != expected[key]:
            raise EvidenceError(f"{scenario}.{report_key} must equal {expected[key]}")
    sample_count = _integer(report.get("sampleCount"), f"{scenario}.sampleCount", minimum=1)
    if sample_count != expected["sampleCount"]:
        raise EvidenceError(f"{scenario}.sampleCount must equal {expected['sampleCount']}")
    _finite_number(report.get("actualMeasurementSeconds"), f"{scenario}.actualMeasurementSeconds", minimum=0.001)

    normalized: dict[str, object] = {
        "configuration": {
            "measurementMode": "attached",
            "warmupSeconds": expected["warmup"],
            "durationSeconds": expected["duration"],
            "sampleIntervalSeconds": expected["interval"],
            "sampleCount": sample_count,
        },
        "summary": _summary(report.get("summary"), sample_count, f"{scenario}.summary"),
    }
    if scenario == "stability":
        normalized["stabilitySummary"] = _stability_summary(
            report.get("stabilitySummary"),
            "stability.stabilitySummary",
        )

    # Platform is validated here but emitted once at the bundle root.
    assert platform == _TARGET_PLATFORM
    return normalized, tool_commit


def _manual(value: object, expected_source_commit: str) -> tuple[dict[str, object], bool]:
    manual = _mapping(value, "manual evidence")
    _exact_keys(manual, _MANUAL_KEYS, "manual evidence")
    if manual.get("schemaVersion") != 1:
        raise EvidenceError("manual evidence schemaVersion must equal 1")
    if _commit(manual.get("sourceCommit"), "manual.sourceCommit") != expected_source_commit:
        raise EvidenceError("manual evidence source commit mismatch")
    _platform(manual.get("platform"), "manual.platform")

    wakeups = _mapping(manual.get("idleWakeups"), "manual.idleWakeups")
    _exact_keys(wakeups, _IDLE_WAKEUP_KEYS, "manual.idleWakeups")
    if wakeups.get("method") != "activity-monitor-idle-wake-ups":
        raise EvidenceError("idle wakeups method must be activity-monitor-idle-wake-ups")
    if _integer(wakeups.get("observationSeconds"), "manual.idleWakeups.observationSeconds", minimum=1) != 60:
        raise EvidenceError("idle wakeups observationSeconds must equal 60")
    wakeups_per_second = _finite_number(
        wakeups.get("wakeupsPerSecond"),
        "manual.idleWakeups.wakeupsPerSecond",
    )

    energy = _mapping(manual.get("energy"), "manual.energy")
    _exact_keys(energy, _ENERGY_KEYS, "manual.energy")
    energy_method = energy.get("method")
    if energy_method not in _ENERGY_METHODS:
        raise EvidenceError(f"unsupported energy method: {energy_method!r}")
    if _integer(energy.get("observationSeconds"), "manual.energy.observationSeconds", minimum=1) != 60:
        raise EvidenceError("energy observationSeconds must equal 60")
    energy_finding = energy.get("finding")
    if energy_finding not in _FINDINGS:
        raise EvidenceError(f"unsupported energy finding: {energy_finding!r}")

    compositor = _mapping(manual.get("compositor"), "manual.compositor")
    _exact_keys(compositor, _COMPOSITOR_KEYS, "manual.compositor")
    if compositor.get("method") != "instruments-core-animation":
        raise EvidenceError("compositor method must be instruments-core-animation")
    if _integer(compositor.get("interactionCycles"), "manual.compositor.interactionCycles", minimum=1) != 10:
        raise EvidenceError("compositor interactionCycles must equal 10")
    compositor_finding = compositor.get("finding")
    if compositor_finding not in _FINDINGS:
        raise EvidenceError(f"unsupported compositor finding: {compositor_finding!r}")

    normalized = {
        "idleWakeups": {
            "method": "activity-monitor-idle-wake-ups",
            "observationSeconds": 60,
            "wakeupsPerSecond": wakeups_per_second,
        },
        "energy": {
            "method": energy_method,
            "observationSeconds": 60,
            "finding": energy_finding,
        },
        "compositor": {
            "method": "instruments-core-animation",
            "interactionCycles": 10,
            "finding": compositor_finding,
        },
    }
    review_required = "anomaly-observed" in {energy_finding, compositor_finding}
    return normalized, review_required


def build_evidence_bundle(
    *,
    expected_source_commit: str,
    idle_report: object,
    hover_report: object,
    stability_report: object,
    manual_evidence: object,
) -> dict[str, object]:
    source_commit = _commit(expected_source_commit, "expected source commit")
    scenarios: dict[str, object] = {}
    tool_commit: str | None = None
    for scenario, report in (
        ("idle", idle_report),
        ("hover", hover_report),
        ("stability", stability_report),
    ):
        normalized, current_tool_commit = _report(
            report,
            scenario=scenario,
            expected_source_commit=source_commit,
            expected_tool_commit=tool_commit,
        )
        if tool_commit is None:
            tool_commit = current_tool_commit
        scenarios[scenario] = normalized

    assert tool_commit is not None
    normalized_manual, review_required = _manual(manual_evidence, source_commit)
    return {
        "schemaVersion": 1,
        "sourceCommit": source_commit,
        "measurementToolCommit": tool_commit,
        "platform": dict(_TARGET_PLATFORM),
        "scenarios": scenarios,
        "manualEvidence": normalized_manual,
        "reviewRequired": review_required,
    }


def _reject_json_constant(value: str) -> None:
    raise EvidenceError(f"non-finite JSON constant is forbidden: {value}")


def _read_json(path: pathlib.Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"), parse_constant=_reject_json_constant)
    except json.JSONDecodeError as error:
        raise EvidenceError(f"invalid JSON in {path}: {error}") from error


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Build privacy-safe P1 target-Mac resource evidence")
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--idle", required=True, type=pathlib.Path)
    parser.add_argument("--hover", required=True, type=pathlib.Path)
    parser.add_argument("--stability", required=True, type=pathlib.Path)
    parser.add_argument("--manual-evidence", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    try:
        bundle = build_evidence_bundle(
            expected_source_commit=args.source_commit,
            idle_report=_read_json(args.idle),
            hover_report=_read_json(args.hover),
            stability_report=_read_json(args.stability),
            manual_evidence=_read_json(args.manual_evidence),
        )
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(
            json.dumps(bundle, sort_keys=True, indent=2, allow_nan=False) + "\n",
            encoding="utf-8",
        )
        print(f"Wrote P1 target resource evidence: {args.output}")
        return 0
    except (EvidenceError, OSError, UnicodeError) as error:
        print(f"P1 target resource evidence failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
