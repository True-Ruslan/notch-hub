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
        expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
    )

    private let insideCompact = CGPoint(x: 500, y: 884)
    private let insideExpanded = CGPoint(x: 300, y: 760)
    private let outside = CGPoint(x: 100, y: 500)

    @Test
    func quickTransitBeforeThresholdDoesNotEmitIntent() {
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

        #expect(fixture.intents.isEmpty)
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

        #expect(fixture.intents.isEmpty)
        #expect(fixture.scheduler.pendingCount == 0)
    }

    @Test
    func deliberateHoverEmitsOneEligibleExpansionIntentAtThreshold() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact
        )
        fixture.scheduler.advance(by: 0.11)
        #expect(fixture.intents.isEmpty)

        fixture.scheduler.advance(by: 0.01)

        #expect(
            fixture.intents == [
                NotchInteractionIntent(
                    desiredPresentation: .expanded,
                    cause: .deliberateHover,
                    hapticEligible: true
                )
            ]
        )
    }

    @Test
    func duplicatePointerEventsKeepOnePendingActivationAndOneIntent() {
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

        #expect(
            fixture.intents == [
                NotchInteractionIntent(
                    desiredPresentation: .expanded,
                    cause: .deliberateHover,
                    hapticEligible: true
                )
            ]
        )
    }

    @Test
    func cancelledActivationCannotEmitFromStaleCallback() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact
        )
        fixture.coordinator.pointerMoved(
            to: outside,
            layout: layout,
            currentPresentation: .compact
        )
        fixture.scheduler.advance(by: 1, invokeCancelled: true)

        #expect(fixture.intents.isEmpty)
    }

    @Test
    func reentryStartsFreshFullDwell() {
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
        fixture.coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact
        )

        fixture.scheduler.advance(by: 0.05)
        #expect(fixture.intents.isEmpty)

        fixture.scheduler.advance(by: 0.07)

        #expect(
            fixture.intents == [
                NotchInteractionIntent(
                    desiredPresentation: .expanded,
                    cause: .deliberateHover,
                    hapticEligible: true
                )
            ]
        )
    }

    @Test
    func expandedRetentionEmitsNoIntent() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(
            to: insideExpanded,
            layout: layout,
            currentPresentation: .expanded
        )
        fixture.coordinator.pointerMoved(
            to: insideExpanded,
            layout: layout,
            currentPresentation: .expanded
        )

        #expect(fixture.intents.isEmpty)
        #expect(fixture.scheduler.pendingCount == 0)
    }

    @Test
    func expandedPointerExitEmitsNonHapticCollapseIntent() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(
            to: outside,
            layout: layout,
            currentPresentation: .expanded
        )

        #expect(
            fixture.intents == [
                NotchInteractionIntent(
                    desiredPresentation: .compact,
                    cause: .pointerExit,
                    hapticEligible: false
                )
            ]
        )
    }

    @Test
    func invalidationCancelsPendingActivationAndStaleCallback() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact
        )
        #expect(fixture.scheduler.pendingCount == 1)

        fixture.coordinator.invalidate()
        #expect(fixture.scheduler.pendingCount == 0)

        fixture.scheduler.advance(by: 1, invokeCancelled: true)

        #expect(fixture.intents.isEmpty)
    }

    private func makeFixture() -> Fixture {
        let scheduler = ManualActivationScheduler()
        let recorder = IntentRecorder()
        let coordinator = NotchInteractionCoordinator(
            scheduler: scheduler,
            dwellSeconds: 0.12,
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

@MainActor
private struct Fixture {
    let scheduler: ManualActivationScheduler
    let recorder: IntentRecorder
    let coordinator: NotchInteractionCoordinator

    var intents: [NotchInteractionIntent] {
        recorder.intents
    }
}

@MainActor
private final class IntentRecorder {
    var intents: [NotchInteractionIntent] = []
}

@MainActor
private final class ManualActivationScheduler: NotchActivationScheduling {
    private final class Token: NotchActivationCancellation {
        var isCancelled = false

        func cancel() {
            isCancelled = true
        }
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
    ) -> any NotchActivationCancellation {
        let token = Token()
        entries.append(
            Entry(
                deadline: now + delaySeconds,
                token: token,
                action: action
            )
        )
        return token
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
