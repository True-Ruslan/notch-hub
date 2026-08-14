from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "NotchHubUITests.xcodeproj/project.pbxproj"
SCHEME = ROOT / "NotchHubUITests.xcodeproj/xcshareddata/xcschemes/NotchHubUITests.xcscheme"
UI_ROOT = ROOT / "Tests/UITests"
APPLICATION = UI_ROOT / "Support/NotchHubUIApplication.swift"
ASSERTIONS = UI_ROOT / "Support/NotchHubUIAssertions.swift"
DIAGNOSTICS = UI_ROOT / "Support/NotchHubUIDiagnostics.swift"
WORKFLOW = ROOT / ".github/workflows/ui-regression.yml"


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

    def test_ui_diagnostics_are_exact_sha_aware_and_fail_closed(self):
        application = APPLICATION.read_text(encoding="utf-8")
        diagnostics = DIAGNOSTICS.read_text(encoding="utf-8")
        workflow = WORKFLOW.read_text(encoding="utf-8")

        self.assertIn("NOTCHHUB_UI_SOURCE_COMMIT", application)
        self.assertIn("NHSourceCommit", application)
        self.assertIn("sourceCommit", diagnostics)
        self.assertIn("XCTAttachment(string: sourceCommit)", diagnostics)
        self.assertIn("NOTCHHUB_UI_SOURCE_COMMIT: ${{ github.sha }}", workflow)

    def test_ui_layer_rejects_fixed_sleeps_and_automatic_retries(self):
        sources = "\n".join(
            path.read_text(encoding="utf-8")
            for path in sorted(UI_ROOT.rglob("*.swift"))
        )
        workflow = WORKFLOW.read_text(encoding="utf-8")
        combined = sources + "\n" + workflow

        for forbidden in (
            "sleep(",
            "Task.sleep",
            "usleep(",
            "retry(",
            "withRetry",
            "automaticRetry",
        ):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, combined)


if __name__ == "__main__":
    unittest.main()
