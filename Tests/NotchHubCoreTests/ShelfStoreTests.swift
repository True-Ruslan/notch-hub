import Foundation
import Testing

@testable import NotchHubCore

@MainActor
struct ShelfStoreTests {
    @Test
    func addDeduplicatesByResolvedStandardizedURLAndPreservesFirstSeenOrder() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let a = try makeFile(named: "A.txt", in: directory)
        let b = try makeFile(named: "B.txt", in: directory)
        let persistence = TestShelfPersistence()
        let codec = TestShelfBookmarkCodec()
        let store = ShelfStore(persistence: persistence, bookmarkCodec: codec)

        await store.loadIfNeeded()
        await store.add(urls: [a, b, a])
        await store.add(urls: [a])

        #expect(store.items.map(\.displayName) == ["A.txt", "B.txt"])
        #expect(await persistence.snapshot().count == 2)
    }

    @Test
    func duplicateSuppressionStillWorksAfterReload() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = try makeFile(named: "Persisted.txt", in: directory)
        let persistence = TestShelfPersistence()
        let codec = TestShelfBookmarkCodec()

        let firstStore = ShelfStore(persistence: persistence, bookmarkCodec: codec)
        await firstStore.loadIfNeeded()
        await firstStore.add(urls: [file])

        let reloaded = ShelfStore(persistence: persistence, bookmarkCodec: codec)
        await reloaded.loadIfNeeded()
        await reloaded.add(urls: [file])

        #expect(reloaded.items.count == 1)
    }

    @Test
    func invalidExistingBookmarkDoesNotBlockAddingValidResource() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let valid = try makeFile(named: "Valid.txt", in: directory)
        let invalid = ShelfItem(
            bookmarkData: Data("invalid".utf8),
            displayName: "Unavailable.txt",
            isDirectory: false
        )
        let persistence = TestShelfPersistence(initialItems: [invalid])
        let store = ShelfStore(
            persistence: persistence,
            bookmarkCodec: TestShelfBookmarkCodec()
        )

        await store.loadIfNeeded()
        await store.add(urls: [valid])

        #expect(store.items.map(\.displayName) == ["Unavailable.txt", "Valid.txt"])
    }

    @Test
    func removeDeletesOnlyShelfReferenceAndLeavesSourceFileUntouched() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = try makeFile(named: "KeepMe.txt", in: directory)
        let persistence = TestShelfPersistence()
        let store = ShelfStore(
            persistence: persistence,
            bookmarkCodec: TestShelfBookmarkCodec()
        )

        await store.loadIfNeeded()
        await store.add(urls: [file])
        let id = try #require(store.items.first?.id)

        await store.remove(id: id)

        #expect(store.items.isEmpty)
        #expect(await persistence.snapshot().isEmpty)
        #expect(FileManager.default.fileExists(atPath: file.path))
    }

    @Test
    func resolvingStaleBookmarkRefreshesInMemoryAndPersistedBookmark() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = try makeFile(named: "Stale.txt", in: directory)
        let codec = TestShelfBookmarkCodec()
        let staleData = codec.staleBookmark(for: file)
        let item = ShelfItem(
            bookmarkData: staleData,
            displayName: "Stale.txt",
            isDirectory: false
        )
        let persistence = TestShelfPersistence(initialItems: [item])
        let store = ShelfStore(persistence: persistence, bookmarkCodec: codec)

        await store.loadIfNeeded()
        let resolution = await store.resolve(try #require(store.items.first))

        #expect(resolution?.url.standardizedFileURL == file.standardizedFileURL)
        let freshData = try codec.makeBookmark(for: file)
        #expect(store.items.first?.bookmarkData == freshData)
        #expect(await persistence.snapshot().first?.bookmarkData == freshData)
    }

    @Test
    func persistenceFailureIsBoundedAndClearsAfterLaterSuccessfulSave() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let a = try makeFile(named: "A.txt", in: directory)
        let b = try makeFile(named: "B.txt", in: directory)
        let persistence = TestShelfPersistence(shouldFailSave: true)
        let store = ShelfStore(
            persistence: persistence,
            bookmarkCodec: TestShelfBookmarkCodec()
        )

        await store.loadIfNeeded()
        await store.add(urls: [a])
        #expect(store.hasPersistenceError)

        await persistence.setShouldFailSave(false)
        await store.add(urls: [b])

        #expect(!store.hasPersistenceError)
        #expect(await persistence.snapshot().count == 2)
    }

    private func makeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ShelfStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func makeFile(named name: String, in directory: URL) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try Data(name.utf8).write(to: url)
        return url
    }
}

private enum TestShelfBookmarkError: Error {
    case invalid
}

private struct TestShelfBookmarkCodec: ShelfBookmarkCoding {
    func makeBookmark(for url: URL) throws -> Data {
        Data("fresh|\(url.standardizedFileURL.path)".utf8)
    }

    func resolve(_ bookmarkData: Data) throws -> ShelfBookmarkResolution {
        let raw = String(decoding: bookmarkData, as: UTF8.self)
        guard let delimiter = raw.firstIndex(of: "|") else {
            throw TestShelfBookmarkError.invalid
        }
        let kind = String(raw[..<delimiter])
        let path = String(raw[raw.index(after: delimiter)...])
        guard kind == "fresh" || kind == "stale", !path.isEmpty else {
            throw TestShelfBookmarkError.invalid
        }
        let url = URL(fileURLWithPath: path)
        return ShelfBookmarkResolution(
            url: url,
            refreshedBookmarkData: kind == "stale" ? try makeBookmark(for: url) : nil
        )
    }

    func staleBookmark(for url: URL) -> Data {
        Data("stale|\(url.standardizedFileURL.path)".utf8)
    }
}

private actor TestShelfPersistence: ShelfPersisting {
    private var storedItems: [ShelfItem]
    private var shouldFailSave: Bool

    init(initialItems: [ShelfItem] = [], shouldFailSave: Bool = false) {
        storedItems = initialItems
        self.shouldFailSave = shouldFailSave
    }

    func load() async -> [ShelfItem] {
        storedItems
    }

    func save(_ items: [ShelfItem]) async throws {
        if shouldFailSave {
            throw CocoaError(.fileWriteUnknown)
        }
        storedItems = items
    }

    func setShouldFailSave(_ value: Bool) {
        shouldFailSave = value
    }

    func snapshot() -> [ShelfItem] {
        storedItems
    }
}
