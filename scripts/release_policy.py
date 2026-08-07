#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

_SEMVER_RE = re.compile(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)")
_SHA40_RE = re.compile(r"[0-9a-fA-F]{40}")
_SHA256_RE = re.compile(r"[0-9a-fA-F]{64}")
_PERSONAL_WARNING_HEADING = "## Personal build — not notarized"
_UNSAFE_NOTE_PATTERNS = (
    re.compile(r"xattr\s+-[^\n]*com\.apple\.quarantine", re.IGNORECASE),
    re.compile(r"(?<!do not )(?<!never )disable\s+Gatekeeper", re.IGNORECASE),
    re.compile(r"spctl\s+--master-disable", re.IGNORECASE),
)
_REQUIRED_PERSONAL_WORKFLOW_FRAGMENTS = (
    "name: Personal Release",
    "workflow_dispatch:",
    "permissions:\n  contents: write",
    "runs-on: macos-26",
    "persist-credentials: false",
    "fetch-depth: 0",
    'test "$GITHUB_REF_NAME" = "main"',
    "scripts/release_policy.py validate-notes",
    "scripts/security-audit.sh",
    "swift build -Xswiftc -warnings-as-errors",
    "swift test --parallel --enable-code-coverage",
    "CODE_SIGN_IDENTITY: \"-\"",
    "Signature=adhoc",
    "codesign --verify --deep --strict",
    "flags=.*runtime",
    "com.apple.security.app-sandbox",
    "hdiutil verify",
    "shasum -a 256",
    "scripts/release_policy.py metadata",
    "gh release view",
    "git rev-parse -q --verify",
    "gh release create",
    "--notes-file",
    "build-metadata.json",
)
_FORBIDDEN_PERSONAL_WORKFLOW_FRAGMENTS = (
    "notarytool",
    "Developer ID Application",
    "APPLE_DEVELOPER_ID",
    "APPLE_NOTARY",
    "environment: release",
    "secrets.",
    "--clobber",
    "gh release upload",
    "xattr",
    "spctl --master-disable",
    "pull_request_target",
)


def parse_semver(value: str) -> tuple[int, int, int]:
    match = _SEMVER_RE.fullmatch(value)
    if match is None:
        raise ValueError(f"invalid strict SemVer release version: {value!r}")
    return tuple(int(component) for component in match.groups())  # type: ignore[return-value]


def release_tag(version: str) -> str:
    parse_semver(version)
    return f"v{version}"


def validate_personal_release_notes(text: str, version: str) -> None:
    release_tag(version)
    lines = text.splitlines()
    nonempty = [(index, line.strip()) for index, line in enumerate(lines) if line.strip()]
    if not nonempty:
        raise ValueError("release notes are empty")

    _, title = nonempty[0]
    expected_title = f"# NotchHub v{version} — Personal build"
    if title != expected_title:
        raise ValueError(f"personal release title must be exactly: {expected_title}")

    headings_after_title = [line for _, line in nonempty[1:] if line.startswith("## ")]
    if not headings_after_title or headings_after_title[0] != _PERSONAL_WARNING_HEADING:
        raise ValueError(f"first level-2 section must be exactly: {_PERSONAL_WARNING_HEADING}")

    lower = text.lower()
    if "ad-hoc signed" not in lower:
        raise ValueError("personal release notes must state that the build is ad-hoc signed")
    if "open anyway" not in lower:
        raise ValueError("personal release notes must document the standard Open Anyway path")
    if "notarized" not in lower:
        raise ValueError("personal release notes must state notarization status")

    for pattern in _UNSAFE_NOTE_PATTERNS:
        if pattern.search(text):
            raise ValueError(f"unsafe Gatekeeper-bypass instruction matched: {pattern.pattern}")


def validate_personal_release_workflow(text: str) -> None:
    for fragment in _REQUIRED_PERSONAL_WORKFLOW_FRAGMENTS:
        if fragment not in text:
            raise ValueError(f"personal release workflow is missing required invariant: {fragment}")

    for fragment in _FORBIDDEN_PERSONAL_WORKFLOW_FRAGMENTS:
        if fragment in text:
            raise ValueError(f"personal release workflow contains forbidden trust-boundary fragment: {fragment}")

    # Personal publication is intentionally manual. A top-level push trigger would
    # make publishing possible without the deliberate workflow_dispatch action.
    trigger_prefix = text.split("permissions:", maxsplit=1)[0]
    if re.search(r"(?m)^\s{2}push:\s*$", trigger_prefix):
        raise ValueError("personal release workflow must not publish from a push trigger")


def _positive_build_number(value: str) -> int:
    if not value.isascii() or not value.isdigit():
        raise ValueError("build number must contain only ASCII decimal digits")
    number = int(value)
    if number <= 0:
        raise ValueError("build number must be positive")
    return number


def _non_negative_size(name: str, value: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise ValueError(f"{name} must be a non-negative integer")
    return value


def build_metadata(
    *,
    version: str,
    build_number: str,
    source_sha: str,
    runner_os: str,
    xcode_version: str,
    swift_version: str,
    dmg_sha256: str,
    dmg_size_bytes: int,
    app_size_bytes: int,
    executable_size_bytes: int,
) -> dict[str, Any]:
    tag = release_tag(version)
    build = _positive_build_number(build_number)
    if _SHA40_RE.fullmatch(source_sha) is None:
        raise ValueError("source commit must be exactly 40 hexadecimal characters")
    if _SHA256_RE.fullmatch(dmg_sha256) is None:
        raise ValueError("DMG SHA-256 must be exactly 64 hexadecimal characters")

    return {
        "schemaVersion": 1,
        "version": version,
        "tag": tag,
        "buildNumber": build,
        "sourceCommit": source_sha.lower(),
        "runnerOS": runner_os,
        "xcodeVersion": xcode_version,
        "swiftVersion": swift_version,
        "dmgSHA256": dmg_sha256.lower(),
        "dmgSizeBytes": _non_negative_size("DMG size", dmg_size_bytes),
        "appSizeBytes": _non_negative_size("app size", app_size_bytes),
        "executableSizeBytes": _non_negative_size("executable size", executable_size_bytes),
        "distributionTier": "personal",
        "appleTrusted": False,
        "notarized": False,
    }


def _cmd_validate_notes(args: argparse.Namespace) -> int:
    text = Path(args.notes).read_text(encoding="utf-8")
    validate_personal_release_notes(text, args.version)
    print("Personal release notes policy passed.")
    return 0


def _cmd_validate_workflow(args: argparse.Namespace) -> int:
    text = Path(args.workflow).read_text(encoding="utf-8")
    validate_personal_release_workflow(text)
    print("Personal release workflow policy passed.")
    return 0


def _cmd_metadata(args: argparse.Namespace) -> int:
    metadata = build_metadata(
        version=args.version,
        build_number=args.build_number,
        source_sha=args.source_sha,
        runner_os=args.runner_os,
        xcode_version=args.xcode_version,
        swift_version=args.swift_version,
        dmg_sha256=args.dmg_sha256,
        dmg_size_bytes=args.dmg_size_bytes,
        app_size_bytes=args.app_size_bytes,
        executable_size_bytes=args.executable_size_bytes,
    )
    output = json.dumps(metadata, sort_keys=True, indent=2) + "\n"
    Path(args.output).write_text(output, encoding="utf-8")
    return 0


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="NotchHub personal-release policy helpers")
    subparsers = parser.add_subparsers(dest="command", required=True)

    notes = subparsers.add_parser("validate-notes", help="validate personal release notes")
    notes.add_argument("--version", required=True)
    notes.add_argument("--notes", required=True)
    notes.set_defaults(handler=_cmd_validate_notes)

    workflow = subparsers.add_parser("validate-workflow", help="validate Personal Release workflow")
    workflow.add_argument("--workflow", required=True)
    workflow.set_defaults(handler=_cmd_validate_workflow)

    metadata = subparsers.add_parser("metadata", help="write deterministic release metadata JSON")
    metadata.add_argument("--version", required=True)
    metadata.add_argument("--build-number", required=True)
    metadata.add_argument("--source-sha", required=True)
    metadata.add_argument("--runner-os", required=True)
    metadata.add_argument("--xcode-version", required=True)
    metadata.add_argument("--swift-version", required=True)
    metadata.add_argument("--dmg-sha256", required=True)
    metadata.add_argument("--dmg-size-bytes", required=True, type=int)
    metadata.add_argument("--app-size-bytes", required=True, type=int)
    metadata.add_argument("--executable-size-bytes", required=True, type=int)
    metadata.add_argument("--output", required=True)
    metadata.set_defaults(handler=_cmd_metadata)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = _parser()
    args = parser.parse_args(argv)
    try:
        return int(args.handler(args))
    except (OSError, ValueError) as exc:
        print(f"RELEASE POLICY FAILED: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
