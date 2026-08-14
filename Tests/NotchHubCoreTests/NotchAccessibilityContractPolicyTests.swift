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

        for identifier in [
            "notch.surface.compact",
            "notch.surface.expanded"
        ] {
            #expect(notchRoot.contains(identifier))
            #expect(mediaRoot.contains(identifier))
        }

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

        let uiTestingBranch = try #require(controller.range(of: "#if NOTCHHUB_UI_TESTING"))
        let injectableInitializer = try #require(
            controller.range(of: "performExpansionHaptic: @escaping @MainActor () -> Void")
        )
        let shippingBranch = try #require(
            controller.range(of: "#else", range: injectableInitializer.upperBound..<controller.endIndex)
        )
        let shippingHaptic = try #require(
            controller.range(
                of: "let haptics = AppKitNotchHapticPerformer()",
                range: shippingBranch.upperBound..<controller.endIndex
            )
        )

        #expect(uiTestingBranch.lowerBound < injectableInitializer.lowerBound)
        #expect(injectableInitializer.lowerBound < shippingBranch.lowerBound)
        #expect(shippingBranch.lowerBound < shippingHaptic.lowerBound)
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
