import CoreGraphics
import Foundation

@MainActor
protocol NotchActivationCancellation: AnyObject {
    func cancel()
}

@MainActor
protocol NotchActivationScheduling: AnyObject {
    func schedule(
        after delaySeconds: TimeInterval,
        action: @escaping @MainActor () -> Void
    ) -> any NotchActivationCancellation
}

@MainActor
protocol NotchHapticPerforming: AnyObject {
    func performExpansionHaptic()
}

@MainActor
final class NotchInteractionCoordinator {
    static let defaultDwellSeconds: TimeInterval = 0.12

    private let scheduler: any NotchActivationScheduling
    private let dwellSeconds: TimeInterval
    private let emitIntent: @MainActor (NotchInteractionIntent) -> Void

    private var pendingCancellation: (any NotchActivationCancellation)?
    private var pendingGeneration: UInt64?
    private var generation: UInt64 = 0
    private var isInvalidated = false

    init(
        scheduler: any NotchActivationScheduling,
        dwellSeconds: TimeInterval = NotchInteractionCoordinator.defaultDwellSeconds,
        emitIntent: @escaping @MainActor (NotchInteractionIntent) -> Void
    ) {
        self.scheduler = scheduler
        self.dwellSeconds = dwellSeconds
        self.emitIntent = emitIntent
    }

    func pointerMoved(
        to pointer: CGPoint,
        layout: NotchLayout,
        currentPresentation: NotchPresentation,
        allowActivation: Bool = true
    ) {
        guard !isInvalidated else {
            return
        }

        switch currentPresentation {
        case .compact:
            let target = NotchPointerPolicy.presentation(
                current: .compact,
                pointer: pointer,
                layout: layout
            )

            if target == .expanded && allowActivation {
                scheduleActivationIfNeeded()
            } else {
                cancelPendingActivation()
            }

        case .expanded:
            cancelPendingActivation()
            let target = NotchPointerPolicy.presentation(
                current: .expanded,
                pointer: pointer,
                layout: layout
            )
            if target == .compact {
                emitIntent(
                    NotchInteractionIntent(
                        desiredPresentation: .compact,
                        cause: .pointerExit,
                        hapticEligible: false
                    )
                )
            }
        }
    }

    func invalidate() {
        guard !isInvalidated else {
            return
        }

        isInvalidated = true
        cancelPendingActivation()
    }

    private func scheduleActivationIfNeeded() {
        guard pendingCancellation == nil else {
            return
        }

        generation &+= 1
        let scheduledGeneration = generation
        pendingGeneration = scheduledGeneration
        pendingCancellation = scheduler.schedule(after: dwellSeconds) { [weak self] in
            self?.completeActivation(generation: scheduledGeneration)
        }
    }

    private func cancelPendingActivation() {
        pendingCancellation?.cancel()
        pendingCancellation = nil
        pendingGeneration = nil
    }

    private func completeActivation(generation scheduledGeneration: UInt64) {
        guard
            !isInvalidated,
            pendingGeneration == scheduledGeneration
        else {
            return
        }

        pendingCancellation = nil
        pendingGeneration = nil
        emitIntent(
            NotchInteractionIntent(
                desiredPresentation: .expanded,
                cause: .deliberateHover,
                hapticEligible: true
            )
        )
    }
}
