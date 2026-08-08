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

    private let model: NotchPanelModel
    private let scheduler: any NotchActivationScheduling
    private let haptics: any NotchHapticPerforming
    private let dwellSeconds: TimeInterval

    private var pendingCancellation: (any NotchActivationCancellation)?
    private var pendingGeneration: UInt64?
    private var generation: UInt64 = 0
    private var isInvalidated = false

    init(
        model: NotchPanelModel,
        scheduler: any NotchActivationScheduling,
        haptics: any NotchHapticPerforming,
        dwellSeconds: TimeInterval = NotchInteractionCoordinator.defaultDwellSeconds
    ) {
        self.model = model
        self.scheduler = scheduler
        self.haptics = haptics
        self.dwellSeconds = dwellSeconds
    }

    func pointerMoved(
        to pointer: CGPoint,
        layout: NotchLayout,
        allowActivation: Bool = true
    ) {
        guard !isInvalidated else {
            return
        }

        switch model.presentation {
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
                model.setHovered(false)
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
            pendingGeneration == scheduledGeneration,
            model.presentation == .compact
        else {
            return
        }

        pendingCancellation = nil
        pendingGeneration = nil
        model.setHovered(true)
        haptics.performExpansionHaptic()
    }
}
