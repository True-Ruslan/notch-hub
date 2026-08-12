import CoreGraphics
import Foundation

enum NotchInteractionIntent {
    case deliberateExpansion
    case pointerExitCollapse
}

@MainActor
final class NotchInteractionCoordinator {
    typealias Cancellation = @MainActor () -> Void
    typealias Scheduler = @MainActor (
        TimeInterval,
        @escaping @MainActor () -> Void
    ) -> Cancellation

    static let defaultDwellSeconds: TimeInterval = 0.12

    private let scheduleActivation: Scheduler
    private let dwellSeconds: TimeInterval
    private let emitIntent: @MainActor (NotchInteractionIntent) -> Void

    private var pendingCancellation: Cancellation?
    private var pendingGeneration: UInt64?
    private var generation: UInt64 = 0
    private var isInvalidated = false

    init(
        scheduleActivation: @escaping Scheduler,
        dwellSeconds: TimeInterval = NotchInteractionCoordinator.defaultDwellSeconds,
        emitIntent: @escaping @MainActor (NotchInteractionIntent) -> Void
    ) {
        self.scheduleActivation = scheduleActivation
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

        case .peek:
            cancelPendingActivation()
            let target = NotchPointerPolicy.presentation(
                current: .peek,
                pointer: pointer,
                layout: layout
            )
            if target == .compact {
                emitIntent(.pointerExitCollapse)
            }

        case .expanded:
            cancelPendingActivation()
            let target = NotchPointerPolicy.presentation(
                current: .expanded,
                pointer: pointer,
                layout: layout
            )
            if target == .compact {
                emitIntent(.pointerExitCollapse)
            }
        }
    }

    func cancelPendingActivationForInteractiveTransition() {
        guard !isInvalidated else {
            return
        }
        cancelPendingActivation()
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
        pendingCancellation = scheduleActivation(dwellSeconds) { [weak self] in
            self?.completeActivation(generation: scheduledGeneration)
        }
    }

    private func cancelPendingActivation() {
        pendingCancellation?()
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
        emitIntent(.deliberateExpansion)
    }
}
