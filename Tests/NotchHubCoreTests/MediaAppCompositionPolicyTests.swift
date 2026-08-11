import Foundation
import Testing

struct MediaAppCompositionPolicyTests {
    @Test
    func appOwnsMediaPresentationAndInjectsMediaAwareRoot() throws {
        let appDelegate = try sourceText(
            relativePath: "Sources/NotchHubApp/AppDelegate.swift"
        )

        #expect(appDelegate.contains("private let mediaPresentationModel = ShippingMediaPresentationModel()"))
        #expect(appDelegate.contains("NotchPanelController(contentFactory:"))
        #expect(appDelegate.contains("MediaNotchRootView("))
        #expect(
            appDelegate.contains(
                "ShippingMediaRuntime(presentationModel: mediaPresentationModel)"
            )
        )
    }

    @Test
    func mediaRootIsEventDrivenAndCapabilityDriven() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )

        #expect(source.contains("@ObservedObject"))
        #expect(source.contains("NSImage(data:"))
        #expect(source.contains("ProgressView("))
        #expect(source.contains(".disabled(!presentation.canGoPrevious)"))
        #expect(source.contains(".disabled(!presentation.canGoNext)"))
        #expect(!source.contains("Timer("))
        #expect(!source.contains("Timer.publish"))
        #expect(!source.contains("DispatchSourceTimer"))
        #expect(!source.contains("sleep("))
        #expect(!source.contains("Slider("))
    }

    @Test
    func coreRemainsIndependentFromMediaCore() throws {
        for path in [
            "Sources/NotchHubCore/Notch/NotchPanelController.swift",
            "Sources/NotchHubCore/UI/NotchHostingViewFactory.swift",
            "Sources/NotchHubCore/UI/NotchRootView.swift",
        ] {
            let source = try sourceText(relativePath: path)
            #expect(!source.contains("import NotchHubMediaCore"))
        }
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
