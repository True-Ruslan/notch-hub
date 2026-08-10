import plistlib
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent


class ShippingMediaCompositionPolicyTests(unittest.TestCase):
    def test_shipping_app_target_links_media_core(self):
        package = (REPOSITORY_ROOT / "Package.swift").read_text(encoding="utf-8")
        self.assertIn(
            'name: "NotchHubApp",\n            dependencies: ["NotchHubCore", "NotchHubMediaCore"]',
            package,
        )

    def test_application_composition_root_owns_shell_and_media_lifecycle(self):
        app_delegate = REPOSITORY_ROOT / "Sources" / "NotchHubApp" / "AppDelegate.swift"
        legacy_delegate = REPOSITORY_ROOT / "Sources" / "NotchHubCore" / "App" / "AppDelegate.swift"

        self.assertTrue(app_delegate.is_file(), "shipping AppDelegate must live in NotchHubApp")
        self.assertFalse(legacy_delegate.exists(), "composition root must not remain in NotchHubCore")

        source = app_delegate.read_text(encoding="utf-8")
        for fragment in (
            "import NotchHubCore",
            "import NotchHubMediaCore",
            "NotchPanelController",
            "ShippingMediaRuntime",
            "mediaRuntime.start()",
            "mediaRuntime?.stop()",
        ):
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, source)

        self.assertLess(source.index("mediaRuntime?.stop()"), source.index("mediaRuntime = nil"))

    def test_info_plist_reserves_exact_shipping_provenance_keys(self):
        path = REPOSITORY_ROOT / "Resources" / "Info.plist"
        with path.open("rb") as handle:
            info = plistlib.load(handle)

        for key in ("NHSourceCommit", "NHAdapterCommit", "NHAdapterPatchSHA256"):
            with self.subTest(key=key):
                self.assertIn(key, info)

    def test_build_app_packages_only_pinned_production_media_assets(self):
        build = (REPOSITORY_ROOT / "scripts" / "build-app.sh").read_text(encoding="utf-8")

        required = (
            "--product NotchHub",
            "-Xlinker -dead_strip",
            "bootstrap-media-bridge-probe.sh",
            "3ac3d4bdf862c7b5399b4fba4df5689f5c38609a",
            "mediaremote-adapter-capabilities.patch",
            "mediaremote-adapter.pl",
            "MediaRemoteAdapter.framework",
            "MediaRemoteAdapter-LICENSE.txt",
            "media-transport-provenance.json",
            "NHSourceCommit",
            "NHAdapterCommit",
            "NHAdapterPatchSHA256",
            "SOURCE_COMMIT",
            "MEDIA_FRAMEWORK_DEST",
        )
        for fragment in required:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, build)

        self.assertNotIn("MediaTransportCandidate", build)
        self.assertNotIn("MediaBridgeProbe.app", build)
        self.assertNotIn("MediaRemoteAdapterTestClient", build)

        nested_sign = build.find('codesign "${nested_sign_args[@]}" "$MEDIA_FRAMEWORK_DEST"')
        app_sign = build.find('codesign "${sign_args[@]}" "$APP_DIR"')
        self.assertGreaterEqual(nested_sign, 0, "nested framework must be signed explicitly")
        self.assertGreater(app_sign, nested_sign, "nested code must be signed before the app")

    def test_ci_verifies_shipping_media_bundle_and_keeps_dev_tools_out(self):
        workflow = (
            REPOSITORY_ROOT / ".github" / "workflows" / "ci.yml"
        ).read_text(encoding="utf-8")

        required = (
            'test -f "$APP/Contents/Resources/mediaremote-adapter.pl"',
            'test -d "$APP/Contents/Resources/MediaRemoteAdapter.framework"',
            'test -f "$APP/Contents/Resources/MediaRemoteAdapter-LICENSE.txt"',
            'test -f "$APP/Contents/Resources/media-transport-provenance.json"',
            'plutil -extract NHSourceCommit raw "$APP/Contents/Info.plist"',
            'plutil -extract NHAdapterCommit raw "$APP/Contents/Info.plist"',
            'plutil -extract NHAdapterPatchSHA256 raw "$APP/Contents/Info.plist"',
            'codesign --verify --strict "$APP/Contents/Resources/MediaRemoteAdapter.framework"',
            "MediaRemoteAdapterTestClient",
            "MediaTransportCandidate",
            "MediaBridgeProbe",
        )
        for fragment in required:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, workflow)

    def test_security_policy_distinguishes_shipping_assets_from_dev_probe(self):
        audit = (REPOSITORY_ROOT / "scripts" / "security-audit.sh").read_text(encoding="utf-8")

        required = (
            "SHIPPING_MEDIA_BUILD=\"scripts/build-app.sh\"",
            "SHIPPING_ADAPTER_COMMIT=\"3ac3d4bdf862c7b5399b4fba4df5689f5c38609a\"",
            "ShippingMediaRuntime",
            "MediaRemoteAdapter.framework",
            "mediaremote-adapter.pl",
            "MediaRemoteAdapterTestClient",
        )
        for fragment in required:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, audit)


if __name__ == "__main__":
    unittest.main()
