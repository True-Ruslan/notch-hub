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
    func uiTestBuildsIsolateSettingsStoreFromTheRealUserDefaultsDomain() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/AppDelegate.swift")

        let settingsStoreDeclaration = try #require(
            source.range(of: "private let settingsStore: NotchHubSettingsStore = {")
        )
        let remainder = source[settingsStoreDeclaration.upperBound...]
        let declarationEnd =
            remainder.range(of: "\n    }()")?.upperBound ?? remainder.endIndex
        let body = remainder[remainder.startIndex..<declarationEnd]

        #expect(body.contains("#if NOTCHHUB_UI_TESTING"))
        #expect(body.contains("UserDefaults(suiteName:"))
        #expect(body.contains("removePersistentDomain(forName:"))
        #expect(body.contains(".standard"))
    }

    @Test
    func settingsControlsExposeStableAccessibilityIdentifiersForUITesting() throws {
        let statusItemMenu = try sourceText(relativePath: "Sources/NotchHubApp/AppDelegate.swift")
        let settingsRoot = try sourceText(
            relativePath: "Sources/NotchHubApp/Settings/SettingsRootView.swift"
        )

        #expect(statusItemMenu.contains("\"notchhub.statusItem\""))
        #expect(statusItemMenu.contains("\"notchhub.menu.settings\""))
        #expect(statusItemMenu.contains("\"settings.window\""))
        #expect(settingsRoot.contains("\"settings.launchAtLogin\""))
        #expect(settingsRoot.contains("\"settings.reduceMotion\""))
        #expect(settingsRoot.contains("\"settings.display\""))
        #expect(settingsRoot.contains("\"settings.about.version\""))
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
