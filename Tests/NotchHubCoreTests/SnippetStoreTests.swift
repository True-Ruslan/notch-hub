import Foundation
import Testing

@testable import NotchHubCore

@MainActor
struct SnippetStoreTests {
    @Test
    func loadIfNeededLoadsExactlyOnceAndPropagatesItems() async {
        let item = makeItem(text: "git status")
        let persistence = TestSnippetPersistence(
            loadResult: SnippetPersistenceLoad(items: [item], hadError: false)
        )
        let store = SnippetStore(persistence: persistence)

        await store.loadIfNeeded()
        await store.loadIfNeeded()

        #expect(store.items == [item])
        #expect(!store.hasPersistenceError)
        #expect(await persistence.loadInvocationCount() == 1)
    }

    @Test
    func loadErrorFailsClosedToReturnedItemsAndSetsBoundedError() async {
        let persistence = TestSnippetPersistence(
            loadResult: SnippetPersistenceLoad(items: [], hadError: true)
        )
        let store = SnippetStore(persistence: persistence)

        await store.loadIfNeeded()

        #expect(store.items.isEmpty)
        #expect(store.hasPersistenceError)
    }

    @Test
    func addPreservesExactTextCreatesTimestampsAndPersists() async throws {
        let persistence = TestSnippetPersistence()
        let store = SnippetStore(persistence: persistence)
        let now = Date(timeIntervalSince1970: 100)
        let text = "  docker compose up -d\n"

        let added = await store.add(text: text, now: now)

        #expect(added)
        let item = try #require(store.items.first)
        #expect(item.text == text)
        #expect(item.createdAt == now)
        #expect(item.updatedAt == now)
        #expect(await persistence.snapshot() == store.items)
        #expect(await persistence.saveInvocationCount() == 1)
    }

    @Test
    func blankAddIsRejectedWithoutMutationOrPersistence() async {
        let persistence = TestSnippetPersistence()
        let store = SnippetStore(persistence: persistence)

        let added = await store.add(text: " \n\t ", now: Date(timeIntervalSince1970: 100))

        #expect(!added)
        #expect(store.items.isEmpty)
        #expect(await persistence.saveInvocationCount() == 0)
    }

    @Test
    func updatePreservesIdentityAndCreatedAtButChangesExactTextAndUpdatedAt() async throws {
        let original = makeItem(
            text: "old",
            createdAt: Date(timeIntervalSince1970: 10),
            updatedAt: Date(timeIntervalSince1970: 20)
        )
        let persistence = TestSnippetPersistence(
            loadResult: SnippetPersistenceLoad(items: [original], hadError: false)
        )
        let store = SnippetStore(persistence: persistence)
        await store.loadIfNeeded()
        let now = Date(timeIntervalSince1970: 30)
        let replacement = "  new value\n"

        let updated = await store.update(id: original.id, text: replacement, now: now)

        #expect(updated)
        let item = try #require(store.items.first)
        #expect(item.id == original.id)
        #expect(item.createdAt == original.createdAt)
        #expect(item.text == replacement)
        #expect(item.updatedAt == now)
        #expect(await persistence.snapshot() == [item])
        #expect(await persistence.saveInvocationCount() == 1)
    }

    @Test
    func blankUpdateIsRejectedWithoutMutationOrPersistence() async {
        let original = makeItem(text: "keep")
        let persistence = TestSnippetPersistence(
            loadResult: SnippetPersistenceLoad(items: [original], hadError: false)
        )
        let store = SnippetStore(persistence: persistence)
        await store.loadIfNeeded()

        let updated = await store.update(
            id: original.id,
            text: " \n ",
            now: Date(timeIntervalSince1970: 999)
        )

        #expect(!updated)
        #expect(store.items == [original])
        #expect(await persistence.saveInvocationCount() == 0)
    }

    @Test
    func updateUnknownIdentifierIsRejectedWithoutPersistence() async {
        let original = makeItem(text: "keep")
        let persistence = TestSnippetPersistence(
            loadResult: SnippetPersistenceLoad(items: [original], hadError: false)
        )
        let store = SnippetStore(persistence: persistence)
        await store.loadIfNeeded()

        let updated = await store.update(
            id: UUID(),
            text: "replacement",
            now: Date(timeIntervalSince1970: 999)
        )

        #expect(!updated)
        #expect(store.items == [original])
        #expect(await persistence.saveInvocationCount() == 0)
    }

    @Test
    func removeDeletesOnlyExistingLocalRecordAndPersistsOnce() async {
        let first = makeItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            text: "first"
        )
        let second = makeItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            text: "second"
        )
        let persistence = TestSnippetPersistence(
            loadResult: SnippetPersistenceLoad(items: [first, second], hadError: false)
        )
        let store = SnippetStore(persistence: persistence)
        await store.loadIfNeeded()

        await store.remove(id: first.id)
        await store.remove(id: UUID())

        #expect(store.items == [second])
        #expect(await persistence.snapshot() == [second])
        #expect(await persistence.saveInvocationCount() == 1)
    }

    @Test
    func saveFailureKeepsInMemoryMutationAndSetsPersistenceError() async throws {
        let persistence = TestSnippetPersistence(shouldFailSave: true)
        let store = SnippetStore(persistence: persistence)
        let now = Date(timeIntervalSince1970: 100)

        let added = await store.add(text: "persist later", now: now)

        #expect(added)
        let item = try #require(store.items.first)
        #expect(item.text == "persist later")
        #expect(item.createdAt == now)
        #expect(store.hasPersistenceError)
        #expect(await persistence.snapshot().isEmpty)
        #expect(await persistence.saveInvocationCount() == 1)
    }

    @Test
    func successfulLaterSaveClearsPersistenceErrorAndPersistsCurrentState() async {
        let persistence = TestSnippetPersistence(shouldFailSave: true)
        let store = SnippetStore(persistence: persistence)

        #expect(await store.add(text: "first", now: Date(timeIntervalSince1970: 1)))
        #expect(store.hasPersistenceError)

        await persistence.setShouldFailSave(false)
        #expect(await store.add(text: "second", now: Date(timeIntervalSince1970: 2)))

        #expect(!store.hasPersistenceError)
        #expect(store.items.map(\.text) == ["first", "second"])
        #expect(await persistence.snapshot() == store.items)
        #expect(await persistence.saveInvocationCount() == 2)
    }

    private func makeItem(
        id: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
        text: String,
        createdAt: Date = Date(timeIntervalSince1970: 10),
        updatedAt: Date = Date(timeIntervalSince1970: 20)
    ) -> SnippetItem {
        SnippetItem(
            id: id,
            text: text,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private actor TestSnippetPersistence: SnippetPersisting {
    private var loadResult: SnippetPersistenceLoad
    private var storedItems: [SnippetItem]
    private var shouldFailSave: Bool
    private var loadCalls = 0
    private var saveCalls = 0

    init(
        loadResult: SnippetPersistenceLoad = SnippetPersistenceLoad(items: [], hadError: false),
        shouldFailSave: Bool = false
    ) {
        self.loadResult = loadResult
        storedItems = loadResult.items
        self.shouldFailSave = shouldFailSave
    }

    func load() async -> SnippetPersistenceLoad {
        loadCalls += 1
        return loadResult
    }

    func save(_ items: [SnippetItem]) async throws {
        saveCalls += 1
        if shouldFailSave {
            throw CocoaError(.fileWriteUnknown)
        }
        storedItems = items
    }

    func setShouldFailSave(_ value: Bool) {
        shouldFailSave = value
    }

    func snapshot() -> [SnippetItem] {
        storedItems
    }

    func loadInvocationCount() -> Int {
        loadCalls
    }

    func saveInvocationCount() -> Int {
        saveCalls
    }
}
