import Foundation
import Testing

struct ShelfSharePolicyTests {
    @Test
    func shelfExposesSingleItemShareAction() throws {
        let shelf = try sourceText(relativePath: "Sources/NotchHubApp/Shelf/ShelfView.swift")

        #expect(shelf.contains("shelf.item.\\(item.id.uuidString).share"))
        #expect(shelf.contains("await share(item)"))
        #expect(shelf.contains("ShelfShareController"))
    }

    @Test
    func shareControllerUsesNativeSharingPickerAndBalancedLifecycle() throws {
        let relativePath = "Sources/NotchHubApp/Shelf/ShelfShareController.swift"
        let url = repositoryRoot().appendingPathComponent(relativePath)
        let exists = FileManager.default.fileExists(atPath: url.path)
        #expect(exists)
        guard exists else {
            return
        }

        let controller = try String(contentsOf: url, encoding: .utf8)
        for required in [
            "NSSharingServicePickerDelegate",
            "NSSharingServiceDelegate",
            "NSSharingServicePicker(items:",
            "picker.delegate = self",
            "picker.show(relativeTo:",
            "accessSession.begin(url:",
            "accessSession.end()",
            "didChoose service:",
            "delegateFor sharingService:",
            "didShareItems",
            "didFailToShareItems"
        ] {
            #expect(controller.contains(required))
        }
    }

    @Test
    func replacementClosesPriorShareBeforeAcquiringNewSecurityScope() throws {
        let relativePath = "Sources/NotchHubApp/Shelf/ShelfShareController.swift"
        let url = repositoryRoot().appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            Issue.record("missing ShelfShareController.swift")
            return
        }

        let controller = try String(contentsOf: url, encoding: .utf8)
        guard
            let replacementCleanup = controller.range(of: "if picker != nil"),
            let newScope = controller.range(of: "guard accessSession.begin(url: url)")
        else {
            Issue.record("missing replacement cleanup or scope acquisition")
            return
        }
        #expect(replacementCleanup.lowerBound < newScope.lowerBound)
    }

    @Test
    func cancellationSuccessAndFailureReleaseShareScope() throws {
        let relativePath = "Sources/NotchHubApp/Shelf/ShelfShareController.swift"
        let url = repositoryRoot().appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            Issue.record("missing ShelfShareController.swift")
            return
        }

        let controller = try String(contentsOf: url, encoding: .utf8)
        #expect(controller.contains("if service == nil"))
        #expect(controller.contains("didShareItems"))
        #expect(controller.contains("didFailToShareItems"))
        #expect(controller.components(separatedBy: "close()").count >= 4)
    }

    @Test
    func shareControllerAddsNoCustomNetworkPollingOrFileMutationAuthority() throws {
        let relativePath = "Sources/NotchHubApp/Shelf/ShelfShareController.swift"
        let url = repositoryRoot().appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            Issue.record("missing ShelfShareController.swift")
            return
        }

        let controller = try String(contentsOf: url, encoding: .utf8)
        for forbidden in [
            "Timer(",
            "DispatchSourceTimer",
            "URLSession",
            "NWConnection",
            "addGlobalMonitorForEvents",
            "removeItem(",
            "moveItem(",
            "trashItem"
        ] {
            #expect(!controller.contains(forbidden))
        }
    }

    @Test
    func appOwnsAndTerminatesShareController() throws {
        let appDelegate = try sourceText(relativePath: "Sources/NotchHubApp/AppDelegate.swift")
        let routing = try sourceText(
            relativePath: "Sources/NotchHubApp/Shelf/ShelfRoutingRootView.swift"
        )

        #expect(appDelegate.contains("private let shelfShareController = ShelfShareController()"))
        #expect(appDelegate.contains("shareController: shelfShareController"))
        #expect(appDelegate.contains("shelfShareController.close()"))
        #expect(routing.contains("ShelfShareController"))
        #expect(routing.contains("shareController:"))
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
