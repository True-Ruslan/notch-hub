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
    let licenseURL: URL
    let provenanceURL: URL
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
            licenseURL: expectedResourceURL.appendingPathComponent(
                "MediaRemoteAdapter-LICENSE.txt",
                isDirectory: false
            ),
            provenanceURL: expectedResourceURL.appendingPathComponent(
                "media-transport-provenance.json",
                isDirectory: false
            ),
            sourceCommit: sourceCommit,
            adapterCommit: pinnedAdapterCommit,
            adapterPatchSHA256: pinnedAdapterPatchSHA256
        )
    }
}

@MainActor
public final class ShippingMediaRuntime {
    private let bundle: Bundle
    private let fileManager: FileManager
    private var controller: MediaSessionController?

    public convenience init() {
        self.init(bundle: .main)
    }

    init(bundle: Bundle, fileManager: FileManager = .default) {
        self.bundle = bundle
        self.fileManager = fileManager
    }

    public func start() {
        guard controller == nil else {
            return
        }

        guard let paths = try? resolveValidatedPaths() else {
            return
        }

        let transport = MediaRemoteSystemTransport(
            scriptURL: paths.scriptURL,
            frameworkURL: paths.frameworkURL
        )
        let bridge = SystemMediaBridge(transport: transport)
        let controller = MediaSessionController(provider: bridge)
        self.controller = controller
        controller.start()
    }

    public func stop() {
        controller?.stop()
        controller = nil
    }

    private func resolveValidatedPaths() throws -> ShippingMediaBundlePaths {
        let info = bundle.infoDictionary ?? [:]
        let paths = try ShippingMediaBundlePaths.resolve(
            bundleURL: bundle.bundleURL,
            resourceURL: bundle.resourceURL,
            sourceCommit: info["NHSourceCommit"] as? String,
            adapterCommit: info["NHAdapterCommit"] as? String,
            adapterPatchSHA256: info["NHAdapterPatchSHA256"] as? String
        )

        guard
            isFile(paths.scriptURL),
            isDirectory(paths.frameworkURL),
            isFile(paths.licenseURL),
            isFile(paths.provenanceURL)
        else {
            throw ShippingMediaBundleError.missingResources
        }

        let data = try Data(contentsOf: paths.provenanceURL, options: [.mappedIfSafe])
        let provenance = try JSONDecoder().decode(ShippingMediaProvenance.self, from: data)
        guard
            provenance.schemaVersion == 1,
            provenance.sourceCommit == paths.sourceCommit,
            provenance.adapterCommit == paths.adapterCommit,
            provenance.adapterPatchSHA256 == paths.adapterPatchSHA256
        else {
            throw ShippingMediaBundleError.invalidProvenance
        }

        return paths
    }

    private func isFile(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
            && !isDirectory.boolValue
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
            && isDirectory.boolValue
    }
}

private struct ShippingMediaProvenance: Decodable {
    let schemaVersion: Int
    let sourceCommit: String
    let adapterCommit: String
    let adapterPatchSHA256: String
}
