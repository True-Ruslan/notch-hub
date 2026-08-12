import Foundation
import Testing
@testable import NotchHubMediaCore

@MainActor
struct ShippingMediaCompactCommandDispatcherTests {
    @Test
    func mapsPreviousNextAndSeekCapabilitiesExactlyWithoutObservation() async {
        let client = CompactCommandProcessClient()
        client.capabilityResult = .success(
            MediaCommandCapabilities(
                previous: .supported,
                next: .unknown,
                seek: .supported
            )
        )
        let dispatcher = ShippingMediaCompactCommandDispatcher(processClient: client)

        #expect(await dispatcher.isSupported(.previous))
        #expect(!(await dispatcher.isSupported(.next)))
        #expect(await dispatcher.canSeek())
        #expect(client.capabilitiesCount == 3)
        #expect(client.startObservationCount == 0)
        #expect(client.commands.isEmpty)
    }

    @Test
    func unsupportedUnknownAndCapabilityFailureFailClosed() async {
        for capability in [MediaCapabilityState.unsupported, .unknown] {
            let client = CompactCommandProcessClient()
            client.capabilityResult = .success(
                MediaCommandCapabilities(
                    previous: capability,
                    next: capability,
                    seek: capability
                )
            )
            let dispatcher = ShippingMediaCompactCommandDispatcher(processClient: client)

            #expect(!(await dispatcher.isSupported(.previous)))
            #expect(!(await dispatcher.isSupported(.next)))
            #expect(!(await dispatcher.canSeek()))
            #expect(client.startObservationCount == 0)
        }

        let failingClient = CompactCommandProcessClient()
        failingClient.capabilityResult = .failure(CompactCommandTestError.expected)
        let failingDispatcher = ShippingMediaCompactCommandDispatcher(
            processClient: failingClient
        )

        #expect(!(await failingDispatcher.isSupported(.previous)))
        #expect(!(await failingDispatcher.canSeek()))
        #expect(failingClient.capabilitiesCount == 2)
        #expect(failingClient.startObservationCount == 0)
    }

    @Test
    func sendMapsPreviousAndNextAndReturnsTransportResult() async {
        let client = CompactCommandProcessClient()
        let dispatcher = ShippingMediaCompactCommandDispatcher(processClient: client)

        client.sendResult = .sent
        #expect(await dispatcher.send(.previous))
        #expect(await dispatcher.send(.next))
        #expect(client.commands == [.previous, .next])

        client.sendResult = .failed
        #expect(!(await dispatcher.send(.next)))
        #expect(client.commands == [.previous, .next, .next])
        #expect(client.startObservationCount == 0)
    }

    @Test
    func seekValidatesInputSendsExactlyOnceAndNeverStartsObservation() async {
        let client = CompactCommandProcessClient()
        let dispatcher = ShippingMediaCompactCommandDispatcher(processClient: client)

        #expect(!(await dispatcher.seek(to: -.infinity)))
        #expect(!(await dispatcher.seek(to: -1)))
        #expect(!(await dispatcher.seek(to: .nan)))
        #expect(client.commands.isEmpty)

        client.sendResult = .sent
        #expect(await dispatcher.seek(to: 42))
        #expect(client.commands == [.seek(seconds: 42)])
        #expect(client.startObservationCount == 0)

        client.sendResult = .failed
        #expect(!(await dispatcher.seek(to: 84)))
        #expect(client.commands == [.seek(seconds: 42), .seek(seconds: 84)])
    }

    @Test
    func invalidShippingBundleFailsClosedBeforeProcessClientCreation() async {
        var processClientCreationCount = 0
        let dispatcher = ShippingMediaCompactCommandDispatcher(
            bundle: .main,
            fileManager: .default,
            processClientFactory: { paths in
                processClientCreationCount += 1
                return MediaRemoteProcessClient(
                    scriptURL: paths.scriptURL,
                    frameworkURL: paths.frameworkURL
                )
            }
        )

        #expect(!(await dispatcher.isSupported(.previous)))
        #expect(!(await dispatcher.canSeek()))
        #expect(!(await dispatcher.send(.next)))
        #expect(!(await dispatcher.seek(to: 1)))
        #expect(processClientCreationCount == 0)
    }

    @Test
    func stopOwnsInFlightOneShotAndLateCompletionFailsClosed() async {
        let client = CompactCommandProcessClient()
        client.suspendCapabilities = true
        let dispatcher = ShippingMediaCompactCommandDispatcher(processClient: client)

        let supportTask = Task { @MainActor in
            await dispatcher.isSupported(.next)
        }
        await waitForCapabilitiesStart(client)

        #expect(client.capabilitiesCount == 1)
        dispatcher.stop()

        #expect(client.stopCount == 1)
        #expect(!(await supportTask.value))
        #expect(!(await dispatcher.isSupported(.next)))
        #expect(!(await dispatcher.canSeek()))
        #expect(!(await dispatcher.send(.next)))
        #expect(!(await dispatcher.seek(to: 12)))
        #expect(client.capabilitiesCount == 1)
        #expect(client.commands.isEmpty)
        #expect(client.startObservationCount == 0)
    }

    @Test
    func productionDispatcherReusesShippingValidationAndHasNoObservationSurface() throws {
        let dispatcherSource = try sourceText(
            relativePath: "Sources/NotchHubMediaCore/ShippingMediaCompactCommandDispatcher.swift"
        )
        let runtimeSource = try sourceText(
            relativePath: "Sources/NotchHubMediaCore/ShippingMediaRuntime.swift"
        )

        #expect(dispatcherSource.contains("ShippingMediaBundlePaths.resolveValidated("))
        #expect(runtimeSource.contains("ShippingMediaBundlePaths.resolveValidated("))
        #expect(!dispatcherSource.contains("startObservation("))
        #expect(!dispatcherSource.contains("togglePlayPause"))
        #expect(dispatcherSource.contains("public func canSeek() async -> Bool"))
        #expect(dispatcherSource.contains("public func seek(to positionSeconds: Double) async -> Bool"))
        #expect(dispatcherSource.contains(".seek(seconds: positionSeconds)"))
        #expect(!dispatcherSource.contains("Process()"))
        #expect(!dispatcherSource.contains("Timer("))
        #expect(!dispatcherSource.contains("sleep("))
    }

    private func waitForCapabilitiesStart(
        _ client: CompactCommandProcessClient
    ) async {
        for _ in 0..<32 {
            if client.capabilitiesCount > 0 {
                return
            }
            await Task.yield()
        }
    }

    private func sourceText(
        relativePath: String
    ) throws -> String {
        let testFile = URL(fileURLWithPath: #filePath)
        let repositoryRoot =
            testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}

private enum CompactCommandTestError: Error {
    case expected
}

@MainActor
private final class CompactCommandProcessClient: MediaRemoteProcessClientProtocol {
    var onPayload: (@MainActor @Sendable (MediaRemoteWirePayload?) -> Void)?
    var onFailure: (@MainActor @Sendable (MediaRemoteProcessFailure) -> Void)?
    var lastTeardownClean = true

    var capabilityResult: Result<MediaCommandCapabilities, Error> = .success(
        MediaCommandCapabilities(
            previous: .supported,
            next: .supported,
            seek: .supported
        )
    )
    var sendResult: MediaCommandResult = .sent
    var suspendCapabilities = false

    private(set) var startObservationCount = 0
    private(set) var stopCount = 0
    private(set) var capabilitiesCount = 0
    private(set) var commands: [MediaCommand] = []
    private var capabilityContinuation: CheckedContinuation<MediaCommandCapabilities, Error>?

    func startObservation() throws {
        startObservationCount += 1
    }

    func stop() {
        stopCount += 1
        capabilityContinuation?.resume(throwing: CancellationError())
        capabilityContinuation = nil
    }

    func send(_ command: MediaCommand) async -> MediaCommandResult {
        commands.append(command)
        return sendResult
    }

    func capabilities() async throws -> MediaCommandCapabilities {
        capabilitiesCount += 1
        if suspendCapabilities {
            return try await withCheckedThrowingContinuation { continuation in
                capabilityContinuation = continuation
            }
        }
        return try capabilityResult.get()
    }
}
