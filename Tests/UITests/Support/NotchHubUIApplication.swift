import Foundation
import XCTest

@MainActor
struct NotchHubUIApplication {
    enum Mode {
        case shippingSmoke
        case deterministicMedia
    }

    let app: XCUIApplication

    init(mode: Mode) throws {
        guard let rawPath = ProcessInfo.processInfo.environment["NOTCHHUB_UI_APP_PATH"] else {
            throw XCTSkip("NOTCHHUB_UI_APP_PATH is required")
        }

        app = XCUIApplication(
            url: URL(fileURLWithPath: rawPath, isDirectory: true)
        )
        app.launchEnvironment["NOTCHHUB_UI_FIXTURE"] =
            mode == .deterministicMedia ? "media-standard" : "shipping-smoke"
    }

    func launch() {
        app.launch()
    }
}
