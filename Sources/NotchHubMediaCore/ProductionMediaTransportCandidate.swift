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
    public let observedArtworkClearOnSourceSwitch: Bool
    public let sourceSwitchCount: Int
    public let sourceBundleIdentifier: String?
    public let capabilities: ProductionMediaTransportCandidateCapabilities
    public let cleanTeardown: Bool

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case sourceCommit
        case adapterCommit
        case eventCount
        case observedSession
        case observedArtwork
        case observedPlayingState
        case observedSessionDisappearance
        case observedArtworkClearOnSourceSwitch
        case sourceSwitchCount
        case sourceBundleIdentifier
        case capabilities
        case cleanTeardown
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(sourceCommit, forKey: .sourceCommit)
        try container.encode(adapterCommit, forKey: .adapterCommit)
        try container.encode(eventCount, forKey: .eventCount)
        try container.encode(observedSession, forKey: .observedSession)
        try container.encode(observedArtwork, forKey: .observedArtwork)
        try container.encode(observedPlayingState, forKey: .observedPlayingState)
        try container.encode(observedSessionDisappearance, forKey: .observedSessionDisappearance)
        try container.encode(
            observedArtworkClearOnSourceSwitch,
            forKey: .observedArtworkClearOnSourceSwitch
        )
        try container.encode(sourceSwitchCount, forKey: .sourceSwitchCount)
        if let sourceBundleIdentifier {
            try container.encode(sourceBundleIdentifier, forKey: .sourceBundleIdentifier)
        } else {
            try container.encodeNil(forKey: .sourceBundleIdentifier)
        }
        try container.encode(capabilities, forKey: .capabilities)
        try container.encode(cleanTeardown, forKey: .cleanTeardown)
    }
}

public enum ProductionMediaTransportCandidateFailureCode: String, Codable, Equatable, Sendable {
    case invalidArguments
    case invalidObservationDuration
    case processTimedOut
    case processFailed
    case outputUnavailable
    case outputTooLarge
    case capabilityProtocol
    case processLaunch
    case unexpectedRuntimeFailure

    public static func classify(_ error: any Error) -> Self {
        if let candidateError = error as? ProductionMediaTransportCandidateError {
            switch candidateError {
            case .invalidArguments:
                return .invalidArguments
            case .invalidObservationDuration:
                return .invalidObservationDuration
            }
        }

        if let processError = error as? MediaRemoteProcessClientError {
            switch processError {
            case .timedOut:
                return .processTimedOut
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

        return .unexpectedRuntimeFailure
    }
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
    private var observedArtworkClearOnSourceSwitch = false
    private var sourceSwitchCount = 0
    private var sourceBundleIdentifier: String?
    private var lastSnapshotHadArtwork = false
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
            if lastSnapshotHadArtwork, snapshot.artworkData == nil {
                observedArtworkClearOnSourceSwitch = true
            }
        }

        observedSession = true
        observedArtwork = observedArtwork || snapshot.artworkData != nil
        observedPlayingState = observedPlayingState || state == .playing || snapshot.playbackState == .playing
        sourceBundleIdentifier = snapshot.source.bundleIdentifier
        lastSnapshotHadArtwork = snapshot.artworkData != nil
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
            observedArtworkClearOnSourceSwitch: observedArtworkClearOnSourceSwitch,
            sourceSwitchCount: sourceSwitchCount,
            sourceBundleIdentifier: sourceBundleIdentifier,
            capabilities: capabilities,
            cleanTeardown: cleanTeardown
        )
    }
}

extension ProductionMediaTransportCandidateCapabilities {
    init(_ capabilities: MediaCommandCapabilities) {
        previous = ProductionMediaTransportCandidateCapabilityState(capabilities.previous)
        next = ProductionMediaTransportCandidateCapabilityState(capabilities.next)
        seek = ProductionMediaTransportCandidateCapabilityState(capabilities.seek)
    }
}

extension ProductionMediaTransportCandidateCapabilityState {
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
