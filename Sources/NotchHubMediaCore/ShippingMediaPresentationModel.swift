import Combine
import Foundation

public enum ShippingMediaPlaybackState: Sendable, Equatable {
    case paused
    case playing
}

public struct ShippingMediaSessionIdentity: Sendable, Equatable, Hashable {
    public let generation: UInt64
    public let sourceBundleIdentifier: String

    public init(generation: UInt64, sourceBundleIdentifier: String) {
        self.generation = generation
        self.sourceBundleIdentifier = sourceBundleIdentifier
    }
}

public struct ShippingMediaSeekTransaction: Sendable, Equatable {
    public let sessionIdentity: ShippingMediaSessionIdentity

    public init?(presentation: ShippingMediaPresentation) {
        guard presentation.canSeek, let sessionIdentity = presentation.sessionIdentity else {
            return nil
        }

        self.sessionIdentity = sessionIdentity
    }

    public func accepts(_ presentation: ShippingMediaPresentation) -> Bool {
        presentation.canSeek && presentation.sessionIdentity == sessionIdentity
    }
}

public struct ShippingMediaPresentation: Sendable, Equatable {
    public let playbackState: ShippingMediaPlaybackState
    public let title: String?
    public let artist: String?
    public let album: String?
    public let artworkData: Data?
    public let sourceBundleIdentifier: String?
    public let sourceDisplayName: String
    public let canGoPrevious: Bool
    public let canGoNext: Bool
    public let canSeek: Bool
    public let positionSeconds: Double?
    public let durationSeconds: Double?
    public let sessionIdentity: ShippingMediaSessionIdentity?

    public init(
        playbackState: ShippingMediaPlaybackState,
        title: String?,
        artist: String?,
        album: String?,
        artworkData: Data?,
        sourceBundleIdentifier: String?,
        sourceDisplayName: String,
        canGoPrevious: Bool,
        canGoNext: Bool,
        canSeek: Bool,
        positionSeconds: Double?,
        durationSeconds: Double?,
        sessionIdentity: ShippingMediaSessionIdentity? = nil
    ) {
        self.playbackState = playbackState
        self.title = title
        self.artist = artist
        self.album = album
        self.artworkData = artworkData
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.sourceDisplayName = sourceDisplayName
        self.canGoPrevious = canGoPrevious
        self.canGoNext = canGoNext
        self.canSeek = canSeek
        self.positionSeconds = positionSeconds
        self.durationSeconds = durationSeconds
        self.sessionIdentity = sessionIdentity
    }
}

enum ShippingMediaPresentationProjection {
    static func make(
        state: MediaSubsystemState,
        snapshot: MediaSessionSnapshot?
    ) -> ShippingMediaPresentation? {
        guard let snapshot else {
            return nil
        }

        let playbackState: ShippingMediaPlaybackState
        switch state {
        case .playing:
            playbackState = .playing
        case .paused:
            playbackState = .paused
        case .unavailable, .idle:
            return nil
        }

        let progress = normalizedProgress(
            positionSeconds: snapshot.positionSeconds,
            durationSeconds: snapshot.durationSeconds
        )
        let sourceBundleIdentifier = normalizedText(snapshot.source.bundleIdentifier)
        let sessionIdentity = sourceBundleIdentifier.map {
            ShippingMediaSessionIdentity(
                generation: snapshot.sequence.generation,
                sourceBundleIdentifier: $0
            )
        }

        return ShippingMediaPresentation(
            playbackState: playbackState,
            title: normalizedText(snapshot.title),
            artist: normalizedText(snapshot.artist),
            album: normalizedText(snapshot.album),
            artworkData: snapshot.artworkData,
            sourceBundleIdentifier: sourceBundleIdentifier,
            sourceDisplayName: normalizedText(snapshot.source.displayName)
                ?? sourceBundleIdentifier
                ?? snapshot.source.bundleIdentifier,
            canGoPrevious: snapshot.capabilities.previous == .supported,
            canGoNext: snapshot.capabilities.next == .supported,
            canSeek: snapshot.capabilities.seek == .supported,
            positionSeconds: progress.position,
            durationSeconds: progress.duration,
            sessionIdentity: sessionIdentity
        )
    }

    private static func normalizedText(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func normalizedProgress(
        positionSeconds: Double?,
        durationSeconds: Double?
    ) -> (position: Double?, duration: Double?) {
        guard let positionSeconds,
            let durationSeconds,
            positionSeconds.isFinite,
            durationSeconds.isFinite,
            positionSeconds >= 0,
            durationSeconds > 0
        else {
            return (nil, nil)
        }

        return (min(positionSeconds, durationSeconds), durationSeconds)
    }
}

@MainActor
public final class ShippingMediaPresentationModel: ObservableObject {
    @Published public private(set) var presentation: ShippingMediaPresentation?
    public var presentationDidChange: (@MainActor (ShippingMediaPresentation?) -> Void)?

    public init() {}

    func apply(state: MediaSubsystemState, snapshot: MediaSessionSnapshot?) {
        setPresentation(
            ShippingMediaPresentationProjection.make(
                state: state,
                snapshot: snapshot
            )
        )
    }

    public func applyOneShotPresentation(_ presentation: ShippingMediaPresentation) {
        setPresentation(presentation)
    }

    public func clearAuthoritativePresentation() {
        setPresentation(nil)
    }

    func clear() {
        clearAuthoritativePresentation()
    }

    private func setPresentation(_ newPresentation: ShippingMediaPresentation?) {
        guard presentation != newPresentation else {
            return
        }

        presentation = newPresentation
        presentationDidChange?(newPresentation)
    }
}
