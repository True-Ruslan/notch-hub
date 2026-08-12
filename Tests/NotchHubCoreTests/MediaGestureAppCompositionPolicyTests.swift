import Foundation
import Testing

struct MediaGestureAppCompositionPolicyTests {
    @Test
    func appOwnsLocalGestureSessionAndKeepsMediaRuntimeSettledPresentationScoped() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/AppDelegate.swift"
        )

        #expect(source.contains("private let mediaGestureVisualModel = MediaGestureVisualModel()"))
        #expect(source.contains("private var mediaGestureSession: MediaGestureSession?"))
        #expect(source.contains("ShippingMediaCompactCommandDispatcher()"))
        #expect(source.contains("MediaGestureSession("))
        #expect(source.contains("onScrollWheel:"))
        #expect(source.contains("handleScrollWheel(event)"))
        #expect(source.contains("mediaGestureSession.bind("))
        #expect(source.contains("mediaGestureSession?.invalidate()"))
        #expect(source.contains("settledPresentationHandler ="))
        #expect(source.contains("updateMediaRuntime(for: presentation)"))
        #expect(occurrenceCount(of: "ShippingMediaRuntime(", in: source) == 1)
        #expect(!source.contains("addGlobalMonitorForEvents"))
        #expect(!source.contains("addLocalMonitorForEvents"))
        #expect(!source.contains("CGEventTap"))
        #expect(!source.contains("NSPanel.setFrame"))
    }

    @Test
    func gestureSessionUsesPrecisePhysicalDeviceDirectionAndIgnoresMomentum() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaGestureSession.swift"
        )

        #expect(source.contains("event.hasPreciseScrollingDeltas"))
        #expect(source.contains("event.momentumPhase.isEmpty"))
        #expect(source.contains("event.isDirectionInvertedFromDevice"))
        #expect(source.contains("event.scrollingDeltaX"))
        #expect(source.contains("event.scrollingDeltaY"))
        #expect(source.contains("MediaGestureSample("))
        #expect(source.contains("case .began:"))
        #expect(source.contains("case .changed:"))
        #expect(source.contains("case .ended:"))
        #expect(source.contains("case .cancelled:"))
        #expect(source.contains("event.window?.contentView?.bounds.width"))
        #expect(!source.contains("Timer("))
        #expect(!source.contains("Timer.publish"))
        #expect(!source.contains("DispatchSourceTimer"))
        #expect(!source.contains("sleep("))
    }

    @Test
    func gestureSessionCapturesSurfaceAndRoutesOnlyApprovedSemanticEffects() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaGestureSession.swift"
        )

        #expect(source.contains("panelModel.contentPresentation"))
        #expect(source.contains("activeSurface"))
        #expect(source.contains("compactDispatcher.isSupported("))
        #expect(source.contains("coordinator.resolveCompactCapability("))
        #expect(source.contains("compactDispatcher.send("))
        #expect(source.contains("runtimeProvider()?"))
        #expect(source.contains("performArmHaptic()"))
        #expect(source.contains("beginInteractiveExpansion()"))
        #expect(source.contains("beginInteractiveCollapse()"))
        #expect(source.contains("updateInteractiveTransition(verticalDistance:"))
        #expect(source.contains("finishInteractiveTransition(commit:"))
        #expect(source.contains("visualModel.setHorizontalOffset("))
        #expect(source.contains("visualModel.reset()"))
        #expect(!source.contains("ShippingMediaRuntime("))
        #expect(!source.contains("startObservation"))
        #expect(!source.contains("NSPanel"))
        #expect(!source.contains("addGlobalMonitorForEvents"))
        #expect(!source.contains("addLocalMonitorForEvents"))
        #expect(!source.contains("CGEventTap"))
    }

    @Test
    func compactCapabilityWorkIsGenerationSafeAndLifecycleOwned() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaGestureSession.swift"
        )

        #expect(source.contains("private var compactCapabilityTask: Task<Void, Never>?"))
        #expect(source.contains("compactCapabilityTask?.cancel()"))
        #expect(source.contains("Task.isCancelled"))
        #expect(source.contains("gestureID:"))
        #expect(source.contains("direction:"))
        #expect(source.contains("compactDispatcher.stop()"))
        #expect(source.contains("coordinator.invalidate()"))
        #expect(source.contains("func invalidate()"))
    }

    @Test
    func horizontalVisualModelIsBoundedAndAppliedInsideStableMediaBackground() throws {
        let modelSource = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaGestureVisualModel.swift"
        )
        let rootSource = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )

        #expect(modelSource.contains("@Published private(set) var horizontalOffset: CGFloat = 0"))
        #expect(modelSource.contains("func setHorizontalOffset("))
        #expect(modelSource.contains("func reset()"))
        #expect(modelSource.contains("case .compact"))
        #expect(modelSource.contains("case .expanded"))

        #expect(rootSource.contains("@ObservedObject private var mediaGestureVisualModel"))
        #expect(rootSource.contains("mediaGestureVisualModel: MediaGestureVisualModel"))
        #expect(rootSource.contains(".offset(x: mediaGestureVisualModel.horizontalOffset)"))
        #expect(rootSource.contains(".background(Color.black)"))
    }

    @Test
    func appHapticUsesPublicSemanticAppKitFeedbackOnly() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/AppDelegate.swift"
        )

        #expect(source.contains("NSHapticFeedbackManager.defaultPerformer.perform("))
        #expect(source.contains(".levelChange"))
        #expect(source.contains("performanceTime: .now"))
        #expect(!source.contains("NSSound"))
        #expect(!source.contains("IOHID"))
    }

    private func occurrenceCount(of needle: String, in haystack: String) -> Int {
        haystack.components(separatedBy: needle).count - 1
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
