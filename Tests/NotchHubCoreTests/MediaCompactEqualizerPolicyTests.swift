import Foundation
import Testing

struct MediaCompactEqualizerPolicyTests {
    @Test
    func equalizerAnimationIsDeclarativeAndArmedOnlyWhilePlaying() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaCompactEqualizerView.swift"
        )

        #expect(source.contains("struct MediaCompactEqualizerView"))
        #expect(source.contains("let isPlaying: Bool"))
        #expect(source.contains(".repeatForever(autoreverses: true)"))
        #expect(source.contains("isPlaying"))

        #expect(!source.contains("Timer.scheduledTimer"))
        #expect(!source.contains("Timer.publish"))
        #expect(!source.contains("Timer("))
        #expect(!source.contains("DispatchSource.makeTimerSource"))
        #expect(!source.contains("CADisplayLink"))
        #expect(!source.contains("CVDisplayLink"))
        #expect(!source.contains("Task.sleep"))
        #expect(!source.contains("while true"))
    }

    @Test
    func compactMediaContentUsesTheEqualizerInsteadOfAStaticGlyph() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )
        let compactSection = try sourceSection(
            source,
            from: "private func compactMediaContent",
            to: "private func peekMediaContent"
        )

        #expect(compactSection.contains("MediaCompactEqualizerView("))
        #expect(!compactSection.contains("systemName: presentation.playbackState == .playing"))
    }

    private func sourceSection(
        _ source: String,
        from startMarker: String,
        to endMarker: String
    ) throws -> String {
        let start = try #require(source.range(of: startMarker))
        let end = try #require(
            source.range(of: endMarker, range: start.upperBound..<source.endIndex)
        )
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
