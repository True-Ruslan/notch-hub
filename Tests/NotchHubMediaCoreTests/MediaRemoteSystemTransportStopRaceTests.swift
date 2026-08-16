import Foundation
import Testing
@testable import NotchHubMediaCore

@MainActor
struct MediaRemoteSystemTransportStopRaceTests {
    @Test
    func stopBeforeQueuedCapabilityTaskStartsPreventsLateOneShotLaunch() async {
        let client = DeferredCapabilityProcessClient()
        let transport = MediaRemoteSystemTransport(processClient: client)

        transport.start()
        client.emitPayload(
            MediaRemoteWirePayload(
                bundleIdentifier: "player",
                playing: true,
                title: "Track",
                artist: "Artist",
                album: "Album",
                durationSeconds: 180,
                positionSeconds: 42,
                referenceDate: Date(timeIntervalSince1970: 1_786_233_600),
                playbackRate: 1,
                artworkData: nil,
                contentIdentifier: "track",
                uniqueIdentifier: "track-1"
            )
        )

        // receive(_:) has queued capability acquisition, but the task has not had
        // an opportunity to run yet. Stopping now must invalidate that queued work
        // before it can launch a new one-shot process outside the teardown snapshot.
        transport.stopNonBlocking()
        await Task.yield()
        await Task.yield()

        #expect(client.nonBlockingStopCount == 1)
        #expect(client.capabilityRequestCount == 0)
    }
}

@MainActor
private final class DeferredCapabilityProcessClient: MediaRemoteProcessClientProtocol {
    var onPayload: (@MainActor @Sendable (MediaRemoteWirePayload?) -> Void)?
    var onFailure: (@MainActor @Sendable (MediaRemoteProcessFailure) -> Void)?

    private(set) var nonBlockingStopCount = 0
    private(set) var capabilityRequestCount = 0

    func startObservation() throws {}

    func stop() {}

    func stopNonBlocking() {
        nonBlockingStopCount += 1
    }

    func send(_ command: MediaCommand) async -> MediaCommandResult {
        .failed
    }

    func capabilities() async throws -> MediaCommandCapabilities {
        capabilityRequestCount += 1
        return MediaCommandCapabilities(
            previous: .supported,
            next: .supported,
            seek: .supported
        )
    }

    func emitPayload(_ payload: MediaRemoteWirePayload?) {
        onPayload?(payload)
    }
}
