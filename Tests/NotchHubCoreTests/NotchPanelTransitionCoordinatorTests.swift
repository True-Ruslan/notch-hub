import CoreGraphics
import Foundation
import Testing
@testable import NotchHubCore

@MainActor
struct NotchPanelTransitionCoordinatorTests {
    private let layout = NotchLayout(
        hasHardwareNotch: true,
        hardwareNotchWidth: 180,
        compactFrame: CGRect(x: 410, y: 868, width: 180, height: 32),
        expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
    )

    @Test
    func expansionSettlesOnlyAfterMatchingCompletion() {
        let fixture = makeFixture()

        fixture.coordinator.accept(.deliberateExpansion, layout: layout)

        #expect(fixture.coordinator.phase.isExpanding)
        #expect(fixture.coordinator.desiredPresentation == .expanded)
        #expect(fixture.model.contentPresentation == .expanded)
        #expect(fixture.driver.requests.count == 1)
        #expect(fixture.driver.requests[0].frame == layout.expandedFrame)
        #expect(fixture.driver.requests[0].cornerRadius == 22)
        #expect(fixture.driver.requests[0].duration == 0.20)
        #expect(fixture.haptics.requestCount == 1)

        fixture.driver.complete(index: 0)

        #expect(fixture.coordinator.phase.isExpanded)
        #expect(fixture.coordinator.desiredPresentation == .expanded)
    }

    @Test
    func collapseRetainsExpandedContentUntilMatchingCompletion() {
        let fixture = makeFixture(initialPresentation: .expanded)

        fixture.coordinator.accept(.pointerExitCollapse, layout: layout)

        #expect(fixture.coordinator.phase.isCollapsing)
        #expect(fixture.coordinator.desiredPresentation == .compact)
        #expect(fixture.model.contentPresentation == .expanded)
        #expect(fixture.driver.requests.count == 1)
        #expect(fixture.driver.requests[0].frame == layout.compactFrame)
        #expect(fixture.driver.requests[0].cornerRadius == 12)
        #expect(fixture.haptics.requestCount == 0)

        fixture.driver.complete(index: 0)

        #expect(fixture.model.contentPresentation == .compact)
        #expect(fixture.coordinator.phase.isCompact)
    }

    @Test
    func staleExpansionCompletionCannotWinAfterCollapseReversal() {
        let fixture = makeFixture()

        fixture.coordinator.accept(.deliberateExpansion, layout: layout)
        fixture.coordinator.accept(.pointerExitCollapse, layout: layout)

        #expect(fixture.driver.requests.count == 2)
        #expect(fixture.driver.cancelCount == 1)
        #expect(fixture.coordinator.phase.isCollapsing)
        #expect(fixture.model.contentPresentation == .expanded)

        fixture.driver.complete(index: 0)

        #expect(fixture.coordinator.phase.isCollapsing)
        #expect(fixture.coordinator.desiredPresentation == .compact)
        #expect(fixture.model.contentPresentation == .expanded)

        fixture.driver.complete(index: 1)

        #expect(fixture.coordinator.phase.isCompact)
        #expect(fixture.model.contentPresentation == .compact)
    }

    @Test
    func staleCollapseCompletionCannotWinAfterExpansionReversal() {
        let fixture = makeFixture(initialPresentation: .expanded)

        fixture.coordinator.accept(.pointerExitCollapse, layout: layout)
        fixture.coordinator.accept(.deliberateExpansion, layout: layout)

        #expect(fixture.driver.requests.count == 2)
        #expect(fixture.driver.cancelCount == 1)
        #expect(fixture.coordinator.phase.isExpanding)
        #expect(fixture.coordinator.desiredPresentation == .expanded)
        #expect(fixture.haptics.requestCount == 1)

        fixture.driver.complete(index: 0)

        #expect(fixture.coordinator.phase.isExpanding)
        #expect(fixture.model.contentPresentation == .expanded)

        fixture.driver.complete(index: 1)

        #expect(fixture.coordinator.phase.isExpanded)
        #expect(fixture.model.contentPresentation == .expanded)
    }

    @Test
    func duplicateDesiredExpansionDoesNotStartSecondTransitionOrHaptic() {
        let fixture = makeFixture()

        fixture.coordinator.accept(.deliberateExpansion, layout: layout)
        fixture.coordinator.accept(.deliberateExpansion, layout: layout)

        #expect(fixture.driver.requests.count == 1)
        #expect(fixture.haptics.requestCount == 1)
        #expect(fixture.coordinator.phase.isExpanding)
    }

    @Test
    func nonHapticProgrammaticExpansionNeverRequestsHaptic() {
        let fixture = makeFixture()

        fixture.coordinator.requestProgrammaticExpansion(layout: layout)

        #expect(fixture.driver.requests.count == 1)
        #expect(fixture.haptics.requestCount == 0)
        #expect(fixture.coordinator.phase.isExpanding)
    }

    @Test
    func invalidationDuringExpansionCancelsDriverAndMakesCompletionHarmless() {
        let fixture = makeFixture()

        fixture.coordinator.accept(.deliberateExpansion, layout: layout)
        fixture.coordinator.invalidate()

        #expect(fixture.driver.cancelCount == 1)
        #expect(fixture.coordinator.phase.isExpanding)
        #expect(fixture.model.contentPresentation == .expanded)

        fixture.driver.complete(index: 0)

        #expect(fixture.coordinator.phase.isExpanding)
        #expect(fixture.model.contentPresentation == .expanded)
    }

    @Test
    func invalidationDuringCollapseCancelsDriverAndMakesCompletionHarmless() {
        let fixture = makeFixture(initialPresentation: .expanded)

        fixture.coordinator.accept(.pointerExitCollapse, layout: layout)
        fixture.coordinator.invalidate()

        #expect(fixture.driver.cancelCount == 1)
        #expect(fixture.coordinator.phase.isCollapsing)
        #expect(fixture.model.contentPresentation == .expanded)

        fixture.driver.complete(index: 0)

        #expect(fixture.coordinator.phase.isCollapsing)
        #expect(fixture.model.contentPresentation == .expanded)
    }

    @Test
    func repeatedInvalidationIsIdempotent() {
        let fixture = makeFixture()

        fixture.coordinator.accept(.deliberateExpansion, layout: layout)
        fixture.coordinator.invalidate()
        fixture.coordinator.invalidate()

        #expect(fixture.driver.cancelCount == 1)
    }

    private func makeFixture(
        initialPresentation: NotchPresentation = .compact
    ) -> TransitionFixture {
        let model = NotchPanelModel()
        model.setContentPresentation(initialPresentation)
        let driver = ManualPanelAnimationDriver()
        let duration = AnimationDurationSource(value: 0.20)
        let haptics = TransitionCountingHapticPerformer()
        let coordinator = NotchPanelTransitionCoordinator(
            model: model,
            initialPresentation: initialPresentation,
            animationDuration: { duration.value },
            animate: { frame, cornerRadius, animationDuration, completion in
                driver.animate(
                    frame: frame,
                    cornerRadius: cornerRadius,
                    duration: animationDuration,
                    completion: completion
                )
            },
            cancelAnimation: { driver.cancel() },
            performExpansionHaptic: { haptics.performExpansionHaptic() }
        )

        return TransitionFixture(
            model: model,
            driver: driver,
            duration: duration,
            haptics: haptics,
            coordinator: coordinator
        )
    }
}

private extension NotchPanelTransitionPhase {
    var isCompact: Bool {
        if case .compact = self {
            true
        } else {
            false
        }
    }

    var isExpanding: Bool {
        if case .expanding = self {
            true
        } else {
            false
        }
    }

    var isExpanded: Bool {
        if case .expanded = self {
            true
        } else {
            false
        }
    }

    var isCollapsing: Bool {
        if case .collapsing = self {
            true
        } else {
            false
        }
    }
}

@MainActor
private struct TransitionFixture {
    let model: NotchPanelModel
    let driver: ManualPanelAnimationDriver
    let duration: AnimationDurationSource
    let haptics: TransitionCountingHapticPerformer
    let coordinator: NotchPanelTransitionCoordinator
}

@MainActor
private final class AnimationDurationSource {
    var value: TimeInterval

    init(value: TimeInterval) {
        self.value = value
    }
}

@MainActor
private final class TransitionCountingHapticPerformer {
    private(set) var requestCount = 0

    func performExpansionHaptic() {
        requestCount += 1
    }
}

@MainActor
private final class ManualPanelAnimationDriver {
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
