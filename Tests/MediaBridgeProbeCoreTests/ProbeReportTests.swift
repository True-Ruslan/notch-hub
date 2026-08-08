import Foundation
import Testing
@testable import MediaBridgeProbeCore

struct ProbeReportTests {
    @Test
    func encodesOnlyPrivacySafeEvidenceFields() throws {
        let report = ProbeReport(
            schemaVersion: 1,
            sourceCommit: String(repeating: "a", count: 40),
            macOSVersion: "26.6",
            hardwareModel: "Mac16,8",
            adapterCommit: String(repeating: "b", count: 40),
            sourceBundleIdentifier: "ru.yandex.desktop.music",
            observedSession: true,
            observedArtwork: true,
            observedPlayingState: true,
            eventCount: 42,
            commandResults: [
                "next": true,
                "previous": false,
                "seek": true,
                "toggle": true
            ],
            cleanTeardown: true,
            orphanProcessDetected: false
        )

        let data = try JSONEncoder().encode(report)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("ru.yandex.desktop.music"))
        #expect(json.contains("observedArtwork"))
        #expect(!json.contains("Secret Track"))
        #expect(!json.contains("Private Artist"))
        #expect(!json.contains("Confidential Album"))
        #expect(!json.contains("artworkData"))
    }

    @Test
    func reportRoundTripsWithoutAddingMetadataSurface() throws {
        let report = ProbeReport(
            schemaVersion: 1,
            sourceCommit: String(repeating: "c", count: 40),
            macOSVersion: "26.6",
            hardwareModel: "Mac16,8",
            adapterCommit: String(repeating: "d", count: 40),
            sourceBundleIdentifier: nil,
            observedSession: false,
            observedArtwork: false,
            observedPlayingState: false,
            eventCount: 0,
            commandResults: [:],
            cleanTeardown: true,
            orphanProcessDetected: false
        )

        let data = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(ProbeReport.self, from: data)

        #expect(decoded == report)
    }
}
