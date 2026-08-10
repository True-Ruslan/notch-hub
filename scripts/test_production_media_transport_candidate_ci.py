import plistlib
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent


class ProductionMediaTransportCandidateCITests(unittest.TestCase):
    def test_candidate_remains_separate_from_shipping_runtime_assets(self):
        package = (REPOSITORY_ROOT / "Package.swift").read_text(encoding="utf-8")

        self.assertIn(
            '.executable(name: "MediaTransportCandidate", targets: ["MediaTransportCandidate"])',
            package,
        )
        self.assertIn('name: "MediaTransportCandidate"', package)
        self.assertIn('dependencies: ["NotchHubMediaCore"]', package)
        self.assertIn('path: "Tools/ProductionMediaTransportCandidate/CLI"', package)
        self.assertIn(
            '.executableTarget(\n            name: "NotchHubApp",\n            dependencies: ["NotchHubCore", "NotchHubMediaCore"]',
            package,
        )

        build_app = (REPOSITORY_ROOT / "scripts" / "build-app.sh").read_text(encoding="utf-8")
        for required in (
            "mediaremote-adapter.pl",
            "MediaRemoteAdapter.framework",
            "MediaRemoteAdapter-LICENSE.txt",
            "media-transport-provenance.json",
        ):
            with self.subTest(required=required):
                self.assertIn(required, build_app)

        for forbidden in (
            "MediaTransportCandidate",
            "ProductionMediaTransportCandidate.app",
            "MediaRemoteAdapterTestClient",
            "MediaBridgeProbe.app",
        ):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, build_app)

        build_dmg = (REPOSITORY_ROOT / "scripts" / "build-dmg.sh").read_text(encoding="utf-8")
        for forbidden in (
            "MediaTransportCandidate",
            "ProductionMediaTransportCandidate.app",
            "MediaRemoteAdapterTestClient",
            "MediaBridgeProbe.app",
        ):
            with self.subTest(path="scripts/build-dmg.sh", forbidden=forbidden):
                self.assertNotIn(forbidden, build_dmg)

    def test_candidate_has_exact_sandbox_only_entitlement(self):
        path = REPOSITORY_ROOT / "Resources" / "ProductionMediaTransportCandidate.entitlements"
        self.assertTrue(path.is_file(), f"missing candidate entitlements: {path}")
        with path.open("rb") as handle:
            actual = plistlib.load(handle)
        self.assertEqual({"com.apple.security.app-sandbox": True}, actual)

    def test_candidate_build_and_verify_scripts_lock_provenance_and_runtime_boundary(self):
        build_path = REPOSITORY_ROOT / "scripts" / "build-production-media-transport-candidate.sh"
        verify_path = REPOSITORY_ROOT / "scripts" / "verify-production-media-transport-candidate.sh"
        self.assertTrue(build_path.is_file(), f"missing candidate build script: {build_path}")
        self.assertTrue(verify_path.is_file(), f"missing candidate verify script: {verify_path}")

        build = build_path.read_text(encoding="utf-8")
        required_build_fragments = (
            "bootstrap-media-bridge-probe.sh",
            "swift build -c release --product MediaTransportCandidate",
            "-Xswiftc -warnings-as-errors",
            "ProductionMediaTransportCandidate.app",
            "mediaremote-adapter.pl",
            "MediaRemoteAdapter.framework",
            "LICENSE",
            "production-media-transport-provenance.json",
            "3ac3d4bdf862c7b5399b4fba4df5689f5c38609a",
            "mediaremote-adapter-capabilities.patch",
            "ProductionMediaTransportCandidate.entitlements",
            "codesign",
            "--options runtime",
            "SOURCE_COMMIT",
        )
        for fragment in required_build_fragments:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, build)
        self.assertNotIn("MediaRemoteAdapterTestClient", build)

        verify = verify_path.read_text(encoding="utf-8")
        required_verify_fragments = (
            "codesign --verify --deep --strict",
            "flags=.*runtime",
            "com.apple.security.app-sandbox",
            "NHSourceCommit",
            "NHAdapterCommit",
            "NHAdapterPatchSHA256",
            "production-media-transport-provenance.json",
            "3ac3d4bdf862c7b5399b4fba4df5689f5c38609a",
            "MediaRemoteAdapterTestClient",
            "otool -L",
        )
        for fragment in required_verify_fragments:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, verify)

    def test_ci_builds_executes_validates_and_uploads_production_candidate(self):
        workflow = (REPOSITORY_ROOT / ".github" / "workflows" / "ci.yml").read_text(
            encoding="utf-8"
        )
        required_fragments = (
            "Build production media transport candidate",
            "build-production-media-transport-candidate.sh",
            "verify-production-media-transport-candidate.sh",
            "MediaTransportCandidate capabilities",
            "MediaTransportCandidate observe --seconds 1",
            "production-media-transport-capabilities.json",
            "production-media-transport-observation.json",
            "observedArtworkClearOnSourceSwitch",
            "ProductionMediaTransportCandidate.zip",
            "Verify archived production media transport candidate",
            "ProductionMediaTransportCandidate-candidate",
        )
        for fragment in required_fragments:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, workflow)

        self.assertIn("${{ github.event.pull_request.head.sha || github.sha }}", workflow)

    def test_ci_smokes_target_acceptance_collector_via_candidate_verification(self):
        workflow = (REPOSITORY_ROOT / ".github" / "workflows" / "ci.yml").read_text(
            encoding="utf-8"
        )
        verify = (
            REPOSITORY_ROOT / "scripts" / "verify-production-media-transport-candidate.sh"
        ).read_text(encoding="utf-8")

        self.assertIn("verify-production-media-transport-candidate.sh", workflow)
        required_fragments = (
            "production_media_transport_acceptance.py",
            "preflight",
            "observe",
            "--seconds 1",
            "production-media-transport-preflight-smoke.json",
            "production-media-transport-observe-smoke.json",
        )
        for fragment in required_fragments:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, verify)


if __name__ == "__main__":
    unittest.main()
