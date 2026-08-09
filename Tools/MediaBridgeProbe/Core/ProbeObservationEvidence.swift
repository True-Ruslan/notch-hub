import Foundation

@MainActor
public final class ProbeObservationEvidence {
    public private(set) var sourceBundleIdentifier: String?
    public private(set) var observedSession = false
    public private(set) var observedArtwork = false
    public private(set) var observedPlayingState = false
    public private(set) var observedSessionDisappearance = false
    public private(set) var sourceSwitchCount = 0
    public private(set) var eventCount = 0

    private var lastObservedBundleIdentifier: String?

    public init() {}

    public func record(_ payload: ProbeMediaPayload?) {
        eventCount += 1

        guard let payload else {
            if observedSession {
                observedSessionDisappearance = true
            }
            return
        }

        if let previous = lastObservedBundleIdentifier,
           previous != payload.bundleIdentifier
        {
            sourceSwitchCount += 1
        }

        lastObservedBundleIdentifier = payload.bundleIdentifier
        sourceBundleIdentifier = payload.bundleIdentifier
        observedSession = true
        observedPlayingState = true
        observedArtwork = observedArtwork || payload.artworkByteCount > 0
    }
}
