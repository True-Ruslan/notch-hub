import Foundation

package struct MediaSequence: Sendable, Equatable, Comparable {
    package let generation: UInt64
    package let revision: UInt64

    package init(generation: UInt64, revision: UInt64) {
        self.generation = generation
        self.revision = revision
    }

    package static func < (lhs: MediaSequence, rhs: MediaSequence) -> Bool {
        if lhs.generation != rhs.generation {
            return lhs.generation < rhs.generation
        }
        return lhs.revision < rhs.revision
    }
}

package enum MediaCapabilityState: Sendable, Equatable {
    case supported
    case unsupported
    case unknown
}

package struct MediaCommandCapabilities: Sendable, Equatable {
    package let previous: MediaCapabilityState
    package let next: MediaCapabilityState
    package let seek: MediaCapabilityState

    package init(
        previous: MediaCapabilityState,
        next: MediaCapabilityState,
        seek: MediaCapabilityState
    ) {
        self.previous = previous
        self.next = next
        self.seek = seek
    }
}

package enum MediaPlaybackState: Sendable, Equatable {
    case paused
    case playing
}

package struct MediaSourceIdentity: Sendable, Equatable {
    package let bundleIdentifier: String
    package let displayName: String?

    package init(bundleIdentifier: String, displayName: String?) {
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
    }
}

package struct MediaSessionSnapshot: Sendable {
    package let sequence: MediaSequence
    package let source: MediaSourceIdentity
    package let title: String?
    package let artist: String?
    package let album: String?
    package let artworkData: Data?
    package let playbackState: MediaPlaybackState
    package let durationSeconds: Double?
    package let positionSeconds: Double?
    package let referenceDate: Date?
    package let playbackRate: Double?
    package let capabilities: MediaCommandCapabilities

    package init(
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

package enum MediaCommand: Sendable, Equatable {
    case togglePlayPause
    case previous
    case next
    case seek(seconds: Double)
}

package enum MediaSubsystemState: Sendable, Equatable {
    case unavailable
    case idle
    case paused
    case playing
}
