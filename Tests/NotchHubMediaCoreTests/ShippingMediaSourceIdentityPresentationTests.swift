import Foundation
import Testing
@testable import NotchHubMediaCore

@MainActor
struct ShippingMediaSourceIdentityPresentationTests {
    @Test
    func sourceBundleIdentifierIsNormalizedSeparatelyFromDisplayName() throws {
        let model = ShippingMediaPresentationModel()
        let snapshot = makeSnapshot(
            bundleIdentifier: "  com.example.player  ",
            displayName: "Example Player"
        )

        model.apply(state: .playing, snapshot: snapshot)

        let presentation = try #require(model.presentation)
        #expect(presentation.sourceBundleIdentifier == "com.example.player")
        #expect(presentation.sourceDisplayName == "Example Player")
    }

    @Test
    func blankBundleIdentifierDoesNotInventSourceIdentity() throws {
        let model = ShippingMediaPresentationModel()
        let snapshot = makeSnapshot(
            bundleIdentifier: "   ",
            displayName: "Example Player"
        )

        model.apply(state: .paused, snapshot: snapshot)

        let presentation = try #require(model.presentation)
        #expect(presentation.sourceBundleIdentifier == nil)
        #expect(presentation.sourceDisplayName == "Example Player")
    }

    @Test
    func sourceBundleIdentifierChangeProducesNewPresentation() throws {
        let model = ShippingMediaPresentationModel()
        var changes: [ShippingMediaPresentation?] = []
        model.presentationDidChange = { presentation in
            changes.append(presentation)
        }

        model.apply(
            state: .playing,
            snapshot: makeSnapshot(
                bundleIdentifier: "com.example.one",
                displayName: "Same Display Name"
            )
        )
        model.apply(
            state: .playing,
            snapshot: makeSnapshot(
                bundleIdentifier: "com.example.two",
                displayName: "Same Display Name"
            )
        )

        #expect(changes.count == 2)
        #expect(changes[0]?.sourceBundleIdentifier == "com.example.one")
        #expect(changes[1]?.sourceBundleIdentifier == "com.example.two")
    }

    private func makeSnapshot(
        bundleIdentifier: String,
        displayName: String?
    ) -> MediaSessionSnapshot {
        MediaSessionSnapshot(
            sequence: MediaSequence(generation: 1, revision: 1),
            source: MediaSourceIdentity(
                bundleIdentifier: bundleIdentifier,
                displayName: displayName
            ),
            title: "Track",
            artist: "Artist",
            album: "Album",
            artworkData: nil,
            playbackState: .playing,
            durationSeconds: 120,
            positionSeconds: 30,
            referenceDate: nil,
            playbackRate: 1,
            capabilities: MediaCommandCapabilities(
                previous: .supported,
                next: .supported,
                seek: .supported
            )
        )
    }
}
