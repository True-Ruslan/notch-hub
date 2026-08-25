import Foundation
import Testing
@testable import NotchHubMediaCore

struct ShippingMediaBundlePathsTests {
    private let adapterCommit = "3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
    private let patchSHA256 = "21730c7216814000213a3276777f2b471354f5d7f59019631da0a2917845545f"

    @Test
    func resolvesOnlyPinnedResourcesInsideShippingBundle() throws {
        let bundleURL = URL(fileURLWithPath: "/tmp/NotchHub.app", isDirectory: true)
        let resourcesURL =
            bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
        let sourceCommit = String(repeating: "a", count: 40)

        let paths = try ShippingMediaBundlePaths.resolve(
            bundleURL: bundleURL,
            resourceURL: resourcesURL,
            sourceCommit: sourceCommit,
            adapterCommit: adapterCommit,
            adapterPatchSHA256: patchSHA256
        )

        #expect(paths.sourceCommit == sourceCommit)
        #expect(paths.adapterCommit == adapterCommit)
        #expect(paths.adapterPatchSHA256 == patchSHA256)
        #expect(
            paths.scriptURL
                == resourcesURL.appendingPathComponent("mediaremote-adapter.pl", isDirectory: false)
        )
        #expect(
            paths.frameworkURL
                == resourcesURL.appendingPathComponent(
                    "MediaRemoteAdapter.framework",
                    isDirectory: true
                )
        )
    }

    @Test
    func rejectsWrongBundleShapeOrProvenance() {
        let bundleURL = URL(fileURLWithPath: "/tmp/NotchHub.app", isDirectory: true)
        let resourcesURL =
            bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
        let sourceCommit = String(repeating: "a", count: 40)

        #expect(throws: ShippingMediaBundleError.invalidBundle) {
            try ShippingMediaBundlePaths.resolve(
                bundleURL: URL(fileURLWithPath: "/tmp/NotchHub", isDirectory: true),
                resourceURL: resourcesURL,
                sourceCommit: sourceCommit,
                adapterCommit: adapterCommit,
                adapterPatchSHA256: patchSHA256
            )
        }

        #expect(throws: ShippingMediaBundleError.invalidBundle) {
            try ShippingMediaBundlePaths.resolve(
                bundleURL: bundleURL,
                resourceURL: nil,
                sourceCommit: sourceCommit,
                adapterCommit: adapterCommit,
                adapterPatchSHA256: patchSHA256
            )
        }

        for malformedSource in [nil, "", "abc", String(repeating: "A", count: 40)] {
            #expect(throws: ShippingMediaBundleError.invalidProvenance) {
                try ShippingMediaBundlePaths.resolve(
                    bundleURL: bundleURL,
                    resourceURL: resourcesURL,
                    sourceCommit: malformedSource,
                    adapterCommit: adapterCommit,
                    adapterPatchSHA256: patchSHA256
                )
            }
        }

        #expect(throws: ShippingMediaBundleError.invalidProvenance) {
            try ShippingMediaBundlePaths.resolve(
                bundleURL: bundleURL,
                resourceURL: resourcesURL,
                sourceCommit: sourceCommit,
                adapterCommit: String(repeating: "b", count: 40),
                adapterPatchSHA256: patchSHA256
            )
        }

        #expect(throws: ShippingMediaBundleError.invalidProvenance) {
            try ShippingMediaBundlePaths.resolve(
                bundleURL: bundleURL,
                resourceURL: resourcesURL,
                sourceCommit: sourceCommit,
                adapterCommit: adapterCommit,
                adapterPatchSHA256: String(repeating: "0", count: 64)
            )
        }
    }
}
