#if NOTCHHUB_UI_TESTING
    import NotchHubMediaCore

    @MainActor
    final class UITestNoMediaRuntime: MediaRuntimeSession {
        private let presentationModel: ShippingMediaPresentationModel

        init(presentationModel: ShippingMediaPresentationModel) {
            self.presentationModel = presentationModel
        }

        func start() {
            presentationModel.applyUITestPresentation(nil)
        }

        func stop() {}
        func togglePlayPause() {}
        func goPrevious() {}
        func goNext() {}
        func seek(to _: Double) {}
    }
#endif
