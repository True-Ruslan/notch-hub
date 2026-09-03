import Foundation

@MainActor
public final class NotchHubSettingsStore: ObservableObject {
    private static let defaultsKey = "ru.trueruslan.notchhub.settings.v1"

    @Published public private(set) var settings: NotchHubSettings

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.settings = Self.load(from: defaults)
    }

    public func update(_ transform: (inout NotchHubSettings) -> Void) {
        var updated = settings
        transform(&updated)
        settings = updated
        save(updated)
    }

    private func save(_ settings: NotchHubSettings) {
        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }
        defaults.set(data, forKey: Self.defaultsKey)
    }

    private static func load(from defaults: UserDefaults) -> NotchHubSettings {
        guard
            let data = defaults.data(forKey: defaultsKey),
            let decoded = try? JSONDecoder().decode(NotchHubSettings.self, from: data)
        else {
            return .default
        }
        return decoded
    }
}
