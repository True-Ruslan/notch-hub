import XCTest

final class NotchHubUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchesExactExternalApplicationBuild() throws {
        let subject = try NotchHubUIApplication(mode: .shippingSmoke)
        subject.launch()
        XCTAssertNotEqual(subject.app.state, .notRunning)
        subject.app.terminate()
        XCTAssertEqual(subject.app.state, .notRunning)
    }

    @MainActor
    func testShippingAppExposesStableCompactSurfaceIdentifier() throws {
        let subject = try NotchHubUIApplication(mode: .shippingSmoke)
        subject.launch()
        defer { subject.app.terminate() }

        let compact = subject.app.otherElements["notch.surface.compact"]
        let exists = NotchHubUIAssertions.waitUntilExists(compact, timeout: 2)
        if !exists {
            NotchHubUIDiagnostics.attachFailureState(
                application: subject.app,
                name: "compact-surface",
                to: self
            )
        }
        XCTAssertTrue(
            exists,
            "shipping app must expose the stable compact-surface accessibility contract"
        )
    }
}
