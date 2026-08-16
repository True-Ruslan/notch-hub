import Dispatch
import Foundation

@MainActor
public protocol MediaPeekProbing: AnyObject {
    func acquire(
        completion: @escaping @MainActor @Sendable (ShippingMediaPeekProbe.Result) -> Void
    )
    func cancel()
}

@MainActor
public final class ShippingMediaPeekProbe: MediaPeekProbing {
    public enum Result: Sendable, Equatable {
        case presentation(ShippingMediaPresentation)
        case noSession
        case failed
    }

    typealias Cancellation = @MainActor () -> Void
    typealias TimeoutScheduler = @MainActor (
        TimeInterval,
        @escaping @MainActor () -> Void
    ) -> Cancellation

    private let makeTransport: @MainActor () -> (any SystemMediaTransport)?
    private let scheduleTimeout: TimeoutScheduler
    private let timeoutSeconds: TimeInterval

    private var generation: UInt64 = 0
    private var activeTransport: (any SystemMediaTransport)?
    private var timeoutCancellation: Cancellation?
    private var completion: (@MainActor @Sendable (Result) -> Void)?

    public convenience init() {
        let bundle = Bundle.main
        let fileManager = FileManager.default
        self.init(
            makeTransport: {
                guard
                    let paths = try? ShippingMediaBundlePaths.resolveValidated(
                        bundle: bundle,
                        fileManager: fileManager
                    )
                else {
                    return nil
                }

                return MediaRemoteSystemTransport(
                    scriptURL: paths.scriptURL,
                    frameworkURL: paths.frameworkURL
                )
            },
            scheduleTimeout: { delaySeconds, action in
                let workItem = DispatchWorkItem {
                    MainActor.assumeIsolated {
                        action()
                    }
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + delaySeconds,
                    execute: workItem
                )
                return { workItem.cancel() }
            },
            timeoutSeconds: 1.0
        )
    }

    init(
        makeTransport: @escaping @MainActor () -> (any SystemMediaTransport)?,
        scheduleTimeout: @escaping TimeoutScheduler,
        timeoutSeconds: TimeInterval
    ) {
        self.makeTransport = makeTransport
        self.scheduleTimeout = scheduleTimeout
        self.timeoutSeconds = timeoutSeconds
    }

    public func acquire(
        completion: @escaping @MainActor @Sendable (Result) -> Void
    ) {
        cancel()
        generation &+= 1
        let acquisitionGeneration = generation

        guard let transport = makeTransport() else {
            completion(.failed)
            return
        }

        activeTransport = transport
        self.completion = completion

        transport.eventHandler = { [weak self] event in
            self?.receive(event, generation: acquisitionGeneration)
        }
        timeoutCancellation = scheduleTimeout(timeoutSeconds) { [weak self] in
            self?.timeout(generation: acquisitionGeneration)
        }
        transport.start()
    }

    public func cancel() {
        generation &+= 1
        clearActiveAcquisition()
    }

    private func receive(
        _ event: SystemMediaTransportEvent,
        generation acquisitionGeneration: UInt64
    ) {
        guard
            acquisitionGeneration == generation,
            activeTransport != nil
        else {
            return
        }

        switch event {
        case .ready:
            break

        case .session(let snapshot):
            guard let result = Self.result(for: snapshot) else {
                return
            }
            finish(result, generation: acquisitionGeneration)

        case .noSession:
            finish(.noSession, generation: acquisitionGeneration)

        case .failed, .stopped:
            finish(.failed, generation: acquisitionGeneration)
        }
    }

    private func timeout(generation acquisitionGeneration: UInt64) {
        guard acquisitionGeneration == generation else {
            return
        }

        finish(.failed, generation: acquisitionGeneration)
    }

    private func finish(
        _ result: Result,
        generation acquisitionGeneration: UInt64
    ) {
        guard
            acquisitionGeneration == generation,
            let completion
        else {
            return
        }

        clearActiveAcquisition()
        completion(result)
    }

    private func clearActiveAcquisition() {
        timeoutCancellation?()
        timeoutCancellation = nil
        completion = nil

        guard let activeTransport else {
            return
        }

        self.activeTransport = nil
        activeTransport.eventHandler = nil
        activeTransport.stopNonBlocking()
    }

    private static func result(
        for snapshot: MediaSessionSnapshot
    ) -> Result? {
        let state: MediaSubsystemState =
            snapshot.playbackState == .playing ? .playing : .paused
        return ShippingMediaPresentationProjection.make(
            state: state,
            snapshot: snapshot
        ).map(Result.presentation)
    }
}
