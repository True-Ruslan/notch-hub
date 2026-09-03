import Foundation
import Testing

struct SettingsMenuPolicyTests {
    @Test
    func statusItemHostsADiscoverableSettingsAction() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/AppDelegate.swift")

        #expect(source.contains("Settings…"))
        #expect(source.contains("#selector(openSettings)"))
        #expect(source.contains("@objc private func openSettings()"))
    }

    @Test
    func settingsItemIsPositionedAboveTheQuitItem() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/AppDelegate.swift")

        let settingsRange = try #require(source.range(of: "Settings…"))
        let quitRange = try #require(source.range(of: "\"Quit NotchHub\""))
        #expect(settingsRange.lowerBound < quitRange.lowerBound)
    }

    @Test
    func openSettingsUsesAnOrdinaryTitledWindowNotTheNotchPanel() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/AppDelegate.swift")

        let openSettingsBody = try #require(
            source.range(of: "@objc private func openSettings()")
        )
        let remainder = source[openSettingsBody.upperBound...]
        let nextFunctionStart =
            remainder.range(of: "\n    func applicationWillTerminate")?.lowerBound
            ?? remainder.endIndex
        let body = remainder[remainder.startIndex..<nextFunctionStart]

        #expect(body.contains(".titled"))
        #expect(body.contains(".closable"))
        #expect(body.contains("NSApp.activate(ignoringOtherApps: true)"))
    }

    @Test
    func settingsAddsNoNewEntitlement() throws {
        let plist = try propertyList(relativePath: "Resources/NotchHub.entitlements")

        #expect(Set(plist.keys) == ["com.apple.security.app-sandbox"])
        #expect(plist["com.apple.security.app-sandbox"] as? Bool == true)
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
