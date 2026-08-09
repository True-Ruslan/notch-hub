import Foundation

public struct MediaSequence: Sendable, Equatable, Comparable {
    public let generation: UInt64
    public let revision: UInt64

    public init(generation: UInt64, revision: UInt64) {
        self.generation = generation
        self.revision = revision
    }

    public static func < (lhs: MediaSequence, rhs: MediaSequence) -> Bool {
        if lhs.generation != rhs.generation {
            return lhs.generation < rhs.generation
        }
        return lhs.revision < rhs.revision
    }
}

public enum MediaCapabilityState: Sendable, Equatable {
    case supported
    case unsupported
    case unknown
}

public struct MediaCommandCapabilities: Sendable, Equatable {
    public let previous: MediaCapabilityState
    public let next: MediaCapabilityState
    public let seek: MediaCapabilityState

    public init(
        previous: MediaCapabilityState,
        next: MediaCapabilityState,
        seek: MediaCapabilityState
    ) {
        self.previous = previous
        self.next = next
        self.seek = seek
    }
}

public enum MediaPlaybackState: Sendable, Equatable {
    case paused
    case playing
}

public struct MediaSourceIdentity: Sendable, Equatable {
    public let bundleIdentifier: String
    public let displayName: String?

    public init(bundleIdentifier: String, displayName: String?) {
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
    }
}

public struct MediaSessionSnapshot: Sendable, Equatable {
    public let sequence: MediaSequence
    public let source: MediaSourceIdentity
    public let title: String?
    public let artist: String?
    public let album: String?
    public let artworkData: Data?
    public let playbackState: MediaPlaybackState
    public let durationSeconds: Double?
    public let positionSeconds: Double?
    public let referenceDate: Date?
    public let playbackRate: Double?
    public let capabilities: MediaCommandCapabilities

    public init(
        sequence: MediaSequence,
        source: MediaSourceIdentity,
        title: String?,
        artist: String?,
        album: String?,
        artworkData: Data?,
        playbackState: MediaPlaybackState,
        durationSeconds: Double?,
        positionSeconds: Double?,
        referenceDate: Date?,
        playbackRate: Double?,
        capabilities: MediaCommandCapabilities
    ) {
        self.sequence = sequence
        self.source = source
        self.title = title
        self.artist = artist
        self.album = album
        self.artworkData = artworkData
        self.playbackState = playbackState
        self.durationSeconds = durationSeconds
        self.positionSeconds = positionSeconds
        self.referenceDate = referenceDate
        self.playbackRate = playbackRate
        self.capabilities = capabilities
    }
}

public enum MediaCommand: Sendable, Equatable {
    case togglePlayPause
    case previous
    case next
    case seek(seconds: Double)
}

public enum MediaSubsystemState: Sendable, Equatable {
    case unavailable
    case idle
    case paused
    case playing
}
