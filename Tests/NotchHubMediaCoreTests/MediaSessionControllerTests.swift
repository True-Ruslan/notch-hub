import Foundation
import Testing
@testable import NotchHubMediaCore

@MainActor
struct MediaSessionControllerTests {
    @Test
    func startIsIdempotentAndReadyExposesIdle() {
        let provider = ControllerFakeMediaProvider()
        let controller = MediaSessionController(provider: provider)

        controller.start()
        controller.start()
        provider.emit(.ready)

        #expect(provider.startCount == 1)
        #expect(provider.installedHandlers.count == 1)
        #expect(controller.state == .idle)
        #expect(controller.snapshot == nil)
    }

    @Test
    func sessionMapsPlaybackStateAndNewerRevisionWins() {
        let provider = ControllerFakeMediaProvider()
        let controller = MediaSessionController(provider: provider)
        controller.start()

        let playing = makeSnapshot(
            generation: 3,
            revision: 1,
            playbackState: .playing,
            title: "first"
        )
        let paused = makeSnapshot(
            generation: 3,
            revision: 2,
            playbackState: .paused,
            title: "second"
        )

        provider.emit(.session(playing))
        provider.emit(.session(paused))

        #expect(controller.state == .paused)
        #expect(controller.snapshot?.sequence == paused.sequence)
        #expect(controller.snapshot?.title == "second")
    }

    @Test
    func staleAndConflictingSameSequenceUpdatesAreIgnored() {
        let provider = ControllerFakeMediaProvider()
        let controller = MediaSessionController(provider: provider)
        controller.start()

        let current = makeSnapshot(
            generation: 7,
            revision: 4,
            playbackState: .playing,
            title: "current"
        )
        let stale = makeSnapshot(
            generation: 7,
            revision: 3,
            playbackState: .paused,
            title: "stale"
        )
        let conflicting = makeSnapshot(
            generation: 7,
            revision: 4,
            playbackState: .paused,
            title: "conflict"
        )

        provider.emit(.session(current))
        provider.emit(.session(stale))
        provider.emit(.session(conflicting))
        provider.emit(.noSession(MediaSequence(generation: 7, revision: 4)))

        #expect(controller.state == .playing)
        #expect(controller.snapshot?.sequence == current.sequence)
        #expect(controller.snapshot?.title == "current")
    }

    @Test
    func newerGenerationSupersedesOlderGeneration() {
        let provider = ControllerFakeMediaProvider()
        let controller = MediaSessionController(provider: provider)
        controller.start()

        let oldGeneration = makeSnapshot(
            generation: 8,
            revision: 99,
            playbackState: .playing,
            title: "old-generation"
        )
        let newGeneration = makeSnapshot(
            generation: 9,
            revision: 0,
            playbackState: .paused,
            title: "new-generation"
        )

        provider.emit(.session(oldGeneration))
        provider.emit(.session(newGeneration))

        #expect(controller.state == .paused)
        #expect(controller.snapshot?.sequence == newGeneration.sequence)
        #expect(controller.snapshot?.title == "new-generation")
    }

    @Test
    func newerNoSessionClearsOnlyMediaState() {
        let provider = ControllerFakeMediaProvider()
        let controller = MediaSessionController(provider: provider)
        controller.start()
        provider.emit(
            .session(
                makeSnapshot(
                    generation: 2,
                    revision: 5,
                    playbackState: .playing,
                    title: "active"
                )
            )
        )

        provider.emit(.noSession(MediaSequence(generation: 2, revision: 6)))

        #expect(controller.state == .idle)
        #expect(controller.snapshot == nil)
    }

    @Test
    func exactDuplicateSnapshotDoesNotPublishSecondChange() {
        let provider = ControllerFakeMediaProvider()
        let controller = MediaSessionController(provider: provider)
        var changeCount = 0
        controller.changeHandler = {
            changeCount += 1
        }
        controller.start()

        let snapshot = makeSnapshot(
            generation: 1,
            revision: 1,
            playbackState: .playing,
            title: "same"
        )
        provider.emit(.session(snapshot))
        provider.emit(.session(snapshot))

        #expect(changeCount == 1)
        #expect(controller.snapshot?.sequence == snapshot.sequence)
        #expect(controller.snapshot?.title == "same")
    }

    @Test
    func unsupportedOrUnknownCommandsFailClosedWithoutProviderCall() async {
        let provider = ControllerFakeMediaProvider()
        let controller = MediaSessionController(provider: provider)
        controller.start()
        provider.emit(
            .session(
                makeSnapshot(
                    generation: 1,
                    revision: 1,
                    playbackState: .playing,
                    capabilities: MediaCommandCapabilities(
                        previous: .unknown,
                        next: .unsupported,
                        seek: .unknown
                    )
                )
            )
        )

        let previous = await controller.send(.previous)
        let next = await controller.send(.next)
        let seek = await controller.send(.seek(seconds: 42))

        #expect(previous == .failed)
        #expect(next == .failed)
        #expect(seek == .failed)
        #expect(provider.commands.isEmpty)
    }

    @Test
    func supportedCommandsAndToggleUseTypedProviderChannel() async {
        let provider = ControllerFakeMediaProvider()
        let controller = MediaSessionController(provider: provider)
        controller.start()
        provider.emit(
            .session(
                makeSnapshot(
                    generation: 1,
                    revision: 1,
                    playbackState: .playing
                )
            )
        )

        #expect(await controller.send(.togglePlayPause) == .sent)
        #expect(await controller.send(.previous) == .sent)
        #expect(await controller.send(.next) == .sent)
        #expect(await controller.send(.seek(seconds: 42)) == .sent)
        #expect(
            provider.commands == [
                .togglePlayPause,
                .previous,
                .next,
                .seek(seconds: 42)
            ]
        )
    }

    @Test
    func invalidSeekAndCommandsWithoutSessionFailClosed() async {
        let provider = ControllerFakeMediaProvider()
        let controller = MediaSessionController(provider: provider)
        controller.start()

        #expect(await controller.send(.togglePlayPause) == .failed)
        provider.emit(
            .session(
                makeSnapshot(
                    generation: 1,
                    revision: 1,
                    playbackState: .playing
                )
            )
        )

        #expect(await controller.send(.seek(seconds: -1)) == .failed)
        #expect(await controller.send(.seek(seconds: .nan)) == .failed)
        #expect(provider.commands.isEmpty)
    }

    @Test
    func commandFailureDoesNotMutateAuthoritativeSnapshot() async {
        let provider = ControllerFakeMediaProvider()
        provider.nextCommandResult = .failed
        let controller = MediaSessionController(provider: provider)
        controller.start()
        let snapshot = makeSnapshot(
            generation: 1,
            revision: 1,
            playbackState: .playing
        )
        provider.emit(.session(snapshot))

        let result = await controller.send(.next)

        #expect(result == .failed)
        #expect(controller.state == .playing)
        #expect(controller.snapshot?.sequence == snapshot.sequence)
        #expect(controller.snapshot?.playbackState == .playing)
    }

    @Test
    func firstUnexpectedFailureRestartsExactlyOnceAndRejectsOldHandlerEvents() {
        let provider = ControllerFakeMediaProvider()
        let controller = MediaSessionController(provider: provider)
        controller.start()
        provider.emit(
            .session(
                makeSnapshot(
                    generation: 5,
                    revision: 1,
                    playbackState: .playing,
                    title: "before-failure"
                )
            )
        )
        let oldHandler = provider.installedHandlers[0]

        provider.emit(.failed(.transport))

        #expect(provider.stopCount == 1)
        #expect(provider.startCount == 2)
        #expect(provider.installedHandlers.count == 2)
        #expect(controller.state == .unavailable)
        #expect(controller.snapshot == nil)

        oldHandler(
            .session(
                makeSnapshot(
                    generation: 99,
                    revision: 99,
                    playbackState: .playing,
                    title: "stale-handler"
                )
            )
        )
        #expect(controller.snapshot == nil)

        provider.emit(.ready)
        #expect(controller.state == .idle)
    }

    @Test
    func secondUnexpectedFailureStopsAndLocksUnavailableWithoutRestartLoop() {
        let provider = ControllerFakeMediaProvider()
        let controller = MediaSessionController(provider: provider)
        controller.start()

        provider.emit(.failed(.transport))
        provider.emit(.failed(.protocolViolation))
        controller.start()

        #expect(provider.startCount == 2)
        #expect(provider.stopCount == 2)
        #expect(provider.eventHandler == nil)
        #expect(controller.state == .unavailable)
        #expect(controller.snapshot == nil)
    }

    @Test
    func explicitStopDisablesRestartAndClearsMediaOnly() {
        let provider = ControllerFakeMediaProvider()
        let controller = MediaSessionController(provider: provider)
        controller.start()
        provider.emit(
            .session(
                makeSnapshot(
                    generation: 1,
                    revision: 1,
                    playbackState: .playing
                )
            )
        )
        let oldHandler = provider.installedHandlers[0]

        controller.stop()
        oldHandler(.failed(.transport))
        controller.start()

        #expect(provider.stopCount == 1)
        #expect(provider.startCount == 1)
        #expect(provider.eventHandler == nil)
        #expect(controller.state == .unavailable)
        #expect(controller.snapshot == nil)
    }

    private func makeSnapshot(
        generation: UInt64,
        revision: UInt64,
        playbackState: MediaPlaybackState,
        title: String? = nil,
        capabilities: MediaCommandCapabilities = MediaCommandCapabilities(
            previous: .supported,
            next: .supported,
            seek: .supported
        )
    ) -> MediaSessionSnapshot {
        MediaSessionSnapshot(
            sequence: MediaSequence(generation: generation, revision: revision),
            source: MediaSourceIdentity(
                bundleIdentifier: "ru.yandex.desktop.music",
                displayName: nil
            ),
            title: title,
            artist: nil,
            album: nil,
            artworkData: nil,
            playbackState: playbackState,
            durationSeconds: 180,
            positionSeconds: 20,
            referenceDate: Date(timeIntervalSince1970: 1_700_000_000),
            playbackRate: playbackState == .playing ? 1 : 0,
            capabilities: capabilities
        )
    }
}

@MainActor
private final class ControllerFakeMediaProvider: MediaProvider {
    var eventHandler: (@MainActor @Sendable (MediaProviderEvent) -> Void)? {
        didSet {
            if let eventHandler {
                installedHandlers.append(eventHandler)
            }
        }
    }

    var installedHandlers: [@MainActor @Sendable (MediaProviderEvent) -> Void] = []
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
