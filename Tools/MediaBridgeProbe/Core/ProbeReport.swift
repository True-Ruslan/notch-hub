import Foundation

public struct ProbeReport: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let sourceCommit: String
    public let macOSVersion: String
    public let hardwareModel: String
    public let adapterCommit: String
    public let sourceBundleIdentifier: String?
    public let observedSession: Bool
    public let observedArtwork: Bool
    public let observedPlayingState: Bool
    public let observedSessionDisappearance: Bool
    public let sourceSwitchCount: Int
    public let eventCount: Int
    public let commandResults: [String: Bool]
    public let cleanTeardown: Bool
    public let orphanProcessDetected: Bool

    public init(
        schemaVersion: Int,
        sourceCommit: String,
        macOSVersion: String,
        hardwareModel: String,
        adapterCommit: String,
        sourceBundleIdentifier: String?,
        observedSession: Bool,
        observedArtwork: Bool,
        observedPlayingState: Bool,
        observedSessionDisappearance: Bool,
        sourceSwitchCount: Int,
        eventCount: Int,
        commandResults: [String: Bool],
        cleanTeardown: Bool,
        orphanProcessDetected: Bool
    ) {
        self.schemaVersion = schemaVersion
        self.sourceCommit = sourceCommit
        self.macOSVersion = macOSVersion
        self.hardwareModel = hardwareModel
        self.adapterCommit = adapterCommit
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.observedSession = observedSession
        self.observedArtwork = observedArtwork
        self.observedPlayingState = observedPlayingState
        self.observedSessionDisappearance = observedSessionDisappearance
        self.sourceSwitchCount = sourceSwitchCount
        self.eventCount = eventCount
        self.commandResults = commandResults
        self.cleanTeardown = cleanTeardown
        self.orphanProcessDetected = orphanProcessDetected
    }
}
