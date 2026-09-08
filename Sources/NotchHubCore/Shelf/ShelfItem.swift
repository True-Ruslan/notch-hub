import Foundation

public struct ShelfItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var bookmarkData: Data
    public let displayName: String
    public let isDirectory: Bool

    public init(
        id: UUID = UUID(),
        bookmarkData: Data,
        displayName: String,
        isDirectory: Bool
    ) {
        self.id = id
        self.bookmarkData = bookmarkData
        self.displayName = displayName
        self.isDirectory = isDirectory
    }
}
