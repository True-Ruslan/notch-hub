import Testing
@testable import NotchHubMediaCore

@MainActor
struct MediaSessionContinuityTests {
    @Test
    func readySessionAndNoSessionExposeDistinctChangeKinds() {
        let provider = ContinuityFakeProvider()
        let controller = MediaSessionController(provider: provider)
        controller.start()

        provider.emit(.ready)
        #expect(controller.lastChangeKind == .ready)

        provider.emit(.session(snapshot(generation: 1, revision: 1, title: "One")))
        #expect(controller.lastChangeKind == .session)

        provider.emit(.noSession(MediaSequence(generation: 2, revision: 1)))
        #expect(controller.lastChangeKind == .noSession)
    }

    @Test
    func explicitNoSessionPublishesEvenWhenReadyAlreadyPublishedIdleNil() {
        let provider = ContinuityFakeProvider()
        let controller = MediaSessionController(provider: provider)
        var changes: [MediaSessionChangeKind] = []
        controller.changeHandler = {
            changes.append(controller.lastChangeKind)
        }
        controller.start()

        provider.emit(.ready)
        provider.emit(.noSession(MediaSequence(generation: 1, revision: 1)))

        #expect(changes == [.ready, .noSession])
        #expect(controller.state == .idle)
        #expect(controller.snapshot == nil)
    }

    @Test
    func unexpectedFailurePublishesUnavailableKindBeforeRestartReady() {
        let provider = ContinuityFakeProvider()
        let controller = MediaSessionController(provider: provider)
        controller.start()
        provider.emit(.session(snapshot(generation: 1, revision: 1, title: "One")))

        provider.emit(.failed(.transport))

        #expect(controller.lastChangeKind == .unavailable)
        #expect(controller.state == .unavailable)
        #expect(controller.snapshot == nil)

        provider.emit(.ready)
        #expect(controller.lastChangeKind == .ready)
        #expect(controller.state == .idle)
    }

    private func snapshot(
        generation: UInt64,
        revision: UInt64,
        title: String
    ) -> MediaSessionSnapshot {
        MediaSessionSnapshot(
            sequence: MediaSequence(generation: generation, revision: revision),
            source: MediaSourceIdentity(bundleIdentifier: "com.example.player", displayName: "Player"),
            title: title,
            artist: "Artist",
            album: nil,
            artworkData: nil,
            playbackState: .playing,
            durationSeconds: 180,
            positionSeconds: 20,
            referenceDate: nil,
            playbackRate: 1,
            capabilities: MediaCommandCapabilities(
                previous: .supported,
                next: .supported,
                seek: .supported
            )
        )
    }
}

@MainActor
private final class ContinuityFakeProvider: MediaProvider {
    var eventHandler: (@MainActor @Sendable (MediaProviderEvent) -> Void)?
    private(set) var startCount = 0
    private(set) var stopCount = 0

    func start() {
        startCount += 1
    }

    func stop() {
        stopCount += 1
    }

    func send(_ command: MediaCommand) async -> MediaCommandResult {
        .failed
    }

    func emit(_ event: MediaProviderEvent) {
        eventHandler?(event)
    }
}
