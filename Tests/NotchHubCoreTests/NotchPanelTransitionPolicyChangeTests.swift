import CoreGraphics
import Foundation
import Testing
@testable import NotchHubCore

@MainActor
struct NotchPanelTransitionPolicyChangeTests {
    private let layout = NotchLayout(
        hasHardwareNotch: true,
        hardwareNotchWidth: 180,
        compactFrame: CGRect(x: 410, y: 868, width: 180, height: 32),
        expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
    )

    @Test
    func reduceMotionRetargetsInFlightWithoutSecondFeedback() {
        let model = NotchPanelModel()
        let driver = PolicyChangeDriver()
        let duration = MutableDuration(value: 0.20)
        var feedbackCount = 0
        let coordinator = NotchPanelTransitionCoordinator(
            model: model,
            animationDuration: { duration.value },
            animate: { frame, radius, seconds, completion in
                driver.animate(frame: frame, radius: radius, duration: seconds, completion: completion)
            },
            cancelAnimation: { driver.cancel() },
            performExpansionHaptic: { feedbackCount += 1 }
        )

        coordinator.accept(.deliberateExpansion, layout: layout)
        #expect(driver.requests.count == 1)
        #expect(driver.requests[0].duration == 0.20)
        #expect(feedbackCount == 1)

        duration.value = 0
        coordinator.animationPolicyDidChange(layout: layout)

        #expect(driver.cancelCount == 1)
        #expect(driver.requests.count == 2)
        #expect(driver.requests[1].duration == 0)
        #expect(feedbackCount == 1)
        #expect(coordinator.phase.isExpanding)

        driver.complete(index: 0)
        #expect(coordinator.phase.isExpanding)

        driver.complete(index: 1)
        #expect(coordinator.phase.isExpanded)
        #expect(model.contentPresentation == .expanded)
    }

    @Test
    func compactLayoutChangeRetargetsInFlightCollapseAndRejectsStaleCompletion() {
        let model = NotchPanelModel()
        let driver = PolicyChangeDriver()
        var feedbackCount = 0
        let coordinator = NotchPanelTransitionCoordinator(
            model: model,
            animationDuration: { 0.20 },
            animate: { frame, radius, seconds, completion in
                driver.animate(frame: frame, radius: radius, duration: seconds, completion: completion)
            },
            cancelAnimation: { driver.cancel() },
            performExpansionHaptic: { feedbackCount += 1 }
        )

        coordinator.accept(.deliberateExpansion, layout: layout)
        driver.complete(index: 0)
        #expect(coordinator.phase.isExpanded)
        #expect(feedbackCount == 1)

        let retainedMediaLayout = layout.withCompactHorizontalExtension(36)
        coordinator.accept(.pointerExitCollapse, layout: retainedMediaLayout)

        #expect(driver.requests.count == 2)
        #expect(driver.requests[1].frame == retainedMediaLayout.compactFrame)
        #expect(driver.requests[1].duration == 0.20)
        #expect(coordinator.phase.isCollapsing)

        coordinator.animationPolicyDidChange(layout: layout)

        #expect(driver.cancelCount == 1)
        #expect(driver.requests.count == 3)
        #expect(driver.requests[2].frame == layout.compactFrame)
        #expect(driver.requests[2].duration == 0.20)
        #expect(feedbackCount == 1)
        #expect(coordinator.phase.isCollapsing)

        driver.complete(index: 1)
        #expect(coordinator.phase.isCollapsing)
        #expect(model.contentPresentation == .expanded)

        driver.complete(index: 2)
        #expect(coordinator.phase.isCompact)
        #expect(model.contentPresentation == .compact)
    }

    @Test
    func policyChangeAtStableEndpointStartsNoTransition() {
        let model = NotchPanelModel()
        let driver = PolicyChangeDriver()
        let duration = MutableDuration(value: 0.20)
        var feedbackCount = 0
        let coordinator = NotchPanelTransitionCoordinator(
            model: model,
            animationDuration: { duration.value },
            animate: { frame, radius, seconds, completion in
                driver.animate(frame: frame, radius: radius, duration: seconds, completion: completion)
            },
            cancelAnimation: { driver.cancel() },
            performExpansionHaptic: { feedbackCount += 1 }
        )

        duration.value = 0
        coordinator.animationPolicyDidChange(layout: layout)

        #expect(driver.requests.isEmpty)
        #expect(driver.cancelCount == 0)
        #expect(feedbackCount == 0)
        #expect(coordinator.phase.isCompact)
    }
}

private extension NotchPanelTransitionPhase {
    var isCompact: Bool {
        if case .compact = self { true } else { false }
    }

    var isExpanding: Bool {
        if case .expanding = self { true } else { false }
    }

    var isExpanded: Bool {
        if case .expanded = self { true } else { false }
    }

    var isCollapsing: Bool {
        if case .collapsing = self { true } else { false }
    }
}

@MainActor
private final class MutableDuration {
    var value: TimeInterval

    init(value: TimeInterval) {
        self.value = value
    }
}

@MainActor
private final class PolicyChangeDriver {
    struct Request {
        let frame: CGRect
        let radius: CGFloat
        let duration: TimeInterval
        let completion: @MainActor () -> Void
    }

    private(set) var requests: [Request] = []
    private(set) var cancelCount = 0

    func animate(
        frame: CGRect,
        radius: CGFloat,
        duration: TimeInterval,
        completion: @escaping @MainActor () -> Void
    ) {
        requests.append(Request(frame: frame, radius: radius, duration: duration, completion: completion))
    }

    func cancel() {
        cancelCount += 1
    }

    func complete(index: Int) {
        requests[index].completion()
    }
}
