import Testing
@testable import NotchHubMediaCore

struct ProductionMediaTransportCandidateInvocationTests {
    @Test
    func parsesOnlyClosedCandidateCommands() throws {
        #expect(
            try ProductionMediaTransportCandidateInvocation.parse(arguments: ["capabilities"])
                == .capabilities
        )
        #expect(
            try ProductionMediaTransportCandidateInvocation.parse(
                arguments: ["observe", "--seconds", "60"]
            ) == .observe(seconds: 60)
        )
        #expect(
            try ProductionMediaTransportCandidateInvocation.parse(arguments: ["send", "toggle"])
                == .send(.toggle)
        )
        #expect(
            try ProductionMediaTransportCandidateInvocation.parse(arguments: ["send", "previous"])
                == .send(.previous)
        )
        #expect(
            try ProductionMediaTransportCandidateInvocation.parse(arguments: ["send", "next"])
                == .send(.next)
        )
        #expect(
            try ProductionMediaTransportCandidateInvocation.parse(arguments: ["seek", "42"])
                == .send(.seek(seconds: 42))
        )
    }

    @Test
    func rejectsArbitraryCommandsPathsAndUnboundedDurations() {
        let rejected = [
            ["observe", "--seconds", "0"],
            ["observe", "--seconds", "1201"],
            ["observe", "--adapter", "/tmp/evil.pl"],
            ["send", "4"],
            ["send", "volume"],
            ["seek", "-1"],
            ["seek", "nan"],
            ["/tmp/evil"],
            ["capabilities", "extra"],
        ]

        for arguments in rejected {
            #expect(throws: ProductionMediaTransportCandidateError.invalidArguments) {
                try ProductionMediaTransportCandidateInvocation.parse(arguments: arguments)
            }
        }
    }
}
