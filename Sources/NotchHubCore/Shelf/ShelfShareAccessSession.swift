import Foundation

@MainActor
public final class ShelfShareAccessSession {
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
