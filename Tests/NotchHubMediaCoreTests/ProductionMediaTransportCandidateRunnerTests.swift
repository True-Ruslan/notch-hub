import NotchHubMediaCore
import Testing
@testable import NotchHubMediaCandidateCore

@MainActor
struct ProductionMediaTransportCandidateRunnerTests {
    @Test
    func observeUsesProductionStateStackAndStopsCleanly() async throws {
        let runtime = CandidateRunnerFakeRuntime(
            initialSnapshot: MediaCandidateSnapshot(
                sourceBundleIdentifier: "source.a",
                hasArtwork: true,
                isPlaying: true,
                capabilities: supportedCapabilities
            ),
            capabilities: supportedCapabilities
        )
        let runner = ProductionMediaTransportCandidateRunner(
            sourceCommit: String(repeating: "c", count: 40),
            runtime: runtime,
            wait: { _ in }
        )

        let report = try await runner.observe(seconds: 1)

        #expect(report.observedSession)
        #expect(report.observedArtwork)
        #expect(report.sourceBundleIdentifier == "source.a")
        #expect(report.capabilities.previous == .supported)
        #expect(report.capabilities.next == .supported)
        #expect(report.capabilities.seek == .supported)
        #expect(report.cleanTeardown)
        #expect(runtime.startCount == 1)
        #expect(runtime.stopCount == 1)
        #expect(runtime.handlerWasNilWhenStopped)
    }

    @Test
    func invalidObservationDurationFailsBeforeStartingTransport() async {
        let runtime = CandidateRunnerFakeRuntime()
        let runner = ProductionMediaTransportCandidateRunner(
            sourceCommit: String(repeating: "d", count: 40),
            runtime: runtime,
            wait: { _ in }
        )

        await #expect(throws: ProductionMediaTransportCandidateError.invalidObservationDuration) {
            try await runner.observe(seconds: 0)
        }
        await #expect(throws: ProductionMediaTransportCandidateError.invalidObservationDuration) {
            try await runner.observe(seconds: 1_201)
        }
        #expect(runtime.startCount == 0)
    }

    @Test
    func capabilitiesUseProductionRuntimeAndNormalizeTriState() async throws {
        let runtime = CandidateRunnerFakeRuntime(
            capabilities: MediaCandidateCapabilities(
                previous: .unsupported,
                next: .supported,
                seek: .unknown
            )
        )
        let runner = ProductionMediaTransportCandidateRunner(
            sourceCommit: String(repeating: "f", count: 40),
            runtime: runtime,
            wait: { _ in }
        )

        let capabilities = try await runner.capabilities()

        #expect(capabilities.previous == .unsupported)
        #expect(capabilities.next == .supported)
        #expect(capabilities.seek == .unknown)
        #expect(runtime.capabilitiesCount == 1)
        #expect(runtime.startCount == 0)
        #expect(runtime.stopCount == 0)
    }

    @Test
    func sendUsesTypedProductionTransportAndAlwaysStops() async {
        let runtime = CandidateRunnerFakeRuntime(commandResult: true)
        let runner = ProductionMediaTransportCandidateRunner(
            sourceCommit: String(repeating: "e", count: 40),
            runtime: runtime,
            wait: { _ in }
        )

        let sent = await runner.send(.seek(seconds: 42))

        #expect(sent)
        #expect(runtime.sentCommands == [.seek(seconds: 42)])
    }

    private var supportedCapabilities: MediaCandidateCapabilities {
        MediaCandidateCapabilities(previous: .supported, next: .supported, seek: .supported)
    }
}

@MainActor
private final class CandidateRunnerFakeRuntime: MediaCandidateRuntimeProtocol {
    var state: MediaCandidateSubsystemState = .idle
    var snapshot: MediaCandidateSnapshot?
    var changeHandler: (@MainActor @Sendable () -> Void)?
    var lastTeardownClean = true

    private let initialSnapshot: MediaCandidateSnapshot?
    private let capabilityResult: MediaCandidateCapabilities
    private let commandResult: Bool

    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var capabilitiesCount = 0
    private(set) var sentCommands: [MediaCandidateCommand] = []
    private(set) var handlerWasNilWhenStopped = false

    init(
        initialSnapshot: MediaCandidateSnapshot? = nil,
        capabilities: MediaCandidateCapabilities = MediaCandidateCapabilities(
            previous: .unknown,
            next: .unknown,
            seek: .unknown
        ),
        commandResult: Bool = false
    ) {
        self.initialSnapshot = initialSnapshot
        capabilityResult = capabilities
        self.commandResult = commandResult
    }

    func startObservation() {
        startCount += 1
        snapshot = initialSnapshot
        if let snapshot {
            state = snapshot.isPlaying ? .playing : .paused
        } else {
            state = .idle
        }
        changeHandler?()
    }

    func stopObservation() {
        stopCount += 1
        handlerWasNilWhenStopped = changeHandler == nil
        state = .unavailable
        snapshot = nil
    }

    func capabilities() async throws -> MediaCandidateCapabilities {
        capabilitiesCount += 1
        return capabilityResult
    }

    func send(_ command: MediaCandidateCommand) async -> Bool {
        sentCommands.append(command)
        return commandResult
    }
}
