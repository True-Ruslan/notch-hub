import Foundation

/// A handle to a scheduled repeating tick, returned by an injected scheduler
/// so tests can control ticking without a real `Timer`/run loop.
@MainActor
public protocol MediaTimelineTickerHandle {
    func invalidate()
}

extension Timer: MediaTimelineTickerHandle {}

/// Extrapolates the displayed Now Playing position between authoritative
/// system events, so a Peek/Expanded progress bar visibly advances while the
/// user watches it. See
/// docs/superpowers/specs/2026-08-22-live-media-timeline-and-compact-design.md
/// for the accepted bounded-lifecycle invariant this type implements.
@MainActor
public final class MediaTimelineTicker: ObservableObject {
    public static let tickInterval: TimeInterval = 0.3

    @Published public private(set) var displayedPositionSeconds: Double?

    private let now: () -> TimeInterval
    private let makeHandle: (@escaping @Sendable () -> Void) -> any MediaTimelineTickerHandle

    private var anchorPositionSeconds: Double?
    private var anchorDurationSeconds: Double?
    private var anchorCapturedAt: TimeInterval?
    private var isPlaying = false
    private var isArmed = false
    private var handle: (any MediaTimelineTickerHandle)?

    public init(
        now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
        makeHandle: @escaping (@escaping @Sendable () -> Void) -> any MediaTimelineTickerHandle = { tick in
            Timer.scheduledTimer(withTimeInterval: MediaTimelineTicker.tickInterval, repeats: true) { _ in
                MainActor.assumeIsolated { tick() }
            }
        }
    ) {
        self.now = now
        self.makeHandle = makeHandle
    }

    /// Whether the settled panel presentation is one where a live timeline
    /// is shown at all (`.peek` or `.expanded`, never `.compact`).
    public func setArmed(_ armed: Bool) {
        guard isArmed != armed else {
            return
        }
        isArmed = armed
        reconcile()
    }

    /// Applies a fresh authoritative snapshot, re-anchoring extrapolation.
    public func apply(presentation: ShippingMediaPresentation?) {
        isPlaying = presentation?.playbackState == .playing

        if let presentation,
            let position = presentation.positionSeconds,
            let duration = presentation.durationSeconds
        {
            anchorPositionSeconds = position
            anchorDurationSeconds = duration
            anchorCapturedAt = now()
        } else {
            anchorPositionSeconds = nil
            anchorDurationSeconds = nil
            anchorCapturedAt = nil
        }

        displayedPositionSeconds = anchorPositionSeconds
        reconcile()
    }

    /// Optimistically re-anchors at a locally committed seek target, before
    /// the system round-trip confirms it, so the bar does not visibly jump
    /// backward to the pre-seek anchor while the tick continues.
    public func applyOptimisticSeek(to positionSeconds: Double) {
        guard let anchorDurationSeconds, positionSeconds.isFinite, positionSeconds >= 0 else {
            return
        }

        anchorPositionSeconds = min(positionSeconds, anchorDurationSeconds)
        anchorCapturedAt = now()
        displayedPositionSeconds = anchorPositionSeconds
    }

    public func invalidate() {
        handle?.invalidate()
        handle = nil
    }

    private func reconcile() {
        let shouldRun = isArmed && isPlaying && anchorCapturedAt != nil
        if shouldRun, handle == nil {
            handle = makeHandle { [weak self] in
                MainActor.assumeIsolated {
                    self?.tick()
                }
            }
        } else if !shouldRun, handle != nil {
            invalidate()
        }
    }

    private func tick() {
        guard
            let anchorPositionSeconds,
            let anchorDurationSeconds,
            let anchorCapturedAt
        else {
            return
        }

        let elapsed = max(0, now() - anchorCapturedAt)
        displayedPositionSeconds = min(anchorDurationSeconds, anchorPositionSeconds + elapsed)
    }
}
