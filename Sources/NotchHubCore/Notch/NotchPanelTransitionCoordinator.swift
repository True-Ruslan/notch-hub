import CoreGraphics
import Foundation

enum NotchPanelTransitionPhase: Equatable, Sendable {
    case compact
    case expanding
    case expanded
    case collapsing
}

@MainActor
final class NotchPanelTransitionCoordinator {
    static let compactCornerRadius: CGFloat = 12
    static let expandedCornerRadius: CGFloat = 22

    private let model: NotchPanelModel
    private let currentAnimationDuration: @MainActor () -> TimeInterval
    private let animate: @MainActor (
        CGRect,
        CGFloat,
        TimeInterval,
        @escaping @MainActor () -> Void
    ) -> Void
    private let cancelAnimation: @MainActor () -> Void
    private let performExpansionHaptic: @MainActor () -> Void

    private(set) var phase: NotchPanelTransitionPhase
    private(set) var desiredPresentation: NotchPresentation

    private var generation: UInt64 = 0
    private var hasActiveAnimation = false
    private var isInvalidated = false

    init(
        model: NotchPanelModel,
        initialPresentation: NotchPresentation = .compact,
        animationDuration: @escaping @MainActor () -> TimeInterval,
        animate: @escaping @MainActor (
            CGRect,
            CGFloat,
            TimeInterval,
            @escaping @MainActor () -> Void
        ) -> Void,
        cancelAnimation: @escaping @MainActor () -> Void,
        performExpansionHaptic: @escaping @MainActor () -> Void
    ) {
        self.model = model
        self.currentAnimationDuration = animationDuration
        self.animate = animate
        self.cancelAnimation = cancelAnimation
        self.performExpansionHaptic = performExpansionHaptic
        self.desiredPresentation = initialPresentation
        self.phase = initialPresentation == .compact ? .compact : .expanded
    }

    func accept(_ intent: NotchInteractionIntent, layout: NotchLayout) {
        let presentation: NotchPresentation
        let hapticEligible: Bool

        switch intent {
        case .deliberateExpansion:
            presentation = .expanded
            hapticEligible = true
        case .pointerExitCollapse:
            presentation = .compact
            hapticEligible = false
        case .programmaticExpansion:
            presentation = .expanded
            hapticEligible = false
        }

        guard !isInvalidated, presentation != desiredPresentation else {
            return
        }

        beginTransition(
            to: presentation,
            layout: layout,
            hapticEligible: hapticEligible
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
        cancelActiveAnimationIfNeeded()
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
        cancelActiveAnimationIfNeeded()

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

        animate(
            frame,
            cornerRadius,
            currentAnimationDuration()
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
            hasActiveAnimation = true
        }

        if hapticEligible, presentation == .expanded {
            performExpansionHaptic()
        }
    }

    private func cancelActiveAnimationIfNeeded() {
        guard hasActiveAnimation else {
            return
        }

        hasActiveAnimation = false
        cancelAnimation()
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

        hasActiveAnimation = false

        switch expectedPresentation {
        case .compact:
            model.setContentPresentation(.compact)
            phase = .compact
        case .expanded:
            phase = .expanded
        }
    }
}
