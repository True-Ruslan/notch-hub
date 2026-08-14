import Foundation
import XCTest

@MainActor
struct NotchHubUIApplication {
    enum Mode {
        case shippingSmoke
        case deterministicMedia
        case mediaHappyPath

        var fixture: String {
            switch self {
            case .shippingSmoke:
                "shipping-smoke"
            case .deterministicMedia, .mediaHappyPath:
                "media-standard"
            }
        }
    }

    let app: XCUIApplication
    let sourceCommit: String

    init(mode: Mode) throws {
        let environment = ProcessInfo.processInfo.environment
        guard let rawPath = environment["NOTCHHUB_UI_APP_PATH"] else {
            throw Self.configurationError("NOTCHHUB_UI_APP_PATH is required")
        }
        guard let expectedSourceCommit = environment["NOTCHHUB_UI_SOURCE_COMMIT"] else {
            throw Self.configurationError("NOTCHHUB_UI_SOURCE_COMMIT is required")
        }
        guard
            expectedSourceCommit.range(
                of: #"^[0-9a-f]{40}$"#,
                options: .regularExpression
            ) != nil
        else {
            throw Self.configurationError(
                "NOTCHHUB_UI_SOURCE_COMMIT must be an exact lowercase full Git SHA"
            )
        }

        let appURL = URL(fileURLWithPath: rawPath, isDirectory: true)
        let infoURL = appURL.appendingPathComponent("Contents/Info.plist")
        let data = try Data(contentsOf: infoURL)
        guard
            let info = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any],
            let actualSourceCommit = info["NHSourceCommit"] as? String
        else {
            throw Self.configurationError("UI test application is missing NHSourceCommit provenance")
        }
        guard actualSourceCommit == expectedSourceCommit else {
            throw Self.configurationError(
                "UI test application source mismatch: expected \(expectedSourceCommit), "
                    + "found \(actualSourceCommit)"
            )
        }

        sourceCommit = actualSourceCommit
        app = XCUIApplication(url: appURL)
        app.launchEnvironment["NOTCHHUB_UI_FIXTURE"] = mode.fixture
    }

    func launch() {
        app.launch()
    }

    private static func configurationError(_ message: String) -> NSError {
        NSError(
            domain: "NotchHubUITests.Configuration",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
