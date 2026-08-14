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
DEFAULT_SUPERSESSIONS = REPOSITORY_ROOT / "Tests" / "Acceptance" / "supersessions.json"

ID_PATTERN = re.compile(r"\bNH-[A-Z0-9]+(?:-[A-Z0-9]+)*-\d{3}\b")
STATUS_PATTERN = re.compile(r"^\s*Status:\s*(.+?)\s*$", re.IGNORECASE | re.MULTILINE)
ALLOWED_STATUSES = {"accepted", "pending", "rejected", "deferred"}
AUTOMATED_LAYERS = {"unit", "integration", "ui", "policy", "shipping"}
ALLOWED_LAYERS = AUTOMATED_LAYERS | {"physical"}
ENTRY_KEYS = {"id", "source", "status", "coverage", "physicalOnlyReason"}
COVERAGE_KEYS = {"layer", "test"}
SUPERSESSION_KEYS = {"id", "supersededBy", "decisionSource"}

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


def _has_explicit_local_status_token(text: str, *tokens: str) -> bool:
    # Acceptance ledgers record per-ID outcomes with explicit uppercase tokens such as
    # PASS / FAIL / DEFERRED. Keep this check case-sensitive so ordinary contract prose
    # like "failed capability" cannot silently redefine the ledger's document status.
    return any(re.search(rf"\b{re.escape(token)}\b", text) is not None for token in tokens)


def _infer_status(identifier: str, text: str) -> str:
    identifier_lines = [line for line in text.splitlines() if identifier in line]
    local = "\n".join(identifier_lines)
    if _has_explicit_local_status_token(local, "DEFERRED") or "NOT TESTED" in local:
        return "deferred"
    if _has_explicit_local_status_token(local, "REJECTED", "FAIL", "FAILED"):
        return "rejected"
    if _has_explicit_local_status_token(local, "PASS", "PASSED"):
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


def _load_json_entries(path: pathlib.Path, *, label: str) -> list[dict[str, Any]]:
    if not path.is_file():
        raise CoverageError(f"{label} is missing: {path}")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise CoverageError(f"{path}: {label} must be valid JSON: {error}") from error

    if not isinstance(data, dict) or set(data) != {"schemaVersion", "entries"}:
        raise CoverageError(f"{label} must contain exactly schemaVersion and entries")
    if data["schemaVersion"] != 1:
        raise CoverageError(f"unsupported {label} schemaVersion: {data['schemaVersion']!r}")
    entries = data["entries"]
    if not isinstance(entries, list):
        raise CoverageError(f"{label} entries must be a list")
    return entries


def load_manifest(path: pathlib.Path) -> list[dict[str, Any]]:
    return _load_json_entries(path, label="acceptance coverage manifest")


def load_supersessions(path: pathlib.Path) -> list[dict[str, Any]]:
    return _load_json_entries(path, label="acceptance supersession ledger")


def validate_supersessions(
    entries: list[dict[str, Any]],
    contracts: dict[str, Contract],
    *,
    repository_root: pathlib.Path = REPOSITORY_ROOT,
) -> dict[str, dict[str, Any]]:
    seen: set[str] = set()
    supersessions: dict[str, dict[str, Any]] = {}
    specs_root = (repository_root / "docs" / "superpowers" / "specs").resolve()

    for index, raw_entry in enumerate(entries):
        label = f"supersessions[{index}]"
        if not isinstance(raw_entry, dict) or set(raw_entry) != SUPERSESSION_KEYS:
            raise CoverageError(
                f"{label}: supersession must contain exactly {sorted(SUPERSESSION_KEYS)}"
            )

        identifier = raw_entry["id"]
        replacement = raw_entry["supersededBy"]
        decision_source = raw_entry["decisionSource"]
        for field_name, value in (("id", identifier), ("supersededBy", replacement)):
            if not isinstance(value, str) or not ID_PATTERN.fullmatch(value):
                raise CoverageError(f"{label}: invalid {field_name}: {value!r}")
        if identifier == replacement:
            raise CoverageError(f"{identifier}: acceptance contract cannot supersede itself")
        if identifier in seen:
            raise CoverageError(f"{identifier}: duplicate supersession entry")
        seen.add(identifier)

        source_contract = contracts.get(identifier)
        if source_contract is None:
            raise CoverageError(f"{identifier}: supersession source is not a discovered acceptance id")
        if source_contract.status != "accepted":
            raise CoverageError(
                f"{identifier}: only a historically accepted contract may be superseded"
            )
        if replacement not in contracts:
            raise CoverageError(
                f"{identifier}: supersededBy target is not a discovered acceptance id: {replacement}"
            )

        if not isinstance(decision_source, str) or not decision_source.strip():
            raise CoverageError(f"{identifier}: decisionSource must be a non-empty path")
        decision_path = pathlib.Path(decision_source)
        if not decision_path.is_absolute():
            decision_path = repository_root / decision_path
        decision_path = decision_path.resolve()
        try:
            decision_path.relative_to(specs_root)
        except ValueError as error:
            raise CoverageError(
                f"{identifier}: decisionSource must be under docs/superpowers/specs"
            ) from error
        if not decision_path.is_file():
            raise CoverageError(f"{identifier}: supersession decision source is missing: {decision_path}")
        decision_text = decision_path.read_text(encoding="utf-8")
        if re.search(r"\bsupersed(?:e|es|ed|ing)\b", decision_text, re.IGNORECASE) is None:
            raise CoverageError(
                f"{identifier}: decisionSource does not explicitly supersede earlier behavior"
            )

        supersessions[identifier] = raw_entry

    chained = sorted(set(supersessions).intersection(
        entry["supersededBy"] for entry in supersessions.values()
    ))
    if chained:
        raise CoverageError(
            "chained acceptance supersessions are not supported: " + ", ".join(chained)
        )

    return supersessions


def validate_manifest(
    entries: list[dict[str, Any]],
    contracts: dict[str, Contract],
    *,
    mode: str,
    supersessions: dict[str, dict[str, Any]] | None = None,
) -> dict[str, dict[str, Any]]:
    seen: set[str] = set()
    mapped: dict[str, dict[str, Any]] = {}
    supersessions = supersessions or {}

    for index, raw_entry in enumerate(entries):
        label = f"entries[{index}]"
        if not isinstance(raw_entry, dict) or set(raw_entry) != ENTRY_KEYS:
            raise CoverageError(f"{label}: entry must contain exactly {sorted(ENTRY_KEYS)}")

        identifier = raw_entry["id"]
        if not isinstance(identifier, str) or not ID_PATTERN.fullmatch(identifier):
            raise CoverageError(f"{label}: invalid acceptance id: {identifier!r}")
        if identifier in seen:
            raise CoverageError(f"{identifier}: duplicate manifest entry")
        seen.add(identifier)

        contract = contracts.get(identifier)
        if contract is None:
            raise CoverageError(f"{identifier}: manifest id is not present in docs/testing")

        source = raw_entry["source"]
        if not isinstance(source, str):
            raise CoverageError(f"{identifier}: source must be a repository-relative path")
        expected_source = _relative_to_repository(contract.source)
        if source != expected_source:
            raise CoverageError(
                f"{identifier}: source {source!r} does not match canonical ledger {expected_source!r}"
            )

        status = raw_entry["status"]
        if status not in ALLOWED_STATUSES:
            raise CoverageError(f"{identifier}: invalid status {status!r}")
        if status != contract.status:
            raise CoverageError(
                f"{identifier}: manifest status {status!r} disagrees with ledger status "
                f"{contract.status!r}"
            )

        coverage = _validate_coverage(identifier, raw_entry["coverage"])
        reason = raw_entry["physicalOnlyReason"]
        if reason is not None and (not isinstance(reason, str) or not reason.strip()):
            raise CoverageError(
                f"{identifier}: physicalOnlyReason must be null or non-empty text"
            )
        has_physical = any(item["layer"] == "physical" for item in coverage)
        if has_physical and not reason:
            raise CoverageError(
                f"{identifier}: physical coverage requires physicalOnlyReason"
            )
        if reason and not has_physical:
            raise CoverageError(
                f"{identifier}: physicalOnlyReason requires a physical coverage layer"
            )

        if status == "accepted" and not coverage:
            raise CoverageError(
                f"{identifier}: mapped accepted contract must cite automated or physical evidence"
            )
        if status == "accepted" and not any(
            item["layer"] in AUTOMATED_LAYERS for item in coverage
        ) and not reason:
            raise CoverageError(
                f"{identifier}: accepted contract lacks automated coverage or physical-only reason"
            )

        # Supersession preserves historical evidence while explicitly declaring that its
        # old current-source symbol may disappear because an approved product contract
        # replaced the behavior. Non-superseded accepted contracts remain fail-closed.
        if identifier not in supersessions:
            for item in coverage:
                if item["layer"] in AUTOMATED_LAYERS:
                    _validate_test_reference(identifier, item["test"])

        mapped[identifier] = raw_entry

    if mode == "strict":
        missing = sorted(set(contracts) - set(mapped))
        if missing:
            preview = ", ".join(missing[:8])
            suffix = "" if len(missing) <= 8 else f", ... (+{len(missing) - 8})"
            raise CoverageError(
                f"strict coverage requires every discovered acceptance id; missing "
                f"{len(missing)}: {preview}{suffix}"
            )

    return mapped


def _validate_coverage(identifier: str, coverage: Any) -> list[dict[str, Any]]:
    if not isinstance(coverage, list):
        raise CoverageError(f"{identifier}: coverage must be a list")

    normalized: list[dict[str, Any]] = []
    seen: set[tuple[str, str | None]] = set()
    for index, raw_item in enumerate(coverage):
        label = f"{identifier}.coverage[{index}]"
        if not isinstance(raw_item, dict) or set(raw_item) != COVERAGE_KEYS:
            raise CoverageError(
                f"{label}: coverage item must contain exactly {sorted(COVERAGE_KEYS)}"
            )
        layer = raw_item["layer"]
        test = raw_item["test"]
        if layer not in ALLOWED_LAYERS:
            raise CoverageError(f"{label}: invalid layer {layer!r}")
        if layer in AUTOMATED_LAYERS:
            if not isinstance(test, str) or not test.strip():
                raise CoverageError(f"{label}: automated layer requires test reference")
        elif test is not None:
            raise CoverageError(f"{label}: physical coverage test must be null")

        key = (layer, test)
        if key in seen:
            raise CoverageError(f"{label}: duplicate coverage evidence")
        seen.add(key)
        normalized.append({"layer": layer, "test": test})
    return normalized


def _validate_test_reference(identifier: str, reference: str) -> None:
    parts = reference.split(".")
    if len(parts) < 3 or any(not part for part in parts):
        raise CoverageError(
            f"{identifier}: test reference must be Module.Suite.testName: {reference!r}"
        )
    symbol = parts[-1]
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", symbol):
        raise CoverageError(f"{identifier}: invalid test symbol in {reference!r}")

    swift_pattern = re.compile(rf"\bfunc\s+{re.escape(symbol)}\s*\(")
    python_pattern = re.compile(rf"\bdef\s+{re.escape(symbol)}\s*\(")

    for path in _test_source_files():
        text = path.read_text(encoding="utf-8")
        pattern = python_pattern if path.suffix == ".py" else swift_pattern
        if pattern.search(text):
            return
    raise CoverageError(f"{identifier}: referenced test symbol does not exist: {reference}")


def _test_source_files() -> Iterable[pathlib.Path]:
    tests_root = REPOSITORY_ROOT / "Tests"
    if tests_root.is_dir():
        yield from sorted(tests_root.rglob("*.swift"))
    scripts_root = REPOSITORY_ROOT / "scripts"
    if scripts_root.is_dir():
        yield from sorted(scripts_root.glob("test_*.py"))


def build_report(
    contracts: dict[str, Contract],
    mapped: dict[str, dict[str, Any]],
    *,
    mode: str,
    supersessions: dict[str, dict[str, Any]] | None = None,
) -> dict[str, Any]:
    rows: list[dict[str, Any]] = []
    supersessions = supersessions or {}
    for identifier, contract in sorted(contracts.items()):
        entry = mapped.get(identifier)
        evidence = list(entry["coverage"]) if entry else []
        automated = any(item.get("layer") in AUTOMATED_LAYERS for item in evidence)
        supersession = supersessions.get(identifier)
        rows.append(
            {
                "id": identifier,
                "source": _relative_to_repository(contract.source),
                "status": contract.status,
                "currentStatus": "superseded" if supersession else contract.status,
                "supersededBy": supersession["supersededBy"] if supersession else None,
                "existingEvidence": evidence,
                "missingAutomation": not automated,
            }
        )
    return {"schemaVersion": 1, "mode": mode, "contracts": rows}


def validate_report(report: dict[str, Any]) -> None:
    rows = report.get("contracts")
    if not isinstance(rows, list):
        raise CoverageError("acceptance report contracts must be a list")
    identifiers = [row.get("id") for row in rows if isinstance(row, dict)]
    if len(identifiers) != len(rows):
        raise CoverageError("acceptance report contains a non-object contract row")
    if identifiers != sorted(identifiers):
        raise CoverageError("acceptance report contract ids must be sorted")
    if len(identifiers) != len(set(identifiers)):
        raise CoverageError("acceptance report contract ids must be unique")


def write_report(report: dict[str, Any], path: pathlib.Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Audit NotchHub acceptance traceability")
    parser.add_argument("--mode", choices=("audit", "strict"), required=True)
    parser.add_argument("--manifest", type=pathlib.Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--docs-root", type=pathlib.Path, default=DEFAULT_DOCS_ROOT)
    parser.add_argument("--supersessions", type=pathlib.Path)
    parser.add_argument("--report", type=pathlib.Path)
    args = parser.parse_args(argv)

    try:
        contracts = discover_contracts(args.docs_root)
        validate_repository_inventory(contracts, args.docs_root)
        entries = load_manifest(args.manifest)
        if args.supersessions is not None:
            supersession_entries = load_supersessions(args.supersessions)
        elif args.docs_root.resolve() == DEFAULT_DOCS_ROOT.resolve():
            supersession_entries = load_supersessions(DEFAULT_SUPERSESSIONS)
        else:
            supersession_entries = []
        supersessions = validate_supersessions(supersession_entries, contracts)
        mapped = validate_manifest(
            entries,
            contracts,
            mode=args.mode,
            supersessions=supersessions,
        )
        report = build_report(
            contracts,
            mapped,
            mode=args.mode,
            supersessions=supersessions,
        )
        validate_report(report)
        if args.report:
            write_report(report, args.report)
    except (CoverageError, OSError) as error:
        print(f"Acceptance coverage {args.mode} failed: {error}", file=sys.stderr)
        return 1

    unmapped = len(contracts) - len(mapped)
    missing_automation = sum(
        1 for row in report["contracts"] if row["missingAutomation"]
    )
    superseded = sum(1 for row in report["contracts"] if row["currentStatus"] == "superseded")
    print(
        f"Acceptance coverage {args.mode} passed: "
        f"discovered={len(contracts)} mapped={len(mapped)} "
        f"unmapped={unmapped} missingAutomation={missing_automation} "
        f"superseded={superseded}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
