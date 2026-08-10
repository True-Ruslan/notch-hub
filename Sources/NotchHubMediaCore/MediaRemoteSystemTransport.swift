import Foundation

@MainActor
final class MediaRemoteSystemTransport: SystemMediaTransport {
    var eventHandler: (@MainActor @Sendable (SystemMediaTransportEvent) -> Void)?

    private let processClient: any MediaRemoteProcessClientProtocol

    private var isStarted = false
    private var handlerGeneration: UInt64 = 0
    private var mediaGeneration: UInt64 = 0
    private var revision: UInt64 = 0
    private var activeFingerprint: MediaRemoteMediaFingerprint?
    private var activePayload: MediaRemoteWirePayload?
    private var activeCapabilities = MediaCommandCapabilities(
        previous: .unknown,
        next: .unknown,
        seek: .unknown
    )
    private var publishedNoSession = false

    init(processClient: any MediaRemoteProcessClientProtocol) {
        self.processClient = processClient
    }

    convenience init(scriptURL: URL, frameworkURL: URL) {
        self.init(processClient: MediaRemoteProcessClient(scriptURL: scriptURL, frameworkURL: frameworkURL))
    }

    func start() {
        guard !isStarted else {
            return
        }

        isStarted = true
        handlerGeneration &+= 1
        let generation = handlerGeneration
        activeFingerprint = nil
        activePayload = nil
        activeCapabilities = Self.unknownCapabilities
        publishedNoSession = false

        processClient.onPayload = { [weak self] payload in
            guard let self, self.acceptsCallback(generation: generation) else {
                return
            }
            self.receive(payload)
        }
        processClient.onFailure = { [weak self] failure in
            guard let self, self.acceptsCallback(generation: generation) else {
                return
            }
            self.receive(failure)
        }

        do {
            try processClient.startObservation()
            eventHandler?(.ready)
        } catch {
            processClient.onPayload = nil
            processClient.onFailure = nil
            isStarted = false
            handlerGeneration &+= 1
            eventHandler?(.failed(.transport))
        }
    }

    func stop() {
        guard isStarted else {
            return
        }

        isStarted = false
        handlerGeneration &+= 1
        processClient.onPayload = nil
        processClient.onFailure = nil
        processClient.stop()
        activeFingerprint = nil
        activePayload = nil
        activeCapabilities = Self.unknownCapabilities
        publishedNoSession = false
        eventHandler?(.stopped)
    }

    func send(_ command: MediaCommand) async -> MediaCommandResult {
        guard isStarted else {
            return .failed
        }
        return await processClient.send(command)
    }

    private func receive(_ payload: MediaRemoteWirePayload?) {
        guard let payload else {
            publishNoSessionIfNeeded()
            return
        }

        publishedNoSession = false
        let fingerprint = MediaRemoteMediaFingerprint(payload: payload)
        let isNewSession = activeFingerprint != fingerprint

        if isNewSession {
            mediaGeneration &+= 1
            revision = 1
            activeFingerprint = fingerprint
            activeCapabilities = Self.unknownCapabilities
        } else {
            revision &+= 1
        }

        activePayload = payload
        publishSnapshot(payload: payload, capabilities: activeCapabilities)

        if isNewSession {
            requestCapabilities(
                fingerprint: fingerprint,
                mediaGeneration: mediaGeneration,
                handlerGeneration: handlerGeneration
            )
        }
    }

    private func receive(_ failure: MediaRemoteProcessFailure) {
        switch failure {
        case .transport:
            eventHandler?(.failed(.transport))
        case .protocolViolation:
            eventHandler?(.failed(.protocolViolation))
        }
    }

    private func publishNoSessionIfNeeded() {
        guard !publishedNoSession || activeFingerprint != nil else {
            return
        }

        mediaGeneration &+= 1
        revision = 1
        activeFingerprint = nil
        activePayload = nil
        activeCapabilities = Self.unknownCapabilities
        publishedNoSession = true
        eventHandler?(.noSession(MediaSequence(generation: mediaGeneration, revision: revision)))
    }

    private func requestCapabilities(
        fingerprint: MediaRemoteMediaFingerprint,
        mediaGeneration expectedMediaGeneration: UInt64,
        handlerGeneration expectedHandlerGeneration: UInt64
    ) {
        Task { [weak self] in
            guard let self else {
                return
            }

            let capabilities: MediaCommandCapabilities
            do {
                capabilities = try await self.processClient.capabilities()
            } catch {
                return
            }

            guard
                self.isStarted,
                self.handlerGeneration == expectedHandlerGeneration,
                self.mediaGeneration == expectedMediaGeneration,
                self.activeFingerprint == fingerprint,
                let payload = self.activePayload
            else {
                return
            }

            self.activeCapabilities = capabilities
            self.revision &+= 1
            self.publishSnapshot(payload: payload, capabilities: capabilities)
        }
    }

    private func publishSnapshot(
        payload: MediaRemoteWirePayload,
        capabilities: MediaCommandCapabilities
    ) {
        let snapshot = MediaSessionSnapshot(
            sequence: MediaSequence(generation: mediaGeneration, revision: revision),
            source: MediaSourceIdentity(
                bundleIdentifier: payload.bundleIdentifier,
                displayName: nil
            ),
            title: payload.title,
            artist: payload.artist,
            album: payload.album,
            artworkData: payload.artworkData,
            playbackState: payload.playing ? .playing : .paused,
            durationSeconds: payload.durationSeconds,
            positionSeconds: payload.positionSeconds,
            referenceDate: payload.referenceDate,
            playbackRate: payload.playbackRate,
            capabilities: capabilities
        )
        eventHandler?(.session(snapshot))
    }

    private func acceptsCallback(generation: UInt64) -> Bool {
        isStarted && generation == handlerGeneration
    }

    private static let unknownCapabilities = MediaCommandCapabilities(
        previous: .unknown,
        next: .unknown,
        seek: .unknown
    )
}

private struct MediaRemoteMediaFingerprint: Equatable, Sendable {
    let bundleIdentifier: String
    let contentIdentifier: String?
    let uniqueIdentifier: String?
    let title: String?
    let artist: String?
    let album: String?
    let durationSeconds: Double?

    init(payload: MediaRemoteWirePayload) {
        bundleIdentifier = payload.bundleIdentifier
        contentIdentifier = payload.contentIdentifier
        uniqueIdentifier = payload.uniqueIdentifier
        title = payload.title
        artist = payload.artist
        album = payload.album
        durationSeconds = payload.durationSeconds
    }
}
