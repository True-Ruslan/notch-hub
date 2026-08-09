import Foundation
import Testing
@testable import MediaBridgeProbeCore

struct ProbeMediaPayloadTests {
    @Test
    func decodesNoDiffMicrosPayloadWithoutRetainingArtworkBytes() throws {
        let line = jsonData(
            #"""
            {
              "type": "data",
              "diff": false,
              "payload": {
                "bundleIdentifier": "ru.yandex.desktop.music",
                "playing": true,
                "title": "Track",
                "artist": "Artist",
                "album": "Album",
                "durationMicros": 180000000,
                "elapsedTimeMicros": 42000000,
                "timestampEpochMicros": 1786233600000000,
                "playbackRate": 1,
                "artworkMimeType": "image/jpeg",
                "artworkData": "AQID",
                "prohibitsSkip": false
              }
            }
            """#
        )

        let decoded = try #require(try ProbePayloadDecoder.decode(line: line))

        #expect(decoded.bundleIdentifier == "ru.yandex.desktop.music")
        #expect(decoded.playing)
        #expect(decoded.title == "Track")
        #expect(decoded.artist == "Artist")
        #expect(decoded.album == "Album")
        #expect(decoded.durationMicros == 180_000_000)
        #expect(decoded.elapsedTimeMicros == 42_000_000)
        #expect(decoded.timestampEpochMicros == 1_786_233_600_000_000)
        #expect(decoded.playbackRate == 1)
        #expect(decoded.artworkMimeType == "image/jpeg")
        #expect(decoded.artworkByteCount == 3)
        #expect(decoded.prohibitsSkip == false)
    }

    @Test
    func emptyPayloadMeansNoActiveSession() throws {
        let line = jsonData(
            #"""
            {"type":"data","diff":false,"payload":{}}
            """#
        )
        #expect(try ProbePayloadDecoder.decode(line: line) == nil)
    }

    @Test
    func rejectsDiffPayloadForProbeSimplicity() {
        let line = jsonData(
            #"""
            {
              "type": "data",
              "diff": true,
              "payload": {
                "bundleIdentifier": "test.player",
                "playing": true,
                "title": "stale"
              }
            }
            """#
        )

        #expect(throws: ProbePayloadDecoderError.diffPayloadNotAllowed) {
            try ProbePayloadDecoder.decode(line: line)
        }
    }

    @Test
    func rejectsOversizedLineBeforeJSONDecoding() {
        let line = Data(repeating: 0x61, count: ProbePayloadDecoder.maximumLineBytes + 1)

        #expect(throws: ProbePayloadDecoderError.lineTooLarge) {
            try ProbePayloadDecoder.decode(line: line)
        }
    }

    @Test
    func rejectsOversizedArtworkAfterBase64Decode() {
        let oversized = Data(
            repeating: 0x41,
            count: ProbePayloadDecoder.maximumArtworkBytes + 1
        ).base64EncodedString()
        let line = jsonData(
            #"""
            {
              "type": "data",
              "diff": false,
              "payload": {
                "bundleIdentifier": "test.player",
                "playing": true,
                "title": "Track",
                "artworkData": "\#(oversized)"
              }
            }
            """#
        )

        #expect(throws: ProbePayloadDecoderError.artworkTooLarge) {
            try ProbePayloadDecoder.decode(line: line)
        }
    }

    @Test
    func rejectsOversizedTextField() {
        let title = String(
            repeating: "x",
            count: ProbePayloadDecoder.maximumTextUTF8Bytes + 1
        )
        let line = jsonData(
            #"""
            {
              "type": "data",
              "diff": false,
              "payload": {
                "bundleIdentifier": "test.player",
                "playing": true,
                "title": "\#(title)"
              }
            }
            """#
        )

        #expect(throws: ProbePayloadDecoderError.textTooLarge) {
            try ProbePayloadDecoder.decode(line: line)
        }
    }

    @Test
    func rejectsPlaybackRateBeyondBound() {
        let line = jsonData(
            #"""
            {
              "type": "data",
              "diff": false,
              "payload": {
                "bundleIdentifier": "test.player",
                "playing": true,
                "title": "Track",
                "playbackRate": 16.1
              }
            }
            """#
        )

        #expect(throws: ProbePayloadDecoderError.playbackRateOutOfRange) {
            try ProbePayloadDecoder.decode(line: line)
        }
    }

    @Test
    func rejectsDurationBeyondThirtyDays() {
        let duration = ProbePayloadDecoder.maximumDurationMicros + 1
        let line = jsonData(
            #"""
            {
              "type": "data",
              "diff": false,
              "payload": {
                "bundleIdentifier": "test.player",
                "playing": true,
                "title": "Track",
                "durationMicros": \#(duration)
              }
            }
            """#
        )

        #expect(throws: ProbePayloadDecoderError.durationOutOfRange) {
            try ProbePayloadDecoder.decode(line: line)
        }
    }

    private func jsonData(_ value: String) -> Data {
        Data(value.utf8)
    }
}
