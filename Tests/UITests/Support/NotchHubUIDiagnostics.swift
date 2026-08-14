import XCTest

enum NotchHubUIDiagnostics {
    @MainActor
    static func attachFailureState(
        application: XCUIApplication,
        name: String,
        to testCase: XCTestCase
    ) {
        let screenshot = XCTAttachment(screenshot: application.screenshot())
        screenshot.name = "\(name)-screenshot"
        screenshot.lifetime = .keepAlways
        testCase.add(screenshot)

        let hierarchy = XCTAttachment(string: application.debugDescription)
        hierarchy.name = "\(name)-hierarchy"
        hierarchy.lifetime = .keepAlways
        testCase.add(hierarchy)
    }
}
