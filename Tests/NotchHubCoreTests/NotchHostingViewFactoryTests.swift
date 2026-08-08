import CoreGraphics
import Testing
@testable import NotchHubCore

@MainActor
struct NotchHostingViewFactoryTests {
    @Test
    func hostingViewDoesNotOwnWindowSizing() {
        let model = NotchPanelModel()
        let layout = NotchLayout(
            hasHardwareNotch: true,
            hardwareNotchWidth: 176,
            compactFrame: CGRect(x: 412, y: 868, width: 176, height: 32),
            expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
        )
        let hostingView = NotchHostingViewFactory.make(model: model, layout: layout)

        #expect(hostingView.sizingOptions == [])
    }
}
