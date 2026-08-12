import Foundation
import Testing

struct MediaGestureAppCompositionPolicyTests {
    @Test
    func appOwnsGestureSessionAndMapsOnlyPublicHapticAndExistingCommandPaths() throws {
        let appSource = try sourceText(
            relativePath: "Sources/NotchHubApp/AppDelegate.swift"
        )
        let sessionSource = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaGestureSession.swift"
        )

        #expect(appSource.contains("MediaGestureSession("))
        #expect(appSource.contains("ShippingMediaCompactCommandDispatcher()"))
        #expect(appSource.contains("NSHapticFeedbackManager.defaultPerformer"))
        #expect(appSource.contains(".levelChange"))
        #expect(appSource.contains("ShippingMediaRuntime(presentationModel: mediaPresentationModel)"))

        #expect(sessionSource.contains("event.hasPreciseScrollingDeltas"))
        #expect(sessionSource.contains("event.momentumPhase.isEmpty"))
        #expect(sessionSource.contains("MediaGestureInputNormalizer.semanticDeltas("))
        #expect(sessionSource.contains("case .compact:"))
        #expect(sessionSource.contains("case .peek:"))
        #expect(sessionSource.contains("case .expanded:"))
        #expect(sessionSource.contains("compactDispatcher.isSupported(action)"))
        #expect(sessionSource.contains("let compactDispatcher = compactDispatcher"))
        #expect(sessionSource.contains("compactDispatcher.send(action)"))
        #expect(sessionSource.contains("runtimeProvider()?.goPrevious()"))
        #expect(sessionSource.contains("runtimeProvider()?.goNext()"))
        #expect(sessionSource.contains("compactDispatcher.seek(to: positionSeconds)"))
        #expect(sessionSource.contains("runtime.seek(to: positionSeconds)"))

        #expect(!appSource.contains("NSEvent.addGlobalMonitorForEvents"))
        #expect(!appSource.contains("NSEvent.addLocalMonitorForEvents"))
        #expect(!sessionSource.contains("NSEvent.addGlobalMonitorForEvents"))
        #expect(!sessionSource.contains("NSEvent.addLocalMonitorForEvents"))
        #expect(!sessionSource.contains("CGEventTap"))
        #expect(!sessionSource.contains("MPRemoteCommandCenter"))
    }

    @Test
    func gestureSessionOwnsOnlySemanticBoundaryTasksAndNoPerEventWorker() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaGestureSession.swift"
        )

        #expect(source.contains("compactCapabilityTask = Task"))
        #expect(source.contains("Task {\n                _ = await compactDispatcher.send(action)"))
        #expect(source.contains("Task {\n                _ = await compactDispatcher.seek(to: positionSeconds)"))
        #expect(!source.contains("Task {\n            let deltas"))
        #expect(!source.contains("Timer("))
        #expect(!source.contains("Task.sleep"))
        #expect(!source.contains("CVDisplayLink"))
    }

    @Test
    func compactAndPeekUseBoundedDispatcherWhileExpandedUsesLiveRuntime() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaGestureSession.swift"
        )

        #expect(source.contains("guard surface == .compact || surface == .peek else"))
        #expect(source.contains("case .compact, .peek:"))
        #expect(source.contains("compactDispatcher.send(action)"))
        #expect(source.contains("case .expanded:"))
        #expect(source.contains("runtimeProvider()?.goPrevious()"))
        #expect(source.contains("runtimeProvider()?.goNext()"))
    }

    @Test
    func scrollMayBeginAndBeganCancelPendingHoverBeforeGestureOwnership() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaGestureSession.swift"
        )

        #expect(source.contains("event.phase.contains(.mayBegin)"))
        #expect(source.contains("panelController?.cancelPendingHoverActivation()"))
        #expect(source.contains("if phase == .began"))
        #expect(source.contains("beginPhysicalGesture()"))
    }

    @Test
    func peekGestureAndSeekHoldCollapseGraceOnlyWhileInteractionIsOwned() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaGestureSession.swift"
        )

        #expect(source.contains("activeSurface = .peek"))
        #expect(source.contains("panelController?.setPeekInteractionHeld(true)"))
        #expect(source.contains("panelController?.setPeekInteractionHeld(false)"))
        #expect(source.contains("releasePeekInteractionHoldIfNeeded"))
        #expect(source.contains("activeSeekSurface = seekSurface"))
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
