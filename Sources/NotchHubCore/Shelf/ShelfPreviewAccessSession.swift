import Foundation

@MainActor
public protocol ShelfSecurityScopeControlling: AnyObject {
    func startAccessing(_ url: URL) -> Bool
    func stopAccessing(_ url: URL)
}

@MainActor
public final class SystemShelfSecurityScopeController: ShelfSecurityScopeControlling {
    public init() {}

    public func startAccessing(_ url: URL) -> Bool {
        url.startAccessingSecurityScopedResource()
    }

    public func stopAccessing(_ url: URL) {
        url.stopAccessingSecurityScopedResource()
    }
}

@MainActor
public final class ShelfPreviewAccessSession {
    private let controller: any ShelfSecurityScopeControlling
    private var activeURL: URL?

    public init(
        controller: any ShelfSecurityScopeControlling = SystemShelfSecurityScopeController()
    ) {
        self.controller = controller
    }

    @discardableResult
    public func begin(url: URL) -> Bool {
        end()
        guard controller.startAccessing(url) else {
            return false
        }

        activeURL = url
        return true
    }

    public func end() {
        guard let activeURL else {
            return
        }

        self.activeURL = nil
        controller.stopAccessing(activeURL)
    }
}
