#!/usr/bin/env python3
from __future__ import annotations

import unittest

from performance_policy import ProcessSample
from shipping_media_acceptance import (
    EXPECTED_ADAPTER_COMMIT,
    EXPECTED_BUNDLE_IDENTIFIER,
    EXPECTED_PATCH_SHA256,
    build_resource_report,
    build_teardown_report,
    validate_shipping_info,
)


class ShippingMediaAcceptanceTests(unittest.TestCase):
    SOURCE_COMMIT = "a" * 40

    def test_shipping_info_requires_exact_provenance(self):
        info = {
            "CFBundleIdentifier": EXPECTED_BUNDLE_IDENTIFIER,
            "NHSourceCommit": self.SOURCE_COMMIT,
            "NHAdapterCommit": EXPECTED_ADAPTER_COMMIT,
            "NHAdapterPatchSHA256": EXPECTED_PATCH_SHA256,
        }
        validate_shipping_info(info, self.SOURCE_COMMIT)

        for key, bad_value in (
            ("CFBundleIdentifier", "wrong.bundle"),
            ("NHSourceCommit", "b" * 40),
            ("NHAdapterCommit", "b" * 40),
            ("NHAdapterPatchSHA256", "0" * 64),
        ):
            invalid = dict(info)
            invalid[key] = bad_value
            with self.subTest(key=key):
                with self.assertRaises(ValueError):
                    validate_shipping_info(invalid, self.SOURCE_COMMIT)

    def test_resource_report_is_privacy_safe_and_combines_parent_and_adapter(self):
        parent = [
            ProcessSample(cpu_percent=0.0, rss_kib=20_000, thread_count=4),
            ProcessSample(cpu_percent=0.2, rss_kib=21_000, thread_count=5),
        ]
        adapter = [
            ProcessSample(cpu_percent=0.1, rss_kib=10_000, thread_count=2),
            ProcessSample(cpu_percent=0.0, rss_kib=11_000, thread_count=2),
        ]

        report = build_resource_report(
            mode="steady",
            source_commit=self.SOURCE_COMMIT,
            platform={"macOSVersion": "26.6", "modelIdentifier": "Mac16,8"},
            started_at="2026-08-10T12:00:00Z",
            ended_at="2026-08-10T12:01:00Z",
            warmup_seconds=10,
            duration_seconds=60,
            interval_seconds=1,
            parent_samples=parent,
            adapter_samples=adapter,
        )

        self.assertEqual(1, report["schemaVersion"])
        self.assertEqual("steady", report["mode"])
        self.assertEqual(2, report["sampleCount"])
        self.assertEqual(32_000, report["combinedUpperBounds"]["rssMaxKiB"])
        self.assertEqual(7, report["combinedUpperBounds"]["threadMax"])
        forbidden = {
            "title",
            "artist",
            "album",
            "artworkData",
            "rawPayload",
            "listeningHistory",
            "parentPid",
            "adapterPid",
        }
        self.assertFalse(forbidden.intersection(report))

    def test_stability_report_preserves_separate_drift_evidence(self):
        parent = [
            ProcessSample(cpu_percent=0.0, rss_kib=20_000, thread_count=4),
            ProcessSample(cpu_percent=0.0, rss_kib=21_000, thread_count=4),
            ProcessSample(cpu_percent=0.0, rss_kib=22_000, thread_count=5),
            ProcessSample(cpu_percent=0.0, rss_kib=21_500, thread_count=4),
        ]
        adapter = [
            ProcessSample(cpu_percent=0.0, rss_kib=10_000, thread_count=2),
            ProcessSample(cpu_percent=0.0, rss_kib=10_500, thread_count=2),
            ProcessSample(cpu_percent=0.0, rss_kib=10_200, thread_count=2),
            ProcessSample(cpu_percent=0.0, rss_kib=10_100, thread_count=2),
        ]

        report = build_resource_report(
            mode="stability",
            source_commit=self.SOURCE_COMMIT,
            platform={"macOSVersion": "26.6", "modelIdentifier": "Mac16,8"},
            started_at="2026-08-10T12:00:00Z",
            ended_at="2026-08-10T12:10:00Z",
            warmup_seconds=10,
            duration_seconds=600,
            interval_seconds=5,
            parent_samples=parent,
            adapter_samples=adapter,
        )

        self.assertIn("parentStability", report)
        self.assertIn("adapterStability", report)
        self.assertEqual(21_500, report["parentStability"]["rssEndKiB"])
        self.assertEqual(10_100, report["adapterStability"]["rssEndKiB"])

    def test_resource_report_rejects_mismatched_or_empty_samples(self):
        sample = [ProcessSample(cpu_percent=0.0, rss_kib=1, thread_count=1)]
        for parent, adapter in (([], []), (sample, []), (sample + sample, sample)):
            with self.subTest(parent=len(parent), adapter=len(adapter)):
                with self.assertRaises(ValueError):
                    build_resource_report(
                        mode="steady",
                        source_commit=self.SOURCE_COMMIT,
                        platform={"macOSVersion": "26.6", "modelIdentifier": "Mac16,8"},
                        started_at="start",
                        ended_at="end",
                        warmup_seconds=10,
                        duration_seconds=60,
                        interval_seconds=1,
                        parent_samples=parent,
                        adapter_samples=adapter,
                    )

    def test_teardown_report_fails_closed_on_remaining_adapter(self):
        clean = build_teardown_report(
            source_commit=self.SOURCE_COMMIT,
            platform={"macOSVersion": "26.6", "modelIdentifier": "Mac16,8"},
            parent_exited=True,
            adapter_exited=True,
        )
        self.assertTrue(clean["parentExited"])
        self.assertTrue(clean["adapterExited"])
        self.assertFalse(clean["orphanProcessDetected"])
        self.assertNotIn("parentPid", clean)
        self.assertNotIn("adapterPid", clean)

        orphan = build_teardown_report(
            source_commit=self.SOURCE_COMMIT,
            platform={"macOSVersion": "26.6", "modelIdentifier": "Mac16,8"},
            parent_exited=True,
            adapter_exited=False,
        )
        self.assertTrue(orphan["orphanProcessDetected"])


if __name__ == "__main__":
    unittest.main()
