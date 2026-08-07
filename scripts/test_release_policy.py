import json
import unittest
from pathlib import Path

from release_policy import (
    build_metadata,
    parse_semver,
    release_tag,
    validate_personal_release_notes,
)


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent


class ReleasePolicyTests(unittest.TestCase):
    def test_release_tag_accepts_strict_three_component_semver(self):
        self.assertEqual((0, 1, 0), parse_semver("0.1.0"))
        self.assertEqual("v0.1.0", release_tag("0.1.0"))

    def test_release_tag_rejects_non_release_versions(self):
        for value in ("0.1", "v0.1.0", "0.1.0-beta", "01.1.0", " 0.1.0 ", "0.1.0\n"):
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    release_tag(value)

    def test_personal_release_notes_require_explicit_trust_warning(self):
        text = (
            "# NotchHub v0.1.0 — Personal build\n\n"
            "## Personal build — not notarized\n\n"
            "This release is for personal use. It is ad-hoc signed and not Apple-notarized. "
            "macOS may require System Settings → Privacy & Security → Open Anyway. "
            "Do not disable Gatekeeper.\n"
        )
        validate_personal_release_notes(text, "0.1.0")

    def test_personal_release_notes_reject_missing_first_warning_section(self):
        text = (
            "# NotchHub v0.1.0 — Personal build\n\n"
            "## Features\n\n"
            "## Personal build — not notarized\n\n"
            "ad-hoc signed; Open Anyway\n"
        )
        with self.assertRaises(ValueError):
            validate_personal_release_notes(text, "0.1.0")

    def test_personal_release_notes_reject_unsafe_gatekeeper_bypass(self):
        unsafe = (
            "# NotchHub v0.1.0 — Personal build\n\n"
            "## Personal build — not notarized\n\n"
            "ad-hoc signed. Open Anyway. Run xattr -dr com.apple.quarantine /Applications/NotchHub.app\n"
        )
        with self.assertRaises(ValueError):
            validate_personal_release_notes(unsafe, "0.1.0")

    def test_repository_contains_valid_notes_for_current_version(self):
        version = (REPOSITORY_ROOT / "VERSION").read_text(encoding="utf-8").strip()
        notes_path = REPOSITORY_ROOT / "docs" / "releases" / f"v{version}.md"
        self.assertTrue(notes_path.is_file(), f"missing versioned release notes: {notes_path}")
        validate_personal_release_notes(notes_path.read_text(encoding="utf-8"), version)

    def test_build_metadata_has_exact_personal_release_schema(self):
        metadata = build_metadata(
            version="0.1.0",
            build_number="42",
            source_sha="0123456789abcdef0123456789abcdef01234567",
            runner_os="macOS 26.5.2",
            xcode_version="Xcode 26.6",
            swift_version="Swift 6.3.3",
            dmg_sha256="a" * 64,
            dmg_size_bytes=12345,
            app_size_bytes=67890,
            executable_size_bytes=4567,
        )

        expected_keys = {
            "schemaVersion",
            "version",
            "tag",
            "buildNumber",
            "sourceCommit",
            "runnerOS",
            "xcodeVersion",
            "swiftVersion",
            "dmgSHA256",
            "dmgSizeBytes",
            "appSizeBytes",
            "executableSizeBytes",
            "distributionTier",
            "appleTrusted",
            "notarized",
        }
        self.assertEqual(expected_keys, set(metadata))
        self.assertEqual(1, metadata["schemaVersion"])
        self.assertEqual("v0.1.0", metadata["tag"])
        self.assertEqual(42, metadata["buildNumber"])
        self.assertEqual("personal", metadata["distributionTier"])
        self.assertIs(False, metadata["appleTrusted"])
        self.assertIs(False, metadata["notarized"])

    def test_build_metadata_rejects_invalid_provenance(self):
        base = dict(
            version="0.1.0",
            build_number="42",
            source_sha="0123456789abcdef0123456789abcdef01234567",
            runner_os="macOS 26.5.2",
            xcode_version="Xcode 26.6",
            swift_version="Swift 6.3.3",
            dmg_sha256="a" * 64,
            dmg_size_bytes=1,
            app_size_bytes=1,
            executable_size_bytes=1,
        )

        cases = (
            {"source_sha": "abc"},
            {"dmg_sha256": "abc"},
            {"build_number": "0"},
            {"build_number": "not-a-number"},
            {"dmg_size_bytes": -1},
            {"app_size_bytes": -1},
            {"executable_size_bytes": -1},
        )
        for override in cases:
            with self.subTest(override=override):
                values = base | override
                with self.assertRaises(ValueError):
                    build_metadata(**values)

    def test_metadata_json_is_stable_when_sorted(self):
        metadata = build_metadata(
            version="0.1.0",
            build_number="1",
            source_sha="0123456789abcdef0123456789abcdef01234567",
            runner_os="macOS",
            xcode_version="Xcode",
            swift_version="Swift",
            dmg_sha256="b" * 64,
            dmg_size_bytes=1,
            app_size_bytes=2,
            executable_size_bytes=3,
        )
        encoded = json.dumps(metadata, sort_keys=True, indent=2) + "\n"
        self.assertTrue(encoded.endswith("\n"))
        self.assertLess(encoded.index('"appleTrusted"'), encoded.index('"version"'))

    def test_personal_release_workflow_has_fail_closed_quality_and_provenance_gates(self):
        workflow_path = REPOSITORY_ROOT / ".github" / "workflows" / "personal-release.yml"
        self.assertTrue(workflow_path.is_file(), f"missing personal release workflow: {workflow_path}")
        workflow = workflow_path.read_text(encoding="utf-8")

        required_fragments = (
            "name: Personal Release",
            "workflow_dispatch:",
            "permissions:\n  contents: write",
            "runs-on: macos-26",
            "persist-credentials: false",
            "fetch-depth: 0",
            "scripts/release_policy.py validate-notes",
            "scripts/security-audit.sh",
            "swift build -Xswiftc -warnings-as-errors",
            "swift test --parallel --enable-code-coverage",
            "codesign --verify --deep --strict",
            "flags=.*runtime",
            "com.apple.security.app-sandbox",
            "hdiutil verify",
            "shasum -a 256",
            "scripts/release_policy.py metadata",
            "gh release view",
            "git rev-parse -q --verify",
            "gh release create",
            "--notes-file",
            "build-metadata.json",
        )
        for fragment in required_fragments:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, workflow)

        forbidden_fragments = (
            "notarytool",
            "Developer ID Application",
            "APPLE_DEVELOPER_ID",
            "APPLE_NOTARY",
            "environment: release",
            "--clobber",
            "xattr",
            "spctl --master-disable",
        )
        for fragment in forbidden_fragments:
            with self.subTest(fragment=fragment):
                self.assertNotIn(fragment, workflow)

    def test_trusted_release_workflow_is_separate_fail_closed_tier(self):
        workflows = REPOSITORY_ROOT / ".github" / "workflows"
        trusted_path = workflows / "trusted-release.yml"
        ambiguous_path = workflows / "release.yml"

        self.assertTrue(trusted_path.is_file(), f"missing trusted release workflow: {trusted_path}")
        self.assertFalse(ambiguous_path.exists(), f"ambiguous legacy workflow must be removed: {ambiguous_path}")

        workflow = trusted_path.read_text(encoding="utf-8")
        required_fragments = (
            "name: Trusted Release",
            "environment: release",
            "Developer ID Application",
            "notarytool",
            "stapler",
            "source=Notarized Developer ID",
            "APPLE_DEVELOPER_ID_P12_BASE64",
            "APPLE_NOTARY_KEY_P8",
            "gh release view",
            "git rev-parse -q --verify",
            "gh release create",
        )
        for fragment in required_fragments:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, workflow)

        self.assertNotIn("--clobber", workflow)


if __name__ == "__main__":
    unittest.main()
