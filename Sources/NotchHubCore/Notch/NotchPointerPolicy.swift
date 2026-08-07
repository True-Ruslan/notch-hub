import CoreGraphics

public enum NotchPointerPolicy {
    public static func presentation(
        current: NotchPresentation,
        pointer: CGPoint,
        layout: NotchLayout,
        activationPadding: CGFloat = 2,
        retentionPadding: CGFloat = 8
    ) -> NotchPresentation {
        let activationFrame = layout.compactFrame.insetBy(
            dx: -activationPadding,
            dy: -activationPadding
        )

        return activationFrame.contains(pointer) ? .expanded : .compact
    }
}
