import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from performance_policy import find_runtime_policy_violations


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


if __name__ == "__main__":
    unittest.main()
