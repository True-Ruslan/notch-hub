import Combine
import Foundation

@MainActor
public final class ShelfStore: ObservableObject {
    @Published public private(set) var items: [ShelfItem] = []
    @Published public private(set) var hasPersistenceError = false

    private let persistence: any ShelfPersisting
    private let bookmarkCodec: any ShelfBookmarkCoding
    private var didLoad = false

    public init(
        persistence: any ShelfPersisting,
        bookmarkCodec: any ShelfBookmarkCoding
    ) {
        self.persistence = persistence
        self.bookmarkCodec = bookmarkCodec
    }

    public func loadIfNeeded() async {
        guard !didLoad else { return }
        didLoad = true
        items = await persistence.load()
    }

    public func add(urls: [URL]) async {
        guard !urls.isEmpty else { return }

        let existingItems = items
        let codec = bookmarkCodec
        let additions = await Task.detached(priority: .userInitiated) {
            var seen = Set<String>()

            for item in existingItems {
                guard let resolution = try? codec.resolve(item.bookmarkData) else {
                    continue
                }
                seen.insert(shelfURLIdentity(resolution.url))
            }

            var prepared: [ShelfItem] = []
            for candidate in urls where candidate.isFileURL {
                let url = candidate.standardizedFileURL
                let identity = shelfURLIdentity(url)
                guard !seen.contains(identity) else { continue }
                guard let bookmarkData = try? codec.makeBookmark(for: url) else { continue }

                let values = try? url.resourceValues(forKeys: [.localizedNameKey, .isDirectoryKey])
                let displayName = values?.localizedName.flatMap { $0.isEmpty ? nil : $0 }
                    ?? url.lastPathComponent
                prepared.append(
                    ShelfItem(
                        bookmarkData: bookmarkData,
                        displayName: displayName,
                        isDirectory: values?.isDirectory ?? false
                    )
                )
                seen.insert(identity)
            }

            return prepared
        }.value

        guard !additions.isEmpty else { return }
        items.append(contentsOf: additions)
        await persistCurrentItems()
    }

    public func remove(id: UUID) async {
        let previousCount = items.count
        items.removeAll { $0.id == id }
        guard items.count != previousCount else { return }
        await persistCurrentItems()
    }

    public func resolve(_ item: ShelfItem) async -> ShelfBookmarkResolution? {
        let codec = bookmarkCodec
        let bookmarkData = item.bookmarkData
        let resolution = await Task.detached(priority: .userInitiated) {
            try? codec.resolve(bookmarkData)
        }.value

        guard let resolution else { return nil }
        if let refreshedBookmarkData = resolution.refreshedBookmarkData,
           let index = items.firstIndex(where: { $0.id == item.id })
        {
            items[index].bookmarkData = refreshedBookmarkData
            await persistCurrentItems()
        }

        return resolution
    }

    private func persistCurrentItems() async {
        do {
            try await persistence.save(items)
            hasPersistenceError = false
        } catch {
            hasPersistenceError = true
        }
    }
}

private func shelfURLIdentity(_ url: URL) -> String {
    url.standardizedFileURL.path
}
