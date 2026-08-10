import Foundation
import NotchHubMediaCore

public enum ProductionMediaTransportCandidateError: Error, Equatable, Sendable {
    case invalidObservationDuration
    case invalidArguments
}

@MainActor
public final class ProductionMediaTransportCandidateRunner {
    public static let maximumObservationSeconds: TimeInterval = 1_200

    private let sourceCommit: String
    private let runtime: any MediaCandidateRuntimeProtocol
    private let wait: @MainActor @Sendable (TimeInterval) async -> Void

    public convenience init(
        scriptURL: URL,
        frameworkURL: URL,
        sourceCommit: String
    ) {
        self.init(
            sourceCommit: sourceCommit,
            runtime: MediaCandidateRuntime(
                scriptURL: scriptURL,
                frameworkURL: frameworkURL
            ),
            wait: Self.waitOnce
        )
    }

    init(
        sourceCommit: String,
        runtime: any MediaCandidateRuntimeProtocol,
        wait: @escaping @MainActor @Sendable (TimeInterval) async -> Void
    ) {
        self.sourceCommit = sourceCommit
        self.runtime = runtime
        self.wait = wait
    }

    public func observe(seconds: TimeInterval) async throws -> ProductionMediaTransportCandidateReport {
        guard
            seconds.isFinite,
            seconds > 0,
            seconds <= Self.maximumObservationSeconds
        else {
            throw ProductionMediaTransportCandidateError.invalidObservationDuration
        }

        let collector = ProductionMediaTransportCandidateCollectorBox(sourceCommit: sourceCommit)

        runtime.changeHandler = { [weak runtime, weak collector] in
            guard let runtime, let collector else {
                return
            }
            collector.record(state: runtime.state, snapshot: runtime.snapshot)
        }

        runtime.startObservation()
        await wait(seconds)
        runtime.changeHandler = nil
        runtime.stopObservation()

        return collector.report(cleanTeardown: runtime.lastTeardownClean)
    }

    public func capabilities() async throws -> ProductionMediaTransportCandidateCapabilities {
        ProductionMediaTransportCandidateCapabilities(try await runtime.capabilities())
    }

    public func send(_ command: ProductionMediaTransportCandidateCommand) async -> Bool {
        await runtime.send(command.runtimeCommand)
    }

    private static func waitOnce(seconds: TimeInterval) async {
        await withCheckedContinuation { continuation in
            let completion = ProductionMediaTransportWaitCompletion(continuation: continuation)
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                MainActor.assumeIsolated {
                    completion.resume()
                }
            }
        }
    }
}

@MainActor
private final class ProductionMediaTransportCandidateCollectorBox {
    private var collector: ProductionMediaTransportCandidateCollector

    init(sourceCommit: String) {
        collector = ProductionMediaTransportCandidateCollector(sourceCommit: sourceCommit)
    }

    func record(state: MediaCandidateSubsystemState, snapshot: MediaCandidateSnapshot?) {
        collector.record(state: state, snapshot: snapshot)
    }

    func report(cleanTeardown: Bool) -> ProductionMediaTransportCandidateReport {
        collector.report(cleanTeardown: cleanTeardown)
    }
}

private final class ProductionMediaTransportWaitCompletion: Sendable {
    private let continuation: CheckedContinuation<Void, Never>

    init(continuation: CheckedContinuation<Void, Never>) {
        self.continuation = continuation
    }

    func resume() {
        continuation.resume()
    }
}
