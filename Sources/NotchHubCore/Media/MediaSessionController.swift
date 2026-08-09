@MainActor
final class MediaSessionController {
    private let provider: any MediaProvider

    private(set) var state: MediaSubsystemState = .unavailable
    private(set) var snapshot: MediaSessionSnapshot?
    var changeHandler: (@MainActor @Sendable () -> Void)?

    private var latestSequence: MediaSequence?
    private var isStarted = false
    private var isTerminal = false
    private var restartUsed = false
    private var handlerGeneration: UInt64 = 0

    init(provider: any MediaProvider) {
        self.provider = provider
    }

    func start() {
        guard !isStarted, !isTerminal else {
            return
        }

        isStarted = true
        installHandlerAndStartProvider()
    }

    func stop() {
        guard !isTerminal else {
            return
        }

        isTerminal = true
        latestSequence = nil
        invalidateProviderHandler()

        if isStarted {
            provider.stop()
        }
        isStarted = false
        publish(state: .unavailable, snapshot: nil)
    }

    func send(_ command: MediaCommand) async -> MediaCommandResult {
        guard isStarted, !isTerminal, let snapshot else {
            return .failed
        }

        switch command {
        case .togglePlayPause:
            break
        case .previous:
            guard snapshot.capabilities.previous == .supported else {
                return .failed
            }
        case .next:
            guard snapshot.capabilities.next == .supported else {
                return .failed
            }
        case .seek(let seconds):
            guard
                snapshot.capabilities.seek == .supported,
                seconds.isFinite,
                seconds >= 0
            else {
                return .failed
            }
        }

        return await provider.send(command)
    }

    private func installHandlerAndStartProvider() {
        handlerGeneration &+= 1
        let generation = handlerGeneration

        provider.eventHandler = { [weak self] event in
            guard let self else {
                return
            }
            guard
                generation == self.handlerGeneration,
                self.isStarted,
                !self.isTerminal
            else {
                return
            }
            self.receive(event)
        }
        provider.start()
    }

    private func invalidateProviderHandler() {
        handlerGeneration &+= 1
        provider.eventHandler = nil
    }

    private func receive(_ event: MediaProviderEvent) {
        switch event {
        case .ready:
            if snapshot == nil {
                publish(state: .idle, snapshot: nil)
            }

        case .session(let newSnapshot):
            guard accepts(sequence: newSnapshot.sequence) else {
                return
            }
            latestSequence = newSnapshot.sequence
            let nextState: MediaSubsystemState =
                newSnapshot.playbackState == .playing ? .playing : .paused
            publish(state: nextState, snapshot: newSnapshot)

        case .noSession(let sequence):
            guard accepts(sequence: sequence) else {
                return
            }
            latestSequence = sequence
            publish(state: .idle, snapshot: nil)

        case .failed, .stopped:
            handleUnexpectedFailure()
        }
    }

    private func accepts(sequence: MediaSequence) -> Bool {
        guard let latestSequence else {
            return true
        }
        return sequence > latestSequence
    }

    private func handleUnexpectedFailure() {
        latestSequence = nil
        publish(state: .unavailable, snapshot: nil)

        invalidateProviderHandler()
        provider.stop()

        guard !restartUsed else {
            isStarted = false
            isTerminal = true
            return
        }

        restartUsed = true
        installHandlerAndStartProvider()
    }

    private func publish(
        state newState: MediaSubsystemState,
        snapshot newSnapshot: MediaSessionSnapshot?
    ) {
        guard state != newState || snapshot != newSnapshot else {
            return
        }

        state = newState
        snapshot = newSnapshot
        changeHandler?()
    }
}
