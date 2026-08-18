import Foundation
import Testing
@testable import NotchHubMediaCore

@MainActor
struct ShippingMediaPeekProbeTransportIntegrationTests {
    @Test
    func firstUsableSnapshotFinishesPeekBeforeCapabilitiesLaunch() async {
        let client = PeekMetadataProcessClient()
        let transport = MediaRemoteSystemTransport(processClient: client)
        let scheduler = PeekMetadataTimeoutScheduler()
        let probe = ShippingMediaPeekProbe(
            makeTransport: { transport },
            scheduleTimeout: { delay, action in
                scheduler.schedule(after: delay, action: action)
            },
            timeoutSeconds: 1.0
        )
        var results: [ShippingMediaPeekProbe.Result] = []

        probe.acquire { results.append($0) }
        await Task.yield()
        await Task.yield()

        #expect(results.count == 1)
        #expect(results.first?.presentation?.title == "Track")
        #expect(client.nonBlockingStopCount == 1)
        #expect(client.capabilityRequestCount == 0)
        #expect(scheduler.pendingCount == 0)
    }
}

private extension ShippingMediaPeekProbe.Result {
    var presentation: ShippingMediaPresentation? {
        if case .presentation(let presentation) = self {
            return presentation
        }
        return nil
    }
}

@MainActor
private final class PeekMetadataProcessClient: MediaRemoteProcessClientProtocol {
    var onPayload: (@MainActor @Sendable (MediaRemoteWirePayload?) -> Void)?
    var onFailure: (@MainActor @Sendable (MediaRemoteProcessFailure) -> Void)?

    private(set) var nonBlockingStopCount = 0
    private(set) var capabilityRequestCount = 0

    func startObservation() throws {
        onPayload?(
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
    }

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
}

@MainActor
private final class PeekMetadataTimeoutScheduler {
    private final class Token {
        var isCancelled = false
    }

    private var tokens: [Token] = []

    var pendingCount: Int {
        tokens.count(where: { !$0.isCancelled })
    }

    func schedule(
        after _: TimeInterval,
        action _: @escaping @MainActor () -> Void
    ) -> @MainActor () -> Void {
        let token = Token()
        tokens.append(token)
        return { token.isCancelled = true }
    }
}
