import Foundation
import Testing

struct MediaSeekCursorCompositionPolicyTests {
    @Test
    func cursorControllerOwnsBalancedIdempotentVisibility() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/CursorVisibilityController.swift")

        #expect(source.contains("final class CursorVisibilityController"))
        #expect(source.contains("private var ownsHiddenCursor = false"))
        #expect(source.contains("func acquireHiddenCursor()"))
        #expect(source.contains("guard !ownsHiddenCursor else"))
        #expect(source.contains("func releaseHiddenCursor()"))
        #expect(source.contains("guard ownsHiddenCursor else"))
        #expect(source.contains("NSCursor.hide()"))
        #expect(source.contains("NSCursor.unhide()"))
        #expect(!source.contains("CGWarpMouseCursorPosition"))
        #expect(!source.contains("CGAssociateMouseAndMouseCursorPosition"))
        #expect(!source.contains("CGEventTapCreate"))
    }

    @Test
    func seekAcquiresCursorOnlyAfterSuccessfulBeginAndReleasesOnEveryIsolationFinish() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/MediaGestureSession.swift")

        #expect(source.contains("private let cursorVisibilityController: CursorVisibilityController"))
        #expect(source.contains("cursorVisibilityController.acquireHiddenCursor()"))
        #expect(source.contains("cursorVisibilityController.releaseHiddenCursor()"))
        #expect(source.contains("activeSeekTransaction = transaction"))
        #expect(source.contains("finishSeekIsolation()"))
        #expect(source.contains("func invalidate()"))
    }

    @Test
    func appResignAndTerminationCancelSeekBeforeLosingOwnership() throws {
        let source = try sourceText(relativePath: "Sources/NotchHubApp/AppDelegate.swift")

        #expect(source.contains("func applicationDidResignActive"))
        #expect(source.contains("mediaGestureSession?.cancelSeek()"))
        #expect(source.contains("func applicationWillTerminate"))
        #expect(source.contains("mediaGestureSession?.invalidate()"))
    }

    private func sourceText(relativePath: String) throws -> String {
        let testFile = URL(fileURLWithPath: #filePath)
        let repositoryRoot =
            testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}
