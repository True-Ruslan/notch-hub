import Foundation
import Testing

struct MediaSourceAppIconCompositionPolicyTests {
    @Test
    func appOwnsPublicWorkspaceResolverAndInjectsItIntoMediaRoot() throws {
        let appSource = try sourceText(
            relativePath: "Sources/NotchHubApp/AppDelegate.swift"
        )
        let resolverSource = try sourceText(
            relativePath: "Sources/NotchHubApp/SourceApplicationIconResolver.swift"
        )

        #expect(appSource.contains("private let sourceApplicationIconResolver = SourceApplicationIconResolver()"))
        #expect(appSource.contains("sourceApplicationIconResolver: sourceApplicationIconResolver"))
        #expect(resolverSource.contains("NSWorkspace"))
        #expect(resolverSource.contains("workspace.urlForApplication("))
        #expect(resolverSource.contains("withBundleIdentifier: bundleIdentifier"))
        #expect(resolverSource.contains("icon(forFile:"))
        #expect(resolverSource.contains("capacity: Int = 8"))
        #expect(resolverSource.contains("while cacheOrder.count > capacity"))
        #expect(!resolverSource.contains("FileManager"))
        #expect(!resolverSource.contains("Timer("))
        #expect(!resolverSource.contains("Task {"))
        #expect(!resolverSource.contains("URLSession"))
        #expect(!resolverSource.contains("UserDefaults"))
    }

    @Test
    func expandedMediaUsesIconBadgeAndRemovesPersistentSourceTextChrome() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )
        let expandedSection = try sourceSection(
            source,
            from: "private func expandedMediaContent",
            to: "private func seekProgress"
        )

        #expect(expandedSection.contains("artworkWithSourceBadge"))
        #expect(!expandedSection.contains("sourceDisplayName"))
        #expect(!expandedSection.contains("sourceBundleIdentifier"))
        #expect(!expandedSection.contains("Text(presentation.source"))
        #expect(source.contains("private func sourceApplicationBadge"))
        #expect(source.contains("Image(systemName: \"app\")"))
        #expect(source.contains(".frame(width: 24, height: 24)"))
    }

    @Test
    func peekMediaDoesNotGainSourceIconOrTransportChrome() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )
        let peekSection = try sourceSection(
            source,
            from: "private func peekMediaContent",
            to: "private func expandedMediaContent"
        )

        #expect(!peekSection.contains("sourceApplicationBadge"))
        #expect(!peekSection.contains("sourceDisplayName"))
        #expect(!peekSection.contains("Button(action: onPrevious)"))
        #expect(!peekSection.contains("Button(action: onNext)"))
        #expect(!peekSection.contains("Button(action: onTogglePlayPause)"))
    }

    @Test
    func sourceIdentityRemainsAvailableForAccessibilityWhenTextChromeIsAbsent() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )

        #expect(source.contains(".accessibilityLabel(Text(presentation.sourceDisplayName))"))
    }

    @Test
    func resolverLookupIsRestrictedToExpandedPresentation() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )

        #expect(source.contains(".onChange(of: presentation.sourceBundleIdentifier, initial: true)"))
        #expect(source.contains("if panelModel.contentPresentation == .expanded"))
        #expect(source.contains("sourceApplicationIconResolver.icon(for: bundleIdentifier)"))
        #expect(source.contains(".onChange(of: panelModel.contentPresentation)"))
    }

    private func sourceSection(
        _ source: String,
        from startMarker: String,
        to endMarker: String
    ) throws -> String {
        let start = try #require(source.range(of: startMarker))
        let end = try #require(source.range(of: endMarker, range: start.upperBound..<source.endIndex))
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
