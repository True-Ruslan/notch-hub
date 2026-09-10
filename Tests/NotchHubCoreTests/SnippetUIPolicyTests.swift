import Foundation
import Testing

struct SnippetUIPolicyTests {
    @Test
    func snippetsSurfaceUsesStableAccessibilityAndExplicitMutationActions() throws {
        let view = try sourceText(
            relativePath: "Sources/NotchHubApp/Snippets/SnippetsView.swift"
        )

        for identifier in [
            "snippets.surface",
            "snippets.home",
            "snippets.add",
            "snippets.empty",
            "snippets.editor",
            "snippets.editor.text",
            "snippets.editor.save",
            "snippets.editor.cancel"
        ] {
            #expect(view.contains("\"\(identifier)\""))
        }

        #expect(view.contains("TextEditor("))
        #expect(view.contains("store.add(text:"))
        #expect(view.contains("store.update(id:"))
        #expect(view.contains("store.remove(id:"))
        #expect(view.contains("clipboardWriter.write(item.text)"))
        #expect(view.contains("confirmationDialog("))

        #expect(view.contains("snippets.item.\\(item.id.uuidString).copy"))
        #expect(view.contains("snippets.item.\\(item.id.uuidString).edit"))
        #expect(view.contains("snippets.item.\\(item.id.uuidString).delete"))
        #expect(!view.contains("NSPasteboard"))
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
