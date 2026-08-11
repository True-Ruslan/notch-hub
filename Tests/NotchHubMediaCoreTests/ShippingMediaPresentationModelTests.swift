import Foundation
import Testing
@testable import NotchHubMediaCore

@MainActor
struct ShippingMediaPresentationModelTests {
    @Test
    func playingSessionMapsAuthoritativePresentation() {
        let model = ShippingMediaPresentationModel()

        model.apply(
            state: .playing,
            snapshot: snapshot(
                title: "Track",
                artist: "Artist",
                album: "Album",
                playbackState: .playing
            )
        )

        #expect(model.presentation?.playbackState == .playing)
        #expect(model.presentation?.title == "Track")
        #expect(model.presentation?.artist == "Artist")
        #expect(model.presentation?.album == "Album")
        #expect(model.presentation?.artworkData == Data([1, 2, 3]))
        #expect(model.presentation?.sourceDisplayName == "Yandex Music")
        #expect(model.presentation?.canGoPrevious == true)
        #expect(model.presentation?.canGoNext == true)
        #expect(model.presentation?.canSeek == true)
        #expect(model.presentation?.positionSeconds == 42)
        #expect(model.presentation?.durationSeconds == 240)
    }

    @Test
    func pausedSessionMapsPausedPresentation() {
        let model = ShippingMediaPresentationModel()

        model.apply(
            state: .paused,
            snapshot: snapshot(playbackState: .paused)
        )

        #expect(model.presentation?.playbackState == .paused)
    }

    @Test
    func whitespaceMetadataIsOmittedWithoutFabrication() {
        let model = ShippingMediaPresentationModel()

        model.apply(
            state: .playing,
            snapshot: snapshot(
                sourceDisplayName: "   ",
                title: "  ",
                artist: "\n\t",
                album: " Album ",
                playbackState: .playing
            )
        )

        #expect(model.presentation?.title == nil)
        #expect(model.presentation?.artist == nil)
        #expect(model.presentation?.album == "Album")
        #expect(model.presentation?.sourceDisplayName == "ru.yandex.desktop.music")
    }

    @Test
    func unsupportedAndUnknownCapabilitiesRemainDisabled() {
        let model = ShippingMediaPresentationModel()

        model.apply(
            state: .playing,
            snapshot: snapshot(
                playbackState: .playing,
                capabilities: MediaCommandCapabilities(
                    previous: .unsupported,
                    next: .unknown,
                    seek: .supported
                )
            )
        )

        #expect(model.presentation?.canGoPrevious == false)
        #expect(model.presentation?.canGoNext == false)
        #expect(model.presentation?.canSeek == true)
    }

    @Test
    func trustworthyProgressIsPreservedAndClamped() {
        let model = ShippingMediaPresentationModel()

        model.apply(
            state: .playing,
            snapshot: snapshot(
                playbackState: .playing,
                durationSeconds: 200,
                positionSeconds: 260
            )
        )

        #expect(model.presentation?.positionSeconds == 200)
        #expect(model.presentation?.durationSeconds == 200)
    }

    @Test
    func invalidProgressIsOmitted() {
        let model = ShippingMediaPresentationModel()

        model.apply(
            state: .playing,
            snapshot: snapshot(
                playbackState: .playing,
                durationSeconds: 0,
                positionSeconds: .nan
            )
        )

        #expect(model.presentation?.positionSeconds == nil)
        #expect(model.presentation?.durationSeconds == nil)
    }

    @Test
    func idleAndUnavailableClearPresentation() {
        let model = ShippingMediaPresentationModel()

        model.apply(state: .playing, snapshot: snapshot(playbackState: .playing))
        #expect(model.presentation != nil)

        model.apply(state: .idle, snapshot: nil)
        #expect(model.presentation == nil)

        model.apply(state: .paused, snapshot: snapshot(playbackState: .paused))
        #expect(model.presentation != nil)

        model.apply(state: .unavailable, snapshot: nil)
        #expect(model.presentation == nil)
    }

    @Test
    func freshRuntimeSnapshotMayReplaceRetainedContextRegardlessOfRawSequence() {
        let model = ShippingMediaPresentationModel()

        model.apply(
            state: .playing,
            snapshot: snapshot(
                generation: 9,
                revision: 12,
                title: "Retained old runtime",
                playbackState: .playing
            )
        )
        model.apply(
            state: .playing,
            snapshot: snapshot(
                generation: 1,
                revision: 1,
                title: "Fresh new runtime",
                playbackState: .playing
            )
        )

        #expect(model.presentation?.title == "Fresh new runtime")
    }

    private func snapshot(
        generation: UInt64 = 1,
        revision: UInt64 = 1,
        sourceDisplayName: String? = "Yandex Music",
        title: String? = "Track",
        artist: String? = "Artist",
        album: String? = "Album",
        playbackState: MediaPlaybackState,
        durationSeconds: Double? = 240,
        positionSeconds: Double? = 42,
        capabilities: MediaCommandCapabilities = MediaCommandCapabilities(
            previous: .supported,
            next: .supported,
            seek: .supported
        )
    ) -> MediaSessionSnapshot {
        MediaSessionSnapshot(
            sequence: MediaSequence(generation: generation, revision: revision),
            source: MediaSourceIdentity(
                bundleIdentifier: "ru.yandex.desktop.music",
                displayName: sourceDisplayName
            ),
            title: title,
            artist: artist,
            album: album,
            artworkData: Data([1, 2, 3]),
            playbackState: playbackState,
            durationSeconds: durationSeconds,
            positionSeconds: positionSeconds,
            referenceDate: nil,
            playbackRate: playbackState == .playing ? 1 : 0,
            capabilities: capabilities
        )
    }
}
