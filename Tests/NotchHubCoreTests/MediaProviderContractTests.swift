import Testing
@testable import NotchHubCore

@MainActor
struct MediaProviderContractTests {
    @Test
    func providerEmitsTypedSessionEventThroughSingleHandler() {
        let provider = FakeMediaProvider()
        var received: MediaProviderEvent?
        provider.eventHandler = { event in
            received = event
        }

        let snapshot = makeSnapshot()
        provider.emit(.session(snapshot))

        #expect(received == .session(snapshot))
    }

    @Test
    func providerReceivesOnlyTypedSemanticCommands() async {
        let provider = FakeMediaProvider()
        provider.nextCommandResult = .sent

        let result = await provider.send(.seek(seconds: 42))

        #expect(result == .sent)
        #expect(provider.commands == [.seek(seconds: 42)])
    }

    @Test
    func failureAndNoSessionRemainTypedProviderEvents() {
        let sequence = MediaSequence(generation: 4, revision: 9)

        #expect(
            MediaProviderEvent.noSession(sequence)
                == .noSession(MediaSequence(generation: 4, revision: 9))
        )
        #expect(
            MediaProviderEvent.failed(.transport)
                == .failed(.transport)
        )
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
private final class FakeMediaProvider: MediaProvider {
    var eventHandler: (@MainActor @Sendable (MediaProviderEvent) -> Void)?
    var startCount = 0
    var stopCount = 0
    var commands: [MediaCommand] = []
    var nextCommandResult: MediaCommandResult = .sent

    func start() {
        startCount += 1
    }

    func stop() {
        stopCount += 1
    }

    func send(_ command: MediaCommand) async -> MediaCommandResult {
        commands.append(command)
        return nextCommandResult
    }

    func emit(_ event: MediaProviderEvent) {
        eventHandler?(event)
    }
}
