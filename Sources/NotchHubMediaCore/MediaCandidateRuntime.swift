import Foundation

package enum MediaCandidateLimits {
    package static let maximumSeekSeconds =
        Double(MediaRemoteWireDecoder.maximumDurationMicros) / 1_000_000
}

package enum MediaCandidateCapabilityState: Sendable, Equatable {
    case supported
    case unsupported
    case unknown
}

package struct MediaCandidateCapabilities: Sendable, Equatable {
    package let previous: MediaCandidateCapabilityState
    package let next: MediaCandidateCapabilityState
    package let seek: MediaCandidateCapabilityState

    package init(
        previous: MediaCandidateCapabilityState,
        next: MediaCandidateCapabilityState,
        seek: MediaCandidateCapabilityState
    ) {
        self.previous = previous
        self.next = next
        self.seek = seek
    }
}

package enum MediaCandidateSubsystemState: Sendable, Equatable {
    case unavailable
    case idle
    case paused
    case playing
}

package struct MediaCandidateSnapshot: Sendable, Equatable {
    package let sourceBundleIdentifier: String
    package let hasArtwork: Bool
    package let isPlaying: Bool
    package let capabilities: MediaCandidateCapabilities

    package init(
        sourceBundleIdentifier: String,
        hasArtwork: Bool,
        isPlaying: Bool,
        capabilities: MediaCandidateCapabilities
    ) {
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.hasArtwork = hasArtwork
        self.isPlaying = isPlaying
        self.capabilities = capabilities
    }
}

package enum MediaCandidateCommand: Sendable, Equatable {
    case toggle
    case previous
    case next
    case seek(seconds: Double)
}

package enum MediaCandidateRuntimeError: Error, Sendable, Equatable {
    case timedOut
    case teardownFailed
    case processFailed
    case outputUnavailable
    case outputTooLarge
    case capabilityProtocol
    case processLaunch
    case unexpected
}

@MainActor
package protocol MediaCandidateRuntimeProtocol: AnyObject {
    var state: MediaCandidateSubsystemState { get }
    var snapshot: MediaCandidateSnapshot? { get }
    var changeHandler: (@MainActor @Sendable () -> Void)? { get set }
    var lastTeardownClean: Bool { get }

    func startObservation()
    func stopObservation()
    func capabilities() async throws -> MediaCandidateCapabilities
    func send(_ command: MediaCandidateCommand) async -> Bool
}

@MainActor
package final class MediaCandidateRuntime: MediaCandidateRuntimeProtocol {
    private let processClient: any MediaRemoteProcessClientProtocol
    private let controller: MediaSessionController

    package var changeHandler: (@MainActor @Sendable () -> Void)?

    package convenience init(scriptURL: URL, frameworkURL: URL) {
        self.init(
            processClient: MediaRemoteProcessClient(
                scriptURL: scriptURL,
                frameworkURL: frameworkURL
            )
        )
    }

    init(processClient: any MediaRemoteProcessClientProtocol) {
        self.processClient = processClient
        let transport = MediaRemoteSystemTransport(processClient: processClient)
        let bridge = SystemMediaBridge(transport: transport)
        controller = MediaSessionController(provider: bridge)
    }

    package var state: MediaCandidateSubsystemState {
        MediaCandidateSubsystemState(controller.state)
    }

    package var snapshot: MediaCandidateSnapshot? {
        controller.snapshot.map(MediaCandidateSnapshot.init)
    }

    package var lastTeardownClean: Bool {
        processClient.lastTeardownClean
    }

    package func startObservation() {
        controller.changeHandler = { [weak self] in
            self?.changeHandler?()
        }
        controller.start()
    }

    package func stopObservation() {
        controller.changeHandler = nil
        controller.stop()
    }

    package func capabilities() async throws -> MediaCandidateCapabilities {
        do {
            return MediaCandidateCapabilities(try await processClient.capabilities())
        } catch {
            throw Self.normalize(error)
        }
    }

    package func send(_ command: MediaCandidateCommand) async -> Bool {
        let transport = MediaRemoteSystemTransport(processClient: processClient)
        transport.start()
        defer {
            transport.stop()
        }
        return await transport.send(command.mediaCommand) == .sent
    }

    private static func normalize(_ error: any Error) -> MediaCandidateRuntimeError {
        if let processError = error as? MediaRemoteProcessClientError {
            switch processError {
            case .timedOut:
                return .timedOut
            case .teardownFailed:
                return .teardownFailed
            case .operationFailed:
                return .processFailed
            case .standardOutputUnavailable:
                return .outputUnavailable
            case .standardOutputTooLarge:
                return .outputTooLarge
            }
        }

        if error is MediaRemoteCapabilityDecoderError {
            return .capabilityProtocol
        }

        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain {
            return .processLaunch
        }

        return .unexpected
    }
}

private extension MediaCandidateCapabilities {
    init(_ capabilities: MediaCommandCapabilities) {
        previous = MediaCandidateCapabilityState(capabilities.previous)
        next = MediaCandidateCapabilityState(capabilities.next)
        seek = MediaCandidateCapabilityState(capabilities.seek)
    }
}

private extension MediaCandidateCapabilityState {
    init(_ capability: MediaCapabilityState) {
        switch capability {
        case .supported:
            self = .supported
        case .unsupported:
            self = .unsupported
        case .unknown:
            self = .unknown
        }
    }
}

private extension MediaCandidateSubsystemState {
    init(_ state: MediaSubsystemState) {
        switch state {
        case .unavailable:
            self = .unavailable
        case .idle:
            self = .idle
        case .paused:
            self = .paused
        case .playing:
            self = .playing
        }
    }
}

private extension MediaCandidateSnapshot {
    init(_ snapshot: MediaSessionSnapshot) {
        sourceBundleIdentifier = snapshot.source.bundleIdentifier
        hasArtwork = snapshot.artworkData != nil
        isPlaying = snapshot.playbackState == .playing
        capabilities = MediaCandidateCapabilities(snapshot.capabilities)
    }
}

private extension MediaCandidateCommand {
    var mediaCommand: MediaCommand {
        switch self {
        case .toggle:
            return .togglePlayPause
        case .previous:
            return .previous
        case .next:
            return .next
        case .seek(let seconds):
            return .seek(seconds: seconds)
        }
    }
}
