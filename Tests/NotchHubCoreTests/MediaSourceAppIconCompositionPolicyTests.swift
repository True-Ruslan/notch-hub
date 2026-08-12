import Foundation
import Testing

struct MediaSourceAppIconCompositionPolicyTests {
    @Test
    func sourceIconResolverUsesOnlyPublicBoundedWorkspaceLookup() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/SourceApplicationIconResolver.swift"
        )

        #expect(source.contains("final class SourceApplicationIconResolver"))
        #expect(source.contains("capacity: Int = 8"))
        #expect(source.contains("urlForApplication(withBundleIdentifier:"))
        #expect(source.contains("workspace.icon(forFile:"))
        #expect(source.contains("private var cache:"))
        #expect(source.contains("private var cacheOrder:"))
        #expect(source.contains("func icon(for bundleIdentifier: String?) -> NSImage?"))
        #expect(!source.contains("FileManager"))
        #expect(!source.contains("Timer"))
        #expect(!source.contains("URLSession"))
        #expect(!source.contains("Process("))
        #expect(!source.contains("MediaRemote"))
    }

    @Test
    func appOwnsResolverAndMediaViewRefreshesIconOnlyWhenSourceIdentityChanges() throws {
        let appSource = try sourceText(
            relativePath: "Sources/NotchHubApp/AppDelegate.swift"
        )
        let viewSource = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )

        #expect(appSource.contains("private let sourceApplicationIconResolver = SourceApplicationIconResolver()"))
        #expect(appSource.contains("sourceApplicationIconResolver: sourceApplicationIconResolver"))
        #expect(viewSource.contains("private let sourceApplicationIconResolver: SourceApplicationIconResolver"))
        #expect(viewSource.contains("@State private var sourceApplicationIcon: NSImage?"))
        #expect(viewSource.contains(".onChange(of: presentation.sourceBundleIdentifier"))
        #expect(viewSource.contains("sourceApplicationIconResolver.icon(for:"))
    }

    @Test
    func expandedMediaUsesIconBadgeInsteadOfPersistentVisualSourceText() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )

        #expect(source.contains("sourceApplicationBadge("))
        #expect(source.contains(".overlay(alignment: .bottomTrailing)"))
        #expect(source.contains(".frame(width: 24, height: 24)"))
        #expect(source.contains("Image(systemName: \"app\")"))
        #expect(source.contains(".accessibilityLabel(Text(presentation.sourceDisplayName))"))
        #expect(!source.contains("Text(presentation.sourceDisplayName)"))

        #expect(source.contains("artwork(presentation, size: 24)"))
        #expect(source.contains("artworkWithSourceBadge(presentation, size: 92)"))
    }

    @Test
    func sourceIconImplementationContainsNoExternalCopiedImplementationMarkers() throws {
        let resolver = try sourceText(
            relativePath: "Sources/NotchHubApp/SourceApplicationIconResolver.swift"
        )
        let view = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )
        let combined = resolver + view

        #expect(!combined.contains("TheBoringNotch"))
        #expect(!combined.contains("BoringNotch"))
        #expect(!combined.contains("boringNotch"))
        #expect(!combined.contains("MusicManager.shared"))
        #expect(!combined.contains("AppIcon(for:"))
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
