import Foundation
import Testing
@testable import MediaBridgeProbeCore

struct ProbeMediaCommandTests {
    private let scriptURL = URL(fileURLWithPath: "/bundle/mediaremote-adapter.pl")
    private let frameworkURL = URL(fileURLWithPath: "/bundle/MediaRemoteAdapter.framework")
    private let testClientURL = URL(fileURLWithPath: "/bundle/MediaRemoteAdapterTestClient")

    @Test
    func togglePlayPauseMapsToCommandTwo() throws {
        let arguments = try ProbeMediaCommand.togglePlayPause.adapterArguments(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            testClientURL: testClientURL
        )

        #expect(arguments.suffix(2) == ["send", "2"])
    }

    @Test
    func nextMapsToCommandFour() throws {
        let arguments = try ProbeMediaCommand.next.adapterArguments(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            testClientURL: testClientURL
        )

        #expect(arguments.suffix(2) == ["send", "4"])
    }

    @Test
    func previousMapsToCommandFive() throws {
        let arguments = try ProbeMediaCommand.previous.adapterArguments(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            testClientURL: testClientURL
        )

        #expect(arguments.suffix(2) == ["send", "5"])
    }

    @Test
    func seekMapsToPositiveMicroseconds() throws {
        let arguments = try ProbeMediaCommand.seek(microseconds: 42_000_000).adapterArguments(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            testClientURL: testClientURL
        )

        #expect(arguments.suffix(2) == ["seek", "42000000"])
    }

    @Test
    func seekRejectsZero() {
        #expect(throws: ProbeMediaCommandError.seekOutOfRange) {
            try ProbeMediaCommand.seek(microseconds: 0).validated()
        }
    }

    @Test
    func seekRejectsValuesBeyondThirtyDays() {
        let invalid = ProbePayloadDecoder.maximumDurationMicros + 1

        #expect(throws: ProbeMediaCommandError.seekOutOfRange) {
            try ProbeMediaCommand.seek(microseconds: invalid).validated()
        }
    }

    @Test
    func adapterArgumentsAlwaysBeginWithFixedProbeAssets() throws {
        let arguments = try ProbeMediaCommand.next.adapterArguments(
            scriptURL: scriptURL,
            frameworkURL: frameworkURL,
            testClientURL: testClientURL
        )

        #expect(
            Array(arguments.prefix(3)) == [
                scriptURL.path,
                frameworkURL.path,
                testClientURL.path,
            ]
        )
    }
}
