import Foundation

struct ProbeProcessConfiguration: Equatable, Sendable {
    let executableURL: URL
    let arguments: [String]
}

enum ProbeProcessState: Equatable, Sendable {
    case stopped
    case running
    case failed(exitCode: Int32)
    case protocolFailure
}

@MainActor
protocol ProbeProcessHandle: AnyObject {
    var isRunning: Bool { get }
    var terminationStatus: Int32 { get }

    func terminate()
    func waitUntilExit()
    func clearHandlers()
}

@MainActor
protocol ProbeProcessLaunching: AnyObject {
    func launch(
        configuration: ProbeProcessConfiguration,
        stdout: @escaping (Data) -> Void,
        stderr: @escaping (Data) -> Void,
        termination: @escaping (Int32) -> Void
    ) throws -> any ProbeProcessHandle
}

@MainActor
public final class ProbeProcessController {
    public static let maximumStderrBytes = 64 * 1024

    private let launcher: any ProbeProcessLaunching
    private var ownedProcess: (any ProbeProcessHandle)?
    private var stdoutBuffer = Data()
    private var generation: UInt64 = 0

    private(set) var state: ProbeProcessState = .stopped
    public private(set) var stderrByteCount = 0
    public var onPayload: ((ProbeMediaPayload?) -> Void)?

    public convenience init() {
        self.init(launcher: FoundationProbeProcessLauncher())
    }

    init(launcher: any ProbeProcessLaunching) {
        self.launcher = launcher
    }

    public func startObservation(
        scriptURL: URL,
        frameworkURL: URL,
        testClientURL: URL
    ) throws {
        guard ownedProcess == nil else {
            return
        }

        generation &+= 1
        let currentGeneration = generation
        stdoutBuffer.removeAll(keepingCapacity: false)
        stderrByteCount = 0

        let configuration = ProbeProcessConfiguration(
            executableURL: URL(fileURLWithPath: "/usr/bin/perl"),
            arguments: [
                scriptURL.path,
                frameworkURL.path,
                testClientURL.path,
                "stream",
                "--no-diff",
                "--micros",
            ]
        )

        let process = try launcher.launch(
            configuration: configuration,
            stdout: { [weak self] data in
                self?.receiveStdout(data, generation: currentGeneration)
            },
            stderr: { [weak self] data in
                self?.receiveStderr(data, generation: currentGeneration)
            },
            termination: { [weak self] status in
                self?.receiveTermination(status, generation: currentGeneration)
            }
        )

        ownedProcess = process
        state = .running
    }

    public func stop() {
        finishOwnedProcess(finalState: .stopped)
    }

    public func runCommand(
        _ command: ProbeMediaCommand,
        scriptURL: URL,
        frameworkURL: URL,
        testClientURL: URL
    ) throws -> Int32 {
        let configuration = ProbeProcessConfiguration(
            executableURL: URL(fileURLWithPath: "/usr/bin/perl"),
            arguments: try command.adapterArguments(
                scriptURL: scriptURL,
                frameworkURL: frameworkURL,
                testClientURL: testClientURL
            )
        )

        let process = try launcher.launch(
            configuration: configuration,
            stdout: { _ in },
            stderr: { _ in },
            termination: { _ in }
        )
        process.waitUntilExit()
        let status = process.terminationStatus
        process.clearHandlers()
        return status
    }

    private func receiveStdout(_ data: Data, generation eventGeneration: UInt64) {
        guard eventGeneration == generation, state == .running else {
            return
        }

        stdoutBuffer.append(data)
        guard stdoutBuffer.count <= ProbePayloadDecoder.maximumLineBytes else {
            finishOwnedProcess(finalState: .protocolFailure)
            return
        }

        while let newlineIndex = stdoutBuffer.firstIndex(of: 0x0A) {
            var line = stdoutBuffer[..<newlineIndex]
            stdoutBuffer.removeSubrange(...newlineIndex)

            if line.last == 0x0D {
                line = line.dropLast()
            }

            guard line.count <= ProbePayloadDecoder.maximumLineBytes else {
                finishOwnedProcess(finalState: .protocolFailure)
                return
            }

            do {
                let payload = try ProbePayloadDecoder.decode(line: Data(line))
                onPayload?(payload)
            } catch {
                finishOwnedProcess(finalState: .protocolFailure)
                return
            }
        }
    }

    private func receiveStderr(_ data: Data, generation eventGeneration: UInt64) {
        guard eventGeneration == generation, state == .running else {
            return
        }

        stderrByteCount = min(
            Self.maximumStderrBytes,
            stderrByteCount + data.count
        )
    }

    private func receiveTermination(_ status: Int32, generation eventGeneration: UInt64) {
        guard eventGeneration == generation, ownedProcess != nil else {
            return
        }

        generation &+= 1
        ownedProcess?.clearHandlers()
        ownedProcess = nil
        stdoutBuffer.removeAll(keepingCapacity: false)
        state = status == 0 ? .stopped : .failed(exitCode: status)
    }

    private func finishOwnedProcess(finalState: ProbeProcessState) {
        generation &+= 1

        guard let process = ownedProcess else {
            stdoutBuffer.removeAll(keepingCapacity: false)
            state = finalState
            return
        }

        process.clearHandlers()
        if process.isRunning {
            process.terminate()
        }
        process.waitUntilExit()
        ownedProcess = nil
        stdoutBuffer.removeAll(keepingCapacity: false)
        state = finalState
    }
}

@MainActor
private final class FoundationProbeProcessLauncher: ProbeProcessLaunching {
    func launch(
        configuration: ProbeProcessConfiguration,
        stdout: @escaping (Data) -> Void,
        stderr: @escaping (Data) -> Void,
        termination: @escaping (Int32) -> Void
    ) throws -> any ProbeProcessHandle {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let callbacks = ProbeProcessCallbacks(
            stdout: stdout,
            stderr: stderr,
            termination: termination
        )

        process.executableURL = configuration.executableURL
        process.arguments = configuration.arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                return
            }
            Task { @MainActor in
                callbacks.stdout(data)
            }
        }
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                return
            }
            Task { @MainActor in
                callbacks.stderr(data)
            }
        }
        process.terminationHandler = { process in
            let status = process.terminationStatus
            Task { @MainActor in
                callbacks.termination(status)
            }
        }

        do {
            try process.run()
        } catch {
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            process.terminationHandler = nil
            throw error
        }

        return FoundationProbeProcessHandle(
            process: process,
            stdoutPipe: stdoutPipe,
            stderrPipe: stderrPipe
        )
    }
}

private final class ProbeProcessCallbacks: @unchecked Sendable {
    let stdout: @MainActor (Data) -> Void
    let stderr: @MainActor (Data) -> Void
    let termination: @MainActor (Int32) -> Void

    init(
        stdout: @escaping @MainActor (Data) -> Void,
        stderr: @escaping @MainActor (Data) -> Void,
        termination: @escaping @MainActor (Int32) -> Void
    ) {
        self.stdout = stdout
        self.stderr = stderr
        self.termination = termination
    }
}

@MainActor
private final class FoundationProbeProcessHandle: ProbeProcessHandle {
    private let process: Process
    private let stdoutPipe: Pipe
    private let stderrPipe: Pipe

    init(process: Process, stdoutPipe: Pipe, stderrPipe: Pipe) {
        self.process = process
        self.stdoutPipe = stdoutPipe
        self.stderrPipe = stderrPipe
    }

    var isRunning: Bool {
        process.isRunning
    }

    var terminationStatus: Int32 {
        process.terminationStatus
    }

    func terminate() {
        process.terminate()
    }

    func waitUntilExit() {
        process.waitUntilExit()
    }

    func clearHandlers() {
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil
        process.terminationHandler = nil
    }
}
