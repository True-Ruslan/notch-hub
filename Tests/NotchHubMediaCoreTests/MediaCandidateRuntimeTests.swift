import Foundation
import Testing
@testable import NotchHubMediaCore

@MainActor
struct MediaCandidateRuntimeTests {
    @Test
    func observationPublishesOnlyPrivacySafeCandidateSnapshot() {
        let client = CandidateRuntimeFakeProcessClient(
            initialPayload: MediaRemoteWirePayload(
                bundleIdentifier: "source.private",
                playing: true,
                title: "Private Track",
                artist: "Private Artist",
                album: "Private Album",
                durationSeconds: 180,
                positionSeconds: 42,
                referenceDate: Date(timeIntervalSince1970: 1_786_233_600),
                playbackRate: 1,
                artworkData: Data([1, 2, 3]),
                contentIdentifier: "secret-content-id",
                uniqueIdentifier: "secret-unique-id"
            )
        )
        let runtime = MediaCandidateRuntime(processClient: client)
        let changes = CandidateRuntimeChangeCounter()
        runtime.changeHandler = {
            changes.value += 1
        }

        runtime.startObservation()

        #expect(runtime.state == .playing)
        #expect(
            runtime.snapshot
                == MediaCandidateSnapshot(
                    sourceBundleIdentifier: "source.private",
                    hasArtwork: true,
                    isPlaying: true,
                    capabilities: MediaCandidateCapabilities(
                        previous: .unknown,
                        next: .unknown,
                        seek: .unknown
                    )
                )
        )
        #expect(changes.value >= 1)

        runtime.stopObservation()
        #expect(runtime.state == .unavailable)
        #expect(runtime.snapshot == nil)
        #expect(client.stopCount == 1)
    }

    @Test
    func capabilitiesNormalizeTriStateWithoutExposingProcessTypes() async throws {
        let client = CandidateRuntimeFakeProcessClient(
            capabilities: MediaCommandCapabilities(
                previous: .unsupported,
                next: .supported,
                seek: .unknown
            )
        )
        let runtime = MediaCandidateRuntime(processClient: client)

        let capabilities = try await runtime.capabilities()

        #expect(
            capabilities
                == MediaCandidateCapabilities(
                    previous: .unsupported,
                    next: .supported,
                    seek: .unknown
                )
        )
    }

    @Test
    func sendMapsOnlyTypedCandidateCommandAndStopsTransport() async {
        let client = CandidateRuntimeFakeProcessClient(commandResult: .sent)
        let runtime = MediaCandidateRuntime(processClient: client)

        let sent = await runtime.send(.seek(seconds: 42))

        #expect(sent)
        #expect(client.sentCommands == [.seek(seconds: 42)])
        #expect(client.startCount == 1)
        #expect(client.stopCount == 1)
    }

    @Test
    func capabilitiesMapOperationalFailureToCandidateError() async {
        let client = CandidateRuntimeFakeProcessClient(capabilitiesError: .timedOut)
        let runtime = MediaCandidateRuntime(processClient: client)

        await #expect(throws: MediaCandidateRuntimeError.timedOut) {
            try await runtime.capabilities()
        }
    }

    @Test
    func teardownStateComesOnlyFromOwnedProcessClient() {
        let client = CandidateRuntimeFakeProcessClient(lastTeardownClean: false)
        let runtime = MediaCandidateRuntime(processClient: client)

        #expect(!runtime.lastTeardownClean)
    }
}

@MainActor
private final class CandidateRuntimeChangeCounter {
    var value = 0
}

@MainActor
private final class CandidateRuntimeFakeProcessClient: MediaRemoteProcessClientProtocol {
    var onPayload: (@MainActor @Sendable (MediaRemoteWirePayload?) -> Void)?
    var onFailure: (@MainActor @Sendable (MediaRemoteProcessFailure) -> Void)?
    var lastTeardownClean: Bool

    private let initialPayload: MediaRemoteWirePayload?
    private let capabilityResult: MediaCommandCapabilities
    private let capabilitiesError: MediaRemoteProcessClientError?
    private let commandResult: MediaCommandResult

    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var sentCommands: [MediaCommand] = []

    init(
        initialPayload: MediaRemoteWirePayload? = nil,
        capabilities: MediaCommandCapabilities = MediaCommandCapabilities(
            previous: .unknown,
            next: .unknown,
            seek: .unknown
        ),
        capabilitiesError: MediaRemoteProcessClientError? = nil,
        commandResult: MediaCommandResult = .failed,
        lastTeardownClean: Bool = true
    ) {
        self.initialPayload = initialPayload
        capabilityResult = capabilities
        self.capabilitiesError = capabilitiesError
        self.commandResult = commandResult
        self.lastTeardownClean = lastTeardownClean
    }

    func startObservation() throws {
        startCount += 1
        if let initialPayload {
            onPayload?(initialPayload)
        }
    }

    func stop() {
        stopCount += 1
    }

    func send(_ command: MediaCommand) async -> MediaCommandResult {
        sentCommands.append(command)
        return commandResult
    }

    func capabilities() async throws -> MediaCommandCapabilities {
        if let capabilitiesError {
            throw capabilitiesError
        }
        return capabilityResult
    }
}
