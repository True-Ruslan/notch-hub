import NotchHubMediaCore

@MainActor
struct AppComposition {
    let makeMediaRuntime: (ShippingMediaPresentationModel) -> any MediaRuntimeSession
    let makeMediaPeekProbe: () -> any MediaPeekProbing
    let makeMediaTimelineTicker: () -> MediaTimelineTicker

    static func shipping() -> Self {
        Self(
            makeMediaRuntime: {
                ShippingMediaRuntime(presentationModel: $0)
            },
            makeMediaPeekProbe: {
                ShippingMediaPeekProbe()
            },
            makeMediaTimelineTicker: {
                MediaTimelineTicker()
            }
        )
    }

    #if NOTCHHUB_UI_TESTING
        static func uiTesting(configuration: UITestConfiguration) -> Self {
            // A real repeating Timer interferes with XCUITest's app
            // quiescence synchronization, so every UI-testing fixture uses a
            // ticker whose scheduler never actually fires. The ticker's real
            // extrapolation/lifecycle logic is covered by
            // MediaTimelineTickerTests; real on-device ticking behavior is a
            // physical-acceptance concern, not a UI-automation one.
            let makeNonFiringTicker = {
                MediaTimelineTicker(makeHandle: { _ in UITestNoOpTickerHandle() })
            }

            switch configuration.fixture {
            case .shippingSmoke:
                return Self(
                    makeMediaRuntime: shipping().makeMediaRuntime,
                    makeMediaPeekProbe: shipping().makeMediaPeekProbe,
                    makeMediaTimelineTicker: makeNonFiringTicker
                )

            case .noMediaHover:
                return Self(
                    makeMediaRuntime: {
                        UITestNoMediaRuntime(presentationModel: $0)
                    },
                    makeMediaPeekProbe: {
                        UITestMediaPeekProbe(result: .noSession)
                    },
                    makeMediaTimelineTicker: makeNonFiringTicker
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
                    },
                    makeMediaTimelineTicker: makeNonFiringTicker
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
                    },
                    makeMediaTimelineTicker: makeNonFiringTicker
                )
            }
        }
    #endif
}
