import CoreGraphics

public struct NotchLayout: Equatable, Sendable {
    public let hasHardwareNotch: Bool
    public let hardwareNotchWidth: CGFloat
    public let compactFrame: CGRect
    public let expandedFrame: CGRect

    public init(
        hasHardwareNotch: Bool,
        hardwareNotchWidth: CGFloat,
        compactFrame: CGRect,
        expandedFrame: CGRect
    ) {
        self.hasHardwareNotch = hasHardwareNotch
        self.hardwareNotchWidth = hardwareNotchWidth
        self.compactFrame = compactFrame
        self.expandedFrame = expandedFrame
    }
}

public enum NotchGeometry {
    public static func layout(
        for input: ScreenGeometryInput,
        minimumCompactWidth: CGFloat = 180,
        fallbackCompactHeight: CGFloat = 32,
        expandedWidth: CGFloat = 520,
        expandedHeight: CGFloat = 250,
        horizontalMargin: CGFloat = 16
    ) -> NotchLayout {
        let detectedNotch = detectedHardwareNotch(in: input)
        let centerX = detectedNotch?.midX ?? input.frame.midX
        let hardwareWidth = detectedNotch?.width ?? 0
        let compactWidth = max(minimumCompactWidth, hardwareWidth)
        let compactHeight = max(input.safeAreaTop, fallbackCompactHeight)

        let compactFrame = CGRect(
            x: centerX - compactWidth / 2,
            y: input.frame.maxY - compactHeight,
            width: compactWidth,
            height: compactHeight
        )

        let maximumExpandedWidth = max(compactWidth, input.frame.width - horizontalMargin * 2)
        let resolvedExpandedWidth = min(max(expandedWidth, compactWidth), maximumExpandedWidth)
        let resolvedExpandedHeight = max(expandedHeight, compactHeight)

        let expandedFrame = CGRect(
            x: centerX - resolvedExpandedWidth / 2,
            y: input.frame.maxY - resolvedExpandedHeight,
            width: resolvedExpandedWidth,
            height: resolvedExpandedHeight
        )

        return NotchLayout(
            hasHardwareNotch: detectedNotch != nil,
            hardwareNotchWidth: hardwareWidth,
            compactFrame: compactFrame,
            expandedFrame: expandedFrame
        )
    }

    static func detectedHardwareNotch(in input: ScreenGeometryInput) -> CGRect? {
        guard input.safeAreaTop > 0,
              let left = input.auxiliaryTopLeftArea,
              let right = input.auxiliaryTopRightArea,
              right.minX > left.maxX
        else {
            return nil
        }

        return CGRect(
            x: left.maxX,
            y: input.frame.maxY - input.safeAreaTop,
            width: right.minX - left.maxX,
            height: input.safeAreaTop
        )
    }
}
