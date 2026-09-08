import Foundation
import Testing

struct ShelfQuickLookPolicyTests {
    @Test
    func shelfExposesSingleItemPreviewAction() throws {
        let shelf = try sourceText(relativePath: "Sources/NotchHubApp/Shelf/ShelfView.swift")

        #expect(shelf.contains("shelf.item.\\(item.id.uuidString).preview"))
        #expect(shelf.contains("await preview(item)"))
        #expect(shelf.contains("ShelfQuickLookController"))
    }

    @Test
    func quickLookControllerUsesNativePanelAndBalancedPreviewLifecycle() throws {
        let relativePath = "Sources/NotchHubApp/Shelf/ShelfQuickLookController.swift"
        let url = repositoryRoot().appendingPathComponent(relativePath)
        let exists = FileManager.default.fileExists(atPath: url.path)
        #expect(exists)
        guard exists else {
            return
        }

        let controller = try String(contentsOf: url, encoding: .utf8)
        for required in [
            "import QuickLookUI",
            "QLPreviewPanelDataSource",
            "QLPreviewPanelDelegate",
            "numberOfPreviewItems(in",
            "previewPanel(",
            "windowWillClose",
            "accessSession.begin(url:",
            "accessSession.end()",
            "panel.dataSource = self",
            "panel.delegate = self",
            "panel.reloadData()",
            "panel.makeKeyAndOrderFront(nil)"
        ] {
            #expect(controller.contains(required))
        }
    }

    @Test
    func quickLookAddsNoPollingNetworkingOrFileMutationAuthority() throws {
        let relativePath = "Sources/NotchHubApp/Shelf/ShelfQuickLookController.swift"
        let url = repositoryRoot().appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            Issue.record("missing ShelfQuickLookController.swift")
            return
        }

        let controller = try String(contentsOf: url, encoding: .utf8)
        for forbidden in [
            "Timer(",
            "DispatchSourceTimer",
            "URLSession",
            "addGlobalMonitorForEvents",
            "removeItem(",
            "moveItem(",
            "trashItem"
        ] {
            #expect(!controller.contains(forbidden))
        }
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
