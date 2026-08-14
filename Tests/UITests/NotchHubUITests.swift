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

    @MainActor
    func testDeterministicMediaFixtureExpandsThroughRealHover() throws {
        let subject = try NotchHubUIApplication(mode: .mediaHappyPath)
        subject.launch()
        defer { subject.app.terminate() }

        let compact = subject.app.otherElements["notch.surface.compact"]
        XCTAssertTrue(NotchHubUIAssertions.waitUntilExists(compact, timeout: 2))

        compact.hover()

        let expanded = subject.app.otherElements["notch.surface.expanded"]
        let title = subject.app.staticTexts["media.title"]
        let artist = subject.app.staticTexts["media.artist"]
        let source = subject.app.staticTexts["media.source"]

        let expandedExists = NotchHubUIAssertions.waitUntilExists(expanded, timeout: 2)
        let titleExists = NotchHubUIAssertions.waitUntilExists(title, timeout: 2)
        if !expandedExists || !titleExists {
            NotchHubUIDiagnostics.attachFailureState(
                application: subject.app,
                name: "deterministic-media-hover",
                to: self
            )
        }

        XCTAssertTrue(expandedExists, "real hover must expand the deterministic fixture surface")
        XCTAssertTrue(titleExists, "expanded deterministic fixture must expose media title")
        XCTAssertEqual(title.label, "Track A")
        XCTAssertEqual(artist.label, "Artist A")
        XCTAssertEqual(source.label, "Fixture Player")
    }
}
