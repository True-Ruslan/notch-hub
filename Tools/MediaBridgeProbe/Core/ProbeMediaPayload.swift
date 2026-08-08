import Foundation

public struct ProbeMediaPayload: Equatable, Sendable {
    public let bundleIdentifier: String
    public let playing: Bool
    public let title: String
    public let artist: String?
    public let album: String?
    public let durationMicros: UInt64?
    public let elapsedTimeMicros: UInt64?
    public let timestampEpochMicros: UInt64?
    public let playbackRate: Double?
    public let artworkMimeType: String?
    public let artworkByteCount: Int
    public let prohibitsSkip: Bool?
}

public enum ProbePayloadDecoderError: Error, Equatable {
    case lineTooLarge
    case invalidEnvelope
    case diffPayloadNotAllowed
    case invalidPayload
    case textTooLarge
    case invalidArtworkEncoding
    case artworkTooLarge
    case durationOutOfRange
    case elapsedTimeOutOfRange
    case playbackRateOutOfRange
}

public enum ProbePayloadDecoder {
    public static let maximumLineBytes = 8 * 1024 * 1024
    public static let maximumArtworkBytes = 4 * 1024 * 1024
    public static let maximumTextUTF8Bytes = 16 * 1024
    public static let maximumDurationMicros: UInt64 = 30 * 24 * 60 * 60 * 1_000_000
    public static let maximumPlaybackRate = 16.0

    public static func decode(line: Data) throws -> ProbeMediaPayload? {
        guard line.count <= maximumLineBytes else {
            throw ProbePayloadDecoderError.lineTooLarge
        }

        let envelope: WireEnvelope
        do {
            envelope = try JSONDecoder().decode(WireEnvelope.self, from: line)
        } catch {
            throw ProbePayloadDecoderError.invalidEnvelope
        }

        guard envelope.type == "data", let payload = envelope.payload else {
            throw ProbePayloadDecoderError.invalidEnvelope
        }
        guard envelope.diff == false else {
            throw ProbePayloadDecoderError.diffPayloadNotAllowed
        }

        if payload.isEmpty {
            return nil
        }

        guard
            let bundleIdentifier = payload.bundleIdentifier,
            let playing = payload.playing,
            let title = payload.title
        else {
            throw ProbePayloadDecoderError.invalidPayload
        }

        try validateText(bundleIdentifier)
        try validateText(title)
        try validateOptionalText(payload.artist)
        try validateOptionalText(payload.album)
        try validateOptionalText(payload.artworkMimeType)

        if let durationMicros = payload.durationMicros,
           durationMicros > maximumDurationMicros
        {
            throw ProbePayloadDecoderError.durationOutOfRange
        }

        if let elapsedTimeMicros = payload.elapsedTimeMicros,
           elapsedTimeMicros > maximumDurationMicros
        {
            throw ProbePayloadDecoderError.elapsedTimeOutOfRange
        }

        if let playbackRate = payload.playbackRate,
           !playbackRate.isFinite || abs(playbackRate) > maximumPlaybackRate
        {
            throw ProbePayloadDecoderError.playbackRateOutOfRange
        }

        let artworkByteCount: Int
        if let artworkData = payload.artworkData {
            guard let decodedArtwork = Data(base64Encoded: artworkData) else {
                throw ProbePayloadDecoderError.invalidArtworkEncoding
            }
            guard decodedArtwork.count <= maximumArtworkBytes else {
                throw ProbePayloadDecoderError.artworkTooLarge
            }
            artworkByteCount = decodedArtwork.count
        } else {
            artworkByteCount = 0
        }

        return ProbeMediaPayload(
            bundleIdentifier: bundleIdentifier,
            playing: playing,
            title: title,
            artist: payload.artist,
            album: payload.album,
            durationMicros: payload.durationMicros,
            elapsedTimeMicros: payload.elapsedTimeMicros,
            timestampEpochMicros: payload.timestampEpochMicros,
            playbackRate: payload.playbackRate,
            artworkMimeType: payload.artworkMimeType,
            artworkByteCount: artworkByteCount,
            prohibitsSkip: payload.prohibitsSkip
        )
    }

    private static func validateOptionalText(_ value: String?) throws {
        if let value {
            try validateText(value)
        }
    }

    private static func validateText(_ value: String) throws {
        guard value.utf8.count <= maximumTextUTF8Bytes else {
            throw ProbePayloadDecoderError.textTooLarge
        }
    }
}

private struct WireEnvelope: Decodable {
    let type: String
    let diff: Bool
    let payload: WirePayload?
}

private struct WirePayload: Decodable {
    let bundleIdentifier: String?
    let playing: Bool?
    let title: String?
    let artist: String?
    let album: String?
    let durationMicros: UInt64?
    let elapsedTimeMicros: UInt64?
    let timestampEpochMicros: UInt64?
    let playbackRate: Double?
    let artworkMimeType: String?
    let artworkData: String?
    let prohibitsSkip: Bool?

    var isEmpty: Bool {
        bundleIdentifier == nil
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
            && prohibitsSkip == nil
    }
}
