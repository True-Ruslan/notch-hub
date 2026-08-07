import CoreGraphics

public enum NotchPointerPolicy {
    public static func presentation(
        current: NotchPresentation,
        pointer: CGPoint,
        layout: NotchLayout,
        activationPadding: CGFloat = 2,
        retentionPadding: CGFloat = 8
    ) -> NotchPresentation {
        let activeFrame: CGRect

        switch current {
        case .compact:
            activeFrame = layout.compactFrame.insetBy(
                dx: -activationPadding,
                dy: -activationPadding
            )
        case .expanded:
            activeFrame = layout.expandedFrame.insetBy(
                dx: -retentionPadding,
                dy: -retentionPadding
            )
        }

        return activeFrame.contains(pointer) ? .expanded : .compact
    }
}
