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

    public func makeBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    public func resolve(_ bookmarkData: Data) throws -> ShelfBookmarkResolution {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        var refreshedBookmarkData: Data?
        if isStale {
            let didStartAccess = url.startAccessingSecurityScopedResource()
            guard didStartAccess else {
                throw CocoaError(.fileReadNoPermission)
            }
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            refreshedBookmarkData = try makeBookmark(for: url)
        }

        return ShelfBookmarkResolution(
            url: url,
            refreshedBookmarkData: refreshedBookmarkData
        )
    }
}
