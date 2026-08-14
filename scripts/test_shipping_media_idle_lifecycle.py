import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent


class ShippingMediaIdleLifecycleTests(unittest.TestCase):
    def test_shipping_media_runtime_is_scoped_to_settled_expanded_presentation(self):
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
        )[1].split("func applicationWillTerminate", 1)[0]
        self.assertNotIn("ShippingMediaRuntime()", did_finish)
        self.assertNotIn("ShippingMediaRuntime(presentationModel:", did_finish)
        self.assertNotIn("mediaRuntime.start()", did_finish)

        required_app_fragments = (
            "private let mediaPresentationModel = ShippingMediaPresentationModel()",
            "panelController.settledPresentationHandler",
            "updateMediaRuntime(for: presentation)",
            "private func updateMediaRuntime(for presentation: NotchPresentation)",
            "case .expanded:",
            "guard mediaRuntime == nil else",
            "let mediaRuntime = composition.makeMediaRuntime(mediaPresentationModel)",
            "mediaRuntime.start()",
            "case .compact:",
            "mediaRuntime?.stop()",
            "mediaRuntime = nil",
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
