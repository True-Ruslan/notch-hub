import Foundation
import Testing
@testable import NotchHubMediaCore

@MainActor
struct ProductionMediaTransportCandidateRunnerTests {
    @Test
    func observeUsesProductionStateStackAndStopsCleanly() async throws {
        let client = CandidateRunnerFakeProcessClient(
            initialPayload: makePayload(source: "source.a", artwork: Data([1, 2, 3])),
            capabilities: supportedCapabilities
        )
        let runner = ProductionMediaTransportCandidateRunner(
            sourceCommit: String(repeating: "c", count: 40),
            processClient: client,
            wait: { _ in
                await Task.yield()
                await Task.yield()
                await Task.yield()
            }
        )

        let report = try await runner.observe(seconds: 1)

        #expect(report.observedSession)
        #expect(report.observedArtwork)
        #expect(report.sourceBundleIdentifier == "source.a")
        #expect(report.capabilities.previous == .supported)
        #expect(report.capabilities.next == .supported)
        #expect(report.capabilities.seek == .supported)
        #expect(report.cleanTeardown)
        #expect(client.startCount == 1)
        #expect(client.stopCount == 1)
        #expect(client.handlersWereNilWhenStopped)
    }

    @Test
    func invalidObservationDurationFailsBeforeStartingTransport() async {
        let client = CandidateRunnerFakeProcessClient()
        let runner = ProductionMediaTransportCandidateRunner(
            sourceCommit: String(repeating: "d", count: 40),
            processClient: client,
            wait: { _ in }
        )

        await #expect(throws: ProductionMediaTransportCandidateError.invalidObservationDuration) {
            try await runner.observe(seconds: 0)
        }
        await #expect(throws: ProductionMediaTransportCandidateError.invalidObservationDuration) {
            try await runner.observe(seconds: 1_201)
        }
        #expect(client.startCount == 0)
    }

    @Test
    func sendUsesTypedProductionTransportAndAlwaysStops() async {
        let client = CandidateRunnerFakeProcessClient(commandResult: .sent)
        let runner = ProductionMediaTransportCandidateRunner(
            sourceCommit: String(repeating: "e", count: 40),
            processClient: client,
            wait: { _ in }
        )

        let sent = await runner.send(.seek(seconds: 42))

        #expect(sent)
        #expect(client.sentCommands == [.seek(seconds: 42)])
        #expect(client.startCount == 1)
        #expect(client.stopCount == 1)
        #expect(client.handlersWereNilWhenStopped)
    }

    private var supportedCapabilities: MediaCommandCapabilities {
        MediaCommandCapabilities(previous: .supported, next: .supported, seek: .supported)
    }

    private func makePayload(source: String, artwork: Data? = nil) -> MediaRemoteWirePayload {
        MediaRemoteWirePayload(
            bundleIdentifier: source,
            playing: true,
            title: "Private Track",
            artist: "Private Artist",
            album: "Private Album",
            durationSeconds: 180,
            positionSeconds: 42,
            referenceDate: Date(timeIntervalSince1970: 1_786_233_600),
            playbackRate: 1,
            artworkData: artwork,
            contentIdentifier: "track-a",
            uniqueIdentifier: nil
        )
    }
}

@MainActor
private final class CandidateRunnerFakeProcessClient: MediaRemoteProcessClientProtocol {
    var onPayload: (@MainActor @Sendable (MediaRemoteWirePayload?) -> Void)?
    var onFailure: (@MainActor @Sendable (MediaRemoteProcessFailure) -> Void)?

    private let initialPayload: MediaRemoteWirePayload?
    private let capabilityResult: MediaCommandCapabilities
    private let commandResult: MediaCommandResult

    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var sentCommands: [MediaCommand] = []
    private(set) var handlersWereNilWhenStopped = false

    init(
        initialPayload: MediaRemoteWirePayload? = nil,
        capabilities: MediaCommandCapabilities = MediaCommandCapabilities(
            previous: .unknown,
            next: .unknown,
            seek: .unknown
        ),
        commandResult: MediaCommandResult = .failed
    ) {
        self.initialPayload = initialPayload
        capabilityResult = capabilities
        self.commandResult = commandResult
    }

    func startObservation() throws {
        startCount += 1
        if let initialPayload {
            onPayload?(initialPayload)
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
        capabilityResult
    }
}
