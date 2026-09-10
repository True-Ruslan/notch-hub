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
            "shelf.home"
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
            "URLSession"
        ] {
            #expect(!combined.contains(forbidden))
        }
    }

    @Test
    func expandedRoutingOwnsShelfSelectionWithoutModifyingMediaRenderingInternals() throws {
        let root = try sourceText(relativePath: "Sources/NotchHubCore/UI/NotchRootView.swift")
        let routing = try sourceText(relativePath: "Sources/NotchHubApp/ProductRoutingRootView.swift")
        let media = try sourceText(relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift")

        #expect(root.contains("\"home.openShelf\""))
        #expect(root.contains("onSelectShelf"))
        #expect(routing.contains("\"media.openShelf\""))
        #expect(routing.contains("destinationModel.destination == .shelf"))
        #expect(routing.contains("panelModel.contentPresentation == .expanded"))
        #expect(routing.contains("destinationModel.reset()"))
        #expect(!media.contains("ShelfStore"))
        #expect(!media.contains("NotchDestinationModel"))

        let legacyRouting = repositoryRoot()
            .appendingPathComponent("Sources/NotchHubApp/Shelf/ShelfRoutingRootView.swift")
        #expect(!FileManager.default.fileExists(atPath: legacyRouting.path))
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
