#if NOTCHHUB_UI_TESTING
    import NotchHubMediaCore

    @MainActor
    final class UITestMediaRuntime: MediaRuntimeSession {
        private static let sourceBundleIdentifier = "ru.trueruslan.notchhub.ui-fixture"
        private static let durationSeconds = 240.0

        private let presentationModel: ShippingMediaPresentationModel
        private let supportsCommands: Bool
        private let tracks = ["Track A", "Track B", "Track C"]
        private var trackIndex = 0
        private var playbackState: ShippingMediaPlaybackState = .playing
        private var positionSeconds = 42.0
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
            positionSeconds = 42
            publish()
        }

        func goNext() {
            guard isStarted, supportsCommands else {
                return
            }
            trackIndex = min(tracks.count - 1, trackIndex + 1)
            positionSeconds = 42
            publish()
        }

        func seek(to positionSeconds: Double) {
            guard
                isStarted,
                supportsCommands,
                positionSeconds.isFinite,
                positionSeconds >= 0
            else {
                return
            }
            self.positionSeconds = min(positionSeconds, Self.durationSeconds)
            publish()
        }

        private func publish() {
            let sourceBundleIdentifier = Self.sourceBundleIdentifier
            presentationModel.applyUITestPresentation(
                ShippingMediaPresentation(
                    playbackState: playbackState,
                    title: tracks[trackIndex],
                    artist: "Fixture Artist",
                    album: "Fixture Album",
                    artworkData: nil,
                    sourceBundleIdentifier: sourceBundleIdentifier,
                    sourceDisplayName: "NotchHub UI Fixture",
                    canGoPrevious: supportsCommands,
                    canGoNext: supportsCommands,
                    canSeek: supportsCommands,
                    positionSeconds: positionSeconds,
                    durationSeconds: Self.durationSeconds,
                    sessionIdentity: ShippingMediaSessionIdentity(
                        generation: 1,
                        sourceBundleIdentifier: sourceBundleIdentifier
                    )
                )
            )
        }
    }
#endif
