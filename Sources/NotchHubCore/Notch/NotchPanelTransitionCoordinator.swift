import CoreGraphics
import Foundation

enum NotchPanelTransitionPhase {
    case compact
    case peek
    case expanding
    case interactiveExpanding(progress: CGFloat)
    case expanded
    case collapsing
    case interactiveCollapsing(progress: CGFloat)
}

@MainActor
final class NotchPanelTransitionCoordinator {
    static let compactCornerRadius: CGFloat = 12
    static let peekCornerRadius: CGFloat = 18
    static let expandedCornerRadius: CGFloat = 22

    private let model: NotchPanelModel
    private let currentAnimationDuration: @MainActor () -> TimeInterval
    private let animate: @MainActor (CGRect, CGFloat, TimeInterval, @escaping @MainActor () -> Void) -> Void
    private let cancelAnimation: @MainActor () -> Void
    private let performExpansionHaptic: @MainActor () -> Void
    private let applyInteractivePresentation: @MainActor (CGRect, CGFloat) -> Void
    private let applySettledPresentation: @MainActor (CGRect, CGFloat) -> Void

    private(set) var phase: NotchPanelTransitionPhase
    private(set) var desiredPresentation: NotchPresentation
    var settledPresentationHandler: (@MainActor @Sendable (NotchPresentation) -> Void)?

    private var generation: UInt64 = 0
    private var hasActiveAnimation = false
    private var isInvalidated = false

    init(
        model: NotchPanelModel,
        initialPresentation: NotchPresentation = .compact,
        animationDuration: @escaping @MainActor () -> TimeInterval,
        animate:
            @escaping @MainActor (CGRect, CGFloat, TimeInterval, @escaping @MainActor () -> Void) -> Void,
        cancelAnimation: @escaping @MainActor () -> Void,
        performExpansionHaptic: @escaping @MainActor () -> Void,
        applyInteractivePresentation: @escaping @MainActor (CGRect, CGFloat) -> Void = { _, _ in },
        applySettledPresentation: @escaping @MainActor (CGRect, CGFloat) -> Void = { _, _ in }
    ) {
        self.model = model
        self.currentAnimationDuration = animationDuration
        self.animate = animate
        self.cancelAnimation = cancelAnimation
        self.performExpansionHaptic = performExpansionHaptic
        self.applyInteractivePresentation = applyInteractivePresentation
        self.applySettledPresentation = applySettledPresentation
        self.desiredPresentation = initialPresentation
        switch initialPresentation {
        case .compact:
            self.phase = .compact
        case .peek:
            self.phase = .peek
        case .expanded:
            self.phase = .expanded
        }
    }

    func accept(_ intent: NotchInteractionIntent, layout: NotchLayout) {
        guard !isInvalidated else {
            return
        }

        if isInteractiveTransitionActive {
            guard case .pointerExitCollapse = intent else {
                return
            }
            beginTransition(
                to: .compact,
                layout: layout,
                hapticEligible: false
            )
            return
        }

        let presentation: NotchPresentation
        let hapticEligible: Bool

        switch intent {
        case .deliberateExpansion:
            presentation = .expanded
            hapticEligible = true
        case .pointerExitCollapse:
            presentation = .compact
            hapticEligible = false
        }

        guard presentation != desiredPresentation else {
            return
        }

        beginTransition(
            to: presentation,
            layout: layout,
            hapticEligible: hapticEligible
        )
    }

    func requestPeek(layout: NotchLayout) {
        guard
            !isInvalidated,
            !isInteractiveTransitionActive,
            desiredPresentation != .peek
        else {
            return
        }

        beginTransition(
            to: .peek,
            layout: layout,
            hapticEligible: true
        )
    }

    func requestProgrammaticExpansion(layout: NotchLayout) {
        guard
            !isInvalidated,
            !isInteractiveTransitionActive,
            desiredPresentation != .expanded
        else {
            return
        }

        beginTransition(
            to: .expanded,
            layout: layout,
            hapticEligible: false
        )
    }

    func requestProgrammaticCollapse(layout: NotchLayout) {
        guard
            !isInvalidated,
            !isInteractiveTransitionActive,
            desiredPresentation != .compact
        else {
            return
        }

        beginTransition(
            to: .compact,
            layout: layout,
            hapticEligible: false
        )
    }

    @discardableResult
    func beginInteractiveTransition(
        from origin: NotchPresentation,
        layout _: NotchLayout
    ) -> Bool {
        guard !isInvalidated else {
            return false
        }

        switch (origin, phase) {
        case (.compact, .compact), (.expanded, .expanded):
            break
        case (.compact, _), (.peek, _), (.expanded, _):
            return false
        }

        generation &+= 1
        cancelActiveAnimationIfNeeded()

        switch origin {
        case .compact:
            desiredPresentation = .expanded
            model.setContentPresentation(.expanded)
            phase = .interactiveExpanding(progress: 0)
        case .peek:
            return false
        case .expanded:
            desiredPresentation = .compact
            phase = .interactiveCollapsing(progress: 0)
        }
        return true
    }

    func updateInteractiveTransition(
        verticalDistance: CGFloat,
        layout: NotchLayout
    ) {
        guard !isInvalidated else {
            return
        }

        let progress = Self.interactiveProgress(
            verticalDistance: verticalDistance,
            layout: layout
        )

        switch phase {
        case .interactiveExpanding:
            phase = .interactiveExpanding(progress: progress)
            applyInteractiveProgress(
                progress,
                origin: .compact,
                layout: layout
            )
        case .interactiveCollapsing:
            phase = .interactiveCollapsing(progress: progress)
            applyInteractiveProgress(
                progress,
                origin: .expanded,
                layout: layout
            )
        case .compact, .peek, .expanding, .expanded, .collapsing:
            break
        }
    }

    func finishInteractiveTransition(
        commit: Bool,
        layout: NotchLayout
    ) {
        guard !isInvalidated else {
            return
        }

        let origin: NotchPresentation
        let destination: NotchPresentation
        switch phase {
        case .interactiveExpanding:
            origin = .compact
            destination = .expanded
        case .interactiveCollapsing:
            origin = .expanded
            destination = .compact
        case .compact, .peek, .expanding, .expanded, .collapsing:
            return
        }

        beginTransition(
            to: commit ? destination : origin,
            layout: layout,
            hapticEligible: false
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
        case .interactiveExpanding(let progress):
            applyInteractiveProgress(
                progress,
                origin: .compact,
                layout: layout
            )
        case .interactiveCollapsing(let progress):
            applyInteractiveProgress(
                progress,
                origin: .expanded,
                layout: layout
            )
        case .compact:
            reconcileSettledFrame(for: .compact, layout: layout)
        case .peek:
            reconcileSettledFrame(for: .peek, layout: layout)
        case .expanded:
            reconcileSettledFrame(for: .expanded, layout: layout)
        }
    }

    /// Re-applies the exact settled frame/corner for `presentation` against a
    /// freshly changed `layout`, without publishing a settlement or
    /// animating. A settled panel is not otherwise guaranteed to already be
    /// showing the frame this `layout` implies: `layoutModel`'s compact
    /// horizontal extension (armed/disarmed as media availability changes)
    /// can change the settled `.compact` layout while the panel sits idle in
    /// that phase, and AppKit has been observed to independently resize the
    /// panel's window (matching the new layout's width but not its
    /// recentered origin) the first time SwiftUI's view tree switches into
    /// media content — reconciling here, instantly, corrects either case
    /// before the next real transition would otherwise visibly "snap."
    private func reconcileSettledFrame(for presentation: NotchPresentation, layout: NotchLayout) {
        let endpoint = Self.endpoint(for: presentation, layout: layout)
        applySettledPresentation(endpoint.frame, endpoint.cornerRadius)
    }

    func displayLayoutDidChange(_ layout: NotchLayout) {
        guard !isInvalidated else {
            return
        }

        let targetPresentation: NotchPresentation
        let shouldPublishSettlement: Bool

        switch phase {
        case .compact:
            targetPresentation = .compact
            shouldPublishSettlement = false
        case .peek:
            targetPresentation = .peek
            shouldPublishSettlement = false
        case .expanded:
            targetPresentation = .expanded
            shouldPublishSettlement = false
        case .expanding, .collapsing:
            targetPresentation = desiredPresentation
            shouldPublishSettlement = true
        case .interactiveExpanding:
            targetPresentation = .compact
            shouldPublishSettlement = false
        case .interactiveCollapsing:
            targetPresentation = .expanded
            shouldPublishSettlement = false
        }

        generation &+= 1
        cancelActiveAnimationIfNeeded()
        desiredPresentation = targetPresentation

        let endpoint = Self.endpoint(for: targetPresentation, layout: layout)
        applySettledPresentation(endpoint.frame, endpoint.cornerRadius)
        model.setContentPresentation(targetPresentation)
        phase = Self.settledPhase(for: targetPresentation)

        if shouldPublishSettlement {
            settledPresentationHandler?(targetPresentation)
        }
    }

    func invalidate() {
        guard !isInvalidated else {
            return
        }

        isInvalidated = true
        generation &+= 1
        cancelActiveAnimationIfNeeded()
        settledPresentationHandler = nil
    }

    var isInteractiveTransitionActive: Bool {
        switch phase {
        case .interactiveExpanding, .interactiveCollapsing:
            return true
        case .compact, .peek, .expanding, .expanded, .collapsing:
            return false
        }
    }

    private func applyInteractiveProgress(
        _ progress: CGFloat,
        origin: NotchPresentation,
        layout: NotchLayout
    ) {
        let boundedProgress = min(1, max(0, progress))
        let startFrame: CGRect
        let endFrame: CGRect
        let startRadius: CGFloat
        let endRadius: CGFloat

        switch origin {
        case .compact:
            startFrame = layout.compactFrame
            endFrame = layout.expandedFrame
            startRadius = Self.compactCornerRadius
            endRadius = Self.expandedCornerRadius
        case .peek:
            return
        case .expanded:
            startFrame = layout.expandedFrame
            endFrame = layout.compactFrame
            startRadius = Self.expandedCornerRadius
            endRadius = Self.compactCornerRadius
        }

        applyInteractivePresentation(
            Self.interpolateFrame(
                from: startFrame,
                to: endFrame,
                progress: boundedProgress
            ),
            Self.interpolate(
                from: startRadius,
                to: endRadius,
                progress: boundedProgress
            )
        )
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

        let endpoint = Self.endpoint(for: presentation, layout: layout)

        switch presentation {
        case .compact:
            phase = .collapsing
        case .peek:
            phase = .expanding
            model.setContentPresentation(.peek)
        case .expanded:
            phase = .expanding
            model.setContentPresentation(.expanded)
        }

        hasActiveAnimation = true
        animate(
            endpoint.frame,
            endpoint.cornerRadius,
            currentAnimationDuration()
        ) { [weak self] in
            self?.completeTransition(
                generation: scheduledGeneration,
                expectedPresentation: presentation,
                settledFrame: endpoint.frame,
                settledCornerRadius: endpoint.cornerRadius
            )
        }

        if hapticEligible {
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
        expectedPresentation: NotchPresentation,
        settledFrame: CGRect,
        settledCornerRadius: CGFloat
    ) {
        guard
            !isInvalidated,
            generation == scheduledGeneration,
            desiredPresentation == expectedPresentation
        else {
            return
        }

        hasActiveAnimation = false
        applySettledPresentation(settledFrame, settledCornerRadius)

        switch expectedPresentation {
        case .compact:
            model.setContentPresentation(.compact)
            phase = .compact
        case .peek:
            model.setContentPresentation(.peek)
            phase = .peek
        case .expanded:
            phase = .expanded
        }

        settledPresentationHandler?(expectedPresentation)
    }

    private static func endpoint(
        for presentation: NotchPresentation,
        layout: NotchLayout
    ) -> (frame: CGRect, cornerRadius: CGFloat) {
        switch presentation {
        case .compact:
            (layout.compactFrame, compactCornerRadius)
        case .peek:
            (layout.peekFrame, peekCornerRadius)
        case .expanded:
            (layout.expandedFrame, expandedCornerRadius)
        }
    }

    private static func settledPhase(
        for presentation: NotchPresentation
    ) -> NotchPanelTransitionPhase {
        switch presentation {
        case .compact:
            .compact
        case .peek:
            .peek
        case .expanded:
            .expanded
        }
    }

    private static func interactiveProgress(
        verticalDistance: CGFloat,
        layout: NotchLayout
    ) -> CGFloat {
        let heightDelta = max(0, layout.expandedFrame.height - layout.compactFrame.height)
        let interactiveTravel = max(140, min(heightDelta, 220))
        let distance = verticalDistance.isFinite ? max(0, verticalDistance) : 0
        return min(1, distance / interactiveTravel)
    }

    private static func interpolateFrame(
        from start: CGRect,
        to end: CGRect,
        progress: CGFloat
    ) -> CGRect {
        CGRect(
            x: interpolate(from: start.origin.x, to: end.origin.x, progress: progress),
            y: interpolate(from: start.origin.y, to: end.origin.y, progress: progress),
            width: interpolate(from: start.width, to: end.width, progress: progress),
            height: interpolate(from: start.height, to: end.height, progress: progress)
        )
    }

    private static func interpolate(
        from start: CGFloat,
        to end: CGFloat,
        progress: CGFloat
    ) -> CGFloat {
        start + ((end - start) * progress)
    }
}
