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

    private struct PendingActivation {
        let generation: UInt64
        let cancellation: any NotchActivationCancellation
    }

    private let model: NotchPanelModel
    private let scheduler: any NotchActivationScheduling
    private let haptics: any NotchHapticPerforming
    private let dwellSeconds: TimeInterval

    private var pendingActivation: PendingActivation?
    private var generation: UInt64 = 0
    private var isInvalidated = false

    init(
        model: NotchPanelModel,
        scheduler: any NotchActivationScheduling,
        haptics: any NotchHapticPerforming,
        dwellSeconds: TimeInterval = NotchInteractionCoordinator.defaultDwellSeconds
    ) {
        precondition(dwellSeconds.isFinite && dwellSeconds >= 0)
        self.model = model
        self.scheduler = scheduler
        self.haptics = haptics
        self.dwellSeconds = dwellSeconds
    }

    func pointerMoved(to pointer: CGPoint, layout: NotchLayout) {
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

            if target == .expanded {
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
        guard pendingActivation == nil else {
            return
        }

        generation &+= 1
        let scheduledGeneration = generation
        let cancellation = scheduler.schedule(after: dwellSeconds) { [weak self] in
            self?.completeActivation(generation: scheduledGeneration)
        }
        pendingActivation = PendingActivation(
            generation: scheduledGeneration,
            cancellation: cancellation
        )
    }

    private func cancelPendingActivation() {
        pendingActivation?.cancellation.cancel()
        pendingActivation = nil
    }

    private func completeActivation(generation scheduledGeneration: UInt64) {
        guard
            !isInvalidated,
            let pendingActivation,
            pendingActivation.generation == scheduledGeneration,
            model.presentation == .compact
        else {
            return
        }

        self.pendingActivation = nil
        model.setHovered(true)
        haptics.performExpansionHaptic()
    }
}
