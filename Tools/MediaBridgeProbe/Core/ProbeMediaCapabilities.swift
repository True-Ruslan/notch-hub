import Foundation

public enum ProbeCapabilityState: String, Codable, Equatable, Sendable {
    case supported
    case unsupported
    case unknown
}

public struct ProbeMediaCapabilities: Codable, Equatable, Sendable {
    public let next: ProbeCapabilityState
    public let previous: ProbeCapabilityState
    public let seek: ProbeCapabilityState

    public init(
        next: ProbeCapabilityState,
        previous: ProbeCapabilityState,
        seek: ProbeCapabilityState
    ) {
        self.next = next
        self.previous = previous
        self.seek = seek
    }
}

public enum ProbeMediaCapabilitiesDecoderError: Error, Equatable {
    case lineTooLarge
    case invalidPayload
}

public enum ProbeMediaCapabilitiesDecoder {
    public static let maximumLineBytes = 1_024

    public static func decode(line: Data) throws -> ProbeMediaCapabilities {
        guard line.count <= maximumLineBytes else {
            throw ProbeMediaCapabilitiesDecoderError.lineTooLarge
        }

        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: line)
        } catch {
            throw ProbeMediaCapabilitiesDecoderError.invalidPayload
        }

        guard
            let dictionary = object as? [String: Any],
            Set(dictionary.keys) == Set(["next", "previous", "seek"]),
            let nextRaw = dictionary["next"] as? String,
            let previousRaw = dictionary["previous"] as? String,
            let seekRaw = dictionary["seek"] as? String,
            let next = ProbeCapabilityState(rawValue: nextRaw),
            let previous = ProbeCapabilityState(rawValue: previousRaw),
            let seek = ProbeCapabilityState(rawValue: seekRaw)
        else {
            throw ProbeMediaCapabilitiesDecoderError.invalidPayload
        }

        return ProbeMediaCapabilities(
            next: next,
            previous: previous,
            seek: seek
        )
    }
}
