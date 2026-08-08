import CoreGraphics

enum NotchVisualLayoutPolicy {
    static func compactBackgroundOpacity(hasHardwareNotch: Bool) -> Double {
        hasHardwareNotch ? 0 : 1
    }

    static func expandedContentTopInset(
        hasHardwareNotch: Bool,
        compactHeight: CGFloat
    ) -> CGFloat {
        hasHardwareNotch ? compactHeight + 12 : 20
    }
}
