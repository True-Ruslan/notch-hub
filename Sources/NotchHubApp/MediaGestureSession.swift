import AppKit
import NotchHubCore
import NotchHubMediaCore

@MainActor
final class MediaGestureSession {
    private enum ActivePanelInteraction {
        case expansion
        case collapse
    }

    private let coordinator: MediaGestureCoordinator
    private let compactDispatcher: ShippingMediaCompactCommandDispatcher
    private let visualModel: MediaGestureVisualModel
    private let performArmHaptic: @MainActor () -> Void

    private weak var panelController: NotchPanelController?
    private weak var panelModel: NotchPanelModel?
    private var runtimeProvider: @MainActor () -> ShippingMediaRuntime? = { nil }
    private var presentationProvider: @MainActor () -> ShippingMediaPresentation? = { nil }

    private var activeSurface: MediaGestureSurface?
    private var activePanelInteraction: ActivePanelInteraction?
    private var compactCapabilityTask: Task<Void, Never>?
    private var isInvalidated = false

    init(
        coordinator: MediaGestureCoordinator = MediaGestureCoordinator(),
        compactDispatcher: ShippingMediaCompactCommandDispatcher,
        visualModel: MediaGestureVisualModel,
        performArmHaptic: @escaping @MainActor () -> Void
    ) {
        self.coordinator = coordinator
        self.compactDispatcher = compactDispatcher
        self.visualModel = visualModel
        self.performArmHaptic = performArmHaptic
    }

    func bind(
        panelController: NotchPanelController,
        panelModel: NotchPanelModel,
        runtimeProvider: @escaping @MainActor () -> ShippingMediaRuntime?,
        presentationProvider: @escaping @MainActor () -> ShippingMediaPresentation?
    ) {
        guard !isInvalidated else {
            return
        }

        self.panelController = panelController
        self.panelModel = panelModel
        self.runtimeProvider = runtimeProvider
        self.presentationProvider = presentationProvider
    }

    func handleScrollWheel(_ event: NSEvent) {
        guard
            !isInvalidated,
            event.hasPreciseScrollingDeltas,
            event.momentumPhase.isEmpty,
            let phase = Self.gesturePhase(for: event.phase)
        else {
            return
        }

        if phase == .began {
            beginPhysicalGesture()
        }

        guard let surface = activeSurface else {
            return
        }

        let directionScale: CGFloat = event.isDirectionInvertedFromDevice ? -1 : 1
        let deltaX = Double(event.scrollingDeltaX * directionScale)
        let deltaY = Double(event.scrollingDeltaY * directionScale)
        let interactiveWidth = Double(event.window?.contentView?.bounds.width ?? 0)
        let capabilities = liveCapabilities(for: surface)

        let effects = coordinator.handle(
            MediaGestureSample(
                phase: phase,
                deltaX: deltaX,
                deltaY: deltaY,
                interactiveWidth: interactiveWidth,
                isMomentum: false
            ),
            surface: surface,
            previous: capabilities.previous,
            next: capabilities.next,
            seekActive: false
        )
        let panelCommit = handleEffects(effects, surface: surface)

        switch phase {
        case .ended:
            finishPanelInteraction(commit: panelCommit)
            activeSurface = nil
            compactCapabilityTask?.cancel()
            compactCapabilityTask = nil
        case .cancelled:
            finishPanelInteraction(commit: false)
            activeSurface = nil
            compactCapabilityTask?.cancel()
            compactCapabilityTask = nil
        case .began, .changed:
            break
        }
    }

    func invalidate() {
        guard !isInvalidated else {
            return
        }

        isInvalidated = true
        compactCapabilityTask?.cancel()
        compactCapabilityTask = nil
        _ = coordinator.invalidate()
        visualModel.reset()
        finishPanelInteraction(commit: false)
        compactDispatcher.stop()

        activeSurface = nil
        panelController = nil
        panelModel = nil
        runtimeProvider = { nil }
        presentationProvider = { nil }
    }

    private func beginPhysicalGesture() {
        compactCapabilityTask?.cancel()
        compactCapabilityTask = nil
        finishPanelInteraction(commit: false)
        _ = coordinator.invalidate()
        visualModel.reset()

        guard let panelModel else {
            activeSurface = nil
            return
        }

        switch panelModel.contentPresentation {
        case .compact:
            activeSurface = .compact
        case .expanded:
            activeSurface = .expanded
        }
    }

    private func handleEffects(
        _ effects: [MediaGestureEffect],
        surface: MediaGestureSurface
    ) -> Bool {
        var panelCommit = false

        for effect in effects {
            switch effect {
            case .requestCompactCapability(let gestureID, let direction):
                requestCompactCapability(
                    gestureID: gestureID,
                    direction: direction,
                    surface: surface
                )

            case .requestArmHaptic:
                performArmHaptic()

            case .commit(let direction):
                commitMediaCommand(direction, surface: surface)

            case .requestExpansion:
                if surface == .compact {
                    panelCommit = true
                }

            case .requestCollapse:
                if surface == .expanded {
                    panelCommit = true
                }

            case .visualOffset(let value):
                visualModel.setHorizontalOffset(CGFloat(value), surface: surface)

            case .panelVisualOffset(let value):
                updatePanelInteraction(
                    verticalOffset: CGFloat(value),
                    surface: surface
                )

            case .resetVisualOffset:
                visualModel.reset()
            }
        }

        return panelCommit
    }

    private func requestCompactCapability(
        gestureID: UInt64,
        direction: MediaGestureDirection,
        surface: MediaGestureSurface
    ) {
        guard surface == .compact else {
            return
        }

        compactCapabilityTask?.cancel()
        let action = compactAction(for: direction)
        compactCapabilityTask = Task { [weak self] in
            guard let self else {
                return
            }

            let supported = await compactDispatcher.isSupported(action)
            guard !Task.isCancelled else {
                return
            }

            let effects = coordinator.resolveCompactCapability(
                gestureID: gestureID,
                direction: direction,
                supported: supported
            )
            _ = handleEffects(effects, surface: surface)
        }
    }

    private func commitMediaCommand(
        _ direction: MediaGestureDirection,
        surface: MediaGestureSurface
    ) {
        switch surface {
        case .compact:
            let dispatcher = compactDispatcher
            let action = compactAction(for: direction)
            Task {
                _ = await dispatcher.send(action)
            }

        case .expanded:
            switch direction {
            case .previous:
                runtimeProvider()?.goPrevious()
            case .next:
                runtimeProvider()?.goNext()
            }
        }
    }

    private func updatePanelInteraction(
        verticalOffset: CGFloat,
        surface: MediaGestureSurface
    ) {
        guard let panelController else {
            return
        }

        switch surface {
        case .compact:
            guard verticalOffset > 0 || activePanelInteraction == .expansion else {
                return
            }
            if activePanelInteraction == nil {
                guard panelController.beginInteractiveExpansion() else {
                    return
                }
                activePanelInteraction = .expansion
            }
            guard activePanelInteraction == .expansion else {
                return
            }
            panelController.updateInteractiveTransition(
                verticalDistance: max(0, verticalOffset)
            )

        case .expanded:
            guard verticalOffset < 0 || activePanelInteraction == .collapse else {
                return
            }
            if activePanelInteraction == nil {
                guard panelController.beginInteractiveCollapse() else {
                    return
                }
                activePanelInteraction = .collapse
            }
            guard activePanelInteraction == .collapse else {
                return
            }
            panelController.updateInteractiveTransition(
                verticalDistance: max(0, -verticalOffset)
            )
        }
    }

    private func finishPanelInteraction(commit: Bool) {
        guard activePanelInteraction != nil else {
            return
        }
        panelController?.finishInteractiveTransition(commit: commit)
        activePanelInteraction = nil
    }

    private func liveCapabilities(
        for surface: MediaGestureSurface
    ) -> (previous: MediaGestureCapability, next: MediaGestureCapability) {
        guard surface == .expanded, let presentation = presentationProvider() else {
            return (.pending, .pending)
        }

        return (
            presentation.canGoPrevious ? .supported : .unavailable,
            presentation.canGoNext ? .supported : .unavailable
        )
    }

    private func compactAction(
        for direction: MediaGestureDirection
    ) -> ShippingMediaCompactCommandAction {
        switch direction {
        case .previous:
            return .previous
        case .next:
            return .next
        }
    }

    private static func gesturePhase(for phase: NSEvent.Phase) -> MediaGesturePhase? {
        switch phase {
        case .began:
            return .began
        case .changed:
            return .changed
        case .ended:
            return .ended
        case .cancelled:
            return .cancelled
        default:
            return nil
        }
    }
}
