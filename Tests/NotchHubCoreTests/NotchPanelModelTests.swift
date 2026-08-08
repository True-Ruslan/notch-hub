import Testing
@testable import NotchHubCore

@MainActor
struct NotchPanelModelTests {
    @Test
    func contentPresentationChangesOnlyWhenExplicitlySet() {
        let model = NotchPanelModel()
        #expect(model.contentPresentation == .compact)

        model.setContentPresentation(.expanded)
        #expect(model.contentPresentation == .expanded)

        model.setContentPresentation(.compact)
        #expect(model.contentPresentation == .compact)
    }
}
