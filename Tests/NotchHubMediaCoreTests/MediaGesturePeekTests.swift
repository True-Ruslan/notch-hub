import Testing
@testable import NotchHubMediaCore

@MainActor
struct MediaGesturePeekTests {
    @Test
    func peekPresentationRightRequestsBoundedCapabilityArmsOnceAndCommitsPrevious() throws {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let changed = coordinator.handle(
            sample(.changed, x: 90),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let request = try #require(capabilityRequests(changed).first)
        #expect(visualOffsets(changed) == [90])
        #expect(request.direction == .previous)
        #expect(armHapticCount(changed) == 0)

        let resolved = coordinator.resolveCompactCapability(
            gestureID: request.id,
            direction: request.direction,
            supported: true
        )
        #expect(armHapticCount(resolved) == 1)

        let ended = coordinator.handle(
            sample(.ended),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        #expect(commits(ended) == [.previous])
    }

    @Test
    func peekPresentationLeftRequestsBoundedCapabilityAndCommitsNext() throws {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let changed = coordinator.handle(
            sample(.changed, x: -90),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let request = try #require(capabilityRequests(changed).first)
        #expect(visualOffsets(changed) == [-90])
        #expect(request.direction == .next)
        _ = coordinator.resolveCompactCapability(
            gestureID: request.id,
            direction: request.direction,
            supported: true
        )

        let ended = coordinator.handle(
            sample(.ended),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        #expect(commits(ended) == [.next])
    }

    @Test
    func negativeSemanticHorizontalDeltaProducesNegativePresentationOffset() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )

        let changed = coordinator.handle(
            sample(.changed, x: -40),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )

        #expect(visualOffsets(changed) == [-40])
    }

    @Test
    func positiveSemanticHorizontalDeltaProducesPositivePresentationOffset() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )

        let changed = coordinator.handle(
            sample(.changed, x: 40),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )

        #expect(visualOffsets(changed) == [40])
    }

    @Test
    func peekDownAt70PointsRequestsExpansionOnlyOnEnd() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let changed = coordinator.handle(
            sample(.changed, y: 70),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let ended = coordinator.handle(
            sample(.ended),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )

        #expect(!changed.contains(.requestExpansion))
        #expect(ended.contains(.requestExpansion))
        #expect(!ended.contains(.requestCollapse))
    }

    @Test
    func peekUpNeverRequestsCollapse() {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        _ = coordinator.handle(
            sample(.changed, y: -120),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let ended = coordinator.handle(
            sample(.ended),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )

        #expect(!ended.contains(.requestExpansion))
        #expect(!ended.contains(.requestCollapse))
    }

    @Test
    func stalePeekCapabilityResolutionCannotArmNewGesture() throws {
        let coordinator = MediaGestureCoordinator()
        _ = coordinator.handle(
            sample(.began),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let changed = coordinator.handle(
            sample(.changed, x: -90),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        let old = try #require(capabilityRequests(changed).first)

        _ = coordinator.handle(
            sample(.cancelled),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )
        _ = coordinator.handle(
            sample(.began),
            surface: .peek,
            previous: .pending,
            next: .pending,
            seekActive: false
        )

        #expect(
            coordinator.resolveCompactCapability(
                gestureID: old.id,
                direction: old.direction,
                supported: true
            ).isEmpty
        )
    }

    private func sample(
        _ phase: MediaGesturePhase,
        x: Double = 0,
        y: Double = 0
    ) -> MediaGestureSample {
        MediaGestureSample(
            phase: phase,
            deltaX: x,
            deltaY: y,
            interactiveWidth: 300,
            isMomentum: false
        )
    }

    private func capabilityRequests(
        _ effects: [MediaGestureEffect]
    ) -> [(id: UInt64, direction: MediaGestureDirection)] {
        effects.compactMap { effect in
            guard case .requestCompactCapability(let gestureID, let direction) = effect else {
                return nil
            }
            return (gestureID, direction)
        }
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

    private func visualOffsets(_ effects: [MediaGestureEffect]) -> [Double] {
        effects.compactMap { effect in
            guard case .visualOffset(let value) = effect else {
                return nil
            }
            return value
        }
    }
}
