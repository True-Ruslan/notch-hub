import Foundation
import Testing

@testable import NotchHubCore

struct NotchHubSettingsTests {
    @Test
    func defaultSettingsFollowSystemAutomaticAndNoLaunchAtLogin() {
        #expect(NotchHubSettings.default.launchAtLoginEnabled == false)
        #expect(NotchHubSettings.default.reduceMotionOverride == .system)
        #expect(NotchHubSettings.default.preferredDisplayOverride == .automatic)
    }

    @Test
    func settingsRoundTripThroughCodableForEveryReduceMotionOverride() throws {
        for override in NotchHubSettings.ReduceMotionOverride.allCases {
            let settings = NotchHubSettings(
                launchAtLoginEnabled: true,
                reduceMotionOverride: override,
                preferredDisplayOverride: .specific(displayUUID: "abc-123")
            )

            let data = try JSONEncoder().encode(settings)
            let decoded = try JSONDecoder().decode(NotchHubSettings.self, from: data)

            #expect(decoded == settings)
        }
    }

    @Test
    func preferredDisplayOverrideRoundTripsBothCases() throws {
        for override: NotchHubSettings.PreferredDisplayOverride in [
            .automatic, .specific(displayUUID: "xyz-789")
        ] {
            let settings = NotchHubSettings(
                launchAtLoginEnabled: false,
                reduceMotionOverride: .system,
                preferredDisplayOverride: override
            )

            let data = try JSONEncoder().encode(settings)
            let decoded = try JSONDecoder().decode(NotchHubSettings.self, from: data)

            #expect(decoded.preferredDisplayOverride == override)
        }
    }
}
