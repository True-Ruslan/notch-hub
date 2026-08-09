@MainActor
protocol MediaRemoteProcessClientProtocol: AnyObject {
    var onPayload: (@MainActor @Sendable (MediaRemoteWirePayload?) -> Void)? { get set }
    var onFailure: (@MainActor @Sendable (MediaRemoteProcessFailure) -> Void)? { get set }

    func startObservation() throws
    func stop()
    func send(_ command: MediaCommand) async -> MediaCommandResult
    func capabilities() async throws -> MediaCommandCapabilities
}

extension MediaRemoteProcessClient: MediaRemoteProcessClientProtocol {}
