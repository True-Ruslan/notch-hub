import Foundation

public enum ShippingMediaCompactCommandAction: Sendable, Equatable {
    case previous
    case next
}

@MainActor
public final class ShippingMediaCompactCommandDispatcher {
    typealias ProcessClientFactory = @MainActor (ShippingMediaBundlePaths) ->
        any MediaRemoteProcessClientProtocol

    private let makeProcessClient: @MainActor () throws -> any MediaRemoteProcessClientProtocol
    private var processClient: (any MediaRemoteProcessClientProtocol)?
    private var generation: UInt64 = 0
    private var isStopped = false

    public init() {
        let bundle = Bundle.main
        let fileManager = FileManager.default
        self.makeProcessClient = {
            let paths = try ShippingMediaBundlePaths.resolveValidated(
                bundle: bundle,
                fileManager: fileManager
            )
            return MediaRemoteProcessClient(
                scriptURL: paths.scriptURL,
                frameworkURL: paths.frameworkURL
            )
        }
    }

    init(processClient: any MediaRemoteProcessClientProtocol) {
        self.makeProcessClient = { processClient }
        self.processClient = processClient
    }

    init(
        bundle: Bundle,
        fileManager: FileManager,
        processClientFactory: @escaping ProcessClientFactory
    ) {
        self.makeProcessClient = {
            let paths = try ShippingMediaBundlePaths.resolveValidated(
                bundle: bundle,
                fileManager: fileManager
            )
            return processClientFactory(paths)
        }
    }

    public func isSupported(_ action: ShippingMediaCompactCommandAction) async -> Bool {
        guard !isStopped, let client = resolveProcessClient() else {
            return false
        }

        let operationGeneration = generation
        do {
            let capabilities = try await client.capabilities()
            guard !isStopped, generation == operationGeneration else {
                return false
            }

            switch action {
            case .previous:
                return capabilities.previous == .supported
            case .next:
                return capabilities.next == .supported
            }
        } catch {
            return false
        }
    }

    public func send(_ action: ShippingMediaCompactCommandAction) async -> Bool {
        guard !isStopped, let client = resolveProcessClient() else {
            return false
        }

        let operationGeneration = generation
        let command: MediaCommand
        switch action {
        case .previous:
            command = .previous
        case .next:
            command = .next
        }

        let result = await client.send(command)
        guard !isStopped, generation == operationGeneration else {
            return false
        }
        return result == .sent
    }

    public func stop() {
        guard !isStopped else {
            return
        }

        isStopped = true
        generation &+= 1
        processClient?.stop()
        processClient = nil
    }

    private func resolveProcessClient() -> (any MediaRemoteProcessClientProtocol)? {
        guard !isStopped else {
            return nil
        }
        if let processClient {
            return processClient
        }

        do {
            let processClient = try makeProcessClient()
            self.processClient = processClient
            return processClient
        } catch {
            return nil
        }
    }
}
