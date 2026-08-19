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
            compare_size_summary_to_feature_budget(
                summary,
                self.baseline(),
                extra_top_level,
            )

        no_baseline_id = self.baseline()
        del no_baseline_id["baselineId"]
        with self.assertRaises(ValueError):
            compare_size_summary_to_feature_budget(
                summary,
                no_baseline_id,
                self.feature_budget(),
            )

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

    def repository_baseline(self):
        return json.loads(
            (REPOSITORY_ROOT / "performance" / "baseline-v0.1.0.json").read_text(
                encoding="utf-8"
            )
        )

    def repository_budget(self, filename):
        return json.loads(
            (REPOSITORY_ROOT / "performance" / filename).read_text(encoding="utf-8")
        )

    def assert_repository_budget(
        self,
        *,
        filename,
        feature_id,
        source_commit,
        workflow_run_id,
        artifact_id,
        summary=None,
        allowance=None,
    ):
        baseline = self.repository_baseline()
        feature_budget = self.repository_budget(filename)
        self.assertEqual(feature_id, feature_budget["featureId"])
        self.assertEqual("v0.1.0", feature_budget["baselineId"])
        self.assertEqual(source_commit, feature_budget["evidence"]["sourceCommit"])
        self.assertEqual(workflow_run_id, feature_budget["evidence"]["workflowRunId"])
        self.assertEqual(artifact_id, feature_budget["evidence"]["artifactId"])
        if summary is not None:
            self.assertEqual(summary, feature_budget["evidence"]["summary"])
        if allowance is not None:
            self.assertEqual(allowance, feature_budget["allowanceBytes"])
        self.assertEqual(
            [],
            compare_size_summary_to_feature_budget(
                feature_budget["evidence"]["summary"],
                baseline,
                feature_budget,
            ),
        )

    def test_repository_historical_budgets_remain_exact_and_self_validating(self):
        historical = (
            (
                "m6-4-shipping-media-size-budget.json",
                "m6.4-shipping-media-composition",
                "21318c94cfcda45f147d3967ddcd7194034e9812",
                31402487785,
                9068350685,
                None,
                None,
            ),
            (
                "m6-5-media-first-ui-size-budget.json",
                "m6.5-media-first-ui",
                "3db9d05619b38198c00b57b3cdd043af0618f714",
                31537964825,
                9119647587,
                {"appSizeBytes": 699614, "dmgSizeBytes": 461748, "executableSizeBytes": 397408},
                {"appSizeBytes": 430080, "dmgSizeBytes": 376832, "executableSizeBytes": 135168},
            ),
            (
                "m6-6-one-shot-lifecycle-size-budget.json",
                "m6.6-one-shot-lifecycle",
                "55d08e58ce755a4e5d32a1128bd1a1262fe1ff42",
                31575348332,
                9133032338,
                {"appSizeBytes": 717406, "dmgSizeBytes": 465191, "executableSizeBytes": 415200},
                {"appSizeBytes": 450560, "dmgSizeBytes": 376832, "executableSizeBytes": 151552},
            ),
            (
                "m6-6-gesture-engine-size-budget.json",
                "m6.6-gesture-engine",
                "ddad4a3efa579caf818693dece9845059fbcd810",
                31582412364,
                9135807459,
                {"appSizeBytes": 724814, "dmgSizeBytes": 474960, "executableSizeBytes": 422608},
                {"appSizeBytes": 458752, "dmgSizeBytes": 389120, "executableSizeBytes": 159744},
            ),
            (
                "m6-6-compact-command-size-budget.json",
                "m6.6-compact-command",
                "55f2ee429932b68ed7a02c3750cd28a28c9bd3d9",
                31588206985,
                9138085911,
                {"appSizeBytes": 745582, "dmgSizeBytes": 475100, "executableSizeBytes": 443376},
                {"appSizeBytes": 479232, "dmgSizeBytes": 389120, "executableSizeBytes": 180224},
            ),
            (
                "m6-6-app-gesture-session-size-budget.json",
                "m6.6-app-gesture-session",
                "3ebbf68a373e32189196b18a11610ec4d2babca9",
                31598200510,
                9142119577,
                {"appSizeBytes": 763662, "dmgSizeBytes": 490395, "executableSizeBytes": 461456},
                {"appSizeBytes": 499712, "dmgSizeBytes": 405504, "executableSizeBytes": 200704},
            ),
            (
                "m6-6-source-app-icon-size-budget.json",
                "m6.6-source-app-icon",
                "066b8264f53c1dc1afe01fe8a120bb8ab9509102",
                31601331136,
                9143349824,
                {"appSizeBytes": 782414, "dmgSizeBytes": 506515, "executableSizeBytes": 480208},
                {"appSizeBytes": 518144, "dmgSizeBytes": 421888, "executableSizeBytes": 219136},
            ),
            (
                "m6-6-media-seek-size-budget.json",
                "m6.6-media-seek",
                "01bb282f7cbc5eab57b11b1695ccf9768fc6cb2e",
                31606258918,
                9145423733,
                {"appSizeBytes": 802190, "dmgSizeBytes": 520488, "executableSizeBytes": 499984},
                {"appSizeBytes": 536576, "dmgSizeBytes": 434176, "executableSizeBytes": 237568},
            ),
            (
                "m6-6-physical-acceptance-repair-size-budget.json",
                "m6.6-physical-acceptance-repair",
                "d8fb784eb9eb47c7af34dbd689b6fcfa5aadef12",
                31617785894,
                9150099248,
                {"appSizeBytes": 825406, "dmgSizeBytes": 527113, "executableSizeBytes": 523200},
                {"appSizeBytes": 556032, "dmgSizeBytes": 437248, "executableSizeBytes": 257024},
            ),
        )
        for filename, feature_id, source_commit, run_id, artifact_id, summary, allowance in historical:
            with self.subTest(filename=filename):
                self.assert_repository_budget(
                    filename=filename,
                    feature_id=feature_id,
                    source_commit=source_commit,
                    workflow_run_id=run_id,
                    artifact_id=artifact_id,
                    summary=summary,
                    allowance=allowance,
                )

    def test_repository_hover_peek_budget_is_provenanced_tight_and_self_validating(self):
        self.assert_repository_budget(
            filename="m6-6-hover-peek-size-budget.json",
            feature_id="m6.6-hover-peek",
            source_commit="7daffde9b7c2a734e2ddfa234b1ee744b0d96d9e",
            workflow_run_id=31636748859,
            artifact_id=9157392052,
            summary={
                "appSizeBytes": 864574,
                "dmgSizeBytes": 555272,
                "executableSizeBytes": 562368,
            },
            allowance={
                "appSizeBytes": 594944,
                "dmgSizeBytes": 465920,
                "executableSizeBytes": 296960,
            },
        )

    def test_repository_m6_6_regression_foundation_integration_budget_is_provenanced_tight_and_self_validating(self):
        self.assert_repository_budget(
            filename="m6-6-regression-foundation-integration-size-budget.json",
            feature_id="m6.6-regression-foundation-integration",
            source_commit="452f78b0e42c5302702393e9c45c563849661ca4",
            workflow_run_id=31869841148,
            artifact_id=9243156724,
            summary={
                "appSizeBytes": 882687,
                "dmgSizeBytes": 552272,
                "executableSizeBytes": 580480,
            },
            allowance={
                "appSizeBytes": 614400,
                "dmgSizeBytes": 462848,
                "executableSizeBytes": 315392,
            },
        )

    def test_repository_m6_6_physical_acceptance_20260815_repair_budget_is_provenanced_tight_and_self_validating(self):
        self.assert_repository_budget(
            filename="m6-6-physical-acceptance-20260815-repair-size-budget.json",
            feature_id="m6.6-physical-acceptance-20260815-repair",
            source_commit="63b0f2f96f879123f3883db7311c90a20d3a4328",
            workflow_run_id=31889213155,
            artifact_id=9248133083,
            summary={
                "appSizeBytes": 883039,
                "dmgSizeBytes": 555132,
                "executableSizeBytes": 580832,
            },
            allowance={
                "appSizeBytes": 614400,
                "dmgSizeBytes": 466944,
                "executableSizeBytes": 315392,
            },
        )

    def test_repository_m6_6_physical_acceptance_20260816_first_click_budget_is_provenanced_tight_and_self_validating(self):
        self.assert_repository_budget(
            filename="m6-6-physical-acceptance-20260816-first-click-size-budget.json",
            feature_id="m6.6-physical-acceptance-20260816-first-click",
            source_commit="327f5b4180d71a1001fb93285fa25b98abcc088c",
            workflow_run_id=31914056522,
            artifact_id=9254479722,
            summary={
                "appSizeBytes": 883087,
                "dmgSizeBytes": 557704,
                "executableSizeBytes": 580880,
            },
            allowance={
                "appSizeBytes": 614400,
                "dmgSizeBytes": 471040,
                "executableSizeBytes": 315392,
            },
        )

    def test_repository_m6_6_hardware_notch_screen_selection_budget_is_provenanced_tight_and_self_validating(self):
        self.assert_repository_budget(
            filename="m6-6-hardware-notch-screen-selection-size-budget.json",
            feature_id="m6.6-hardware-notch-screen-selection",
            source_commit="46f069e57997eab060c79c3d9e279da944d6e263",
            workflow_run_id=32226544212,
            artifact_id=9355827331,
            summary={
                "appSizeBytes": 882911,
                "dmgSizeBytes": 561421,
                "executableSizeBytes": 580704,
            },
            allowance={
                "appSizeBytes": 614400,
                "dmgSizeBytes": 475136,
                "executableSizeBytes": 315392,
            },
        )

    def test_ci_uses_first_click_physical_acceptance_budget_over_immutable_baseline(self):
        workflow = (
            REPOSITORY_ROOT / ".github" / "workflows" / "ci.yml"
        ).read_text(encoding="utf-8")

        self.assertIn("check-size-feature-budget", workflow)
        self.assertIn("--baseline performance/baseline-v0.1.0.json", workflow)
        self.assertIn(
            "--feature-budget performance/m6-6-hardware-notch-screen-selection-size-budget.json",
            workflow,
        )
        for historical_budget in (
            "m6-6-physical-acceptance-20260816-first-click-size-budget.json",
            "m6-6-physical-acceptance-20260815-repair-size-budget.json",
            "m6-6-regression-foundation-integration-size-budget.json",
            "regression-ui-automation-foundation-size-budget.json",
            "m6-6-hover-peek-size-budget.json",
            "m6-6-physical-acceptance-repair-size-budget.json",
            "m6-6-media-seek-size-budget.json",
            "m6-6-source-app-icon-size-budget.json",
            "m6-6-app-gesture-session-size-budget.json",
            "m6-6-compact-command-size-budget.json",
            "m6-6-gesture-engine-size-budget.json",
            "m6-6-one-shot-lifecycle-size-budget.json",
            "m6-5-media-first-ui-size-budget.json",
        ):
            self.assertNotIn(f"--feature-budget performance/{historical_budget}", workflow)
        self.assertNotIn(
            "check-size-budget \\\n            --summary build/perf-size.json",
            workflow,
        )


if __name__ == "__main__":
    unittest.main()
