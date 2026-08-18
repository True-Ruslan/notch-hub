#if NOTCHHUB_UI_TESTING
    import NotchHubMediaCore

    @MainActor
    final class UITestMediaPeekProbe: MediaPeekProbing {
        private let result: ShippingMediaPeekProbe.Result

        init(result: ShippingMediaPeekProbe.Result) {
            self.result = result
        }

        func acquire(
            completion: @escaping @MainActor @Sendable (ShippingMediaPeekProbe.Result) -> Void
        ) {
            completion(result)
        }

        func cancel() {}
    }
#endif
