import AppKit
import NotchHubCore

@MainActor
final class SystemSnippetClipboardWriter: SnippetClipboardWriting {
    @discardableResult
    func write(_ text: String) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }
}
