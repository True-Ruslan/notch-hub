public struct NotchHubSettings: Equatable, Sendable, Codable {
    public var launchAtLoginEnabled: Bool
    public var reduceMotionOverride: ReduceMotionOverride
    public var preferredDisplayOverride: PreferredDisplayOverride

    public init(
        launchAtLoginEnabled: Bool,
        reduceMotionOverride: ReduceMotionOverride,
        preferredDisplayOverride: PreferredDisplayOverride
    ) {
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.reduceMotionOverride = reduceMotionOverride
        self.preferredDisplayOverride = preferredDisplayOverride
    }

    public static let `default` = NotchHubSettings(
        launchAtLoginEnabled: false,
        reduceMotionOverride: .system,
        preferredDisplayOverride: .automatic
    )

    public enum ReduceMotionOverride: String, Equatable, Sendable, Codable, CaseIterable {
        case system
        case alwaysOn
        case alwaysOff
    }

    public enum PreferredDisplayOverride: Equatable, Sendable, Codable {
        case automatic
        case specific(displayUUID: String)
    }
}
