import contextlib
import io
import math
import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from performance_policy import (
    ProcessSample,
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
            "while true {": "unbounded busy loop",
            "Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in }": "scheduled Timer",
            "Timer.publish(every: 1, on: .main, in: .common)": "Timer publisher",
            "DispatchSource.makeTimerSource()": "dispatch timer source",
            "try await Task.sleep(nanoseconds: 1)": "Task.sleep",
            "Thread.sleep(forTimeInterval: 1)": "Thread.sleep",
            "usleep(1000)": "usleep",
            "sleep(1)": "sleep",
            "CVDisplayLinkCreateWithActiveCGDisplays(nil)": "CVDisplayLink",
            "CADisplayLink(target: target, selector: selector)": "CADisplayLink",
        }

        for source, expected_rule in cases.items():
            with self.subTest(source=source):
                with tempfile.TemporaryDirectory() as temp_dir:
                    root = pathlib.Path(temp_dir)
                    swift_file = root / "Feature.swift"
                    swift_file.write_text(f"func run() {{\n    {source}\n}}\n", encoding="utf-8")

                    violations = find_runtime_policy_violations(root)

                    self.assertEqual(1, len(violations))
                    self.assertIn("Feature.swift:2:", violations[0])
                    self.assertIn(expected_rule, violations[0])

    def test_ordinary_event_driven_code_is_allowed(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            (root / "Feature.swift").write_text(
                """func handle(values: [Int]) {
    for value in values {
        DispatchQueue.main.async {
            print(value)
        }
    }
}
""",
                encoding="utf-8",
            )

            self.assertEqual([], find_runtime_policy_violations(root))

    def test_non_swift_files_are_not_scanned(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            (root / "README.md").write_text("Timer.scheduledTimer\nwhile true\n", encoding="utf-8")

            self.assertEqual([], find_runtime_policy_violations(root))

    def test_violations_are_sorted_deterministically(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            (root / "B.swift").write_text("sleep(1)\n", encoding="utf-8")
            (root / "A.swift").write_text("while true { }\n", encoding="utf-8")

            violations = find_runtime_policy_violations(root)

            self.assertEqual(2, len(violations))
            self.assertTrue(violations[0].startswith("A.swift:1:"))
            self.assertTrue(violations[1].startswith("B.swift:1:"))

    def test_audit_cli_returns_success_for_clean_sources_and_failure_for_violation(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            swift_file = root / "Feature.swift"
            swift_file.write_text("func eventDriven() {}\n", encoding="utf-8")

            stdout = io.StringIO()
            with contextlib.redirect_stdout(stdout):
                self.assertEqual(0, main(["audit", str(root)]))
            self.assertIn("Performance policy checks passed.", stdout.getvalue())

            swift_file.write_text("while true { }\n", encoding="utf-8")
            stderr = io.StringIO()
            with contextlib.redirect_stderr(stderr):
                self.assertEqual(1, main(["audit", str(root)]))
            self.assertIn("unbounded busy loop", stderr.getvalue())


class ProcessMetricTests(unittest.TestCase):
    def test_parse_ps_sample_accepts_exact_three_field_format(self):
        sample = parse_ps_sample(" 0.3  18432  7 ")
        self.assertEqual(0.3, sample.cpu_percent)
        self.assertEqual(18432, sample.rss_kib)
        self.assertEqual(7, sample.thread_count)

    def test_parse_ps_sample_rejects_malformed_or_unsafe_values(self):
        invalid = (
            "0.3 18432",
            "0.3 18432 7 extra",
            "nan 18432 7",
            "inf 18432 7",
            "-0.1 18432 7",
            "0.3 -1 7",
            "0.3 18432 0",
            "0.3 18432 -1",
            "0,3 18432 7",
            "cpu rss threads",
        )
        for line in invalid:
            with self.subTest(line=line):
                with self.assertRaises(ValueError):
                    parse_ps_sample(line)

    def test_count_ps_thread_rows_counts_darwin_ps_m_body_rows(self):
        output = """USER   PID   TT   %CPU STAT PRI     STIME     UTIME COMMAND
runner 1234   ??    0.0 S    31T   0:00.10   0:00.20 NotchHub
       1234         0.0 S    31T   0:00.00   0:00.00
       1234         0.0 S    31T   0:00.00   0:00.00
"""
        self.assertEqual(3, count_ps_thread_rows(output))

    def test_count_ps_thread_rows_rejects_missing_thread_body(self):
        with self.assertRaises(ValueError):
            count_ps_thread_rows("")
        with self.assertRaises(ValueError):
            count_ps_thread_rows("USER PID COMMAND\n")

    def test_summarize_samples_reports_exact_medians_and_maxima(self):
        samples = [
            ProcessSample(0.1, 10_000, 5),
            ProcessSample(0.3, 12_000, 7),
            ProcessSample(0.2, 11_000, 6),
            ProcessSample(0.8, 14_000, 8),
            ProcessSample(0.4, 13_000, 7),
        ]

        self.assertEqual(
            {
                "sampleCount": 5,
                "cpuMedianPercent": 0.3,
                "cpuMaxPercent": 0.8,
                "rssMedianKiB": 12_000,
                "rssMaxKiB": 14_000,
                "threadMedian": 7,
                "threadMax": 8,
            },
            summarize_samples(samples),
        )

    def test_summarize_samples_rejects_empty_input(self):
        with self.assertRaises(ValueError):
            summarize_samples([])

    def test_stability_summary_preserves_start_end_and_first_quartile(self):
        samples = [
            ProcessSample(0.1, 10_000, 5),
            ProcessSample(0.1, 11_000, 5),
            ProcessSample(0.1, 12_000, 6),
            ProcessSample(0.1, 13_000, 7),
        ]

        self.assertEqual(
            {
                "rssStartKiB": 10_000,
                "rssEndKiB": 13_000,
                "rssFirstQuartileKiB": 10_750.0,
                "threadStart": 5,
                "threadEnd": 7,
                "threadFirstQuartile": 5.0,
            },
            summarize_stability_samples(samples),
        )


class BaselineConfigTests(unittest.TestCase):
    def test_validate_config_accepts_launch_and_attach_modes(self):
        validate_config("idle", 10, 60, 1, pathlib.Path("build/NotchHub.app"), None)
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


if __name__ == "__main__":
    unittest.main()
