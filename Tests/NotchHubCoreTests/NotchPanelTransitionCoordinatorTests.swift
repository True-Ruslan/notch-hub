import CoreGraphics
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

        #expect(fixture.coordinator.phase == .expanding)
        #expect(fixture.coordinator.desiredPresentation == .expanded)
        #expect(fixture.model.contentPresentation == .expanded)
        #expect(fixture.driver.requests.count == 1)
        #expect(fixture.driver.requests[0].frame == layout.expandedFrame)
        #expect(fixture.driver.requests[0].cornerRadius == 22)
        #expect(fixture.haptics.requestCount == 1)

        fixture.driver.complete(index: 0)

        #expect(fixture.coordinator.phase == .expanded)
        #expect(fixture.coordinator.desiredPresentation == .expanded)
    }

    @Test
    func collapseRetainsExpandedContentUntilMatchingCompletion() {
        let fixture = makeFixture(initialPresentation: .expanded)

        fixture.coordinator.accept(.pointerExitCollapse, layout: layout)

        #expect(fixture.coordinator.phase == .collapsing)
        #expect(fixture.coordinator.desiredPresentation == .compact)
        #expect(fixture.model.contentPresentation == .expanded)
        #expect(fixture.driver.requests.count == 1)
        #expect(fixture.driver.requests[0].frame == layout.compactFrame)
        #expect(fixture.driver.requests[0].cornerRadius == 12)
        #expect(fixture.haptics.requestCount == 0)

        fixture.driver.complete(index: 0)

        #expect(fixture.model.contentPresentation == .compact)
        #expect(fixture.coordinator.phase == .compact)
    }

    @Test
    func staleExpansionCompletionCannotWinAfterCollapseReversal() {
        let fixture = makeFixture()

        fixture.coordinator.accept(.deliberateExpansion, layout: layout)
        fixture.coordinator.accept(.pointerExitCollapse, layout: layout)

        #expect(fixture.driver.requests.count == 2)
        #expect(fixture.driver.requests[0].handle.cancelCount == 1)
        #expect(fixture.coordinator.phase == .collapsing)
        #expect(fixture.model.contentPresentation == .expanded)

        fixture.driver.complete(index: 0)

        #expect(fixture.coordinator.phase == .collapsing)
        #expect(fixture.coordinator.desiredPresentation == .compact)
        #expect(fixture.model.contentPresentation == .expanded)

        fixture.driver.complete(index: 1)

        #expect(fixture.coordinator.phase == .compact)
        #expect(fixture.model.contentPresentation == .compact)
    }

    @Test
    func staleCollapseCompletionCannotWinAfterExpansionReversal() {
        let fixture = makeFixture(initialPresentation: .expanded)

        fixture.coordinator.accept(.pointerExitCollapse, layout: layout)
        fixture.coordinator.accept(.deliberateExpansion, layout: layout)

        #expect(fixture.driver.requests.count == 2)
        #expect(fixture.driver.requests[0].handle.cancelCount == 1)
        #expect(fixture.coordinator.phase == .expanding)
        #expect(fixture.coordinator.desiredPresentation == .expanded)
        #expect(fixture.haptics.requestCount == 1)

        fixture.driver.complete(index: 0)

        #expect(fixture.coordinator.phase == .expanding)
        #expect(fixture.model.contentPresentation == .expanded)

        fixture.driver.complete(index: 1)

        #expect(fixture.coordinator.phase == .expanded)
        #expect(fixture.model.contentPresentation == .expanded)
    }

    @Test
    func duplicateDesiredExpansionDoesNotStartSecondTransitionOrHaptic() {
        let fixture = makeFixture()

        fixture.coordinator.accept(.deliberateExpansion, layout: layout)
        fixture.coordinator.accept(.deliberateExpansion, layout: layout)

        #expect(fixture.driver.requests.count == 1)
        #expect(fixture.haptics.requestCount == 1)
        #expect(fixture.coordinator.phase == .expanding)
    }

    @Test
    func nonHapticProgrammaticExpansionNeverRequestsHaptic() {
        let fixture = makeFixture()

        fixture.coordinator.accept(.programmaticExpansion, layout: layout)

        #expect(fixture.driver.requests.count == 1)
        #expect(fixture.haptics.requestCount == 0)
        #expect(fixture.coordinator.phase == .expanding)
    }

    @Test
    func invalidationDuringExpansionCancelsHandleAndMakesCompletionHarmless() {
        let fixture = makeFixture()

        fixture.coordinator.accept(.deliberateExpansion, layout: layout)
        fixture.coordinator.invalidate()

        #expect(fixture.driver.requests[0].handle.cancelCount == 1)
        #expect(fixture.coordinator.phase == .expanding)
        #expect(fixture.model.contentPresentation == .expanded)

        fixture.driver.complete(index: 0)

        #expect(fixture.coordinator.phase == .expanding)
        #expect(fixture.model.contentPresentation == .expanded)
    }

    @Test
    func invalidationDuringCollapseCancelsHandleAndMakesCompletionHarmless() {
        let fixture = makeFixture(initialPresentation: .expanded)

        fixture.coordinator.accept(.pointerExitCollapse, layout: layout)
        fixture.coordinator.invalidate()

        #expect(fixture.driver.requests[0].handle.cancelCount == 1)
        #expect(fixture.coordinator.phase == .collapsing)
        #expect(fixture.model.contentPresentation == .expanded)

        fixture.driver.complete(index: 0)

        #expect(fixture.coordinator.phase == .collapsing)
        #expect(fixture.model.contentPresentation == .expanded)
    }

    @Test
    func repeatedInvalidationIsIdempotent() {
        let fixture = makeFixture()

        fixture.coordinator.accept(.deliberateExpansion, layout: layout)
        fixture.coordinator.invalidate()
        fixture.coordinator.invalidate()

        #expect(fixture.driver.requests[0].handle.cancelCount == 1)
    }

    private func makeFixture(
        initialPresentation: NotchPresentation = .compact
    ) -> TransitionFixture {
        let model = NotchPanelModel()
        model.setContentPresentation(initialPresentation)
        let driver = ManualPanelAnimationDriver()
        let policy = StaticAnimationPolicyProvider(policy: .standard)
        let haptics = TransitionCountingHapticPerformer()
        let coordinator = NotchPanelTransitionCoordinator(
            model: model,
            animationDriver: driver,
            animationPolicy: { policy.currentPolicy },
            haptics: haptics,
            initialPresentation: initialPresentation
        )

        return TransitionFixture(
            model: model,
            driver: driver,
            policy: policy,
            haptics: haptics,
            coordinator: coordinator
        )
    }
}

private extension NotchInteractionIntent {
    static let deliberateExpansion = NotchInteractionIntent(
        desiredPresentation: .expanded,
        cause: .deliberateHover,
        hapticEligible: true
    )

    static let pointerExitCollapse = NotchInteractionIntent(
        desiredPresentation: .compact,
        cause: .pointerExit,
        hapticEligible: false
    )

    static let programmaticExpansion = NotchInteractionIntent(
        desiredPresentation: .expanded,
        cause: .programmatic,
        hapticEligible: false
    )
}

@MainActor
private struct TransitionFixture {
    let model: NotchPanelModel
    let driver: ManualPanelAnimationDriver
    let policy: StaticAnimationPolicyProvider
    let haptics: TransitionCountingHapticPerformer
    let coordinator: NotchPanelTransitionCoordinator
}

@MainActor
private final class StaticAnimationPolicyProvider {
    var currentPolicy: NotchAnimationPolicy

    init(policy: NotchAnimationPolicy) {
        self.currentPolicy = policy
    }
}

@MainActor
private final class TransitionCountingHapticPerformer: NotchHapticPerforming {
    private(set) var requestCount = 0

    func performExpansionHaptic() {
        requestCount += 1
    }
}

@MainActor
private final class ManualPanelAnimationDriver: NotchPanelAnimationDriving {
    final class Handle: NotchPanelAnimationHandle {
        private(set) var cancelCount = 0

        func cancel() {
            cancelCount += 1
        }
    }

    struct Request {
        let frame: CGRect
        let cornerRadius: CGFloat
        let policy: NotchAnimationPolicy
        let completion: @MainActor () -> Void
        let handle: Handle
    }

    private(set) var requests: [Request] = []

    func animate(
        frame: CGRect,
        cornerRadius: CGFloat,
        policy: NotchAnimationPolicy,
        completion: @escaping @MainActor () -> Void
    ) -> any NotchPanelAnimationHandle {
        let handle = Handle()
        requests.append(
            Request(
                frame: frame,
                cornerRadius: cornerRadius,
                policy: policy,
                completion: completion,
                handle: handle
            )
        )
        return handle
    }

    func complete(index: Int) {
        requests[index].completion()
    }
}
