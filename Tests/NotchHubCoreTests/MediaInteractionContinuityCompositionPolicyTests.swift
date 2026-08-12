import Foundation
import Testing

struct MediaInteractionContinuityCompositionPolicyTests {
    @Test
    func mediaAndHomeChangesUseBoundedEventDrivenCrossfadeWithoutRetainingFakeState() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )

        #expect(source.contains("ZStack"))
        #expect(source.contains(".transition(.opacity)"))
        #expect(source.contains(".id(presentation.sessionIdentity)"))
        #expect(source.contains(".animation("))
        #expect(source.contains(".easeInOut(duration: 0.12)"))
        #expect(source.contains("value: mediaModel.presentation?.sessionIdentity"))
        #expect(!source.contains("Timer("))
        #expect(!source.contains("Timer.publish"))
        #expect(!source.contains("DispatchSourceTimer"))
        #expect(!source.contains("Task.sleep"))
        #expect(!source.contains("lastPresentation"))
    }

    @Test
    func horizontalGestureReleaseSettlesOnlyTheVisualOffsetWithBoundedAnimation() throws {
        let modelSource = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaGestureVisualModel.swift"
        )
        let sessionSource = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaGestureSession.swift"
        )

        #expect(modelSource.contains("func reset(animated: Bool = false)"))
        #expect(modelSource.contains("withAnimation(.easeOut(duration: 0.16))"))
        #expect(sessionSource.contains("case .resetVisualOffset:"))
        #expect(sessionSource.contains("visualModel.reset(animated: true)"))
        #expect(!modelSource.contains("Timer("))
        #expect(!modelSource.contains("Task {"))
        #expect(!modelSource.contains("DispatchSourceTimer"))
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
