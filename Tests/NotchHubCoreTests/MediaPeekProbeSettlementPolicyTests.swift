import Foundation
import Testing

struct MediaPeekProbeSettlementPolicyTests {
    @Test
    func boundedPeekProbeStartsOnlyAfterPeekSettlement() throws {
        let sessionSource = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaPeekSession.swift"
        )
        let appSource = try sourceText(
            relativePath: "Sources/NotchHubApp/AppDelegate.swift"
        )

        let hoverSection = try sourceSection(
            sessionSource,
            from: "func handleHoverRequest",
            to: "func handleSettledPeek"
        )
        let settledSection = try sourceSection(
            sessionSource,
            from: "func handleSettledPeek",
            to: "func cancel()"
        )

        #expect(!hoverSection.contains("probe.acquire"))
        #expect(settledSection.contains("probe.acquire"))
        #expect(appSource.contains("mediaPeekSession.handleSettledPeek()"))
        #expect(!appSource.contains("NSEvent.pressedMouseButtons"))
        #expect(!appSource.contains(".leftMouseDown"))
        #expect(!appSource.contains(".leftMouseUp"))
        #expect(!sessionSource.contains("Task.sleep"))
        #expect(!sessionSource.contains("Timer.scheduledTimer"))
    }

    @Test
    func boundedPeekProbeNeverOverwritesAnAlreadyLiveAuthoritativePresentation() throws {
        // M6.7's always-on runtime means a live authoritative presentation
        // can already exist by the time Peek settles. The bounded one-shot
        // probe must not run (and therefore cannot clobber it with a stale
        // .noSession result) when that is the case; it exists only to
        // enrich a genuinely empty presentation. See
        // docs/superpowers/specs/2026-08-22-live-media-timeline-and-compact-design.md.
        let sessionSource = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaPeekSession.swift"
        )
        let settledSection = try sourceSection(
            sessionSource,
            from: "func handleSettledPeek",
            to: "func cancel()"
        )

        #expect(settledSection.contains("presentationModel.presentation == nil"))

        let guardRange = try #require(
            settledSection.range(of: "presentationModel.presentation == nil")
        )
        let acquireRange = try #require(settledSection.range(of: "probe.acquire"))
        #expect(guardRange.lowerBound < acquireRange.lowerBound)
    }

    @Test
    func boundedPeekCancellationUsesNonblockingProcessTeardown() throws {
        let probeSource = try sourceText(
            relativePath: "Sources/NotchHubMediaCore/ShippingMediaPeekProbe.swift"
        )
        let clientSource = try sourceText(
            relativePath: "Sources/NotchHubMediaCore/MediaRemoteProcessClient.swift"
        )
        let protocolSource = try sourceText(
            relativePath: "Sources/NotchHubMediaCore/MediaRemoteProcessClientProtocol.swift"
        )

        #expect(probeSource.contains("activeTransport.stopNonBlocking()"))
        #expect(protocolSource.contains("func stopNonBlocking()"))

        let nonblockingStop = try sourceSection(
            clientSource,
            from: "func stopNonBlocking()",
            to: "func send("
        )
        #expect(!nonblockingStop.contains("waitUntilExit"))
        #expect(clientSource.contains("MediaRemoteDeferredTermination"))
    }

    private func sourceSection(
        _ source: String,
        from startMarker: String,
        to endMarker: String
    ) throws -> String {
        let start = try #require(source.range(of: startMarker))
        let end = try #require(
            source.range(of: endMarker, range: start.upperBound..<source.endIndex)
        )
        return String(source[start.lowerBound..<end.lowerBound])
    }

    private func sourceText(relativePath: String) throws -> String {
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
