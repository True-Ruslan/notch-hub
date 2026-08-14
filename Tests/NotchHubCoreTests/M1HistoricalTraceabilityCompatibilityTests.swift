import CoreGraphics
import Foundation
import Testing
@testable import NotchHubCore

@MainActor
extension NotchInteractionCoordinatorTests {
    @Test
    func quickTransitBeforeThresholdDoesNotEmitIntent() {
        let fixture = makeHistoricalM1Fixture()
        let layout = historicalM1Layout()

        fixture.coordinator.pointerMoved(
            to: CGPoint(x: 500, y: 884),
            layout: layout,
            currentPresentation: .compact
        )
        fixture.scheduler.advance(by: 0.08)
        fixture.coordinator.pointerMoved(
            to: CGPoint(x: 100, y: 500),
            layout: layout,
            currentPresentation: .compact
        )
        fixture.scheduler.advance(by: 1, invokeCancelled: true)

        #expect(fixture.recorder.requests.isEmpty)
        #expect(fixture.recorder.intents.isEmpty)
        #expect(fixture.scheduler.pendingCount == 0)
    }

    @Test
    func expandedRetentionEmitsNoIntent() {
        let fixture = makeHistoricalM1Fixture()
        let layout = historicalM1Layout()

        fixture.coordinator.pointerMoved(
            to: CGPoint(x: 300, y: 760),
            layout: layout,
            currentPresentation: .expanded
        )

        #expect(fixture.recorder.requests.isEmpty)
        #expect(fixture.recorder.intents.isEmpty)
        #expect(fixture.scheduler.pendingCount == 0)
    }
}

@MainActor
private struct HistoricalM1Fixture {
    let scheduler: HistoricalM1ActivationScheduler
    let recorder: HistoricalM1InteractionRecorder
    let coordinator: NotchInteractionCoordinator
}

@MainActor
private func makeHistoricalM1Fixture() -> HistoricalM1Fixture {
    let scheduler = HistoricalM1ActivationScheduler()
    let recorder = HistoricalM1InteractionRecorder()
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
    return HistoricalM1Fixture(
        scheduler: scheduler,
        recorder: recorder,
        coordinator: coordinator
    )
}

private func historicalM1Layout() -> NotchLayout {
    NotchLayout(
        hasHardwareNotch: true,
        hardwareNotchWidth: 180,
        compactFrame: CGRect(x: 410, y: 868, width: 180, height: 32),
        peekFrame: CGRect(x: 320, y: 804, width: 360, height: 96),
        expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
    )
}

@MainActor
private final class HistoricalM1InteractionRecorder {
    var requests: [NotchHoverPeekRequest] = []
    var intents: [NotchInteractionIntent] = []
}

@MainActor
private final class HistoricalM1ActivationScheduler {
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

        for entry in due where !entry.token.isCancelled || invokeCancelled {
            entry.action()
        }
    }
}
