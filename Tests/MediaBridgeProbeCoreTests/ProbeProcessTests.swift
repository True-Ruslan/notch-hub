import Foundation
import Testing
@testable import MediaBridgeProbeCore

@MainActor
struct ProbeProcessTests {
    private let scriptURL = URL(fileURLWithPath: "/bundle/mediaremote-adapter.pl")
    private let frameworkURL = URL(fileURLWithPath: "/bundle/MediaRemoteAdapter.framework")
    private let testClientURL = URL(fileURLWithPath: "/bundle/MediaRemoteAdapterTestClient")

    @Test
    func startTwiceCreatesOneStreamProcess() throws {
        let launcher = FakeProbeProcessLauncher()
        let controller = ProbeProcessController(launcher: launcher)

        try controller.startObservation(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            testClientURL: testClientURL
        )
        try controller.startObservation(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            testClientURL: testClientURL
        )

        #expect(launcher.launches.count == 1)
        #expect(launcher.launches[0].executableURL.path == "/usr/bin/perl")
        #expect(
            launcher.launches[0].arguments == [
                scriptURL.path,
                frameworkURL.path,
                testClientURL.path,
                "stream",
                "--no-diff",
                "--micros"
            ]
        )
        #expect(controller.state == .running)
    }

    @Test
    func stopTerminatesAndWaitsForTheOwnedProcess() throws {
        let launcher = FakeProbeProcessLauncher()
        let controller = ProbeProcessController(launcher: launcher)

        try controller.startObservation(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            testClientURL: testClientURL
        )
        let process = try #require(launcher.lastProcess)

        controller.stop()

        #expect(process.clearHandlerCount == 1)
        #expect(process.terminateCount == 1)
        #expect(process.waitCount == 1)
        #expect(controller.state == .stopped)
    }

    @Test
    func nonzeroExitTransitionsToFailedWithoutAutomaticLoop() throws {
        let launcher = FakeProbeProcessLauncher()
        let controller = ProbeProcessController(launcher: launcher)

        try controller.startObservation(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            testClientURL: testClientURL
        )

        launcher.emitExit(17)

        #expect(controller.state == .failed(exitCode: 17))
        #expect(launcher.launches.count == 1)
    }

    @Test
    func oversizedStdoutLineStopsTheStreamAsProtocolFailure() throws {
        let launcher = FakeProbeProcessLauncher()
        let controller = ProbeProcessController(launcher: launcher)

        try controller.startObservation(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            testClientURL: testClientURL
        )
        let process = try #require(launcher.lastProcess)

        launcher.emitStdout(
            Data(repeating: 0x61, count: ProbePayloadDecoder.maximumLineBytes + 1)
        )

        #expect(controller.state == .protocolFailure)
        #expect(process.terminateCount == 1)
        #expect(process.waitCount == 1)
        #expect(launcher.launches.count == 1)
    }

    @Test
    func stderrIsBoundedAndDoesNotBecomeDurableMetadata() throws {
        let launcher = FakeProbeProcessLauncher()
        let controller = ProbeProcessController(launcher: launcher)

        try controller.startObservation(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            testClientURL: testClientURL
        )

        launcher.emitStderr(
            Data(repeating: 0x62, count: ProbeProcessController.maximumStderrBytes + 1024)
        )

        #expect(controller.stderrByteCount == ProbeProcessController.maximumStderrBytes)
        #expect(controller.state == .running)
    }

    @Test
    func commandProcessUsesFixedPerlExecutableAndAllowlistedArguments() throws {
        let launcher = FakeProbeProcessLauncher()
        launcher.nextTerminationStatus = 0
        let controller = ProbeProcessController(launcher: launcher)

        let status = try controller.runCommand(
            .next,
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            testClientURL: testClientURL
        )

        #expect(status == 0)
        #expect(launcher.launches.count == 1)
        #expect(launcher.launches[0].executableURL.path == "/usr/bin/perl")
        #expect(Array(launcher.launches[0].arguments.suffix(2)) == ["send", "4"])
    }
}

@MainActor
private final class FakeProbeProcessLauncher: ProbeProcessLaunching {
    var launches: [ProbeProcessConfiguration] = []
    var lastProcess: FakeProbeProcess?
    var nextTerminationStatus: Int32 = 0

    private var stdoutHandler: (@MainActor @Sendable (Data) -> Void)?
    private var stderrHandler: (@MainActor @Sendable (Data) -> Void)?
    private var terminationHandler: (@MainActor @Sendable (Int32) -> Void)?

    func launch(
        configuration: ProbeProcessConfiguration,
        stdout: @escaping @MainActor @Sendable (Data) -> Void,
        stderr: @escaping @MainActor @Sendable (Data) -> Void,
        termination: @escaping @MainActor @Sendable (Int32) -> Void
    ) throws -> any ProbeProcessHandle {
        launches.append(configuration)
        stdoutHandler = stdout
        stderrHandler = stderr
        terminationHandler = termination

        let process = FakeProbeProcess(terminationStatus: nextTerminationStatus)
        lastProcess = process
        return process
    }

    func emitStdout(_ data: Data) {
        stdoutHandler?(data)
    }

    func emitStderr(_ data: Data) {
        stderrHandler?(data)
    }

    func emitExit(_ status: Int32) {
        lastProcess?.terminationStatus = status
        lastProcess?.isRunning = false
        terminationHandler?(status)
    }
}

@MainActor
private final class FakeProbeProcess: ProbeProcessHandle {
    var isRunning = true
    var terminationStatus: Int32
    var terminateCount = 0
    var waitCount = 0
    var clearHandlerCount = 0

    init(terminationStatus: Int32) {
        self.terminationStatus = terminationStatus
    }

    func terminate() {
        terminateCount += 1
        isRunning = false
    }

    func waitUntilExit() {
        waitCount += 1
        isRunning = false
    }

    func clearHandlers() {
        clearHandlerCount += 1
    }
}
