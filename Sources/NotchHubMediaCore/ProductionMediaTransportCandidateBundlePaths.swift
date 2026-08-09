import Foundation

public struct ProductionMediaTransportCandidateBundlePaths: Equatable, Sendable {
    public let scriptURL: URL
    public let frameworkURL: URL
    public let sourceCommit: String

    public static func resolve(
        bundleURL: URL,
        resourceURL: URL?,
        sourceCommit: String?
    ) throws -> Self {
        let normalizedBundleURL = bundleURL.standardizedFileURL
        let expectedResourceURL = normalizedBundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
            .standardizedFileURL

        guard
            normalizedBundleURL.pathExtension == "app",
            let resourceURL,
            resourceURL.standardizedFileURL == expectedResourceURL,
            let sourceCommit,
            sourceCommit.range(of: "^[0-9a-f]{40}$", options: .regularExpression) != nil
        else {
            throw ProductionMediaTransportCandidateError.invalidArguments
        }

        return Self(
            scriptURL: expectedResourceURL.appendingPathComponent(
                "mediaremote-adapter.pl",
                isDirectory: false
            ),
            frameworkURL: expectedResourceURL.appendingPathComponent(
                "MediaRemoteAdapter.framework",
                isDirectory: true
            ),
            sourceCommit: sourceCommit
        )
    }
}
