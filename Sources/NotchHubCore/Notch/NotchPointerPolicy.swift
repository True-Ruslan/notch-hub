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
            let frame = compactActivationFrame(for: layout)
            let isInsideActivationRegion =
                pointer.x >= frame.minX + activationInset
                && pointer.x <= frame.maxX - activationInset
                && pointer.y >= frame.minY + activationInset
                && pointer.y <= frame.maxY

            return isInsideActivationRegion ? .peek : .compact

        case .peek:
            let activeFrame = layout.peekFrame.insetBy(
                dx: -retentionPadding,
                dy: -retentionPadding
            )
            return activeFrame.contains(pointer) ? .peek : .compact

        case .expanded:
            let activeFrame = layout.expandedFrame.insetBy(
                dx: -retentionPadding,
                dy: -retentionPadding
            )
            return activeFrame.contains(pointer) ? .expanded : .compact
        }
    }

    public static func containsInteractivePointer(
        _ pointer: CGPoint,
        in panelFrame: CGRect
    ) -> Bool {
        pointer.x >= panelFrame.minX
            && pointer.x <= panelFrame.maxX
            && pointer.y >= panelFrame.minY
            && pointer.y <= panelFrame.maxY
    }

    private static func compactActivationFrame(for layout: NotchLayout) -> CGRect {
        guard layout.hasHardwareNotch, layout.hardwareNotchWidth > 0 else {
            return layout.compactFrame
        }

        let activationWidth = min(layout.compactFrame.width, layout.hardwareNotchWidth)
        return CGRect(
            x: layout.compactFrame.midX - (activationWidth / 2),
            y: layout.compactFrame.minY,
            width: activationWidth,
            height: layout.compactFrame.height
        )
    }
}
