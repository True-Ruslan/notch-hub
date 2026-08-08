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
    }

    @Test
    func hardwareNotchWidthIsNotInflatedByFallbackMinimum() {
        let input = ScreenGeometryInput(
            frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
            safeAreaTop: 37,
            auxiliaryTopLeftArea: CGRect(x: 0, y: 945, width: 668, height: 37),
            auxiliaryTopRightArea: CGRect(x: 844, y: 945, width: 668, height: 37)
        )

        let layout = NotchGeometry.layout(for: input, minimumCompactWidth: 180)

        #expect(layout.hasHardwareNotch)
        #expect(layout.hardwareNotchWidth == 176)
        #expect(layout.compactFrame.width == 176)
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
        #expect(layout.compactBackgroundOpacity == 1)
        #expect(layout.expandedContentTopInset == 20)
    }

    @Test
    func clampsExpandedPanelToScreenMargins() {
        let input = ScreenGeometryInput(
            frame: CGRect(x: 0, y: 0, width: 420, height: 900),
            safeAreaTop: 0,
            auxiliaryTopLeftArea: nil,
            auxiliaryTopRightArea: nil
        )

        let layout = NotchGeometry.layout(for: input, expandedWidth: 800, horizontalMargin: 16)

        #expect(layout.expandedFrame.width == 388)
        #expect(layout.expandedFrame.minX == 16)
    }
}
