#!/usr/bin/env python3
from __future__ import annotations

import contextlib
import io
import json
import pathlib
import tempfile
import unittest

from performance_policy import compare_size_summary_to_feature_budget, main


class FeatureSizeBudgetTests(unittest.TestCase):
    @staticmethod
    def baseline():
        return {
            "schemaVersion": 1,
            "baselineId": "v0.1.0",
            "size": {
                "summary": {
                    "executableSizeBytes": 100,
                    "appSizeBytes": 200,
                    "dmgSizeBytes": 50,
                },
                "budget": {
                    "maxRegressionPercent": 15,
                    "relativeRegressionMetrics": [
                        "executableSizeBytes",
                        "appSizeBytes",
                    ],
                    "absoluteCeilingBytes": {
                        "executableSizeBytes": 120,
                        "appSizeBytes": 240,
                        "dmgSizeBytes": 60,
                    },
                },
            },
        }

    @staticmethod
    def feature_budget():
        return {
            "schemaVersion": 1,
            "featureId": "m6.4-shipping-media-composition",
            "baselineId": "v0.1.0",
            "evidence": {
                "sourceCommit": "a" * 40,
                "workflowRunId": 123,
                "artifactId": 456,
                "summary": {
                    "executableSizeBytes": 150,
                    "appSizeBytes": 300,
                    "dmgSizeBytes": 100,
                },
            },
            "allowanceBytes": {
                "executableSizeBytes": 40,
                "appSizeBytes": 80,
                "dmgSizeBytes": 50,
            },
        }

    def test_feature_budget_adds_only_reviewed_allowance_to_baseline_absolute_ceiling(self):
        summary = {
            "executableSizeBytes": 160,
            "appSizeBytes": 320,
            "dmgSizeBytes": 110,
        }
        self.assertEqual(
            [],
            compare_size_summary_to_feature_budget(
                summary,
                self.baseline(),
                self.feature_budget(),
            ),
        )

        summary["appSizeBytes"] = 321
        violations = compare_size_summary_to_feature_budget(
            summary,
            self.baseline(),
            self.feature_budget(),
        )
        self.assertEqual(1, len(violations))
        self.assertIn("appSizeBytes", violations[0])
        self.assertIn("feature-adjusted ceiling 320", violations[0])

    def test_feature_budget_requires_matching_immutable_baseline_id(self):
        budget = self.feature_budget()
        budget["baselineId"] = "other"
        with self.assertRaises(ValueError):
            compare_size_summary_to_feature_budget(
                budget["evidence"]["summary"],
                self.baseline(),
                budget,
            )

    def test_feature_budget_rejects_unknown_missing_or_negative_allowance_metrics(self):
        for mutate in ("unknown", "missing", "negative"):
            budget = self.feature_budget()
            if mutate == "unknown":
                budget["allowanceBytes"]["unknownMetric"] = 1
            elif mutate == "missing":
                del budget["allowanceBytes"]["dmgSizeBytes"]
            else:
                budget["allowanceBytes"]["dmgSizeBytes"] = -1

            with self.subTest(mutate=mutate):
                with self.assertRaises(ValueError):
                    compare_size_summary_to_feature_budget(
                        budget["evidence"]["summary"],
                        self.baseline(),
                        budget,
                    )

    def test_feature_budget_rejects_malformed_or_out_of_budget_evidence(self):
        malformed = self.feature_budget()
        malformed["evidence"]["sourceCommit"] = "not-a-sha"
        with self.assertRaises(ValueError):
            compare_size_summary_to_feature_budget(
                malformed["evidence"]["summary"],
                self.baseline(),
                malformed,
            )

        oversized = self.feature_budget()
        oversized["evidence"]["excess"] = True
        with self.assertRaises(ValueError):
            compare_size_summary_to_feature_budget(
                oversized["evidence"]["summary"],
                self.baseline(),
                oversized,
            )

        out_of_budget = self.feature_budget()
        out_of_budget["evidence"]["summary"]["dmgSizeBytes"] = 111
        with self.assertRaises(ValueError):
            compare_size_summary_to_feature_budget(
                out_of_budget["evidence"]["summary"],
                self.baseline(),
                out_of_budget,
            )

    def test_feature_budget_schema_is_fail_closed(self):
        summary = self.feature_budget()["evidence"]["summary"]

        bad_schema = self.feature_budget()
        bad_schema["schemaVersion"] = 2
        with self.assertRaises(ValueError):
            compare_size_summary_to_feature_budget(summary, self.baseline(), bad_schema)

        extra_top_level = self.feature_budget()
        extra_top_level["notes"] = "unexpected"
        with self.assertRaises(ValueError):
            compare_size_summary_to_feature_budget(summary, self.baseline(), extra_top_level)

        no_baseline_id = self.baseline()
        del no_baseline_id["baselineId"]
        with self.assertRaises(ValueError):
            compare_size_summary_to_feature_budget(summary, no_baseline_id, self.feature_budget())

    def test_feature_budget_cli_is_fail_closed(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            summary_path = root / "summary.json"
            baseline_path = root / "baseline.json"
            feature_path = root / "feature.json"

            baseline_path.write_text(json.dumps(self.baseline()), encoding="utf-8")
            feature_path.write_text(json.dumps(self.feature_budget()), encoding="utf-8")
            summary_path.write_text(
                json.dumps(
                    {
                        "executableSizeBytes": 150,
                        "appSizeBytes": 300,
                        "dmgSizeBytes": 100,
                    }
                ),
                encoding="utf-8",
            )

            stdout = io.StringIO()
            with contextlib.redirect_stdout(stdout):
                self.assertEqual(
                    0,
                    main(
                        [
                            "check-size-feature-budget",
                            "--summary",
                            str(summary_path),
                            "--baseline",
                            str(baseline_path),
                            "--feature-budget",
                            str(feature_path),
                        ]
                    ),
                )
            self.assertIn("Feature size budget checks passed.", stdout.getvalue())

            summary_path.write_text(
                json.dumps(
                    {
                        "executableSizeBytes": 161,
                        "appSizeBytes": 300,
                        "dmgSizeBytes": 100,
                    }
                ),
                encoding="utf-8",
            )
            stderr = io.StringIO()
            with contextlib.redirect_stderr(stderr):
                self.assertEqual(
                    1,
                    main(
                        [
                            "check-size-feature-budget",
                            "--summary",
                            str(summary_path),
                            "--baseline",
                            str(baseline_path),
                            "--feature-budget",
                            str(feature_path),
                        ]
                    ),
                )
            self.assertIn("feature-adjusted ceiling", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
