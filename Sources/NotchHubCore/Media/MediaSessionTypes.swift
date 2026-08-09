import Foundation

struct MediaSequence: Sendable, Equatable, Comparable {
    let generation: UInt64
    let revision: UInt64

    init(generation: UInt64, revision: UInt64) {
        self.generation = generation
        self.revision = revision
    }

    static func < (lhs: MediaSequence, rhs: MediaSequence) -> Bool {
        if lhs.generation != rhs.generation {
            return lhs.generation < rhs.generation
        }
        return lhs.revision < rhs.revision
    }
}

enum MediaCapabilityState: Sendable, Equatable {
    case supported
    case unsupported
    case unknown
}

struct MediaCommandCapabilities: Sendable, Equatable {
    let previous: MediaCapabilityState
    let next: MediaCapabilityState
    let seek: MediaCapabilityState

    init(
        previous: MediaCapabilityState,
        next: MediaCapabilityState,
        seek: MediaCapabilityState
    ) {
        self.previous = previous
        self.next = next
        self.seek = seek
    }
}

enum MediaPlaybackState: Sendable, Equatable {
    case paused
    case playing
}

struct MediaSourceIdentity: Sendable, Equatable {
    let bundleIdentifier: String
    let displayName: String?

    init(bundleIdentifier: String, displayName: String?) {
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
    }
}

struct MediaSessionSnapshot: Sendable, Equatable {
    let sequence: MediaSequence
    let source: MediaSourceIdentity
    let title: String?
    let artist: String?
    let album: String?
    let artworkData: Data?
    let playbackState: MediaPlaybackState
    let durationSeconds: Double?
    let positionSeconds: Double?
    let referenceDate: Date?
    let playbackRate: Double?
    let capabilities: MediaCommandCapabilities

    init(
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

enum MediaCommand: Sendable, Equatable {
    case togglePlayPause
    case previous
    case next
    case seek(seconds: Double)
}

enum MediaSubsystemState: Sendable, Equatable {
    case unavailable
    case idle
    case paused
    case playing
}
