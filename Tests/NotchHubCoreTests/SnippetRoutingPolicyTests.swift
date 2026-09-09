import Foundation
import Testing

struct SnippetRoutingPolicyTests {
    @Test
    func homeExposesExplicitSnippetsActionWithoutOwningSnippetsState() throws {
        let root = try sourceText(relativePath: "Sources/NotchHubCore/UI/NotchRootView.swift")

        #expect(root.contains("NotchSelectSnippetsAction"))
        #expect(root.contains("notchSelectSnippetsAction"))
        #expect(root.contains("onSelectSnippets"))
        #expect(root.contains("\"home.openSnippets\""))
        #expect(root.contains("moduleTile(\"Snippets\""))
        #expect(!root.contains("SnippetStore"))
    }

    @Test
    func productRoutingOwnsExpandedSnippetsSelectionAndReset() throws {
        let routing = try sourceText(
            relativePath: "Sources/NotchHubApp/ProductRoutingRootView.swift"
        )

        #expect(routing.contains("destinationModel.destination == .snippets"))
        #expect(routing.contains("panelModel.contentPresentation == .expanded"))
        #expect(routing.contains("snippetsContent"))
        #expect(routing.contains("notchSelectSnippetsAction"))
        #expect(routing.contains("destinationModel.select(.snippets)"))
        #expect(routing.contains("\"media.openSnippets\""))
        #expect(routing.contains("destinationModel.reset()"))
    }

    @Test
    func appCompositionOwnsProcessIsolatedSnippetsStateAndInjectedWriter() throws {
        let appDelegate = try sourceText(relativePath: "Sources/NotchHubApp/AppDelegate.swift")

        #expect(appDelegate.contains("private let snippetStore: SnippetStore"))
        #expect(appDelegate.contains("SnippetPersistenceRepository.defaultFileURL()"))
        #expect(appDelegate.contains("\"NotchHub-UITests-\\(ProcessInfo.processInfo.processIdentifier)\""))
        #expect(appDelegate.contains("\"Snippets\""))
        #expect(appDelegate.contains("\"snippets.json\""))
        #expect(appDelegate.contains("SystemSnippetClipboardWriter()"))
        #expect(appDelegate.contains("ProductRoutingRootView("))
        #expect(appDelegate.contains("SnippetsView("))
        #expect(!appDelegate.contains("NSPasteboard"))
    }

    @Test
    func mediaRenderingInternalsRemainIndependentFromSnippetsRouting() throws {
        let media = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )

        #expect(!media.contains("SnippetStore"))
        #expect(!media.contains("SnippetItem"))
        #expect(!media.contains("NotchDestinationModel"))
    }

    private func sourceText(relativePath: String) throws -> String {
        try String(
            contentsOf: repositoryRoot().appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }

    private func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
