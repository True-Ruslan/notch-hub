import Foundation

public struct SnippetPersistenceLoad: Equatable, Sendable {
    public let items: [SnippetItem]
    public let hadError: Bool

    public init(items: [SnippetItem], hadError: Bool) {
        self.items = items
        self.hadError = hadError
    }
}

public protocol SnippetPersisting: Sendable {
    func load() async -> SnippetPersistenceLoad
    func save(_ items: [SnippetItem]) async throws
}

public actor SnippetPersistenceRepository: SnippetPersisting {
    private struct Archive: Codable {
        let schemaVersion: Int
        let items: [SnippetItem]
    }

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
            .appendingPathComponent("Snippets", isDirectory: true)
            .appendingPathComponent("snippets.json", isDirectory: false)
    }

    public func load() async -> SnippetPersistenceLoad {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return SnippetPersistenceLoad(items: [], hadError: false)
        }

        guard
            let data = try? Data(contentsOf: fileURL),
            let archive = try? JSONDecoder().decode(Archive.self, from: data),
            archive.schemaVersion == 1
        else {
            return SnippetPersistenceLoad(items: [], hadError: true)
        }

        return SnippetPersistenceLoad(items: archive.items, hadError: false)
    }

    public func save(_ items: [SnippetItem]) async throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let archive = Archive(schemaVersion: 1, items: items)
        let data = try JSONEncoder().encode(archive)
        try data.write(to: fileURL, options: .atomic)
    }
}
