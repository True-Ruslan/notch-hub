import Foundation

public enum ProductionMediaTransportCandidateCapabilityState: String, Codable, Equatable, Sendable {
    case supported
    case unsupported
    case unknown
}

public struct ProductionMediaTransportCandidateCapabilities: Codable, Equatable, Sendable {
    public let previous: ProductionMediaTransportCandidateCapabilityState
    public let next: ProductionMediaTransportCandidateCapabilityState
    public let seek: ProductionMediaTransportCandidateCapabilityState

    public init(
        previous: ProductionMediaTransportCandidateCapabilityState,
        next: ProductionMediaTransportCandidateCapabilityState,
        seek: ProductionMediaTransportCandidateCapabilityState
    ) {
        self.previous = previous
        self.next = next
        self.seek = seek
    }
}

public struct ProductionMediaTransportCandidateReport: Codable, Sendable {
    public let schemaVersion: Int
    public let sourceCommit: String
    public let adapterCommit: String
    public let eventCount: Int
    public let observedSession: Bool
    public let observedArtwork: Bool
    public let observedPlayingState: Bool
    public let observedSessionDisappearance: Bool
    public let sourceSwitchCount: Int
    public let sourceBundleIdentifier: String?
    public let capabilities: ProductionMediaTransportCandidateCapabilities
    public let cleanTeardown: Bool
}

public enum ProductionMediaTransportCandidateCommand: Equatable, Sendable {
    case toggle
    case previous
    case next
    case seek(seconds: Double)

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

struct ProductionMediaTransportCandidateCollector {
    private static let adapterCommit = "3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"

    private let sourceCommit: String
    private var eventCount = 0
    private var observedSession = false
    private var observedArtwork = false
    private var observedPlayingState = false
    private var observedSessionDisappearance = false
    private var sourceSwitchCount = 0
    private var sourceBundleIdentifier: String?
    private var capabilities = ProductionMediaTransportCandidateCapabilities(
        previous: .unknown,
        next: .unknown,
        seek: .unknown
    )

    init(sourceCommit: String) {
        self.sourceCommit = sourceCommit
    }

    mutating func record(state: MediaSubsystemState, snapshot: MediaSessionSnapshot?) {
        eventCount += 1

        guard let snapshot else {
            if observedSession, state == .idle {
                observedSessionDisappearance = true
            }
            return
        }

        if let previousSource = sourceBundleIdentifier,
            previousSource != snapshot.source.bundleIdentifier
        {
            sourceSwitchCount += 1
        }

        observedSession = true
        observedArtwork = observedArtwork || snapshot.artworkData != nil
        observedPlayingState = observedPlayingState || state == .playing || snapshot.playbackState == .playing
        sourceBundleIdentifier = snapshot.source.bundleIdentifier
        capabilities = ProductionMediaTransportCandidateCapabilities(snapshot.capabilities)
    }

    func report(cleanTeardown: Bool) -> ProductionMediaTransportCandidateReport {
        ProductionMediaTransportCandidateReport(
            schemaVersion: 1,
            sourceCommit: sourceCommit,
            adapterCommit: Self.adapterCommit,
            eventCount: eventCount,
            observedSession: observedSession,
            observedArtwork: observedArtwork,
            observedPlayingState: observedPlayingState,
            observedSessionDisappearance: observedSessionDisappearance,
            sourceSwitchCount: sourceSwitchCount,
            sourceBundleIdentifier: sourceBundleIdentifier,
            capabilities: capabilities,
            cleanTeardown: cleanTeardown
        )
    }
}

private extension ProductionMediaTransportCandidateCapabilities {
    init(_ capabilities: MediaCommandCapabilities) {
        previous = ProductionMediaTransportCandidateCapabilityState(capabilities.previous)
        next = ProductionMediaTransportCandidateCapabilityState(capabilities.next)
        seek = ProductionMediaTransportCandidateCapabilityState(capabilities.seek)
    }
}

private extension ProductionMediaTransportCandidateCapabilityState {
    init(_ state: MediaCapabilityState) {
        switch state {
        case .supported:
            self = .supported
        case .unsupported:
            self = .unsupported
        case .unknown:
            self = .unknown
        }
    }
}
