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

    public func add(urls _: [URL]) async {}

    public func remove(id _: UUID) async {}

    public func resolve(_: ShelfItem) async -> ShelfBookmarkResolution? {
        nil
    }
}
