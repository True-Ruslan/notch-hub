import Testing
@testable import NotchHubMediaCore

@MainActor
struct MediaGestureCoordinatorTests {
    @Test
    func horizontalThresholdClampsToMinimumProportionalValueAndMaximum() {
        let cases: [(width: Double, before: Double, crossing: Double)] = [
            (100, -69, -1),
            (300, -83, -1),
            (1_000, -119, -1),
        ]

        for testCase in cases {
            let coordinator = MediaGestureCoordinator()
            _ = coordinator.handle(
                sample(.began, width: testCase.width),
                surface: .expanded,
                previous: .supported,
                next: .supported,
                seekActive: false
            )

            let before = coordinator.handle(
                sample(.changed, x: testCase.before, width: testCase.width),
                surface: .expanded,
                previous: .supported,
                next: .supported,
                seekActive: false
            )
            #expect(armHapticCount(before) == 0)

            let crossing = coordinator.handle(
                sample(.changed, x: testCase.crossing, width: testCase.width),
                surface: .expanded,
                previous: .supported,
                next: .supported,
                seekActive: false
            )
            #expect(armHapticCount(crossing) == 1)
        }
    }

    @Test
    func shortOrRevertedHorizontalGestureHasNoCommandOrHaptic() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )

        let first = coordinator.handle(
            sample(.changed, x: -50, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let reverted = coordinator.handle(
            sample(.changed, x: 35, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let ended = coordinator.handle(
            sample(.ended, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )

        #expect(armHapticCount(first + reverted + ended) == 0)
        #expect(commits(first + reverted + ended).isEmpty)
    }

    @Test
    func expandedLeftSwipeArmsOnceAndCommitsNextOnlyOnPhysicalEnd() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )

        let changed = coordinator.handle(
            sample(.changed, x: -90, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let stillChanged = coordinator.handle(
            sample(.changed, x: -20, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let ended = coordinator.handle(
            sample(.ended, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let duplicateEnd = coordinator.handle(
            sample(.ended, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )

        #expect(armHapticCount(changed) == 1)
        #expect(armHapticCount(stillChanged) == 0)
        #expect(commits(changed + stillChanged).isEmpty)
        #expect(commits(ended) == [.next])
        #expect(commits(duplicateEnd).isEmpty)
    }

    @Test
    func expandedRightSwipeCommitsPreviousWithSameSemantics() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let changed = coordinator.handle(
            sample(.changed, x: 90, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let ended = coordinator.handle(
            sample(.ended, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )

        #expect(armHapticCount(changed) == 1)
        #expect(commits(changed).isEmpty)
        #expect(commits(ended) == [.previous])
    }

    @Test
    func armedGestureUsesTwentyPointDisarmHysteresisAndMayRearmOncePerTransition() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )

        let arm = coordinator.handle(
            sample(.changed, x: -90, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let insideHysteresis = coordinator.handle(
            sample(.changed, x: 15, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let disarm = coordinator.handle(
            sample(.changed, x: 20, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let rearm = coordinator.handle(
            sample(.changed, x: -35, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let ended = coordinator.handle(
            sample(.ended, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )

        #expect(armHapticCount(arm) == 1)
        #expect(armHapticCount(insideHysteresis) == 0)
        #expect(armHapticCount(disarm) == 0)
        #expect(armHapticCount(rearm) == 1)
        #expect(commits(ended) == [.next])
    }

    @Test
    func cancelledGestureNeverCommits() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let changed = coordinator.handle(
            sample(.changed, x: -100, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let cancelled = coordinator.handle(
            sample(.cancelled, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )

        #expect(armHapticCount(changed) == 1)
        #expect(commits(cancelled).isEmpty)
        #expect(cancelled.contains(.resetVisualOffset))
    }

    @Test
    func momentumCannotCaptureArmOrCommit() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let momentum = coordinator.handle(
            sample(.changed, x: -200, width: 300, momentum: true),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let ended = coordinator.handle(
            sample(.ended, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )

        #expect(momentum.isEmpty)
        #expect(armHapticCount(ended) == 0)
        #expect(commits(ended).isEmpty)
    }

    @Test
    func ambiguousDiagonalGestureDoesNotSwitchTracks() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let changed = coordinator.handle(
            sample(.changed, x: -100, y: 95, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let ended = coordinator.handle(
            sample(.ended, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )

        #expect(armHapticCount(changed) == 0)
        #expect(commits(ended).isEmpty)
        #expect(!ended.contains(.requestExpansion))
        #expect(!ended.contains(.requestCollapse))
    }

    @Test
    func horizontalCapturePreventsVerticalPanelIntentInSameGesture() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let captured = coordinator.handle(
            sample(.changed, x: -40, y: 2, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let request = try? #require(compactRequests(captured).first)
        if let request {
            _ = coordinator.resolveCompactCapability(
                gestureID: request.id,
                direction: request.direction,
                supported: true
            )
        }

        _ = coordinator.handle(
            sample(.changed, x: -60, y: 120, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let ended = coordinator.handle(
            sample(.ended, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )

        #expect(!ended.contains(.requestExpansion))
        #expect(!ended.contains(.requestCollapse))
        #expect(commits(ended) == [.next])
    }

    @Test
    func compactHorizontalGestureRequestsFreshCapabilityAndCannotArmBeforeResolution() throws {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let changed = coordinator.handle(
            sample(.changed, x: -90, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )

        let request = try #require(compactRequests(changed).first)
        #expect(request.direction == .next)
        #expect(armHapticCount(changed) == 0)
        #expect(commits(changed).isEmpty)

        let resolved = coordinator.resolveCompactCapability(
            gestureID: request.id,
            direction: request.direction,
            supported: true
        )
        #expect(armHapticCount(resolved) == 1)

        let ended = coordinator.handle(
            sample(.ended, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        #expect(commits(ended) == [.next])
    }

    @Test
    func unsupportedLateAndStaleCompactCapabilityCannotArmOrCommit() throws {
        let coordinator = MediaGestureCoordinator()

        _ = coordinator.handle(
            sample(.began, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let firstChanged = coordinator.handle(
            sample(.changed, x: -90, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let first = try #require(compactRequests(firstChanged).first)
        let unsupported = coordinator.resolveCompactCapability(
            gestureID: first.id,
            direction: first.direction,
            supported: false
        )
        #expect(armHapticCount(unsupported) == 0)
        let firstEnd = coordinator.handle(
            sample(.ended, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        #expect(commits(firstEnd).isEmpty)
        #expect(
            coordinator.resolveCompactCapability(
                gestureID: first.id,
                direction: first.direction,
                supported: true
            ).isEmpty
        )

        _ = coordinator.handle(
            sample(.began, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let secondChanged = coordinator.handle(
            sample(.changed, x: 90, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let second = try #require(compactRequests(secondChanged).first)
        #expect(second.id != first.id)
        #expect(
            coordinator.resolveCompactCapability(
                gestureID: first.id,
                direction: first.direction,
                supported: true
            ).isEmpty
        )
        let secondResolved = coordinator.resolveCompactCapability(
            gestureID: second.id,
            direction: second.direction,
            supported: true
        )
        #expect(armHapticCount(secondResolved) == 1)
        let secondEnd = coordinator.handle(
            sample(.ended, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        #expect(commits(secondEnd) == [.previous])
    }

    @Test
    func expandedUnsupportedCapabilityCannotArmOrHaptic() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .unavailable,
            seekActive: false
        )
        let changed = coordinator.handle(
            sample(.changed, x: -100, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .unavailable,
            seekActive: false
        )
        let ended = coordinator.handle(
            sample(.ended, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .unavailable,
            seekActive: false
        )

        #expect(armHapticCount(changed) == 0)
        #expect(commits(ended).isEmpty)
    }

    @Test
    func compactDownAndExpandedUpEmitOnlyMatchingPanelIntentOnPhysicalEnd() {
        let compact = MediaGestureCoordinator()
        _ = compact.handle(
            sample(.began, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let compactChanged = compact.handle(
            sample(.changed, y: 80, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let compactEnd = compact.handle(
            sample(.ended, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        #expect(!compactChanged.contains(.requestExpansion))
        #expect(compactEnd.contains(.requestExpansion))
        #expect(commits(compactEnd).isEmpty)

        let expanded = MediaGestureCoordinator()
        _ = expanded.handle(
            sample(.began, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let expandedChanged = expanded.handle(
            sample(.changed, y: -80, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        let expandedEnd = expanded.handle(
            sample(.ended, width: 300),
            surface: .expanded,
            previous: .supported,
            next: .supported,
            seekActive: false
        )
        #expect(!expandedChanged.contains(.requestCollapse))
        #expect(expandedEnd.contains(.requestCollapse))
        #expect(commits(expandedEnd).isEmpty)
    }

    @Test
    func seekActivePreventsGestureCaptureAndInvalidateMakesStaleCapabilityHarmless() throws {
        let coordinator = MediaGestureCoordinator()
        let ignoredBegin = coordinator.handle(
            sample(.began, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: true
        )
        let ignoredChanged = coordinator.handle(
            sample(.changed, x: -120, y: 100, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: true
        )
        let ignoredEnd = coordinator.handle(
            sample(.ended, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: true
        )
        #expect(ignoredBegin.isEmpty)
        #expect(ignoredChanged.isEmpty)
        #expect(ignoredEnd.isEmpty)

        _ = coordinator.handle(
            sample(.began, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let changed = coordinator.handle(
            sample(.changed, x: -90, width: 300),
            surface: .compact,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let request = try #require(compactRequests(changed).first)
        _ = coordinator.invalidate()

        #expect(
            coordinator.resolveCompactCapability(
                gestureID: request.id,
                direction: request.direction,
                supported: true
            ).isEmpty
        )
    }

    private func sample(
        _ phase: MediaGesturePhase,
        x: Double = 0,
        y: Double = 0,
        width: Double,
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

    private func armHapticCount(_ effects: [MediaGestureEffect]) -> Int {
        effects.filter { $0 == .requestArmHaptic }.count
    }

    private func commits(_ effects: [MediaGestureEffect]) -> [MediaGestureDirection] {
        effects.compactMap { effect in
            guard case .commit(let direction) = effect else {
                return nil
            }
            return direction
        }
    }

    private func compactRequests(
        _ effects: [MediaGestureEffect]
    ) -> [(id: UInt64, direction: MediaGestureDirection)] {
        effects.compactMap { effect in
            guard case .requestCompactCapability(let gestureID, let direction) = effect else {
                return nil
            }
            return (gestureID, direction)
        }
    }
}
