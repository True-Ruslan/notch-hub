import Foundation
import Testing
@testable import NotchHubMediaCore

@MainActor
struct MediaRemoteOneShotLifecycleTests {
    private let scriptURL = URL(fileURLWithPath: "/bundle/mediaremote-adapter.pl")
    private let frameworkURL = URL(fileURLWithPath: "/bundle/MediaRemoteAdapter.framework")

    @Test
    func stopOwnsObservationAndEveryInFlightOneShotAndRejectsStaleCallbacks() async throws {
        let launcher = OneShotLifecycleLauncher()
        let scheduler = OneShotLifecycleTimeoutScheduler()
        let client = makeClient(launcher: launcher, scheduler: scheduler)

        try client.startObservation()
        let commandTask = Task { @MainActor in
            await client.send(.next)
        }
        let capabilityTask = Task { @MainActor in
            do {
                _ = try await client.capabilities()
                return true
            } catch {
                return false
            }
        }

        await waitForLaunchCount(3, launcher: launcher)
        #expect(launcher.records.count == 3)
        #expect(scheduler.entries.count == 2)

        let staleTerminationCallbacks = launcher.records.map(\.staleTermination)

        client.stop()

        #expect(client.state == .stopped)
        #expect(client.lastTeardownClean)
        #expect(launcher.records.allSatisfy { $0.handle.terminateCount == 1 })
        #expect(
            launcher.records.allSatisfy {
                $0.handle.waitTimeouts
                    == [MediaRemoteProcessClient.gracefulTerminationTimeoutSeconds]
            })
        #expect(scheduler.cancelledCount == 2)

        scheduler.fireAll()
        #expect(await commandTask.value == .failed)
        #expect(await capabilityTask.value == false)

        for callback in staleTerminationCallbacks {
            callback(0)
        }
        client.stop()

        #expect(launcher.records.allSatisfy { $0.handle.terminateCount == 1 })
        #expect(client.state == .stopped)
        #expect(client.lastTeardownClean)
    }

    @Test
    func nonblockingStopCancelsOneShotBeforeDeferredTerminationDeadlines() async throws {
        let launcher = OneShotLifecycleLauncher { _ in [false, false] }
        let scheduler = OneShotLifecycleTimeoutScheduler()
        let client = makeClient(launcher: launcher, scheduler: scheduler)

        let commandTask = Task { @MainActor in
            await client.send(.previous)
        }

        await waitForLaunchCount(1, launcher: launcher)
        let handle = try #require(launcher.records.first?.handle)

        client.stopNonBlocking()

        #expect(client.state == .stopped)
        #expect(client.lastTeardownClean)
        #expect(handle.terminateCount == 1)
        #expect(handle.forceTerminateCount == 0)
        #expect(handle.waitTimeouts.isEmpty)
        #expect(scheduler.cancelledCount == 1)
        #expect(await commandTask.value == .failed)

        scheduler.fireNextPending()

        #expect(handle.forceTerminateCount == 1)
        #expect(handle.waitTimeouts.isEmpty)

        handle.isRunning = false
        scheduler.fireNextPending()
        client.stop()

        #expect(handle.terminateCount == 1)
        #expect(handle.forceTerminateCount == 1)
        #expect(handle.waitTimeouts.isEmpty)
        #expect(client.state == .stopped)
        #expect(client.lastTeardownClean)
    }

    @Test
    func failedOneShotTeardownFailsClosedAndRemainsOwnedForRetry() async throws {
        let launcher = OneShotLifecycleLauncher { _ in [false, false] }
        let scheduler = OneShotLifecycleTimeoutScheduler()
        let client = makeClient(launcher: launcher, scheduler: scheduler)

        let commandTask = Task { @MainActor in
            await client.send(.previous)
        }

        await waitForLaunchCount(1, launcher: launcher)
        let handle = try #require(launcher.records.first?.handle)

        client.stop()

        #expect(!client.lastTeardownClean)
        #expect(client.state == .teardownFailure)
        #expect(handle.terminateCount == 1)
        #expect(handle.forceTerminateCount == 1)
        #expect(
            handle.waitTimeouts
                == [
                    MediaRemoteProcessClient.gracefulTerminationTimeoutSeconds,
                    MediaRemoteProcessClient.forcedTerminationTimeoutSeconds
                ])
        #expect(scheduler.cancelledCount == 1)

        scheduler.fireAll()
        #expect(await commandTask.value == .failed)

        handle.replaceWaitResults([true])
        client.stop()

        #expect(client.lastTeardownClean)
        #expect(client.state == .stopped)
        #expect(handle.terminateCount == 2)
        #expect(handle.forceTerminateCount == 1)
        #expect(
            handle.waitTimeouts
                == [
                    MediaRemoteProcessClient.gracefulTerminationTimeoutSeconds,
                    MediaRemoteProcessClient.forcedTerminationTimeoutSeconds,
                    MediaRemoteProcessClient.gracefulTerminationTimeoutSeconds
                ])
    }

    private func makeClient(
        launcher: OneShotLifecycleLauncher,
        scheduler: OneShotLifecycleTimeoutScheduler
    ) -> MediaRemoteProcessClient {
        MediaRemoteProcessClient(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            launcher: launcher,
            timeoutScheduler: scheduler
        )
    }

    private func waitForLaunchCount(
        _ expectedCount: Int,
        launcher: OneShotLifecycleLauncher
    ) async {
        for _ in 0..<16 {
            if launcher.records.count >= expectedCount {
                return
            }
            await Task.yield()
        }
    }
}

@MainActor
private final class OneShotLifecycleLauncher: MediaRemoteProcessLaunching {
    private let waitResults: (Int) -> [Bool]
    private(set) var records: [OneShotLifecycleLaunchRecord] = []

    init(waitResults: @escaping (Int) -> [Bool] = { _ in [true] }) {
        self.waitResults = waitResults
    }

    func launch(
        configuration: MediaRemoteProcessConfiguration,
        stdout _: @escaping @MainActor @Sendable (Data) -> Void,
        stderr _: @escaping @MainActor @Sendable (Data) -> Void,
        termination: @escaping @MainActor @Sendable (Int32) -> Void
    ) throws -> any MediaRemoteProcessHandle {
        let index = records.count
        let handle = OneShotLifecycleHandle(waitResults: waitResults(index))
        handle.isRunning = true
        handle.capturedStdout = Data(
            #"{"next":"supported","previous":"supported","seek":"supported"}"#.utf8
        )

        let record = OneShotLifecycleLaunchRecord(
            configuration: configuration,
            handle: handle,
            termination: termination
        )
        handle.clearHandlersAction = { [weak record] in
            record?.currentTermination = nil
        }
        records.append(record)
        return handle
    }
}

@MainActor
private final class OneShotLifecycleLaunchRecord {
    let configuration: MediaRemoteProcessConfiguration
    let handle: OneShotLifecycleHandle
    let staleTermination: @MainActor @Sendable (Int32) -> Void
    var currentTermination: (@MainActor @Sendable (Int32) -> Void)?

    init(
        configuration: MediaRemoteProcessConfiguration,
        handle: OneShotLifecycleHandle,
        termination: @escaping @MainActor @Sendable (Int32) -> Void
    ) {
        self.configuration = configuration
        self.handle = handle
        staleTermination = termination
        currentTermination = termination
    }
}

@MainActor
private final class OneShotLifecycleHandle: MediaRemoteProcessHandle {
    var isRunning = false
    var terminationStatus: Int32 = 0
    var capturedStdout = Data()
    var terminateCount = 0
    var forceTerminateCount = 0
    var clearHandlersCount = 0
    var waitTimeouts: [TimeInterval] = []
    var clearHandlersAction: (() -> Void)?

    private var waitResults: [Bool]

    init(waitResults: [Bool]) {
        self.waitResults = waitResults
    }

    func replaceWaitResults(_ results: [Bool]) {
        waitResults = results
    }

    func terminate() {
        terminateCount += 1
    }

    func forceTerminate() {
        forceTerminateCount += 1
    }

    func waitUntilExit() {}

    func waitUntilExit(timeout: TimeInterval) -> Bool {
        waitTimeouts.append(timeout)
        let result = waitResults.isEmpty ? false : waitResults.removeFirst()
        if result {
            isRunning = false
        }
        return result
    }

    func readStdout(maximumBytes: Int) throws -> Data {
        guard capturedStdout.count <= maximumBytes else {
            throw MediaRemoteProcessClientError.standardOutputTooLarge
        }
        return capturedStdout
    }

    func clearHandlers() {
        clearHandlersCount += 1
        clearHandlersAction?()
    }
}

@MainActor
private final class OneShotLifecycleTimeoutScheduler: MediaRemoteTimeoutScheduling {
    private(set) var entries: [OneShotLifecycleScheduledAction] = []

    var cancelledCount: Int {
        entries.filter(\.isCancelled).count
    }

    func schedule(
        after _: TimeInterval,
        action: @escaping @MainActor @Sendable () -> Void
    ) -> any MediaRemoteTimeoutToken {
        let entry = OneShotLifecycleScheduledAction(action: action)
        entries.append(entry)
        return OneShotLifecycleTimeoutToken(entry: entry)
    }

    func fireNextPending() {
        entries.first { !$0.isCancelled && !$0.isFired }?.fire()
    }

    func fireAll() {
        for entry in entries {
            entry.fire()
        }
    }
}

@MainActor
private final class OneShotLifecycleScheduledAction {
    private var action: (@MainActor @Sendable () -> Void)?
    private(set) var isCancelled = false
    private(set) var isFired = false

    init(action: @escaping @MainActor @Sendable () -> Void) {
        self.action = action
    }

    func cancel() {
        isCancelled = true
        action = nil
    }

    func fire() {
        guard !isFired else {
            return
        }
        isFired = true
        let action = action
        self.action = nil
        action?()
    }
}

@MainActor
private final class OneShotLifecycleTimeoutToken: MediaRemoteTimeoutToken {
    private weak var entry: OneShotLifecycleScheduledAction?

    init(entry: OneShotLifecycleScheduledAction) {
        self.entry = entry
    }

    func cancel() {
        entry?.cancel()
    }
}
