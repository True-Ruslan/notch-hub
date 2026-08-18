#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import pathlib
import tempfile
import unittest

from p1_target_resource_evidence import EvidenceError, build_evidence_bundle, main


SOURCE_COMMIT = "a" * 40
TOOL_COMMIT = "b" * 40
PLATFORM = {"macOSVersion": "26.6", "modelIdentifier": "Mac16,8"}


def _report(scenario: str) -> dict[str, object]:
    if scenario == "stability":
        duration = 600.0
        interval = 5.0
        count = 120
    else:
        duration = 60.0
        interval = 1.0
        count = 60

    report: dict[str, object] = {
        "schemaVersion": 1,
        "scenario": scenario,
        "sourceCommit": SOURCE_COMMIT,
        "measurementToolCommit": TOOL_COMMIT,
        "platform": dict(PLATFORM),
        "measurementMode": "attached",
        "startedAt": "2026-08-18T08:00:00Z",
        "endedAt": "2026-08-18T08:10:00Z",
        "requestedWarmupSeconds": 10.0,
        "requestedDurationSeconds": duration,
        "sampleIntervalSeconds": interval,
        "actualMeasurementSeconds": duration + 0.01,
        "sampleCount": count,
        "summary": {
            "sampleCount": count,
            "cpuMedianPercent": 0.0,
            "cpuMaxPercent": 1.2,
            "rssMedianKiB": 40_000,
            "rssMaxKiB": 42_000,
            "threadMedian": 4,
            "threadMax": 5,
        },
    }
    if scenario == "stability":
        report["stabilitySummary"] = {
            "rssStartKiB": 40_000,
            "rssFirstQuartileKiB": 40_100.0,
            "rssEndKiB": 40_200,
            "threadStart": 4,
            "threadFirstQuartile": 4.0,
            "threadEnd": 4,
        }
    return report


def _manual_evidence() -> dict[str, object]:
    return {
        "schemaVersion": 1,
        "sourceCommit": SOURCE_COMMIT,
        "platform": dict(PLATFORM),
        "idleWakeups": {
            "method": "activity-monitor-idle-wake-ups",
            "observationSeconds": 60,
            "wakeupsPerSecond": 0.2,
        },
        "energy": {
            "method": "instruments-power-profiler",
            "observationSeconds": 60,
            "finding": "no-anomaly-observed",
        },
        "compositor": {
            "method": "instruments-core-animation",
            "interactionCycles": 10,
            "finding": "no-anomaly-observed",
        },
    }


class P1TargetResourceEvidenceTests(unittest.TestCase):
    def test_builds_privacy_safe_bundle_from_exact_target_reports(self):
        bundle = build_evidence_bundle(
            expected_source_commit=SOURCE_COMMIT,
            idle_report=_report("idle"),
            hover_report=_report("hover"),
            stability_report=_report("stability"),
            manual_evidence=_manual_evidence(),
        )

        self.assertEqual(1, bundle["schemaVersion"])
        self.assertEqual(SOURCE_COMMIT, bundle["sourceCommit"])
        self.assertEqual(TOOL_COMMIT, bundle["measurementToolCommit"])
        self.assertEqual(PLATFORM, bundle["platform"])
        self.assertEqual({"idle", "hover", "stability"}, set(bundle["scenarios"]))
        self.assertEqual(
            {"configuration", "summary"},
            set(bundle["scenarios"]["idle"]),
        )
        self.assertEqual(
            {"configuration", "summary", "stabilitySummary"},
            set(bundle["scenarios"]["stability"]),
        )
        self.assertEqual(
            {"idleWakeups", "energy", "compositor"},
            set(bundle["manualEvidence"]),
        )
        self.assertFalse(bundle["reviewRequired"])

        serialized = json.dumps(bundle, sort_keys=True)
        for forbidden in (
            "startedAt",
            "endedAt",
            "/Users/",
            "title",
            "artist",
            "windowTitle",
            "pointerCoordinates",
            "rawTrace",
        ):
            self.assertNotIn(forbidden, serialized)

    def test_rejects_mismatched_source_or_tool_provenance(self):
        idle = _report("idle")
        idle["sourceCommit"] = "c" * 40
        with self.assertRaises(EvidenceError):
            build_evidence_bundle(
                expected_source_commit=SOURCE_COMMIT,
                idle_report=idle,
                hover_report=_report("hover"),
                stability_report=_report("stability"),
                manual_evidence=_manual_evidence(),
            )

        hover = _report("hover")
        hover["measurementToolCommit"] = "d" * 40
        with self.assertRaises(EvidenceError):
            build_evidence_bundle(
                expected_source_commit=SOURCE_COMMIT,
                idle_report=_report("idle"),
                hover_report=hover,
                stability_report=_report("stability"),
                manual_evidence=_manual_evidence(),
            )

    def test_rejects_non_target_platform_and_wrong_scenario_configuration(self):
        idle = _report("idle")
        idle["platform"] = {"macOSVersion": "26.5", "modelIdentifier": "Mac16,8"}
        with self.assertRaises(EvidenceError):
            build_evidence_bundle(
                expected_source_commit=SOURCE_COMMIT,
                idle_report=idle,
                hover_report=_report("hover"),
                stability_report=_report("stability"),
                manual_evidence=_manual_evidence(),
            )

        hover = _report("hover")
        hover["sampleIntervalSeconds"] = 2.0
        with self.assertRaises(EvidenceError):
            build_evidence_bundle(
                expected_source_commit=SOURCE_COMMIT,
                idle_report=_report("idle"),
                hover_report=hover,
                stability_report=_report("stability"),
                manual_evidence=_manual_evidence(),
            )

    def test_rejects_missing_stability_summary_or_unsafe_manual_surface(self):
        stability = _report("stability")
        del stability["stabilitySummary"]
        with self.assertRaises(EvidenceError):
            build_evidence_bundle(
                expected_source_commit=SOURCE_COMMIT,
                idle_report=_report("idle"),
                hover_report=_report("hover"),
                stability_report=stability,
                manual_evidence=_manual_evidence(),
            )

        manual = _manual_evidence()
        manual["notes"] = "arbitrary free-form content is intentionally forbidden"
        with self.assertRaises(EvidenceError):
            build_evidence_bundle(
                expected_source_commit=SOURCE_COMMIT,
                idle_report=_report("idle"),
                hover_report=_report("hover"),
                stability_report=_report("stability"),
                manual_evidence=manual,
            )

    def test_rejects_nonfinite_wakeups_and_unknown_manual_methods_or_findings(self):
        manual = _manual_evidence()
        manual["idleWakeups"]["wakeupsPerSecond"] = math.nan
        with self.assertRaises(EvidenceError):
            build_evidence_bundle(
                expected_source_commit=SOURCE_COMMIT,
                idle_report=_report("idle"),
                hover_report=_report("hover"),
                stability_report=_report("stability"),
                manual_evidence=manual,
            )

        manual = _manual_evidence()
        manual["energy"]["method"] = "sudo-powermetrics"
        with self.assertRaises(EvidenceError):
            build_evidence_bundle(
                expected_source_commit=SOURCE_COMMIT,
                idle_report=_report("idle"),
                hover_report=_report("hover"),
                stability_report=_report("stability"),
                manual_evidence=manual,
            )

        manual = _manual_evidence()
        manual["compositor"]["finding"] = "probably-fine"
        with self.assertRaises(EvidenceError):
            build_evidence_bundle(
                expected_source_commit=SOURCE_COMMIT,
                idle_report=_report("idle"),
                hover_report=_report("hover"),
                stability_report=_report("stability"),
                manual_evidence=manual,
            )

    def test_rejects_malformed_manual_method_and_finding_types_fail_closed(self):
        manual = _manual_evidence()
        manual["energy"]["method"] = ["instruments-power-profiler"]
        with self.assertRaises(EvidenceError):
            build_evidence_bundle(
                expected_source_commit=SOURCE_COMMIT,
                idle_report=_report("idle"),
                hover_report=_report("hover"),
                stability_report=_report("stability"),
                manual_evidence=manual,
            )

        manual = _manual_evidence()
        manual["energy"]["finding"] = {"value": "no-anomaly-observed"}
        with self.assertRaises(EvidenceError):
            build_evidence_bundle(
                expected_source_commit=SOURCE_COMMIT,
                idle_report=_report("idle"),
                hover_report=_report("hover"),
                stability_report=_report("stability"),
                manual_evidence=manual,
            )

        manual = _manual_evidence()
        manual["compositor"]["finding"] = ["no-anomaly-observed"]
        with self.assertRaises(EvidenceError):
            build_evidence_bundle(
                expected_source_commit=SOURCE_COMMIT,
                idle_report=_report("idle"),
                hover_report=_report("hover"),
                stability_report=_report("stability"),
                manual_evidence=manual,
            )

    def test_flags_explicit_manual_anomaly_for_review_without_inventing_threshold(self):
        manual = _manual_evidence()
        manual["energy"]["finding"] = "anomaly-observed"
        bundle = build_evidence_bundle(
            expected_source_commit=SOURCE_COMMIT,
            idle_report=_report("idle"),
            hover_report=_report("hover"),
            stability_report=_report("stability"),
            manual_evidence=manual,
        )
        self.assertTrue(bundle["reviewRequired"])

    def test_cli_writes_only_normalized_bundle(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            paths: dict[str, pathlib.Path] = {}
            for name, payload in (
                ("idle", _report("idle")),
                ("hover", _report("hover")),
                ("stability", _report("stability")),
                ("manual", _manual_evidence()),
            ):
                path = root / f"{name}.json"
                path.write_text(json.dumps(payload), encoding="utf-8")
                paths[name] = path

            output = root / "evidence.json"
            result = main(
                [
                    "--source-commit",
                    SOURCE_COMMIT,
                    "--idle",
                    str(paths["idle"]),
                    "--hover",
                    str(paths["hover"]),
                    "--stability",
                    str(paths["stability"]),
                    "--manual-evidence",
                    str(paths["manual"]),
                    "--output",
                    str(output),
                ]
            )

            self.assertEqual(0, result)
            data = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(SOURCE_COMMIT, data["sourceCommit"])
            self.assertNotIn("startedAt", json.dumps(data, sort_keys=True))


if __name__ == "__main__":
    unittest.main()
