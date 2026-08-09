#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
import math
import pathlib
import plistlib
import re
import subprocess
import sys
import time
from collections.abc import Sequence
from typing import Any

from performance_policy import (
    count_ps_thread_rows,
    parse_ps_sample,
    summarize_samples,
    summarize_stability_samples,
)

EXPECTED_SOURCE_COMMIT = "c63f39c40b90d647e48271b9dc1d5ffd6e612c0b"
EXPECTED_ADAPTER_COMMIT = "3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
EXPECTED_PATCH_SHA256 = "f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974"
EXPECTED_BUNDLE_IDENTIFIER = "ru.trueruslan.notchhub.media-transport-candidate"
EXPECTED_CAPABILITY_KEYS = frozenset(("previous", "next", "seek"))
ALLOWED_CAPABILITY_VALUES = frozenset(("supported", "unsupported", "unknown"))
EXPECTED_REPORT_KEYS = frozenset(
    (
        "schemaVersion",
        "sourceCommit",
        "adapterCommit",
        "eventCount",
        "observedSession",
        "observedArtwork",
        "observedPlayingState",
        "observedSessionDisappearance",
        "observedArtworkClearOnSourceSwitch",
        "sourceSwitchCount",
        "sourceBundleIdentifier",
        "capabilities",
        "cleanTeardown",
    )
)

_STEADY_WARMUP_SECONDS = 10.0
_STEADY_DURATION_SECONDS = 60.0
_STEADY_INTERVAL_SECONDS = 1.0
_STABILITY_WARMUP_SECONDS = 0.0
_STABILITY_DURATION_SECONDS = 600.0
_STABILITY_INTERVAL_SECONDS = 5.0
_OBSERVER_MARGIN_SECONDS = 10.0
_ADAPTER_DISCOVERY_TIMEOUT_SECONDS = 5.0


def _validated_source_commit(value: str) -> str:
    if not re.fullmatch(r"[0-9a-f]{40}", value):
        raise ValueError("source commit must be exactly 40 lowercase hexadecimal characters")
    return value


def _validated_non_negative_number(mapping: dict[str, Any], key: str) -> float:
    value = mapping.get(key)
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f"{key} must be numeric")
    numeric = float(value)
    if not math.isfinite(numeric) or numeric < 0:
        raise ValueError(f"{key} must be finite and non-negative")
    return numeric


def _validate_capabilities(value: Any) -> dict[str, str]:
    if not isinstance(value, dict) or set(value) != EXPECTED_CAPABILITY_KEYS:
        raise ValueError("capabilities must contain exactly previous, next, and seek")
    normalized: dict[str, str] = {}
    for key in EXPECTED_CAPABILITY_KEYS:
        state = value.get(key)
        if not isinstance(state, str) or state not in ALLOWED_CAPABILITY_VALUES:
            raise ValueError(f"invalid capability state for {key}")
        normalized[key] = state
    return normalized


def validate_candidate_report(report: Any, source_commit: str) -> dict[str, Any]:
    expected_source = _validated_source_commit(source_commit)
    if not isinstance(report, dict) or set(report) != EXPECTED_REPORT_KEYS:
        raise ValueError("candidate report does not match the exact privacy-safe schema")
    if report.get("schemaVersion") != 1:
        raise ValueError("candidate report schemaVersion must be 1")
    if report.get("sourceCommit") != expected_source:
        raise ValueError("candidate report source provenance mismatch")
    if report.get("adapterCommit") != EXPECTED_ADAPTER_COMMIT:
        raise ValueError("candidate report adapter provenance mismatch")

    for key in ("eventCount", "sourceSwitchCount"):
        value = report.get(key)
        if isinstance(value, bool) or not isinstance(value, int) or value < 0:
            raise ValueError(f"candidate report {key} must be a non-negative integer")

    for key in (
        "observedSession",
        "observedArtwork",
        "observedPlayingState",
        "observedSessionDisappearance",
        "observedArtworkClearOnSourceSwitch",
        "cleanTeardown",
    ):
        if not isinstance(report.get(key), bool):
            raise ValueError(f"candidate report {key} must be boolean")

    source = report.get("sourceBundleIdentifier")
    if source is not None and (not isinstance(source, str) or not source):
        raise ValueError("sourceBundleIdentifier must be null or a non-empty string")

    capabilities = _validate_capabilities(report.get("capabilities"))
    normalized = dict(report)
    normalized["capabilities"] = capabilities
    return normalized


def _process_rows(output: str) -> list[tuple[int, int, str]]:
    rows: list[tuple[int, int, str]] = []
    for raw_line in output.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        fields = line.split(maxsplit=2)
        if len(fields) != 3:
            raise ValueError("process table row must contain pid, ppid, and command")
        try:
            pid = int(fields[0], 10)
            ppid = int(fields[1], 10)
        except ValueError as error:
            raise ValueError("process table pid/ppid must be integers") from error
        if pid <= 0 or ppid < 0:
            raise ValueError("process table pid/ppid are outside the valid range")
        rows.append((pid, ppid, fields[2]))
    return rows


def _is_stream_adapter_command(command: str) -> bool:
    return (
        command.startswith("/usr/bin/perl ")
        and "mediaremote-adapter.pl" in command
        and "MediaRemoteAdapter.framework" in command
        and command.endswith(" stream --no-diff --micros")
    )


def find_owned_adapter_pid(process_rows: str, parent_pid: int) -> int:
    if parent_pid <= 0:
        raise ValueError("parent pid must be positive")
    matches = [
        pid
        for pid, ppid, command in _process_rows(process_rows)
        if ppid == parent_pid and _is_stream_adapter_command(command)
    ]
    if len(matches) != 1:
        raise ValueError(f"expected exactly one owned media adapter process, found {len(matches)}")
    return matches[0]


def _candidate_adapter_pids(process_rows: str, script_path: pathlib.Path) -> list[int]:
    expected_script = str(script_path.resolve())
    return [
        pid
        for pid, _, command in _process_rows(process_rows)
        if _is_stream_adapter_command(command) and expected_script in command
    ]


def combine_resource_summaries(
    parent: dict[str, Any], adapter: dict[str, Any]
) -> dict[str, float | int]:
    pairs = (
        ("cpuMedianPercent", "cpuMedianPercentUpperBound"),
        ("cpuMaxPercent", "cpuMaxPercentUpperBound"),
        ("rssMedianKiB", "rssMedianKiBUpperBound"),
        ("rssMaxKiB", "rssMaxKiBUpperBound"),
        ("threadMedian", "threadMedianUpperBound"),
        ("threadMax", "threadMaxUpperBound"),
    )
    result: dict[str, float | int] = {}
    for source_key, output_key in pairs:
        value = _validated_non_negative_number(parent, source_key) + _validated_non_negative_number(
            adapter, source_key
        )
        if source_key == "threadMax":
            result[output_key] = int(value)
        else:
            result[output_key] = round(value, 6)
    return result


def _combine_stability_summaries(
    parent: dict[str, Any], adapter: dict[str, Any]
) -> dict[str, float | int]:
    keys = (
        "rssStartKiB",
        "rssEndKiB",
        "rssFirstQuartileKiB",
        "threadStart",
        "threadEnd",
        "threadFirstQuartile",
    )
    combined: dict[str, float | int] = {}
    for key in keys:
        value = _validated_non_negative_number(parent, key) + _validated_non_negative_number(adapter, key)
        combined[key] = int(value) if key in ("rssStartKiB", "rssEndKiB", "threadStart", "threadEnd") else round(value, 6)
    combined["rssEndMinusStartKiB"] = int(combined["rssEndKiB"]) - int(combined["rssStartKiB"])
    return combined


def _run_text(arguments: list[str]) -> str:
    result = subprocess.run(arguments, check=True, capture_output=True, text=True)
    return result.stdout.strip()


def _platform() -> dict[str, str | None]:
    macos_version = _run_text(["/usr/bin/sw_vers", "-productVersion"])
    try:
        model = _run_text(["/usr/sbin/sysctl", "-n", "hw.model"])
    except (OSError, subprocess.CalledProcessError):
        model = None
    return {"macOSVersion": macos_version, "modelIdentifier": model or None}


def _candidate_executable(app: pathlib.Path) -> pathlib.Path:
    app = app.resolve()
    executable = app / "Contents" / "MacOS" / "MediaTransportCandidate"
    if not app.is_dir() or app.suffix != ".app":
        raise ValueError("candidate app bundle does not exist or is not an .app")
    if not executable.is_file():
        raise ValueError("candidate executable is missing")
    return executable


def _candidate_info(app: pathlib.Path) -> dict[str, Any]:
    info_path = app.resolve() / "Contents" / "Info.plist"
    with info_path.open("rb") as stream:
        value = plistlib.load(stream)
    if not isinstance(value, dict):
        raise ValueError("candidate Info.plist is not a dictionary")
    return value


def _load_json_output(data: str) -> Any:
    try:
        return json.loads(data)
    except json.JSONDecodeError as error:
        raise ValueError("candidate emitted invalid JSON") from error


def _write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def _validate_info(info: dict[str, Any], source_commit: str) -> None:
    if info.get("CFBundleIdentifier") != EXPECTED_BUNDLE_IDENTIFIER:
        raise ValueError("candidate bundle identifier mismatch")
    if info.get("NHSourceCommit") != source_commit:
        raise ValueError("candidate Info.plist source provenance mismatch")
    if info.get("NHAdapterCommit") != EXPECTED_ADAPTER_COMMIT:
        raise ValueError("candidate Info.plist adapter provenance mismatch")
    if info.get("NHAdapterPatchSHA256") != EXPECTED_PATCH_SHA256:
        raise ValueError("candidate Info.plist patch provenance mismatch")


def collect_preflight(app: pathlib.Path, source_commit: str) -> dict[str, Any]:
    source_commit = _validated_source_commit(source_commit)
    executable = _candidate_executable(app)
    info = _candidate_info(app)
    _validate_info(info, source_commit)

    subprocess.run(
        ["/usr/bin/codesign", "--verify", "--deep", "--strict", str(app.resolve())],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    details = subprocess.run(
        ["/usr/bin/codesign", "-dv", "--verbose=4", str(app.resolve())],
        check=True,
        capture_output=True,
        text=True,
    )
    detail_text = details.stdout + details.stderr
    if re.search(r"flags=.*runtime", detail_text) is None:
        raise ValueError("candidate Hardened Runtime flag is missing")

    entitlements = subprocess.run(
        ["/usr/bin/codesign", "--display", "--entitlements", "-", "--xml", str(app.resolve())],
        check=True,
        capture_output=True,
    )
    try:
        entitlement_value = plistlib.loads(entitlements.stdout)
    except (plistlib.InvalidFileException, ValueError) as error:
        raise ValueError("candidate effective entitlements are not a valid plist") from error
    expected_entitlements = {"com.apple.security.app-sandbox": True}
    if entitlement_value != expected_entitlements:
        raise ValueError("candidate effective entitlements are not exactly sandbox-only")

    capabilities_result = subprocess.run(
        [str(executable), "capabilities"],
        check=True,
        capture_output=True,
        text=True,
        timeout=15,
    )
    capabilities = _validate_capabilities(_load_json_output(capabilities_result.stdout))

    return {
        "schemaVersion": 1,
        "sourceCommit": source_commit,
        "adapterCommit": EXPECTED_ADAPTER_COMMIT,
        "adapterPatchSHA256": EXPECTED_PATCH_SHA256,
        "bundleIdentifier": EXPECTED_BUNDLE_IDENTIFIER,
        "platform": _platform(),
        "codesignVerified": True,
        "hardenedRuntime": True,
        "sandboxOnly": True,
        "capabilities": capabilities,
    }


def _utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z")


def collect_observation(
    app: pathlib.Path, source_commit: str, seconds: float
) -> dict[str, Any]:
    source_commit = _validated_source_commit(source_commit)
    executable = _candidate_executable(app)
    if not math.isfinite(seconds) or seconds <= 0 or seconds > 1_200:
        raise ValueError("observation seconds must be finite, positive, and <= 1200")
    result = subprocess.run(
        [str(executable), "observe", "--seconds", str(seconds)],
        check=True,
        capture_output=True,
        text=True,
        timeout=seconds + _OBSERVER_MARGIN_SECONDS,
    )
    report = _load_json_output(result.stdout)
    return validate_candidate_report(report, source_commit)


def _ps_table() -> str:
    return _run_text(["/bin/ps", "-axo", "pid=,ppid=,command="])


def _sample_process(pid: int) -> dict[str, Any]:
    result = subprocess.run(
        ["/bin/ps", "-p", str(pid), "-o", "%cpu=,rss=,command="],
        check=True,
        capture_output=True,
        text=True,
    )
    cpu, rss = parse_ps_sample(result.stdout)
    threads = count_ps_thread_rows(
        _run_text(["/bin/ps", "-M", "-p", str(pid), "-o", "pid="])
    )
    return {
        "elapsedSeconds": 0.0,
        "cpuPercent": cpu,
        "rssKiB": rss,
        "threads": threads,
    }


def _sleep_until(target: float) -> None:
    delay = target - time.monotonic()
    if delay > 0:
        time.sleep(delay)


def _discover_owned_adapter(parent_pid: int) -> int:
    deadline = time.monotonic() + _ADAPTER_DISCOVERY_TIMEOUT_SECONDS
    while True:
        try:
            return find_owned_adapter_pid(_ps_table(), parent_pid)
        except ValueError:
            if time.monotonic() >= deadline:
                raise
            time.sleep(0.1)


def _ensure_process_alive(process: subprocess.Popen[str], name: str) -> None:
    status = process.poll()
    if status is not None:
        raise RuntimeError(f"{name} exited before acceptance sampling completed: {status}")


def collect_resources(app: pathlib.Path, source_commit: str, mode: str) -> dict[str, Any]:
    source_commit = _validated_source_commit(source_commit)
    executable = _candidate_executable(app)
    script_path = app.resolve() / "Contents" / "Resources" / "mediaremote-adapter.pl"
    if mode == "steady":
        warmup_seconds = _STEADY_WARMUP_SECONDS
        duration_seconds = _STEADY_DURATION_SECONDS
        interval_seconds = _STEADY_INTERVAL_SECONDS
    elif mode == "stability":
        warmup_seconds = _STABILITY_WARMUP_SECONDS
        duration_seconds = _STABILITY_DURATION_SECONDS
        interval_seconds = _STABILITY_INTERVAL_SECONDS
    else:
        raise ValueError("mode must be steady or stability")

    observer_seconds = warmup_seconds + duration_seconds + _OBSERVER_MARGIN_SECONDS
    observer = subprocess.Popen(
        [str(executable), "observe", "--seconds", str(observer_seconds)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    started_at = _utc_now()
    parent_samples: list[dict[str, Any]] = []
    adapter_samples: list[dict[str, Any]] = []
    adapter_pid: int | None = None
    try:
        adapter_pid = _discover_owned_adapter(observer.pid)
        _sleep_until(time.monotonic() + warmup_seconds)
        sample_start = time.monotonic()
        sample_count = int(round(duration_seconds / interval_seconds))
        for index in range(sample_count):
            _ensure_process_alive(observer, "candidate observer")
            parent = _sample_process(observer.pid)
            adapter = _sample_process(adapter_pid)
            elapsed = time.monotonic() - sample_start
            parent["elapsedSeconds"] = round(elapsed, 6)
            adapter["elapsedSeconds"] = round(elapsed, 6)
            parent_samples.append(parent)
            adapter_samples.append(adapter)
            if index + 1 < sample_count:
                _sleep_until(sample_start + ((index + 1) * interval_seconds))

        _ensure_process_alive(observer, "candidate observer")
        stdout, stderr = observer.communicate(timeout=_OBSERVER_MARGIN_SECONDS + 10)
        if observer.returncode != 0:
            raise RuntimeError(f"candidate observer exited {observer.returncode}")
        if stderr.strip():
            raise RuntimeError("candidate observer emitted unexpected stderr")
        observer_report = validate_candidate_report(_load_json_output(stdout), source_commit)
    finally:
        if observer.poll() is None:
            observer.terminate()
            try:
                observer.wait(timeout=5)
            except subprocess.TimeoutExpired:
                observer.kill()
                observer.wait(timeout=5)

    remaining_adapter_pids = _candidate_adapter_pids(_ps_table(), script_path)
    if remaining_adapter_pids:
        raise RuntimeError(
            f"owned adapter process remained after observer teardown: {remaining_adapter_pids}"
        )

    parent_summary = summarize_samples(parent_samples)
    adapter_summary = summarize_samples(adapter_samples)
    result: dict[str, Any] = {
        "schemaVersion": 1,
        "mode": mode,
        "sourceCommit": source_commit,
        "adapterCommit": EXPECTED_ADAPTER_COMMIT,
        "platform": _platform(),
        "startedAt": started_at,
        "endedAt": _utc_now(),
        "requestedWarmupSeconds": warmup_seconds,
        "requestedDurationSeconds": duration_seconds,
        "sampleIntervalSeconds": interval_seconds,
        "sampleCount": len(parent_samples),
        "parent": parent_summary,
        "adapter": adapter_summary,
        "combinedUpperBounds": combine_resource_summaries(parent_summary, adapter_summary),
        "observerReport": observer_report,
        "orphanProcessDetected": False,
    }
    if mode == "stability":
        parent_stability = summarize_stability_samples(parent_samples)
        adapter_stability = summarize_stability_samples(adapter_samples)
        result["parentStability"] = parent_stability
        result["adapterStability"] = adapter_stability
        result["combinedStability"] = _combine_stability_summaries(
            parent_stability,
            adapter_stability,
        )
    return result


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="NotchHub M6.3 target-Mac production media transport acceptance collector"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    def add_common(subparser: argparse.ArgumentParser) -> None:
        subparser.add_argument("--app", required=True, type=pathlib.Path)
        subparser.add_argument("--source-commit", default=EXPECTED_SOURCE_COMMIT)
        subparser.add_argument("--output", required=True, type=pathlib.Path)

    preflight = subparsers.add_parser("preflight")
    add_common(preflight)

    observe = subparsers.add_parser("observe")
    add_common(observe)
    observe.add_argument("--seconds", required=True, type=float)

    resources = subparsers.add_parser("resources")
    add_common(resources)
    resources.add_argument("--mode", required=True, choices=("steady", "stability"))

    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    try:
        if args.command == "preflight":
            evidence = collect_preflight(args.app, args.source_commit)
        elif args.command == "observe":
            evidence = collect_observation(args.app, args.source_commit, args.seconds)
        elif args.command == "resources":
            evidence = collect_resources(args.app, args.source_commit, args.mode)
        else:
            raise ValueError("unsupported acceptance command")
        _write_json(args.output, evidence)
        print(f"Wrote production media transport acceptance evidence: {args.output}")
        return 0
    except (
        OSError,
        subprocess.CalledProcessError,
        subprocess.TimeoutExpired,
        RuntimeError,
        UnicodeError,
        ValueError,
    ) as error:
        print(f"Production media transport acceptance failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
