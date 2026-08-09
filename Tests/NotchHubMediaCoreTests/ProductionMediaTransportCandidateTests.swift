import Foundation
import Testing
@testable import NotchHubMediaCore

struct ProductionMediaTransportCandidateTests {
    @Test
    func collectorRecordsOnlyPrivacySafeTransitionEvidence() throws {
        var collector = ProductionMediaTransportCandidateCollector(sourceCommit: String(repeating: "a", count: 40))

        collector.record(state: .idle, snapshot: nil)
        collector.record(
            state: .playing,
            snapshot: makeSnapshot(
                generation: 1,
                revision: 1,
                source: "source.a",
                title: "Secret Track A",
                artist: "Secret Artist A",
                artwork: Data([1, 2, 3]),
                capabilities: supportedCapabilities
            ))
        collector.record(
            state: .paused,
            snapshot: makeSnapshot(
                generation: 2,
                revision: 1,
                source: "source.b",
                title: "Secret Track B",
                artist: "Secret Artist B",
                artwork: nil,
                capabilities: partialCapabilities
            ))
        collector.record(state: .idle, snapshot: nil)

        let report = collector.report(cleanTeardown: true)
        let encoded = try JSONEncoder().encode(report)
        let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        #expect(report.schemaVersion == 1)
        #expect(report.observedSession)
        #expect(report.observedArtwork)
        #expect(report.observedPlayingState)
        #expect(report.observedSessionDisappearance)
        #expect(report.sourceSwitchCount == 1)
        #expect(report.sourceBundleIdentifier == "source.b")
        #expect(report.capabilities.previous == .unsupported)
        #expect(report.capabilities.next == .supported)
        #expect(report.capabilities.seek == .unknown)
        #expect(report.cleanTeardown)
        #expect(report.eventCount == 4)

        let forbidden = [
            "title", "artist", "album", "artworkData", "rawPayload", "listeningHistory"
        ]
        #expect(forbidden.allSatisfy { object[$0] == nil })
        let serialized = String(decoding: encoded, as: UTF8.self)
        #expect(!serialized.contains("Secret Track"))
        #expect(!serialized.contains("Secret Artist"))
    }

    @Test
    func stableSourceDoesNotFabricateSwitchOrDisappearance() {
        var collector = ProductionMediaTransportCandidateCollector(sourceCommit: String(repeating: "b", count: 40))
        collector.record(
            state: .playing,
            snapshot: makeSnapshot(
                generation: 1,
                revision: 1,
                source: "source.a",
                title: "A",
                artist: nil,
                artwork: nil,
                capabilities: supportedCapabilities
            ))
        collector.record(
            state: .paused,
            snapshot: makeSnapshot(
                generation: 1,
                revision: 2,
                source: "source.a",
                title: "A",
                artist: nil,
                artwork: nil,
                capabilities: supportedCapabilities
            ))

        let report = collector.report(cleanTeardown: true)
        #expect(report.sourceSwitchCount == 0)
        #expect(!report.observedSessionDisappearance)
    }

    @Test
    func candidateCommandMapsOnlyToTypedProductionCommands() {
        #expect(ProductionMediaTransportCandidateCommand.toggle.mediaCommand == .togglePlayPause)
        #expect(ProductionMediaTransportCandidateCommand.previous.mediaCommand == .previous)
        #expect(ProductionMediaTransportCandidateCommand.next.mediaCommand == .next)
        #expect(ProductionMediaTransportCandidateCommand.seek(seconds: 42).mediaCommand == .seek(seconds: 42))
    }

    @Test
    func candidateCapabilityEncodingUsesExactTriStateStrings() throws {
        let capabilities = ProductionMediaTransportCandidateCapabilities(
            previous: .supported,
            next: .unsupported,
            seek: .unknown
        )
        let data = try JSONEncoder().encode(capabilities)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])

        #expect(
            object == [
                "previous": "supported",
                "next": "unsupported",
                "seek": "unknown"
            ])
    }

    private var supportedCapabilities: MediaCommandCapabilities {
        MediaCommandCapabilities(previous: .supported, next: .supported, seek: .supported)
    }

    private var partialCapabilities: MediaCommandCapabilities {
        MediaCommandCapabilities(previous: .unsupported, next: .supported, seek: .unknown)
    }

    private func makeSnapshot(
        generation: UInt64,
        revision: UInt64,
        source: String,
        title: String?,
        artist: String?,
        artwork: Data?,
        capabilities: MediaCommandCapabilities
    ) -> MediaSessionSnapshot {
        MediaSessionSnapshot(
            sequence: MediaSequence(generation: generation, revision: revision),
            source: MediaSourceIdentity(bundleIdentifier: source, displayName: nil),
            title: title,
            artist: artist,
            album: "Secret Album",
            artworkData: artwork,
            playbackState: .playing,
            durationSeconds: 180,
            positionSeconds: 42,
            referenceDate: Date(timeIntervalSince1970: 1_786_233_600),
            playbackRate: 1,
            capabilities: capabilities
        )
    }
}
