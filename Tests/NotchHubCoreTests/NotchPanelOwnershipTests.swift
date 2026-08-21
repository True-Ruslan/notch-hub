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
    func transitionBoundaryUsesLeanAppKitFunctions() throws {
        let controllerSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )

        #expect(!controllerSource.contains("AppKitNotchPanelAnimationDriver("))
        #expect(controllerSource.contains("animateNotchPanel("))
        #expect(controllerSource.contains("cancelNotchPanelAnimation("))
    }

    @Test
    func shippingTransitionBoundaryReconcilesSettledPhysicalEndpoint() throws {
        let controllerSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )
        let coordinatorSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift"
        )

        #expect(controllerSource.contains("applySettledPresentation: { frame, cornerRadius in"))
        #expect(controllerSource.contains("applyInteractiveNotchPanelPresentation("))
        #expect(coordinatorSource.contains("applySettledPresentation(settledFrame, settledCornerRadius)"))
    }

    @Test
    func animationCancellationFreezesVisibleCornerRadiusBeforeRemovingAnimation() throws {
        let driverSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelAnimationDriver.swift"
        )

        #expect(driverSource.contains("freezeVisibleCornerRadius(chromeView: chromeView)"))
        #expect(driverSource.contains("layer.presentation()?.cornerRadius ?? layer.cornerRadius"))
        #expect(driverSource.contains("setNotchCornerRadius(visibleCornerRadius, on: layer)"))
    }

    @Test
    func reduceMotionObservationUsesSelectorWithoutObserverToken() throws {
        let controllerSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )

        #expect(controllerSource.contains("accessibilityDisplayOptionsDidChangeNotification"))
        #expect(controllerSource.contains("reduceMotion != reduceMotionEnabled"))
        #expect(!controllerSource.contains("accessibilityObserver: NSObjectProtocol?"))
        #expect(controllerSource.contains("selector: #selector(accessibilityDisplayOptionsDidChange(_:))"))
        #expect(controllerSource.contains("workspace.notificationCenter.removeObserver("))
        #expect(controllerSource.contains("@objc private func accessibilityDisplayOptionsDidChange"))
        #expect(controllerSource.contains("transitionCoordinator.animationPolicyDidChange"))
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

    @Test
    func panelControllerAcceptsInjectedContentWithoutMediaDependency() throws {
        let controllerSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )

        #expect(controllerSource.contains("NotchPanelContentFactory"))
        #expect(controllerSource.contains("contentFactory(model, layoutModel)"))
        #expect(!controllerSource.contains("import NotchHubMediaCore"))
    }

    @Test
    func compactWingGeometryRemainsOwnedBySharedPanelLayoutInput() throws {
        let controllerSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )
        let layoutModelSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelLayoutModel.swift"
        )

        #expect(controllerSource.contains("public func setCompactHorizontalExtension"))
        #expect(controllerSource.contains("layoutModel.currentLayout"))
        #expect(layoutModelSource.contains("layout.withCompactHorizontalExtension"))
        #expect(!controllerSource.contains("panel.setFrame("))
    }

    @Test
    func compactExtensionChangeRetargetsTransitionOnlyWhenEffectiveValueChanges() throws {
        let controllerSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )

        #expect(
            controllerSource.contains(
                "guard layoutModel.setCompactHorizontalExtension(extensionWidth) else"
            )
        )
        #expect(
            controllerSource.contains(
                "transitionCoordinator.animationPolicyDidChange(layout: layoutModel.currentLayout)"
            )
        )
        #expect(!controllerSource.contains("panel.setFrame("))
    }

    @Test
    func showKeepsStationaryPointerEligibleForHoverDwell() throws {
        let controllerSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )

        #expect(controllerSource.contains("to: NSEvent.mouseLocation"))
        #expect(!controllerSource.contains("allowActivation: false"))
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
