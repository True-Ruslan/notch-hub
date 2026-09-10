#!/usr/bin/env python3
from __future__ import annotations

import json
import pathlib
import unittest

from performance_policy import compare_size_summary_to_feature_budget


REPOSITORY_ROOT = pathlib.Path(__file__).resolve().parent.parent
BUDGET_PATH = REPOSITORY_ROOT / "performance" / "m3-1-snippets-foundation-size-budget.json"
BASELINE_PATH = REPOSITORY_ROOT / "performance" / "baseline-v0.1.0.json"
WORKFLOW_PATH = REPOSITORY_ROOT / ".github" / "workflows" / "ci.yml"


class M31SnippetsSizeBudgetTests(unittest.TestCase):
    def test_budget_is_exact_provenanced_and_bounded(self):
        budget = json.loads(BUDGET_PATH.read_text(encoding="utf-8"))
        baseline = json.loads(BASELINE_PATH.read_text(encoding="utf-8"))

        self.assertEqual(1, budget["schemaVersion"])
        self.assertEqual("m3-1-snippets-foundation", budget["featureId"])
        self.assertEqual("v0.1.0", budget["baselineId"])
        self.assertEqual(
            "be46025ccfc4b4b9d6f33e78d294c6d186a9202c",
            budget["evidence"]["sourceCommit"],
        )
        self.assertEqual(34372146755, budget["evidence"]["workflowRunId"])
        self.assertEqual(10112663094, budget["evidence"]["artifactId"])
        self.assertEqual(
            {
                "appSizeBytes": 1318340,
                "dmgSizeBytes": 807169,
                "executableSizeBytes": 1016032,
            },
            budget["evidence"]["summary"],
        )
        self.assertEqual(
            {
                "appSizeBytes": 1095000,
                "dmgSizeBytes": 765000,
                "executableSizeBytes": 795000,
            },
            budget["allowanceBytes"],
        )
        self.assertEqual(
            [],
            compare_size_summary_to_feature_budget(
                budget["evidence"]["summary"],
                baseline,
                budget,
            ),
        )

        ceilings = baseline["size"]["budget"]["absoluteCeilingBytes"]
        for metric, actual in budget["evidence"]["summary"].items():
            headroom = ceilings[metric] + budget["allowanceBytes"][metric] - actual
            self.assertGreaterEqual(headroom, 40000, metric)
            self.assertLessEqual(headroom, 50000, metric)

    def test_ci_uses_m31_as_active_budget_and_validates_m21_as_historical_evidence(self):
        workflow = WORKFLOW_PATH.read_text(encoding="utf-8")
        m31 = "--feature-budget performance/m3-1-snippets-foundation-size-budget.json"
        m21 = "--feature-budget performance/m2-1-shelf-foundation-size-budget.json"

        self.assertEqual(1, workflow.count(m31))
        self.assertEqual(1, workflow.count(m21))

        active_start = workflow.index("- name: Enforce release size budget")
        active_end = workflow.index("- name: Performance harness compatibility smoke", active_start)
        active_step = workflow[active_start:active_end]
        self.assertIn(m31, active_step)
        self.assertNotIn(m21, active_step)


if __name__ == "__main__":
    unittest.main()
