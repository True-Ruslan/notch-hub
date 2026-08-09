import Foundation

public enum ProductionMediaTransportCandidateInvocation: Equatable, Sendable {
    case capabilities
    case observe(seconds: TimeInterval)
    case send(ProductionMediaTransportCandidateCommand)

    public static func parse(arguments: [String]) throws -> Self {
        switch arguments {
        case ["capabilities"]:
            return .capabilities
        case ["observe", "--seconds", let rawSeconds]:
            guard
                let seconds = TimeInterval(rawSeconds),
                seconds.isFinite,
                seconds > 0,
                seconds <= ProductionMediaTransportCandidateRunner.maximumObservationSeconds
            else {
                throw ProductionMediaTransportCandidateError.invalidArguments
            }
            return .observe(seconds: seconds)
        case ["send", "toggle"]:
            return .send(.toggle)
        case ["send", "previous"]:
            return .send(.previous)
        case ["send", "next"]:
            return .send(.next)
        case ["seek", let rawSeconds]:
            guard
                let seconds = Double(rawSeconds),
                seconds.isFinite,
                seconds > 0,
                seconds <= MediaRemoteProcessClient.maximumSeekSeconds
            else {
                throw ProductionMediaTransportCandidateError.invalidArguments
            }
            return .send(.seek(seconds: seconds))
        default:
            throw ProductionMediaTransportCandidateError.invalidArguments
        }
    }
}
