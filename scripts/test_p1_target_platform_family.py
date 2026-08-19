#!/usr/bin/env python3
from __future__ import annotations

import unittest

from p1_target_resource_evidence import EvidenceError, build_evidence_bundle


SOURCE_COMMIT = "a" * 40
TOOL_COMMIT = "b" * 40
MODEL = "Mac16,8"


def _platform(version: str) -> dict[str, str]:
    return {"macOSVersion": version, "modelIdentifier": MODEL}


def _report(scenario: str, version: str) -> dict[str, object]:
    duration = 600.0 if scenario == "stability" else 60.0
    interval = 5.0 if scenario == "stability" else 1.0
    count = 120 if scenario == "stability" else 60
    report: dict[str, object] = {
        "schemaVersion": 1,
        "scenario": scenario,
        "sourceCommit": SOURCE_COMMIT,
        "measurementToolCommit": TOOL_COMMIT,
        "platform": _platform(version),
        "measurementMode": "attached",
        "startedAt": "2026-08-19T18:00:00Z",
        "endedAt": "2026-08-19T18:10:00Z",
        "requestedWarmupSeconds": 10.0,
        "requestedDurationSeconds": duration,
        "sampleIntervalSeconds": interval,
        "actualMeasurementSeconds": duration + 0.01,
        "sampleCount": count,
        "summary": {
            "sampleCount": count,
            "cpuMedianPercent": 0.0,
            "cpuMaxPercent": 1.0,
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


def _manual(version: str) -> dict[str, object]:
    return {
        "schemaVersion": 1,
        "sourceCommit": SOURCE_COMMIT,
        "platform": _platform(version),
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


def _bundle(version: str, *, hover_version: str | None = None) -> dict[str, object]:
    return build_evidence_bundle(
        expected_source_commit=SOURCE_COMMIT,
        idle_report=_report("idle", version),
        hover_report=_report("hover", hover_version or version),
        stability_report=_report("stability", version),
        manual_evidence=_manual(version),
    )


class P1TargetPlatformFamilyTests(unittest.TestCase):
    def test_accepts_and_preserves_26_6_patch_release(self):
        bundle = _bundle("26.6.1")
        self.assertEqual(_platform("26.6.1"), bundle["platform"])

    def test_keeps_exact_26_6_compatible(self):
        bundle = _bundle("26.6")
        self.assertEqual(_platform("26.6"), bundle["platform"])

    def test_rejects_cross_file_patch_version_mismatch(self):
        with self.assertRaises(EvidenceError):
            _bundle("26.6.1", hover_version="26.6.2")

    def test_rejects_adjacent_minor_and_malformed_versions(self):
        for version in ("26.5.9", "26.7", "26.6.1.1", "26.6.beta", "26.06.1"):
            with self.subTest(version=version):
                with self.assertRaises(EvidenceError):
                    _bundle(version)


if __name__ == "__main__":
    unittest.main()
