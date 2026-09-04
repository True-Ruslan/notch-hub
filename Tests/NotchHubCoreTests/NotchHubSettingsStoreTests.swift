import Foundation
import Testing

@testable import NotchHubCore

@MainActor
struct NotchHubSettingsStoreTests {
    @Test
    func freshStoreWithNoPersistedDataStartsAtDefault() {
        let store = NotchHubSettingsStore(defaults: makeIsolatedDefaults())

        #expect(store.settings == .default)
    }

    @Test
    func updatePersistsAndIsVisibleToANewStoreOverTheSameDefaults() {
        let defaults = makeIsolatedDefaults()
        let store = NotchHubSettingsStore(defaults: defaults)

        store.update {
            $0.launchAtLoginEnabled = true
            $0.reduceMotionOverride = .alwaysOn
            $0.preferredDisplayOverride = .specific(displayUUID: "abc-123")
        }

        let reloaded = NotchHubSettingsStore(defaults: defaults)
        #expect(reloaded.settings.launchAtLoginEnabled == true)
        #expect(reloaded.settings.reduceMotionOverride == .alwaysOn)
        #expect(reloaded.settings.preferredDisplayOverride == .specific(displayUUID: "abc-123"))
    }

    @Test
    func corruptPersistedDataFallsBackToDefaultRatherThanCrashing() {
        let defaults = makeIsolatedDefaults()
        defaults.set(Data([0xFF, 0x00, 0x13]), forKey: "ru.trueruslan.notchhub.settings.v1")

        let store = NotchHubSettingsStore(defaults: defaults)

        #expect(store.settings == .default)
    }

    private func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "NotchHubSettingsStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
