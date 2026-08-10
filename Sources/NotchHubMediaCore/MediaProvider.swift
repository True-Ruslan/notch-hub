enum MediaProviderFailure: Sendable, Equatable {
    case transport
    case protocolViolation
}

enum MediaCommandResult: Sendable, Equatable {
    case sent
    case failed
}

enum MediaProviderEvent: Sendable {
    case ready
    case session(MediaSessionSnapshot)
    case noSession(MediaSequence)
    case failed(MediaProviderFailure)
    case stopped
}

@MainActor
protocol MediaProvider: AnyObject {
    var eventHandler: (@MainActor @Sendable (MediaProviderEvent) -> Void)? { get set }

    func start()
    func stop()
    func send(_ command: MediaCommand) async -> MediaCommandResult
}
