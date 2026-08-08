import AppKit
import SwiftUI

@MainActor
public final class NotchPanelController: NSObject {
    private let panel: NSPanel
    private let model: NotchPanelModel
    private let interactionCoordinator: NotchInteractionCoordinator
    private let pointerMonitor: NotchPointerMonitor
    private var layout: NotchLayout

    public override init() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let geometry = ScreenGeometryInput(screen: screen)
        let resolvedLayout = NotchGeometry.layout(for: geometry)
        let model = NotchPanelModel()
        let haptics = AppKitNotchHapticPerformer()
        let panel = NSPanel(
            contentRect: resolvedLayout.compactFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        let interactionCoordinator = NotchInteractionCoordinator(
            scheduler: MainQueueNotchActivationScheduler(),
            emitIntent: { intent in
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

                model.setContentPresentation(presentation)
                if let contentView = panel.contentView {
                    NotchHostingViewFactory.applyPresentation(
                        presentation,
                        to: contentView
                    )
                }
                let targetFrame =
                    presentation == .compact
                    ? resolvedLayout.compactFrame
                    : resolvedLayout.expandedFrame
                panel.setFrame(targetFrame, display: true)
                if hapticEligible {
                    haptics.performExpansionHaptic()
                }
            }
        )

        self.layout = resolvedLayout
        self.model = model
        self.interactionCoordinator = interactionCoordinator
        self.pointerMonitor = NotchPointerMonitor()
        self.panel = panel

        super.init()
        configurePanel()
        configurePointerMonitoring()
    }

    public func show() {
        panel.orderFrontRegardless()
        interactionCoordinator.pointerMoved(
            to: NSEvent.mouseLocation,
            layout: layout,
            currentPresentation: model.contentPresentation,
            allowActivation: false
        )
    }

    func invalidate() {
        pointerMonitor.invalidate()
        interactionCoordinator.invalidate()
    }

    private func configurePanel() {
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovable = false
        panel.acceptsMouseMovedEvents = true
        panel.contentView = NotchHostingViewFactory.make(model: model, layout: layout)
    }

    private func configurePointerMonitoring() {
        pointerMonitor.start { [weak self] pointer in
            self?.updateInteraction(for: pointer)
        }
    }

    private func updateInteraction(for pointer: CGPoint) {
        interactionCoordinator.pointerMoved(
            to: pointer,
            layout: layout,
            currentPresentation: model.contentPresentation
        )
    }
}
