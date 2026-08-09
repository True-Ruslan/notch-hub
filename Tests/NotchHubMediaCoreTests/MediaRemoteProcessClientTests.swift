import Foundation
import Testing
@testable import NotchHubMediaCore

@MainActor
struct MediaRemoteProcessClientTests {
    private let scriptURL = URL(fileURLWithPath: "/bundle/mediaremote-adapter.pl")
    private let frameworkURL = URL(fileURLWithPath: "/bundle/MediaRemoteAdapter.framework")

    @Test
    func observationUsesFixedPerlAndExactNoDiffMicrosArguments() throws {
        let launcher = FakeMediaRemoteProcessLauncher()
        let scheduler = FakeMediaRemoteTimeoutScheduler()
        let client = makeClient(launcher: launcher, scheduler: scheduler)

        try client.startObservation()
        try client.startObservation()

        #expect(launcher.configurations.count == 1)
        #expect(launcher.configurations[0].executableURL.path == "/usr/bin/perl")
        #expect(
            launcher.configurations[0].arguments == [
                scriptURL.path,
                frameworkURL.path,
                "stream",
                "--no-diff",
                "--micros",
            ])
        #expect(launcher.configurations[0].standardOutputMode == .stream)
        #expect(client.state == .running)
    }

    @Test
    func observationDecodesCompleteLinesAndBoundsStderr() throws {
        let launcher = FakeMediaRemoteProcessLauncher()
        let scheduler = FakeMediaRemoteTimeoutScheduler()
        let client = makeClient(launcher: launcher, scheduler: scheduler)
        var receivedBundleIdentifier: String?
        client.onPayload = { payload in
            receivedBundleIdentifier = payload?.bundleIdentifier
        }

        try client.startObservation()
        let observationJSON =
            #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"player","playing":true,"title":"Track"}}"#
        launcher.emitStdout(Data((observationJSON + "\n").utf8))
        launcher.emitStderr(
            Data(repeating: 0x61, count: MediaRemoteProcessClient.maximumStderrBytes * 2)
        )

        #expect(receivedBundleIdentifier == "player")
        #expect(client.stderrByteCount == MediaRemoteProcessClient.maximumStderrBytes)
    }

    @Test
    func protocolFailureClearsHandlersTerminatesAndReportsFailure() throws {
        let launcher = FakeMediaRemoteProcessLauncher()
        let scheduler = FakeMediaRemoteTimeoutScheduler()
        let client = makeClient(launcher: launcher, scheduler: scheduler)
        var failures: [MediaRemoteProcessFailure] = []
        client.onFailure = { failures.append($0) }

        try client.startObservation()
        launcher.emitStdout(Data(repeating: 0x61, count: MediaRemoteWireDecoder.maximumLineBytes + 1))

        #expect(client.state == .protocolFailure)
        #expect(failures == [.protocolViolation])
        #expect(launcher.handle.clearHandlersCount == 1)
        #expect(launcher.handle.terminateCount == 1)
        #expect(launcher.handle.waitUntilExitCount == 1)
    }

    @Test
    func nonzeroObservationExitReportsTransportFailureWithoutRestarting() throws {
        let launcher = FakeMediaRemoteProcessLauncher()
        let scheduler = FakeMediaRemoteTimeoutScheduler()
        let client = makeClient(launcher: launcher, scheduler: scheduler)
        var failures: [MediaRemoteProcessFailure] = []
        client.onFailure = { failures.append($0) }

        try client.startObservation()
        launcher.emitTermination(9)

        #expect(client.state == .failed(exitCode: 9))
        #expect(failures == [.transport])
        #expect(launcher.configurations.count == 1)
        #expect(launcher.handle.clearHandlersCount == 1)
    }

    @Test
    func stopIsIdempotentAndOwnsCleanTeardown() throws {
        let launcher = FakeMediaRemoteProcessLauncher()
        let scheduler = FakeMediaRemoteTimeoutScheduler()
        let client = makeClient(launcher: launcher, scheduler: scheduler)

        try client.startObservation()
        client.stop()
        client.stop()

        #expect(client.state == .stopped)
        #expect(launcher.handle.clearHandlersCount == 1)
        #expect(launcher.handle.terminateCount == 1)
        #expect(launcher.handle.waitUntilExitCount == 1)
    }

    @Test
    func typedCommandsUseOnlyFixedAllowlistArguments() async throws {
        let launcher = FakeMediaRemoteProcessLauncher(automaticTerminationStatus: 0)
        let scheduler = FakeMediaRemoteTimeoutScheduler()
        let client = makeClient(launcher: launcher, scheduler: scheduler)

        #expect(await client.send(.togglePlayPause) == .sent)
        #expect(await client.send(.next) == .sent)
        #expect(await client.send(.previous) == .sent)
        #expect(await client.send(.seek(seconds: 42)) == .sent)

        let arguments = launcher.configurations.map(\.arguments)
        #expect(arguments[0] == [scriptURL.path, frameworkURL.path, "send", "2"])
        #expect(arguments[1] == [scriptURL.path, frameworkURL.path, "send", "4"])
        #expect(arguments[2] == [scriptURL.path, frameworkURL.path, "send", "5"])
        #expect(arguments[3] == [scriptURL.path, frameworkURL.path, "seek", "42000000"])
        #expect(launcher.configurations.allSatisfy { $0.executableURL.path == "/usr/bin/perl" })
        #expect(launcher.configurations.allSatisfy { $0.standardOutputMode == .discard })
    }

    @Test
    func invalidSeekFailsBeforeLaunchingProcess() async {
        let launcher = FakeMediaRemoteProcessLauncher(automaticTerminationStatus: 0)
        let scheduler = FakeMediaRemoteTimeoutScheduler()
        let client = makeClient(launcher: launcher, scheduler: scheduler)

        #expect(await client.send(.seek(seconds: -.infinity)) == .failed)
        #expect(await client.send(.seek(seconds: -1)) == .failed)
        #expect(await client.send(.seek(seconds: 30 * 24 * 60 * 60 + 1)) == .failed)
        #expect(launcher.configurations.isEmpty)
    }

    @Test
    func capabilitiesUseExactInvocationAndStrictDecoder() async throws {
        let capabilitiesJSON =
            #"{"next":"supported","previous":"unsupported","seek":"unknown"}"#
        let launcher = FakeMediaRemoteProcessLauncher(
            automaticTerminationStatus: 0,
            capturedStdout: Data((capabilitiesJSON + "\n").utf8)
        )
        let scheduler = FakeMediaRemoteTimeoutScheduler()
        let client = makeClient(launcher: launcher, scheduler: scheduler)

        let capabilities = try await client.capabilities()

        #expect(launcher.configurations.count == 1)
        #expect(
            launcher.configurations[0].arguments == [
                scriptURL.path,
                frameworkURL.path,
                "capabilities",
            ])
        #expect(launcher.configurations[0].standardOutputMode == .capture)
        #expect(capabilities.next == .supported)
        #expect(capabilities.previous == .unsupported)
        #expect(capabilities.seek == .unknown)
    }

    @Test
    func oneShotTimeoutTerminatesWaitsAndFailsClosed() async {
        let launcher = FakeMediaRemoteProcessLauncher()
        let scheduler = FakeMediaRemoteTimeoutScheduler()
        let client = makeClient(launcher: launcher, scheduler: scheduler)

        let operation = Task { @MainActor in
            await client.send(.next)
        }
        await Task.yield()
        scheduler.fire()
        let result = await operation.value

        #expect(result == .failed)
        #expect(scheduler.lastDelay == MediaRemoteProcessClient.oneShotTimeoutSeconds)
        #expect(launcher.handle.terminateCount == 1)
        #expect(launcher.handle.waitUntilExitCount == 1)
        #expect(launcher.handle.clearHandlersCount == 1)
    }

    private func makeClient(
        launcher: FakeMediaRemoteProcessLauncher,
        scheduler: FakeMediaRemoteTimeoutScheduler
    ) -> MediaRemoteProcessClient {
        MediaRemoteProcessClient(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            launcher: launcher,
            timeoutScheduler: scheduler
        )
    }
}

@MainActor
private final class FakeMediaRemoteProcessLauncher: MediaRemoteProcessLaunching {
    var configurations: [MediaRemoteProcessConfiguration] = []
    let handle = FakeMediaRemoteProcessHandle()

    private let automaticTerminationStatus: Int32?
    private let capturedStdout: Data
    private var stdoutHandler: (@MainActor @Sendable (Data) -> Void)?
    private var stderrHandler: (@MainActor @Sendable (Data) -> Void)?
    private var terminationHandler: (@MainActor @Sendable (Int32) -> Void)?

    init(
        automaticTerminationStatus: Int32? = nil,
        capturedStdout: Data = Data()
    ) {
        self.automaticTerminationStatus = automaticTerminationStatus
        self.capturedStdout = capturedStdout
        handle.capturedStdout = capturedStdout
    }

    func launch(
        configuration: MediaRemoteProcessConfiguration,
        stdout: @escaping @MainActor @Sendable (Data) -> Void,
        stderr: @escaping @MainActor @Sendable (Data) -> Void,
        termination: @escaping @MainActor @Sendable (Int32) -> Void
    ) throws -> any MediaRemoteProcessHandle {
        configurations.append(configuration)
        stdoutHandler = stdout
        stderrHandler = stderr
        terminationHandler = termination
        handle.isRunning = true
        handle.clearHandlersAction = { [weak self] in
            self?.stdoutHandler = nil
            self?.stderrHandler = nil
            self?.terminationHandler = nil
        }

        if let automaticTerminationStatus {
            Task { @MainActor in
                self.handle.isRunning = false
                self.handle.terminationStatus = automaticTerminationStatus
                termination(automaticTerminationStatus)
            }
        }
        return handle
    }

    func emitStdout(_ data: Data) {
        stdoutHandler?(data)
    }

    func emitStderr(_ data: Data) {
        stderrHandler?(data)
    }

    func emitTermination(_ status: Int32) {
        handle.isRunning = false
        handle.terminationStatus = status
        terminationHandler?(status)
    }
}

@MainActor
private final class FakeMediaRemoteProcessHandle: MediaRemoteProcessHandle {
    var isRunning = false
    var terminationStatus: Int32 = 0
    var capturedStdout = Data()
    var terminateCount = 0
    var waitUntilExitCount = 0
    var clearHandlersCount = 0
    var clearHandlersAction: (() -> Void)?

    func terminate() {
        terminateCount += 1
        isRunning = false
    }

    func waitUntilExit() {
        waitUntilExitCount += 1
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
private final class FakeMediaRemoteTimeoutScheduler: MediaRemoteTimeoutScheduling {
    private(set) var lastDelay: TimeInterval?
    private var action: (@MainActor @Sendable () -> Void)?

    func schedule(
        after delay: TimeInterval,
        action: @escaping @MainActor @Sendable () -> Void
    ) -> any MediaRemoteTimeoutToken {
        lastDelay = delay
        self.action = action
        return FakeMediaRemoteTimeoutToken { [weak self] in
            self?.action = nil
        }
    }

    func fire() {
        let action = action
        self.action = nil
        action?()
    }
}

@MainActor
private final class FakeMediaRemoteTimeoutToken: MediaRemoteTimeoutToken {
    private let cancellation: () -> Void

    init(cancellation: @escaping () -> Void) {
        self.cancellation = cancellation
    }

    func cancel() {
        cancellation()
    }
}
