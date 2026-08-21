import CoreGraphics
import Foundation
import Testing
@testable import NotchHubCore

@MainActor
struct NotchPointerMonitorTests {
    @Test
    func startRegistersOnlyOneLocalMouseMovedMonitor() {
        let backend = FakeNotchEventMonitorBackend()
        let monitor = makeMonitor(backend: backend)
        var received: [CGPoint] = []

        monitor.start { point in
            received.append(point)
        }

        #expect(backend.localRegistrationCount == 1)
        #expect(backend.globalRegistrationCount == 0)

        let localPoint = CGPoint(x: 10, y: 20)
        let unrelatedGlobalPoint = CGPoint(x: 30, y: 40)
        backend.emitLocal(localPoint)
        backend.emitGlobal(unrelatedGlobalPoint)

        #expect(received == [localPoint])
    }

    @Test
    func repeatedStartDoesNotRegisterDuplicateMonitors() {
        let backend = FakeNotchEventMonitorBackend()
        let monitor = makeMonitor(backend: backend)

        monitor.start { _ in }
        monitor.start { _ in }

        #expect(backend.localRegistrationCount == 1)
        #expect(backend.globalRegistrationCount == 0)
    }

    @Test
    func invalidateRemovesLocalMonitorExactlyOnce() {
        let backend = FakeNotchEventMonitorBackend()
        let monitor = makeMonitor(backend: backend)

        monitor.start { _ in }
        monitor.invalidate()
        monitor.invalidate()

        #expect(backend.removedTokens == ["local-1"])
    }

    @Test
    func liveMouseMovedDeliveryDoesNotAllocateTaskOrUseGlobalObservation() throws {
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
        #expect(!source.contains("NSEvent.addGlobalMonitorForEvents"))
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
        globalHandler = handler
        return "global-\(globalRegistrationCount)"
    }

    func removeMonitor(_ monitor: Any) {
        removedTokens.append(String(describing: monitor))
    }

    func emitLocal(_ point: CGPoint) {
        localHandler?(point)
    }

    func emitGlobal(_ point: CGPoint) {
        globalHandler?(point)
    }
}
