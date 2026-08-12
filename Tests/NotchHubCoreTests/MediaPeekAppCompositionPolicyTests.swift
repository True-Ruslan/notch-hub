import Foundation
import Testing

struct MediaPeekAppCompositionPolicyTests {
    @Test
    func peekSessionUsesCachedFirstThenExactlyOneBoundedProbe() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/MediaPeekSession.swift")

        #expect(source.contains("final class MediaPeekSession"))
        #expect(source.contains("func handleHoverRequest(_ request: NotchHoverPeekRequest)"))
        #expect(source.contains("presentationModel.presentation != nil"))
        #expect(source.contains("resolveHoverPeekRequest(request, mediaAvailable: true)"))
        #expect(source.contains("probe.acquire"))
        #expect(source.contains("activeRequest"))
        #expect(source.contains("generation"))
        #expect(!source.contains("Timer.scheduledTimer"))
        #expect(!source.contains("Timer.publish"))
        #expect(!source.contains("DispatchSource.makeTimerSource"))
        #expect(!source.contains("CVDisplayLink"))
        #expect(!source.contains("Task.sleep"))
    }

    @Test
    func positiveNoSessionAndFailureResultsRemainFailClosed() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/MediaPeekSession.swift")

        #expect(source.contains("case .presentation(let presentation)"))
        #expect(source.contains("presentationModel.applyOneShotPresentation(presentation)"))
        #expect(source.contains("resolveHoverPeekRequest(request, mediaAvailable: true)"))
        #expect(source.contains("case .noSession:"))
        #expect(source.contains("presentationModel.clearAuthoritativePresentation()"))
        #expect(source.contains("resolveHoverPeekRequest(request, mediaAvailable: false)"))
        #expect(source.contains("panelController.requestCollapse()"))
        #expect(source.contains("case .failed:"))
        #expect(!source.contains("case .failed:\n            presentationModel.clearAuthoritativePresentation()"))
    }

    @Test
    func cancellationRejectsLateProbeAndReleasesTemporaryOwnership() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/MediaPeekSession.swift")

        #expect(source.contains("func cancel()"))
        #expect(source.contains("func invalidate()"))
        #expect(source.contains("probe.cancel()"))
        #expect(source.contains("generation &+= 1"))
        #expect(source.contains("generation == expectedGeneration"))
    }

    @Test
    func appComposesPeekSessionWithoutStartingPersistentRuntimeForPeek() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/AppDelegate.swift")

        #expect(source.contains("private var mediaPeekSession: MediaPeekSession?"))
        #expect(source.contains("let mediaPeekSession = MediaPeekSession("))
        #expect(source.contains("panelController.hoverPeekRequestHandler"))
        #expect(source.contains("mediaPeekSession?.handleHoverRequest(request)"))
        #expect(source.contains("mediaPeekSession.cancel()"))
        #expect(source.contains("mediaPeekSession.invalidate()"))
        #expect(source.contains("case .compact, .peek:"))
        #expect(source.contains("case .expanded:"))
    }

    @Test
    func gestureSessionMapsPeekToDedicatedSurfaceAndHoldsGraceDuringOwnedInput() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/MediaGestureSession.swift")

        #expect(source.contains("case .peek:"))
        #expect(source.contains("activeSurface = .peek"))
        #expect(source.contains("panelController?.setPeekInteractionHeld(true)"))
        #expect(source.contains("panelController?.setPeekInteractionHeld(false)"))
        #expect(source.contains("case .compact, .peek:"))
        #expect(source.contains("requestCompactCapability"))
        #expect(source.contains("panelController?.requestExpansion()"))
    }

    @Test
    func peekSeekUsesBoundedDispatcherWhileExpandedSeekKeepsRuntime() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/MediaGestureSession.swift")

        #expect(source.contains("private var activeSeekSurface: MediaGestureSurface?"))
        #expect(source.contains("case .peek:"))
        #expect(source.contains("compactDispatcher.seek(to: positionSeconds)"))
        #expect(source.contains("case .expanded:"))
        #expect(source.contains("runtime.seek(to: positionSeconds)"))
        #expect(source.contains("ShippingMediaSeekTransaction(presentation: presentation)"))
    }

    @Test
    func rootViewHasRealOneLinePeekAndExplicitExpansionWithoutTransportButtons() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift")
        let peekSection = try sourceSection(
            source,
            from: "private func peekMediaContent",
            to: "private func expandedMediaContent"
        )

        #expect(source.contains("case .peek:"))
        #expect(source.contains("peekMediaContent(presentation)"))
        #expect(peekSection.contains("artwork(presentation, size: 40)"))
        #expect(peekSection.contains("onExplicitExpansion"))
        #expect(source.contains("panelModel.contentPresentation == .peek"))
        #expect(source.contains("panelModel.contentPresentation == .expanded"))
        #expect(!peekSection.contains("sourceApplicationBadge"))
        #expect(!peekSection.contains("Button(action: onPrevious)"))
        #expect(!peekSection.contains("Button(action: onNext)"))
        #expect(!peekSection.contains("Button(action: onTogglePlayPause)"))
    }

    @Test
    func explicitClickExpansionIsWiredForMediaAndNoMediaCompactStates() throws {
        let appSource = try sourceText(relativePath: "Sources/NotchHubApp/AppDelegate.swift")
        let rootSource = try sourceText(relativePath: "Sources/NotchHubCore/UI/NotchRootView.swift")

        #expect(appSource.contains("onExplicitExpansion:"))
        #expect(appSource.contains("self?.panelController?.requestExpansion()"))
        #expect(rootSource.contains("onExplicitExpansion"))
        #expect(rootSource.contains(".onTapGesture"))
    }

    private func sourceSection(
        _ source: String,
        from startMarker: String,
        to endMarker: String
    ) throws -> String {
        let start = try #require(source.range(of: startMarker))
        let end = try #require(source.range(of: endMarker, range: start.upperBound..<source.endIndex))
        return String(source[start.lowerBound..<end.lowerBound])
    }

    private func sourceText(relativePath: String) throws -> String {
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
