import CoreGraphics
import Testing
@testable import NotchHubCore

struct NotchPointerPolicyTests {
    private let layout = NotchLayout(
        hasHardwareNotch: true,
        hardwareNotchWidth: 180,
        compactFrame: CGRect(x: 410, y: 868, width: 180, height: 32),
        peekFrame: CGRect(x: 320, y: 804, width: 360, height: 96),
        expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
    )

    @Test
    func compactPointerInsideActivationRegionTargetsPeek() {
        let result = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: 500, y: 884),
            layout: layout
        )

        #expect(result == .peek)
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
    func compactPointerFourPointsInsideBottomEdgeTargetsPeek() {
        let result = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: 500, y: 872),
            layout: layout
        )

        #expect(result == .peek)
    }

    @Test
    func compactPointerAtExactTopScreenEdgeTargetsPeekWithoutTopInset() {
        let result = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: 500, y: layout.compactFrame.maxY),
            layout: layout
        )

        #expect(result == .peek)
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
    func compactPointerAtExactLeftInsetTargetsPeek() {
        let result = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: layout.compactFrame.minX + 4, y: layout.compactFrame.maxY),
            layout: layout
        )

        #expect(result == .peek)
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
    func compactPointerAtExactRightInsetTargetsPeek() {
        let result = NotchPointerPolicy.presentation(
            current: .compact,
            pointer: CGPoint(x: layout.compactFrame.maxX - 4, y: layout.compactFrame.maxY),
            layout: layout
        )

        #expect(result == .peek)
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

        #expect(result == .peek)
    }

    @Test
    func peekPointerInsideRetentionRegionStaysPeek() {
        let result = NotchPointerPolicy.presentation(
            current: .peek,
            pointer: CGPoint(x: 500, y: 840),
            layout: layout
        )

        #expect(result == .peek)
    }

    @Test
    func peekPointerOutsideRetentionRegionTargetsCompact() {
        let result = NotchPointerPolicy.presentation(
            current: .peek,
            pointer: CGPoint(x: 100, y: 500),
            layout: layout
        )

        #expect(result == .compact)
    }

    @Test
    func expandedPointerInsideExpandedRegionStaysExpanded() {
        let result = NotchPointerPolicy.presentation(
            current: .expanded,
            pointer: CGPoint(x: 300, y: 760),
            layout: layout
        )

        #expect(result == .expanded)
    }

    @Test
    func expandedPointerOutsideExpandedRegionStillStaysExpanded() {
        let result = NotchPointerPolicy.presentation(
            current: .expanded,
            pointer: CGPoint(x: 100, y: 500),
            layout: layout
        )

        #expect(result == .expanded)
    }
}
