import Foundation
import Testing
@testable import NotchHubMediaCore

@MainActor
struct ShippingMediaSeekTransactionTests {
    @Test
    func presentationCarriesAuthoritativeMediaSessionIdentity() throws {
        let presentation = try makePresentation(
            generation: 7,
            revision: 3,
            bundleIdentifier: "  com.example.player  "
        )

        #expect(
            presentation.sessionIdentity
                == ShippingMediaSessionIdentity(
                    generation: 7,
                    sourceBundleIdentifier: "com.example.player"
                )
        )
    }

    @Test
    func seekTransactionAcceptsRevisionUpdateWithinSameMediaSession() throws {
        let initial = try makePresentation(generation: 7, revision: 1)
        let transaction = try #require(ShippingMediaSeekTransaction(presentation: initial))
        let progressRevision = try makePresentation(
            generation: 7,
            revision: 4,
            positionSeconds: 72
        )

        #expect(transaction.accepts(progressRevision))
    }

    @Test
    func seekTransactionRejectsTrackGenerationOrSourceChange() throws {
        let initial = try makePresentation(generation: 7, revision: 1)
        let transaction = try #require(ShippingMediaSeekTransaction(presentation: initial))
        let nextTrack = try makePresentation(generation: 8, revision: 1)
        let switchedSource = try makePresentation(
            generation: 7,
            revision: 2,
            bundleIdentifier: "com.example.browser"
        )

        #expect(!transaction.accepts(nextTrack))
        #expect(!transaction.accepts(switchedSource))
    }

    @Test
    func seekTransactionRejectsCapabilityLossAndMissingIdentity() throws {
        let initial = try makePresentation(generation: 7, revision: 1)
        let transaction = try #require(ShippingMediaSeekTransaction(presentation: initial))
        let unsupported = try makePresentation(
            generation: 7,
            revision: 2,
            canSeek: false
        )
        let identityMissing = try makePresentation(
            generation: 7,
            revision: 2,
            bundleIdentifier: "   "
        )

        #expect(!transaction.accepts(unsupported))
        #expect(!transaction.accepts(identityMissing))
        #expect(ShippingMediaSeekTransaction(presentation: unsupported) == nil)
        #expect(ShippingMediaSeekTransaction(presentation: identityMissing) == nil)
    }

    private func makePresentation(
        generation: UInt64,
        revision: UInt64,
        bundleIdentifier: String = "com.example.player",
        positionSeconds: Double = 30,
        canSeek: Bool = true
    ) throws -> ShippingMediaPresentation {
        let model = ShippingMediaPresentationModel()
        model.apply(
            state: .playing,
            snapshot: MediaSessionSnapshot(
                sequence: MediaSequence(generation: generation, revision: revision),
                source: MediaSourceIdentity(
                    bundleIdentifier: bundleIdentifier,
                    displayName: "Example Player"
                ),
                title: "Track",
                artist: "Artist",
                album: "Album",
                artworkData: nil,
                playbackState: .playing,
                durationSeconds: 180,
                positionSeconds: positionSeconds,
                referenceDate: nil,
                playbackRate: 1,
                capabilities: MediaCommandCapabilities(
                    previous: .supported,
                    next: .supported,
                    seek: canSeek ? .supported : .unsupported
                )
            )
        )
        return try #require(model.presentation)
    }
}
