import subprocess
import unittest
from unittest.mock import patch

from production_media_transport_acceptance import (
    EXPECTED_ADAPTER_COMMIT,
    EXPECTED_REPORT_KEYS,
    EXPECTED_SOURCE_COMMIT,
    _sample_process,
    combine_resource_summaries,
    find_owned_adapter_pid,
    validate_candidate_report,
)


SOURCE_COMMIT = "3932426bcf063162ee7de1378ed301c9ce664746"
CURRENT_SOURCE_COMMIT = "c63f39c40b90d647e48271b9dc1d5ffd6e612c0b"


class ProductionMediaTransportAcceptanceTests(unittest.TestCase):
    def test_default_source_commit_tracks_current_exact_candidate(self):
        self.assertEqual(CURRENT_SOURCE_COMMIT, EXPECTED_SOURCE_COMMIT)

    def test_resource_sampler_uses_numeric_cpu_rss_and_darwin_thread_rows(self):
        metric_result = subprocess.CompletedProcess(
            args=[], returncode=0, stdout="  0.0  5680\n", stderr=""
        )
        thread_result = subprocess.CompletedProcess(
            args=[],
            returncode=0,
            stdout="USER PID TT %CPU STAT PRI STIME UTIME COMMAND\nuser 123 ?? 0.0 S 31 0:00.01 0:00.00 candidate\nuser 123 ?? 0.0 S 31 0:00.01 0:00.00 candidate\n",
            stderr="",
        )

        with patch(
            "production_media_transport_acceptance.subprocess.run",
            side_effect=[metric_result, thread_result],
        ) as run:
            sample = _sample_process(123)

        self.assertEqual(0.0, sample.cpu_percent)
        self.assertEqual(5680, sample.rss_kib)
        self.assertEqual(2, sample.thread_count)
        self.assertEqual(
            ["/bin/ps", "-p", "123", "-o", "%cpu=", "-o", "rss="],
            run.call_args_list[0].args[0],
        )
        self.assertEqual(["/bin/ps", "-M", "123"], run.call_args_list[1].args[0])

    def test_report_validation_accepts_exact_privacy_safe_schema(self):
        report = {
            "schemaVersion": 1,
            "sourceCommit": SOURCE_COMMIT,
            "adapterCommit": EXPECTED_ADAPTER_COMMIT,
            "eventCount": 3,
            "observedSession": True,
            "observedArtwork": True,
            "observedPlayingState": True,
            "observedSessionDisappearance": False,
            "observedArtworkClearOnSourceSwitch": False,
            "sourceSwitchCount": 0,
            "sourceBundleIdentifier": "ru.yandex.desktop.music",
            "capabilities": {
                "previous": "supported",
                "next": "supported",
                "seek": "supported",
            },
            "cleanTeardown": True,
        }

        normalized = validate_candidate_report(report, SOURCE_COMMIT)

        self.assertEqual(EXPECTED_REPORT_KEYS, set(normalized))
        self.assertEqual(report, normalized)

    def test_report_validation_rejects_metadata_extra_keys_and_wrong_provenance(self):
        base = {
            "schemaVersion": 1,
            "sourceCommit": SOURCE_COMMIT,
            "adapterCommit": EXPECTED_ADAPTER_COMMIT,
            "eventCount": 1,
            "observedSession": False,
            "observedArtwork": False,
            "observedPlayingState": False,
            "observedSessionDisappearance": False,
            "observedArtworkClearOnSourceSwitch": False,
            "sourceSwitchCount": 0,
            "sourceBundleIdentifier": None,
            "capabilities": {"previous": "unknown", "next": "unknown", "seek": "unknown"},
            "cleanTeardown": True,
        }

        mutations = (
            base | {"title": "private"},
            base | {"sourceCommit": "0" * 40},
            base | {"adapterCommit": "0" * 40},
            base | {"capabilities": {"previous": "supported", "next": "supported"}},
            base | {"eventCount": -1},
            base | {"sourceSwitchCount": -1},
        )
        for mutation in mutations:
            with self.subTest(mutation=mutation):
                with self.assertRaises(ValueError):
                    validate_candidate_report(mutation, SOURCE_COMMIT)

    def test_owned_adapter_pid_requires_exact_parent_and_adapter_command(self):
        process_rows = """
100 1 /Applications/Other.app/Contents/MacOS/Other
201 100 /usr/bin/perl /tmp/other.pl
301 200 /usr/bin/perl /tmp/app/Contents/Resources/mediaremote-adapter.pl /tmp/app/Contents/Resources/MediaRemoteAdapter.framework stream --no-diff --micros
302 200 /usr/bin/python3 helper.py
401 999 /usr/bin/perl /tmp/app/Contents/Resources/mediaremote-adapter.pl /tmp/app/Contents/Resources/MediaRemoteAdapter.framework stream --no-diff --micros
"""

        self.assertEqual(301, find_owned_adapter_pid(process_rows, parent_pid=200))

    def test_owned_adapter_pid_fails_closed_on_missing_or_ambiguous_child(self):
        missing = "301 200 /usr/bin/python3 helper.py\n"
        ambiguous = """
301 200 /usr/bin/perl /a/mediaremote-adapter.pl /a/MediaRemoteAdapter.framework stream --no-diff --micros
302 200 /usr/bin/perl /b/mediaremote-adapter.pl /b/MediaRemoteAdapter.framework stream --no-diff --micros
"""

        with self.assertRaises(ValueError):
            find_owned_adapter_pid(missing, parent_pid=200)
        with self.assertRaises(ValueError):
            find_owned_adapter_pid(ambiguous, parent_pid=200)

    def test_combined_resource_summary_is_conservative_and_stable(self):
        parent = {
            "cpuMedianPercent": 0.1,
            "cpuMaxPercent": 0.4,
            "rssMedianKiB": 6000.0,
            "rssMaxKiB": 7000.0,
            "threadMedian": 2.0,
            "threadMax": 3,
        }
        adapter = {
            "cpuMedianPercent": 0.0,
            "cpuMaxPercent": 0.2,
            "rssMedianKiB": 20000.0,
            "rssMaxKiB": 24000.0,
            "threadMedian": 2.0,
            "threadMax": 6,
        }

        combined = combine_resource_summaries(parent, adapter)

        self.assertEqual(0.1, combined["cpuMedianPercentUpperBound"])
        self.assertEqual(0.6, combined["cpuMaxPercentUpperBound"])
        self.assertEqual(26000.0, combined["rssMedianKiBUpperBound"])
        self.assertEqual(31000.0, combined["rssMaxKiBUpperBound"])
        self.assertEqual(4.0, combined["threadMedianUpperBound"])
        self.assertEqual(9, combined["threadMaxUpperBound"])


if __name__ == "__main__":
    unittest.main()
