import CoreGraphics
import Foundation
import XCTest

@MainActor
struct NotchHubUIApplication {
    enum Mode {
        case shippingSmoke
        case noMediaHover
        case deterministicMedia
        case mediaHappyPath
        case mediaUnsupported

        var fixture: String {
            switch self {
            case .shippingSmoke:
                "shipping-smoke"
            case .noMediaHover:
                "no-media-hover"
            case .deterministicMedia, .mediaHappyPath:
                "media-standard"
            case .mediaUnsupported:
                "media-unsupported"
            }
        }
    }

    enum LaunchPointerPolicy {
        case parkOutsideNotch
        case preserveCurrentPosition
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

    func launch(pointerPolicy: LaunchPointerPolicy = .parkOutsideNotch) {
        if pointerPolicy == .parkOutsideNotch {
            XCTAssertTrue(
                parkPointerOutsideNotch(),
                "UI harness must park the real pointer away from the top-center notch before launch"
            )
        }
        app.launch()
    }

    func surface(_ identifier: String) -> XCUIElement {
        app.groups[identifier]
    }

    func titleElement() -> XCUIElement {
        app.staticTexts["media.title"]
    }

    func waitForStableCompact(timeout: TimeInterval = 2) -> Bool {
        let compact = surface("notch.surface.compact")
        guard NotchHubUIAssertions.waitUntilExists(compact, timeout: timeout) else {
            return false
        }

        return surface("notch.surface.peek").waitForNonExistence(timeout: timeout)
            && surface("notch.surface.expanded").waitForNonExistence(timeout: timeout)
    }

    func openExpandedExplicitly(timeout: TimeInterval = 2) -> Bool {
        guard waitForStableCompact(timeout: timeout) else {
            return false
        }

        let hitTarget =
            app.descendants(matching: .any)
            .matching(identifier: "notch.surface.hitTarget")
            .firstMatch
        guard NotchHubUIAssertions.waitUntilExists(hitTarget, timeout: timeout) else {
            return false
        }
        guard positionPointerForExplicitClick(on: hitTarget) else {
            return false
        }

        hitTarget.click()
        return NotchHubUIAssertions.waitUntilExists(
            surface("notch.surface.expanded"),
            timeout: timeout
        )
    }

    func hoverCompact(timeout: TimeInterval = 2) -> Bool {
        let compact = surface("notch.surface.compact")
        guard NotchHubUIAssertions.waitUntilExists(compact, timeout: timeout) else {
            return false
        }
        compact.hover()
        return true
    }

    func movePointerOutside(_ element: XCUIElement) {
        let center = element.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
        )
        center.withOffset(
            CGVector(dx: 0, dy: max(element.frame.height, 80))
        ).hover()
    }

    private func positionPointerForExplicitClick(on element: XCUIElement) -> Bool {
        let frame = element.frame
        guard
            frame.origin.x.isFinite,
            frame.origin.y.isFinite,
            frame.width.isFinite,
            frame.height.isFinite,
            frame.width > 0,
            frame.height > 0
        else {
            return false
        }

        return CGWarpMouseCursorPosition(
            CGPoint(x: frame.midX, y: frame.midY)
        ) == .success
    }

    private func parkPointerOutsideNotch() -> Bool {
        let displayBounds = CGDisplayBounds(CGMainDisplayID())
        guard
            displayBounds.width.isFinite,
            displayBounds.height.isFinite,
            displayBounds.width > 0,
            displayBounds.height > 0
        else {
            return false
        }

        let destination = CGPoint(
            x: displayBounds.midX,
            y: displayBounds.maxY - min(120, displayBounds.height / 4)
        )
        return CGWarpMouseCursorPosition(destination) == .success
    }

    private static func configurationError(_ message: String) -> NSError {
        NSError(
            domain: "NotchHubUITests.Configuration",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
