import CoreGraphics

public enum NotchPointerPolicy {
    public static func presentation(
        current: NotchPresentation,
        pointer: CGPoint,
        layout: NotchLayout,
        activationInset: CGFloat = 4,
        retentionPadding: CGFloat = 8
    ) -> NotchPresentation {
        let activeFrame: CGRect

        switch current {
        case .compact:
            var compactActivationFrame = layout.compactFrame.insetBy(
                dx: activationInset,
                dy: 0
            )
            compactActivationFrame.origin.y += activationInset
            compactActivationFrame.size.height -= activationInset
            activeFrame = compactActivationFrame
        case .expanded:
            activeFrame = layout.expandedFrame.insetBy(
                dx: -retentionPadding,
                dy: -retentionPadding
            )
        }

        return activeFrame.contains(pointer) ? .expanded : .compact
    }
}
