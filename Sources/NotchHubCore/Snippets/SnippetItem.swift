import Foundation

public struct SnippetItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var text: String
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID,
        text: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
