import Foundation

public protocol ShelfPersisting: Sendable {
    func load() async -> [ShelfItem]
    func save(_ items: [ShelfItem]) async throws
}

public actor ShelfPersistenceRepository: ShelfPersisting {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func load() async -> [ShelfItem] {
        []
    }

    public func save(_: [ShelfItem]) async throws {}
}
