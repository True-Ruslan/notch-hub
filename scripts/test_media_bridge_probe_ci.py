import unittest
from pathlib import Path

from test_production_media_transport_acceptance import ProductionMediaTransportAcceptanceTests
from test_production_media_transport_candidate_ci import ProductionMediaTransportCandidateCITests
from test_shipping_media_acceptance import ShippingMediaAcceptanceTests
from test_shipping_media_composition import ShippingMediaCompositionPolicyTests
from test_shipping_media_diagnostic_mode import ShippingMediaDiagnosticModeTests


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent


class MediaBridgeProbeCITests(unittest.TestCase):
    def test_ci_builds_verifies_and_publishes_exact_probe_candidate(self):
        workflow = (
            REPOSITORY_ROOT / ".github" / "workflows" / "ci.yml"
        ).read_text(encoding="utf-8")

        required_fragments = (
            "Build and verify media bridge probe candidate",
            "scripts/build-media-bridge-probe-app.sh",
            "scripts/verify-media-bridge-probe.sh",
            "ditto -c -k --sequesterRsrc --keepParent",
            "build/MediaBridgeProbe.zip",
            "Verify archived media bridge probe candidate",
            "codesign --verify --deep --strict",
            "name: MediaBridgeProbe-candidate",
        )
        for fragment in required_fragments:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, workflow)

        self.assertIn(
            "SOURCE_COMMIT: ${{ github.event.pull_request.head.sha || github.sha }}",
            workflow,
        )

    def test_probe_builds_link_the_executable_product(self):
        workflow = (
            REPOSITORY_ROOT / ".github" / "workflows" / "ci.yml"
        ).read_text(encoding="utf-8")
        build_script = (
            REPOSITORY_ROOT / "scripts" / "build-media-bridge-probe-app.sh"
        ).read_text(encoding="utf-8")

        self.assertIn("--product MediaBridgeProbe", workflow)
        self.assertIn("--product MediaBridgeProbe", build_script)
        self.assertNotIn("--target MediaBridgeProbe", workflow)
        self.assertNotIn("--target MediaBridgeProbe", build_script)

    def test_capability_patch_is_repo_owned_reproducible_and_provenanced(self):
        patch_path = (
            REPOSITORY_ROOT
            / "Tools"
            / "MediaBridgeProbe"
            / "patches"
            / "mediaremote-adapter-capabilities.patch"
        )
        self.assertTrue(patch_path.is_file(), "missing repo-owned capability patch")

        patch = patch_path.read_text(encoding="utf-8")
        bootstrap = (
            REPOSITORY_ROOT / "scripts" / "bootstrap-media-bridge-probe.sh"
        ).read_text(encoding="utf-8")
        build_script = (
            REPOSITORY_ROOT / "scripts" / "build-media-bridge-probe-app.sh"
        ).read_text(encoding="utf-8")
        verify_script = (
            REPOSITORY_ROOT / "scripts" / "verify-media-bridge-probe.sh"
        ).read_text(encoding="utf-8")
        workflow = (
            REPOSITORY_ROOT / ".github" / "workflows" / "ci.yml"
        ).read_text(encoding="utf-8")

        for fragment in (
            "src/adapter/capabilities.m",
            "adapter_capabilities",
            "MRMediaRemoteGetSupportedCommandsForOrigin",
            "MRMediaRemoteCommandInfoGetCommand",
            "MRMediaRemoteCommandInfoGetEnabled",
            "MRMediaRemoteGetNowPlayingApplicationPID",
            "activeNowPlayingSessionState",
            "kMRANextTrack",
            "kMRAPreviousTrack",
            "kMRASeekToPlaybackPosition = 24",
        ):
            with self.subTest(patch_fragment=fragment):
                self.assertIn(fragment, patch)

        self.assertNotIn("kMRANextTrack = 4,", patch)
        self.assertNotIn("kMRAPreviousTrack = 5,", patch)

        for fragment in (
            "mediaremote-adapter-capabilities.patch",
            "git -C \"$SOURCE_DIR\" apply --check",
            "git -C \"$SOURCE_DIR\" apply \"$PATCH_FILE\"",
            "shasum -a 256",
        ):
            with self.subTest(bootstrap_fragment=fragment):
                self.assertIn(fragment, bootstrap)

        self.assertIn("ProbeAdapterPatchSHA256", build_script)
        self.assertIn("ProbeAdapterPatchSHA256", verify_script)
        self.assertIn("MediaBridgeProbe capabilities", workflow)
        self.assertIn("media-bridge-capabilities.json", workflow)

    def test_ci_executes_and_validates_privacy_safe_observation_schema(self):
        workflow = (
            REPOSITORY_ROOT / ".github" / "workflows" / "ci.yml"
        ).read_text(encoding="utf-8")

        for fragment in (
            "MediaBridgeProbe observe --seconds 1",
            "media-bridge-observation.json",
            "schemaVersion",
            "observedSessionDisappearance",
            "sourceSwitchCount",
        ):
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, workflow)


if __name__ == "__main__":
    unittest.main()
