import NotchHubMediaCore

@MainActor
struct AppComposition {
    let makeMediaRuntime: (ShippingMediaPresentationModel) -> any MediaRuntimeSession
    let makeMediaPeekProbe: () -> any MediaPeekProbing

    static func shipping() -> Self {
        Self(
            makeMediaRuntime: {
                ShippingMediaRuntime(presentationModel: $0)
            },
            makeMediaPeekProbe: {
                ShippingMediaPeekProbe()
            }
        )
    }

    #if NOTCHHUB_UI_TESTING
        static func uiTesting(configuration: UITestConfiguration) -> Self {
            switch configuration.fixture {
            case .shippingSmoke:
                return shipping()

            case .noMediaHover:
                return Self(
                    makeMediaRuntime: {
                        UITestNoMediaRuntime(presentationModel: $0)
                    },
                    makeMediaPeekProbe: {
                        UITestMediaPeekProbe(result: .noSession)
                    }
                )

            case .mediaStandard:
                return Self(
                    makeMediaRuntime: {
                        UITestMediaRuntime(
                            presentationModel: $0,
                            supportsCommands: true
                        )
                    },
                    makeMediaPeekProbe: {
                        UITestMediaPeekProbe(result: .noSession)
                    }
                )

            case .mediaUnsupported:
                return Self(
                    makeMediaRuntime: {
                        UITestMediaRuntime(
                            presentationModel: $0,
                            supportsCommands: false
                        )
                    },
                    makeMediaPeekProbe: {
                        UITestMediaPeekProbe(result: .noSession)
                    }
                )
            }
        }
    #endif
}
