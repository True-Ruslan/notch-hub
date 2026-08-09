import Foundation
import Testing
@testable import NotchHubMediaCore

@MainActor
struct ProductionMediaTransportCandidateTeardownTests {
    @Test
    func observationReportsUncleanTeardownWhenOwnedProcessCannotBeConfirmedStopped() async throws {
        let processClient = UncleanCandidateProcessClient()
        let runner = ProductionMediaTransportCandidateRunner(
            sourceCommit: String(repeating: "a", count: 40),
            processClient: processClient,
            wait: { _ in }
        )

        let report = try await runner.observe(seconds: 1)

        #expect(!report.cleanTeardown)
    }
}

@MainActor
private final class UncleanCandidateProcessClient: MediaRemoteProcessClientProtocol {
    var onPayload: (@MainActor @Sendable (MediaRemoteWirePayload?) -> Void)?
    var onFailure: (@MainActor @Sendable (MediaRemoteProcessFailure) -> Void)?
    var lastTeardownClean = false

    func startObservation() throws {}

    func stop() {}

    func send(_: MediaCommand) async -> MediaCommandResult {
        .failed
    }

    func capabilities() async throws -> MediaCommandCapabilities {
        MediaCommandCapabilities(previous: .unknown, next: .unknown, seek: .unknown)
    }
}
