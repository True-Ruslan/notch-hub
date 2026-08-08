import CoreGraphics

public enum NotchPanelTransitionPhase: Equatable, Sendable {
    case compact
    case expanding
    case expanded
    case collapsing
}

@MainActor
protocol NotchPanelAnimationHandle: AnyObject {
    func cancel()
}

@MainActor
protocol NotchPanelAnimationDriving: AnyObject {
    func animate(
        frame: CGRect,
        cornerRadius: CGFloat,
        policy: NotchAnimationPolicy,
        completion: @escaping @MainActor () -> Void
    ) -> any NotchPanelAnimationHandle
}

@MainActor
final class NotchPanelTransitionCoordinator {
    static let compactCornerRadius: CGFloat = 12
    static let expandedCornerRadius: CGFloat = 22

    private let model: NotchPanelModel
    private let animationDriver: any NotchPanelAnimationDriving
    private let currentAnimationPolicy: @MainActor () -> NotchAnimationPolicy
    private let haptics: any NotchHapticPerforming

    private(set) var phase: NotchPanelTransitionPhase
    private(set) var desiredPresentation: NotchPresentation

    private var generation: UInt64 = 0
    private var activeAnimation: (any NotchPanelAnimationHandle)?
    private var isInvalidated = false

    init(
        model: NotchPanelModel,
        animationDriver: any NotchPanelAnimationDriving,
        animationPolicy: @escaping @MainActor () -> NotchAnimationPolicy,
        haptics: any NotchHapticPerforming,
        initialPresentation: NotchPresentation = .compact
    ) {
        self.model = model
        self.animationDriver = animationDriver
        self.currentAnimationPolicy = animationPolicy
        self.haptics = haptics
        self.desiredPresentation = initialPresentation
        self.phase = initialPresentation == .compact ? .compact : .expanded
    }

    func accept(_ intent: NotchInteractionIntent, layout: NotchLayout) {
        guard !isInvalidated, intent.desiredPresentation != desiredPresentation else {
            return
        }

        beginTransition(
            to: intent.desiredPresentation,
            layout: layout,
            hapticEligible: intent.hapticEligible
        )
    }

    func animationPolicyDidChange(layout: NotchLayout) {
        guard !isInvalidated else {
            return
        }

        switch phase {
        case .expanding, .collapsing:
            beginTransition(
                to: desiredPresentation,
                layout: layout,
                hapticEligible: false,
                forceRetarget: true
            )
        case .compact, .expanded:
            break
        }
    }

    func invalidate() {
        guard !isInvalidated else {
            return
        }

        isInvalidated = true
        generation &+= 1
        activeAnimation?.cancel()
        activeAnimation = nil
    }

    private func beginTransition(
        to presentation: NotchPresentation,
        layout: NotchLayout,
        hapticEligible: Bool,
        forceRetarget: Bool = false
    ) {
        if !forceRetarget {
            desiredPresentation = presentation
        }

        generation &+= 1
        let scheduledGeneration = generation

        activeAnimation?.cancel()
        activeAnimation = nil

        let expectedPhase: NotchPanelTransitionPhase
        let frame: CGRect
        let cornerRadius: CGFloat

        switch presentation {
        case .compact:
            phase = .collapsing
            expectedPhase = .collapsing
            frame = layout.compactFrame
            cornerRadius = Self.compactCornerRadius

        case .expanded:
            phase = .expanding
            expectedPhase = .expanding
            model.setContentPresentation(.expanded)
            frame = layout.expandedFrame
            cornerRadius = Self.expandedCornerRadius
        }

        let handle = animationDriver.animate(
            frame: frame,
            cornerRadius: cornerRadius,
            policy: currentAnimationPolicy()
        ) { [weak self] in
            self?.completeTransition(
                generation: scheduledGeneration,
                expectedPresentation: presentation
            )
        }

        if !isInvalidated,
            generation == scheduledGeneration,
            phase == expectedPhase
        {
            activeAnimation = handle
        }

        if hapticEligible, presentation == .expanded {
            haptics.performExpansionHaptic()
        }
    }

    private func completeTransition(
        generation scheduledGeneration: UInt64,
        expectedPresentation: NotchPresentation
    ) {
        guard
            !isInvalidated,
            generation == scheduledGeneration,
            desiredPresentation == expectedPresentation
        else {
            return
        }

        activeAnimation = nil

        switch expectedPresentation {
        case .compact:
            model.setContentPresentation(.compact)
            phase = .compact
        case .expanded:
            phase = .expanded
        }
    }
}
