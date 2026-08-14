from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
BUILD_APP = (ROOT / "scripts/build-app.sh").read_text(encoding="utf-8")
CI = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
PERSONAL_RELEASE = (ROOT / ".github/workflows/personal-release.yml").read_text(encoding="utf-8")
TRUSTED_RELEASE = (ROOT / ".github/workflows/trusted-release.yml").read_text(encoding="utf-8")


class UIAutomationPolicyTests(unittest.TestCase):
    def test_build_script_has_explicit_test_compilation_condition(self):
        self.assertIn("NOTCHHUB_UI_TESTING", BUILD_APP)
        self.assertIn("-DNOTCHHUB_UI_TESTING", BUILD_APP)

    def test_shipping_workflows_never_enable_fixture_build(self):
        self.assertNotIn("NOTCHHUB_UI_TESTING=1", CI)
        self.assertNotIn("NOTCHHUB_UI_TESTING=1", PERSONAL_RELEASE)
        self.assertNotIn("NOTCHHUB_UI_TESTING=1", TRUSTED_RELEASE)


if __name__ == "__main__":
    unittest.main()
