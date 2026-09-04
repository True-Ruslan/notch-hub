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
    static func waitUntilSelected(
        _ element: XCUIElement,
        equals expectedSelected: Bool,
        timeout: TimeInterval
    ) -> Bool {
        wait(
            for: NSPredicate(format: "isSelected == %@", NSNumber(value: expectedSelected)),
            object: element,
            timeout: timeout
        )
    }

    @MainActor
    static func waitUntilValue(
        _ element: XCUIElement,
        equals expectedValue: String,
        timeout: TimeInterval
    ) -> Bool {
        wait(
            for: NSPredicate(format: "value == %@", expectedValue),
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
