import unittest

from performance_policy import ProcessSample
from shipping_media_acceptance import build_compact_resource_report


class ShippingMediaCompactResourceTests(unittest.TestCase):
    SOURCE_COMMIT = "a" * 40

    def test_compact_report_is_parent_only_and_privacy_safe(self):
        samples = [
            ProcessSample(cpu_percent=0.0, rss_kib=30_000, thread_count=4),
            ProcessSample(cpu_percent=0.2, rss_kib=31_000, thread_count=5),
        ]

        report = build_compact_resource_report(
            mode="steady",
            source_commit=self.SOURCE_COMMIT,
            platform={"macOSVersion": "26.6", "modelIdentifier": "Mac16,8"},
            started_at="start",
            ended_at="end",
            warmup_seconds=10,
            duration_seconds=60,
            interval_seconds=1,
            parent_samples=samples,
        )

        self.assertEqual(1, report["schemaVersion"])
        self.assertEqual("compact-parent-only", report["resourceScope"])
        self.assertTrue(report["adapterAbsent"])
        self.assertEqual(31_000, report["parent"]["rssMaxKiB"])
        self.assertNotIn("adapter", report)
        self.assertNotIn("combinedUpperBounds", report)
        for key in ("title", "artist", "album", "artworkData", "parentPid"):
            self.assertNotIn(key, report)

    def test_compact_stability_preserves_parent_drift(self):
        samples = [
            ProcessSample(cpu_percent=0.0, rss_kib=30_000, thread_count=4),
            ProcessSample(cpu_percent=0.0, rss_kib=31_000, thread_count=4),
            ProcessSample(cpu_percent=0.0, rss_kib=29_000, thread_count=4),
            ProcessSample(cpu_percent=0.0, rss_kib=28_000, thread_count=4),
        ]

        report = build_compact_resource_report(
            mode="stability",
            source_commit=self.SOURCE_COMMIT,
            platform={"macOSVersion": "26.6", "modelIdentifier": "Mac16,8"},
            started_at="start",
            ended_at="end",
            warmup_seconds=10,
            duration_seconds=600,
            interval_seconds=5,
            parent_samples=samples,
        )

        self.assertEqual(30_000, report["parentStability"]["rssStartKiB"])
        self.assertEqual(28_000, report["parentStability"]["rssEndKiB"])

    def test_compact_report_rejects_empty_samples(self):
        with self.assertRaises(ValueError):
            build_compact_resource_report(
                mode="steady",
                source_commit=self.SOURCE_COMMIT,
                platform={"macOSVersion": "26.6", "modelIdentifier": "Mac16,8"},
                started_at="start",
                ended_at="end",
                warmup_seconds=10,
                duration_seconds=60,
                interval_seconds=1,
                parent_samples=[],
            )


if __name__ == "__main__":
    unittest.main()
