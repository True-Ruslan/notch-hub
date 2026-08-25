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

from performance_policy import ProcessSample, summarize_samples, summarize_stability_samples
from production_media_transport_acceptance import (
    _platform,
    _ps_table,
    _sample_process,
    find_owned_adapter_pid,
)


EXPECTED_BUNDLE_IDENTIFIER = "ru.trueruslan.notchhub"
EXPECTED_ADAPTER_COMMIT = "3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
EXPECTED_PATCH_SHA256 = "21730c7216814000213a3276777f2b471354f5d7f59019631da0a2917845545f"

_STEADY_WARMUP_SECONDS = 10.0
_STEADY_DURATION_SECONDS = 60.0
_STEADY_INTERVAL_SECONDS = 1.0
_STABILITY_WARMUP_SECONDS = 10.0
_STABILITY_DURATION_SECONDS = 600.0
_STABILITY_INTERVAL_SECONDS = 5.0
_ADAPTER_DISCOVERY_TIMEOUT_SECONDS = 5.0
_MAX_TEARDOWN_TIMEOUT_SECONDS = 300.0
_POLL_INTERVAL_SECONDS = 0.1

_RESOURCE_NAMES = (
    "mediaremote-adapter.pl",
    "MediaRemoteAdapter.framework",
    "MediaRemoteAdapter-LICENSE.txt",
    "media-transport-provenance.json",
)
_DEVELOPMENT_TOOL_NAMES = frozenset(
    (
        "MediaBridgeProbe",
        "MediaBridgeProbe.app",
        "MediaTransportCandidate",
        "ProductionMediaTransportCandidate.app",
        "MediaRemoteAdapterTestClient",
    )
)


def _validated_source_commit(value: str) -> str:
    if re.fullmatch(r"[0-9a-f]{40}", value) is None:
        raise ValueError("source commit must be exactly 40 lowercase hexadecimal characters")
    return value


def validate_shipping_info(info: dict[str, Any], source_commit: str) -> None:
    source_commit = _validated_source_commit(source_commit)
    if info.get("CFBundleIdentifier") != EXPECTED_BUNDLE_IDENTIFIER:
        raise ValueError("shipping bundle identifier mismatch")
    if info.get("NHSourceCommit") != source_commit:
        raise ValueError("shipping source provenance mismatch")
    if info.get("NHAdapterCommit") != EXPECTED_ADAPTER_COMMIT:
        raise ValueError("shipping adapter provenance mismatch")
    if info.get("NHAdapterPatchSHA256") != EXPECTED_PATCH_SHA256:
        raise ValueError("shipping adapter patch provenance mismatch")


def _validated_samples(
    parent_samples: Sequence[ProcessSample], adapter_samples: Sequence[ProcessSample]
) -> None:
    if not parent_samples or not adapter_samples:
        raise ValueError("parent and adapter resource samples must be non-empty")
    if len(parent_samples) != len(adapter_samples):
        raise ValueError("parent and adapter resource sample counts must match")


def _combined_upper_bounds(
    parent: dict[str, float | int], adapter: dict[str, float | int]
) -> dict[str, float | int]:
    keys = (
        "cpuMedianPercent",
        "cpuMaxPercent",
        "rssMedianKiB",
        "rssMaxKiB",
        "threadMedian",
        "threadMax",
    )
    result: dict[str, float | int] = {}
    for key in keys:
        left = parent[key]
        right = adapter[key]
        if isinstance(left, bool) or isinstance(right, bool):
            raise ValueError(f"invalid boolean resource metric: {key}")
        value = float(left) + float(right)
        if key == "threadMax":
            result[key] = int(value)
        elif key in ("rssMaxKiB",):
            result[key] = int(value)
        else:
            result[key] = round(value, 6)
    return result


def build_resource_report(
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
    adapter_samples: Sequence[ProcessSample],
) -> dict[str, Any]:
    source_commit = _validated_source_commit(source_commit)
    if mode not in ("steady", "stability"):
        raise ValueError("mode must be steady or stability")
    for name, value in (
        ("warmup_seconds", warmup_seconds),
        ("duration_seconds", duration_seconds),
        ("interval_seconds", interval_seconds),
    ):
        if not math.isfinite(value) or value < 0:
            raise ValueError(f"{name} must be finite and non-negative")
    if duration_seconds <= 0 or interval_seconds <= 0:
        raise ValueError("duration and interval must be positive")
    _validated_samples(parent_samples, adapter_samples)

    parent_summary = summarize_samples(parent_samples)
    adapter_summary = summarize_samples(adapter_samples)
    report: dict[str, Any] = {
        "schemaVersion": 1,
        "mode": mode,
        "sourceCommit": source_commit,
        "adapterCommit": EXPECTED_ADAPTER_COMMIT,
        "adapterPatchSHA256": EXPECTED_PATCH_SHA256,
        "platform": platform,
        "startedAt": started_at,
        "endedAt": ended_at,
        "requestedWarmupSeconds": warmup_seconds,
        "requestedDurationSeconds": duration_seconds,
        "sampleIntervalSeconds": interval_seconds,
        "sampleCount": len(parent_samples),
        "parent": parent_summary,
        "adapter": adapter_summary,
        "combinedUpperBounds": _combined_upper_bounds(parent_summary, adapter_summary),
    }
    if mode == "stability":
        report["parentStability"] = summarize_stability_samples(parent_samples)
        report["adapterStability"] = summarize_stability_samples(adapter_samples)
    return report


def build_teardown_report(
    *,
    source_commit: str,
    platform: dict[str, str | None],
    parent_exited: bool,
    adapter_exited: bool,
) -> dict[str, Any]:
    source_commit = _validated_source_commit(source_commit)
    if not isinstance(parent_exited, bool) or not isinstance(adapter_exited, bool):
        raise ValueError("teardown exit states must be boolean")
    return {
        "schemaVersion": 1,
        "sourceCommit": source_commit,
        "adapterCommit": EXPECTED_ADAPTER_COMMIT,
        "adapterPatchSHA256": EXPECTED_PATCH_SHA256,
        "platform": platform,
        "parentExited": parent_exited,
        "adapterExited": adapter_exited,
        "orphanProcessDetected": parent_exited and not adapter_exited,
    }


def _utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z")


def _shipping_executable(app: pathlib.Path) -> pathlib.Path:
    app = app.resolve()
    executable = app / "Contents" / "MacOS" / "NotchHub"
    if not app.is_dir() or app.suffix != ".app":
        raise ValueError("shipping app bundle does not exist or is not an .app")
    if not executable.is_file():
        raise ValueError("shipping app executable is missing")
    return executable


def _shipping_info(app: pathlib.Path) -> dict[str, Any]:
    info_path = app.resolve() / "Contents" / "Info.plist"
    with info_path.open("rb") as stream:
        value = plistlib.load(stream)
    if not isinstance(value, dict):
        raise ValueError("shipping Info.plist is not a dictionary")
    return value


def _load_provenance(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError("shipping media provenance is not an object")
    return value


def _effective_entitlements(app: pathlib.Path) -> dict[str, Any]:
    result = subprocess.run(
        ["/usr/bin/codesign", "--display", "--entitlements", "-", "--xml", str(app)],
        check=True,
        capture_output=True,
    )
    try:
        value = plistlib.loads(result.stdout)
    except (plistlib.InvalidFileException, ValueError) as error:
        raise ValueError("shipping effective entitlements are not a valid plist") from error
    if not isinstance(value, dict):
        raise ValueError("shipping effective entitlements are not a dictionary")
    return value


def _codesign_has_runtime(app: pathlib.Path) -> bool:
    result = subprocess.run(
        ["/usr/bin/codesign", "-dv", "--verbose=4", str(app)],
        check=True,
        capture_output=True,
        text=True,
    )
    return re.search(r"flags=.*runtime", result.stdout + result.stderr) is not None


def _development_tools_absent(app: pathlib.Path) -> bool:
    for path in app.rglob("*"):
        if path.name in _DEVELOPMENT_TOOL_NAMES:
            return False
    return True


def _system_libraries_only(executable: pathlib.Path) -> bool:
    result = subprocess.run(
        ["/usr/bin/otool", "-L", str(executable)],
        check=True,
        capture_output=True,
        text=True,
    )
    lines = result.stdout.splitlines()[1:]
    if not lines:
        raise ValueError("otool reported no linked libraries")
    for line in lines:
        fields = line.strip().split()
        if not fields:
            continue
        library = fields[0]
        if not (library.startswith("/System/") or library.startswith("/usr/lib/")):
            return False
    return True


def _capability_symbol_present(framework_binary: pathlib.Path) -> bool:
    result = subprocess.run(
        ["/usr/bin/nm", "-gU", str(framework_binary)],
        check=True,
        capture_output=True,
        text=True,
    )
    return any(line.rstrip().endswith("_adapter_capabilities") for line in result.stdout.splitlines())


def collect_preflight(app: pathlib.Path, source_commit: str) -> dict[str, Any]:
    source_commit = _validated_source_commit(source_commit)
    app = app.resolve()
    executable = _shipping_executable(app)
    info = _shipping_info(app)
    validate_shipping_info(info, source_commit)

    resources = app / "Contents" / "Resources"
    expected_paths = {name: resources / name for name in _RESOURCE_NAMES}
    if not all(path.exists() for path in expected_paths.values()):
        raise ValueError("shipping media resources are incomplete")

    provenance = _load_provenance(expected_paths["media-transport-provenance.json"])
    expected_provenance = {
        "schemaVersion": 1,
        "sourceCommit": source_commit,
        "adapterCommit": EXPECTED_ADAPTER_COMMIT,
        "adapterPatchSHA256": EXPECTED_PATCH_SHA256,
    }
    if provenance != expected_provenance:
        raise ValueError("shipping media provenance mismatch")

    framework = expected_paths["MediaRemoteAdapter.framework"]
    framework_binary = framework / "Versions" / "A" / "MediaRemoteAdapter"
    if not framework_binary.is_file():
        raise ValueError("shipping media framework binary is missing")

    subprocess.run(
        ["/usr/bin/codesign", "--verify", "--deep", "--strict", str(app)],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    subprocess.run(
        ["/usr/bin/codesign", "--verify", "--strict", str(framework)],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    if not _codesign_has_runtime(app):
        raise ValueError("shipping Hardened Runtime flag is missing")
    if _effective_entitlements(app) != {"com.apple.security.app-sandbox": True}:
        raise ValueError("shipping effective entitlements are not exactly sandbox-only")
    if not _development_tools_absent(app):
        raise ValueError("development media tooling is present in shipping app")
    if not _system_libraries_only(executable):
        raise ValueError("shipping executable links an unexpected non-system library")
    if not _capability_symbol_present(framework_binary):
        raise ValueError("shipping media framework capability symbol is missing")

    return {
        "schemaVersion": 1,
        "sourceCommit": source_commit,
        "adapterCommit": EXPECTED_ADAPTER_COMMIT,
        "adapterPatchSHA256": EXPECTED_PATCH_SHA256,
        "bundleIdentifier": EXPECTED_BUNDLE_IDENTIFIER,
        "platform": _platform(),
        "resourcesVerified": True,
        "provenanceVerified": True,
        "codesignVerified": True,
        "nestedCodesignVerified": True,
        "hardenedRuntime": True,
        "sandboxOnly": True,
        "systemLibrariesOnly": True,
        "developmentToolsAbsent": True,
        "capabilitySymbolVerified": True,
    }


def _process_exists(pid: int) -> bool:
    result = subprocess.run(
        ["/bin/ps", "-p", str(pid), "-o", "pid="],
        check=False,
        capture_output=True,
        text=True,
    )
    return result.returncode == 0 and result.stdout.strip() == str(pid)


def _discover_owned_adapter(parent_pid: int) -> int:
    deadline = time.monotonic() + _ADAPTER_DISCOVERY_TIMEOUT_SECONDS
    while True:
        try:
            return find_owned_adapter_pid(_ps_table(), parent_pid)
        except ValueError:
            if time.monotonic() >= deadline:
                raise
            time.sleep(_POLL_INTERVAL_SECONDS)


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


def _sleep_until(target: float) -> None:
    remaining = target - time.monotonic()
    if remaining > 0:
        time.sleep(remaining)


def collect_resources(parent_pid: int, source_commit: str, mode: str) -> dict[str, Any]:
    source_commit = _validated_source_commit(source_commit)
    if parent_pid <= 0:
        raise ValueError("parent pid must be positive")
    if not _process_exists(parent_pid):
        raise ValueError("shipping parent process is not running")

    warmup_seconds, duration_seconds, interval_seconds = _resource_config(mode)
    adapter_pid = _discover_owned_adapter(parent_pid)
    started_at = _utc_now()
    _sleep_until(time.monotonic() + warmup_seconds)

    parent_samples: list[ProcessSample] = []
    adapter_samples: list[ProcessSample] = []
    sample_count = int(round(duration_seconds / interval_seconds))
    sample_started = time.monotonic()
    for index in range(sample_count):
        if not _process_exists(parent_pid):
            raise RuntimeError("shipping parent exited during resource sampling")
        if not _process_exists(adapter_pid):
            raise RuntimeError("owned media adapter exited during resource sampling")
        parent_samples.append(_sample_process(parent_pid))
        adapter_samples.append(_sample_process(adapter_pid))
        if index + 1 < sample_count:
            _sleep_until(sample_started + ((index + 1) * interval_seconds))

    return build_resource_report(
        mode=mode,
        source_commit=source_commit,
        platform=_platform(),
        started_at=started_at,
        ended_at=_utc_now(),
        warmup_seconds=warmup_seconds,
        duration_seconds=duration_seconds,
        interval_seconds=interval_seconds,
        parent_samples=parent_samples,
        adapter_samples=adapter_samples,
    )


def collect_teardown(
    parent_pid: int,
    source_commit: str,
    timeout_seconds: float,
) -> dict[str, Any]:
    source_commit = _validated_source_commit(source_commit)
    if parent_pid <= 0:
        raise ValueError("parent pid must be positive")
    if not math.isfinite(timeout_seconds) or not (0 < timeout_seconds <= _MAX_TEARDOWN_TIMEOUT_SECONDS):
        raise ValueError("teardown timeout must be finite, positive, and <= 300 seconds")
    if not _process_exists(parent_pid):
        raise ValueError("shipping parent process is not running")

    adapter_pid = _discover_owned_adapter(parent_pid)
    deadline = time.monotonic() + timeout_seconds
    while _process_exists(parent_pid) and time.monotonic() < deadline:
        time.sleep(_POLL_INTERVAL_SECONDS)
    parent_exited = not _process_exists(parent_pid)

    while _process_exists(adapter_pid) and time.monotonic() < deadline:
        time.sleep(_POLL_INTERVAL_SECONDS)
    adapter_exited = not _process_exists(adapter_pid)

    return build_teardown_report(
        source_commit=source_commit,
        platform=_platform(),
        parent_exited=parent_exited,
        adapter_exited=adapter_exited,
    )


def _write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="NotchHub shipping media target-Mac acceptance")
    subparsers = parser.add_subparsers(dest="command", required=True)

    preflight = subparsers.add_parser("preflight", help="verify exact shipping bundle boundary")
    preflight.add_argument("--app", required=True, type=pathlib.Path)
    preflight.add_argument("--source-commit", required=True)
    preflight.add_argument("--output", required=True, type=pathlib.Path)

    resources = subparsers.add_parser("resources", help="measure shipping app plus owned adapter")
    resources.add_argument("--attach-pid", required=True, type=int)
    resources.add_argument("--source-commit", required=True)
    resources.add_argument("--mode", required=True, choices=("steady", "stability"))
    resources.add_argument("--output", required=True, type=pathlib.Path)

    teardown = subparsers.add_parser("teardown", help="verify normal app termination releases adapter")
    teardown.add_argument("--attach-pid", required=True, type=int)
    teardown.add_argument("--source-commit", required=True)
    teardown.add_argument("--timeout-seconds", type=float, default=60.0)
    teardown.add_argument("--output", required=True, type=pathlib.Path)

    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    try:
        if args.command == "preflight":
            result = collect_preflight(args.app, args.source_commit)
        elif args.command == "resources":
            result = collect_resources(args.attach_pid, args.source_commit, args.mode)
        elif args.command == "teardown":
            result = collect_teardown(args.attach_pid, args.source_commit, args.timeout_seconds)
        else:
            raise AssertionError(f"unhandled command: {args.command}")
        _write_json(args.output, result)
        print(f"Wrote shipping media acceptance evidence: {args.output}")
        if args.command == "teardown" and (
            not result["parentExited"]
            or not result["adapterExited"]
            or result["orphanProcessDetected"]
        ):
            return 1
        return 0
    except (
        OSError,
        subprocess.CalledProcessError,
        RuntimeError,
        TimeoutError,
        UnicodeError,
        ValueError,
        json.JSONDecodeError,
    ) as error:
        print(f"Shipping media acceptance failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
