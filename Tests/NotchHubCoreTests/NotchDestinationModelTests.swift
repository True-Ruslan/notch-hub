import Testing

@testable import NotchHubCore

@MainActor
struct NotchDestinationModelTests {
    @Test
    func destinationStartsHomeCanSelectShelfAndResetsHome() {
        let model = NotchDestinationModel()

        #expect(model.destination == .home)

        model.select(.shelf)
        #expect(model.destination == .shelf)

        model.reset()
        #expect(model.destination == .home)
    }
}
