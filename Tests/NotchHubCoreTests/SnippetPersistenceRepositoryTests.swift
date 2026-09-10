import Foundation
import Testing

@testable import NotchHubCore

struct SnippetPersistenceRepositoryTests {
    @Test
    func missingStoreLoadsEmptyWithoutError() async {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("nested/snippets.json")
        let repository = SnippetPersistenceRepository(fileURL: fileURL)

        #expect(
            await repository.load()
                == SnippetPersistenceLoad(items: [], hadError: false)
        )
    }

    @Test
    func schemaV1RoundTripPreservesSnippetAndWritesVersionedArchive() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("nested/snippets.json")
        let repository = SnippetPersistenceRepository(fileURL: fileURL)
        let item = makeItem()

        try await repository.save([item])

        #expect(
            await repository.load()
                == SnippetPersistenceLoad(items: [item], hadError: false)
        )
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        let data = try Data(contentsOf: fileURL)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["schemaVersion"] as? Int == 1)
        #expect((object["items"] as? [[String: Any]])?.count == 1)
    }

    @Test
    func snippetItemCodableRoundTripPreservesAllFields() throws {
        let item = makeItem()

        let encoded = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(SnippetItem.self, from: encoded)

        #expect(decoded == item)
    }

    @Test
    func corruptStoreFailsClosedWithBoundedLoadError() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("snippets.json")
        try Data("not-json".utf8).write(to: fileURL)
        let repository = SnippetPersistenceRepository(fileURL: fileURL)

        #expect(
            await repository.load()
                == SnippetPersistenceLoad(items: [], hadError: true)
        )
    }

    @Test
    func unsupportedSchemaFailsClosedWithBoundedLoadError() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("snippets.json")
        let unsupported = """
            {
              "schemaVersion": 2,
              "items": []
            }
            """
        try Data(unsupported.utf8).write(to: fileURL)
        let repository = SnippetPersistenceRepository(fileURL: fileURL)

        #expect(
            await repository.load()
                == SnippetPersistenceLoad(items: [], hadError: true)
        )
    }

    @Test
    func defaultPathIsInsideDedicatedNotchHubSnippetsDirectory() {
        let fileURL = SnippetPersistenceRepository.defaultFileURL()

        #expect(fileURL.lastPathComponent == "snippets.json")
        #expect(fileURL.deletingLastPathComponent().lastPathComponent == "Snippets")
        #expect(
            fileURL.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
                == "NotchHub"
        )
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "SnippetPersistenceRepositoryTests-\(UUID().uuidString)",
                isDirectory: true
            )
    }

    private func makeItem() -> SnippetItem {
        SnippetItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            text: "docker compose up -d\n",
            createdAt: Date(timeIntervalSince1970: 10),
            updatedAt: Date(timeIntervalSince1970: 20)
        )
    }
}
