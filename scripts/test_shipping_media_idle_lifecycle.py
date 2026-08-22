import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent


class ShippingMediaIdleLifecycleTests(unittest.TestCase):
    def test_shipping_media_runtime_runs_for_the_apps_whole_lifetime(self):
        # M6.7 reverses the prior "zero-adapter compact" invariant: the
        # shipping runtime now starts once at launch and stops once at Quit,
        # rather than starting/stopping on every Compact<->Expanded
        # transition, so Compact reflects live state. See
        # docs/superpowers/specs/2026-08-22-live-media-timeline-and-compact-design.md.
        app_delegate = (
            REPOSITORY_ROOT / "Sources" / "NotchHubApp" / "AppDelegate.swift"
        ).read_text(encoding="utf-8")
        app_composition = (
            REPOSITORY_ROOT / "Sources" / "NotchHubApp" / "AppComposition.swift"
        ).read_text(encoding="utf-8")
        panel_controller = (
            REPOSITORY_ROOT
            / "Sources"
            / "NotchHubCore"
            / "Notch"
            / "NotchPanelController.swift"
        ).read_text(encoding="utf-8")

        did_finish = app_delegate.split(
            "func applicationDidFinishLaunching", 1
        )[1].split("func applicationDidResignActive", 1)[0]
        self.assertNotIn("ShippingMediaRuntime()", did_finish)
        self.assertNotIn("ShippingMediaRuntime(presentationModel:", did_finish)
        self.assertIn("mediaRuntime.start()", did_finish)
        self.assertIn(
            "let mediaRuntime = composition.makeMediaRuntime(mediaPresentationModel)",
            did_finish,
        )

        will_terminate = app_delegate.split(
            "func applicationWillTerminate", 1
        )[1].split("func applicationShouldTerminateAfterLastWindowClosed", 1)[0]
        self.assertIn("mediaRuntime?.stop()", will_terminate)
        self.assertIn("mediaRuntime = nil", will_terminate)

        self.assertNotIn("func updateMediaRuntime", app_delegate)

        required_app_fragments = (
            "private let mediaPresentationModel = ShippingMediaPresentationModel()",
            "private let mediaTimelineTicker = MediaTimelineTicker()",
            "private let composition:",
            "AppComposition.shipping()",
            "panelController.settledPresentationHandler",
            "self?.mediaTimelineTicker.setArmed(presentation == .peek || presentation == .expanded)",
        )
        for fragment in required_app_fragments:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, app_delegate)

        self.assertIn("static func shipping() -> Self", app_composition)
        self.assertIn(
            "ShippingMediaRuntime(presentationModel: $0)",
            app_composition,
        )

        self.assertIn(
            "public var settledPresentationHandler:",
            panel_controller,
        )
        self.assertIn(
            "transitionCoordinator.settledPresentationHandler = settledPresentationHandler",
            panel_controller,
        )


if __name__ == "__main__":
    unittest.main()
