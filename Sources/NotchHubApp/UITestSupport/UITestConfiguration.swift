#if NOTCHHUB_UI_TESTING
import Foundation

struct UITestConfiguration: Equatable {
    enum Fixture: String {
        case shippingSmoke = "shipping-smoke"
        case mediaStandard = "media-standard"
        case mediaUnsupported = "media-unsupported"
    }

    let fixture: Fixture

    static func current(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Self {
        let rawValue = environment["NOTCHHUB_UI_FIXTURE"] ?? Fixture.shippingSmoke.rawValue
        return Self(fixture: Fixture(rawValue: rawValue) ?? .shippingSmoke)
    }
}
#endif
