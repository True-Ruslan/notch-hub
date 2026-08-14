import argparse
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
BUILD_APP = (ROOT / "scripts/build-app.sh").read_text(encoding="utf-8")
CI = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
PERSONAL_RELEASE = (ROOT / ".github/workflows/personal-release.yml").read_text(encoding="utf-8")
TRUSTED_RELEASE = (ROOT / ".github/workflows/trusted-release.yml").read_text(encoding="utf-8")

FORBIDDEN_MARKERS = (
    b"NOTCHHUB_UI_FIXTURE",
    b"media-standard",
    b"media-unsupported",
    b"ui-test.hapticCount",
)


def assert_shipping_binary_has_no_ui_test_markers(app_path: Path) -> None:
    binary = app_path / "Contents/MacOS/NotchHub"
    if not binary.is_file():
        raise AssertionError(f"shipping executable not found: {binary}")

    data = binary.read_bytes()
    leaked = [marker.decode("utf-8") for marker in FORBIDDEN_MARKERS if marker in data]
    if leaked:
        raise AssertionError(f"shipping binary contains UI-test markers: {leaked}")


class UIAutomationPolicyTests(unittest.TestCase):
    def test_build_script_has_explicit_test_compilation_condition(self):
        self.assertIn("NOTCHHUB_UI_TESTING", BUILD_APP)
        self.assertIn("-DNOTCHHUB_UI_TESTING", BUILD_APP)

    def test_shipping_workflows_never_enable_fixture_build(self):
        self.assertNotIn("NOTCHHUB_UI_TESTING=1", CI)
        self.assertNotIn("NOTCHHUB_UI_TESTING=1", PERSONAL_RELEASE)
        self.assertNotIn("NOTCHHUB_UI_TESTING=1", TRUSTED_RELEASE)

    def test_shipping_marker_verifier_rejects_fixture_marker(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            app_path = Path(temporary_directory) / "NotchHub.app"
            binary = app_path / "Contents/MacOS/NotchHub"
            binary.parent.mkdir(parents=True)
            binary.write_bytes(b"shipping-prefix\x00media-standard\x00shipping-suffix")

            with self.assertRaisesRegex(AssertionError, "media-standard"):
                assert_shipping_binary_has_no_ui_test_markers(app_path)

    def test_shipping_marker_verifier_accepts_clean_binary(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            app_path = Path(temporary_directory) / "NotchHub.app"
            binary = app_path / "Contents/MacOS/NotchHub"
            binary.parent.mkdir(parents=True)
            binary.write_bytes(b"clean-shipping-binary")

            assert_shipping_binary_has_no_ui_test_markers(app_path)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--verify-shipping-app", type=Path)
    args, remaining = parser.parse_known_args()

    if args.verify_shipping_app is not None:
        if remaining:
            parser.error(f"unexpected arguments with --verify-shipping-app: {remaining}")
        assert_shipping_binary_has_no_ui_test_markers(args.verify_shipping_app)
        return

    unittest.main(argv=[__file__, *remaining])


if __name__ == "__main__":
    main()
