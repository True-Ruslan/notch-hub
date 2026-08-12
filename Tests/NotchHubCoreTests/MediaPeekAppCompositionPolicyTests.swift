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
        #expect(source.contains("guard generation == expectedGeneration"))
    }

    @Test
    func appComposesPeekSessionWithoutStartingPersistentRuntimeForPeek() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/AppDelegate.swift")

        #expect(source.contains("private var mediaPeekSession: MediaPeekSession?"))
        #expect(source.contains("let mediaPeekSession = MediaPeekSession("))
        #expect(source.contains("panelController.hoverPeekRequestHandler"))
        #expect(source.contains("mediaPeekSession.handleHoverRequest(request)"))
        #expect(source.contains("mediaPeekSession.cancel()"))
        #expect(source.contains("mediaPeekSession.invalidate()"))
        #expect(source.contains("case .compact, .peek:"))
        #expect(source.contains("case .expanded:"))
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
