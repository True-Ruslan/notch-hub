import Testing
@testable import NotchHubMediaCore

@MainActor
struct SystemMediaBridgeTests {
    @Test
    func repeatedStartOwnsOneTransportHandlerAndStartsOnce() {
        let transport = FakeSystemMediaTransport()
        let bridge = SystemMediaBridge(transport: transport)

        bridge.start()
        bridge.start()

        #expect(transport.startCount == 1)
        #expect(transport.installedHandlers.count == 1)
    }

    @Test
    func transportEventsForwardThroughProviderBoundary() {
        let transport = FakeSystemMediaTransport()
        let bridge = SystemMediaBridge(transport: transport)
        var received: [MediaProviderEvent] = []
        bridge.eventHandler = { event in
            received.append(event)
        }
        bridge.start()

        let snapshot = makeSnapshot()
        transport.emit(.ready)
        transport.emit(.session(snapshot))
        transport.emit(.noSession(MediaSequence(generation: 2, revision: 0)))
        transport.emit(.failed(.transport))
        transport.emit(.stopped)

        #expect(received.count == 5)
        guard case .ready = received[0] else {
            Issue.record("Expected ready event")
            return
        }
        guard case .session(let receivedSnapshot) = received[1] else {
            Issue.record("Expected session event")
            return
        }
        #expect(receivedSnapshot.sequence == snapshot.sequence)
        guard case .noSession(let sequence) = received[2] else {
            Issue.record("Expected no-session event")
            return
        }
        #expect(sequence == MediaSequence(generation: 2, revision: 0))
        guard case .failed(let failure) = received[3] else {
            Issue.record("Expected failure event")
            return
        }
        #expect(failure == .transport)
        guard case .stopped = received[4] else {
            Issue.record("Expected stopped event")
            return
        }
    }

    @Test
    func typedCommandsForwardOnlyWhileBridgeIsStarted() async {
        let transport = FakeSystemMediaTransport()
        let bridge = SystemMediaBridge(transport: transport)

        #expect(await bridge.send(.next) == .failed)

        bridge.start()
        #expect(await bridge.send(.seek(seconds: 42)) == .sent)

        bridge.stop()
        #expect(await bridge.send(.previous) == .failed)
        #expect(transport.commands == [.seek(seconds: 42)])
    }

    @Test
    func stopClearsTransportHandlerBeforeTransportTeardown() {
        let transport = FakeSystemMediaTransport()
        let bridge = SystemMediaBridge(transport: transport)
        bridge.start()

        bridge.stop()

        #expect(transport.stopCount == 1)
        #expect(transport.handlerWasNilWhenStopped)
        #expect(transport.eventHandler == nil)
    }

    @Test
    func staleTransportHandlerCannotSurfaceAfterStopOrRestart() {
        let transport = FakeSystemMediaTransport()
        let bridge = SystemMediaBridge(transport: transport)
        var receivedCount = 0
        bridge.eventHandler = { _ in
            receivedCount += 1
        }
        bridge.start()
        let staleHandler = transport.installedHandlers[0]

        bridge.stop()
        staleHandler(.ready)
        #expect(receivedCount == 0)

        bridge.start()
        staleHandler(.ready)
        #expect(receivedCount == 0)

        transport.emit(.ready)
        #expect(receivedCount == 1)
        #expect(transport.startCount == 2)
        #expect(transport.installedHandlers.count == 2)
    }

    private func makeSnapshot() -> MediaSessionSnapshot {
        MediaSessionSnapshot(
            sequence: MediaSequence(generation: 1, revision: 1),
            source: MediaSourceIdentity(
                bundleIdentifier: "ru.yandex.desktop.music",
                displayName: nil
            ),
            title: nil,
            artist: nil,
            album: nil,
            artworkData: nil,
            playbackState: .playing,
            durationSeconds: nil,
            positionSeconds: nil,
            referenceDate: nil,
            playbackRate: nil,
            capabilities: MediaCommandCapabilities(
                previous: .supported,
                next: .supported,
                seek: .supported
            )
        )
    }
}

@MainActor
private final class FakeSystemMediaTransport: SystemMediaTransport {
    var eventHandler: (@MainActor @Sendable (SystemMediaTransportEvent) -> Void)? {
        didSet {
            if let eventHandler {
                installedHandlers.append(eventHandler)
            }
        }
    }

    var installedHandlers: [@MainActor @Sendable (SystemMediaTransportEvent) -> Void] = []
    var startCount = 0
    var stopCount = 0
    var handlerWasNilWhenStopped = false
    var commands: [MediaCommand] = []
    var nextCommandResult: MediaCommandResult = .sent

    func start() {
        startCount += 1
    }

    func stop() {
        stopCount += 1
        handlerWasNilWhenStopped = eventHandler == nil
    }

    func send(_ command: MediaCommand) async -> MediaCommandResult {
        commands.append(command)
        return nextCommandResult
    }

    func emit(_ event: SystemMediaTransportEvent) {
        eventHandler?(event)
    }
}
