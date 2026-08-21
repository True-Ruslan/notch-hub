import CoreGraphics
import Foundation
import Testing
@testable import NotchHubCore

@MainActor
struct NotchDisplayMigrationTests {
    private let oldLayout = NotchLayout(
        hasHardwareNotch: true,
        hardwareNotchWidth: 176,
        compactFrame: CGRect(x: 668, y: 945, width: 176, height: 37),
        peekFrame: CGRect(x: 576, y: 886, width: 360, height: 96),
        expandedFrame: CGRect(x: 496, y: 732, width: 520, height: 250)
    )

    private let newLayout = NotchLayout(
        hasHardwareNotch: false,
        hardwareNotchWidth: 0,
        compactFrame: CGRect(x: 870, y: 1048, width: 180, height: 32),
        peekFrame: CGRect(x: 780, y: 984, width: 360, height: 96),
        expandedFrame: CGRect(x: 700, y: 830, width: 520, height: 250)
    )

    @Test
    func layoutModelPublishesNewBaseLayoutAndIgnoresDuplicates() {
        let model = NotchPanelLayoutModel(baseLayout: oldLayout)

        #expect(model.currentLayout == oldLayout)
        #expect(model.updateBaseLayout(newLayout))
        #expect(model.currentLayout == newLayout)
        #expect(!model.updateBaseLayout(newLayout))
        #expect(model.currentLayout == newLayout)
    }

    @Test
    func layoutModelPreservesCompactExtensionAcrossDisplayMigration() {
        let model = NotchPanelLayoutModel(baseLayout: oldLayout)

        #expect(model.setCompactHorizontalExtension(36))
        #expect(
            model.currentLayout.compactFrame
                == oldLayout.compactFrame.insetBy(dx: -36, dy: 0)
        )

        #expect(model.updateBaseLayout(newLayout))
        #expect(
            model.currentLayout.compactFrame
                == newLayout.compactFrame.insetBy(dx: -36, dy: 0)
        )
        #expect(model.currentLayout.peekFrame == newLayout.peekFrame)
        #expect(model.currentLayout.expandedFrame == newLayout.expandedFrame)
        #expect(model.currentLayout.hardwareNotchWidth == 0)
    }

    @Test(arguments: [
        NotchPresentation.compact,
        NotchPresentation.peek,
        NotchPresentation.expanded,
    ])
    func stableEndpointMigrationReconcilesPhysicalGeometryWithoutDuplicateSettlement(
        presentation: NotchPresentation
    ) {
        let model = NotchPanelModel()
        model.setContentPresentation(presentation)
        let driver = DisplayMigrationDriver()
        var hapticCount = 0
        var settlements: [NotchPresentation] = []
        let coordinator = makeCoordinator(
            model: model,
            initialPresentation: presentation,
            driver: driver,
            hapticCount: &hapticCount
        )
        coordinator.settledPresentationHandler = { settlements.append($0) }

        coordinator.displayLayoutDidChange(newLayout)

        #expect(driver.animationRequests.isEmpty)
        #expect(driver.cancelCount == 0)
        #expect(driver.settledRequests.count == 1)
        #expect(driver.settledRequests[0].frame == endpointFrame(for: presentation, layout: newLayout))
        #expect(driver.settledRequests[0].radius == endpointRadius(for: presentation))
        #expect(coordinator.desiredPresentation == presentation)
        #expect(coordinator.phase.isSettled(presentation))
        #expect(model.contentPresentation == presentation)
        #expect(settlements.isEmpty)
        #expect(hapticCount == 0)
    }

    @Test
    func inFlightExpansionMigratesToNewExpandedEndpointAndRejectsOldCompletion() {
        let model = NotchPanelModel()
        let driver = DisplayMigrationDriver()
        var hapticCount = 0
        var settlements: [NotchPresentation] = []
        let coordinator = makeCoordinator(
            model: model,
            initialPresentation: .compact,
            driver: driver,
            hapticCount: &hapticCount
        )
        coordinator.settledPresentationHandler = { settlements.append($0) }

        coordinator.accept(.deliberateExpansion, layout: oldLayout)
        #expect(driver.animationRequests.count == 1)
        #expect(hapticCount == 1)

        coordinator.displayLayoutDidChange(newLayout)

        #expect(driver.cancelCount == 1)
        #expect(driver.settledRequests.count == 1)
        #expect(driver.settledRequests[0].frame == newLayout.expandedFrame)
        #expect(driver.settledRequests[0].radius == NotchPanelTransitionCoordinator.expandedCornerRadius)
        #expect(coordinator.desiredPresentation == .expanded)
        #expect(coordinator.phase.isSettled(.expanded))
        #expect(model.contentPresentation == .expanded)
        #expect(settlements == [.expanded])
        #expect(hapticCount == 1)

        driver.completeAnimation(index: 0)

        #expect(driver.settledRequests.count == 1)
        #expect(settlements == [.expanded])
        #expect(coordinator.phase.isSettled(.expanded))
    }

    @Test
    func inFlightCollapseMigratesToNewCompactEndpointAndRejectsOldCompletion() {
        let model = NotchPanelModel()
        model.setContentPresentation(.expanded)
        let driver = DisplayMigrationDriver()
        var hapticCount = 0
        var settlements: [NotchPresentation] = []
        let coordinator = makeCoordinator(
            model: model,
            initialPresentation: .expanded,
            driver: driver,
            hapticCount: &hapticCount
        )
        coordinator.settledPresentationHandler = { settlements.append($0) }

        coordinator.accept(.pointerExitCollapse, layout: oldLayout)
        #expect(driver.animationRequests.count == 1)

        coordinator.displayLayoutDidChange(newLayout)

        #expect(driver.cancelCount == 1)
        #expect(driver.settledRequests.count == 1)
        #expect(driver.settledRequests[0].frame == newLayout.compactFrame)
        #expect(driver.settledRequests[0].radius == NotchPanelTransitionCoordinator.compactCornerRadius)
        #expect(coordinator.desiredPresentation == .compact)
        #expect(coordinator.phase.isSettled(.compact))
        #expect(model.contentPresentation == .compact)
        #expect(settlements == [.compact])
        #expect(hapticCount == 0)

        driver.completeAnimation(index: 0)

        #expect(driver.settledRequests.count == 1)
        #expect(settlements == [.compact])
        #expect(coordinator.phase.isSettled(.compact))
    }

    @Test
    func interactiveExpansionMigrationCancelsBackToCompactOrigin() {
        let model = NotchPanelModel()
        let driver = DisplayMigrationDriver()
        var hapticCount = 0
        var settlements: [NotchPresentation] = []
        let coordinator = makeCoordinator(
            model: model,
            initialPresentation: .compact,
            driver: driver,
            hapticCount: &hapticCount
        )
        coordinator.settledPresentationHandler = { settlements.append($0) }

        #expect(coordinator.beginInteractiveTransition(from: .compact, layout: oldLayout))
        coordinator.updateInteractiveTransition(verticalDistance: 80, layout: oldLayout)
        #expect(coordinator.desiredPresentation == .expanded)

        coordinator.displayLayoutDidChange(newLayout)

        #expect(driver.settledRequests.count == 1)
        #expect(driver.settledRequests[0].frame == newLayout.compactFrame)
        #expect(driver.settledRequests[0].radius == NotchPanelTransitionCoordinator.compactCornerRadius)
        #expect(coordinator.desiredPresentation == .compact)
        #expect(coordinator.phase.isSettled(.compact))
        #expect(model.contentPresentation == .compact)
        #expect(settlements.isEmpty)
        #expect(hapticCount == 0)
    }

    @Test
    func interactiveCollapseMigrationCancelsBackToExpandedOrigin() {
        let model = NotchPanelModel()
        model.setContentPresentation(.expanded)
        let driver = DisplayMigrationDriver()
        var hapticCount = 0
        var settlements: [NotchPresentation] = []
        let coordinator = makeCoordinator(
            model: model,
            initialPresentation: .expanded,
            driver: driver,
            hapticCount: &hapticCount
        )
        coordinator.settledPresentationHandler = { settlements.append($0) }

        #expect(coordinator.beginInteractiveTransition(from: .expanded, layout: oldLayout))
        coordinator.updateInteractiveTransition(verticalDistance: 80, layout: oldLayout)
        #expect(coordinator.desiredPresentation == .compact)

        coordinator.displayLayoutDidChange(newLayout)

        #expect(driver.settledRequests.count == 1)
        #expect(driver.settledRequests[0].frame == newLayout.expandedFrame)
        #expect(driver.settledRequests[0].radius == NotchPanelTransitionCoordinator.expandedCornerRadius)
        #expect(coordinator.desiredPresentation == .expanded)
        #expect(coordinator.phase.isSettled(.expanded))
        #expect(model.contentPresentation == .expanded)
        #expect(settlements.isEmpty)
        #expect(hapticCount == 0)
    }

    @Test
    func controllerOwnsEventDrivenDisplayObserverAndFreshTopologyResolution() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )

        #expect(source.contains("NSApplication.didChangeScreenParametersNotification"))
        #expect(source.contains("NotificationCenter.default.addObserver("))
        #expect(source.contains("NotificationCenter.default.removeObserver("))
        #expect(source.contains("@objc private func displayParametersDidChange"))
        #expect(source.contains("let screens = NSScreen.screens"))
        #expect(source.contains("NotchScreenSelection.preferredIndex("))
        #expect(source.contains("layoutModel.updateBaseLayout("))
        #expect(source.contains("transitionCoordinator.displayLayoutDidChange("))
        #expect(source.contains("pointerMonitor.resetInteractionEscapeMonitoring()"))
        #expect(!source.contains("DispatchSourceTimer"))
        #expect(!source.contains("Timer.publish"))
        #expect(!source.contains("CVDisplayLink"))
        #expect(!source.contains("CADisplayLink"))
    }

    @Test
    func viewsObserveSharedLayoutModelInsteadOfOneTimeDisplayGeometry() throws {
        let appDelegate = try sourceText(relativePath: "Sources/NotchHubApp/AppDelegate.swift")
        let mediaRoot = try sourceText(relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift")
        let coreRoot = try sourceText(relativePath: "Sources/NotchHubCore/UI/NotchRootView.swift")
        let factory = try sourceText(relativePath: "Sources/NotchHubCore/UI/NotchHostingViewFactory.swift")

        #expect(appDelegate.contains("model, layoutModel in"))
        #expect(appDelegate.contains("layoutModel: layoutModel"))
        #expect(mediaRoot.contains("@ObservedObject private var layoutModel: NotchPanelLayoutModel"))
        #expect(mediaRoot.contains("layoutModel.currentLayout.hardwareNotchWidth"))
        #expect(mediaRoot.contains("layoutModel.currentLayout.expandedContentTopInset"))
        #expect(coreRoot.contains("@ObservedObject private var layoutModel: NotchPanelLayoutModel"))
        #expect(coreRoot.contains("layoutModel.currentLayout.expandedContentTopInset"))
        #expect(factory.contains("layoutModel: NotchPanelLayoutModel"))
    }

    private func makeCoordinator(
        model: NotchPanelModel,
        initialPresentation: NotchPresentation,
        driver: DisplayMigrationDriver,
        hapticCount: inout Int
    ) -> NotchPanelTransitionCoordinator {
        NotchPanelTransitionCoordinator(
            model: model,
            initialPresentation: initialPresentation,
            animationDuration: { 0.20 },
            animate: { frame, radius, duration, completion in
                driver.animate(
                    frame: frame,
                    radius: radius,
                    duration: duration,
                    completion: completion
                )
            },
            cancelAnimation: { driver.cancel() },
            performExpansionHaptic: { hapticCount += 1 },
            applyInteractivePresentation: { frame, radius in
                driver.applyInteractive(frame: frame, radius: radius)
            },
            applySettledPresentation: { frame, radius in
                driver.applySettled(frame: frame, radius: radius)
            }
        )
    }

    private func endpointFrame(
        for presentation: NotchPresentation,
        layout: NotchLayout
    ) -> CGRect {
        switch presentation {
        case .compact:
            layout.compactFrame
        case .peek:
            layout.peekFrame
        case .expanded:
            layout.expandedFrame
        }
    }

    private func endpointRadius(for presentation: NotchPresentation) -> CGFloat {
        switch presentation {
        case .compact:
            NotchPanelTransitionCoordinator.compactCornerRadius
        case .peek:
            NotchPanelTransitionCoordinator.peekCornerRadius
        case .expanded:
            NotchPanelTransitionCoordinator.expandedCornerRadius
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

private extension NotchPanelTransitionPhase {
    func isSettled(_ presentation: NotchPresentation) -> Bool {
        switch (self, presentation) {
        case (.compact, .compact), (.peek, .peek), (.expanded, .expanded):
            true
        default:
            false
        }
    }
}

@MainActor
private final class DisplayMigrationDriver {
    struct Request {
        let frame: CGRect
        let radius: CGFloat
    }

    struct AnimationRequest {
        let frame: CGRect
        let radius: CGFloat
        let duration: TimeInterval
        let completion: @MainActor () -> Void
    }

    private(set) var animationRequests: [AnimationRequest] = []
    private(set) var interactiveRequests: [Request] = []
    private(set) var settledRequests: [Request] = []
    private(set) var cancelCount = 0

    func animate(
        frame: CGRect,
        radius: CGFloat,
        duration: TimeInterval,
        completion: @escaping @MainActor () -> Void
    ) {
        animationRequests.append(
            AnimationRequest(
                frame: frame,
                radius: radius,
                duration: duration,
                completion: completion
            )
        )
    }

    func applyInteractive(frame: CGRect, radius: CGFloat) {
        interactiveRequests.append(Request(frame: frame, radius: radius))
    }

    func applySettled(frame: CGRect, radius: CGFloat) {
        settledRequests.append(Request(frame: frame, radius: radius))
    }

    func cancel() {
        cancelCount += 1
    }

    func completeAnimation(index: Int) {
        animationRequests[index].completion()
    }
}
