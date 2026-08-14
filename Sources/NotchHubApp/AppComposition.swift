import NotchHubMediaCore

@MainActor
struct AppComposition {
    let makeMediaRuntime: (ShippingMediaPresentationModel) -> any MediaRuntimeSession

    static func shipping() -> Self {
        Self(
            makeMediaRuntime: {
                ShippingMediaRuntime(presentationModel: $0)
            }
        )
    }

    #if NOTCHHUB_UI_TESTING
        static func uiTesting(configuration: UITestConfiguration) -> Self {
            switch configuration.fixture {
            case .shippingSmoke:
                return shipping()
            case .mediaStandard:
                return Self(
                    makeMediaRuntime: {
                        UITestMediaRuntime(
                            presentationModel: $0,
                            supportsCommands: true
                        )
                    }
                )
            case .mediaUnsupported:
                return Self(
                    makeMediaRuntime: {
                        UITestMediaRuntime(
                            presentationModel: $0,
                            supportsCommands: false
                        )
                    }
                )
            }
        }
    #endif
}
