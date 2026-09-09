import Testing

@testable import NotchHubCore

@MainActor
struct NotchDestinationModelTests {
    @Test
    func destinationStartsHomeCanSelectShelfAndSnippetsAndResetsHome() {
        let model = NotchDestinationModel()

        #expect(model.destination == .home)

        model.select(.shelf)
        #expect(model.destination == .shelf)

        model.select(.snippets)
        #expect(model.destination == .snippets)

        model.reset()
        #expect(model.destination == .home)
    }
}
