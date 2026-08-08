import CoreGraphics
import Testing
@testable import NotchHubCore

struct NotchPointerPolicyTests {
    private let layout = NotchLayout(
        hasHardwareNotch: true,
        hardwareNotchWidth: 180,
        compactFrame: CGRect(x: 410, y: 868, width: 180, height: 32),
        expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
    )

    @Test
    func compactPointerInsideActivationRegionExpands() {
        let result = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: 500, y: 884),
            layout: layout
        )

        #expect(result == .expanded)
    }

    @Test
    func compactPointerJustInsidePhysicalEdgeDoesNotActivate() {
        let result = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: 500, y: 870),
            layout: layout
        )

        #expect(result == .compact)
    }

    @Test
    func compactPointerFourPointsInsideActivates() {
        let result = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: 500, y: 872),
            layout: layout
        )

        #expect(result == .expanded)
    }

    @Test
    func expandedPointerInsideExpandedRetentionRegionStaysExpanded() {
        let result = NotchPointerPolicy.presentation(
            current: .expanded,
            pointer: CGPoint(x: 300, y: 760),
            layout: layout
        )

        #expect(result == .expanded)
    }

    @Test
    func expandedPointerOutsideRetentionRegionCollapses() {
        let result = NotchPointerPolicy.presentation(
            current: .expanded,
            pointer: CGPoint(x: 100, y: 500),
            layout: layout
        )

        #expect(result == .compact)
    }
}
