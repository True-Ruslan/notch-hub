enum SystemMediaTransportEvent: Sendable {
    case ready
    case session(MediaSessionSnapshot)
    case noSession(MediaSequence)
    case failed(MediaProviderFailure)
    case stopped
}

@MainActor
protocol SystemMediaTransport: AnyObject {
    var eventHandler: (@MainActor @Sendable (SystemMediaTransportEvent) -> Void)? { get set }

    func start()
    func stop()
    func send(_ command: MediaCommand) async -> MediaCommandResult
}

@MainActor
final class SystemMediaBridge: MediaProvider {
    private let transport: any SystemMediaTransport

    var eventHandler: (@MainActor @Sendable (MediaProviderEvent) -> Void)?

    private var isStarted = false
    private var handlerGeneration: UInt64 = 0

    init(transport: any SystemMediaTransport) {
        self.transport = transport
    }

    func start() {
        guard !isStarted else {
            return
        }

        isStarted = true
        handlerGeneration &+= 1
        let generation = handlerGeneration

        transport.eventHandler = { [weak self] event in
            guard let self else {
                return
            }
            guard self.isStarted, generation == self.handlerGeneration else {
                return
            }
            self.forward(event)
        }
        transport.start()
    }

    func stop() {
        guard isStarted else {
            return
        }

        isStarted = false
        handlerGeneration &+= 1
        transport.eventHandler = nil
        transport.stop()
    }

    func send(_ command: MediaCommand) async -> MediaCommandResult {
        guard isStarted else {
            return .failed
        }
        return await transport.send(command)
    }

    private func forward(_ event: SystemMediaTransportEvent) {
        switch event {
        case .ready:
            eventHandler?(.ready)
        case .session(let snapshot):
            eventHandler?(.session(snapshot))
        case .noSession(let sequence):
            eventHandler?(.noSession(sequence))
        case .failed(let failure):
            eventHandler?(.failed(failure))
        case .stopped:
            eventHandler?(.stopped)
        }
    }
}
