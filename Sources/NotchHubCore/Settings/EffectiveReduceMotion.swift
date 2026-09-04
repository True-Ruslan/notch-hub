public func effectiveReduceMotion(
    systemValue: Bool,
    override: NotchHubSettings.ReduceMotionOverride
) -> Bool {
    switch override {
    case .system: systemValue
    case .alwaysOn: true
    case .alwaysOff: false
    }
}
