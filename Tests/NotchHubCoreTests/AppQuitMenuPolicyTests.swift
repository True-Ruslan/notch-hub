import Foundation
import Testing

struct AppQuitMenuPolicyTests {
    @Test
    func statusItemHostsADiscoverableQuitAction() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/AppDelegate.swift")

        #expect(source.contains("NSStatusBar.system.statusItem"))
        #expect(source.contains("NSMenu()"))
        #expect(source.contains("Quit"))
        #expect(source.contains("#selector(NSApplication.terminate"))
    }

    @Test
    func quitStillRunsExistingTerminationCleanup() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/AppDelegate.swift")

        #expect(source.contains("target = NSApp") || source.contains("target: NSApp"))
        let occurrences = source.components(separatedBy: "func applicationWillTerminate").count - 1
        #expect(occurrences == 1)
    }

    @Test
    func statusItemAddsNoNewEntitlementOrPermission() throws {
        let plist = try propertyList(relativePath: "Resources/NotchHub.entitlements")

        #expect(Set(plist.keys) == ["com.apple.security.app-sandbox"])
        #expect(plist["com.apple.security.app-sandbox"] as? Bool == true)
    }

    @Test
    func appRemainsAccessoryWithNoDockIconRegression() throws {
        let infoPlistSource = try sourceText(relativePath: "Resources/Info.plist")
        #expect(infoPlistSource.contains("<key>LSUIElement</key>"))

        let appDelegateSource = try sourceText(relativePath: "Sources/NotchHubApp/AppDelegate.swift")
        #expect(appDelegateSource.contains("NSApp.setActivationPolicy(.accessory)"))
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
