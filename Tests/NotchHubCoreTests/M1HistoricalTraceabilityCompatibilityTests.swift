import CoreGraphics
import Foundation
import Testing
@testable import NotchHubCore

@MainActor
extension NotchInteractionCoordinatorTests {
    @Test
    func quickTransitBeforeThresholdDoesNotEmitIntent() {
        let scheduler = HistoricalM1ActivationScheduler()
        var requests: [NotchHoverPeekRequest] = []
        var intents: [NotchInteractionIntent] = []
        let coordinator = makeHistoricalM1Coordinator(
            scheduler: scheduler,
            requests: &requests,
            intents: &intents
        )
        let layout = historicalM1Layout()

        coordinator.pointerMoved(
            to: CGPoint(x: 500, y: 884),
            layout: layout,
            currentPresentation: .compact
        )
        scheduler.advance(by: 0.08)
        coordinator.pointerMoved(
            to: CGPoint(x: 100, y: 500),
            layout: layout,
            currentPresentation: .compact
        )
        scheduler.advance(by: 1, invokeCancelled: true)

        #expect(requests.isEmpty)
        #expect(intents.isEmpty)
        #expect(scheduler.pendingCount == 0)
    }

    @Test
    func expandedRetentionEmitsNoIntent() {
        let scheduler = HistoricalM1ActivationScheduler()
        var requests: [NotchHoverPeekRequest] = []
        var intents: [NotchInteractionIntent] = []
        let coordinator = makeHistoricalM1Coordinator(
            scheduler: scheduler,
            requests: &requests,
            intents: &intents
        )
        let layout = historicalM1Layout()

        coordinator.pointerMoved(
            to: CGPoint(x: 300, y: 760),
            layout: layout,
            currentPresentation: .expanded
        )

        #expect(requests.isEmpty)
        #expect(intents.isEmpty)
        #expect(scheduler.pendingCount == 0)
    }
}

@MainActor
private func makeHistoricalM1Coordinator(
    scheduler: HistoricalM1ActivationScheduler,
    requests: inout [NotchHoverPeekRequest],
    intents: inout [NotchInteractionIntent]
) -> NotchInteractionCoordinator {
    let recorder = HistoricalM1InteractionRecorder(requests: requests, intents: intents)
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
    requests = recorder.requests
    intents = recorder.intents
    return coordinator
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
    var requests: [NotchHoverPeekRequest]
    var intents: [NotchInteractionIntent]

    init(requests: [NotchHoverPeekRequest], intents: [NotchInteractionIntent]) {
        self.requests = requests
        self.intents = intents
    }
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
