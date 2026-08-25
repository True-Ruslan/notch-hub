import Foundation
import Testing
@testable import NotchHubMediaCore

struct MediaRemoteWireTests {
    @Test
    func fullNoDiffPayloadDecodesNormalizedValues() throws {
        let json = #"""
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
                "playbackRate": 1.0,
                "artworkMimeType": "image/jpeg",
                "artworkData": "AQID",
                "contentItemIdentifier": "item-1",
                "uniqueIdentifier": "unique-1"
              }
            }
            """#
        let line = Data(json.utf8)

        let decoded = try MediaRemoteWireDecoder.decode(line: line)
        let payload = try #require(decoded)

        #expect(payload.bundleIdentifier == "ru.yandex.desktop.music")
        #expect(payload.playing)
        #expect(payload.title == "Track")
        #expect(payload.artist == "Artist")
        #expect(payload.album == "Album")
        #expect(payload.durationSeconds == 180)
        #expect(payload.positionSeconds == 42)
        #expect(payload.referenceDate == Date(timeIntervalSince1970: 1_786_233_600))
        #expect(payload.playbackRate == 1)
        #expect(payload.artworkData == Data([1, 2, 3]))
        #expect(payload.contentIdentifier == "item-1")
        #expect(payload.uniqueIdentifier == "unique-1")
    }

    @Test
    func missingArtworkRemainsAbsentInsteadOfReusingOldContent() throws {
        let line = Data(
            #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"com.apple.Safari","playing":true,"title":"Video"}}"#.utf8
        )

        let decoded = try MediaRemoteWireDecoder.decode(line: line)
        let payload = try #require(decoded)
        #expect(payload.artworkData == nil)
    }

    @Test
    func emptyPayloadMeansNoActiveSession() throws {
        let line = Data(#"{"type":"data","diff":false,"payload":{}}"#.utf8)
        #expect(try MediaRemoteWireDecoder.decode(line: line) == nil)
    }

    @Test
    func activeSessionWithoutTitleStillDecodes() throws {
        // Some browser video sites register a playing MediaRemote session
        // (bundleIdentifier + playing) without ever setting
        // navigator.mediaSession.metadata, so title/artist/album arrive as
        // empty strings rather than being omitted. The wire decoder must
        // still surface this as an active, controllable session rather than
        // collapsing it into "no session," matching the adapter's own
        // relaxed mandatoryPayloadKeys (processIdentifier + playing only).
        let line = Data(
            #"""
            {"type":"data","diff":false,"payload":{
              "bundleIdentifier":"ru.yandex.desktop.yandex-browser",
              "playing":true,
              "title":"",
              "artist":"",
              "album":"",
              "durationMicros":8150355000,
              "elapsedTimeMicros":6980505579
            }}
            """#.utf8
        )

        let decoded = try MediaRemoteWireDecoder.decode(line: line)
        let payload = try #require(decoded)

        #expect(payload.bundleIdentifier == "ru.yandex.desktop.yandex-browser")
        #expect(payload.playing)
        // The wire decoder passes text fields through as-is; normalizing an
        // empty string to nil happens one layer up, in
        // ShippingMediaPresentationProjection.make.
        #expect(payload.title == "")
        #expect(payload.artist == "")
        #expect(payload.album == "")
    }

    @Test
    func diffPayloadIsRejected() {
        let line = Data(
            #"{"type":"data","diff":true,"payload":{"bundleIdentifier":"player","playing":true,"title":"Track"}}"#.utf8
        )

        #expect(throws: MediaRemoteWireDecoderError.diffPayloadNotAllowed) {
            try MediaRemoteWireDecoder.decode(line: line)
        }
    }

    @Test
    func activePayloadRequiresBundleIdentifierAndPlayingState() {
        let missingBundle = Data(
            #"{"type":"data","diff":false,"payload":{"playing":true,"title":"Track"}}"#.utf8
        )
        let missingPlaying = Data(
            #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"player","title":"Track"}}"#.utf8
        )

        #expect(throws: MediaRemoteWireDecoderError.invalidPayload) {
            try MediaRemoteWireDecoder.decode(line: missingBundle)
        }
        #expect(throws: MediaRemoteWireDecoderError.invalidPayload) {
            try MediaRemoteWireDecoder.decode(line: missingPlaying)
        }
    }

    @Test
    func oversizedLineIsRejectedBeforeJSONDecode() {
        let line = Data(repeating: 0x61, count: MediaRemoteWireDecoder.maximumLineBytes + 1)
        #expect(throws: MediaRemoteWireDecoderError.lineTooLarge) {
            try MediaRemoteWireDecoder.decode(line: line)
        }
    }

    @Test
    func oversizedTextFieldIsRejected() {
        let title = String(repeating: "x", count: MediaRemoteWireDecoder.maximumTextUTF8Bytes + 1)
        let line = Data(
            "{\"type\":\"data\",\"diff\":false,\"payload\":{\"bundleIdentifier\":\"player\",\"playing\":true,\"title\":\"\(title)\"}}".utf8
        )

        #expect(throws: MediaRemoteWireDecoderError.textTooLarge) {
            try MediaRemoteWireDecoder.decode(line: line)
        }
    }

    @Test
    func invalidOrOversizedArtworkIsRejected() {
        let invalid = Data(
            #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"player","playing":true,"artworkData":"%%%"}}"#.utf8
        )
        let artwork = Data(repeating: 0x41, count: MediaRemoteWireDecoder.maximumArtworkBytes + 1)
            .base64EncodedString()
        let oversizedJSON =
            "{\"type\":\"data\",\"diff\":false,\"payload\":{"
            + "\"bundleIdentifier\":\"player\",\"playing\":true,"
            + "\"artworkData\":\"\(artwork)\"}}"
        let oversized = Data(oversizedJSON.utf8)

        #expect(throws: MediaRemoteWireDecoderError.invalidArtwork) {
            try MediaRemoteWireDecoder.decode(line: invalid)
        }
        #expect(throws: MediaRemoteWireDecoderError.artworkTooLarge) {
            try MediaRemoteWireDecoder.decode(line: oversized)
        }
    }

    @Test
    func outOfRangeTimingAndPlaybackRateAreRejected() {
        let negativeDuration = Data(
            #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"player","playing":true,"durationMicros":-1}}"#.utf8
        )
        let tooLong = MediaRemoteWireDecoder.maximumDurationMicros + 1
        let oversizedDurationJSON =
            "{\"type\":\"data\",\"diff\":false,\"payload\":{"
            + "\"bundleIdentifier\":\"player\",\"playing\":true,"
            + "\"durationMicros\":\(tooLong)}}"
        let oversizedDuration = Data(oversizedDurationJSON.utf8)
        let excessiveRate = Data(
            #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"player","playing":true,"playbackRate":17}}"#.utf8
        )

        #expect(throws: MediaRemoteWireDecoderError.invalidNumericValue) {
            try MediaRemoteWireDecoder.decode(line: negativeDuration)
        }
        #expect(throws: MediaRemoteWireDecoderError.invalidNumericValue) {
            try MediaRemoteWireDecoder.decode(line: oversizedDuration)
        }
        #expect(throws: MediaRemoteWireDecoderError.invalidNumericValue) {
            try MediaRemoteWireDecoder.decode(line: excessiveRate)
        }
    }

    @Test
    func capabilitiesDecodeExactTriStateSchema() throws {
        let line = Data(#"{"next":"supported","previous":"unsupported","seek":"unknown"}"#.utf8)
        let capabilities = try MediaRemoteCapabilityDecoder.decode(line: line)

        #expect(capabilities.next == .supported)
        #expect(capabilities.previous == .unsupported)
        #expect(capabilities.seek == .unknown)
    }

    @Test
    func capabilitiesRejectMissingExtraOrUnknownValues() {
        let missing = Data(#"{"next":"supported","previous":"unsupported"}"#.utf8)
        let extra = Data(
            #"{"next":"supported","previous":"unsupported","seek":"unknown","volume":"supported"}"#.utf8
        )
        let unknown = Data(#"{"next":"maybe","previous":"unsupported","seek":"unknown"}"#.utf8)

        #expect(throws: MediaRemoteCapabilityDecoderError.invalidSchema) {
            try MediaRemoteCapabilityDecoder.decode(line: missing)
        }
        #expect(throws: MediaRemoteCapabilityDecoderError.invalidSchema) {
            try MediaRemoteCapabilityDecoder.decode(line: extra)
        }
        #expect(throws: MediaRemoteCapabilityDecoderError.invalidState) {
            try MediaRemoteCapabilityDecoder.decode(line: unknown)
        }
    }
}
