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

    public static func defaultFileURL(fileManager: FileManager = .default) -> URL {
        let baseURL =
            fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first ?? fileManager.temporaryDirectory

        return
            baseURL
            .appendingPathComponent("NotchHub", isDirectory: true)
            .appendingPathComponent("Shelf", isDirectory: true)
            .appendingPathComponent("items.json", isDirectory: false)
    }

    public func load() async -> [ShelfItem] {
        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }

        return (try? JSONDecoder().decode([ShelfItem].self, from: data)) ?? []
    }

    public func save(_ items: [ShelfItem]) async throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let data = try JSONEncoder().encode(items)
        try data.write(to: fileURL, options: .atomic)
    }
}
