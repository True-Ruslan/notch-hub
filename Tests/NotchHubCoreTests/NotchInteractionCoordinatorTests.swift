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
    func quickTransitBeforeThresholdDoesNotExpand() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(to: insideCompact, layout: layout)
        fixture.scheduler.advance(by: 0.08)
        fixture.coordinator.pointerMoved(to: outside, layout: layout)
        fixture.scheduler.advance(by: 1, invokeCancelled: true)

        #expect(fixture.model.presentation == .compact)
        #expect(fixture.haptics.requestCount == 0)
        #expect(fixture.scheduler.pendingCount == 0)
    }

    @Test
    func deliberateHoverExpandsOnlyAfterThreshold() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(to: insideCompact, layout: layout)
        fixture.scheduler.advance(by: 0.11)
        #expect(fixture.model.presentation == .compact)

        fixture.scheduler.advance(by: 0.02)
        #expect(fixture.model.presentation == .expanded)
    }

    @Test
    func successfulHoverExpansionRequestsExactlyOneHaptic() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(to: insideCompact, layout: layout)
        fixture.scheduler.advance(by: 0.12)

        #expect(fixture.model.presentation == .expanded)
        #expect(fixture.haptics.requestCount == 1)
    }

    @Test
    func duplicatePointerEventsDoNotDuplicatePendingActivationOrHaptic() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(to: insideCompact, layout: layout)
        fixture.coordinator.pointerMoved(to: insideCompact, layout: layout)
        fixture.coordinator.pointerMoved(to: insideCompact, layout: layout)

        #expect(fixture.scheduler.pendingCount == 1)

        fixture.scheduler.advance(by: 0.12)

        #expect(fixture.model.presentation == .expanded)
        #expect(fixture.haptics.requestCount == 1)
    }

    @Test
    func cancelledActivationCannotFireFromStaleCallback() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(to: insideCompact, layout: layout)
        fixture.coordinator.pointerMoved(to: outside, layout: layout)
        fixture.scheduler.advance(by: 1, invokeCancelled: true)

        #expect(fixture.model.presentation == .compact)
        #expect(fixture.haptics.requestCount == 0)
    }

    @Test
    func reentryStartsFreshDwell() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(to: insideCompact, layout: layout)
        fixture.scheduler.advance(by: 0.08)
        fixture.coordinator.pointerMoved(to: outside, layout: layout)
        fixture.coordinator.pointerMoved(to: insideCompact, layout: layout)

        fixture.scheduler.advance(by: 0.05)
        #expect(fixture.model.presentation == .compact)

        fixture.scheduler.advance(by: 0.07)
        #expect(fixture.model.presentation == .expanded)
        #expect(fixture.haptics.requestCount == 1)
    }

    @Test
    func expandedRetentionDoesNotRetriggerHaptic() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(to: insideCompact, layout: layout)
        fixture.scheduler.advance(by: 0.12)
        fixture.coordinator.pointerMoved(to: insideExpanded, layout: layout)
        fixture.coordinator.pointerMoved(to: insideExpanded, layout: layout)

        #expect(fixture.model.presentation == .expanded)
        #expect(fixture.haptics.requestCount == 1)
        #expect(fixture.scheduler.pendingCount == 0)
    }

    @Test
    func collapseThenNewDeliberateHoverCanHapticAgain() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(to: insideCompact, layout: layout)
        fixture.scheduler.advance(by: 0.12)
        fixture.coordinator.pointerMoved(to: outside, layout: layout)
        fixture.coordinator.pointerMoved(to: insideCompact, layout: layout)
        fixture.scheduler.advance(by: 0.12)

        #expect(fixture.model.presentation == .expanded)
        #expect(fixture.haptics.requestCount == 2)
    }

    @Test
    func invalidationCancelsPendingActivationAndStaleCallback() {
        let fixture = makeFixture()

        fixture.coordinator.pointerMoved(to: insideCompact, layout: layout)
        #expect(fixture.scheduler.pendingCount == 1)

        fixture.coordinator.invalidate()
        #expect(fixture.scheduler.pendingCount == 0)

        fixture.scheduler.advance(by: 1, invokeCancelled: true)

        #expect(fixture.model.presentation == .compact)
        #expect(fixture.haptics.requestCount == 0)
    }

    private func makeFixture() -> Fixture {
        let model = NotchPanelModel()
        let scheduler = ManualActivationScheduler()
        let haptics = CountingHapticPerformer()
        let coordinator = NotchInteractionCoordinator(
            model: model,
            scheduler: scheduler,
            haptics: haptics,
            dwellSeconds: 0.12
        )
        return Fixture(
            model: model,
            scheduler: scheduler,
            haptics: haptics,
            coordinator: coordinator
        )
    }
}

@MainActor
private struct Fixture {
    let model: NotchPanelModel
    let scheduler: ManualActivationScheduler
    let haptics: CountingHapticPerformer
    let coordinator: NotchInteractionCoordinator
}

@MainActor
private final class CountingHapticPerformer: NotchHapticPerforming {
    private(set) var requestCount = 0

    func performExpansionHaptic() {
        requestCount += 1
    }
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
