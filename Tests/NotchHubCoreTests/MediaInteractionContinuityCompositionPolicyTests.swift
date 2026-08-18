import Foundation
import Testing

struct MediaInteractionContinuityCompositionPolicyTests {
    @Test
    func mediaRootKeepsStableViewIdentityAcrossSessionChanges() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )

        #expect(source.contains(".transition(.opacity)"))
        #expect(source.contains(".easeInOut(duration: 0.12)"))
        #expect(source.contains("value: mediaModel.presentation?.sessionIdentity"))
        #expect(!source.contains(".id(presentation.sessionIdentity)"))
        #expect(!source.contains("Timer("))
        #expect(!source.contains("Task.sleep"))
        #expect(!source.contains("CVDisplayLink"))
    }

    @Test
    func shippingRuntimePreservesRetainedMediaAcrossReadyAndClearsOnlyExplicitLoss() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubMediaCore/ShippingMediaRuntime.swift"
        )

        #expect(source.contains("switch controller.lastChangeKind"))
        #expect(source.contains("case .ready:"))
        #expect(source.contains("case .session:"))
        #expect(source.contains("presentationModel.apply("))
        #expect(source.contains("case .noSession, .unavailable:"))
        #expect(source.contains("presentationModel.clearAuthoritativePresentation()"))
    }

    @Test
    func controllerPublishesExplicitNoSessionEvenAfterReadyIdle() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubMediaCore/MediaSessionController.swift"
        )

        #expect(source.contains("enum MediaSessionChangeKind"))
        #expect(source.contains("case ready"))
        #expect(source.contains("case session"))
        #expect(source.contains("case noSession"))
        #expect(source.contains("case unavailable"))
        #expect(source.contains("kind: .noSession"))
        #expect(source.contains("force: true"))
    }

    @Test
    func horizontalVisualResetUsesBoundedAnimationOnlyForSemanticReset() throws {
        let sessionSource = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaGestureSession.swift"
        )
        let visualSource = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaGestureVisualModel.swift"
        )

        #expect(visualSource.contains("func reset(animated: Bool = false)"))
        #expect(visualSource.contains("withAnimation(.easeOut(duration: 0.16))"))
        #expect(sessionSource.contains("case .resetVisualOffset:"))
        #expect(sessionSource.contains("visualModel.reset(animated: true)"))
        #expect(sessionSource.contains("visualModel.reset()"))
        #expect(!visualSource.contains("Timer("))
        #expect(!visualSource.contains("Task"))
    }

    @Test
    func compactDownSelectsExpandedMediaPresentationBeforeRuntimeReady() throws {
        let transitionSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift"
        )
        let runtimeSource = try sourceText(
            relativePath: "Sources/NotchHubMediaCore/ShippingMediaRuntime.swift"
        )

        #expect(transitionSource.contains("model.setContentPresentation(.expanded)"))
        #expect(runtimeSource.contains("case .ready:"))
        #expect(runtimeSource.contains("break"))
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
