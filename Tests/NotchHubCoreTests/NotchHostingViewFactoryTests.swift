import CoreGraphics
import SwiftUI
import Testing
@testable import NotchHubCore

@MainActor
struct NotchHostingViewFactoryTests {
    private let layout = NotchLayout(
        hasHardwareNotch: true,
        hardwareNotchWidth: 176,
        compactFrame: CGRect(x: 412, y: 868, width: 176, height: 32),
        expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
    )

    @Test
    func hostingViewDoesNotOwnWindowSizing() {
        let model = NotchPanelModel()
        let hostingView = NotchHostingViewFactory.make(model: model, layout: layout)

        #expect(hostingView.sizingOptions == [])
    }

    @Test
    func hostingViewTracksPanelBoundsInBothDimensions() {
        let model = NotchPanelModel()
        let hostingView = NotchHostingViewFactory.make(model: model, layout: layout)

        #expect(hostingView.autoresizingMask.contains(.width))
        #expect(hostingView.autoresizingMask.contains(.height))
    }

    @Test
    func hostingViewStartsWithStableCompactAppKitChrome() {
        let model = NotchPanelModel()
        let hostingView = NotchHostingViewFactory.make(model: model, layout: layout)

        #expect(hostingView.wantsLayer)
        #expect(hostingView.layer?.masksToBounds == true)
        #expect(hostingView.layer?.cornerCurve == .continuous)
        #expect(hostingView.layer?.cornerRadius == 12)
    }

    @Test
    func customSwiftUIRootKeepsAcceptedHostingAndChromeInvariants() {
        let hostingView = NotchHostingViewFactory.make(
            rootView: Text("Injected content")
        )

        #expect(hostingView.sizingOptions == [])
        #expect(hostingView.autoresizingMask.contains(.width))
        #expect(hostingView.autoresizingMask.contains(.height))
        #expect(hostingView.wantsLayer)
        #expect(hostingView.layer?.masksToBounds == true)
        #expect(hostingView.layer?.cornerCurve == .continuous)
        #expect(hostingView.layer?.cornerRadius == 12)
    }
}
