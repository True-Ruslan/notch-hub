import CoreGraphics
import Foundation
import Testing
@testable import NotchHubCore

@MainActor
struct M66PhysicalAcceptance20260815RegressionTests {
    private let layout = NotchLayout(
        hasHardwareNotch: true,
        hardwareNotchWidth: 180,
        compactFrame: CGRect(x: 410, y: 868, width: 180, height: 32),
        peekFrame: CGRect(x: 320, y: 804, width: 360, height: 96),
        expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
    )

    @Test
    func noMediaHoverRemainsEligibleForGenericPeekAfterDwell() {
        let scheduler = PhysicalAcceptanceManualScheduler()
        let recorder = PhysicalAcceptanceHoverRecorder()
        let coordinator = NotchInteractionCoordinator(
            scheduleActivation: { delaySeconds, action in
                scheduler.schedule(after: delaySeconds, action: action)
            },
            dwellSeconds: 0.12,
            emitHoverPeekRequest: { request in
                recorder.requests.append(request)
            },
            emitIntent: { _ in }
        )

        coordinator.pointerMoved(
            to: CGPoint(x: 500, y: 884),
            layout: layout,
            currentPresentation: .compact
        )
        scheduler.advance(by: 0.12)

        #expect(recorder.requests.count == 1)
        let accepted = coordinator.resolveHoverPeekRequest(
            recorder.requests[0],
            mediaAvailable: false,
            layout: layout,
            currentPresentation: .compact
        )

        #expect(accepted)
    }

    @Test
    func interactivePointerExitAvoidsHalfOpenCGRectContainsAtExactTopEdge() throws {
        let frame = CGRect(x: 410, y: 868, width: 180, height: 32)
        let exactTopEdge = CGPoint(x: frame.midX, y: frame.maxY)

        #expect(!frame.contains(exactTopEdge))

        let controllerSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )
        #expect(!controllerSource.contains("!panel.frame.contains(pointer)"))
        #expect(controllerSource.contains("containsInteractivePointer"))
    }

    private func sourceText(relativePath: String) throws -> String {
        let testFile = URL(fileURLWithPath: #filePath)
        let repositoryRoot =
            testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}

@MainActor
private final class PhysicalAcceptanceHoverRecorder {
    var requests: [NotchHoverPeekRequest] = []
}

@MainActor
private final class PhysicalAcceptanceManualScheduler {
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

    func advance(by seconds: TimeInterval) {
        now += seconds
        let due = entries.filter { $0.deadline <= now }
        entries.removeAll { $0.deadline <= now }
        for entry in due where !entry.token.isCancelled {
            entry.action()
        }
    }
}
