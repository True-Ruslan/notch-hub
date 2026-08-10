import Foundation

struct MediaRemoteWirePayload: Sendable {
    let bundleIdentifier: String
    let playing: Bool
    let title: String?
    let artist: String?
    let album: String?
    let durationSeconds: Double?
    let positionSeconds: Double?
    let referenceDate: Date?
    let playbackRate: Double?
    let artworkData: Data?
    let contentIdentifier: String?
    let uniqueIdentifier: String?
}

enum MediaRemoteWireDecoderError: Error, Equatable {
    case lineTooLarge
    case invalidEnvelope
    case diffPayloadNotAllowed
    case invalidPayload
    case textTooLarge
    case invalidArtwork
    case artworkTooLarge
    case invalidNumericValue
}

enum MediaRemoteWireDecoder {
    static let maximumLineBytes = 8 * 1024 * 1024
    static let maximumArtworkBytes = 4 * 1024 * 1024
    static let maximumTextUTF8Bytes = 16 * 1024
    static let maximumDurationMicros: Int64 = 30 * 24 * 60 * 60 * 1_000_000
    static let maximumPlaybackRate = 16.0

    static func decode(line: Data) throws -> MediaRemoteWirePayload? {
        guard line.count <= maximumLineBytes else {
            throw MediaRemoteWireDecoderError.lineTooLarge
        }

        let envelope: MediaRemoteWireEnvelope
        do {
            envelope = try JSONDecoder().decode(MediaRemoteWireEnvelope.self, from: line)
        } catch {
            throw MediaRemoteWireDecoderError.invalidEnvelope
        }

        guard envelope.type == "data", let payload = envelope.payload else {
            throw MediaRemoteWireDecoderError.invalidEnvelope
        }
        guard !envelope.diff else {
            throw MediaRemoteWireDecoderError.diffPayloadNotAllowed
        }

        if payload.isEmpty {
            return nil
        }

        guard
            let reportedBundleIdentifier = payload.bundleIdentifier,
            let playing = payload.playing
        else {
            throw MediaRemoteWireDecoderError.invalidPayload
        }

        let bundleIdentifier = payload.parentApplicationBundleIdentifier ?? reportedBundleIdentifier
        guard !bundleIdentifier.isEmpty else {
            throw MediaRemoteWireDecoderError.invalidPayload
        }

        try validateText(bundleIdentifier)
        try validateText(reportedBundleIdentifier)
        try validateOptionalText(payload.parentApplicationBundleIdentifier)
        try validateOptionalText(payload.title)
        try validateOptionalText(payload.artist)
        try validateOptionalText(payload.album)
        try validateOptionalText(payload.artworkMimeType)
        try validateOptionalText(payload.contentItemIdentifier)
        try validateOptionalText(payload.uniqueIdentifier)

        let durationSeconds = try seconds(fromMicros: payload.durationMicros)
        let positionSeconds = try seconds(fromMicros: payload.elapsedTimeMicros)
        let referenceDate = try date(fromEpochMicros: payload.timestampEpochMicros)

        if let playbackRate = payload.playbackRate {
            guard
                playbackRate.isFinite,
                abs(playbackRate) <= maximumPlaybackRate
            else {
                throw MediaRemoteWireDecoderError.invalidNumericValue
            }
        }

        let artworkData: Data?
        if let encodedArtwork = payload.artworkData {
            guard let decodedArtwork = Data(base64Encoded: encodedArtwork) else {
                throw MediaRemoteWireDecoderError.invalidArtwork
            }
            guard decodedArtwork.count <= maximumArtworkBytes else {
                throw MediaRemoteWireDecoderError.artworkTooLarge
            }
            artworkData = decodedArtwork
        } else {
            artworkData = nil
        }

        return MediaRemoteWirePayload(
            bundleIdentifier: bundleIdentifier,
            playing: playing,
            title: payload.title,
            artist: payload.artist,
            album: payload.album,
            durationSeconds: durationSeconds,
            positionSeconds: positionSeconds,
            referenceDate: referenceDate,
            playbackRate: payload.playbackRate,
            artworkData: artworkData,
            contentIdentifier: payload.contentItemIdentifier,
            uniqueIdentifier: payload.uniqueIdentifier
        )
    }

    private static func seconds(fromMicros value: Int64?) throws -> Double? {
        guard let value else {
            return nil
        }
        guard value >= 0, value <= maximumDurationMicros else {
            throw MediaRemoteWireDecoderError.invalidNumericValue
        }
        return Double(value) / 1_000_000
    }

    private static func date(fromEpochMicros value: Int64?) throws -> Date? {
        guard let value else {
            return nil
        }
        guard value >= 0 else {
            throw MediaRemoteWireDecoderError.invalidNumericValue
        }

        let seconds = Double(value) / 1_000_000
        guard seconds.isFinite else {
            throw MediaRemoteWireDecoderError.invalidNumericValue
        }
        return Date(timeIntervalSince1970: seconds)
    }

    private static func validateOptionalText(_ value: String?) throws {
        if let value {
            try validateText(value)
        }
    }

    private static func validateText(_ value: String) throws {
        guard value.utf8.count <= maximumTextUTF8Bytes else {
            throw MediaRemoteWireDecoderError.textTooLarge
        }
    }
}

enum MediaRemoteCapabilityDecoderError: Error, Equatable {
    case invalidSchema
    case invalidState
}

enum MediaRemoteCapabilityDecoder {
    private static let expectedKeys: Set<String> = ["next", "previous", "seek"]
    private static let maximumLineBytes = 4 * 1024

    static func decode(line: Data) throws -> MediaCommandCapabilities {
        guard line.count <= maximumLineBytes else {
            throw MediaRemoteCapabilityDecoderError.invalidSchema
        }

        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: line)
        } catch {
            throw MediaRemoteCapabilityDecoderError.invalidSchema
        }

        guard let dictionary = object as? [String: Any], Set(dictionary.keys) == expectedKeys else {
            throw MediaRemoteCapabilityDecoderError.invalidSchema
        }
        guard
            let previous = dictionary["previous"] as? String,
            let next = dictionary["next"] as? String,
            let seek = dictionary["seek"] as? String
        else {
            throw MediaRemoteCapabilityDecoderError.invalidSchema
        }

        return MediaCommandCapabilities(
            previous: try state(from: previous),
            next: try state(from: next),
            seek: try state(from: seek)
        )
    }

    private static func state(from value: String) throws -> MediaCapabilityState {
        switch value {
        case "supported":
            return .supported
        case "unsupported":
            return .unsupported
        case "unknown":
            return .unknown
        default:
            throw MediaRemoteCapabilityDecoderError.invalidState
        }
    }
}

private struct MediaRemoteWireEnvelope: Decodable {
    let type: String
    let diff: Bool
    let payload: MediaRemoteWirePayloadContainer?
}

private struct MediaRemoteWirePayloadContainer: Decodable {
    let bundleIdentifier: String?
    let parentApplicationBundleIdentifier: String?
    let playing: Bool?
    let title: String?
    let artist: String?
    let album: String?
    let durationMicros: Int64?
    let elapsedTimeMicros: Int64?
    let timestampEpochMicros: Int64?
    let playbackRate: Double?
    let artworkMimeType: String?
    let artworkData: String?
    let contentItemIdentifier: String?
    let uniqueIdentifier: String?

    var isEmpty: Bool {
        bundleIdentifier == nil
            && parentApplicationBundleIdentifier == nil
            && playing == nil
            && title == nil
            && artist == nil
            && album == nil
            && durationMicros == nil
            && elapsedTimeMicros == nil
            && timestampEpochMicros == nil
            && playbackRate == nil
            && artworkMimeType == nil
            && artworkData == nil
            && contentItemIdentifier == nil
            && uniqueIdentifier == nil
    }
}
