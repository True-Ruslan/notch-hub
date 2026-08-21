import CoreGraphics
import Foundation
import Testing
@testable import NotchHubCore

@MainActor
struct NotchPointerMonitorTests {
    @Test
    func startIsLocalOnlyUntilPointerActuallyInteractsWithNotchHub() {
        let backend = FakeNotchEventMonitorBackend()
        let monitor = makeMonitor(backend: backend)

        monitor.start { _ in }

        #expect(backend.localRegistrationCount == 1)
        #expect(backend.globalRegistrationCount == 0)
    }

    @Test
    func localPointerEventArmsOneGlobalEscapeMonitorBeforeDelivery() {
        let backend = FakeNotchEventMonitorBackend()
        let monitor = makeMonitor(backend: backend)
        var received: [CGPoint] = []
        var globalCountWhenDelivered: Int?

        monitor.start { point in
            received.append(point)
            globalCountWhenDelivered = backend.globalRegistrationCount
        }

        let localPoint = CGPoint(x: 10, y: 20)
        backend.emitLocal(localPoint)

        #expect(received == [localPoint])
        #expect(globalCountWhenDelivered == 1)
        #expect(backend.globalRegistrationCount == 1)
    }

    @Test
    func repeatedLocalPointerEventsKeepOneGlobalEscapeMonitor() {
        let backend = FakeNotchEventMonitorBackend()
        let monitor = makeMonitor(backend: backend)

        monitor.start { _ in }
        backend.emitLocal(CGPoint(x: 10, y: 20))
        backend.emitLocal(CGPoint(x: 11, y: 21))
        backend.emitLocal(CGPoint(x: 12, y: 22))

        #expect(backend.localRegistrationCount == 1)
        #expect(backend.globalRegistrationCount == 1)
        #expect(backend.removedTokens.isEmpty)
    }

    @Test
    func firstGlobalEscapeDisarmsMonitorBeforeDeliveringOutsidePointer() {
        let backend = FakeNotchEventMonitorBackend()
        let monitor = makeMonitor(backend: backend)
        var observations: [(CGPoint, Int)] = []

        monitor.start { point in
            observations.append((point, backend.removedTokens.count))
        }
        backend.emitLocal(CGPoint(x: 10, y: 20))

        let outsidePoint = CGPoint(x: 30, y: 40)
        backend.emitGlobal(outsidePoint)
        backend.emitGlobal(CGPoint(x: 50, y: 60))

        #expect(observations.count == 2)
        #expect(observations[1].0 == outsidePoint)
        #expect(observations[1].1 == 1)
        #expect(backend.removedTokens == ["global-1"])
    }

    @Test
    func laterLocalPointerEventCanRearmEscapeMonitoring() {
        let backend = FakeNotchEventMonitorBackend()
        let monitor = makeMonitor(backend: backend)

        monitor.start { _ in }
        backend.emitLocal(CGPoint(x: 10, y: 20))
        backend.emitGlobal(CGPoint(x: 30, y: 40))
        backend.emitLocal(CGPoint(x: 11, y: 21))

        #expect(backend.globalRegistrationCount == 2)
        #expect(backend.removedTokens == ["global-1"])
    }

    @Test
    func repeatedStartDoesNotRegisterDuplicateLocalMonitor() {
        let backend = FakeNotchEventMonitorBackend()
        let monitor = makeMonitor(backend: backend)

        monitor.start { _ in }
        monitor.start { _ in }

        #expect(backend.localRegistrationCount == 1)
        #expect(backend.globalRegistrationCount == 0)
    }

    @Test
    func invalidateRemovesActiveLocalAndGlobalMonitorsExactlyOnce() {
        let backend = FakeNotchEventMonitorBackend()
        let monitor = makeMonitor(backend: backend)

        monitor.start { _ in }
        backend.emitLocal(CGPoint(x: 10, y: 20))
        monitor.invalidate()
        monitor.invalidate()

        #expect(backend.removedTokens.sorted() == ["global-1", "local-1"])
    }

    @Test
    func liveMouseMovedDeliveryDoesNotAllocateTaskAndGlobalObservationIsOneShot() throws {
        let testFile = URL(fileURLWithPath: #filePath)
        let repositoryRoot =
            testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: repositoryRoot.appendingPathComponent(
                "Sources/NotchHubCore/Notch/NotchPointerMonitor.swift"
            ),
            encoding: .utf8
        )

        #expect(!source.contains("Task { @MainActor"))
        #expect(source.contains("MainActor.assumeIsolated"))
        #expect(source.contains("NSEvent.addLocalMonitorForEvents"))
        #expect(source.contains("NSEvent.addGlobalMonitorForEvents"))
        #expect(source.contains("armGlobalEscapeMonitorIfNeeded"))
        #expect(source.contains("disarmGlobalEscapeMonitor"))
    }

    private func makeMonitor(backend: FakeNotchEventMonitorBackend) -> NotchPointerMonitor {
        NotchPointerMonitor(
            addLocal: { handler in backend.addLocalMouseMoved(handler: handler) },
            addGlobal: { handler in backend.addGlobalMouseMoved(handler: handler) },
            remove: { token in backend.removeMonitor(token) }
        )
    }
}

@MainActor
private final class FakeNotchEventMonitorBackend {
    private(set) var localRegistrationCount = 0
    private(set) var globalRegistrationCount = 0
    private(set) var removedTokens: [String] = []

    private var localHandler: (@MainActor (CGPoint) -> Void)?
    private var globalHandler: (@MainActor (CGPoint) -> Void)?
    private var activeGlobalToken: String?

    func addLocalMouseMoved(
        handler: @escaping @MainActor (CGPoint) -> Void
    ) -> Any? {
        localRegistrationCount += 1
        localHandler = handler
        return "local-\(localRegistrationCount)"
    }

    func addGlobalMouseMoved(
        handler: @escaping @MainActor (CGPoint) -> Void
    ) -> Any? {
        globalRegistrationCount += 1
        let token = "global-\(globalRegistrationCount)"
        activeGlobalToken = token
        globalHandler = handler
        return token
    }

    func removeMonitor(_ monitor: Any) {
        let token = String(describing: monitor)
        removedTokens.append(token)
        if token == activeGlobalToken {
            activeGlobalToken = nil
            globalHandler = nil
        }
    }

    func emitLocal(_ point: CGPoint) {
        localHandler?(point)
    }

    func emitGlobal(_ point: CGPoint) {
        globalHandler?(point)
    }
}
