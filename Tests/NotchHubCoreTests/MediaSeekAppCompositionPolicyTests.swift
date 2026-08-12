import Foundation
import Testing

struct MediaSeekAppCompositionPolicyTests {
    @Test
    func seekSessionIsIdentityLockedAndOwnsGestureIsolation() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaGestureSession.swift"
        )

        #expect(source.contains("private var activeSeekTransaction: ShippingMediaSeekTransaction?"))
        #expect(source.contains("func beginSeek() -> Bool"))
        #expect(source.contains("panelModel.contentPresentation == .expanded"))
        #expect(source.contains("ShippingMediaSeekTransaction(presentation: presentation)"))
        #expect(source.contains("runtimeProvider()"))
        #expect(source.contains("activeSeekTransaction != nil"))
        #expect(source.contains("guard activeSeekTransaction == nil else"))
        #expect(source.contains("func commitSeek(to positionSeconds: Double)"))
        #expect(source.contains("positionSeconds.isFinite"))
        #expect(source.contains("transaction.accepts(presentation)"))
        #expect(source.contains("runtime.seek(to:"))
        #expect(source.contains("func cancelSeek()"))
        #expect(source.contains("_ = coordinator.invalidate()"))
        #expect(source.contains("compactCapabilityTask?.cancel()"))
        #expect(!source.contains("private var isSeekActive"))
        #expect(!source.contains("compactDispatcher.send(.seek"))
        #expect(!source.contains("Timer("))
        #expect(!source.contains("Task.sleep"))
    }

    @Test
    func expandedMediaUsesLocalDragPreviewAndSingleSemanticCommit() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )

        #expect(source.contains("@State private var seekPreviewSeconds: Double?"))
        #expect(source.contains("DragGesture(minimumDistance: 0)"))
        #expect(source.contains("presentation.canSeek"))
        #expect(source.contains("onSeekBegan"))
        #expect(source.contains("onSeekCommitted"))
        #expect(source.contains("onSeekCancelled"))
        #expect(source.contains("seekPreviewSeconds"))
        #expect(source.contains("ProgressView("))
        #expect(!source.contains("Slider("))
        #expect(!source.contains("Timer("))
        #expect(!source.contains("Task {"))
    }

    @Test
    func seekSurfaceOrMediaIdentityChangeCancelsOwnershipAndUnsupportedProgressIsPassive() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )

        #expect(source.contains("private var isSeekSurfaceAvailable: Bool"))
        #expect(source.contains("panelModel.contentPresentation == .expanded"))
        #expect(source.contains("let presentation = mediaModel.presentation"))
        #expect(source.contains("presentation.canSeek"))
        #expect(source.contains("presentation.positionSeconds"))
        #expect(source.contains("presentation.durationSeconds"))
        #expect(source.contains(".onChange(of: isSeekSurfaceAvailable)"))
        #expect(source.contains(".onChange(of: presentation.sessionIdentity)"))
        #expect(source.contains("cancelSeekPreview()"))
        #expect(source.contains(".onDisappear"))
        #expect(source.contains(".allowsHitTesting(canSeek)"))
    }

    @Test
    func appWiresSeekOnlyThroughExistingExpandedRuntimeSession() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/AppDelegate.swift"
        )

        #expect(source.contains("onSeekBegan:"))
        #expect(source.contains("mediaGestureSession?.beginSeek()"))
        #expect(source.contains("onSeekCommitted:"))
        #expect(source.contains("mediaGestureSession?.commitSeek(to:"))
        #expect(source.contains("onSeekCancelled:"))
        #expect(source.contains("mediaGestureSession?.cancelSeek()"))
        #expect(source.contains("case .expanded:"))
        #expect(source.contains("ShippingMediaRuntime(presentationModel: mediaPresentationModel)"))
        #expect(source.contains("case .compact, .peek:"))
        #expect(source.contains("mediaRuntime?.stop()"))
    }

    @Test
    func compactDispatcherRemainsPreviousNextOnlyAfterSeekWiring() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubMediaCore/ShippingMediaCompactCommandDispatcher.swift"
        )

        #expect(source.contains("case previous"))
        #expect(source.contains("case next"))
        #expect(!source.contains("case seek"))
        #expect(!source.contains(".seek("))
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
