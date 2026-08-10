import Foundation
import NotchHubMediaCore

private struct CandidateCommandResult: Codable {
    let sent: Bool
}

@main
@MainActor
struct MediaTransportCandidateMain {
    static func main() async {
        do {
            let invocation = try ProductionMediaTransportCandidateInvocation.parse(
                arguments: Array(CommandLine.arguments.dropFirst())
            )
            let paths = try ProductionMediaTransportCandidateBundlePaths.resolve(
                bundleURL: Bundle.main.bundleURL,
                resourceURL: Bundle.main.resourceURL,
                sourceCommit: Bundle.main.object(forInfoDictionaryKey: "NHSourceCommit") as? String
            )
            let runner = ProductionMediaTransportCandidateRunner(
                scriptURL: paths.scriptURL,
                frameworkURL: paths.frameworkURL,
                sourceCommit: paths.sourceCommit
            )

            switch invocation {
            case .capabilities:
                try writeJSON(try await runner.capabilities())
            case .observe(let seconds):
                try writeJSON(try await runner.observe(seconds: seconds))
            case .send(let command):
                try writeJSON(CandidateCommandResult(sent: await runner.send(command)))
            }
        } catch {
            let code = ProductionMediaTransportCandidateFailureCode.classify(error)
            FileHandle.standardError.write(
                Data("media transport candidate failed: \(code.rawValue)\n".utf8)
            )
            Foundation.exit(EXIT_FAILURE)
        }
    }

    private static func writeJSON<T: Encodable>(_ value: T) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(value)
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }
}
