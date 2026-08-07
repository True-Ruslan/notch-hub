import Testing
@testable import NotchHubCore

@MainActor
struct NotchPanelModelTests {
    @Test
    func hoverExpandsAndLeavingCollapses() {
        let model = NotchPanelModel()
        #expect(model.presentation == .compact)

        model.setHovered(true)
        #expect(model.presentation == .expanded)

        model.setHovered(false)
        #expect(model.presentation == .compact)
    }

    @Test
    func toggleAlternatesPresentation() {
        let model = NotchPanelModel()

        model.toggle()
        #expect(model.presentation == .expanded)

        model.toggle()
        #expect(model.presentation == .compact)
    }
}
