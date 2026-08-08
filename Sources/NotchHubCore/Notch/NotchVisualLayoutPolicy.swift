import CoreGraphics

struct NotchVisualMetrics: Equatable, Sendable {
    let compactBackgroundOpacity: Double
    let expandedContentTopInset: CGFloat
}

enum NotchVisualLayoutPolicy {
    private static let standardContentInset: CGFloat = 20
    private static let hardwareNotchContentSpacing: CGFloat = 12

    static func metrics(
        hasHardwareNotch: Bool,
        compactHeight: CGFloat
    ) -> NotchVisualMetrics {
        NotchVisualMetrics(
            compactBackgroundOpacity: hasHardwareNotch ? 0 : 1,
            expandedContentTopInset: hasHardwareNotch
                ? compactHeight + hardwareNotchContentSpacing
                : standardContentInset
        )
    }
}
