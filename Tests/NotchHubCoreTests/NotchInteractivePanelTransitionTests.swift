import CoreGraphics
import Foundation
import Testing
@testable import NotchHubCore

@MainActor
struct NotchInteractivePanelTransitionTests {
    private let layout = NotchLayout(
        hasHardwareNotch: true,
        hardwareNotchWidth: 180,
        compactFrame: CGRect(x: 410, y: 868, width: 180, height: 32),
        expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
    )

    @Test
    func interactiveExpansionTracksHalfwayGeometryAndStagesExpandedContent() {
        let fixture = makeFixture()

        #expect(
            fixture.coordinator.beginInteractiveTransition(
                from: .compact,
                layout: layout
            )
        )
        fixture.coordinator.updateInteractiveTransition(
            verticalDistance: 109,
            layout: layout
        )

        #expect(fixture.coordinator.phase.isInteractiveExpanding)
        #expect(fixture.coordinator.desiredPresentation == .expanded)
        #expect(fixture.model.contentPresentation == .expanded)
        #expect(fixture.interactiveDriver.requests.count == 1)
        #expect(
            fixture.interactiveDriver.requests[0].frame
                == CGRect(x: 325, y: 759, width: 350, height: 141)
        )
        #expect(fixture.interactiveDriver.requests[0].cornerRadius == 17)
        #expect(fixture.animationDriver.requests.isEmpty)
        #expect(fixture.haptics.requestCount == 0)
    }

    @Test
    func interactiveExpansionClampsAtExactExpandedEndpoint() {
        let fixture = makeFixture()

        #expect(
            fixture.coordinator.beginInteractiveTransition(
                from: .compact,
                layout: layout
            )
        )
        fixture.coordinator.updateInteractiveTransition(
            verticalDistance: 1_000,
            layout: layout
        )

        #expect(fixture.interactiveDriver.requests.count == 1)
        #expect(fixture.interactiveDriver.requests[0].frame == layout.expandedFrame)
        #expect(fixture.interactiveDriver.requests[0].cornerRadius == 22)
        #expect(fixture.coordinator.phase.isInteractiveExpandingAtFullProgress)
    }

    @Test
    func cancelledInteractiveExpansionSettlesBackToCompactWithoutHaptic() {
        let fixture = makeFixture()

        #expect(
            fixture.coordinator.beginInteractiveTransition(
                from: .compact,
                layout: layout
            )
        )
        fixture.coordinator.updateInteractiveTransition(
            verticalDistance: 109,
            layout: layout
        )
        fixture.coordinator.finishInteractiveTransition(
            commit: false,
            layout: layout
        )

        #expect(fixture.animationDriver.requests.count == 1)
        #expect(fixture.animationDriver.requests[0].frame == layout.compactFrame)
        #expect(fixture.animationDriver.requests[0].cornerRadius == 12)
        #expect(fixture.coordinator.phase.isCollapsing)
        #expect(fixture.coordinator.desiredPresentation == .compact)
        #expect(fixture.model.contentPresentation == .expanded)
        #expect(fixture.haptics.requestCount == 0)

        fixture.animationDriver.complete(index: 0)

        #expect(fixture.coordinator.phase.isCompact)
        #expect(fixture.model.contentPresentation == .compact)
    }

    @Test
    func committedInteractiveExpansionSettlesToExpandedWithoutHaptic() {
        let fixture = makeFixture()

        #expect(
            fixture.coordinator.beginInteractiveTransition(
                from: .compact,
                layout: layout
            )
        )
        fixture.coordinator.updateInteractiveTransition(
            verticalDistance: 109,
            layout: layout
        )
        fixture.coordinator.finishInteractiveTransition(
            commit: true,
            layout: layout
        )

        #expect(fixture.animationDriver.requests.count == 1)
        #expect(fixture.animationDriver.requests[0].frame == layout.expandedFrame)
        #expect(fixture.animationDriver.requests[0].cornerRadius == 22)
        #expect(fixture.coordinator.phase.isExpanding)
        #expect(fixture.coordinator.desiredPresentation == .expanded)
        #expect(fixture.haptics.requestCount == 0)

        fixture.animationDriver.complete(index: 0)

        #expect(fixture.coordinator.phase.isExpanded)
        #expect(fixture.model.contentPresentation == .expanded)
    }

    @Test
    func interactiveCollapseTracksHalfwayGeometryAndRetainsExpandedContent() {
        let fixture = makeFixture(initialPresentation: .expanded)

        #expect(
            fixture.coordinator.beginInteractiveTransition(
                from: .expanded,
                layout: layout
            )
        )
        fixture.coordinator.updateInteractiveTransition(
            verticalDistance: 109,
            layout: layout
        )

        #expect(fixture.coordinator.phase.isInteractiveCollapsing)
        #expect(fixture.coordinator.desiredPresentation == .compact)
        #expect(fixture.model.contentPresentation == .expanded)
        #expect(fixture.interactiveDriver.requests.count == 1)
        #expect(
            fixture.interactiveDriver.requests[0].frame
                == CGRect(x: 325, y: 759, width: 350, height: 141)
        )
        #expect(fixture.interactiveDriver.requests[0].cornerRadius == 17)
        #expect(fixture.animationDriver.requests.isEmpty)
        #expect(fixture.haptics.requestCount == 0)
    }

    @Test
    func cancelledInteractiveCollapseSettlesBackToExpanded() {
        let fixture = makeFixture(initialPresentation: .expanded)

        #expect(
            fixture.coordinator.beginInteractiveTransition(
                from: .expanded,
                layout: layout
            )
        )
        fixture.coordinator.updateInteractiveTransition(
            verticalDistance: 109,
            layout: layout
        )
        fixture.coordinator.finishInteractiveTransition(
            commit: false,
            layout: layout
        )

        #expect(fixture.animationDriver.requests.count == 1)
        #expect(fixture.animationDriver.requests[0].frame == layout.expandedFrame)
        #expect(fixture.animationDriver.requests[0].cornerRadius == 22)
        #expect(fixture.coordinator.phase.isExpanding)
        #expect(fixture.coordinator.desiredPresentation == .expanded)
        #expect(fixture.model.contentPresentation == .expanded)

        fixture.animationDriver.complete(index: 0)

        #expect(fixture.coordinator.phase.isExpanded)
        #expect(fixture.model.contentPresentation == .expanded)
    }

    @Test
    func interactiveLayoutRetargetReappliesCurrentProgressAgainstNewEndpoints() {
        let fixture = makeFixture()

        #expect(
            fixture.coordinator.beginInteractiveTransition(
                from: .compact,
                layout: layout
            )
        )
        fixture.coordinator.updateInteractiveTransition(
            verticalDistance: 109,
            layout: layout
        )

        let retainedMediaLayout = layout.withCompactHorizontalExtension(36)
        fixture.coordinator.animationPolicyDidChange(layout: retainedMediaLayout)

        #expect(fixture.interactiveDriver.requests.count == 2)
        #expect(
            fixture.interactiveDriver.requests[1].frame
                == CGRect(x: 307, y: 759, width: 386, height: 141)
        )
        #expect(fixture.interactiveDriver.requests[1].cornerRadius == 17)
        #expect(fixture.animationDriver.requests.isEmpty)
        #expect(fixture.haptics.requestCount == 0)
    }

    @Test
    func interactiveTransitionStartsOnlyFromMatchingStableEndpoint() {
        let compactFixture = makeFixture()
        let expandedFixture = makeFixture(initialPresentation: .expanded)

        #expect(
            !compactFixture.coordinator.beginInteractiveTransition(
                from: .expanded,
                layout: layout
            )
        )
        #expect(
            !expandedFixture.coordinator.beginInteractiveTransition(
                from: .compact,
                layout: layout
            )
        )

        #expect(
            compactFixture.coordinator.beginInteractiveTransition(
                from: .compact,
                layout: layout
            )
        )
        #expect(
            !compactFixture.coordinator.beginInteractiveTransition(
                from: .compact,
                layout: layout
            )
        )
    }

    @Test
    func pointerIntentCannotReplaceOwnedInteractiveTransition() {
        let fixture = makeFixture()

        #expect(
            fixture.coordinator.beginInteractiveTransition(
                from: .compact,
                layout: layout
            )
        )
        fixture.coordinator.updateInteractiveTransition(
            verticalDistance: 109,
            layout: layout
        )

        fixture.coordinator.accept(.pointerExitCollapse, layout: layout)

        #expect(fixture.coordinator.phase.isInteractiveExpanding)
        #expect(fixture.coordinator.desiredPresentation == .expanded)
        #expect(fixture.animationDriver.requests.isEmpty)
        #expect(fixture.interactiveDriver.requests.count == 1)
    }

    private func makeFixture(
        initialPresentation: NotchPresentation = .compact
    ) -> InteractiveTransitionFixture {
        let model = NotchPanelModel()
        model.setContentPresentation(initialPresentation)
        let animationDriver = InteractiveEndpointAnimationDriver()
        let interactiveDriver = InteractivePresentationDriver()
        let haptics = InteractiveTransitionHapticRecorder()
        let coordinator = NotchPanelTransitionCoordinator(
            model: model,
            initialPresentation: initialPresentation,
            animationDuration: { 0.20 },
            animate: { frame, cornerRadius, duration, completion in
                animationDriver.animate(
                    frame: frame,
                    cornerRadius: cornerRadius,
                    duration: duration,
                    completion: completion
                )
            },
            cancelAnimation: { animationDriver.cancel() },
            performExpansionHaptic: { haptics.performExpansionHaptic() },
            applyInteractivePresentation: { frame, cornerRadius in
                interactiveDriver.apply(
                    frame: frame,
                    cornerRadius: cornerRadius
                )
            }
        )

        return InteractiveTransitionFixture(
            model: model,
            animationDriver: animationDriver,
            interactiveDriver: interactiveDriver,
            haptics: haptics,
            coordinator: coordinator
        )
    }
}

private extension NotchPanelTransitionPhase {
    var isCompact: Bool {
        if case .compact = self { true } else { false }
    }

    var isInteractiveExpanding: Bool {
        if case .interactiveExpanding = self { true } else { false }
    }

    var isInteractiveExpandingAtFullProgress: Bool {
        if case .interactiveExpanding(let progress) = self {
            progress == 1
        } else {
            false
        }
    }

    var isExpanding: Bool {
        if case .expanding = self { true } else { false }
    }

    var isExpanded: Bool {
        if case .expanded = self { true } else { false }
    }

    var isInteractiveCollapsing: Bool {
        if case .interactiveCollapsing = self { true } else { false }
    }

    var isCollapsing: Bool {
        if case .collapsing = self { true } else { false }
    }
}

@MainActor
private struct InteractiveTransitionFixture {
    let model: NotchPanelModel
    let animationDriver: InteractiveEndpointAnimationDriver
    let interactiveDriver: InteractivePresentationDriver
    let haptics: InteractiveTransitionHapticRecorder
    let coordinator: NotchPanelTransitionCoordinator
}

@MainActor
private final class InteractiveEndpointAnimationDriver {
    struct Request {
        let frame: CGRect
        let cornerRadius: CGFloat
        let duration: TimeInterval
        let completion: @MainActor () -> Void
    }

    private(set) var requests: [Request] = []
    private(set) var cancelCount = 0

    func animate(
        frame: CGRect,
        cornerRadius: CGFloat,
        duration: TimeInterval,
        completion: @escaping @MainActor () -> Void
    ) {
        requests.append(
            Request(
                frame: frame,
                cornerRadius: cornerRadius,
                duration: duration,
                completion: completion
            )
        )
    }

    func cancel() {
        cancelCount += 1
    }

    func complete(index: Int) {
        requests[index].completion()
    }
}

@MainActor
private final class InteractivePresentationDriver {
    struct Request {
        let frame: CGRect
        let cornerRadius: CGFloat
    }

    private(set) var requests: [Request] = []

    func apply(frame: CGRect, cornerRadius: CGFloat) {
        requests.append(Request(frame: frame, cornerRadius: cornerRadius))
    }
}

@MainActor
private final class InteractiveTransitionHapticRecorder {
    private(set) var requestCount = 0

    func performExpansionHaptic() {
        requestCount += 1
    }
}
