import Foundation
import XCTest

enum NotchHubUIAssertions {
    @MainActor
    static func waitUntilExists(
        _ element: XCUIElement,
        timeout: TimeInterval
    ) -> Bool {
        wait(
            for: NSPredicate(format: "exists == true"),
            object: element,
            timeout: timeout
        )
    }

    @MainActor
    static func waitUntilLabel(
        _ element: XCUIElement,
        equals expectedLabel: String,
        timeout: TimeInterval
    ) -> Bool {
        wait(
            for: NSPredicate(format: "label == %@", expectedLabel),
            object: element,
            timeout: timeout
        )
    }

    @MainActor
    private static func wait(
        for predicate: NSPredicate,
        object: Any,
        timeout: TimeInterval
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: predicate,
            object: object
        )
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
