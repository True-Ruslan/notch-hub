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

        XCTAssertTrue(subject.waitForStableCompact())
    }

    @MainActor
    func testShippingHoverDwellExpandsThroughRealPointerDelivery() throws {
        let subject = try NotchHubUIApplication(mode: .shippingSmoke)
        subject.launch()
        defer { subject.app.terminate() }

        XCTAssertTrue(subject.openExpandedViaAcceptedHover())
    }

    @MainActor
    func testExpandedPointerExitReturnsToStableCompact() throws {
        let subject = try NotchHubUIApplication(mode: .shippingSmoke)
        subject.launch()
        defer { subject.app.terminate() }

        XCTAssertTrue(subject.openExpandedViaAcceptedHover())
        subject.movePointerOutside(subject.surface("notch.surface.expanded"))
        XCTAssertTrue(subject.waitForStableCompact())
    }

    @MainActor
    func testTenHoverExitCyclesNeverLeaveStaleSurface() throws {
        let subject = try NotchHubUIApplication(mode: .shippingSmoke)
        subject.launch()
        defer { subject.app.terminate() }

        for _ in 0..<10 {
            XCTAssertTrue(subject.openExpandedViaAcceptedHover())
            subject.movePointerOutside(subject.surface("notch.surface.expanded"))
            XCTAssertTrue(subject.waitForStableCompact())
        }
    }

    @MainActor
    func testDeterministicMediaFixtureExpandsThroughRealHover() throws {
        let subject = try NotchHubUIApplication(mode: .mediaHappyPath)
        subject.launch()
        defer { subject.app.terminate() }

        let compact = subject.surface("notch.surface.compact")
        XCTAssertTrue(NotchHubUIAssertions.waitUntilExists(compact, timeout: 2))

        compact.hover()

        let expanded = subject.surface("notch.surface.expanded")
        let title = subject.app.staticTexts["media.title"]
        let artist = subject.app.staticTexts["media.artist"]
        let source = subject.app.staticTexts["media.source"]

        let expandedExists = NotchHubUIAssertions.waitUntilExists(expanded, timeout: 2)
        let titleMatches = NotchHubUIAssertions.waitUntilValue(
            title,
            equals: "Track A",
            timeout: 2
        )
        let artistMatches = NotchHubUIAssertions.waitUntilValue(
            artist,
            equals: "Fixture Artist",
            timeout: 2
        )
        let sourceMatches = NotchHubUIAssertions.waitUntilValue(
            source,
            equals: "NotchHub UI Fixture",
            timeout: 2
        )
        if !expandedExists || !titleMatches || !artistMatches || !sourceMatches {
            NotchHubUIDiagnostics.attachFailureState(
                application: subject.app,
                sourceCommit: subject.sourceCommit,
                name: "deterministic-media-hover",
                to: self
            )
        }

        XCTAssertTrue(expandedExists, "real hover must expand the deterministic fixture surface")
        XCTAssertTrue(titleMatches, "expanded deterministic fixture must expose Track A")
        XCTAssertTrue(artistMatches, "expanded deterministic fixture must expose fixture artist")
        XCTAssertTrue(sourceMatches, "expanded deterministic fixture must expose fixture source")
    }

    @MainActor
    func testDeterministicMediaControlsUseRealTypedUICommands() throws {
        let subject = try NotchHubUIApplication(mode: .mediaHappyPath)
        subject.launch()
        defer { subject.app.terminate() }

        let compact = subject.surface("notch.surface.compact")
        XCTAssertTrue(NotchHubUIAssertions.waitUntilExists(compact, timeout: 2))
        compact.hover()

        let expanded = subject.surface("notch.surface.expanded")
        let title = subject.app.staticTexts["media.title"]
        let previous = subject.app.buttons["media.previous"]
        let playPause = subject.app.buttons["media.playPause"]
        let next = subject.app.buttons["media.next"]

        XCTAssertTrue(NotchHubUIAssertions.waitUntilExists(expanded, timeout: 2))
        XCTAssertTrue(NotchHubUIAssertions.waitUntilValue(title, equals: "Track A", timeout: 2))
        XCTAssertTrue(previous.exists && previous.isEnabled)
        XCTAssertTrue(playPause.exists && playPause.isEnabled)
        XCTAssertTrue(next.exists && next.isEnabled)

        next.click()
        XCTAssertTrue(NotchHubUIAssertions.waitUntilValue(title, equals: "Track B", timeout: 2))

        previous.click()
        XCTAssertTrue(NotchHubUIAssertions.waitUntilValue(title, equals: "Track A", timeout: 2))

        XCTAssertTrue(NotchHubUIAssertions.waitUntilLabel(playPause, equals: "Pause", timeout: 2))
        playPause.click()
        XCTAssertTrue(NotchHubUIAssertions.waitUntilLabel(playPause, equals: "Play", timeout: 2))
        playPause.click()
        XCTAssertTrue(NotchHubUIAssertions.waitUntilLabel(playPause, equals: "Pause", timeout: 2))
    }
}
