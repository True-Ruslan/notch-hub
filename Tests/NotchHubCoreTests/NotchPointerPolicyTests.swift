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
    func compactPointerJustInsidePhysicalBottomEdgeDoesNotActivate() {
        let result = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: 500, y: 870),
            layout: layout
        )

        #expect(result == .compact)
    }

    @Test
    func compactPointerFourPointsInsideBottomEdgeActivates() {
        let result = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: 500, y: 872),
            layout: layout
        )

        #expect(result == .expanded)
    }

    @Test
    func compactPointerAtExactTopScreenEdgeActivatesWithoutTopInset() {
        let result = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: 500, y: layout.compactFrame.maxY),
            layout: layout
        )

        #expect(result == .expanded)
    }

    @Test
    func compactPointerJustInsideLeftEdgeStillDoesNotActivate() {
        let result = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: layout.compactFrame.minX + 2, y: layout.compactFrame.maxY),
            layout: layout
        )

        #expect(result == .compact)
    }

    @Test
    func compactPointerAtExactLeftInsetActivates() {
        let result = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: layout.compactFrame.minX + 4, y: layout.compactFrame.maxY),
            layout: layout
        )

        #expect(result == .expanded)
    }

    @Test
    func compactPointerJustInsideRightEdgeStillDoesNotActivate() {
        let result = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: layout.compactFrame.maxX - 2, y: layout.compactFrame.maxY),
            layout: layout
        )

        #expect(result == .compact)
    }

    @Test
    func compactPointerAtExactRightInsetActivates() {
        let result = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: layout.compactFrame.maxX - 4, y: layout.compactFrame.maxY),
            layout: layout
        )

        #expect(result == .expanded)
    }

    @Test
    func mediaCompactExtensionWingsDoNotBroadenHoverActivationRegion() {
        let extended = layout.withCompactHorizontalExtension(36)
        let y = extended.compactFrame.maxY - 8

        let leftWing = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: extended.compactFrame.minX + 8, y: y),
            layout: extended
        )
        let rightWing = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: extended.compactFrame.maxX - 8, y: y),
            layout: extended
        )

        #expect(leftWing == .compact)
        #expect(rightWing == .compact)
    }

    @Test
    func mediaCompactExtensionKeepsOriginalHardwareHoverRegionActive() {
        let extended = layout.withCompactHorizontalExtension(36)
        let result = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: layout.compactFrame.minX + 4, y: layout.compactFrame.maxY),
            layout: extended
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
