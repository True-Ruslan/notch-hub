import CoreGraphics
import Foundation
import Testing
@testable import NotchHubCore

@MainActor
struct NotchPrimaryPressInteractionTests {
    private let layout = NotchLayout(
        hasHardwareNotch: true,
        hardwareNotchWidth: 180,
        compactFrame: CGRect(x: 410, y: 868, width: 180, height: 32),
        peekFrame: CGRect(x: 320, y: 804, width: 360, height: 96),
        expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
    )
    private let insideCompact = CGPoint(x: 500, y: 884)

    @Test
    func primaryPressCancelsPendingHoverAndSuppressesSurfaceMutationUntilRelease() {
        let scheduler = PrimaryPressScheduler()
        var requests: [NotchHoverPeekRequest] = []
        let coordinator = NotchInteractionCoordinator(
            scheduleActivation: { delay, action in
                scheduler.schedule(after: delay, action: action)
            },
            dwellSeconds: 0.12,
            emitHoverPeekRequest: { requests.append($0) },
            emitIntent: { _ in }
        )

        coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact
        )
        #expect(scheduler.pendingCount == 1)

        coordinator.setPrimaryPointerPressed(
            true,
            layout: layout,
            currentPresentation: .compact
        )
        scheduler.advance(by: 1, invokeCancelled: true)

        #expect(requests.isEmpty)
        #expect(scheduler.pendingCount == 0)

        coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact
        )
        scheduler.advance(by: 1)

        #expect(requests.isEmpty)
        #expect(scheduler.pendingCount == 0)
    }

    @Test
    func releaseAfterSwiftUITapExpansionDoesNotRestartCompactHoverActivation() {
        let scheduler = PrimaryPressScheduler()
        var requests: [NotchHoverPeekRequest] = []
        let coordinator = NotchInteractionCoordinator(
            scheduleActivation: { delay, action in
                scheduler.schedule(after: delay, action: action)
            },
            dwellSeconds: 0.12,
            emitHoverPeekRequest: { requests.append($0) },
            emitIntent: { _ in }
        )

        coordinator.pointerMoved(
            to: insideCompact,
            layout: layout,
            currentPresentation: .compact
        )
        coordinator.setPrimaryPointerPressed(
            true,
            layout: layout,
            currentPresentation: .compact
        )

        coordinator.setPrimaryPointerPressed(
            false,
            layout: layout,
            currentPresentation: .expanded
        )
        scheduler.advance(by: 1, invokeCancelled: true)

        #expect(requests.isEmpty)
        #expect(scheduler.pendingCount == 0)
    }
}

@MainActor
private final class PrimaryPressScheduler {
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
        after delay: TimeInterval,
        action: @escaping @MainActor () -> Void
    ) -> @MainActor () -> Void {
        let token = Token()
        entries.append(Entry(deadline: now + delay, token: token, action: action))
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
