import Testing
@testable import NotchHubMediaCore

@MainActor
struct MediaGestureVerticalVisualTrackingTests {
    @Test
    func compactDownwardVerticalCaptureEmitsRawCumulativeVisualOffset() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )

        let first = coordinator.handle(
            sample(.changed, x: 2, y: 30),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let second = coordinator.handle(
            sample(.changed, x: -1, y: 20),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )

        #expect(panelVisualOffsets(first) == [30])
        #expect(panelVisualOffsets(second) == [50])
        #expect(armHapticCount(first + second) == 0)
        #expect(commits(first + second).isEmpty)
    }

    @Test
    func expandedUpwardVerticalCaptureEmitsNegativeRawCumulativeVisualOffset() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )

        let first = coordinator.handle(
            sample(.changed, x: 1, y: -40),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let second = coordinator.handle(
            sample(.changed, y: -25),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )

        #expect(panelVisualOffsets(first) == [-40])
        #expect(panelVisualOffsets(second) == [-65])
        #expect(armHapticCount(first + second) == 0)
    }

    @Test
    func ambiguousAxisEmitsNoPanelVisualOffsetUntilVerticalDominanceExists() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )

        let ambiguous = coordinator.handle(
            sample(.changed, x: 20, y: 20),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let captured = coordinator.handle(
            sample(.changed, y: 20),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )

        #expect(panelVisualOffsets(ambiguous).isEmpty)
        #expect(panelVisualOffsets(captured) == [40])
    }

    @Test
    func momentumNeverAdvancesVerticalVisualTracking() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let captured = coordinator.handle(
            sample(.changed, y: 30),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let momentum = coordinator.handle(
            sample(.changed, y: 200, momentum: true),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let physicalAgain = coordinator.handle(
            sample(.changed, y: 10),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )

        #expect(panelVisualOffsets(captured) == [30])
        #expect(panelVisualOffsets(momentum).isEmpty)
        #expect(panelVisualOffsets(physicalAgain) == [40])
    }

    @Test
    func horizontalCaptureNeverEmitsPanelVisualOffset() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )

        let horizontal = coordinator.handle(
            sample(.changed, x: -40, y: 2),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let laterVerticalMovement = coordinator.handle(
            sample(.changed, x: -10, y: 100),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )

        #expect(panelVisualOffsets(horizontal + laterVerticalMovement).isEmpty)
        #expect(horizontal.contains(where: isHorizontalVisualOffset))
        #expect(laterVerticalMovement.contains(where: isHorizontalVisualOffset))
    }

    @Test
    func seekOwnershipSuppressesVerticalVisualTrackingAndSemanticPanelIntent() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let captured = coordinator.handle(
            sample(.changed, y: 40),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let seekOwned = coordinator.handle(
            sample(.changed, y: 40),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: true
        )
        let ended = coordinator.handle(
            sample(.ended),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: true
        )

        #expect(panelVisualOffsets(captured) == [40])
        #expect(panelVisualOffsets(seekOwned + ended).isEmpty)
        #expect(!seekOwned.contains(.requestExpansion))
        #expect(!ended.contains(.requestExpansion))
    }

    @Test
    func reversalKeepsEmittingRawCumulativeOffsetSoAppCanDriveBackTowardOrigin() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let forward = coordinator.handle(
            sample(.changed, y: 50),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let reverse = coordinator.handle(
            sample(.changed, y: -35),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )

        #expect(panelVisualOffsets(forward) == [50])
        #expect(panelVisualOffsets(reverse) == [15])
    }

    @Test
    func verticalVisualTrackingDoesNotChangeFrozenEndOnlyCommitThreshold() {
        let compact = MediaGestureCoordinator()
        _ = compact.handle(
            sample(.began),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let below = compact.handle(
            sample(.changed, y: 69),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let belowEnd = compact.handle(
            sample(.ended),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )

        let expanded = MediaGestureCoordinator()
        _ = expanded.handle(
            sample(.began),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let atThreshold = expanded.handle(
            sample(.changed, y: -70),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let thresholdEnd = expanded.handle(
            sample(.ended),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )

        #expect(panelVisualOffsets(below) == [69])
        #expect(!belowEnd.contains(.requestExpansion))
        #expect(panelVisualOffsets(atThreshold) == [-70])
        #expect(thresholdEnd.contains(.requestCollapse))
        #expect(armHapticCount(below + belowEnd + atThreshold + thresholdEnd) == 0)
    }

    private func sample(
        _ phase: MediaGesturePhase,
        x: Double = 0,
        y: Double = 0,
        width: Double = 300,
        momentum: Bool = false
    ) -> MediaGestureSample {
        MediaGestureSample(
            phase: phase,
            deltaX: x,
            deltaY: y,
            interactiveWidth: width,
            isMomentum: momentum
        )
    }

    private func panelVisualOffsets(_ effects: [MediaGestureEffect]) -> [Double] {
        effects.compactMap { effect in
            if case .panelVisualOffset(let offset) = effect {
                return offset
            }
            return nil
        }
    }

    private func armHapticCount(_ effects: [MediaGestureEffect]) -> Int {
        effects.count(where: { $0 == .requestArmHaptic })
    }

    private func commits(_ effects: [MediaGestureEffect]) -> [MediaGestureDirection] {
        effects.compactMap { effect in
            if case .commit(let direction) = effect {
                return direction
            }
            return nil
        }
    }

    private func isHorizontalVisualOffset(_ effect: MediaGestureEffect) -> Bool {
        if case .visualOffset = effect {
            return true
        }
        return false
    }
}
