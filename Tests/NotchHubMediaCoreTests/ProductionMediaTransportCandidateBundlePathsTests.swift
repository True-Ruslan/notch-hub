import Foundation
import Testing
@testable import NotchHubMediaCore

struct ProductionMediaTransportCandidateBundlePathsTests {
    @Test
    func resolvesOnlyCandidateResourcesFromBundleInputs() throws {
        let bundleURL = URL(
            fileURLWithPath: "/tmp/ProductionMediaTransportCandidate.app",
            isDirectory: true
        )
        let resourcesURL = bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
        let sourceCommit = String(repeating: "a", count: 40)

        let paths = try ProductionMediaTransportCandidateBundlePaths.resolve(
            bundleURL: bundleURL,
            resourceURL: resourcesURL,
            sourceCommit: sourceCommit
        )

        #expect(paths.sourceCommit == sourceCommit)
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
    func rejectsMissingResourcesAndMalformedSourceProvenance() {
        let bundleURL = URL(
            fileURLWithPath: "/tmp/ProductionMediaTransportCandidate.app",
            isDirectory: true
        )
        let resourcesURL = bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)

        #expect(throws: ProductionMediaTransportCandidateError.invalidArguments) {
            try ProductionMediaTransportCandidateBundlePaths.resolve(
                bundleURL: bundleURL,
                resourceURL: nil,
                sourceCommit: String(repeating: "a", count: 40)
            )
        }

        for sourceCommit in [nil, "", "abc", String(repeating: "A", count: 40), String(repeating: "a", count: 39)] {
            #expect(throws: ProductionMediaTransportCandidateError.invalidArguments) {
                try ProductionMediaTransportCandidateBundlePaths.resolve(
                    bundleURL: bundleURL,
                    resourceURL: resourcesURL,
                    sourceCommit: sourceCommit
                )
            }
        }
    }
}
