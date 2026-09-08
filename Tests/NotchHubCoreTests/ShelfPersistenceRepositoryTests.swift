import Foundation
import Testing

@testable import NotchHubCore

struct ShelfPersistenceRepositoryTests {
    @Test
    func missingStoreLoadsAsEmptyAndRoundTripIsAtomic() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("nested/items.json")
        let repository = ShelfPersistenceRepository(fileURL: fileURL)
        let item = makeItem(name: "A.txt")

        #expect(await repository.load() == [])

        try await repository.save([item])

        #expect(await repository.load() == [item])
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test
    func corruptStoreFailsClosedToEmptyCollection() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("items.json")
        try Data("not-json".utf8).write(to: fileURL)
        let repository = ShelfPersistenceRepository(fileURL: fileURL)

        #expect(await repository.load() == [])
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("ShelfPersistenceRepositoryTests-\(UUID().uuidString)", isDirectory: true)
    }

    private func makeItem(name: String) -> ShelfItem {
        ShelfItem(
            bookmarkData: Data(name.utf8),
            displayName: name,
            isDirectory: false
        )
    }
}
