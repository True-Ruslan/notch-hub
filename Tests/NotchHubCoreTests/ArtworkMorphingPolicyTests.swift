import Foundation
import Testing

struct ArtworkMorphingPolicyTests {
    @Test
    func mediaNotchRootViewSharesOneMatchedGeometryNamespaceForArtwork() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift")

        #expect(source.contains("@Namespace private var artworkNamespace"))

        let occurrences =
            source.components(separatedBy: "matchedGeometryEffect(id: \"media.artwork\", in: artworkNamespace)")
            .count - 1
        #expect(occurrences == 1)
    }

    @Test
    func mediaNotchRootViewAnimatesContentPresentationSwitchWithoutNewTimerPrimitive() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift")

        #expect(source.contains("value: panelModel.contentPresentation"))

        #expect(!source.contains("Timer.scheduledTimer"))
        #expect(!source.contains("Timer.publish"))
        #expect(!source.contains("Timer("))
        #expect(!source.contains(".repeatForever"))
        #expect(!source.contains("DispatchSource.makeTimerSource"))
        #expect(!source.contains("CADisplayLink"))
        #expect(!source.contains("CVDisplayLink"))
        #expect(!source.contains("Task.sleep"))
        #expect(!source.contains("while true"))
    }

    @Test
    func notchAnimationDurationProviderIsPublicForCrossModuleReuse() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchAnimationDurationProvider.swift"
        )

        #expect(source.contains("public let notchStandardAnimationDuration"))
        #expect(source.contains("public func notchAnimationDuration(reduceMotion: Bool)"))
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
