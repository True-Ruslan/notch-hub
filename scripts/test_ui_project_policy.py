from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "NotchHubUITests.xcodeproj/project.pbxproj"
SCHEME = ROOT / "NotchHubUITests.xcodeproj/xcshareddata/xcschemes/NotchHubUITests.xcscheme"
ASSERTIONS = ROOT / "Tests/UITests/Support/NotchHubUIAssertions.swift"
DIAGNOSTICS = ROOT / "Tests/UITests/Support/NotchHubUIDiagnostics.swift"


class UIProjectPolicyTests(unittest.TestCase):
    def test_project_and_shared_scheme_exist(self):
        self.assertTrue(PROJECT.is_file())
        self.assertTrue(SCHEME.is_file())

    def test_project_contains_only_test_host_and_ui_test_targets(self):
        text = PROJECT.read_text(encoding="utf-8")
        self.assertIn("NotchHubUITestHost", text)
        self.assertIn("NotchHubUITests", text)
        self.assertNotIn("Sources/NotchHubApp", text)
        self.assertNotIn("Sources/NotchHubCore", text)
        self.assertNotIn("Sources/NotchHubMediaCore", text)

    def test_ui_support_contract_is_checked_in_targeted_and_wait_driven(self):
        project = PROJECT.read_text(encoding="utf-8")
        support_files = (ASSERTIONS, DIAGNOSTICS)
        all_exist = True

        for path in support_files:
            with self.subTest(path=path.name):
                exists = path.is_file()
                self.assertTrue(exists)
                self.assertIn(path.name, project)
                all_exist = all_exist and exists

        if not all_exist:
            return

        assertions = ASSERTIONS.read_text(encoding="utf-8")
        diagnostics = DIAGNOSTICS.read_text(encoding="utf-8")

        self.assertIn("NSPredicate", assertions)
        self.assertIn("XCTNSPredicateExpectation", assertions)
        self.assertIn("XCTWaiter", assertions)
        self.assertIn("XCTAttachment(screenshot:", diagnostics)
        self.assertIn(".lifetime = .keepAlways", diagnostics)

        combined = assertions + diagnostics
        for forbidden in ("sleep(", "Task.sleep", "usleep("):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, combined)


if __name__ == "__main__":
    unittest.main()
