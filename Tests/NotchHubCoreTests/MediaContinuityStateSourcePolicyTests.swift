import Foundation
import Testing

struct MediaContinuityStateSourcePolicyTests {
    @Test
    func runtimeKeepsRetainedPresentationAcrossReadyAndClearsOnlyExplicitLoss() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubMediaCore/ShippingMediaRuntime.swift")

        #expect(source.contains("switch controller.lastChangeKind"))
        #expect(source.contains("case .ready:"))
        #expect(source.contains("break"))
        #expect(source.contains("case .session:"))
        #expect(source.contains("presentationModel.apply("))
        #expect(source.contains("case .noSession, .unavailable:"))
        #expect(source.contains("presentationModel.clearAuthoritativePresentation()"))
    }

    @Test
    func rootDoesNotRemountMediaTreeBySessionIdentity() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift")

        #expect(!source.contains(".id(presentation.sessionIdentity)"))
        #expect(source.contains("value: mediaModel.presentation?.sessionIdentity"))
        #expect(source.contains(".transition(.opacity)"))
    }

    @Test
    func interactiveDownKeepsAuthoritativeMediaBranchBeforeExpandedRuntimeReady() throws {
        let controllerSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift"
        )
        let runtimeSource = try sourceText(relativePath: "Sources/NotchHubMediaCore/ShippingMediaRuntime.swift")

        #expect(controllerSource.contains("model.setContentPresentation(.expanded)"))
        #expect(runtimeSource.contains("case .ready:"))
        #expect(runtimeSource.contains("case .session:"))
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
