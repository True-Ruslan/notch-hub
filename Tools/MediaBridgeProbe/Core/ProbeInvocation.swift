public enum ProbeInvocationError: Error, Equatable {
    case invalidArguments
}

public enum ProbeInvocation: Equatable, Sendable {
    case observe(seconds: UInt64, reportPath: String)
    case command(ProbeMediaCommand)
    case selfTest

    public static let maximumObserveSeconds: UInt64 = 3_600

    public static func parse(arguments: [String]) throws -> ProbeInvocation {
        guard let command = arguments.first else {
            throw ProbeInvocationError.invalidArguments
        }

        switch command {
        case "self-test":
            guard arguments.count == 1 else {
                throw ProbeInvocationError.invalidArguments
            }
            return .selfTest

        case "send":
            guard arguments.count == 2 else {
                throw ProbeInvocationError.invalidArguments
            }

            switch arguments[1] {
            case "toggle":
                return .command(.togglePlayPause)
            case "next":
                return .command(.next)
            case "previous":
                return .command(.previous)
            default:
                throw ProbeInvocationError.invalidArguments
            }

        case "seek":
            guard
                arguments.count == 2,
                let microseconds = UInt64(arguments[1])
            else {
                throw ProbeInvocationError.invalidArguments
            }

            let mediaCommand = ProbeMediaCommand.seek(microseconds: microseconds)
            do {
                return .command(try mediaCommand.validated())
            } catch {
                throw ProbeInvocationError.invalidArguments
            }

        case "observe":
            guard
                arguments.count == 5,
                arguments[1] == "--seconds",
                let seconds = UInt64(arguments[2]),
                seconds > 0,
                seconds <= maximumObserveSeconds,
                arguments[3] == "--report",
                !arguments[4].isEmpty
            else {
                throw ProbeInvocationError.invalidArguments
            }

            return .observe(seconds: seconds, reportPath: arguments[4])

        default:
            throw ProbeInvocationError.invalidArguments
        }
    }
}
