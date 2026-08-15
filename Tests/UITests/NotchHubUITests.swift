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
    func testShippingHoverDoesNotOpenFullInterface() throws {
        let subject = try NotchHubUIApplication(mode: .shippingSmoke)
        subject.launch()
        defer { subject.app.terminate() }

        let compact = subject.surface("notch.surface.compact")
        XCTAssertTrue(NotchHubUIAssertions.waitUntilExists(compact, timeout: 2))
        compact.hover()

        let expanded = subject.surface("notch.surface.expanded")
        let appears = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true"),
            object: expanded
        )
        appears.isInverted = true
        XCTAssertEqual(XCTWaiter().wait(for: [appears], timeout: 0.35), .completed)
    }

    @MainActor
    func testNoMediaHoverOpensPeekAndRequestsExactlyOneHaptic() throws {
        let subject = try NotchHubUIApplication(mode: .shippingSmoke)
        subject.launch()
        defer { subject.app.terminate() }

        let compact = subject.surface("notch.surface.compact")
        XCTAssertTrue(NotchHubUIAssertions.waitUntilExists(compact, timeout: 2))
        compact.hover()

        let peek = subject.surface("notch.surface.peek")
        let expanded = subject.surface("notch.surface.expanded")
        let hapticCount = subject.app.descendants(matching: .any)["ui-test.hapticCount"]

        XCTAssertTrue(
            NotchHubUIAssertions.waitUntilExists(peek, timeout: 2),
            "120 ms hover must open lightweight Peek even without media"
        )
        XCTAssertTrue(
            expanded.waitForNonExistence(timeout: 0.5),
            "hover must never open full expanded interface"
        )
        XCTAssertTrue(
            NotchHubUIAssertions.waitUntilExists(hapticCount, timeout: 2),
            "UI-test build must expose compile-time-only haptic diagnostics"
        )
        XCTAssertTrue(
            NotchHubUIAssertions.waitUntilValue(hapticCount, equals: "1", timeout: 2),
            "one hover Peek transition must request exactly one haptic"
        )
    }

    @MainActor
    func testExpandedPointerExitReturnsToStableCompact() throws {
        let subject = try NotchHubUIApplication(mode: .shippingSmoke)
        subject.launch()
        defer { subject.app.terminate() }

        XCTAssertTrue(subject.openExpandedExplicitly())
        subject.movePointerOutside(subject.surface("notch.surface.expanded"))
        XCTAssertTrue(subject.waitForStableCompact())
    }

    @MainActor
    func testTenHoverExitCyclesNeverLeaveStaleSurface() throws {
        let subject = try NotchHubUIApplication(mode: .shippingSmoke)
        subject.launch()
        defer { subject.app.terminate() }

        for _ in 0..<10 {
            XCTAssertTrue(subject.openExpandedExplicitly())
            subject.movePointerOutside(subject.surface("notch.surface.expanded"))
            XCTAssertTrue(subject.waitForStableCompact())
        }
    }

    @MainActor
    func testDeterministicMediaFixtureExpandsThroughExplicitClick() throws {
        let subject = try NotchHubUIApplication(mode: .mediaHappyPath)
        subject.launch()
        defer { subject.app.terminate() }

        XCTAssertTrue(subject.openExpandedExplicitly())

        let expanded = subject.surface("notch.surface.expanded")
        let title = subject.titleElement()
        let artist = subject.app.staticTexts["media.artist"]
        let source = subject.app.descendants(matching: .any)["media.source"]

        let expandedExists = NotchHubUIAssertions.waitUntilExists(expanded, timeout: 2)
        let titleMatches = NotchHubUIAssertions.waitUntilValue(title, equals: "Track A", timeout: 2)
        let artistMatches = NotchHubUIAssertions.waitUntilValue(
            artist,
            equals: "Fixture Artist",
            timeout: 2
        )
        let sourceMatches = NotchHubUIAssertions.waitUntilLabel(
            source,
            equals: "NotchHub UI Fixture",
            timeout: 2
        )
        if !expandedExists || !titleMatches || !artistMatches || !sourceMatches {
            NotchHubUIDiagnostics.attachFailureState(
                application: subject.app,
                sourceCommit: subject.sourceCommit,
                name: "deterministic-media-explicit-expansion",
                to: self
            )
        }

        XCTAssertTrue(expandedExists)
        XCTAssertTrue(titleMatches)
        XCTAssertTrue(artistMatches)
        XCTAssertTrue(sourceMatches)
        XCTAssertTrue(subject.app.buttons["media.playPause"].exists)
        XCTAssertTrue(subject.app.buttons["media.previous"].exists)
        XCTAssertTrue(subject.app.buttons["media.next"].exists)
    }

    @MainActor
    func testDeterministicMediaControlsUseRealTypedUICommands() throws {
        let subject = try NotchHubUIApplication(mode: .mediaHappyPath)
        subject.launch()
        defer { subject.app.terminate() }

        XCTAssertTrue(subject.openExpandedExplicitly())

        let title = subject.titleElement()
        let previous = subject.app.buttons["media.previous"]
        let playPause = subject.app.buttons["media.playPause"]
        let next = subject.app.buttons["media.next"]

        XCTAssertTrue(NotchHubUIAssertions.waitUntilValue(title, equals: "Track A", timeout: 2))
        XCTAssertTrue(previous.exists && previous.isEnabled)
        XCTAssertTrue(playPause.exists && playPause.isEnabled)
        XCTAssertTrue(next.exists && next.isEnabled)
        XCTAssertTrue(NotchHubUIAssertions.waitUntilValue(previous, equals: "enabled", timeout: 2))
        XCTAssertTrue(NotchHubUIAssertions.waitUntilValue(next, equals: "enabled", timeout: 2))
        XCTAssertTrue(NotchHubUIAssertions.waitUntilValue(playPause, equals: "playing", timeout: 2))

        next.click()
        XCTAssertTrue(NotchHubUIAssertions.waitUntilValue(title, equals: "Track B", timeout: 2))

        previous.click()
        XCTAssertTrue(NotchHubUIAssertions.waitUntilValue(title, equals: "Track A", timeout: 2))

        playPause.click()
        XCTAssertTrue(NotchHubUIAssertions.waitUntilValue(playPause, equals: "paused", timeout: 2))
        playPause.click()
        XCTAssertTrue(NotchHubUIAssertions.waitUntilValue(playPause, equals: "playing", timeout: 2))
    }

    @MainActor
    func testUnsupportedCapabilitiesStayDisabledAndDoNotChangeTrack() throws {
        let subject = try NotchHubUIApplication(mode: .mediaUnsupported)
        subject.launch()
        defer { subject.app.terminate() }

        XCTAssertTrue(subject.openExpandedExplicitly())

        let title = subject.titleElement()
        let previous = subject.app.buttons["media.previous"]
        let next = subject.app.buttons["media.next"]

        XCTAssertTrue(NotchHubUIAssertions.waitUntilValue(title, equals: "Track A", timeout: 2))
        XCTAssertTrue(previous.exists)
        XCTAssertTrue(next.exists)
        XCTAssertTrue(NotchHubUIAssertions.waitUntilValue(previous, equals: "disabled", timeout: 2))
        XCTAssertTrue(NotchHubUIAssertions.waitUntilValue(next, equals: "disabled", timeout: 2))
        XCTAssertTrue(NotchHubUIAssertions.waitUntilValue(title, equals: "Track A", timeout: 2))
    }

    @MainActor
    func testCompactRetainsAuthoritativeMediaContextAfterCollapse() throws {
        let subject = try NotchHubUIApplication(mode: .deterministicMedia)
        subject.launch()
        defer { subject.app.terminate() }

        XCTAssertTrue(subject.openExpandedExplicitly())
        XCTAssertTrue(
            NotchHubUIAssertions.waitUntilValue(subject.titleElement(), equals: "Track A", timeout: 2)
        )

        subject.movePointerOutside(subject.surface("notch.surface.expanded"))
        XCTAssertTrue(subject.waitForStableCompact())

        let retainedArtwork = subject.app.descendants(matching: .any)["media.artwork"]
        XCTAssertTrue(
            NotchHubUIAssertions.waitUntilExists(retainedArtwork, timeout: 2),
            "accepted compact collapse must retain authoritative media context without reopening runtime"
        )
    }
}
