@MainActor
public protocol SnippetClipboardWriting {
    @discardableResult
    func write(_ text: String) -> Bool
}
