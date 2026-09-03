import Foundation
import Testing

struct MediaAppCompositionPolicyTests {
    @Test
    func appOwnsMediaPresentationAndInjectsMediaAwareRoot() throws {
        let appDelegate = try sourceText(
            relativePath: "Sources/NotchHubApp/AppDelegate.swift"
        )
        let appComposition = try sourceText(
            relativePath: "Sources/NotchHubApp/AppComposition.swift"
        )

        #expect(appDelegate.contains("private static let mediaCompactWingWidth: CGFloat = 36"))
        #expect(appDelegate.contains("private let mediaPresentationModel = ShippingMediaPresentationModel()"))
        #expect(appDelegate.contains("mediaPresentationModel.presentationDidChange ="))
        #expect(appDelegate.contains("setCompactHorizontalExtension("))
        #expect(appDelegate.contains("NotchPanelController("))
        #expect(appDelegate.contains("settingsStore: settingsStore"))
        #expect(appDelegate.contains("MediaNotchRootView("))
        #expect(appDelegate.contains("private var mediaRuntime: (any MediaRuntimeSession)?"))
        #expect(!appDelegate.contains("ShippingMediaRuntime(presentationModel: mediaPresentationModel)"))
        #expect(appComposition.contains("static func shipping() -> Self"))
        #expect(appComposition.contains("ShippingMediaRuntime(presentationModel: $0)"))
    }

    @Test
    func uiTestCompositionIsCompileTimeGuardedAndShippingIsDefault() throws {
        let appDelegate = try sourceText(
            relativePath: "Sources/NotchHubApp/AppDelegate.swift"
        )
        let appComposition = try sourceText(
            relativePath: "Sources/NotchHubApp/AppComposition.swift"
        )
        let presentationModel = try sourceText(
            relativePath: "Sources/NotchHubMediaCore/ShippingMediaPresentationModel.swift"
        )

        #expect(appDelegate.contains("#if NOTCHHUB_UI_TESTING"))
        #expect(appDelegate.contains("AppComposition.uiTesting(configuration: .current())"))
        #expect(appDelegate.contains("AppComposition.shipping()"))
        #expect(appComposition.contains("#if NOTCHHUB_UI_TESTING"))
        #expect(appComposition.contains("static func uiTesting(configuration: UITestConfiguration) -> Self"))
        #expect(presentationModel.contains("#if NOTCHHUB_UI_TESTING"))
        #expect(presentationModel.contains("applyUITestPresentation"))

        for relativePath in [
            "Sources/NotchHubApp/UITestSupport/UITestConfiguration.swift",
            "Sources/NotchHubApp/UITestSupport/UITestMediaRuntime.swift"
        ] {
            let source = try sourceText(relativePath: relativePath)
            #expect(source.contains("#if NOTCHHUB_UI_TESTING"))
            #expect(source.contains("#endif"))
        }
    }

    @Test
    func mediaRootIsEventDrivenCapabilityDrivenAndKeepsNotchCenterClear() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )

        #expect(source.contains("@ObservedObject"))
        #expect(source.contains("NSImage(data:"))
        #expect(source.contains("ProgressView("))
        #expect(source.contains(".disabled(!presentation.canGoPrevious)"))
        #expect(source.contains(".disabled(!presentation.canGoNext)"))
        #expect(source.contains("Color.clear.frame(width: hardwareNotchWidth)"))
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
            "Sources/NotchHubCore/UI/NotchRootView.swift"
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
