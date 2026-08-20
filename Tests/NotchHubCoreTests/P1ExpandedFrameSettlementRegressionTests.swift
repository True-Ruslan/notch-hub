import CoreGraphics
import Foundation
import Testing
@testable import NotchHubCore

@MainActor
struct P1ExpandedFrameSettlementRegressionTests {
    private let layout = NotchLayout(
        hasHardwareNotch: true,
        hardwareNotchWidth: 180,
        compactFrame: CGRect(x: 410, y: 868, width: 180, height: 32),
        peekFrame: CGRect(x: 320, y: 804, width: 360, height: 96),
        expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
    )

    @Test
    func matchingCollapseCompletionReconcilesPhysicalEndpointBeforePublishingCompactContent() {
        let model = NotchPanelModel()
        model.setContentPresentation(.expanded)
        let surface = SimulatedPhysicalPanel(
            frame: layout.expandedFrame,
            cornerRadius: NotchPanelTransitionCoordinator.expandedCornerRadius
        )
        let animations = PendingAnimations()

        let coordinator = NotchPanelTransitionCoordinator(
            model: model,
            initialPresentation: .expanded,
            animationDuration: { 0.20 },
            animate: { _, _, _, completion in
                animations.append(completion)
            },
            cancelAnimation: {},
            performExpansionHaptic: {},
            applySettledPresentation: { frame, cornerRadius in
                #expect(model.contentPresentation == .expanded)
                surface.apply(frame: frame, cornerRadius: cornerRadius)
            }
        )

        coordinator.requestProgrammaticCollapse(layout: layout)
        #expect(model.contentPresentation == .expanded)
        #expect(surface.frame == layout.expandedFrame)

        animations.complete(index: 0)

        #expect(surface.frame == layout.compactFrame)
        #expect(surface.cornerRadius == NotchPanelTransitionCoordinator.compactCornerRadius)
        #expect(model.contentPresentation == .compact)
    }

    @Test
    func staleCompletionCannotReconcilePhysicalEndpointAfterReversal() {
        let model = NotchPanelModel()
        model.setContentPresentation(.expanded)
        let surface = SimulatedPhysicalPanel(
            frame: layout.expandedFrame,
            cornerRadius: NotchPanelTransitionCoordinator.expandedCornerRadius
        )
        let animations = PendingAnimations()

        let coordinator = NotchPanelTransitionCoordinator(
            model: model,
            initialPresentation: .expanded,
            animationDuration: { 0.20 },
            animate: { _, _, _, completion in
                animations.append(completion)
            },
            cancelAnimation: {},
            performExpansionHaptic: {},
            applySettledPresentation: { frame, cornerRadius in
                surface.apply(frame: frame, cornerRadius: cornerRadius)
            }
        )

        coordinator.requestProgrammaticCollapse(layout: layout)
        coordinator.requestProgrammaticExpansion(layout: layout)

        animations.complete(index: 0)
        #expect(surface.frame == layout.expandedFrame)
        #expect(model.contentPresentation == .expanded)

        animations.complete(index: 1)
        #expect(surface.frame == layout.expandedFrame)
        #expect(surface.cornerRadius == NotchPanelTransitionCoordinator.expandedCornerRadius)
        #expect(model.contentPresentation == .expanded)
    }
}

@MainActor
private final class PendingAnimations {
    private var completions: [@MainActor () -> Void] = []

    func append(_ completion: @escaping @MainActor () -> Void) {
        completions.append(completion)
    }

    func complete(index: Int) {
        completions[index]()
    }
}

@MainActor
private final class SimulatedPhysicalPanel {
    private(set) var frame: CGRect
    private(set) var cornerRadius: CGFloat

    init(frame: CGRect, cornerRadius: CGFloat) {
        self.frame = frame
        self.cornerRadius = cornerRadius
    }

    func apply(frame: CGRect, cornerRadius: CGFloat) {
        self.frame = frame
        self.cornerRadius = cornerRadius
    }
}
