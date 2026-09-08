import Foundation

public struct ShelfBookmarkResolution: Equatable, Sendable {
    public let url: URL
    public let refreshedBookmarkData: Data?

    public init(url: URL, refreshedBookmarkData: Data? = nil) {
        self.url = url
        self.refreshedBookmarkData = refreshedBookmarkData
    }
}

public protocol ShelfBookmarkCoding: Sendable {
    func makeBookmark(for url: URL) throws -> Data
    func resolve(_ bookmarkData: Data) throws -> ShelfBookmarkResolution
}

public struct SecurityScopedShelfBookmarkCodec: ShelfBookmarkCoding {
    public init() {}

    public func makeBookmark(for _: URL) throws -> Data {
        throw CocoaError(.fileWriteUnknown)
    }

    public func resolve(_: Data) throws -> ShelfBookmarkResolution {
        throw CocoaError(.fileReadUnknown)
    }
}
