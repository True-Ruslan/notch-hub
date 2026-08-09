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
            let paths = try candidatePaths()
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
            FileHandle.standardError.write(Data("media transport candidate failed\n".utf8))
            Foundation.exit(EXIT_FAILURE)
        }
    }

    private static func candidatePaths() throws -> (
        scriptURL: URL,
        frameworkURL: URL,
        sourceCommit: String
    ) {
        let executableURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
        let contentsURL = executableURL.deletingLastPathComponent().deletingLastPathComponent()
        let resourcesURL = contentsURL.appendingPathComponent("Resources", isDirectory: true)
        let infoURL = contentsURL.appendingPathComponent("Info.plist", isDirectory: false)

        guard
            let infoData = try? Data(contentsOf: infoURL),
            let propertyList = try? PropertyListSerialization.propertyList(
                from: infoData,
                options: [],
                format: nil
            ),
            let info = propertyList as? [String: Any],
            let sourceCommit = info["NHSourceCommit"] as? String,
            sourceCommit.range(of: "^[0-9a-f]{40}$", options: .regularExpression) != nil
        else {
            throw ProductionMediaTransportCandidateError.invalidArguments
        }

        return (
            scriptURL: resourcesURL.appendingPathComponent("mediaremote-adapter.pl", isDirectory: false),
            frameworkURL: resourcesURL.appendingPathComponent(
                "MediaRemoteAdapter.framework",
                isDirectory: true
            ),
            sourceCommit: sourceCommit
        )
    }

    private static func writeJSON<T: Encodable>(_ value: T) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(value)
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }
}
