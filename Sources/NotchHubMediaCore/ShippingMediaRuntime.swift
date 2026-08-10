import Foundation

enum ShippingMediaBundleError: Error, Equatable {
    case invalidBundle
    case invalidProvenance
    case missingResources
}

struct ShippingMediaBundlePaths: Equatable, Sendable {
    static let pinnedAdapterCommit = "3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
    static let pinnedAdapterPatchSHA256 =
        "f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974"

    let scriptURL: URL
    let frameworkURL: URL
    let sourceCommit: String
    let adapterCommit: String
    let adapterPatchSHA256: String

    static func resolve(
        bundleURL: URL,
        resourceURL: URL?,
        sourceCommit: String?,
        adapterCommit: String?,
        adapterPatchSHA256: String?
    ) throws -> Self {
        let normalizedBundleURL = bundleURL.standardizedFileURL
        let expectedResourceURL =
            normalizedBundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
            .standardizedFileURL

        guard
            normalizedBundleURL.pathExtension == "app",
            let resourceURL,
            resourceURL.standardizedFileURL == expectedResourceURL
        else {
            throw ShippingMediaBundleError.invalidBundle
        }

        guard
            let sourceCommit,
            sourceCommit.range(of: "^[0-9a-f]{40}$", options: .regularExpression) != nil,
            adapterCommit == pinnedAdapterCommit,
            adapterPatchSHA256 == pinnedAdapterPatchSHA256
        else {
            throw ShippingMediaBundleError.invalidProvenance
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
            sourceCommit: sourceCommit,
            adapterCommit: pinnedAdapterCommit,
            adapterPatchSHA256: pinnedAdapterPatchSHA256
        )
    }
}
