import Foundation
import Testing

@testable import NotchHubCore

@MainActor
struct ShelfShareAccessSessionTests {
    @Test
    func beginHoldsSecurityScopeUntilExplicitEnd() {
        let controller = TestShelfShareSecurityScopeController(startResult: true)
        let session = ShelfShareAccessSession(controller: controller)
        let url = URL(fileURLWithPath: "/tmp/share-a.txt")

        #expect(session.begin(url: url))
        #expect(controller.startCalls == [url])
        #expect(controller.stopCalls.isEmpty)

        session.end()

        #expect(controller.stopCalls == [url])
    }

    @Test
    func failedBeginDoesNotCreateOrStopAScope() {
        let controller = TestShelfShareSecurityScopeController(startResult: false)
        let session = ShelfShareAccessSession(controller: controller)
        let url = URL(fileURLWithPath: "/tmp/share-denied.txt")

        #expect(!session.begin(url: url))
        session.end()

        #expect(controller.startCalls == [url])
        #expect(controller.stopCalls.isEmpty)
    }

    @Test
    func beginningAnotherShareStopsPreviousScopeBeforeStartingNext() {
        let controller = TestShelfShareSecurityScopeController(startResult: true)
        let session = ShelfShareAccessSession(controller: controller)
        let first = URL(fileURLWithPath: "/tmp/share-first.txt")
        let second = URL(fileURLWithPath: "/tmp/share-second.txt")

        #expect(session.begin(url: first))
        #expect(session.begin(url: second))

        #expect(controller.startCalls == [first, second])
        #expect(controller.stopCalls == [first])

        session.end()
        #expect(controller.stopCalls == [first, second])
    }

    @Test
    func endIsIdempotent() {
        let controller = TestShelfShareSecurityScopeController(startResult: true)
        let session = ShelfShareAccessSession(controller: controller)
        let url = URL(fileURLWithPath: "/tmp/share-idempotent.txt")

        #expect(session.begin(url: url))
        session.end()
        session.end()

        #expect(controller.stopCalls == [url])
    }
}

@MainActor
private final class TestShelfShareSecurityScopeController: ShelfSecurityScopeControlling {
    private let startResult: Bool
    private(set) var startCalls: [URL] = []
    private(set) var stopCalls: [URL] = []

    init(startResult: Bool) {
        self.startResult = startResult
    }

    func startAccessing(_ url: URL) -> Bool {
        startCalls.append(url)
        return startResult
    }

    func stopAccessing(_ url: URL) {
        stopCalls.append(url)
    }
}
