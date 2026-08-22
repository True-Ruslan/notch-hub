import Testing

@testable import NotchHubMediaCore

@MainActor
private final class FakeTickerHandle: MediaTimelineTickerHandle {
    private(set) var invalidateCallCount = 0

    func invalidate() {
        invalidateCallCount += 1
    }
}

@MainActor
private final class FakeTickerEnvironment {
    private(set) var currentTime: Double = 0
    private(set) var scheduleCallCount = 0
    private(set) var lastHandle: FakeTickerHandle?
    private var tick: (() -> Void)?

    lazy var ticker = MediaTimelineTicker(
        now: { [weak self] in self?.currentTime ?? 0 },
        makeHandle: { [weak self] tick in
            guard let self else {
                return FakeTickerHandle()
            }
            self.scheduleCallCount += 1
            self.tick = tick
            let handle = FakeTickerHandle()
            self.lastHandle = handle
            return handle
        }
    )

    func advance(by seconds: Double) {
        currentTime += seconds
    }

    func fireTick() {
        tick?()
    }
}

private func playingPresentation(
    position: Double,
    duration: Double
) -> ShippingMediaPresentation {
    ShippingMediaPresentation(
        playbackState: .playing,
        title: "Title",
        artist: "Artist",
        album: nil,
        artworkData: nil,
        sourceBundleIdentifier: "com.example.player",
        sourceDisplayName: "Player",
        canGoPrevious: true,
        canGoNext: true,
        canSeek: true,
        positionSeconds: position,
        durationSeconds: duration
    )
}

private func pausedPresentation(
    position: Double,
    duration: Double
) -> ShippingMediaPresentation {
    ShippingMediaPresentation(
        playbackState: .paused,
        title: "Title",
        artist: "Artist",
        album: nil,
        artworkData: nil,
        sourceBundleIdentifier: "com.example.player",
        sourceDisplayName: "Player",
        canGoPrevious: true,
        canGoNext: true,
        canSeek: true,
        positionSeconds: position,
        durationSeconds: duration
    )
}

@MainActor
struct MediaTimelineTickerTests {
    @Test
    func timerStaysUnscheduledUntilArmedAndPlayingWithKnownPosition() {
        let environment = FakeTickerEnvironment()
        let ticker = environment.ticker

        ticker.apply(presentation: playingPresentation(position: 10, duration: 200))
        #expect(environment.scheduleCallCount == 0)

        ticker.setArmed(true)
        #expect(environment.scheduleCallCount == 1)
    }

    @Test
    func timerNeverArmsWhileCompactEvenIfPlaying() {
        let environment = FakeTickerEnvironment()
        let ticker = environment.ticker

        ticker.setArmed(false)
        ticker.apply(presentation: playingPresentation(position: 10, duration: 200))

        #expect(environment.scheduleCallCount == 0)
        #expect(ticker.displayedPositionSeconds == 10)
    }

    @Test
    func timerDoesNotArmWhenPausedEvenIfPanelIsExpanded() {
        let environment = FakeTickerEnvironment()
        let ticker = environment.ticker

        ticker.setArmed(true)
        ticker.apply(presentation: pausedPresentation(position: 10, duration: 200))

        #expect(environment.scheduleCallCount == 0)
    }

    @Test
    func tickExtrapolatesFromAnchorAndClampsToDuration() {
        let environment = FakeTickerEnvironment()
        let ticker = environment.ticker

        ticker.setArmed(true)
        ticker.apply(presentation: playingPresentation(position: 10, duration: 12))

        environment.advance(by: 1.5)
        environment.fireTick()
        #expect(ticker.displayedPositionSeconds == 11.5)

        environment.advance(by: 10)
        environment.fireTick()
        #expect(ticker.displayedPositionSeconds == 12)
    }

    @Test
    func newAuthoritativeSnapshotReanchorsWithoutDrift() {
        let environment = FakeTickerEnvironment()
        let ticker = environment.ticker

        ticker.setArmed(true)
        ticker.apply(presentation: playingPresentation(position: 10, duration: 200))
        environment.advance(by: 5)
        environment.fireTick()
        #expect(ticker.displayedPositionSeconds == 15)

        ticker.apply(presentation: playingPresentation(position: 40, duration: 200))
        #expect(ticker.displayedPositionSeconds == 40)

        environment.advance(by: 2)
        environment.fireTick()
        #expect(ticker.displayedPositionSeconds == 42)
    }

    @Test
    func collapsingToCompactTearsDownTheTimer() {
        let environment = FakeTickerEnvironment()
        let ticker = environment.ticker

        ticker.setArmed(true)
        ticker.apply(presentation: playingPresentation(position: 10, duration: 200))
        #expect(environment.scheduleCallCount == 1)

        ticker.setArmed(false)
        #expect(environment.lastHandle?.invalidateCallCount == 1)
    }

    @Test
    func pausingTearsDownTheTimer() {
        let environment = FakeTickerEnvironment()
        let ticker = environment.ticker

        ticker.setArmed(true)
        ticker.apply(presentation: playingPresentation(position: 10, duration: 200))
        #expect(environment.scheduleCallCount == 1)

        ticker.apply(presentation: pausedPresentation(position: 12, duration: 200))
        #expect(environment.lastHandle?.invalidateCallCount == 1)
    }

    @Test
    func sessionLossTearsDownTheTimer() {
        let environment = FakeTickerEnvironment()
        let ticker = environment.ticker

        ticker.setArmed(true)
        ticker.apply(presentation: playingPresentation(position: 10, duration: 200))
        #expect(environment.scheduleCallCount == 1)

        ticker.apply(presentation: nil)
        #expect(environment.lastHandle?.invalidateCallCount == 1)
        #expect(ticker.displayedPositionSeconds == nil)
    }

    @Test
    func invalidateTearsDownAnActiveTimer() {
        let environment = FakeTickerEnvironment()
        let ticker = environment.ticker

        ticker.setArmed(true)
        ticker.apply(presentation: playingPresentation(position: 10, duration: 200))
        #expect(environment.scheduleCallCount == 1)

        ticker.invalidate()
        #expect(environment.lastHandle?.invalidateCallCount == 1)
    }

    @Test
    func optimisticSeekReanchorsImmediatelyWithoutWaitingForConfirmation() {
        let environment = FakeTickerEnvironment()
        let ticker = environment.ticker

        ticker.setArmed(true)
        ticker.apply(presentation: playingPresentation(position: 10, duration: 200))

        ticker.applyOptimisticSeek(to: 90)
        #expect(ticker.displayedPositionSeconds == 90)

        environment.advance(by: 3)
        environment.fireTick()
        #expect(ticker.displayedPositionSeconds == 93)
    }

    @Test
    func optimisticSeekClampsToKnownDuration() {
        let environment = FakeTickerEnvironment()
        let ticker = environment.ticker

        ticker.setArmed(true)
        ticker.apply(presentation: playingPresentation(position: 10, duration: 200))

        ticker.applyOptimisticSeek(to: 999)
        #expect(ticker.displayedPositionSeconds == 200)
    }
}
