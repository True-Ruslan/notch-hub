import plistlib
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent


class ProductionMediaTransportCandidateCITests(unittest.TestCase):
    def test_candidate_is_separate_product_and_shipping_app_remains_isolated(self):
        package = (REPOSITORY_ROOT / "Package.swift").read_text(encoding="utf-8")

        self.assertIn(
            '.executable(name: "MediaTransportCandidate", targets: ["MediaTransportCandidate"])',
            package,
        )
        self.assertIn('name: "MediaTransportCandidate"', package)
        self.assertIn('dependencies: ["NotchHubMediaCore"]', package)
        self.assertIn('path: "Tools/ProductionMediaTransportCandidate/CLI"', package)
        self.assertIn(
            '.executableTarget(\n            name: "NotchHubApp",\n            dependencies: ["NotchHubCore"]',
            package,
        )

        forbidden = (
            "MediaTransportCandidate",
            "ProductionMediaTransportCandidate.app",
            "mediaremote-adapter.pl",
            "MediaRemoteAdapter.framework",
        )
        for relative_path in ("scripts/build-app.sh", "scripts/build-dmg.sh"):
            text = (REPOSITORY_ROOT / relative_path).read_text(encoding="utf-8")
            for fragment in forbidden:
                with self.subTest(path=relative_path, fragment=fragment):
                    self.assertNotIn(fragment, text)

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

    def test_ci_smokes_target_acceptance_collector_against_real_candidate(self):
        workflow = (REPOSITORY_ROOT / ".github" / "workflows" / "ci.yml").read_text(
            encoding="utf-8"
        )
        required_fragments = (
            "Smoke production media transport acceptance collector",
            "scripts/production_media_transport_acceptance.py preflight",
            "scripts/production_media_transport_acceptance.py observe",
            "--seconds 1",
            "production-media-transport-preflight-smoke.json",
            "production-media-transport-observe-smoke.json",
        )
        for fragment in required_fragments:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, workflow)


if __name__ == "__main__":
    unittest.main()
