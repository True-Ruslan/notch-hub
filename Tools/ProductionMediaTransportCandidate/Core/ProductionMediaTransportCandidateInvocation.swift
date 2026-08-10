import Foundation
import NotchHubMediaCore

enum ProductionMediaTransportCandidateLimits {
    static let maximumObservationSeconds: TimeInterval = 1_200
    static let maximumSeekSeconds = MediaCandidateRuntime.maximumSeekSeconds
}

public enum ProductionMediaTransportCandidateInvocation: Equatable, Sendable {
    case capabilities
    case observe(seconds: TimeInterval)
    case send(ProductionMediaTransportCandidateCommand)

    public static func parse(arguments: [String]) throws -> Self {
        if arguments == ["capabilities"] {
            return .capabilities
        }

        if arguments.count == 3,
            arguments[0] == "observe",
            arguments[1] == "--seconds"
        {
            guard
                let seconds = TimeInterval(arguments[2]),
                seconds.isFinite,
                seconds > 0,
                seconds <= ProductionMediaTransportCandidateLimits.maximumObservationSeconds
            else {
                throw ProductionMediaTransportCandidateError.invalidArguments
            }
            return .observe(seconds: seconds)
        }

        if arguments == ["send", "toggle"] {
            return .send(.toggle)
        }
        if arguments == ["send", "previous"] {
            return .send(.previous)
        }
        if arguments == ["send", "next"] {
            return .send(.next)
        }

        if arguments.count == 2, arguments[0] == "seek" {
            guard
                let seconds = Double(arguments[1]),
                seconds.isFinite,
                seconds > 0,
                seconds <= ProductionMediaTransportCandidateLimits.maximumSeekSeconds
            else {
                throw ProductionMediaTransportCandidateError.invalidArguments
            }
            return .send(.seek(seconds: seconds))
        }

        throw ProductionMediaTransportCandidateError.invalidArguments
    }
}
