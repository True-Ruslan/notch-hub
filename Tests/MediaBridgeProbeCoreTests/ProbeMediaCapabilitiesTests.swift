import Foundation
import Testing
@testable import MediaBridgeProbeCore

struct ProbeMediaCapabilitiesTests {
    @Test
    func decodesAuthoritativeTriStateCapabilities() throws {
        let line = Data(
            #"{"next":"supported","previous":"unsupported","seek":"unknown"}"#.utf8
        )

        let capabilities = try ProbeMediaCapabilitiesDecoder.decode(line: line)

        #expect(
            capabilities
                == ProbeMediaCapabilities(
                    next: .supported,
                    previous: .unsupported,
                    seek: .unknown
                )
        )
    }

    @Test
    func rejectsExpandedOrUnknownCapabilitySurface() {
        let invalidLines = [
            #"{"next":"supported","previous":"unsupported","seek":"unknown","volume":"supported"}"#,
            #"{"next":"sometimes","previous":"unsupported","seek":"unknown"}"#,
            #"{"next":"supported","previous":"unsupported"}"#
        ]

        for line in invalidLines {
            #expect(throws: ProbeMediaCapabilitiesDecoderError.invalidPayload) {
                try ProbeMediaCapabilitiesDecoder.decode(line: Data(line.utf8))
            }
        }
    }
}
