#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
from collections.abc import Sequence

ADAPTER_COMMIT = "3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
SCENARIO_IDS = tuple(f"NH-MEDIA-BRIDGE-{index:03d}" for index in range(1, 19))
RESULT_VALUES = ("PASS", "FAIL", "NOT_SUPPORTED", "NEEDS_REDESIGN")
_SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")


def parse_result(value: str) -> tuple[str, str]:
    if "=" not in value:
        raise ValueError("result must use SCENARIO_ID=STATUS")
    scenario_id, status = value.split("=", maxsplit=1)
    if scenario_id not in SCENARIO_IDS:
        raise ValueError(f"unknown media bridge scenario: {scenario_id}")
    if status not in RESULT_VALUES:
        raise ValueError(f"unsupported media bridge result: {status}")
    return scenario_id, status


def build_acceptance_record(
    *,
    source_commit: str,
    macos_version: str,
    hardware_model: str,
    result_values: Sequence[str],
) -> dict[str, object]:
    if not _SHA_PATTERN.fullmatch(source_commit):
        raise ValueError("source commit must be a lowercase 40-character Git SHA")
    if not macos_version or len(macos_version) > 64:
        raise ValueError("macOS version must be present and bounded")
    if not hardware_model or len(hardware_model) > 128:
        raise ValueError("hardware model must be present and bounded")

    results: dict[str, str] = {}
    for value in result_values:
        scenario_id, status = parse_result(value)
        if scenario_id in results:
            raise ValueError(f"duplicate media bridge scenario: {scenario_id}")
        results[scenario_id] = status

    if not results:
        raise ValueError("at least one media bridge result is required")

    return {
        "schemaVersion": 1,
        "sourceCommit": source_commit,
        "adapterCommit": ADAPTER_COMMIT,
        "platform": {
            "macOS": macos_version,
            "hardwareModel": hardware_model,
        },
        "results": dict(sorted(results.items())),
    }


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Record privacy-safe NotchHub media bridge probe acceptance results"
    )
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--macos", required=True)
    parser.add_argument("--hardware-model", required=True)
    parser.add_argument("--result", action="append", required=True)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    try:
        record = build_acceptance_record(
            source_commit=args.source_commit,
            macos_version=args.macos,
            hardware_model=args.hardware_model,
            result_values=args.result,
        )
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(
            json.dumps(record, sort_keys=True, indent=2) + "\n",
            encoding="utf-8",
        )
    except (OSError, UnicodeError, ValueError) as error:
        print(f"Media bridge acceptance record failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
