import Testing
@testable import NotchHubCore

@MainActor
struct NotchHostingViewFactoryTests {
    @Test
    func hostingViewDoesNotOwnWindowSizing() {
        let model = NotchPanelModel()
        let hostingView = NotchHostingViewFactory.make(model: model)

        #expect(hostingView.sizingOptions == [])
    }
}
