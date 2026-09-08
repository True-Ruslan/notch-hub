import Foundation
import Testing

struct ShelfUIPolicyTests {
    @Test
    func shelfSurfaceUsesNativePickerLocalDropAndStableAccessibilityContract() throws {
        let shelf = try sourceText(relativePath: "Sources/NotchHubApp/Shelf/ShelfView.swift")

        for identifier in [
            "shelf.surface",
            "shelf.addFiles",
            "shelf.emptyDropZone",
            "shelf.home",
        ] {
            #expect(shelf.contains("\"\(identifier)\""))
        }

        #expect(shelf.contains("NSOpenPanel()"))
        #expect(shelf.contains("canChooseFiles = true"))
        #expect(shelf.contains("canChooseDirectories = true"))
        #expect(shelf.contains("allowsMultipleSelection = true"))
        #expect(shelf.contains("dropDestination(for: URL.self)"))
    }

    @Test
    func shelfSourceCannotMutateFilesPollOrInstallGlobalInputMonitoring() throws {
        let shelf = try sourceText(relativePath: "Sources/NotchHubApp/Shelf/ShelfView.swift")
        let store = try sourceText(relativePath: "Sources/NotchHubCore/Shelf/ShelfStore.swift")
        let combined = shelf + "\n" + store

        for forbidden in [
            "removeItem(",
            "moveItem(",
            "trashItem",
            "Timer(",
            "DispatchSourceTimer",
            "addGlobalMonitorForEvents",
            "URLSession",
        ] {
            #expect(!combined.contains(forbidden))
        }
    }

    @Test
    func expandedHomeAndMediaExposeShelfSelectionWithoutChangingCompactPeekSemantics() throws {
        let root = try sourceText(relativePath: "Sources/NotchHubCore/UI/NotchRootView.swift")
        let media = try sourceText(relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift")

        #expect(root.contains("\"home.openShelf\""))
        #expect(root.contains("onSelectShelf"))
        #expect(media.contains("\"media.openShelf\""))
        #expect(media.contains("destinationModel.destination == .shelf"))
        #expect(media.contains("panelModel.contentPresentation == .expanded"))
        #expect(media.contains("destinationModel.reset()"))
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
