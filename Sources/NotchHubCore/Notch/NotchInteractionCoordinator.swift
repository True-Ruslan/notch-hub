import CoreGraphics
import Foundation

public struct NotchHoverPeekRequest: Equatable, Sendable {
    fileprivate let generation: UInt64
}

enum NotchInteractionIntent {
    case deliberateExpansion
    case pointerExitCollapse
}

@MainActor
final class NotchInteractionCoordinator {
    typealias Cancellation = @MainActor () -> Void
    typealias Scheduler =
        @MainActor (
            TimeInterval,
            @escaping @MainActor () -> Void
        ) -> Cancellation

    static let defaultDwellSeconds: TimeInterval = 0.12
    static let defaultPeekCollapseGraceSeconds: TimeInterval = 0.14

    private let scheduleActivation: Scheduler
    private let dwellSeconds: TimeInterval
    private let peekCollapseGraceSeconds: TimeInterval
    private let emitHoverPeekRequest: @MainActor (NotchHoverPeekRequest) -> Void
    private let emitIntent: @MainActor (NotchInteractionIntent) -> Void

    private var pendingActivationCancellation: Cancellation?
    private var pendingActivationGeneration: UInt64?
    private var pendingCollapseCancellation: Cancellation?
    private var pendingCollapseGeneration: UInt64?
    private var activeHoverRequest: NotchHoverPeekRequest?
    private var latestPointer: CGPoint?
    private var generation: UInt64 = 0
    private var isPeekInteractionHeld = false
    private var isInvalidated = false

    init(
        scheduleActivation: @escaping Scheduler,
        dwellSeconds: TimeInterval = NotchInteractionCoordinator.defaultDwellSeconds,
        peekCollapseGraceSeconds: TimeInterval = NotchInteractionCoordinator.defaultPeekCollapseGraceSeconds,
        emitHoverPeekRequest: @escaping @MainActor (NotchHoverPeekRequest) -> Void = { _ in },
        emitIntent: @escaping @MainActor (NotchInteractionIntent) -> Void
    ) {
        self.scheduleActivation = scheduleActivation
        self.dwellSeconds = dwellSeconds
        self.peekCollapseGraceSeconds = peekCollapseGraceSeconds
        self.emitHoverPeekRequest = emitHoverPeekRequest
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

        latestPointer = pointer

        switch currentPresentation {
        case .compact:
            cancelPendingCollapse()
            let target = NotchPointerPolicy.presentation(
                current: .compact,
                pointer: pointer,
                layout: layout
            )

            if target == .peek, allowActivation, !isPeekInteractionHeld {
                scheduleHoverActivationIfNeeded()
            } else {
                invalidateHoverActivation()
            }

        case .peek:
            invalidateHoverActivation()
            let target = NotchPointerPolicy.presentation(
                current: .peek,
                pointer: pointer,
                layout: layout
            )
            if target == .peek {
                cancelPendingCollapse()
            } else if !isPeekInteractionHeld {
                schedulePeekCollapseIfNeeded()
            }

        case .expanded:
            invalidateHoverActivation()
            cancelPendingCollapse()
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

    func resolveHoverPeekRequest(
        _ request: NotchHoverPeekRequest,
        mediaAvailable _: Bool,
        layout: NotchLayout,
        currentPresentation: NotchPresentation
    ) -> Bool {
        guard
            !isInvalidated,
            activeHoverRequest == request
        else {
            return false
        }

        activeHoverRequest = nil

        guard
            currentPresentation == .compact,
            !isPeekInteractionHeld,
            let latestPointer,
            NotchPointerPolicy.presentation(
                current: .compact,
                pointer: latestPointer,
                layout: layout
            ) == .peek
        else {
            return false
        }

        return true
    }

    func setPeekInteractionHeld(
        _ held: Bool,
        layout: NotchLayout,
        currentPresentation: NotchPresentation
    ) {
        guard !isInvalidated else {
            return
        }

        isPeekInteractionHeld = held
        if held {
            cancelPendingCollapse()
            return
        }

        guard
            currentPresentation == .peek,
            let latestPointer,
            NotchPointerPolicy.presentation(
                current: .peek,
                pointer: latestPointer,
                layout: layout
            ) == .compact
        else {
            return
        }

        schedulePeekCollapseIfNeeded()
    }

    func cancelPendingActivationForInteractiveTransition() {
        guard !isInvalidated else {
            return
        }
        invalidateHoverActivation()
    }

    func resetPointerStateForDisplayMigration() {
        guard !isInvalidated else {
            return
        }

        invalidateHoverActivation()
        cancelPendingCollapse()
        latestPointer = nil
    }

    func invalidate() {
        guard !isInvalidated else {
            return
        }

        isInvalidated = true
        invalidateHoverActivation()
        cancelPendingCollapse()
        latestPointer = nil
    }

    private func scheduleHoverActivationIfNeeded() {
        guard
            pendingActivationCancellation == nil,
            activeHoverRequest == nil
        else {
            return
        }

        generation &+= 1
        let scheduledGeneration = generation
        pendingActivationGeneration = scheduledGeneration
        pendingActivationCancellation = scheduleActivation(dwellSeconds) { [weak self] in
            self?.completeHoverActivation(generation: scheduledGeneration)
        }
    }

    private func invalidateHoverActivation() {
        let hadActivation = pendingActivationCancellation != nil || activeHoverRequest != nil
        pendingActivationCancellation?()
        pendingActivationCancellation = nil
        pendingActivationGeneration = nil
        activeHoverRequest = nil
        if hadActivation {
            generation &+= 1
        }
    }

    private func completeHoverActivation(generation scheduledGeneration: UInt64) {
        guard
            !isInvalidated,
            pendingActivationGeneration == scheduledGeneration
        else {
            return
        }

        pendingActivationCancellation = nil
        pendingActivationGeneration = nil
        let request = NotchHoverPeekRequest(generation: scheduledGeneration)
        activeHoverRequest = request
        emitHoverPeekRequest(request)
    }

    private func schedulePeekCollapseIfNeeded() {
        guard
            !isPeekInteractionHeld,
            pendingCollapseCancellation == nil
        else {
            return
        }

        generation &+= 1
        let scheduledGeneration = generation
        pendingCollapseGeneration = scheduledGeneration
        pendingCollapseCancellation = scheduleActivation(peekCollapseGraceSeconds) { [weak self] in
            self?.completePeekCollapse(generation: scheduledGeneration)
        }
    }

    private func cancelPendingCollapse() {
        pendingCollapseCancellation?()
        pendingCollapseCancellation = nil
        pendingCollapseGeneration = nil
    }

    private func completePeekCollapse(generation scheduledGeneration: UInt64) {
        guard
            !isInvalidated,
            !isPeekInteractionHeld,
            pendingCollapseGeneration == scheduledGeneration
        else {
            return
        }

        pendingCollapseCancellation = nil
        pendingCollapseGeneration = nil
        emitIntent(.pointerExitCollapse)
    }
}
