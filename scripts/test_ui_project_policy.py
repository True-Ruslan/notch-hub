from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "NotchHubUITests.xcodeproj/project.pbxproj"
SCHEME = ROOT / "NotchHubUITests.xcodeproj/xcshareddata/xcschemes/NotchHubUITests.xcscheme"
UI_ROOT = ROOT / "Tests/UITests"
APPLICATION = UI_ROOT / "Support/NotchHubUIApplication.swift"
ASSERTIONS = UI_ROOT / "Support/NotchHubUIAssertions.swift"
DIAGNOSTICS = UI_ROOT / "Support/NotchHubUIDiagnostics.swift"
CANONICAL_WORKFLOW = ROOT / ".github/workflows/ci.yml"
LEGACY_UI_WORKFLOW = ROOT / ".github/workflows/ui-regression.yml"
EXACT_SOURCE_EXPRESSION = "${{ github.event.pull_request.head.sha || github.sha }}"


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

    def test_canonical_ci_owns_mandatory_ui_regression_and_acceptance_audit(self):
        workflow = CANONICAL_WORKFLOW.read_text(encoding="utf-8")

        self.assertFalse(
            LEGACY_UI_WORKFLOW.exists(),
            "UI regression must not live in a second workflow with its own trigger surface",
        )
        for required in (
            "macos-ui-regression:",
            "name: macOS UI regression",
            "runs-on: macos-26",
            "Validate UI test project policy",
            "python3 scripts/test_ui_project_policy.py -v",
            "Validate UI fixture isolation policy",
            "python3 scripts/test_ui_automation_policy.py -v",
            "Audit acceptance coverage",
            "python3 scripts/test_acceptance_coverage.py --mode audit",
            "xcodebuild -list -project NotchHubUITests.xcodeproj",
            "bash scripts/build-ui-test-app.sh",
            "--verify-shipping-app build/NotchHub.app",
            "NOTCHHUB_UI_APP_PATH:",
            "NOTCHHUB_UI_SOURCE_COMMIT:",
            "xcodebuild test",
            "build/NotchHubUITests-smoke.xcresult",
            "if: always()",
        ):
            with self.subTest(required=required):
                self.assertIn(required, workflow)

        exact_source = EXACT_SOURCE_EXPRESSION
        self.assertGreaterEqual(
            workflow.count(exact_source),
            3,
            "UI build, shipping verification and XCUI provenance must use exact PR-head SHA",
        )

    def test_ui_diagnostics_are_exact_sha_aware_and_fail_closed(self):
        application = APPLICATION.read_text(encoding="utf-8")
        diagnostics = DIAGNOSTICS.read_text(encoding="utf-8")
        workflow = CANONICAL_WORKFLOW.read_text(encoding="utf-8")

        self.assertIn("NOTCHHUB_UI_SOURCE_COMMIT", application)
        self.assertIn("NHSourceCommit", application)
        self.assertIn("sourceCommit", diagnostics)
        self.assertIn("XCTAttachment(string: sourceCommit)", diagnostics)
        self.assertIn(
            f"NOTCHHUB_UI_SOURCE_COMMIT: {EXACT_SOURCE_EXPRESSION}",
            workflow,
        )

    def test_ui_layer_rejects_fixed_sleeps_and_automatic_retries(self):
        sources = "\n".join(
            path.read_text(encoding="utf-8")
            for path in sorted(UI_ROOT.rglob("*.swift"))
        )
        workflow = CANONICAL_WORKFLOW.read_text(encoding="utf-8")
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
