import Foundation
import Testing

struct NotchPanelOwnershipTests {
    @Test
    func panelControllerRoutesPresentationThroughSingleTransitionAuthority() throws {
        let controllerSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )

        #expect(!controllerSource.contains("panel.setFrame("))
        #expect(!controllerSource.contains("NotchHostingViewFactory.applyPresentation"))
        #expect(controllerSource.contains("transitionCoordinator.accept"))
        #expect(controllerSource.contains("transitionCoordinator.desiredPresentation"))
    }

    @Test
    func hostingFactoryOwnsOnlyInitialChromeSetup() throws {
        let factorySource = try sourceText(
            relativePath: "Sources/NotchHubCore/UI/NotchHostingViewFactory.swift"
        )

        #expect(!factorySource.contains("static func applyPresentation"))
        #expect(factorySource.contains("masksToBounds = true"))
        #expect(factorySource.contains("cornerCurve = .continuous"))
        #expect(factorySource.contains("cornerRadius = 12"))
    }

    private func sourceText(relativePath: String) throws -> String {
        let testFile = URL(fileURLWithPath: #filePath)
        let repositoryRoot = testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}
