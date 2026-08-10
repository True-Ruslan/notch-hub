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
    private let processClient: any MediaRemoteProcessClientProtocol
    private let wait: @MainActor @Sendable (TimeInterval) async -> Void

    public convenience init(
        scriptURL: URL,
        frameworkURL: URL,
        sourceCommit: String
    ) {
        self.init(
            sourceCommit: sourceCommit,
            processClient: MediaRemoteProcessClient(
                scriptURL: scriptURL,
                frameworkURL: frameworkURL
            ),
            wait: Self.waitOnce
        )
    }

    init(
        sourceCommit: String,
        processClient: any MediaRemoteProcessClientProtocol,
        wait: @escaping @MainActor @Sendable (TimeInterval) async -> Void
    ) {
        self.sourceCommit = sourceCommit
        self.processClient = processClient
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

        let transport = MediaRemoteSystemTransport(processClient: processClient)
        let bridge = SystemMediaBridge(transport: transport)
        let controller = MediaSessionController(provider: bridge)
        let collector = ProductionMediaTransportCandidateCollectorBox(sourceCommit: sourceCommit)

        controller.changeHandler = { [weak controller, weak collector] in
            guard let controller, let collector else {
                return
            }
            collector.record(state: controller.state, snapshot: controller.snapshot)
        }

        controller.start()
        await wait(seconds)
        controller.changeHandler = nil
        controller.stop()

        return collector.report(cleanTeardown: processClient.lastTeardownClean)
    }

    public func capabilities() async throws -> ProductionMediaTransportCandidateCapabilities {
        ProductionMediaTransportCandidateCapabilities(try await processClient.capabilities())
    }

    public func send(_ command: ProductionMediaTransportCandidateCommand) async -> Bool {
        let transport = MediaRemoteSystemTransport(processClient: processClient)
        transport.start()
        defer {
            transport.stop()
        }

        return await transport.send(command.mediaCommand) == .sent
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

    func record(state: MediaSubsystemState, snapshot: MediaSessionSnapshot?) {
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
