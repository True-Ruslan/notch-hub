import Foundation
import Testing

struct MediaMarqueeTextPolicyTests {
    @Test
    func marqueeUsesPhaseAnimatorNotTimerOrRepeatForever() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/MediaMarqueeText.swift")

        #expect(source.contains("struct MediaMarqueeText"))
        #expect(source.contains("PhaseAnimator("))

        #expect(!source.contains("Timer.scheduledTimer"))
        #expect(!source.contains("Timer.publish"))
        #expect(!source.contains("Timer("))
        #expect(!source.contains(".repeatForever"))
        #expect(!source.contains("DispatchSource.makeTimerSource"))
        #expect(!source.contains("CADisplayLink"))
        #expect(!source.contains("CVDisplayLink"))
        #expect(!source.contains("TimelineView"))
        #expect(!source.contains("Task.sleep"))
        #expect(!source.contains("while true"))
    }

    @Test
    func marqueeChecksAccessibilityReduceMotion() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/MediaMarqueeText.swift")

        #expect(source.contains("accessibilityReduceMotion"))
    }

    @Test
    func staticFallbackPreservesLineLimitOneAndTailTruncation() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/MediaMarqueeText.swift")

        #expect(source.contains(".lineLimit(1)"))
        #expect(source.contains(".truncationMode(.tail)"))
    }

    @Test
    func mediaNotchRootViewUsesMarqueeTextForAllFiveSites() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift")

        let occurrences = source.components(separatedBy: "MediaMarqueeText(").count - 1
        #expect(occurrences == 5)

        let peekAndExpandedSection = try sourceSection(
            source,
            from: "private func peekMediaContent",
            to: "private func seekProgress"
        )
        #expect(!peekAndExpandedSection.contains(".truncationMode(.tail)"))
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
