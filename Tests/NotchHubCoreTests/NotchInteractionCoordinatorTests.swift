import CoreGraphics
import Foundation
import Testing
@testable import NotchHubCore

@MainActor
struct NotchInteractionCoordinatorTests {
    private let layout = NotchLayout(
        hasHardwareNotch: true,
        hardwareNotchWidth: 180,
        compactFrame: CGRect(x: 410, y: 868, width: 180, height: 32),
        peekFrame: CGRect(x: 320, y: 804, width: 360, height: 96),
        expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
    )

    private let insideCompact = CGPoint(x: 500, y: 884)
    private let insidePeek = CGPoint(x: 500, y: 840)
    private let outside = CGPoint(x: 100, y: 500)

    @Test
    func quickTransitBeforeThresholdDoesNotEmitPeekRequest() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact
        )
        fixture.scheduler.advance(by: 0.08)
        fixture.coordinator.pointerMoved(
            to: outside,
            layout: layout,
            currentPresentation: .compact
        )
        fixture.scheduler.advance(by: 1, invokeCancelled: true)

        #expect(fixture.requests.isEmpty)
        #expect(fixture.intents.isEmpty)
        #expect(fixture.scheduler.pendingCount == 0)
    }

    @Test
    func setupSynchronizationNeverEmitsPeekRequest() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact,
            allowActivation: false
        )
        fixture.scheduler.advance(by: 1, invokeCancelled: true)

        #expect(fixture.requests.isEmpty)
        #expect(fixture.scheduler.pendingCount == 0)
    }

    @Test
    func setupSynchronizationNeverEmitsExpansionIntent() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact,
            allowActivation: false
        )
        fixture.scheduler.advance(by: 1, invokeCancelled: true)

        #expect(fixture.requests.isEmpty)
        #expect(fixture.intents.isEmpty)
        #expect(fixture.scheduler.pendingCount == 0)
    }

    @Test
    func hoverDwellEmitsOnePeekRequestAtExactly120Milliseconds() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact
        )
        fixture.scheduler.advance(by: 0.119)
        #expect(fixture.requests.isEmpty)

        fixture.scheduler.advance(by: 0.001)

        #expect(fixture.requests.count == 1)
        #expect(fixture.intents.isEmpty)
    }

    @Test
    func duplicatePointerEventsKeepOnePendingActivationAndOneRequest() {
        let fixture = makeFixture()

        for _ in 0..<3 {
            fixture.coordinator.pointerMoved(
                to: insideCompact,
                layout: layout,
                currentPresentation: .compact
            )
        }

        #expect(fixture.scheduler.pendingCount == 1)

        fixture.scheduler.advance(by: 0.12)

        #expect(fixture.requests.count == 1)
    }

    @Test
    func currentPositiveMediaResolutionAllowsPeek() {
        let fixture = makeFixture()
        fixture.coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact
        )
        fixture.scheduler.advance(by: 0.12)
        let request = fixture.requests[0]

        let accepted = fixture.coordinator.resolveHoverPeekRequest(
            request,
            mediaAvailable: true,
            layout: layout,
            currentPresentation: .compact
        )

        #expect(accepted)
    }

    @Test
    func noMediaResolutionLeavesCompactAndProducesNoActivation() {
        let fixture = makeFixture()
        fixture.coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact
        )
        fixture.scheduler.advance(by: 0.12)
        let request = fixture.requests[0]

        let accepted = fixture.coordinator.resolveHoverPeekRequest(
            request,
            mediaAvailable: false,
            layout: layout,
            currentPresentation: .compact
        )

        #expect(!accepted)
        #expect(fixture.intents.isEmpty)
    }

    @Test
    func stalePositiveMediaResolutionAfterPointerExitCannotOpenPeek() {
        let fixture = makeFixture()
        fixture.coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact
        )
        fixture.scheduler.advance(by: 0.12)
        let request = fixture.requests[0]

        fixture.coordinator.pointerMoved(
            to: outside,
            layout: layout,
            currentPresentation: .compact
        )

        let accepted = fixture.coordinator.resolveHoverPeekRequest(
            request,
            mediaAvailable: true,
            layout: layout,
            currentPresentation: .compact
        )

        #expect(!accepted)
    }

    @Test
    func newerHoverRequestRejectsOlderPositiveResolution() {
        let fixture = makeFixture()
        fixture.coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact
        )
        fixture.scheduler.advance(by: 0.12)
        let first = fixture.requests[0]

        fixture.coordinator.pointerMoved(
            to: outside,
            layout: layout,
            currentPresentation: .compact
        )
        fixture.coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact
        )
        fixture.scheduler.advance(by: 0.12)

        #expect(fixture.requests.count == 2)
        let accepted = fixture.coordinator.resolveHoverPeekRequest(
            first,
            mediaAvailable: true,
            layout: layout,
            currentPresentation: .compact
        )
        #expect(!accepted)
    }

    @Test
    func interactiveTransitionCancelsPendingAndIssuedHoverActivation() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact
        )
        fixture.scheduler.advance(by: 0.12)
        let request = fixture.requests[0]

        fixture.coordinator.cancelPendingActivationForInteractiveTransition()

        let accepted = fixture.coordinator.resolveHoverPeekRequest(
            request,
            mediaAvailable: true,
            layout: layout,
            currentPresentation: .compact
        )
        #expect(!accepted)
    }

    @Test
    func peekExitDoesNotCollapseBefore140Milliseconds() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(
            to: outside,
            layout: layout,
            currentPresentation: .peek
        )
        fixture.scheduler.advance(by: 0.139)

        #expect(fixture.intents.isEmpty)

        fixture.scheduler.advance(by: 0.001)

        #expect(fixture.intents.count == 1)
        #expect(fixture.intents.first?.isPointerExitCollapse == true)
    }

    @Test
    func peekReentryBefore140MillisecondsCancelsCollapse() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(
            to: outside,
            layout: layout,
            currentPresentation: .peek
        )
        fixture.scheduler.advance(by: 0.10)
        fixture.coordinator.pointerMoved(
            to: insidePeek,
            layout: layout,
            currentPresentation: .peek
        )
        fixture.scheduler.advance(by: 1, invokeCancelled: true)

        #expect(fixture.intents.isEmpty)
        #expect(fixture.scheduler.pendingCount == 0)
    }

    @Test
    func heldPeekInteractionSuppressesCollapseUntilReleased() {
        let fixture = makeFixture()

        fixture.coordinator.setPeekInteractionHeld(
            true,
            layout: layout,
            currentPresentation: .peek
        )
        fixture.coordinator.pointerMoved(
            to: outside,
            layout: layout,
            currentPresentation: .peek
        )
        fixture.scheduler.advance(by: 1)
        #expect(fixture.intents.isEmpty)

        fixture.coordinator.setPeekInteractionHeld(
            false,
            layout: layout,
            currentPresentation: .peek
        )
        fixture.scheduler.advance(by: 0.14)

        #expect(fixture.intents.count == 1)
        #expect(fixture.intents.first?.isPointerExitCollapse == true)
    }

    @Test
    func expandedPointerExitEmitsNonHapticCollapseIntent() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(
            to: outside,
            layout: layout,
            currentPresentation: .expanded
        )

        #expect(fixture.intents.count == 1)
        #expect(fixture.intents.first?.isPointerExitCollapse == true)
        #expect(fixture.scheduler.pendingCount == 0)
    }

    @Test
    func invalidationCancelsPendingActivationCollapseAndStaleCallbacks() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact
        )
        #expect(fixture.scheduler.pendingCount == 1)

        fixture.coordinator.invalidate()
        fixture.scheduler.advance(by: 1, invokeCancelled: true)

        #expect(fixture.requests.isEmpty)
        #expect(fixture.intents.isEmpty)
        #expect(fixture.scheduler.pendingCount == 0)
    }

    private func makeFixture() -> Fixture {
        let scheduler = ManualActivationScheduler()
        let recorder = InteractionRecorder()
        let coordinator = NotchInteractionCoordinator(
            scheduleActivation: { delaySeconds, action in
                scheduler.schedule(after: delaySeconds, action: action)
            },
            dwellSeconds: 0.12,
            peekCollapseGraceSeconds: 0.14,
            emitHoverPeekRequest: { request in
                recorder.requests.append(request)
            },
            emitIntent: { intent in
                recorder.intents.append(intent)
            }
        )
        return Fixture(
            scheduler: scheduler,
            recorder: recorder,
            coordinator: coordinator
        )
    }
}

private extension NotchInteractionIntent {
    var isPointerExitCollapse: Bool {
        if case .pointerExitCollapse = self {
            true
        } else {
            false
        }
    }
}

@MainActor
private struct Fixture {
    let scheduler: ManualActivationScheduler
    let recorder: InteractionRecorder
    let coordinator: NotchInteractionCoordinator

    var requests: [NotchHoverPeekRequest] {
        recorder.requests
    }

    var intents: [NotchInteractionIntent] {
        recorder.intents
    }
}

@MainActor
private final class InteractionRecorder {
    var requests: [NotchHoverPeekRequest] = []
    var intents: [NotchInteractionIntent] = []
}

@MainActor
private final class ManualActivationScheduler {
    private final class Token {
        var isCancelled = false
    }

    private struct Entry {
        let deadline: TimeInterval
        let token: Token
        let action: @MainActor () -> Void
    }

    private var now: TimeInterval = 0
    private var entries: [Entry] = []

    var pendingCount: Int {
        entries.count(where: { !$0.token.isCancelled })
    }

    func schedule(
        after delaySeconds: TimeInterval,
        action: @escaping @MainActor () -> Void
    ) -> @MainActor () -> Void {
        let token = Token()
        entries.append(
            Entry(
                deadline: now + delaySeconds,
                token: token,
                action: action
            )
        )
        return { token.isCancelled = true }
    }

    func advance(by seconds: TimeInterval, invokeCancelled: Bool = false) {
        now += seconds

        let due = entries.filter { $0.deadline <= now }
        entries.removeAll { $0.deadline <= now }

        for entry in due {
            if !entry.token.isCancelled || invokeCancelled {
                entry.action()
            }
        }
    }
}
