import CoreGraphics

public enum NotchPointerPolicy {
    public static func presentation(
        current: NotchPresentation,
        pointer: CGPoint,
        layout: NotchLayout,
        activationInset: CGFloat = 4,
        retentionPadding: CGFloat = 8
    ) -> NotchPresentation {
        switch current {
        case .compact:
            let frame = layout.compactFrame
            let isInsideActivationRegion =
                pointer.x >= frame.minX + activationInset
                && pointer.x <= frame.maxX - activationInset
                && pointer.y >= frame.minY + activationInset
                && pointer.y <= frame.maxY

            return isInsideActivationRegion ? .expanded : .compact
        case .expanded:
            let activeFrame = layout.expandedFrame.insetBy(
                dx: -retentionPadding,
                dy: -retentionPadding
            )
            return activeFrame.contains(pointer) ? .expanded : .compact
        }
    }
}
