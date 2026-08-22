#if NOTCHHUB_UI_TESTING
    import NotchHubMediaCore

    /// A MediaTimelineTickerHandle that never fires. A real repeating Timer
    /// interferes with XCUITest's app-quiescence synchronization; UI-testing
    /// fixtures use this so the ticker's arm/disarm/re-anchor logic still
    /// runs exactly as in shipping, it just never ticks during automated UI
    /// runs. Real on-device ticking is verified by
    /// MediaTimelineTickerTests (dependency-injected) and by physical
    /// acceptance.
    @MainActor
    final class UITestNoOpTickerHandle: MediaTimelineTickerHandle {
        func invalidate() {}
    }
#endif
