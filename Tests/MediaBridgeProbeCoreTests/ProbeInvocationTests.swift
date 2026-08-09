import Testing
@testable import MediaBridgeProbeCore

struct ProbeInvocationTests {
    @Test
    func parsesBoundedObserveInvocation() throws {
        let invocation = try ProbeInvocation.parse(
            arguments: [
                "observe",
                "--seconds",
                "15"
            ]
        )

        #expect(invocation == .observe(seconds: 15))
    }

    @Test
    func rejectsZeroOrUnboundedObserveDuration() {
        for seconds in ["0", "3601", "forever"] {
            #expect(throws: ProbeInvocationError.invalidArguments) {
                try ProbeInvocation.parse(
                    arguments: [
                        "observe",
                        "--seconds",
                        seconds
                    ]
                )
            }
        }
    }

    @Test
    func observeRejectsArbitraryReportPathSurface() {
        #expect(throws: ProbeInvocationError.invalidArguments) {
            try ProbeInvocation.parse(
                arguments: [
                    "observe",
                    "--seconds",
                    "15",
                    "--report",
                    "/tmp/probe.json"
                ]
            )
        }
    }

    @Test
    func parsesOnlyAllowlistedSendCommands() throws {
        #expect(
            try ProbeInvocation.parse(arguments: ["send", "toggle"])
                == .command(.togglePlayPause)
        )
        #expect(
            try ProbeInvocation.parse(arguments: ["send", "next"])
                == .command(.next)
        )
        #expect(
            try ProbeInvocation.parse(arguments: ["send", "previous"])
                == .command(.previous)
        )
    }

    @Test
    func rejectsArbitrarySendCommand() {
        #expect(throws: ProbeInvocationError.invalidArguments) {
            try ProbeInvocation.parse(arguments: ["send", "99"])
        }
        #expect(throws: ProbeInvocationError.invalidArguments) {
            try ProbeInvocation.parse(arguments: ["send", "volume-up"])
        }
    }

    @Test
    func parsesSeekThroughTypedCommandValidation() throws {
        #expect(
            try ProbeInvocation.parse(arguments: ["seek", "42000000"])
                == .command(.seek(microseconds: 42_000_000))
        )
    }

    @Test
    func rejectsInvalidSeekAndExtraArguments() {
        #expect(throws: ProbeInvocationError.invalidArguments) {
            try ProbeInvocation.parse(arguments: ["seek", "0"])
        }
        #expect(throws: ProbeInvocationError.invalidArguments) {
            try ProbeInvocation.parse(arguments: ["self-test", "unexpected"])
        }
    }

    @Test
    func parsesCapabilitiesWithoutAdditionalSurface() throws {
        #expect(try ProbeInvocation.parse(arguments: ["capabilities"]) == .capabilities)
        #expect(throws: ProbeInvocationError.invalidArguments) {
            try ProbeInvocation.parse(arguments: ["capabilities", "next"])
        }
    }

    @Test
    func parsesSelfTestWithoutAdditionalSurface() throws {
        #expect(try ProbeInvocation.parse(arguments: ["self-test"]) == .selfTest)
    }
}
