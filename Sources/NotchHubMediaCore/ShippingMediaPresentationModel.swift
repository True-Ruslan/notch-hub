import Combine
import Foundation

public enum ShippingMediaPlaybackState: Sendable, Equatable {
    case paused
    case playing
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
        durationSeconds: Double?
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
    }
}

@MainActor
public final class ShippingMediaPresentationModel: ObservableObject {
    @Published public private(set) var presentation: ShippingMediaPresentation?
    public var presentationDidChange: (@MainActor (ShippingMediaPresentation?) -> Void)?

    public init() {}

    func apply(state: MediaSubsystemState, snapshot: MediaSessionSnapshot?) {
        guard let snapshot else {
            setPresentation(nil)
            return
        }

        let playbackState: ShippingMediaPlaybackState
        switch state {
        case .playing:
            playbackState = .playing
        case .paused:
            playbackState = .paused
        case .unavailable, .idle:
            setPresentation(nil)
            return
        }

        let progress = Self.normalizedProgress(
            positionSeconds: snapshot.positionSeconds,
            durationSeconds: snapshot.durationSeconds
        )
        let sourceBundleIdentifier = Self.normalizedText(snapshot.source.bundleIdentifier)

        setPresentation(
            ShippingMediaPresentation(
                playbackState: playbackState,
                title: Self.normalizedText(snapshot.title),
                artist: Self.normalizedText(snapshot.artist),
                album: Self.normalizedText(snapshot.album),
                artworkData: snapshot.artworkData,
                sourceBundleIdentifier: sourceBundleIdentifier,
                sourceDisplayName: Self.normalizedText(snapshot.source.displayName)
                    ?? sourceBundleIdentifier
                    ?? snapshot.source.bundleIdentifier,
                canGoPrevious: snapshot.capabilities.previous == .supported,
                canGoNext: snapshot.capabilities.next == .supported,
                canSeek: snapshot.capabilities.seek == .supported,
                positionSeconds: progress.position,
                durationSeconds: progress.duration
            )
        )
    }

    func clear() {
        setPresentation(nil)
    }

    private func setPresentation(_ newPresentation: ShippingMediaPresentation?) {
        guard presentation != newPresentation else {
            return
        }

        presentation = newPresentation
        presentationDidChange?(newPresentation)
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
