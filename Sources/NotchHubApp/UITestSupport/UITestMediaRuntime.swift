#if NOTCHHUB_UI_TESTING
    import NotchHubMediaCore

    @MainActor
    final class UITestMediaRuntime: MediaRuntimeSession {
        private let presentationModel: ShippingMediaPresentationModel
        private let supportsCommands: Bool
        private let tracks = ["Track A", "Track B", "Track C"]
        private var trackIndex = 0
        private var playbackState: ShippingMediaPlaybackState = .playing
        private var isStarted = false

        init(
            presentationModel: ShippingMediaPresentationModel,
            supportsCommands: Bool
        ) {
            self.presentationModel = presentationModel
            self.supportsCommands = supportsCommands
        }

        func start() {
            guard !isStarted else {
                return
            }
            isStarted = true
            publish()
        }

        func stop() {
            guard isStarted else {
                return
            }
            isStarted = false
            presentationModel.applyUITestPresentation(nil)
        }

        func togglePlayPause() {
            guard isStarted else {
                return
            }
            playbackState = playbackState == .playing ? .paused : .playing
            publish()
        }

        func goPrevious() {
            guard isStarted, supportsCommands else {
                return
            }
            trackIndex = max(0, trackIndex - 1)
            publish()
        }

        func goNext() {
            guard isStarted, supportsCommands else {
                return
            }
            trackIndex = min(tracks.count - 1, trackIndex + 1)
            publish()
        }

        private func publish() {
            presentationModel.applyUITestPresentation(
                ShippingMediaPresentation(
                    playbackState: playbackState,
                    title: tracks[trackIndex],
                    artist: "Fixture Artist",
                    album: "Fixture Album",
                    artworkData: nil,
                    sourceDisplayName: "NotchHub UI Fixture",
                    canGoPrevious: supportsCommands,
                    canGoNext: supportsCommands,
                    canSeek: supportsCommands,
                    positionSeconds: 42,
                    durationSeconds: 240
                )
            )
        }
    }
#endif
