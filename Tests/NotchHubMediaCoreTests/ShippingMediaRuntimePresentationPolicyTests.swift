import Foundation
import Testing

struct ShippingMediaRuntimePresentationPolicyTests {
    @Test
    func runtimePublishesControllerStateThroughAppOwnedPresentationModel() throws {
        let source = try runtimeSource()

        #expect(source.contains("private let presentationModel: ShippingMediaPresentationModel"))
        #expect(source.contains("public convenience init(presentationModel: ShippingMediaPresentationModel)"))
        #expect(source.contains("controller.changeHandler ="))
        #expect(source.contains("switch controller.lastChangeKind"))
        #expect(source.contains("case .ready:"))
        #expect(source.contains("case .session:"))
        #expect(source.contains("presentationModel.apply("))
        #expect(source.contains("state: controller.state"))
        #expect(source.contains("snapshot: controller.snapshot"))
        #expect(source.contains("case .noSession, .unavailable:"))
        #expect(source.contains("presentationModel.clearAuthoritativePresentation()"))
    }

    @Test
    func normalStopDetachesPresentationCallbackBeforeControllerStop() throws {
        let source = try runtimeSource()
        let detachRange = try #require(source.range(of: "controller?.changeHandler = nil"))
        let stopRange = try #require(source.range(of: "controller?.stop()"))

        #expect(detachRange.lowerBound < stopRange.lowerBound)
    }

    @Test
    func runtimeExposesOnlyTypedMediaCommandsIncludingValidatedSeek() throws {
        let source = try runtimeSource()

        #expect(source.contains("public func togglePlayPause()"))
        #expect(source.contains("public func goPrevious()"))
        #expect(source.contains("public func goNext()"))
        #expect(source.contains("public func seek(to positionSeconds: Double)"))
        #expect(source.contains("positionSeconds.isFinite"))
        #expect(source.contains("positionSeconds >= 0"))
        #expect(source.contains("send(.togglePlayPause)"))
        #expect(source.contains("send(.previous)"))
        #expect(source.contains("send(.next)"))
        #expect(source.contains("send(.seek(seconds: positionSeconds))"))
    }

    @Test
    func runtimePresentationWiringAddsNoPollingOrProcessBoundary() throws {
        let source = try runtimeSource()

        #expect(!source.contains("Timer("))
        #expect(!source.contains("Timer.publish"))
        #expect(!source.contains("DispatchSourceTimer"))
        #expect(!source.contains("sleep("))
        #expect(!source.contains("Process()"))
    }

    private func runtimeSource() throws -> String {
        try sourceText(relativePath: "Sources/NotchHubMediaCore/ShippingMediaRuntime.swift")
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
