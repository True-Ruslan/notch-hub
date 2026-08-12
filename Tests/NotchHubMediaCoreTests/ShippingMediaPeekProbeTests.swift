import Foundation
import Testing
@testable import NotchHubMediaCore

@MainActor
struct ShippingMediaPeekProbeTests {
    @Test
    func sessionWithResolvedCapabilitiesReturnsPresentationAndStopsTransport() {
        let fixture = makeFixture()
        var results: [ShippingMediaPeekProbe.Result] = []

        fixture.probe.acquire { results.append($0) }
        fixture.transport.emit(.ready)
        fixture.transport.emit(.session(snapshot(revision: 1, capabilities: resolvedCapabilities)))

        #expect(results.count == 1)
        #expect(results[0].presentation?.title == "Track")
        #expect(results[0].presentation?.canGoPrevious == true)
        #expect(results[0].presentation?.canGoNext == true)
        #expect(results[0].presentation?.canSeek == true)
        #expect(fixture.transport.startCount == 1)
        #expect(fixture.transport.stopCount == 1)
        #expect(fixture.transport.eventHandler == nil)
        #expect(fixture.scheduler.pendingCount == 0)
    }

    @Test
    func noSessionReturnsNoSessionAndStopsTransport() {
        let fixture = makeFixture()
        var results: [ShippingMediaPeekProbe.Result] = []

        fixture.probe.acquire { results.append($0) }
        fixture.transport.emit(.noSession(MediaSequence(generation: 2, revision: 1)))

        #expect(results == [.noSession])
        #expect(fixture.transport.stopCount == 1)
        #expect(fixture.scheduler.pendingCount == 0)
    }

    @Test
    func failureReturnsFailedAndStopsTransport() {
        let fixture = makeFixture()
        var results: [ShippingMediaPeekProbe.Result] = []

        fixture.probe.acquire { results.append($0) }
        fixture.transport.emit(.failed(.transport))

        #expect(results == [.failed])
        #expect(fixture.transport.stopCount == 1)
        #expect(fixture.scheduler.pendingCount == 0)
    }

    @Test
    func timeoutReturnsFailedAndStopsTransportWithoutSnapshot() {
        let fixture = makeFixture()
        var results: [ShippingMediaPeekProbe.Result] = []

        fixture.probe.acquire { results.append($0) }
        fixture.scheduler.advance(by: 0.999)
        #expect(results.isEmpty)

        fixture.scheduler.advance(by: 0.001)

        #expect(results == [.failed])
        #expect(fixture.transport.stopCount == 1)
    }

    @Test
    func timeoutReturnsLatestUsableSnapshotWhenCapabilitiesStayUnknown() {
        let fixture = makeFixture()
        var results: [ShippingMediaPeekProbe.Result] = []

        fixture.probe.acquire { results.append($0) }
        fixture.transport.emit(.session(snapshot(revision: 1, capabilities: unknownCapabilities)))
        #expect(results.isEmpty)

        fixture.scheduler.advance(by: 1.0)

        #expect(results.count == 1)
        #expect(results[0].presentation?.title == "Track")
        #expect(results[0].presentation?.canGoPrevious == false)
        #expect(results[0].presentation?.canGoNext == false)
        #expect(results[0].presentation?.canSeek == false)
        #expect(fixture.transport.stopCount == 1)
    }

    @Test
    func cancelMakesLateTransportEventHarmless() {
        let fixture = makeFixture()
        var results: [ShippingMediaPeekProbe.Result] = []

        fixture.probe.acquire { results.append($0) }
        let staleHandler = fixture.transport.eventHandler
        fixture.probe.cancel()

        staleHandler?(.session(snapshot(revision: 1, capabilities: resolvedCapabilities)))
        fixture.scheduler.advance(by: 2, invokeCancelled: true)

        #expect(results.isEmpty)
        #expect(fixture.transport.stopCount == 1)
        #expect(fixture.transport.eventHandler == nil)
    }

    @Test
    func firstUnknownCapabilitySnapshotCanBeReplacedByResolvedRevisionBeforeCompletion() {
        let fixture = makeFixture()
        var results: [ShippingMediaPeekProbe.Result] = []

        fixture.probe.acquire { results.append($0) }
        fixture.transport.emit(.session(snapshot(revision: 1, capabilities: unknownCapabilities)))
        #expect(results.isEmpty)

        fixture.transport.emit(.session(snapshot(revision: 2, capabilities: resolvedCapabilities)))

        #expect(results.count == 1)
        #expect(results[0].presentation?.sessionIdentity?.generation == 1)
        #expect(results[0].presentation?.canSeek == true)
        #expect(fixture.transport.stopCount == 1)
    }

    @Test
    func repeatedAcquireCancelsPreviousTransportOwnershipBeforeStartingNewGeneration() {
        let fixture = makeFixture()
        var firstResults: [ShippingMediaPeekProbe.Result] = []
        var secondResults: [ShippingMediaPeekProbe.Result] = []

        fixture.probe.acquire { firstResults.append($0) }
        let staleHandler = fixture.transport.eventHandler
        fixture.probe.acquire { secondResults.append($0) }

        staleHandler?(.noSession(MediaSequence(generation: 5, revision: 1)))
        fixture.transport.emit(.session(snapshot(revision: 1, capabilities: resolvedCapabilities)))

        #expect(firstResults.isEmpty)
        #expect(secondResults.count == 1)
        #expect(fixture.transport.startCount == 2)
        #expect(fixture.transport.stopCount == 2)
    }

    private var unknownCapabilities: MediaCommandCapabilities {
        MediaCommandCapabilities(previous: .unknown, next: .unknown, seek: .unknown)
    }

    private var resolvedCapabilities: MediaCommandCapabilities {
        MediaCommandCapabilities(previous: .supported, next: .supported, seek: .supported)
    }

    private func snapshot(
        revision: UInt64,
        capabilities: MediaCommandCapabilities
    ) -> MediaSessionSnapshot {
        MediaSessionSnapshot(
            sequence: MediaSequence(generation: 1, revision: revision),
            source: MediaSourceIdentity(bundleIdentifier: "com.example.player", displayName: "Player"),
            title: "Track",
            artist: "Artist",
            album: "Album",
            artworkData: nil,
            playbackState: .playing,
            durationSeconds: 180,
            positionSeconds: 30,
            referenceDate: nil,
            playbackRate: 1,
            capabilities: capabilities
        )
    }

    private func makeFixture() -> PeekProbeFixture {
        let transport = PeekProbeFakeTransport()
        let scheduler = PeekProbeManualScheduler()
        let probe = ShippingMediaPeekProbe(
            makeTransport: { transport },
            scheduleTimeout: { delay, action in
                scheduler.schedule(after: delay, action: action)
            },
            timeoutSeconds: 1.0
        )
        return PeekProbeFixture(
            transport: transport,
            scheduler: scheduler,
            probe: probe
        )
    }
}

private extension ShippingMediaPeekProbe.Result {
    var presentation: ShippingMediaPresentation? {
        if case .presentation(let presentation) = self {
            return presentation
        }
        return nil
    }
}

@MainActor
private struct PeekProbeFixture {
    let transport: PeekProbeFakeTransport
    let scheduler: PeekProbeManualScheduler
    let probe: ShippingMediaPeekProbe
}

@MainActor
private final class PeekProbeFakeTransport: SystemMediaTransport {
    var eventHandler: (@MainActor @Sendable (SystemMediaTransportEvent) -> Void)?
    private(set) var startCount = 0
    private(set) var stopCount = 0

    func start() {
        startCount += 1
    }

    func stop() {
        stopCount += 1
    }

    func send(_ command: MediaCommand) async -> MediaCommandResult {
        .failed
    }

    func emit(_ event: SystemMediaTransportEvent) {
        eventHandler?(event)
    }
}

@MainActor
private final class PeekProbeManualScheduler {
    private final class Token {
        var isCancelled = false
    }

    private struct Entry {
        let deadline: TimeInterval
        let token: Token
        let action: @MainActor () -> Void
    }

    private var now: TimeInterval = 0
    private var entries: [Entry] = []

    var pendingCount: Int {
        entries.count(where: { !$0.token.isCancelled })
    }

    func schedule(
        after delay: TimeInterval,
        action: @escaping @MainActor () -> Void
    ) -> @MainActor () -> Void {
        let token = Token()
        entries.append(Entry(deadline: now + delay, token: token, action: action))
        return { token.isCancelled = true }
    }

    func advance(by seconds: TimeInterval, invokeCancelled: Bool = false) {
        now += seconds
        let due = entries.filter { $0.deadline <= now }
        entries.removeAll { $0.deadline <= now }
        for entry in due where !entry.token.isCancelled || invokeCancelled {
            entry.action()
        }
    }
}
