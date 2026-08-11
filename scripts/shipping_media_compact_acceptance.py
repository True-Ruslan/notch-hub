#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import pathlib
import subprocess
import sys
import time
from collections.abc import Sequence
from typing import Any

from performance_policy import ProcessSample, summarize_samples, summarize_stability_samples
from production_media_transport_acceptance import (
    _is_stream_adapter_command,
    _platform,
    _process_rows,
    _ps_table,
    _sample_process,
)
from shipping_media_acceptance import _process_exists, _validated_source_commit

_STEADY_WARMUP_SECONDS = 10.0
_STEADY_DURATION_SECONDS = 60.0
_STEADY_INTERVAL_SECONDS = 1.0
_STABILITY_WARMUP_SECONDS = 10.0
_STABILITY_DURATION_SECONDS = 600.0
_STABILITY_INTERVAL_SECONDS = 5.0


def _validated_timing(name: str, value: float, *, positive: bool = False) -> float:
    if not math.isfinite(value) or value < 0 or (positive and value <= 0):
        qualifier = "positive" if positive else "non-negative"
        raise ValueError(f"{name} must be finite and {qualifier}")
    return value


def build_compact_resource_report(
    *,
    mode: str,
    source_commit: str,
    platform: dict[str, str | None],
    started_at: str,
    ended_at: str,
    warmup_seconds: float,
    duration_seconds: float,
    interval_seconds: float,
    parent_samples: Sequence[ProcessSample],
) -> dict[str, Any]:
    source_commit = _validated_source_commit(source_commit)
    if mode not in ("steady", "stability"):
        raise ValueError("mode must be steady or stability")
    _validated_timing("warmup_seconds", warmup_seconds)
    _validated_timing("duration_seconds", duration_seconds, positive=True)
    _validated_timing("interval_seconds", interval_seconds, positive=True)
    if not parent_samples:
        raise ValueError("compact parent resource samples must be non-empty")

    report: dict[str, Any] = {
        "schemaVersion": 1,
        "mode": mode,
        "resourceScope": "compact-parent-only",
        "sourceCommit": source_commit,
        "platform": platform,
        "startedAt": started_at,
        "endedAt": ended_at,
        "requestedWarmupSeconds": warmup_seconds,
        "requestedDurationSeconds": duration_seconds,
        "sampleIntervalSeconds": interval_seconds,
        "sampleCount": len(parent_samples),
        "adapterAbsent": True,
        "parent": summarize_samples(parent_samples),
    }
    if mode == "stability":
        report["parentStability"] = summarize_stability_samples(parent_samples)
    return report


def _resource_config(mode: str) -> tuple[float, float, float]:
    if mode == "steady":
        return (
            _STEADY_WARMUP_SECONDS,
            _STEADY_DURATION_SECONDS,
            _STEADY_INTERVAL_SECONDS,
        )
    if mode == "stability":
        return (
            _STABILITY_WARMUP_SECONDS,
            _STABILITY_DURATION_SECONDS,
            _STABILITY_INTERVAL_SECONDS,
        )
    raise ValueError("mode must be steady or stability")


def _owned_adapter_pids(parent_pid: int) -> list[int]:
    return [
        pid
        for pid, ppid, command in _process_rows(_ps_table())
        if ppid == parent_pid and _is_stream_adapter_command(command)
    ]


def _assert_adapter_absent(parent_pid: int) -> None:
    adapter_pids = _owned_adapter_pids(parent_pid)
    if adapter_pids:
        raise RuntimeError(
            f"compact idle unexpectedly owns {len(adapter_pids)} media adapter process(es)"
        )


def _sleep_until(target: float) -> None:
    remaining = target - time.monotonic()
    if remaining > 0:
        time.sleep(remaining)


def _utc_now() -> str:
    import datetime as dt

    return dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z")


def collect_compact_resources(
    parent_pid: int,
    source_commit: str,
    mode: str,
) -> dict[str, Any]:
    source_commit = _validated_source_commit(source_commit)
    if parent_pid <= 0:
        raise ValueError("parent pid must be positive")
    if not _process_exists(parent_pid):
        raise ValueError("shipping parent process is not running")

    warmup_seconds, duration_seconds, interval_seconds = _resource_config(mode)
    _assert_adapter_absent(parent_pid)
    started_at = _utc_now()
    _sleep_until(time.monotonic() + warmup_seconds)
    _assert_adapter_absent(parent_pid)

    samples: list[ProcessSample] = []
    sample_count = int(round(duration_seconds / interval_seconds))
    sample_started = time.monotonic()
    for index in range(sample_count):
        if not _process_exists(parent_pid):
            raise RuntimeError("shipping parent exited during compact resource sampling")
        _assert_adapter_absent(parent_pid)
        samples.append(_sample_process(parent_pid))
        if index + 1 < sample_count:
            _sleep_until(sample_started + ((index + 1) * interval_seconds))

    _assert_adapter_absent(parent_pid)
    return build_compact_resource_report(
        mode=mode,
        source_commit=source_commit,
        platform=_platform(),
        started_at=started_at,
        ended_at=_utc_now(),
        warmup_seconds=warmup_seconds,
        duration_seconds=duration_seconds,
        interval_seconds=interval_seconds,
        parent_samples=samples,
    )


def _write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="NotchHub compact-idle target-Mac resource acceptance"
    )
    parser.add_argument("--attach-pid", required=True, type=int)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--mode", required=True, choices=("steady", "stability"))
    parser.add_argument("--output", required=True, type=pathlib.Path)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    try:
        result = collect_compact_resources(args.attach_pid, args.source_commit, args.mode)
        _write_json(args.output, result)
        print(f"Wrote compact shipping acceptance evidence: {args.output}")
        return 0
    except (
        OSError,
        subprocess.CalledProcessError,
        RuntimeError,
        UnicodeError,
        ValueError,
    ) as error:
        print(f"Compact shipping acceptance failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
