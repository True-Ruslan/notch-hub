#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
from dataclasses import dataclass
from typing import Any, Iterable

REPOSITORY_ROOT = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_DOCS_ROOT = REPOSITORY_ROOT / "docs" / "testing"
DEFAULT_MANIFEST = REPOSITORY_ROOT / "Tests" / "Acceptance" / "coverage.yml"

ID_PATTERN = re.compile(r"\bNH-[A-Z0-9]+(?:-[A-Z0-9]+)*-\d{3}\b")
STATUS_PATTERN = re.compile(r"^\s*Status:\s*(.+?)\s*$", re.IGNORECASE | re.MULTILINE)
ALLOWED_STATUSES = {"accepted", "pending", "rejected", "deferred"}
AUTOMATED_LAYERS = {"unit", "integration", "ui", "policy", "shipping"}
ALLOWED_LAYERS = AUTOMATED_LAYERS | {"physical"}
ENTRY_KEYS = {"id", "source", "status", "coverage", "physicalOnlyReason"}
COVERAGE_KEYS = {"layer", "test"}

# These IDs already exist in accepted M1 project/spec/testing history. Plan 2 makes
# them canonical under docs/testing so the machine-readable inventory cannot silently
# omit the interaction baseline just because it predates the acceptance-ledger layout.
REQUIRED_M1_IDS = {
    "NH-NOTCH-001",
    "NH-HOVER-001",
    "NH-HOVER-002",
    "NH-HOVER-003",
    "NH-HOVER-DELAY-001",
    "NH-HOVER-DELAY-002",
    "NH-HOVER-TOP-001",
    "NH-HAPTIC-001",
    "NH-HAPTIC-002",
    "NH-VISUAL-001",
    "NH-VISUAL-002",
    "NH-VISUAL-003",
    "NH-ANIM-001",
    "NH-ANIM-002",
    "NH-ANIM-003",
    "NH-ANIM-004",
    "NH-MOTION-001",
    "NH-MOTION-002",
    "NH-SPACE-001",
    "NH-DISPLAY-001",
}


class CoverageError(ValueError):
    pass


@dataclass(frozen=True)
class Contract:
    identifier: str
    source: pathlib.Path
    status: str


def _relative_to_repository(path: pathlib.Path) -> str:
    try:
        return path.resolve().relative_to(REPOSITORY_ROOT.resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def discover_contracts(docs_root: pathlib.Path) -> dict[str, Contract]:
    if not docs_root.is_dir():
        raise CoverageError(f"acceptance docs directory is missing: {docs_root}")

    occurrences: dict[str, list[pathlib.Path]] = {}
    contents: dict[pathlib.Path, str] = {}
    for path in sorted(docs_root.glob("*.md")):
        text = path.read_text(encoding="utf-8")
        contents[path] = text
        for identifier in sorted(set(ID_PATTERN.findall(text))):
            occurrences.setdefault(identifier, []).append(path)

    contracts: dict[str, Contract] = {}
    for identifier, paths in sorted(occurrences.items()):
        source = _canonical_source(identifier, paths)
        status = _infer_status(identifier, contents[source])
        contracts[identifier] = Contract(identifier=identifier, source=source, status=status)
    return contracts


def _canonical_source(identifier: str, paths: list[pathlib.Path]) -> pathlib.Path:
    acceptance = [path for path in paths if path.name.endswith("_ACCEPTANCE.md")]
    if len(acceptance) == 1:
        return acceptance[0]
    if len(acceptance) > 1:
        names = ", ".join(path.name for path in acceptance)
        raise CoverageError(f"{identifier}: ambiguous acceptance sources: {names}")
    return sorted(paths, key=lambda path: path.name)[0]


def _has_status_token(text: str, *tokens: str) -> bool:
    return any(
        re.search(rf"\b{re.escape(token)}\b", text, re.IGNORECASE) is not None
        for token in tokens
    )


def _infer_status(identifier: str, text: str) -> str:
    identifier_lines = [line for line in text.splitlines() if identifier in line]
    local = "\n".join(identifier_lines)
    if _has_status_token(local, "DEFERRED") or "NOT TESTED" in local.upper():
        return "deferred"
    if _has_status_token(local, "REJECTED", "FAIL", "FAILED"):
        return "rejected"
    if _has_status_token(local, "PASS", "PASSED"):
        return "accepted"

    match = STATUS_PATTERN.search(text)
    status_text = match.group(1) if match else ""
    if _has_status_token(status_text, "REJECTED", "FAIL", "FAILED"):
        return "rejected"
    if _has_status_token(status_text, "PENDING") or "IN PROGRESS" in status_text.upper():
        return "pending"
    if _has_status_token(status_text, "ACCEPTED") or "ACCEPT_" in status_text.upper():
        return "accepted"

    raise CoverageError(
        f"{identifier}: cannot infer ledger status from {_short_status(status_text)}"
    )


def _short_status(status_text: str) -> str:
    return repr(status_text[:120] if status_text else "<missing Status: line>")


def validate_repository_inventory(
    contracts: dict[str, Contract],
    docs_root: pathlib.Path,
) -> None:
    # Temporary docs roots used by focused validator tests remain generic. The frozen
    # M1 requirement applies only to the real repository acceptance inventory.
    if docs_root.resolve() != DEFAULT_DOCS_ROOT.resolve():
        return

    missing = sorted(REQUIRED_M1_IDS - set(contracts))
    if missing:
        raise CoverageError(
            "repository acceptance inventory is missing frozen M1 ids: "
            + ", ".join(missing)
        )


def load_manifest(path: pathlib.Path) -> list[dict[str, Any]]:
    if not path.is_file():
        raise CoverageError(f"acceptance coverage manifest is missing: {path}")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise CoverageError(
            f"{path}: manifest must use JSON-compatible YAML: {error}"
        ) from error

    if not isinstance(data, dict) or set(data) != {"schemaVersion", "entries"}:
        raise CoverageError("manifest must contain exactly schemaVersion and entries")
    if data["schemaVersion"] != 1:
        raise CoverageError(f"unsupported manifest schemaVersion: {data['schemaVersion']!r}")
    entries = data["entries"]
    if not isinstance(entries, list):
        raise CoverageError("manifest entries must be a list")
    return entries


def validate_manifest(
    entries: list[dict[str, Any]],
    contracts: dict[str, Contract],
    *,
    mode: str,
) -> dict[str, dict[str, Any]]:
    seen: set[str] = set()
    mapped: dict[str, dict[str, Any]] = {}

    for index, raw_entry in enumerate(entries):
        label = f"entries[{index}]"
        if not isinstance(raw_entry, dict) or set(raw_entry) != ENTRY_KEYS:
            raise CoverageError(f"{label}: entry must contain exactly {sorted(ENTRY_KEYS)}")

        identifier = raw_entry["id"]
        if not isinstance(identifier, str) or not ID_PATTERN.fullmatch(identifier):
            raise CoverageError(f"{label}: invalid acceptance id: {identifier!r}")
        if identifier in seen:
            raise CoverageError(f"duplicate acceptance id in manifest: {identifier}")
        seen.add(identifier)

        contract = contracts.get(identifier)
        if contract is None:
            raise CoverageError(f"{identifier}: manifest id is not present in acceptance docs")

        source = raw_entry["source"]
        expected_source = _relative_to_repository(contract.source)
        if source != expected_source:
            raise CoverageError(
                f"{identifier}: source mismatch: expected {expected_source!r}, got {source!r}"
            )

        status = raw_entry["status"]
        if status not in ALLOWED_STATUSES:
            raise CoverageError(f"{identifier}: unsupported status: {status!r}")
        if status != contract.status:
            raise CoverageError(
                f"{identifier}: manifest status {status!r} disagrees with ledger status {contract.status!r}"
            )

        coverage = raw_entry["coverage"]
        if not isinstance(coverage, list):
            raise CoverageError(f"{identifier}: coverage must be a list")
        automated_count = 0
        physical_count = 0
        for coverage_index, item in enumerate(coverage):
            coverage_label = f"{identifier}.coverage[{coverage_index}]"
            if not isinstance(item, dict) or set(item) != COVERAGE_KEYS:
                raise CoverageError(
                    f"{coverage_label}: coverage item must contain exactly {sorted(COVERAGE_KEYS)}"
                )
            layer = item["layer"]
            if layer not in ALLOWED_LAYERS:
                raise CoverageError(f"{coverage_label}: unsupported layer: {layer!r}")
            test = item["test"]
            if layer == "physical":
                if test is not None:
                    raise CoverageError(f"{coverage_label}: physical coverage test must be null")
                physical_count += 1
            else:
                if not isinstance(test, str) or test.count(".") < 2:
                    raise CoverageError(
                        f"{coverage_label}: automated test must use Module.Suite.testName"
                    )
                _validate_test_reference(test)
                automated_count += 1

        physical_reason = raw_entry["physicalOnlyReason"]
        if physical_count:
            if not isinstance(physical_reason, str) or len(physical_reason.strip()) < 40:
                raise CoverageError(
                    f"{identifier}: physical coverage requires a concrete physicalOnlyReason"
                )
        elif physical_reason is not None:
            raise CoverageError(
                f"{identifier}: physicalOnlyReason requires a physical coverage item"
            )

        if status == "accepted" and automated_count == 0 and physical_count == 0:
            raise CoverageError(f"{identifier}: accepted contract has no evidence")

        mapped[identifier] = raw_entry

    unmapped = sorted(set(contracts) - set(mapped))
    if mode == "strict" and unmapped:
        raise CoverageError(
            "strict mode requires complete mapping; unmapped: " + ", ".join(unmapped)
        )

    return mapped


def _validate_test_reference(reference: str) -> None:
    module, suite, test_name = reference.split(".", 2)
    if not module or not suite or not test_name:
        raise CoverageError(f"invalid automated test reference: {reference!r}")

    if module == "scripts":
        source_path = REPOSITORY_ROOT / "scripts" / _python_source_name_for_suite(suite)
        if not source_path.is_file():
            raise CoverageError(f"automated test source is missing: {source_path}")
        source = source_path.read_text(encoding="utf-8")
        if f"def {test_name}(" not in source:
            raise CoverageError(f"automated test reference is missing: {reference}")
        return

    tests_root = REPOSITORY_ROOT / "Tests"
    candidates = list(tests_root.glob(f"**/{suite}.swift"))
    if not candidates:
        raise CoverageError(f"automated test suite source is missing: {reference}")
    if not any(f"func {test_name}(" in path.read_text(encoding="utf-8") for path in candidates):
        raise CoverageError(f"automated test reference is missing: {reference}")


def _python_source_name_for_suite(suite: str) -> str:
    words = re.findall(r"[A-Z]+(?=[A-Z][a-z]|\d|$)|[A-Z]?[a-z]+|\d+", suite)
    snake = "_".join(word.lower() for word in words)
    return f"test_{snake}.py"


def summarize(
    contracts: dict[str, Contract],
    mapped: dict[str, dict[str, Any]],
) -> dict[str, int]:
    automated = 0
    physical_only = 0
    mixed = 0
    accepted = 0
    for entry in mapped.values():
        if entry["status"] == "accepted":
            accepted += 1
        layers = {item["layer"] for item in entry["coverage"]}
        if layers & AUTOMATED_LAYERS and "physical" in layers:
            mixed += 1
        elif layers & AUTOMATED_LAYERS:
            automated += 1
        elif "physical" in layers:
            physical_only += 1

    return {
        "discovered": len(contracts),
        "mapped": len(mapped),
        "unmapped": len(contracts) - len(mapped),
        "accepted": accepted,
        "automatedOnly": automated,
        "mixed": mixed,
        "physicalOnly": physical_only,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=("audit", "strict"), default="audit")
    parser.add_argument("--docs-root", type=pathlib.Path, default=DEFAULT_DOCS_ROOT)
    parser.add_argument("--manifest", type=pathlib.Path, default=DEFAULT_MANIFEST)
    args = parser.parse_args(argv)

    try:
        contracts = discover_contracts(args.docs_root)
        validate_repository_inventory(contracts, args.docs_root)
        entries = load_manifest(args.manifest)
        mapped = validate_manifest(entries, contracts, mode=args.mode)
        summary = summarize(contracts, mapped)
    except CoverageError as error:
        print(f"Acceptance coverage {args.mode} failed: {error}", file=sys.stderr)
        return 1

    print(
        f"Acceptance coverage {args.mode} passed: "
        f"discovered={summary['discovered']} "
        f"mapped={summary['mapped']} "
        f"unmapped={summary['unmapped']} "
        f"accepted={summary['accepted']} "
        f"automatedOnly={summary['automatedOnly']} "
        f"mixed={summary['mixed']} "
        f"physicalOnly={summary['physicalOnly']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
