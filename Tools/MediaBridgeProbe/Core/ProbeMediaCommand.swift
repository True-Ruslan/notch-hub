import Foundation

public enum ProbeMediaCommandError: Error, Equatable {
    case seekOutOfRange
}

public enum ProbeMediaCommand: Equatable, Sendable {
    case togglePlayPause
    case next
    case previous
    case seek(microseconds: UInt64)

    public func validated() throws -> ProbeMediaCommand {
        if case .seek(let microseconds) = self {
            guard
                microseconds > 0,
                microseconds <= ProbePayloadDecoder.maximumDurationMicros
            else {
                throw ProbeMediaCommandError.seekOutOfRange
            }
        }

        return self
    }

    public func adapterArguments(
        scriptURL: URL,
        frameworkURL: URL,
        testClientURL: URL
    ) throws -> [String] {
        let command = try validated()
        let prefix = [scriptURL.path, frameworkURL.path, testClientURL.path]

        switch command {
        case .togglePlayPause:
            return prefix + ["send", "2"]
        case .next:
            return prefix + ["send", "4"]
        case .previous:
            return prefix + ["send", "5"]
        case .seek(let microseconds):
            return prefix + ["seek", String(microseconds)]
        }
    }
}
