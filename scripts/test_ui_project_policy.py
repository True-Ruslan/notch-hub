from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "NotchHubUITests.xcodeproj/project.pbxproj"
SCHEME = ROOT / "NotchHubUITests.xcodeproj/xcshareddata/xcschemes/NotchHubUITests.xcscheme"


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


if __name__ == "__main__":
    unittest.main()
