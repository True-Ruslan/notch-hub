import AppKit

@MainActor
final class SourceApplicationIconResolver {
    private enum CacheEntry {
        case image(NSImage)
        case missing
    }

    private let workspace: NSWorkspace
    private let capacity: Int
    private var cache: [String: CacheEntry] = [:]
    private var cacheOrder: [String] = []

    init(workspace: NSWorkspace = .shared, capacity: Int = 8) {
        self.workspace = workspace
        self.capacity = max(1, capacity)
    }

    func icon(for bundleIdentifier: String?) -> NSImage? {
        guard let bundleIdentifier = normalizedBundleIdentifier(bundleIdentifier) else {
            return nil
        }

        if let cached = cache[bundleIdentifier] {
            return image(from: cached)
        }

        let entry: CacheEntry
        if let applicationURL = workspace.urlForApplication(
            withBundleIdentifier: bundleIdentifier
        ) {
            entry = .image(workspace.icon(forFile: applicationURL.path))
        } else {
            entry = .missing
        }

        store(entry, for: bundleIdentifier)
        return image(from: entry)
    }

    private func normalizedBundleIdentifier(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }

    private func image(from entry: CacheEntry) -> NSImage? {
        switch entry {
        case .image(let image):
            return image
        case .missing:
            return nil
        }
    }

    private func store(_ entry: CacheEntry, for bundleIdentifier: String) {
        if cache[bundleIdentifier] == nil {
            cacheOrder.append(bundleIdentifier)
        }
        cache[bundleIdentifier] = entry

        while cacheOrder.count > capacity {
            let evicted = cacheOrder.removeFirst()
            cache.removeValue(forKey: evicted)
        }
    }
}
