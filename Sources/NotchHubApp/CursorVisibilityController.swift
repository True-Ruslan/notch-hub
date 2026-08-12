import AppKit

@MainActor
final class CursorVisibilityController {
    private let hideCursor: @MainActor () -> Void
    private let unhideCursor: @MainActor () -> Void
    private var ownsHiddenCursor = false

    convenience init() {
        self.init(
            hideCursor: { NSCursor.hide() },
            unhideCursor: { NSCursor.unhide() }
        )
    }

    init(
        hideCursor: @escaping @MainActor () -> Void,
        unhideCursor: @escaping @MainActor () -> Void
    ) {
        self.hideCursor = hideCursor
        self.unhideCursor = unhideCursor
    }

    func acquireHiddenCursor() {
        guard !ownsHiddenCursor else {
            return
        }

        ownsHiddenCursor = true
        hideCursor()
    }

    func releaseHiddenCursor() {
        guard ownsHiddenCursor else {
            return
        }

        ownsHiddenCursor = false
        unhideCursor()
    }
}
