import Testing
@testable import NotchHubMediaCore

@MainActor
struct MediaGesturePhysicalPipelineTests {
    @Test
    func physicalHorizontalDirectionControlsMatchingVisualAndCommandAcrossScrollPreferences() {
        let cases: [PhysicalCase] = [
            .init(rawX: -90, invertedFromDevice: false, visualX: 90, command: .previous),
            .init(rawX: 90, invertedFromDevice: true, visualX: 90, command: .previous),
            .init(rawX: 90, invertedFromDevice: false, visualX: -90, command: .next),
            .init(rawX: -90, invertedFromDevice: true, visualX: -90, command: .next)
        ]

        for testCase in cases {
            let normalized = MediaGestureInputNormalizer.semanticDeltas(
                scrollingDeltaX: testCase.rawX,
                scrollingDeltaY: 0,
                isDirectionInvertedFromDevice: testCase.invertedFromDevice
            )
            #expect(normalized.x == testCase.visualX)
            #expect(normalized.y == 0)

            let coordinator = MediaGestureCoordinator()
            _ = coordinator.handle(
                sample(.began),
                surface: .expanded,
                previous: .supported,
                next: .supported,
                seekActive: false
            )
            let changed = coordinator.handle(
                sample(.changed, x: normalized.x),
                surface: .expanded,
                previous: .supported,
                next: .supported,
                seekActive: false
            )
            let ended = coordinator.handle(
                sample(.ended),
                surface: .expanded,
                previous: .supported,
                next: .supported,
                seekActive: false
            )

            #expect(visualOffsets(changed) == [testCase.visualX])
            #expect(changed.filter { $0 == .requestArmHaptic }.count == 1)
            #expect(commits(ended) == [testCase.command])
        }
    }

    private struct PhysicalCase {
        let rawX: Double
        let invertedFromDevice: Bool
        let visualX: Double
        let command: MediaGestureDirection
    }

    private func sample(
        _ phase: MediaGesturePhase,
        x: Double = 0
    ) -> MediaGestureSample {
        MediaGestureSample(
            phase: phase,
            deltaX: x,
            deltaY: 0,
            interactiveWidth: 300,
            isMomentum: false
        )
    }

    private func visualOffsets(_ effects: [MediaGestureEffect]) -> [Double] {
        effects.compactMap { effect in
            guard case .visualOffset(let value) = effect else {
                return nil
            }
            return value
        }
    }

    private func commits(_ effects: [MediaGestureEffect]) -> [MediaGestureDirection] {
        effects.compactMap { effect in
            guard case .commit(let direction) = effect else {
                return nil
            }
            return direction
        }
    }
}
