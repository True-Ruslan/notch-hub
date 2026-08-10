import Darwin
import Foundation

enum MediaRemoteProcessOutputMode: Equatable, Sendable {
    case stream
    case capture
    case discard
}

struct MediaRemoteProcessConfiguration: Equatable, Sendable {
    let executableURL: URL
    let arguments: [String]
    let standardOutputMode: MediaRemoteProcessOutputMode
}

enum MediaRemoteProcessState: Equatable, Sendable {
    case stopped
    case running
    case failed(exitCode: Int32)
    case protocolFailure
    case teardownFailure
}

enum MediaRemoteProcessFailure: Equatable, Sendable {
    case transport
    case protocolViolation
}

enum MediaRemoteProcessClientError: Error, Equatable {
    case timedOut
    case teardownFailed
    case operationFailed(exitCode: Int32)
    case standardOutputUnavailable
    case standardOutputTooLarge
}

@MainActor
protocol MediaRemoteProcessHandle: AnyObject {
    var isRunning: Bool { get }
    var terminationStatus: Int32 { get }

    func terminate()
    func forceTerminate()
    func waitUntilExit()
    func waitUntilExit(timeout: TimeInterval) -> Bool
    func readStdout(maximumBytes: Int) throws -> Data
    func clearHandlers()
}

@MainActor
extension MediaRemoteProcessHandle {
    func forceTerminate() {
        terminate()
    }

    func waitUntilExit(timeout _: TimeInterval) -> Bool {
        waitUntilExit()
        return true
    }
}

@MainActor
protocol MediaRemoteProcessLaunching: AnyObject {
    func launch(
        configuration: MediaRemoteProcessConfiguration,
        stdout: @escaping @MainActor @Sendable (Data) -> Void,
        stderr: @escaping @MainActor @Sendable (Data) -> Void,
        termination: @escaping @MainActor @Sendable (Int32) -> Void
    ) throws -> any MediaRemoteProcessHandle
}

@MainActor
protocol MediaRemoteTimeoutToken: AnyObject {
    func cancel()
}

@MainActor
protocol MediaRemoteTimeoutScheduling: AnyObject {
    func schedule(
        after delay: TimeInterval,
        action: @escaping @MainActor @Sendable () -> Void
    ) -> any MediaRemoteTimeoutToken
}

@MainActor
final class MediaRemoteProcessClient {
    static let maximumStderrBytes = 64 * 1024
    static let oneShotTimeoutSeconds: TimeInterval = 5
    static let gracefulTerminationTimeoutSeconds: TimeInterval = 1
    static let forcedTerminationTimeoutSeconds: TimeInterval = 1
    static let maximumSeekSeconds = Double(MediaRemoteWireDecoder.maximumDurationMicros) / 1_000_000

    private static let maximumCapabilityBytes = 4 * 1024
    private static let perlURL = URL(fileURLWithPath: "/usr/bin/perl")

    private let scriptURL: URL
    private let frameworkURL: URL
    private let launcher: any MediaRemoteProcessLaunching
    private let timeoutScheduler: any MediaRemoteTimeoutScheduling

    private var observationProcess: (any MediaRemoteProcessHandle)?
    private var stdoutBuffer = Data()
    private var observationGeneration: UInt64 = 0

    private(set) var state: MediaRemoteProcessState = .stopped
    private(set) var stderrByteCount = 0
    private(set) var lastTeardownClean = true
    var onPayload: (@MainActor @Sendable (MediaRemoteWirePayload?) -> Void)?
    var onFailure: (@MainActor @Sendable (MediaRemoteProcessFailure) -> Void)?

    convenience init(scriptURL: URL, frameworkURL: URL) {
        self.init(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            launcher: FoundationMediaRemoteProcessLauncher(),
            timeoutScheduler: DispatchMediaRemoteTimeoutScheduler()
        )
    }

    init(
        scriptURL: URL,
        frameworkURL: URL,
        launcher: any MediaRemoteProcessLaunching,
        timeoutScheduler: any MediaRemoteTimeoutScheduling
    ) {
        self.scriptURL = scriptURL
        self.frameworkURL = frameworkURL
        self.launcher = launcher
        self.timeoutScheduler = timeoutScheduler
    }

    func startObservation() throws {
        guard observationProcess == nil else {
            return
        }

        observationGeneration &+= 1
        let currentGeneration = observationGeneration
        stdoutBuffer.removeAll(keepingCapacity: false)
        stderrByteCount = 0
        lastTeardownClean = true

        let configuration = MediaRemoteProcessConfiguration(
            executableURL: Self.perlURL,
            arguments: [
                scriptURL.path,
                frameworkURL.path,
                "stream",
                "--no-diff",
                "--micros"
            ],
            standardOutputMode: .stream
        )

        let process = try launcher.launch(
            configuration: configuration,
            stdout: { [weak self] data in
                self?.receiveObservationStdout(data, generation: currentGeneration)
            },
            stderr: { [weak self] data in
                self?.receiveObservationStderr(data, generation: currentGeneration)
            },
            termination: { [weak self] status in
                self?.receiveObservationTermination(status, generation: currentGeneration)
            }
        )

        observationProcess = process
        state = .running
    }

    func stop() {
        observationGeneration &+= 1

        guard let process = observationProcess else {
            stdoutBuffer.removeAll(keepingCapacity: false)
            state = .stopped
            lastTeardownClean = true
            return
        }

        let clean = MediaRemoteProcessTerminationPolicy.stop(process)
        lastTeardownClean = clean
        stdoutBuffer.removeAll(keepingCapacity: false)

        if clean {
            observationProcess = nil
            state = .stopped
        } else {
            state = .teardownFailure
            onFailure?(.transport)
        }
    }

    func send(_ command: MediaCommand) async -> MediaCommandResult {
        guard let arguments = commandArguments(for: command) else {
            return .failed
        }

        do {
            let result = try await runOneShot(
                arguments: arguments,
                standardOutputMode: .discard,
                maximumStdoutBytes: 0
            )
            return result.status == 0 ? .sent : .failed
        } catch {
            return .failed
        }
    }

    func capabilities() async throws -> MediaCommandCapabilities {
        let result = try await runOneShot(
            arguments: [
                scriptURL.path,
                frameworkURL.path,
                "capabilities"
            ],
            standardOutputMode: .capture,
            maximumStdoutBytes: Self.maximumCapabilityBytes
        )

        guard result.status == 0 else {
            throw MediaRemoteProcessClientError.operationFailed(exitCode: result.status)
        }

        var line = result.stdout
        while line.last == 0x0A || line.last == 0x0D {
            line.removeLast()
        }
        return try MediaRemoteCapabilityDecoder.decode(line: line)
    }

    private func commandArguments(for command: MediaCommand) -> [String]? {
        let prefix = [scriptURL.path, frameworkURL.path]

        switch command {
        case .togglePlayPause:
            return prefix + ["send", "2"]
        case .next:
            return prefix + ["send", "4"]
        case .previous:
            return prefix + ["send", "5"]
        case .seek(let seconds):
            guard
                seconds.isFinite,
                seconds > 0,
                seconds <= Self.maximumSeekSeconds
            else {
                return nil
            }

            let micros = seconds * 1_000_000
            guard micros.isFinite, micros <= Double(Int64.max) else {
                return nil
            }
            return prefix + ["seek", String(Int64(micros.rounded(.towardZero)))]
        }
    }

    private func runOneShot(
        arguments: [String],
        standardOutputMode: MediaRemoteProcessOutputMode,
        maximumStdoutBytes: Int
    ) async throws -> (status: Int32, stdout: Data) {
        let configuration = MediaRemoteProcessConfiguration(
            executableURL: Self.perlURL,
            arguments: arguments,
            standardOutputMode: standardOutputMode
        )
        let operationReference = MediaRemoteOneShotOperationReference()

        return try await withCheckedThrowingContinuation { continuation in
            do {
                let process = try launcher.launch(
                    configuration: configuration,
                    stdout: { _ in },
                    stderr: { _ in },
                    termination: { status in
                        operationReference.operation?.finish(status: status)
                    }
                )

                let operation = MediaRemoteOneShotOperation(
                    process: process,
                    standardOutputMode: standardOutputMode,
                    maximumStdoutBytes: maximumStdoutBytes,
                    continuation: continuation
                )
                operationReference.operation = operation
                operation.timeoutToken = timeoutScheduler.schedule(
                    after: Self.oneShotTimeoutSeconds,
                    action: { [weak operation] in
                        operation?.timeout()
                    }
                )
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func receiveObservationStdout(_ data: Data, generation eventGeneration: UInt64) {
        guard eventGeneration == observationGeneration, state == .running else {
            return
        }

        stdoutBuffer.append(data)

        while let newlineIndex = stdoutBuffer.firstIndex(of: 0x0A) {
            var line = Data(stdoutBuffer[..<newlineIndex])
            stdoutBuffer.removeSubrange(...newlineIndex)

            if line.last == 0x0D {
                line.removeLast()
            }

            guard line.count <= MediaRemoteWireDecoder.maximumLineBytes else {
                failObservation(.protocolViolation)
                return
            }

            do {
                onPayload?(try MediaRemoteWireDecoder.decode(line: line))
            } catch {
                failObservation(.protocolViolation)
                return
            }
        }

        guard stdoutBuffer.count <= MediaRemoteWireDecoder.maximumLineBytes else {
            failObservation(.protocolViolation)
            return
        }
    }

    private func receiveObservationStderr(_ data: Data, generation eventGeneration: UInt64) {
        guard eventGeneration == observationGeneration, state == .running else {
            return
        }

        stderrByteCount = min(Self.maximumStderrBytes, stderrByteCount + data.count)
    }

    private func receiveObservationTermination(_ status: Int32, generation eventGeneration: UInt64) {
        guard eventGeneration == observationGeneration, let process = observationProcess else {
            return
        }

        observationGeneration &+= 1
        process.clearHandlers()
        observationProcess = nil
        stdoutBuffer.removeAll(keepingCapacity: false)
        lastTeardownClean = true
        state = .failed(exitCode: status)
        onFailure?(.transport)
    }

    private func failObservation(_ failure: MediaRemoteProcessFailure) {
        observationGeneration &+= 1

        let clean: Bool
        if let process = observationProcess {
            clean = MediaRemoteProcessTerminationPolicy.stop(process)
        } else {
            clean = true
        }

        lastTeardownClean = clean
        stdoutBuffer.removeAll(keepingCapacity: false)
        if clean {
            observationProcess = nil
            state = .protocolFailure
        } else {
            state = .teardownFailure
        }
        onFailure?(failure)
    }
}

@MainActor
private enum MediaRemoteProcessTerminationPolicy {
    static func stop(_ process: any MediaRemoteProcessHandle) -> Bool {
        process.clearHandlers()
        guard process.isRunning else {
            return true
        }

        process.terminate()
        if process.waitUntilExit(timeout: MediaRemoteProcessClient.gracefulTerminationTimeoutSeconds) {
            return true
        }

        process.forceTerminate()
        return process.waitUntilExit(timeout: MediaRemoteProcessClient.forcedTerminationTimeoutSeconds)
    }
}

@MainActor
private final class MediaRemoteOneShotOperationReference {
    var operation: MediaRemoteOneShotOperation?
}

@MainActor
private final class MediaRemoteOneShotOperation {
    let process: any MediaRemoteProcessHandle
    let standardOutputMode: MediaRemoteProcessOutputMode
    let maximumStdoutBytes: Int
    let continuation: CheckedContinuation<(status: Int32, stdout: Data), Error>

    var timeoutToken: (any MediaRemoteTimeoutToken)?
    private var isCompleted = false

    init(
        process: any MediaRemoteProcessHandle,
        standardOutputMode: MediaRemoteProcessOutputMode,
        maximumStdoutBytes: Int,
        continuation: CheckedContinuation<(status: Int32, stdout: Data), Error>
    ) {
        self.process = process
        self.standardOutputMode = standardOutputMode
        self.maximumStdoutBytes = maximumStdoutBytes
        self.continuation = continuation
    }

    func finish(status: Int32) {
        guard !isCompleted else {
            return
        }
        isCompleted = true
        timeoutToken?.cancel()
        timeoutToken = nil
        process.clearHandlers()

        do {
            let stdout: Data
            if standardOutputMode == .capture {
                stdout = try process.readStdout(maximumBytes: maximumStdoutBytes)
            } else {
                stdout = Data()
            }
            continuation.resume(returning: (status, stdout))
        } catch {
            continuation.resume(throwing: error)
        }
    }

    func timeout() {
        guard !isCompleted else {
            return
        }
        isCompleted = true
        timeoutToken = nil
        let clean = MediaRemoteProcessTerminationPolicy.stop(process)
        continuation.resume(
            throwing: clean ? MediaRemoteProcessClientError.timedOut : .teardownFailed
        )
    }
}

@MainActor
private final class FoundationMediaRemoteProcessLauncher: MediaRemoteProcessLaunching {
    func launch(
        configuration: MediaRemoteProcessConfiguration,
        stdout: @escaping @MainActor @Sendable (Data) -> Void,
        stderr: @escaping @MainActor @Sendable (Data) -> Void,
        termination: @escaping @MainActor @Sendable (Int32) -> Void
    ) throws -> any MediaRemoteProcessHandle {
        let process = Process()
        let stdoutPipe: Pipe?
        let stderrPipe = Pipe()
        let exitSignal = FoundationMediaRemoteProcessExitSignal()
        let callbacks = MediaRemoteProcessCallbacks(
            stdout: stdout,
            stderr: stderr,
            termination: termination
        )

        process.executableURL = configuration.executableURL
        process.arguments = configuration.arguments

        switch configuration.standardOutputMode {
        case .stream, .capture:
            let pipe = Pipe()
            stdoutPipe = pipe
            process.standardOutput = pipe
        case .discard:
            stdoutPipe = nil
            process.standardOutput = FileHandle.nullDevice
        }
        process.standardError = stderrPipe

        if configuration.standardOutputMode == .stream {
            stdoutPipe?.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else {
                    return
                }
                Task { @MainActor in
                    callbacks.stdout(data)
                }
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
            exitSignal.signal()
            let status = process.terminationStatus
            Task { @MainActor in
                callbacks.termination(status)
            }
        }

        do {
            try process.run()
        } catch {
            stdoutPipe?.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            process.terminationHandler = nil
            exitSignal.signal()
            throw error
        }

        return FoundationMediaRemoteProcessHandle(
            process: process,
            stdoutPipe: stdoutPipe,
            stderrPipe: stderrPipe,
            capturesStdout: configuration.standardOutputMode == .capture,
            exitSignal: exitSignal
        )
    }
}

private final class MediaRemoteProcessCallbacks: Sendable {
    let stdout: @MainActor @Sendable (Data) -> Void
    let stderr: @MainActor @Sendable (Data) -> Void
    let termination: @MainActor @Sendable (Int32) -> Void

    init(
        stdout: @escaping @MainActor @Sendable (Data) -> Void,
        stderr: @escaping @MainActor @Sendable (Data) -> Void,
        termination: @escaping @MainActor @Sendable (Int32) -> Void
    ) {
        self.stdout = stdout
        self.stderr = stderr
        self.termination = termination
    }
}

private final class FoundationMediaRemoteProcessExitSignal: @unchecked Sendable {
    private let group = DispatchGroup()
    private let lock = NSLock()
    private var isSignaled = false

    init() {
        group.enter()
    }

    func signal() {
        lock.lock()
        guard !isSignaled else {
            lock.unlock()
            return
        }
        isSignaled = true
        lock.unlock()
        group.leave()
    }

    func wait(timeout: TimeInterval) -> Bool {
        group.wait(timeout: .now() + timeout) == .success
    }
}

@MainActor
private final class FoundationMediaRemoteProcessHandle: MediaRemoteProcessHandle {
    private let process: Process
    private let stdoutPipe: Pipe?
    private let stderrPipe: Pipe
    private let capturesStdout: Bool
    private let exitSignal: FoundationMediaRemoteProcessExitSignal

    init(
        process: Process,
        stdoutPipe: Pipe?,
        stderrPipe: Pipe,
        capturesStdout: Bool,
        exitSignal: FoundationMediaRemoteProcessExitSignal
    ) {
        self.process = process
        self.stdoutPipe = stdoutPipe
        self.stderrPipe = stderrPipe
        self.capturesStdout = capturesStdout
        self.exitSignal = exitSignal
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

    func forceTerminate() {
        guard process.isRunning else {
            return
        }
        _ = Darwin.kill(process.processIdentifier, SIGKILL)
    }

    func waitUntilExit() {
        process.waitUntilExit()
    }

    func waitUntilExit(timeout: TimeInterval) -> Bool {
        exitSignal.wait(timeout: timeout)
    }

    func readStdout(maximumBytes: Int) throws -> Data {
        guard capturesStdout, let stdoutPipe else {
            throw MediaRemoteProcessClientError.standardOutputUnavailable
        }

        let handle = stdoutPipe.fileHandleForReading
        var result = Data()

        for _ in 0...maximumBytes {
            let remaining = maximumBytes + 1 - result.count
            guard remaining > 0 else {
                throw MediaRemoteProcessClientError.standardOutputTooLarge
            }

            let chunk = try handle.read(upToCount: remaining) ?? Data()
            if chunk.isEmpty {
                return result
            }
            result.append(chunk)
            if result.count > maximumBytes {
                throw MediaRemoteProcessClientError.standardOutputTooLarge
            }
        }

        throw MediaRemoteProcessClientError.standardOutputTooLarge
    }

    func clearHandlers() {
        stdoutPipe?.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil
    }
}

@MainActor
private final class DispatchMediaRemoteTimeoutScheduler: MediaRemoteTimeoutScheduling {
    func schedule(
        after delay: TimeInterval,
        action: @escaping @MainActor @Sendable () -> Void
    ) -> any MediaRemoteTimeoutToken {
        let callback = MediaRemoteTimeoutCallback(action: action)
        let workItem = DispatchWorkItem {
            MainActor.assumeIsolated {
                callback.action()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        return DispatchMediaRemoteTimeoutToken(workItem: workItem)
    }
}

private final class MediaRemoteTimeoutCallback: Sendable {
    let action: @MainActor @Sendable () -> Void

    init(action: @escaping @MainActor @Sendable () -> Void) {
        self.action = action
    }
}

@MainActor
private final class DispatchMediaRemoteTimeoutToken: MediaRemoteTimeoutToken {
    private var workItem: DispatchWorkItem?

    init(workItem: DispatchWorkItem) {
        self.workItem = workItem
    }

    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}
