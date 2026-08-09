import Foundation
import Testing
@testable import MediaBridgeProbeCore

@MainActor
struct ProbeObservationEvidenceTests {
    @Test
    func noSessionCountsAsDisappearanceOnlyAfterObservedSession() {
        let evidence = ProbeObservationEvidence()

        evidence.record(nil)
        #expect(evidence.observedSessionDisappearance == false)

        evidence.record(payload(bundleIdentifier: "ru.yandex.desktop.music"))
        evidence.record(nil)

        #expect(evidence.observedSession == true)
        #expect(evidence.observedSessionDisappearance == true)
        #expect(evidence.eventCount == 3)
    }

    @Test
    func sourceSwitchCountChangesOnlyForDifferentObservedBundleIdentifier() {
        let evidence = ProbeObservationEvidence()

        evidence.record(payload(bundleIdentifier: "ru.yandex.desktop.music"))
        evidence.record(payload(bundleIdentifier: "ru.yandex.desktop.music"))
        evidence.record(nil)
        evidence.record(payload(bundleIdentifier: "com.apple.Music"))
        evidence.record(payload(bundleIdentifier: "com.apple.Music"))

        #expect(evidence.sourceSwitchCount == 1)
        #expect(evidence.sourceBundleIdentifier == "com.apple.Music")
        #expect(evidence.eventCount == 5)
    }

    private func payload(bundleIdentifier: String) -> ProbeMediaPayload {
        ProbeMediaPayload(
            bundleIdentifier: bundleIdentifier,
            playing: true,
            title: "ignored by evidence collector",
            artist: nil,
            album: nil,
            durationMicros: nil,
            elapsedTimeMicros: nil,
            timestampEpochMicros: nil,
            playbackRate: nil,
            artworkMimeType: nil,
            artworkByteCount: 0,
            prohibitsSkip: nil
        )
    }
}
