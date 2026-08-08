#!/usr/bin/env python3
from __future__ import annotations

import contextlib
import io
import math
import pathlib
import tempfile
import unittest

from performance_policy import (
    ProcessSample,
    compare_size_summary_to_baseline,
    compare_summary_to_budget,
    count_ps_thread_rows,
    find_runtime_policy_violations,
    main,
    parse_ps_sample,
    summarize_samples,
    summarize_stability_samples,
    validate_config,
)


class RuntimePerformancePolicyTests(unittest.TestCase):
    def test_forbidden_runtime_primitives_are_reported_with_path_line_and_rule(self):
        cases = {
            "while true { }": "unbounded busy loop",
            "Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in }": "scheduled Timer",
            "Timer.publish(every: 1, on: .main, in: .common)": "Timer publisher",
            "DispatchSource.makeTimerSource()": "dispatch timer source",
            "try await Task.sleep(for: .seconds(1))": "Task.sleep",
            "Thread.sleep(forTimeInterval: 1)": "Thread.sleep",
            "usleep(1000)": "usleep",
            "sleep(1)": "sleep",
            "CVDisplayLinkCreateWithActiveCGDisplays(&link)": "CVDisplayLink",
            "CADisplayLink(target: self, selector: #selector(tick))": "CADisplayLink",
        }
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            source = root / "Runtime.swift"
            source.write_text("\n".join(cases), encoding="utf-8")
            violations = find_runtime_policy_violations(root)

        self.assertEqual(len(cases), len(violations))
        for rule in cases.values():
            self.assertTrue(any(rule in violation for violation in violations), rule)

    def test_ordinary_event_driven_code_is_allowed(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            (root / "Runtime.swift").write_text(
                """
                for item in items { consume(item) }
                DispatchQueue.main.async { refresh() }
                let token = NotificationCenter.default.addObserver(
                    forName: .init("event"), object: nil, queue: .main
                ) { _ in refresh() }
                """,
                encoding="utf-8",
            )
            self.assertEqual([], find_runtime_policy_violations(root))

    def test_non_swift_files_are_not_scanned(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            (root / "notes.md").write_text("while true Timer.publish", encoding="utf-8")
            self.assertEqual([], find_runtime_policy_violations(root))

    def test_violations_are_sorted_deterministically(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            (root / "B.swift").write_text("sleep(1)\n", encoding="utf-8")
            (root / "A.swift").write_text("while true { }\n", encoding="utf-8")
            violations = find_runtime_policy_violations(root)
        self.assertEqual(sorted(violations), violations)

    def test_audit_cli_returns_success_for_clean_sources_and_failure_for_violation(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            source = root / "Runtime.swift"
            source.write_text("func handleEvent() {}\n", encoding="utf-8")
            stdout = io.StringIO()
            with contextlib.redirect_stdout(stdout):
                self.assertEqual(0, main(["audit", str(root)]))
            self.assertIn("Performance policy checks passed.", stdout.getvalue())

            source.write_text("while true { }\n", encoding="utf-8")
            stderr = io.StringIO()
            with contextlib.redirect_stderr(stderr):
                self.assertEqual(1, main(["audit", str(root)]))
            self.assertIn("unbounded busy loop", stderr.getvalue())


class ProcessMetricTests(unittest.TestCase):
    def test_parse_ps_sample_accepts_exact_three_field_format(self):
        sample = parse_ps_sample(" 0.3  18432  7 ")
        self.assertEqual(ProcessSample(0.3, 18432, 7), sample)

    def test_parse_ps_sample_rejects_malformed_or_unsafe_values(self):
        cases = (
            "0.3 18432",
            "0,3 18432 7",
            "nan 18432 7",
            "-0.1 18432 7",
            "0.1 -1 7",
            "0.1 18432 0",
        )
        for value in cases:
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    parse_ps_sample(value)

    def test_summarize_samples_reports_exact_medians_and_maxima(self):
        samples = [
            ProcessSample(0.1, 100, 2),
            ProcessSample(0.3, 300, 6),
            ProcessSample(0.2, 200, 4),
            ProcessSample(0.5, 500, 8),
            ProcessSample(0.4, 400, 7),
        ]
        summary = summarize_samples(samples)
        self.assertEqual(5, summary["sampleCount"])
        self.assertEqual(0.3, summary["cpuMedianPercent"])
        self.assertEqual(0.5, summary["cpuMaxPercent"])
        self.assertEqual(300, summary["rssMedianKiB"])
        self.assertEqual(500, summary["rssMaxKiB"])
        self.assertEqual(6, summary["threadMedian"])
        self.assertEqual(8, summary["threadMax"])

    def test_summarize_samples_rejects_empty_input(self):
        with self.assertRaises(ValueError):
            summarize_samples([])

    def test_stability_summary_preserves_start_end_and_first_quartile(self):
        samples = [
            ProcessSample(0.0, 400, 4),
            ProcessSample(0.0, 200, 3),
            ProcessSample(0.0, 220, 3),
            ProcessSample(0.0, 240, 3),
            ProcessSample(0.0, 260, 4),
        ]
        summary = summarize_stability_samples(samples)
        self.assertEqual(400, summary["rssStartKiB"])
        self.assertEqual(260, summary["rssEndKiB"])
        self.assertEqual(220.0, summary["rssFirstQuartileKiB"])
        self.assertEqual(4, summary["threadStart"])
        self.assertEqual(4, summary["threadEnd"])
        self.assertEqual(3.0, summary["threadFirstQuartile"])

    def test_count_ps_thread_rows_counts_darwin_ps_m_body_rows(self):
        output = "PID TT STAT TIME COMMAND\n42 ?? S 0:00.01 App\n42 ?? S 0:00.00 App\n"
        self.assertEqual(2, count_ps_thread_rows(output))

    def test_count_ps_thread_rows_rejects_missing_thread_body(self):
        with self.assertRaises(ValueError):
            count_ps_thread_rows("PID TT STAT TIME COMMAND\n")


class BaselineConfigTests(unittest.TestCase):
    def test_validate_config_accepts_launch_and_attach_modes(self):
        validate_config("idle", 10, 60, 1, pathlib.Path("app"), None)
        validate_config("hover", 10, 60, 1, None, 1234)

    def test_validate_config_rejects_invalid_measurement_configuration(self):
        cases = (
            ("unknown", 10, 60, 1, pathlib.Path("app"), None),
            ("idle", -1, 60, 1, pathlib.Path("app"), None),
            ("idle", 10, 0, 1, pathlib.Path("app"), None),
            ("idle", 10, 60, 0, pathlib.Path("app"), None),
            ("idle", 10, 5, 6, pathlib.Path("app"), None),
            ("idle", 10, 60, 1, None, None),
            ("idle", 10, 60, 1, pathlib.Path("app"), 1234),
            ("idle", 10, 60, 1, None, 0),
            ("idle", math.nan, 60, 1, pathlib.Path("app"), None),
        )
        for args in cases:
            with self.subTest(args=args):
                with self.assertRaises(ValueError):
                    validate_config(*args)


class BudgetComparisonTests(unittest.TestCase):
    def test_compare_summary_to_budget_returns_no_violations_when_under_budget(self):
        summary = {
            "cpuMaxPercent": 0.8,
            "rssMaxKiB": 14_000,
            "threadMax": 8,
        }
        budget = {
            "cpuMaxPercent": 1.0,
            "rssMaxKiB": 16_000,
            "threadMax": 10,
        }
        self.assertEqual([], compare_summary_to_budget(summary, budget))

    def test_compare_summary_to_budget_reports_only_exceeded_metrics(self):
        summary = {
            "cpuMaxPercent": 1.2,
            "rssMaxKiB": 14_000,
            "threadMax": 11,
        }
        budget = {
            "cpuMaxPercent": 1.0,
            "rssMaxKiB": 16_000,
            "threadMax": 10,
        }
        violations = compare_summary_to_budget(summary, budget)
        self.assertEqual(2, len(violations))
        self.assertIn("cpuMaxPercent", violations[0])
        self.assertIn("threadMax", violations[1])

    def test_compare_summary_to_budget_rejects_missing_or_non_finite_values(self):
        with self.assertRaises(ValueError):
            compare_summary_to_budget({"cpuMaxPercent": 1.0}, {"rssMaxKiB": 10})
        with self.assertRaises(ValueError):
            compare_summary_to_budget({"cpuMaxPercent": math.nan}, {"cpuMaxPercent": 1.0})


class ReleaseSizeBudgetTests(unittest.TestCase):
    @staticmethod
    def baseline(
        *,
        regression_percent=15.0,
        executable_ceiling=200,
        app_ceiling=300,
        dmg_ceiling=100,
        relative_metrics=None,
    ):
        if relative_metrics is None:
            relative_metrics = ["executableSizeBytes", "appSizeBytes", "dmgSizeBytes"]
        return {
            "schemaVersion": 1,
            "size": {
                "summary": {
                    "executableSizeBytes": 100,
                    "appSizeBytes": 200,
                    "dmgSizeBytes": 50,
                },
                "budget": {
                    "maxRegressionPercent": regression_percent,
                    "relativeRegressionMetrics": relative_metrics,
                    "absoluteCeilingBytes": {
                        "executableSizeBytes": executable_ceiling,
                        "appSizeBytes": app_ceiling,
                        "dmgSizeBytes": dmg_ceiling,
                    },
                },
            },
        }

    def test_size_budget_accepts_values_below_relative_and_absolute_limits(self):
        summary = {
            "executableSizeBytes": 114,
            "appSizeBytes": 220,
            "dmgSizeBytes": 55,
        }
        self.assertEqual([], compare_size_summary_to_baseline(summary, self.baseline()))

    def test_size_budget_reports_absolute_ceiling_violation(self):
        summary = {
            "executableSizeBytes": 121,
            "appSizeBytes": 200,
            "dmgSizeBytes": 50,
        }
        baseline = self.baseline(regression_percent=100.0, executable_ceiling=120)
        violations = compare_size_summary_to_baseline(summary, baseline)
        self.assertEqual(1, len(violations))
        self.assertIn("executableSizeBytes", violations[0])
        self.assertIn("absolute ceiling", violations[0])

    def test_size_budget_reports_relative_regression_violation(self):
        summary = {
            "executableSizeBytes": 116,
            "appSizeBytes": 200,
            "dmgSizeBytes": 50,
        }
        baseline = self.baseline(regression_percent=15.0, executable_ceiling=200)
        violations = compare_size_summary_to_baseline(summary, baseline)
        self.assertEqual(1, len(violations))
        self.assertIn("executableSizeBytes", violations[0])
        self.assertIn("15% regression allowance", violations[0])

    def test_dmg_uses_absolute_ceiling_when_relative_bytes_are_not_reproducible(self):
        summary = {
            "executableSizeBytes": 114,
            "appSizeBytes": 220,
            "dmgSizeBytes": 59,
        }
        baseline = self.baseline(
            regression_percent=15.0,
            dmg_ceiling=60,
            relative_metrics=["executableSizeBytes", "appSizeBytes"],
        )
        self.assertEqual([], compare_size_summary_to_baseline(summary, baseline))

        summary["dmgSizeBytes"] = 61
        violations = compare_size_summary_to_baseline(summary, baseline)
        self.assertEqual(1, len(violations))
        self.assertIn("dmgSizeBytes", violations[0])
        self.assertIn("absolute ceiling", violations[0])

    def test_size_budget_rejects_unknown_or_malformed_relative_metric_policy(self):
        summary = {
            "executableSizeBytes": 100,
            "appSizeBytes": 200,
            "dmgSizeBytes": 50,
        }

        unknown = self.baseline(relative_metrics=["executableSizeBytes", "unknownMetric"])
        with self.assertRaises(ValueError):
            compare_size_summary_to_baseline(summary, unknown)

        malformed = self.baseline()
        malformed["size"]["budget"]["relativeRegressionMetrics"] = "appSizeBytes"
        with self.assertRaises(ValueError):
            compare_size_summary_to_baseline(summary, malformed)

        empty = self.baseline(relative_metrics=[])
        with self.assertRaises(ValueError):
            compare_size_summary_to_baseline(summary, empty)

    def test_size_budget_fails_closed_on_schema_or_required_metric_mismatch(self):
        summary = {
            "executableSizeBytes": 100,
            "appSizeBytes": 200,
            "dmgSizeBytes": 50,
        }
        bad_schema = self.baseline()
        bad_schema["schemaVersion"] = 2
        with self.assertRaises(ValueError):
            compare_size_summary_to_baseline(summary, bad_schema)

        missing_metric = self.baseline()
        del missing_metric["size"]["summary"]["dmgSizeBytes"]
        with self.assertRaises(ValueError):
            compare_size_summary_to_baseline(summary, missing_metric)

    def test_check_size_budget_cli_is_fail_closed(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            summary_path = root / "summary.json"
            baseline_path = root / "baseline.json"
            summary_path.write_text(
                '{"executableSizeBytes": 114, "appSizeBytes": 220, "dmgSizeBytes": 55}\n',
                encoding="utf-8",
            )
            baseline_path.write_text(
                __import__("json").dumps(self.baseline()),
                encoding="utf-8",
            )

            stdout = io.StringIO()
            with contextlib.redirect_stdout(stdout):
                self.assertEqual(
                    0,
                    main(
                        [
                            "check-size-budget",
                            "--summary",
                            str(summary_path),
                            "--baseline",
                            str(baseline_path),
                        ]
                    ),
                )
            self.assertIn("Release size budget checks passed.", stdout.getvalue())

            summary_path.write_text(
                '{"executableSizeBytes": 116, "appSizeBytes": 220, "dmgSizeBytes": 55}\n',
                encoding="utf-8",
            )
            stderr = io.StringIO()
            with contextlib.redirect_stderr(stderr):
                self.assertEqual(
                    1,
                    main(
                        [
                            "check-size-budget",
                            "--summary",
                            str(summary_path),
                            "--baseline",
                            str(baseline_path),
                        ]
                    ),
                )
            self.assertIn("regression allowance", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
