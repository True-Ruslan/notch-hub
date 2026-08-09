import Foundation
import Testing
@testable import NotchHubMediaCore

@MainActor
struct MediaRemoteProcessTeardownTests {
    private let scriptURL = URL(fileURLWithPath: "/bundle/mediaremote-adapter.pl")
    private let frameworkURL = URL(fileURLWithPath: "/bundle/MediaRemoteAdapter.framework")

    @Test
    func stopEscalatesFromGracefulToForcedTerminationWithinFixedBounds() throws {
        let launcher = BoundedTeardownLauncher(waitResults: [false, true])
        let scheduler = BoundedTeardownTimeoutScheduler()
        let client = MediaRemoteProcessClient(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            launcher: launcher,
            timeoutScheduler: scheduler
        )

        try client.startObservation()
        client.stop()

        #expect(client.lastTeardownClean)
        #expect(launcher.handle.terminateCount == 1)
        #expect(launcher.handle.forceTerminateCount == 1)
        #expect(
            launcher.handle.waitTimeouts == [
                MediaRemoteProcessClient.gracefulTerminationTimeoutSeconds,
                MediaRemoteProcessClient.forcedTerminationTimeoutSeconds
            ])
    }

    @Test
    func stopFailsClosedWhenForcedTerminationCannotBeConfirmed() throws {
        let launcher = BoundedTeardownLauncher(waitResults: [false, false])
        let scheduler = BoundedTeardownTimeoutScheduler()
        let client = MediaRemoteProcessClient(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            launcher: launcher,
            timeoutScheduler: scheduler
        )

        try client.startObservation()
        client.stop()

        #expect(!client.lastTeardownClean)
        #expect(client.state == .teardownFailure)
        #expect(launcher.handle.terminateCount == 1)
        #expect(launcher.handle.forceTerminateCount == 1)
    }
}

@MainActor
private final class BoundedTeardownLauncher: MediaRemoteProcessLaunching {
    let handle: BoundedTeardownHandle

    init(waitResults: [Bool]) {
        handle = BoundedTeardownHandle(waitResults: waitResults)
    }

    func launch(
        configuration _: MediaRemoteProcessConfiguration,
        stdout _: @escaping @MainActor @Sendable (Data) -> Void,
        stderr _: @escaping @MainActor @Sendable (Data) -> Void,
        termination _: @escaping @MainActor @Sendable (Int32) -> Void
    ) throws -> any MediaRemoteProcessHandle {
        handle.isRunning = true
        return handle
    }
}

@MainActor
private final class BoundedTeardownHandle: MediaRemoteProcessHandle {
    var isRunning = false
    var terminationStatus: Int32 = 0
    var terminateCount = 0
    var forceTerminateCount = 0
    var waitUntilExitCount = 0
    var waitTimeouts: [TimeInterval] = []
    private var waitResults: [Bool]

    init(waitResults: [Bool]) {
        self.waitResults = waitResults
    }

    func terminate() {
        terminateCount += 1
    }

    func forceTerminate() {
        forceTerminateCount += 1
    }

    func waitUntilExit() {
        waitUntilExitCount += 1
    }

    func waitUntilExit(timeout: TimeInterval) -> Bool {
        waitTimeouts.append(timeout)
        let result = waitResults.isEmpty ? false : waitResults.removeFirst()
        if result {
            isRunning = false
        }
        return result
    }

    func readStdout(maximumBytes _: Int) throws -> Data {
        Data()
    }

    func clearHandlers() {}
}

@MainActor
private final class BoundedTeardownTimeoutScheduler: MediaRemoteTimeoutScheduling {
    func schedule(
        after _: TimeInterval,
        action _: @escaping @MainActor @Sendable () -> Void
    ) -> any MediaRemoteTimeoutToken {
        BoundedTeardownTimeoutToken()
    }
}

@MainActor
private final class BoundedTeardownTimeoutToken: MediaRemoteTimeoutToken {
    func cancel() {}
}
