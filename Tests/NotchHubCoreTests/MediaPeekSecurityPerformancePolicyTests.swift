import Foundation
import Testing

struct MediaPeekSecurityPerformancePolicyTests {
    @Test
    func hoverPeekHotPathsRemainLocalBoundedAndEventDriven() throws {
        let files = try [
            sourceText("Sources/NotchHubCore/Notch/NotchInteractionCoordinator.swift"),
            sourceText("Sources/NotchHubApp/MediaPeekSession.swift"),
            sourceText("Sources/NotchHubApp/MediaGestureSession.swift"),
            sourceText("Sources/NotchHubApp/MediaNotchRootView.swift"),
            sourceText("Sources/NotchHubMediaCore/ShippingMediaPeekProbe.swift")
        ]
        let source = files.joined(separator: "\n")

        #expect(!source.contains("NSEvent.addGlobalMonitorForEvents"))
        #expect(!source.contains("NSEvent.addLocalMonitorForEvents"))
        #expect(!source.contains("CGEventTap"))
        #expect(!source.contains("Timer.scheduledTimer"))
        #expect(!source.contains("Timer.publish"))
        #expect(!source.contains("DispatchSource.makeTimerSource"))
        #expect(!source.contains("CVDisplayLink"))
        #expect(!source.contains("Task.sleep"))
        #expect(!source.contains("URLSession"))
        #expect(!source.contains("UserDefaults"))
    }

    @Test
    func cursorPolicyIntroducesNoWarpOrGlobalInputAuthority() throws {
        let source = try sourceText("Sources/NotchHubApp/CursorVisibilityController.swift")

        #expect(source.contains("NSCursor.hide()"))
        #expect(source.contains("NSCursor.unhide()"))
        #expect(!source.contains("CGWarpMouseCursorPosition"))
        #expect(!source.contains("CGAssociateMouseAndMouseCursorPosition"))
        #expect(!source.contains("CGEventTap"))
        #expect(!source.contains("AXUIElement"))
    }

    @Test
    func mediaRuntimeStartsOnceAtLaunchAndStopsOnlyAtQuit() throws {
        // M6.7 reverses the prior "zero-adapter compact" invariant: the
        // shipping runtime now runs for the app's whole lifetime so Compact
        // reflects live state, per
        // docs/superpowers/specs/2026-08-22-live-media-timeline-and-compact-design.md.
        let appSource = try sourceText("Sources/NotchHubApp/AppDelegate.swift")
        let probeSource = try sourceText("Sources/NotchHubMediaCore/ShippingMediaPeekProbe.swift")

        #expect(appSource.contains("let mediaRuntime = composition.makeMediaRuntime(mediaPresentationModel)"))
        #expect(appSource.contains("mediaRuntime.start()"))
        #expect(appSource.contains("mediaRuntime?.stop()"))
        #expect(!appSource.contains("func updateMediaRuntime"))
        #expect(probeSource.contains("transport.start()"))
        #expect(probeSource.contains("activeTransport.eventHandler = nil"))
        #expect(probeSource.contains("activeTransport.stopNonBlocking()"))
        #expect(!probeSource.contains("activeTransport.stop()"))
        #expect(!probeSource.contains("repeat"))
        #expect(!probeSource.contains("while true"))
    }

    @Test
    func timelineTickerIsTheOnlyReviewedBoundedTimerAndNeverArmsInCompact() throws {
        let tickerSource = try sourceText("Sources/NotchHubMediaCore/MediaTimelineTicker.swift")
        let rootViewSource = try sourceText("Sources/NotchHubApp/MediaNotchRootView.swift")

        #expect(tickerSource.contains("Timer.scheduledTimer(withTimeInterval:"))
        #expect(tickerSource.contains("let shouldRun = isArmed && isPlaying && anchorCapturedAt != nil"))
        #expect(tickerSource.contains("invalidate()"))
        #expect(!rootViewSource.contains("Timer("))
        #expect(!rootViewSource.contains("Timer.scheduledTimer"))
    }

    @Test
    func peekUIDoesNotResolveSourceIconUnlessExpanded() throws {
        let source = try sourceText("Sources/NotchHubApp/MediaNotchRootView.swift")

        #expect(source.contains("if panelModel.contentPresentation == .expanded"))
        #expect(source.contains("sourceApplicationIconResolver.icon"))
    }

    private func sourceText(_ relativePath: String) throws -> String {
        let testFile = URL(fileURLWithPath: #filePath)
        let repositoryRoot =
            testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}
