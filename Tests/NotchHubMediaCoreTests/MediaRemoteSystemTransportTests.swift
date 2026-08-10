import Foundation
import Testing
@testable import NotchHubMediaCore

@MainActor
struct MediaRemoteSystemTransportTests {
    @Test
    func startIsIdempotentAndPublishesReadyAfterObservationStarts() {
        let client = FakeProductionMediaProcessClient()
        let transport = MediaRemoteSystemTransport(processClient: client)
        var events: [SystemMediaTransportEvent] = []
        transport.eventHandler = { events.append($0) }

        transport.start()
        transport.start()

        #expect(client.startCount == 1)
        #expect(events.count == 1)
        guard case .ready = events[0] else {
            Issue.record("Expected ready event")
            return
        }
    }

    @Test
    func launchFailureFailsClosedWithoutReady() {
        let client = FakeProductionMediaProcessClient(startError: MediaRemoteProcessClientError.timedOut)
        let transport = MediaRemoteSystemTransport(processClient: client)
        var events: [SystemMediaTransportEvent] = []
        transport.eventHandler = { events.append($0) }

        transport.start()

        #expect(events.count == 1)
        guard case .failed(.transport) = events[0] else {
            Issue.record("Expected transport failure")
            return
        }
    }

    @Test
    func activePayloadPublishesNormalizedUnknownCapabilitySnapshot() async {
        let client = FakeProductionMediaProcessClient()
        let transport = MediaRemoteSystemTransport(processClient: client)
        var events: [SystemMediaTransportEvent] = []
        transport.eventHandler = { events.append($0) }
        transport.start()
        events.removeAll()

        client.emitPayload(
            makePayload(
                source: "ru.yandex.desktop.music",
                playing: true,
                title: "Track A",
                artwork: Data([1, 2, 3]),
                contentIdentifier: "track-a"
            ))

        let snapshot = try? #require(sessionSnapshots(events).last)
        #expect(snapshot?.sequence == MediaSequence(generation: 1, revision: 1))
        #expect(snapshot?.source.bundleIdentifier == "ru.yandex.desktop.music")
        #expect(snapshot?.source.displayName == nil)
        #expect(snapshot?.title == "Track A")
        #expect(snapshot?.artworkData == Data([1, 2, 3]))
        #expect(snapshot?.playbackState == .playing)
        #expect(snapshot?.capabilities == unknownCapabilities)

        await waitForCapabilityRequests(client, count: 1)
    }

    @Test
    func sameMediaStateUpdateAdvancesRevisionWithoutCapabilityRefresh() async {
        let client = FakeProductionMediaProcessClient()
        let transport = MediaRemoteSystemTransport(processClient: client)
        var events: [SystemMediaTransportEvent] = []
        transport.eventHandler = { events.append($0) }
        transport.start()
        events.removeAll()

        client.emitPayload(makePayload(source: "player", playing: true, title: "A", contentIdentifier: "a"))
        await waitForCapabilityRequests(client, count: 1)
        client.completeCapabilityRequest(at: 0, with: supportedCapabilities)
        await Task.yield()
        events.removeAll()

        client.emitPayload(makePayload(source: "player", playing: false, title: "A", contentIdentifier: "a"))

        let snapshots = sessionSnapshots(events)
        #expect(snapshots.count == 1)
        #expect(snapshots[0].sequence == MediaSequence(generation: 1, revision: 3))
        #expect(snapshots[0].playbackState == .paused)
        #expect(snapshots[0].capabilities == supportedCapabilities)
        #expect(client.capabilityRequestCount == 1)
    }

    @Test
    func matchingCapabilityCompletionPublishesNewerSnapshot() async {
        let client = FakeProductionMediaProcessClient()
        let transport = MediaRemoteSystemTransport(processClient: client)
        var events: [SystemMediaTransportEvent] = []
        transport.eventHandler = { events.append($0) }
        transport.start()
        events.removeAll()

        client.emitPayload(makePayload(source: "player", playing: true, title: "A", contentIdentifier: "a"))
        await waitForCapabilityRequests(client, count: 1)
        client.completeCapabilityRequest(at: 0, with: supportedCapabilities)
        await Task.yield()

        let snapshots = sessionSnapshots(events)
        #expect(snapshots.count == 2)
        #expect(snapshots[0].sequence == MediaSequence(generation: 1, revision: 1))
        #expect(snapshots[0].capabilities == unknownCapabilities)
        #expect(snapshots[1].sequence == MediaSequence(generation: 1, revision: 2))
        #expect(snapshots[1].capabilities == supportedCapabilities)
    }

    @Test
    func sourceSwitchClearsArtworkAndNeverReusesPriorMetadata() async {
        let client = FakeProductionMediaProcessClient()
        let transport = MediaRemoteSystemTransport(processClient: client)
        var events: [SystemMediaTransportEvent] = []
        transport.eventHandler = { events.append($0) }
        transport.start()
        events.removeAll()

        client.emitPayload(
            makePayload(
                source: "source.a",
                playing: true,
                title: "Track A",
                artist: "Artist A",
                artwork: Data([9, 9]),
                contentIdentifier: "a"
            ))
        await waitForCapabilityRequests(client, count: 1)
        events.removeAll()

        client.emitPayload(
            makePayload(
                source: "source.b",
                playing: true,
                title: "Track B",
                artist: nil,
                artwork: nil,
                contentIdentifier: "b"
            ))

        let snapshot = try? #require(sessionSnapshots(events).last)
        #expect(snapshot?.sequence == MediaSequence(generation: 2, revision: 1))
        #expect(snapshot?.source.bundleIdentifier == "source.b")
        #expect(snapshot?.title == "Track B")
        #expect(snapshot?.artist == nil)
        #expect(snapshot?.artworkData == nil)
        #expect(snapshot?.capabilities == unknownCapabilities)
        await waitForCapabilityRequests(client, count: 2)
    }

    @Test
    func staleCapabilityCompletionAfterRapidSourceSwitchIsIgnored() async {
        let client = FakeProductionMediaProcessClient()
        let transport = MediaRemoteSystemTransport(processClient: client)
        var events: [SystemMediaTransportEvent] = []
        transport.eventHandler = { events.append($0) }
        transport.start()
        events.removeAll()

        client.emitPayload(makePayload(source: "source.a", playing: true, title: "A", contentIdentifier: "a"))
        await waitForCapabilityRequests(client, count: 1)
        client.emitPayload(makePayload(source: "source.b", playing: true, title: "B", contentIdentifier: "b"))
        await waitForCapabilityRequests(client, count: 2)
        events.removeAll()

        client.completeCapabilityRequest(at: 0, with: supportedCapabilities)
        await Task.yield()
        #expect(events.isEmpty)

        let bCapabilities = MediaCommandCapabilities(
            previous: .unsupported,
            next: .supported,
            seek: .unknown
        )
        client.completeCapabilityRequest(at: 1, with: bCapabilities)
        await Task.yield()

        let snapshots = sessionSnapshots(events)
        #expect(snapshots.count == 1)
        #expect(snapshots[0].source.bundleIdentifier == "source.b")
        #expect(snapshots[0].sequence == MediaSequence(generation: 2, revision: 2))
        #expect(snapshots[0].capabilities == bCapabilities)
    }

    @Test
    func capabilityFailureKeepsMetadataStreamAliveWithUnknownCapabilities() async {
        let client = FakeProductionMediaProcessClient()
        let transport = MediaRemoteSystemTransport(processClient: client)
        var events: [SystemMediaTransportEvent] = []
        transport.eventHandler = { events.append($0) }
        transport.start()
        events.removeAll()

        client.emitPayload(makePayload(source: "player", playing: true, title: "A", contentIdentifier: "a"))
        await waitForCapabilityRequests(client, count: 1)
        client.failCapabilityRequest(at: 0)
        await Task.yield()

        #expect(sessionSnapshots(events).count == 1)
        #expect(failureEvents(events).isEmpty)
        #expect(sessionSnapshots(events)[0].capabilities == unknownCapabilities)
    }

    @Test
    func noSessionEmitsStrictlyNewerSequenceAndInvalidatesCapabilities() async {
        let client = FakeProductionMediaProcessClient()
        let transport = MediaRemoteSystemTransport(processClient: client)
        var events: [SystemMediaTransportEvent] = []
        transport.eventHandler = { events.append($0) }
        transport.start()
        events.removeAll()

        client.emitPayload(makePayload(source: "player", playing: true, title: "A", contentIdentifier: "a"))
        await waitForCapabilityRequests(client, count: 1)
        events.removeAll()

        client.emitPayload(nil)

        #expect(events.count == 1)
        guard case .noSession(let sequence) = events[0] else {
            Issue.record("Expected no-session event")
            return
        }
        #expect(sequence == MediaSequence(generation: 2, revision: 1))

        client.completeCapabilityRequest(at: 0, with: supportedCapabilities)
        await Task.yield()
        #expect(events.count == 1)
    }

    @Test
    func processFailuresMapToTypedTransportFailures() {
        let client = FakeProductionMediaProcessClient()
        let transport = MediaRemoteSystemTransport(processClient: client)
        var events: [SystemMediaTransportEvent] = []
        transport.eventHandler = { events.append($0) }
        transport.start()
        events.removeAll()

        client.emitFailure(.protocolViolation)
        client.emitFailure(.transport)

        #expect(failureEvents(events) == [.protocolViolation, .transport])
    }

    @Test
    func stopClearsClientCallbacksBeforeTeardownAndRejectsStaleCallbacks() {
        let client = FakeProductionMediaProcessClient()
        let transport = MediaRemoteSystemTransport(processClient: client)
        var events: [SystemMediaTransportEvent] = []
        transport.eventHandler = { events.append($0) }
        transport.start()
        events.removeAll()
        let stalePayloadHandler = client.onPayload

        transport.stop()
        transport.stop()

        #expect(client.stopCount == 1)
        #expect(client.handlersWereNilWhenStopped)
        #expect(events.count == 1)
        guard case .stopped = events[0] else {
            Issue.record("Expected stopped event")
            return
        }

        stalePayloadHandler?(makePayload(source: "stale", playing: true, title: "Stale"))
        #expect(events.count == 1)
    }

    @Test
    func typedCommandsForwardWithoutPlayerSpecificFallback() async {
        let client = FakeProductionMediaProcessClient(commandResult: .sent)
        let transport = MediaRemoteSystemTransport(processClient: client)
        transport.start()

        #expect(await transport.send(.togglePlayPause) == .sent)
        #expect(await transport.send(.previous) == .sent)
        #expect(await transport.send(.next) == .sent)
        #expect(await transport.send(.seek(seconds: 42)) == .sent)
        #expect(
            client.sentCommands == [
                .togglePlayPause,
                .previous,
                .next,
                .seek(seconds: 42)
            ])
    }

    private var unknownCapabilities: MediaCommandCapabilities {
        MediaCommandCapabilities(previous: .unknown, next: .unknown, seek: .unknown)
    }

    private var supportedCapabilities: MediaCommandCapabilities {
        MediaCommandCapabilities(previous: .supported, next: .supported, seek: .supported)
    }

    private func makePayload(
        source: String,
        playing: Bool,
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        artwork: Data? = nil,
        contentIdentifier: String? = nil,
        uniqueIdentifier: String? = nil
    ) -> MediaRemoteWirePayload {
        MediaRemoteWirePayload(
            bundleIdentifier: source,
            playing: playing,
            title: title,
            artist: artist,
            album: album,
            durationSeconds: 180,
            positionSeconds: 42,
            referenceDate: Date(timeIntervalSince1970: 1_786_233_600),
            playbackRate: playing ? 1 : 0,
            artworkData: artwork,
            contentIdentifier: contentIdentifier,
            uniqueIdentifier: uniqueIdentifier
        )
    }

    private func sessionSnapshots(_ events: [SystemMediaTransportEvent]) -> [MediaSessionSnapshot] {
        events.compactMap { event in
            guard case .session(let snapshot) = event else {
                return nil
            }
            return snapshot
        }
    }

    private func failureEvents(_ events: [SystemMediaTransportEvent]) -> [MediaProviderFailure] {
        events.compactMap { event in
            guard case .failed(let failure) = event else {
                return nil
            }
            return failure
        }
    }

    private func waitForCapabilityRequests(
        _ client: FakeProductionMediaProcessClient,
        count: Int
    ) async {
        for _ in 0..<100 {
            if client.capabilityRequestCount >= count {
                return
            }
            await Task.yield()
        }
        Issue.record("Timed out waiting for capability request count \(count)")
    }
}

@MainActor
private final class FakeProductionMediaProcessClient: MediaRemoteProcessClientProtocol {
    var onPayload: (@MainActor @Sendable (MediaRemoteWirePayload?) -> Void)?
    var onFailure: (@MainActor @Sendable (MediaRemoteProcessFailure) -> Void)?

    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var capabilityRequestCount = 0
    private(set) var sentCommands: [MediaCommand] = []
    private(set) var handlersWereNilWhenStopped = false

    private let startError: Error?
    private let commandResult: MediaCommandResult
    private var capabilityContinuations: [CheckedContinuation<MediaCommandCapabilities, Error>?] = []

    init(
        startError: Error? = nil,
        commandResult: MediaCommandResult = .failed
    ) {
        self.startError = startError
        self.commandResult = commandResult
    }

    func startObservation() throws {
        startCount += 1
        if let startError {
            throw startError
        }
    }

    func stop() {
        stopCount += 1
        handlersWereNilWhenStopped = onPayload == nil && onFailure == nil
    }

    func send(_ command: MediaCommand) async -> MediaCommandResult {
        sentCommands.append(command)
        return commandResult
    }

    func capabilities() async throws -> MediaCommandCapabilities {
        capabilityRequestCount += 1
        return try await withCheckedThrowingContinuation { continuation in
            capabilityContinuations.append(continuation)
        }
    }

    func emitPayload(_ payload: MediaRemoteWirePayload?) {
        onPayload?(payload)
    }

    func emitFailure(_ failure: MediaRemoteProcessFailure) {
        onFailure?(failure)
    }

    func completeCapabilityRequest(
        at index: Int,
        with capabilities: MediaCommandCapabilities
    ) {
        guard capabilityContinuations.indices.contains(index),
            let continuation = capabilityContinuations[index]
        else {
            Issue.record("Missing capability continuation at index \(index)")
            return
        }
        capabilityContinuations[index] = nil
        continuation.resume(returning: capabilities)
    }

    func failCapabilityRequest(at index: Int) {
        guard capabilityContinuations.indices.contains(index),
            let continuation = capabilityContinuations[index]
        else {
            Issue.record("Missing capability continuation at index \(index)")
            return
        }
        capabilityContinuations[index] = nil
        continuation.resume(throwing: MediaRemoteProcessClientError.timedOut)
    }
}
