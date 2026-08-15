import Foundation
import Testing

struct NotchAccessibilityContractPolicyTests {
    @Test
    func appRootsDeclareStableSurfaceAndMediaAccessibilityIdentifiers() throws {
        let notchRoot = try sourceText(
            relativePath: "Sources/NotchHubCore/UI/NotchRootView.swift"
        )
        let mediaRoot = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )
        let hostingFactory = try sourceText(
            relativePath: "Sources/NotchHubCore/UI/NotchHostingViewFactory.swift"
        )

        for identifier in [
            "notch.surface.compact",
            "notch.surface.peek",
            "notch.surface.expanded"
        ] {
            #expect(notchRoot.contains(identifier))
            #expect(mediaRoot.contains(identifier))
        }

        #expect(!mediaRoot.contains("notch.surface.hitTarget"))
        #expect(hostingFactory.contains("notch.surface.hitTarget"))
        #expect(hostingFactory.contains("setAccessibilityElement(true)"))
        #expect(hostingFactory.contains("#if NOTCHHUB_UI_TESTING"))

        for identifier in [
            "media.artwork",
            "media.title",
            "media.artist",
            "media.playPause",
            "media.previous",
            "media.next",
            "media.source"
        ] {
            #expect(mediaRoot.contains(identifier))
        }
    }

    @Test
    func panelControllerExposesNarrowExpansionHapticInjectionSeam() throws {
        let controller = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )
        let recorder = try sourceText(
            relativePath: "Sources/NotchHubApp/UITestSupport/UITestHapticRecorder.swift"
        )

        #expect(controller.contains("performExpansionHaptic:"))
        #expect(controller.contains("@escaping @MainActor () -> Void"))
        #expect(recorder.contains("#if NOTCHHUB_UI_TESTING"))
        #expect(recorder.contains("ui-test.hapticCount"))
    }

    @Test
    func hapticInjectionSeamIsCompileTimeIsolatedFromShipping() throws {
        let controller = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )

        let shippingInitializer = try #require(
            controller.range(
                of: "public convenience init(contentFactory: @escaping NotchPanelContentFactory)"
            )
        )
        let shippingHaptic = try #require(
            controller.range(
                of: "let haptics = AppKitNotchHapticPerformer()",
                range: shippingInitializer.upperBound..<controller.endIndex
            )
        )
        let uiTestingBranch = try #require(
            controller.range(
                of: "#if NOTCHHUB_UI_TESTING",
                range: shippingHaptic.upperBound..<controller.endIndex
            )
        )
        let injectableInitializer = try #require(
            controller.range(
                of: "performExpansionHaptic: @escaping @MainActor () -> Void",
                range: uiTestingBranch.upperBound..<controller.endIndex
            )
        )
        let uiTestingEnd = try #require(
            controller.range(
                of: "#endif",
                range: injectableInitializer.upperBound..<controller.endIndex
            )
        )

        #expect(shippingInitializer.lowerBound < shippingHaptic.lowerBound)
        #expect(shippingHaptic.lowerBound < uiTestingBranch.lowerBound)
        #expect(uiTestingBranch.lowerBound < injectableInitializer.lowerBound)
        #expect(injectableInitializer.lowerBound < uiTestingEnd.lowerBound)
    }

    private func sourceText(relativePath: String) throws -> String {
        let testFile = URL(fileURLWithPath: #filePath)
        let repositoryRoot =
            testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}
