#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import pathlib
import re
from collections.abc import Sequence


_FULL_SHA = re.compile(r"^[0-9a-f]{40}$")


def physical_tree_size_bytes(root: pathlib.Path) -> int:
    root = root.resolve(strict=False) if not root.is_symlink() else root
    if root.is_symlink() or not root.exists() or not root.is_dir():
        raise ValueError(f"artifact root must be an existing real directory: {root}")

    total = 0
    for path in root.rglob("*"):
        if path.is_symlink():
            continue
        if path.is_file():
            total += path.stat().st_size
    return total


def build_size_summary(
    *,
    app: pathlib.Path,
    dmg: pathlib.Path,
    source_commit: str,
) -> dict[str, int | str]:
    if not _FULL_SHA.fullmatch(source_commit):
        raise ValueError("source commit must be a lowercase full Git SHA")
    if not dmg.exists() or not dmg.is_file() or dmg.is_symlink():
        raise ValueError(f"DMG must be an existing real file: {dmg}")

    executable = app / "Contents" / "MacOS" / "NotchHub"
    if not executable.exists() or not executable.is_file() or executable.is_symlink():
        raise ValueError(f"shipping executable is missing or invalid: {executable}")

    return {
        "schemaVersion": 1,
        "sourceCommit": source_commit,
        "executableSizeBytes": executable.stat().st_size,
        "appSizeBytes": physical_tree_size_bytes(app),
        "dmgSizeBytes": dmg.stat().st_size,
    }


def _write_json(data: object, output: pathlib.Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(data, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Measure physical NotchHub artifact sizes")
    parser.add_argument("--app", required=True, type=pathlib.Path)
    parser.add_argument("--dmg", required=True, type=pathlib.Path)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args(argv)

    try:
        summary = build_size_summary(
            app=args.app,
            dmg=args.dmg,
            source_commit=args.source_commit,
        )
        _write_json(summary, args.output)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
