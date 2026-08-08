import CoreGraphics
import Foundation
import Testing
@testable import NotchHubCore

@MainActor
struct NotchPanelTransitionStressTests {
    private let layout = NotchLayout(
        hasHardwareNotch: true,
        hardwareNotchWidth: 180,
        compactFrame: CGRect(x: 410, y: 868, width: 180, height: 32),
        expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
    )

    @Test
    func tenThousandReversalsKeepOnlyLatestGenerationAuthoritative() {
        let model = NotchPanelModel()
        let driver = BoundedAnimationDriver()
        var hapticCount = 0
        let coordinator = NotchPanelTransitionCoordinator(
            model: model,
            animationDuration: { 0.20 },
            animate: { frame, cornerRadius, duration, completion in
                driver.animate(
                    frame: frame,
                    cornerRadius: cornerRadius,
                    duration: duration,
                    completion: completion
                )
            },
            cancelAnimation: { driver.cancel() },
            performExpansionHaptic: { hapticCount += 1 }
        )

        for index in 0..<10_000 {
            coordinator.accept(
                index.isMultiple(of: 2) ? .deliberateExpansion : .pointerExitCollapse,
                layout: layout
            )
        }

        #expect(coordinator.desiredPresentation == .compact)
        #expect(coordinator.phase.isCollapsing)
        #expect(model.contentPresentation == .expanded)
        #expect(driver.requestCount == 10_000)
        #expect(driver.cancelCount == 9_999)
        #expect(driver.retainedCompletionCount == 2)
        #expect(hapticCount == 5_000)

        driver.completeFirstStale()

        #expect(coordinator.phase.isCollapsing)
        #expect(coordinator.desiredPresentation == .compact)
        #expect(model.contentPresentation == .expanded)

        driver.completeLatest()

        #expect(coordinator.phase.isCompact)
        #expect(coordinator.desiredPresentation == .compact)
        #expect(model.contentPresentation == .compact)
    }
}

private extension NotchPanelTransitionPhase {
    var isCompact: Bool {
        if case .compact = self {
            true
        } else {
            false
        }
    }

    var isCollapsing: Bool {
        if case .collapsing = self {
            true
        } else {
            false
        }
    }
}

@MainActor
private final class BoundedAnimationDriver {
    private var firstStaleCompletion: (@MainActor () -> Void)?
    private var latestCompletion: (@MainActor () -> Void)?

    private(set) var requestCount = 0
    private(set) var cancelCount = 0

    var retainedCompletionCount: Int {
        (firstStaleCompletion == nil ? 0 : 1) + (latestCompletion == nil ? 0 : 1)
    }

    func animate(
        frame: CGRect,
        cornerRadius: CGFloat,
        duration: TimeInterval,
        completion: @escaping @MainActor () -> Void
    ) {
        _ = frame
        _ = cornerRadius
        _ = duration
        requestCount += 1
        if firstStaleCompletion == nil {
            firstStaleCompletion = completion
        }
        latestCompletion = completion
    }

    func cancel() {
        cancelCount += 1
    }

    func completeFirstStale() {
        firstStaleCompletion?()
    }

    func completeLatest() {
        latestCompletion?()
    }
}
