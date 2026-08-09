import unittest
from pathlib import Path


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


if __name__ == "__main__":
    unittest.main()
