#!/usr/bin/env python3
from __future__ import annotations

import contextlib
import io
import json
import pathlib
import tempfile
import unittest

from performance_policy import compare_size_summary_to_feature_budget, main


REPOSITORY_ROOT = pathlib.Path(__file__).resolve().parent.parent


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

    def test_feature_budget_accepts_exact_artifact_size_envelope_only(self):
        summary = {
            "schemaVersion": 1,
            "sourceCommit": "b" * 40,
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

        for mutate in ("extra", "bad-schema", "bad-sha"):
            invalid = dict(summary)
            if mutate == "extra":
                invalid["unexpected"] = True
            elif mutate == "bad-schema":
                invalid["schemaVersion"] = 2
            else:
                invalid["sourceCommit"] = "not-a-sha"
            with self.subTest(mutate=mutate):
                with self.assertRaises(ValueError):
                    compare_size_summary_to_feature_budget(
                        invalid,
                        self.baseline(),
                        self.feature_budget(),
                    )

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

    def test_repository_m6_4_budget_remains_provenanced_and_self_validating(self):
        baseline = json.loads(
            (REPOSITORY_ROOT / "performance" / "baseline-v0.1.0.json").read_text(
                encoding="utf-8"
            )
        )
        feature_budget = json.loads(
            (
                REPOSITORY_ROOT
                / "performance"
                / "m6-4-shipping-media-size-budget.json"
            ).read_text(encoding="utf-8")
        )

        self.assertEqual("m6.4-shipping-media-composition", feature_budget["featureId"])
        self.assertEqual("v0.1.0", feature_budget["baselineId"])
        self.assertEqual(31402487785, feature_budget["evidence"]["workflowRunId"])
        self.assertEqual(9068350685, feature_budget["evidence"]["artifactId"])
        self.assertEqual(
            [],
            compare_size_summary_to_feature_budget(
                feature_budget["evidence"]["summary"],
                baseline,
                feature_budget,
            ),
        )

    def test_repository_m6_5_budget_is_provenanced_tight_and_self_validating(self):
        baseline = json.loads(
            (REPOSITORY_ROOT / "performance" / "baseline-v0.1.0.json").read_text(
                encoding="utf-8"
            )
        )
        feature_budget = json.loads(
            (
                REPOSITORY_ROOT
                / "performance"
                / "m6-5-media-first-ui-size-budget.json"
            ).read_text(encoding="utf-8")
        )

        self.assertEqual("m6.5-media-first-ui", feature_budget["featureId"])
        self.assertEqual("v0.1.0", feature_budget["baselineId"])
        self.assertEqual(
            {
                "appSizeBytes": 430080,
                "dmgSizeBytes": 376832,
                "executableSizeBytes": 135168,
            },
            feature_budget["allowanceBytes"],
        )
        self.assertEqual(
            "3db9d05619b38198c00b57b3cdd043af0618f714",
            feature_budget["evidence"]["sourceCommit"],
        )
        self.assertEqual(31537964825, feature_budget["evidence"]["workflowRunId"])
        self.assertEqual(9119647587, feature_budget["evidence"]["artifactId"])
        self.assertEqual(
            {
                "appSizeBytes": 699614,
                "dmgSizeBytes": 461748,
                "executableSizeBytes": 397408,
            },
            feature_budget["evidence"]["summary"],
        )
        self.assertEqual(
            [],
            compare_size_summary_to_feature_budget(
                feature_budget["evidence"]["summary"],
                baseline,
                feature_budget,
            ),
        )

    def test_repository_m6_6_one_shot_budget_is_provenanced_tight_and_self_validating(self):
        baseline = json.loads(
            (REPOSITORY_ROOT / "performance" / "baseline-v0.1.0.json").read_text(
                encoding="utf-8"
            )
        )
        feature_budget = json.loads(
            (
                REPOSITORY_ROOT
                / "performance"
                / "m6-6-one-shot-lifecycle-size-budget.json"
            ).read_text(encoding="utf-8")
        )

        self.assertEqual("m6.6-one-shot-lifecycle", feature_budget["featureId"])
        self.assertEqual("v0.1.0", feature_budget["baselineId"])
        self.assertEqual(
            {
                "appSizeBytes": 450560,
                "dmgSizeBytes": 376832,
                "executableSizeBytes": 151552,
            },
            feature_budget["allowanceBytes"],
        )
        self.assertEqual(
            "55d08e58ce755a4e5d32a1128bd1a1262fe1ff42",
            feature_budget["evidence"]["sourceCommit"],
        )
        self.assertEqual(31575348332, feature_budget["evidence"]["workflowRunId"])
        self.assertEqual(9133032338, feature_budget["evidence"]["artifactId"])
        self.assertEqual(
            {
                "appSizeBytes": 717406,
                "dmgSizeBytes": 465191,
                "executableSizeBytes": 415200,
            },
            feature_budget["evidence"]["summary"],
        )
        self.assertEqual(
            [],
            compare_size_summary_to_feature_budget(
                feature_budget["evidence"]["summary"],
                baseline,
                feature_budget,
            ),
        )

    def test_repository_m6_6_gesture_engine_budget_is_provenanced_tight_and_self_validating(self):
        baseline = json.loads(
            (REPOSITORY_ROOT / "performance" / "baseline-v0.1.0.json").read_text(
                encoding="utf-8"
            )
        )
        feature_budget = json.loads(
            (
                REPOSITORY_ROOT
                / "performance"
                / "m6-6-gesture-engine-size-budget.json"
            ).read_text(encoding="utf-8")
        )

        self.assertEqual("m6.6-gesture-engine", feature_budget["featureId"])
        self.assertEqual("v0.1.0", feature_budget["baselineId"])
        self.assertEqual(
            {
                "appSizeBytes": 458752,
                "dmgSizeBytes": 389120,
                "executableSizeBytes": 159744,
            },
            feature_budget["allowanceBytes"],
        )
        self.assertEqual(
            "ddad4a3efa579caf818693dece9845059fbcd810",
            feature_budget["evidence"]["sourceCommit"],
        )
        self.assertEqual(31582412364, feature_budget["evidence"]["workflowRunId"])
        self.assertEqual(9135807459, feature_budget["evidence"]["artifactId"])
        self.assertEqual(
            {
                "appSizeBytes": 724814,
                "dmgSizeBytes": 474960,
                "executableSizeBytes": 422608,
            },
            feature_budget["evidence"]["summary"],
        )
        self.assertEqual(
            [],
            compare_size_summary_to_feature_budget(
                feature_budget["evidence"]["summary"],
                baseline,
                feature_budget,
            ),
        )

    def test_repository_m6_6_compact_command_budget_is_provenanced_tight_and_self_validating(self):
        baseline = json.loads(
            (REPOSITORY_ROOT / "performance" / "baseline-v0.1.0.json").read_text(
                encoding="utf-8"
            )
        )
        feature_budget = json.loads(
            (
                REPOSITORY_ROOT
                / "performance"
                / "m6-6-compact-command-size-budget.json"
            ).read_text(encoding="utf-8")
        )

        self.assertEqual("m6.6-compact-command", feature_budget["featureId"])
        self.assertEqual("v0.1.0", feature_budget["baselineId"])
        self.assertEqual(
            {
                "appSizeBytes": 479232,
                "dmgSizeBytes": 389120,
                "executableSizeBytes": 180224,
            },
            feature_budget["allowanceBytes"],
        )
        self.assertEqual(
            "55f2ee429932b68ed7a02c3750cd28a28c9bd3d9",
            feature_budget["evidence"]["sourceCommit"],
        )
        self.assertEqual(31588206985, feature_budget["evidence"]["workflowRunId"])
        self.assertEqual(9138085911, feature_budget["evidence"]["artifactId"])
        self.assertEqual(
            {
                "appSizeBytes": 745582,
                "dmgSizeBytes": 475100,
                "executableSizeBytes": 443376,
            },
            feature_budget["evidence"]["summary"],
        )
        self.assertEqual(
            [],
            compare_size_summary_to_feature_budget(
                feature_budget["evidence"]["summary"],
                baseline,
                feature_budget,
            ),
        )

    def test_ci_uses_m6_6_compact_command_feature_budget_over_immutable_baseline(self):
        workflow = (
            REPOSITORY_ROOT / ".github" / "workflows" / "ci.yml"
        ).read_text(encoding="utf-8")

        self.assertIn("check-size-feature-budget", workflow)
        self.assertIn("--baseline performance/baseline-v0.1.0.json", workflow)
        self.assertIn(
            "--feature-budget performance/m6-6-compact-command-size-budget.json",
            workflow,
        )
        self.assertNotIn(
            "--feature-budget performance/m6-6-gesture-engine-size-budget.json",
            workflow,
        )
        self.assertNotIn(
            "--feature-budget performance/m6-6-one-shot-lifecycle-size-budget.json",
            workflow,
        )
        self.assertNotIn(
            "--feature-budget performance/m6-5-media-first-ui-size-budget.json",
            workflow,
        )
        self.assertNotIn(
            "check-size-budget \\\n            --summary build/perf-size.json",
            workflow,
        )


if __name__ == "__main__":
    unittest.main()
