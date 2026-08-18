import CoreGraphics
import Testing
@testable import NotchHubCore

struct NotchPerformanceInvariantTests {
    @Test
    func pointerPolicyHandlesOneHundredThousandCompactPeekTransitionsWithoutRetainedHistory() {
        let layout = NotchLayout(
            hasHardwareNotch: true,
            hardwareNotchWidth: 180,
            compactFrame: CGRect(x: 410, y: 868, width: 180, height: 32),
            peekFrame: CGRect(x: 320, y: 804, width: 360, height: 96),
            expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
        )
        let insideCompact = CGPoint(x: 500, y: 884)
        let outsidePeek = CGPoint(x: 100, y: 500)

        var presentation: NotchPresentation = .compact
        var peekCount = 0
        var collapseCount = 0

        for index in 0..<100_000 {
            let pointer = index.isMultiple(of: 2) ? insideCompact : outsidePeek
            let next = NotchPointerPolicy.presentation(
                current: presentation,
                pointer: pointer,
                layout: layout
            )

            if presentation == .compact, next == .peek {
                peekCount += 1
            } else if presentation == .peek, next == .compact {
                collapseCount += 1
            }

            presentation = next
        }

        #expect(presentation == .compact)
        #expect(peekCount == 50_000)
        #expect(collapseCount == 50_000)
    }
}
