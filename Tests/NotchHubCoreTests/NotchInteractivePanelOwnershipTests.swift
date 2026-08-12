import Foundation
import Testing

struct NotchInteractivePanelOwnershipTests {
    @Test
    func panelControllerExposesOnlyNarrowInteractiveTransitionSurface() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )

        #expect(source.contains("public func beginInteractiveExpansion() -> Bool"))
        #expect(source.contains("public func beginInteractiveCollapse() -> Bool"))
        #expect(source.contains("public func updateInteractiveTransition(verticalDistance: CGFloat)"))
        #expect(source.contains("public func finishInteractiveTransition(commit: Bool)"))
        #expect(source.contains("interactionCoordinator.cancelPendingActivationForInteractiveTransition()"))
        #expect(source.contains("transitionCoordinator.beginInteractiveTransition"))
        #expect(source.contains("transitionCoordinator.updateInteractiveTransition"))
        #expect(source.contains("transitionCoordinator.finishInteractiveTransition"))
        #expect(!source.contains("panel.setFrame("))
    }

    @Test
    func interactivePanelFrameMutationRemainsInsideCoreAnimationDriverBoundary() throws {
        let controllerSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )
        let driverSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelAnimationDriver.swift"
        )

        #expect(controllerSource.contains("applyInteractiveNotchPanelPresentation("))
        #expect(!controllerSource.contains("panel.setFrame("))
        #expect(driverSource.contains("func applyInteractiveNotchPanelPresentation("))
        #expect(driverSource.contains("panel.setFrame(frame, display: true)"))
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
