import Foundation
import Testing

struct ShelfSecurityPolicyTests {
    private let expectedShippingEntitlements: Set<String> = [
        "com.apple.security.app-sandbox",
        "com.apple.security.files.user-selected.read-only"
    ]

    @Test
    func shippingShelfEntitlementsAreExactlySandboxPlusUserSelectedReadOnly() throws {
        let plist = try propertyList(relativePath: "Resources/NotchHub.entitlements")

        #expect(Set(plist.keys) == expectedShippingEntitlements)
        #expect(plist["com.apple.security.app-sandbox"] as? Bool == true)
        #expect(plist["com.apple.security.files.user-selected.read-only"] as? Bool == true)
    }

    @Test
    func shippingShelfAddsNoBroadWriteNetworkOrAutomationAuthority() throws {
        let plist = try propertyList(relativePath: "Resources/NotchHub.entitlements")
        let forbidden = [
            "com.apple.security.files.user-selected.read-write",
            "com.apple.security.files.downloads.read-write",
            "com.apple.security.files.downloads.read-only",
            "com.apple.security.files.all",
            "com.apple.security.network.client",
            "com.apple.security.network.server",
            "com.apple.security.automation.apple-events",
            "com.apple.security.device.camera",
            "com.apple.security.device.microphone",
            "com.apple.security.device.bluetooth"
        ]

        for key in forbidden {
            #expect(plist[key] == nil)
        }
    }

    @Test
    func shippingSecurityAndPackagingGatesAssertTheReadOnlyEntitlement() throws {
        let securityAudit = try sourceText(relativePath: "scripts/security-audit.sh")
        let shippingAcceptance = try sourceText(relativePath: "scripts/shipping_media_acceptance.py")
        let ci = try sourceText(relativePath: ".github/workflows/ci.yml")
        let personalRelease = try sourceText(relativePath: ".github/workflows/personal-release.yml")
        let trustedRelease = try sourceText(relativePath: ".github/workflows/trusted-release.yml")

        for source in [securityAudit, shippingAcceptance, ci, personalRelease, trustedRelease] {
            #expect(source.contains("com.apple.security.files.user-selected.read-only"))
        }
    }

    @Test
    func shelfResourceActionsFailClosedAndDoNotAcquireScopeDuringIdle() throws {
        let shelf = try sourceText(relativePath: "Sources/NotchHubApp/Shelf/ShelfView.swift")
        let store = try sourceText(relativePath: "Sources/NotchHubCore/Shelf/ShelfStore.swift")

        #expect(shelf.contains("startAccessingSecurityScopedResource()"))
        #expect(shelf.contains("stopAccessingSecurityScopedResource()"))
        #expect(shelf.contains("guard didStartAccess else"))
        #expect(!store.contains("startAccessingSecurityScopedResource"))
        #expect(!store.contains("stopAccessingSecurityScopedResource"))
    }

    @Test
    func staleBookmarkRefreshUsesShortLivedSecurityScope() throws {
        let codec = try sourceText(relativePath: "Sources/NotchHubCore/Shelf/ShelfBookmarkCodec.swift")

        #expect(codec.contains("if isStale"))
        #expect(codec.contains("startAccessingSecurityScopedResource()"))
        #expect(codec.contains("stopAccessingSecurityScopedResource()"))
        #expect(codec.contains("guard didStartAccess else"))
    }

    private func propertyList(relativePath: String) throws -> [String: Any] {
        let data = try Data(contentsOf: repositoryRoot().appendingPathComponent(relativePath))
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        return try #require(plist as? [String: Any])
    }

    private func sourceText(relativePath: String) throws -> String {
        try String(
            contentsOf: repositoryRoot().appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }

    private func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
