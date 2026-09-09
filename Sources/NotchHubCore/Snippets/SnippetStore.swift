import Combine
import Foundation

@MainActor
public final class SnippetStore: ObservableObject {
    @Published public private(set) var items: [SnippetItem]
    @Published public private(set) var hasPersistenceError: Bool

    private let persistence: any SnippetPersisting
    private var didLoad = false

    public init(
        persistence: any SnippetPersisting,
        items: [SnippetItem] = [],
        hasPersistenceError: Bool = false
    ) {
        self.persistence = persistence
        self.items = items
        self.hasPersistenceError = hasPersistenceError
    }

    public func loadIfNeeded() async {
        guard !didLoad else {
            return
        }

        didLoad = true
        let load = await persistence.load()
        items = load.items
        hasPersistenceError = load.hadError
    }

    public func add(text: String, now: Date = .now) async -> Bool {
        guard isValidSnippetText(text) else {
            return false
        }

        items.append(
            SnippetItem(
                id: UUID(),
                text: text,
                createdAt: now,
                updatedAt: now
            )
        )
        await persist()
        return true
    }

    public func update(id: UUID, text: String, now: Date = .now) async -> Bool {
        guard
            isValidSnippetText(text),
            let index = items.firstIndex(where: { $0.id == id })
        else {
            return false
        }

        items[index].text = text
        items[index].updatedAt = now
        await persist()
        return true
    }

    public func remove(id: UUID) async {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        items.remove(at: index)
        await persist()
    }

    private func isValidSnippetText(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func persist() async {
        do {
            try await persistence.save(items)
            hasPersistenceError = false
        } catch {
            hasPersistenceError = true
        }
    }
}
