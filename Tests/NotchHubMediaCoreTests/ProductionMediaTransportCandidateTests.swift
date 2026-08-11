import Foundation
import NotchHubMediaCore
import Testing
@testable import NotchHubMediaCandidateCore

struct ProductionMediaTransportCandidateTests {
    @Test
    func collectorRecordsOnlyPrivacySafeTransitionEvidence() throws {
        var collector = ProductionMediaTransportCandidateCollector(
            sourceCommit: String(repeating: "a", count: 40)
        )

        collector.record(state: .idle, snapshot: nil)
        collector.record(
            state: .playing,
            snapshot: makeSnapshot(
                source: "source.a",
                hasArtwork: true,
                isPlaying: true,
                capabilities: supportedCapabilities
            ))
        collector.record(
            state: .paused,
            snapshot: makeSnapshot(
                source: "source.b",
                hasArtwork: false,
                isPlaying: false,
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
        #expect(report.observedArtworkClearOnSourceSwitch)
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
    }

    @Test
    func stableSourceDoesNotFabricateSwitchDisappearanceOrArtworkClear() {
        var collector = ProductionMediaTransportCandidateCollector(
            sourceCommit: String(repeating: "b", count: 40)
        )
        collector.record(
            state: .playing,
            snapshot: makeSnapshot(
                source: "source.a",
                hasArtwork: true,
                isPlaying: true,
                capabilities: supportedCapabilities
            ))
        collector.record(
            state: .paused,
            snapshot: makeSnapshot(
                source: "source.a",
                hasArtwork: false,
                isPlaying: false,
                capabilities: supportedCapabilities
            ))

        let report = collector.report(cleanTeardown: true)
        #expect(report.sourceSwitchCount == 0)
        #expect(!report.observedSessionDisappearance)
        #expect(!report.observedArtworkClearOnSourceSwitch)
    }

    @Test
    func candidateCommandMapsOnlyToTypedProductionCommands() {
        #expect(ProductionMediaTransportCandidateCommand.toggle.runtimeCommand == .toggle)
        #expect(ProductionMediaTransportCandidateCommand.previous.runtimeCommand == .previous)
        #expect(ProductionMediaTransportCandidateCommand.next.runtimeCommand == .next)
        #expect(
            ProductionMediaTransportCandidateCommand.seek(seconds: 42).runtimeCommand
                == .seek(seconds: 42)
        )
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

    @Test
    func failureCodesAreOperationalOnlyAndNeverSerializeUnderlyingErrors() {
        #expect(
            ProductionMediaTransportCandidateFailureCode.classify(
                ProductionMediaTransportCandidateError.invalidArguments
            ) == .invalidArguments
        )
        #expect(
            ProductionMediaTransportCandidateFailureCode.classify(
                ProductionMediaTransportCandidateError.invalidObservationDuration
            ) == .invalidObservationDuration
        )
        #expect(
            ProductionMediaTransportCandidateFailureCode.classify(
                MediaCandidateRuntimeError.timedOut
            ) == .processTimedOut
        )
        #expect(
            ProductionMediaTransportCandidateFailureCode.classify(
                MediaCandidateRuntimeError.teardownFailed
            ) == .processTeardown
        )
        #expect(
            ProductionMediaTransportCandidateFailureCode.classify(
                MediaCandidateRuntimeError.processFailed
            ) == .processFailed
        )
        #expect(
            ProductionMediaTransportCandidateFailureCode.classify(
                MediaCandidateRuntimeError.outputUnavailable
            ) == .outputUnavailable
        )
        #expect(
            ProductionMediaTransportCandidateFailureCode.classify(
                MediaCandidateRuntimeError.outputTooLarge
            ) == .outputTooLarge
        )
        #expect(
            ProductionMediaTransportCandidateFailureCode.classify(
                MediaCandidateRuntimeError.capabilityProtocol
            ) == .capabilityProtocol
        )
        #expect(
            ProductionMediaTransportCandidateFailureCode.classify(
                MediaCandidateRuntimeError.processLaunch
            ) == .processLaunch
        )
        #expect(
            ProductionMediaTransportCandidateFailureCode.classify(
                MediaCandidateRuntimeError.unexpected
            ) == .unexpectedRuntimeFailure
        )

        let encoded = try? JSONEncoder().encode(
            ProductionMediaTransportCandidateFailureCode.processLaunch
        )
        #expect(encoded == Data("\"processLaunch\"".utf8))
    }

    private var supportedCapabilities: MediaCandidateCapabilities {
        MediaCandidateCapabilities(previous: .supported, next: .supported, seek: .supported)
    }

    private var partialCapabilities: MediaCandidateCapabilities {
        MediaCandidateCapabilities(previous: .unsupported, next: .supported, seek: .unknown)
    }

    private func makeSnapshot(
        source: String,
        hasArtwork: Bool,
        isPlaying: Bool,
        capabilities: MediaCandidateCapabilities
    ) -> MediaCandidateSnapshot {
        MediaCandidateSnapshot(
            sourceBundleIdentifier: source,
            hasArtwork: hasArtwork,
            isPlaying: isPlaying,
            capabilities: capabilities
        )
    }
}
