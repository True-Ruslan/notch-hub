import Foundation
import Testing

@testable import NotchHubCore

@MainActor
struct SnippetClipboardPolicyTests {
    @Test
    func clipboardBoundaryExposesOnlyExplicitWrite() {
        let writer = RecordingClipboardWriter()

        #expect(writer.write("docker compose up -d"))
        #expect(writer.writes == ["docker compose up -d"])
    }

    @Test
    func shippingWriterIsWriteOnlyAndSnippetsAddNoObservationOrBroadAuthority() throws {
        let protocolSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Snippets/SnippetClipboardWriting.swift"
        )
        let writerSource = try sourceText(
            relativePath: "Sources/NotchHubApp/Snippets/SystemSnippetClipboardWriter.swift"
        )
        let viewSource = try sourceText(
            relativePath: "Sources/NotchHubApp/Snippets/SnippetsView.swift"
        )
        let combined = protocolSource + "\n" + writerSource + "\n" + viewSource

        #expect(writerSource.contains("NSPasteboard.general"))
        #expect(writerSource.contains("clearContents()"))
        #expect(writerSource.contains("setString(text, forType: .string)"))
        #expect(!viewSource.contains("NSPasteboard"))

        for forbidden in [
            "string(forType:",
            "data(forType:",
            "propertyList(forType:",
            "pasteboardItems",
            "readObjects(",
            "changeCount",
            "Timer(",
            "scheduledTimer",
            "URLSession",
            "WKWebView",
            "addGlobalMonitorForEvents",
            "AXIsProcessTrusted",
            "NSAppleEventDescriptor",
            "print(",
            "NSLog("
        ] {
            #expect(!combined.contains(forbidden))
        }
    }

    @Test
    func shippingEntitlementsRemainExactlyPreSnippetsAuthority() throws {
        let data = try Data(
            contentsOf: repositoryRoot().appendingPathComponent("Resources/NotchHub.entitlements")
        )
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        let dictionary = try #require(plist as? [String: Any])

        #expect(
            Set(dictionary.keys) == [
                "com.apple.security.app-sandbox",
                "com.apple.security.files.user-selected.read-only"
            ]
        )
        #expect(dictionary["com.apple.security.app-sandbox"] as? Bool == true)
        #expect(dictionary["com.apple.security.files.user-selected.read-only"] as? Bool == true)
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

@MainActor
private final class RecordingClipboardWriter: SnippetClipboardWriting {
    private(set) var writes: [String] = []

    @discardableResult
    func write(_ text: String) -> Bool {
        writes.append(text)
        return true
    }
}
