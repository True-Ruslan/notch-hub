import CoreGraphics
import Testing
@testable import NotchHubCore

struct NotchScreenSelectionTests {
    @Test
    func hardwareNotchDisplayWinsOverPreferredExternalDisplay() {
        let external = displayInput(
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            hasHardwareNotch: false
        )
        let builtInNotch = displayInput(
            frame: CGRect(x: 1920, y: 0, width: 1512, height: 982),
            hasHardwareNotch: true
        )

        let selected = NotchScreenSelection.preferredIndex(
            in: [external, builtInNotch],
            fallbackIndex: 0
        )

        #expect(selected == 1)
    }

    @Test
    func preferredDisplayIsPreservedWhenNoHardwareNotchExists() {
        let first = displayInput(
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            hasHardwareNotch: false
        )
        let preferred = displayInput(
            frame: CGRect(x: 1920, y: 0, width: 2560, height: 1440),
            hasHardwareNotch: false
        )

        let selected = NotchScreenSelection.preferredIndex(
            in: [first, preferred],
            fallbackIndex: 1
        )

        #expect(selected == 1)
    }

    @Test
    func firstDisplayIsFallbackWhenPreferredDisplayIsUnavailable() {
        let first = displayInput(
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            hasHardwareNotch: false
        )

        let selected = NotchScreenSelection.preferredIndex(
            in: [first],
            fallbackIndex: nil
        )

        #expect(selected == 0)
    }

    @Test
    func emptyDisplayListHasNoSelection() {
        #expect(NotchScreenSelection.preferredIndex(in: [], fallbackIndex: nil) == nil)
    }

    private func displayInput(frame: CGRect, hasHardwareNotch: Bool) -> ScreenGeometryInput {
        guard hasHardwareNotch else {
            return ScreenGeometryInput(
                frame: frame,
                safeAreaTop: 0,
                auxiliaryTopLeftArea: nil,
                auxiliaryTopRightArea: nil
            )
        }

        let safeAreaTop: CGFloat = 37
        let notchWidth: CGFloat = 176
        let sideWidth = (frame.width - notchWidth) / 2
        return ScreenGeometryInput(
            frame: frame,
            safeAreaTop: safeAreaTop,
            auxiliaryTopLeftArea: CGRect(
                x: frame.minX,
                y: frame.maxY - safeAreaTop,
                width: sideWidth,
                height: safeAreaTop
            ),
            auxiliaryTopRightArea: CGRect(
                x: frame.minX + sideWidth + notchWidth,
                y: frame.maxY - safeAreaTop,
                width: sideWidth,
                height: safeAreaTop
            )
        )
    }
}
