import NotchHubMediaCore
import Testing
@testable import NotchHubMediaCandidateCore

@MainActor
struct ProductionMediaTransportCandidateTeardownTests {
    @Test
    func observationReportsUncleanTeardownWhenOwnedProcessCannotBeConfirmedStopped() async throws {
        let runtime = UncleanCandidateRuntime()
        let runner = ProductionMediaTransportCandidateRunner(
            sourceCommit: String(repeating: "a", count: 40),
            runtime: runtime,
            wait: { _ in }
        )

        let report = try await runner.observe(seconds: 1)

        #expect(!report.cleanTeardown)
    }
}

@MainActor
private final class UncleanCandidateRuntime: MediaCandidateRuntimeProtocol {
    var state: MediaCandidateSubsystemState = .idle
    var snapshot: MediaCandidateSnapshot?
    var changeHandler: (@MainActor @Sendable () -> Void)?
    var lastTeardownClean = false

    func startObservation() {}

    func stopObservation() {}

    func capabilities() async throws -> MediaCandidateCapabilities {
        MediaCandidateCapabilities(previous: .unknown, next: .unknown, seek: .unknown)
    }

    func send(_: MediaCandidateCommand) async -> Bool {
        false
    }
}
