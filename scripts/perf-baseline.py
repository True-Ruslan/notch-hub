#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
import math
import pathlib
import subprocess
import sys
import time
from collections.abc import Sequence

from performance_policy import (
    count_ps_thread_rows,
    parse_ps_sample,
    summarize_samples,
    summarize_stability_samples,
    validate_config,
)


def _command_text(args: list[str]) -> str:
    result = subprocess.run(args, check=True, capture_output=True, text=True)
    return result.stdout.strip()


def _validated_commit(value: str) -> str:
    if len(value) != 40 or any(character not in "0123456789abcdefABCDEF" for character in value):
        raise ValueError(f"unexpected Git commit: {value!r}")
    return value.lower()


def _measurement_tool_commit() -> str:
    return _validated_commit(_command_text(["/usr/bin/git", "rev-parse", "HEAD"]))


def _macos_version() -> str:
    return _command_text(["/usr/bin/sw_vers", "-productVersion"])


def _hardware_model() -> str | None:
    try:
        value = _command_text(["/usr/sbin/sysctl", "-n", "hw.model"])
    except (OSError, subprocess.CalledProcessError):
        return None
    return value or None


def _sample_process(pid: int):
    metrics = subprocess.run(
        ["/bin/ps", "-p", str(pid), "-o", "%cpu=", "-o", "rss="],
        check=False,
        capture_output=True,
        text=True,
    )
    if metrics.returncode != 0:
        message = metrics.stderr.strip() or metrics.stdout.strip() or f"ps exited {metrics.returncode}"
        raise RuntimeError(f"process CPU/RSS sampling failed for pid {pid}: {message}")

    metric_line = metrics.stdout.strip()
    metric_fields = metric_line.split()
    if len(metric_fields) != 2:
        raise RuntimeError(
            f"process CPU/RSS sampling returned unexpected output for pid {pid}: {metric_line!r}"
        )

    threads = subprocess.run(
        ["/bin/ps", "-M", str(pid)],
        check=False,
        capture_output=True,
        text=True,
    )
    if threads.returncode != 0:
        message = threads.stderr.strip() or threads.stdout.strip() or f"ps -M exited {threads.returncode}"
        raise RuntimeError(f"process thread sampling failed for pid {pid}: {message}")

    try:
        thread_count = count_ps_thread_rows(threads.stdout)
    except ValueError as error:
        raise RuntimeError(f"process thread sampling returned invalid output for pid {pid}: {error}") from error

    return parse_ps_sample(f"{metric_fields[0]} {metric_fields[1]} {thread_count}")


def _app_executable(app: pathlib.Path) -> pathlib.Path:
    executable = app / "Contents" / "MacOS" / "NotchHub"
    if not app.is_dir():
        raise ValueError(f"app bundle does not exist: {app}")
    if not executable.is_file():
        raise ValueError(f"app executable does not exist: {executable}")
    return executable


def _terminate_launched(process: subprocess.Popen[bytes]) -> None:
    if process.poll() is not None:
        return
    process.terminate()
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait(timeout=5)


def _utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z")


def _sample_offsets(duration_seconds: float, interval_seconds: float) -> list[float]:
    full_intervals = math.floor((duration_seconds / interval_seconds) + 1e-12)
    offsets = [interval_seconds * index for index in range(1, full_intervals + 1)]
    if not offsets or not math.isclose(offsets[-1], duration_seconds, rel_tol=0, abs_tol=1e-9):
        offsets.append(duration_seconds)
    return offsets


def measure(
    *,
    scenario: str,
    warmup_seconds: float,
    duration_seconds: float,
    interval_seconds: float,
    app: pathlib.Path | None,
    attach_pid: int | None,
    source_commit: str | None,
) -> dict[str, object]:
    validate_config(
        scenario,
        warmup_seconds,
        duration_seconds,
        interval_seconds,
        app,
        attach_pid,
    )

    tool_commit = _measurement_tool_commit()
    measured_source_commit = _validated_commit(source_commit) if source_commit is not None else tool_commit

    launched: subprocess.Popen[bytes] | None = None
    if app is not None:
        executable = _app_executable(app)
        launched = subprocess.Popen(
            [str(executable)],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            close_fds=True,
        )
        pid = launched.pid
        measurement_mode = "launched"
    else:
        assert attach_pid is not None
        pid = attach_pid
        measurement_mode = "attached"

    try:
        if warmup_seconds:
            time.sleep(warmup_seconds)

        offsets = _sample_offsets(duration_seconds, interval_seconds)
        samples = []
        started_at = _utc_now()
        started_monotonic = time.monotonic()

        for index, offset in enumerate(offsets, 1):
            scheduled = started_monotonic + offset
            remaining = scheduled - time.monotonic()
            if remaining > 0:
                time.sleep(remaining)
            if launched is not None and launched.poll() is not None:
                raise RuntimeError(f"launched NotchHub exited before sample {index}")
            samples.append(_sample_process(pid))

        ended_monotonic = time.monotonic()
        ended_at = _utc_now()
        summary = summarize_samples(samples)

        result: dict[str, object] = {
            "schemaVersion": 1,
            "scenario": scenario,
            "sourceCommit": measured_source_commit,
            "measurementToolCommit": tool_commit,
            "platform": {
                "macOSVersion": _macos_version(),
                "modelIdentifier": _hardware_model(),
            },
            "measurementMode": measurement_mode,
            "startedAt": started_at,
            "endedAt": ended_at,
            "requestedWarmupSeconds": warmup_seconds,
            "requestedDurationSeconds": duration_seconds,
            "sampleIntervalSeconds": interval_seconds,
            "actualMeasurementSeconds": round(ended_monotonic - started_monotonic, 3),
            "sampleCount": len(samples),
            "summary": summary,
        }
        if scenario == "stability":
            result["stabilitySummary"] = summarize_stability_samples(samples)
        return result
    finally:
        if launched is not None:
            _terminate_launched(launched)


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="NotchHub target-Mac performance baseline harness")
    target = parser.add_mutually_exclusive_group(required=True)
    target.add_argument("--app", type=pathlib.Path)
    target.add_argument("--attach-pid", type=int)
    parser.add_argument("--scenario", required=True, choices=("idle", "hover", "stability"))
    parser.add_argument("--warmup-seconds", type=float, default=10)
    parser.add_argument("--duration-seconds", type=float, required=True)
    parser.add_argument("--interval-seconds", type=float, required=True)
    parser.add_argument(
        "--source-commit",
        help="40-character commit for the measured app; defaults to the harness checkout HEAD",
    )
    parser.add_argument("--output", required=True, type=pathlib.Path)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    try:
        result = measure(
            scenario=args.scenario,
            warmup_seconds=args.warmup_seconds,
            duration_seconds=args.duration_seconds,
            interval_seconds=args.interval_seconds,
            app=args.app,
            attach_pid=args.attach_pid,
            source_commit=args.source_commit,
        )
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, sort_keys=True, indent=2) + "\n", encoding="utf-8")
        print(f"Wrote performance measurement: {args.output}")
        return 0
    except (OSError, subprocess.CalledProcessError, RuntimeError, UnicodeError, ValueError) as error:
        print(f"Performance measurement failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
