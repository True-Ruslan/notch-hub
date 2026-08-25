import CoreGraphics
import Testing
@testable import NotchHubCore

struct NotchGeometryTests {
    @Test
    func detectsHardwareNotchFromAuxiliaryAreas() {
        let input = ScreenGeometryInput(
            frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
            safeAreaTop: 37,
            auxiliaryTopLeftArea: CGRect(x: 0, y: 945, width: 662, height: 37),
            auxiliaryTopRightArea: CGRect(x: 850, y: 945, width: 662, height: 37)
        )
        let layout = NotchGeometry.layout(for: input)
        #expect(layout.hasHardwareNotch)
        #expect(layout.hardwareNotchWidth == 188)
        #expect(layout.compactFrame.midX == input.frame.midX)
        #expect(layout.compactFrame.maxY == input.frame.maxY)
        #expect(layout.compactBackgroundOpacity == 1)
        #expect(layout.expandedContentTopInset == layout.compactFrame.height + 12)
        #expect(layout.peekContentTopInset == layout.compactFrame.height + 4)
    }

    @Test
    func hardwareNotchLayoutIncludesTopAnchoredPeekFrame() {
        let input = hardwareInput()
        let layout = NotchGeometry.layout(for: input)
        #expect(layout.peekFrame.size == CGSize(width: 360, height: 96))
        #expect(layout.peekFrame.midX == layout.compactFrame.midX)
        #expect(layout.peekFrame.maxY == layout.compactFrame.maxY)
    }

    @Test
    func hardwareNotchWidthIsNotInflatedByFallbackMinimum() {
        let layout = NotchGeometry.layout(for: hardwareInput(), minimumCompactWidth: 180)
        #expect(layout.hasHardwareNotch)
        #expect(layout.hardwareNotchWidth == 176)
        #expect(layout.compactFrame.width == 176)
    }

    @Test
    func mediaCompactWingsExtendSymmetricallyWithoutChangingNotchPeekOrExpandedGeometry() {
        assertMediaCompactWingGeometry()
    }

    @Test
    func mediaCompactWingsExtendSymmetricallyWithoutChangingNotchOrExpandedGeometry() {
        assertMediaCompactWingGeometry()
    }

    @Test
    func negativeCompactExtensionIsClampedToZero() {
        let layout = NotchGeometry.layout(for: hardwareInput())
        #expect(layout.withCompactHorizontalExtension(-10).compactFrame == layout.compactFrame)
        #expect(layout.withCompactHorizontalExtension(-10).peekFrame == layout.peekFrame)
    }

    @Test
    func fallsBackToCenteredPanelOnDisplayWithoutNotch() {
        let input = ScreenGeometryInput(
            frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080),
            safeAreaTop: 0,
            auxiliaryTopLeftArea: nil,
            auxiliaryTopRightArea: nil
        )
        let layout = NotchGeometry.layout(for: input)
        #expect(!layout.hasHardwareNotch)
        #expect(layout.hardwareNotchWidth == 0)
        #expect(layout.compactFrame.width == 180)
        #expect(layout.compactFrame.height == 32)
        #expect(layout.compactFrame.midX == input.frame.midX)
        #expect(layout.peekFrame.width == 360)
        #expect(layout.peekFrame.height == 96)
        #expect(layout.peekFrame.midX == input.frame.midX)
        #expect(layout.compactBackgroundOpacity == 1)
        #expect(layout.expandedContentTopInset == 20)
        #expect(layout.peekContentTopInset == 28)
    }

    @Test
    func peekContentTopInsetAlwaysClearsThePhysicallyOpaqueNotchHeight() {
        let layout = NotchGeometry.layout(for: hardwareInput())
        // Peek content is horizontally centered on the notch the same way
        // Compact is, so anything rendered above this inset would be
        // physically unrenderable, not just visually cramped.
        #expect(layout.peekContentTopInset >= layout.compactFrame.height)
    }

    @Test
    func clampsPeekAndExpandedPanelToScreenMargins() {
        let input = ScreenGeometryInput(
            frame: CGRect(x: 0, y: 0, width: 300, height: 900),
            safeAreaTop: 0,
            auxiliaryTopLeftArea: nil,
            auxiliaryTopRightArea: nil
        )
        let layout = NotchGeometry.layout(for: input, expandedWidth: 800, horizontalMargin: 16)
        #expect(layout.peekFrame.width == 268)
        #expect(layout.peekFrame.minX == 16)
        #expect(layout.expandedFrame.width == 268)
        #expect(layout.expandedFrame.minX == 16)
    }

    private func assertMediaCompactWingGeometry() {
        let layout = NotchGeometry.layout(for: hardwareInput(), minimumCompactWidth: 180)
        let mediaLayout = layout.withCompactHorizontalExtension(36)
        #expect(mediaLayout.hasHardwareNotch == layout.hasHardwareNotch)
        #expect(mediaLayout.hardwareNotchWidth == 176)
        #expect(mediaLayout.compactFrame.minX == layout.compactFrame.minX - 36)
        #expect(mediaLayout.compactFrame.width == layout.compactFrame.width + 72)
        #expect(mediaLayout.compactFrame.height == layout.compactFrame.height)
        #expect(mediaLayout.compactFrame.midX == layout.compactFrame.midX)
        #expect(mediaLayout.peekFrame == layout.peekFrame)
        #expect(mediaLayout.expandedFrame == layout.expandedFrame)
    }

    private func hardwareInput() -> ScreenGeometryInput {
        ScreenGeometryInput(
            frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
            safeAreaTop: 37,
            auxiliaryTopLeftArea: CGRect(x: 0, y: 945, width: 668, height: 37),
            auxiliaryTopRightArea: CGRect(x: 844, y: 945, width: 668, height: 37)
        )
    }
}
