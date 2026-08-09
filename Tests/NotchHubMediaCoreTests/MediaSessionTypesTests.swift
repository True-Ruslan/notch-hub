import Foundation
import Testing
@testable import NotchHubMediaCore

struct MediaSessionTypesTests {
    @Test
    func sequenceOrdersByGenerationThenRevision() {
        #expect(
            MediaSequence(generation: 1, revision: 2)
                < MediaSequence(generation: 2, revision: 0)
        )
        #expect(
            MediaSequence(generation: 2, revision: 1)
                > MediaSequence(generation: 2, revision: 0)
        )
    }

    @Test
    func snapshotKeepsMissingMetadataAbsent() {
        let snapshot = MediaSessionSnapshot(
            sequence: MediaSequence(generation: 1, revision: 1),
            source: MediaSourceIdentity(
                bundleIdentifier: "ru.yandex.desktop.music",
                displayName: nil
            ),
            title: nil,
            artist: nil,
            album: nil,
            artworkData: nil,
            playbackState: .paused,
            durationSeconds: nil,
            positionSeconds: nil,
            referenceDate: nil,
            playbackRate: nil,
            capabilities: MediaCommandCapabilities(
                previous: .unknown,
                next: .unknown,
                seek: .unknown
            )
        )

        #expect(snapshot.title == nil)
        #expect(snapshot.artist == nil)
        #expect(snapshot.album == nil)
        #expect(snapshot.artworkData == nil)
        #expect(snapshot.durationSeconds == nil)
        #expect(snapshot.positionSeconds == nil)
        #expect(snapshot.referenceDate == nil)
        #expect(snapshot.playbackRate == nil)
        #expect(snapshot.capabilities.seek == .unknown)
    }

    @Test
    func sourceIdentityPreservesOnlyProvidedDisplayInformation() {
        let source = MediaSourceIdentity(
            bundleIdentifier: "ru.yandex.desktop.yandex-browser",
            displayName: nil
        )

        #expect(source.bundleIdentifier == "ru.yandex.desktop.yandex-browser")
        #expect(source.displayName == nil)
    }
}
