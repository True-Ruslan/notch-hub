import AppKit
import Dispatch
import SwiftUI

@MainActor
public final class NotchPanelController: NSObject {
    private let panel: NSPanel
    private let interactionCoordinator: NotchInteractionCoordinator
    private let transitionCoordinator: NotchPanelTransitionCoordinator
    private let animationDurationProvider: NotchAnimationDurationProvider
    private let pointerMonitor: NotchPointerMonitor
    private let layout: NotchLayout

    public override init() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let resolvedLayout = NotchGeometry.layout(
            for: ScreenGeometryInput(screen: screen)
        )
        let model = NotchPanelModel()
        let panel = NSPanel(
            contentRect: resolvedLayout.compactFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        let hostingView = NotchHostingViewFactory.make(
            model: model,
            layout: resolvedLayout
        )
        panel.contentView = hostingView

        let animationDurationProvider = NotchAnimationDurationProvider.live()
        let animationDriver = AppKitNotchPanelAnimationDriver(
            panel: panel,
            chromeView: hostingView
        )
        let haptics = AppKitNotchHapticPerformer()
        let transitionCoordinator = NotchPanelTransitionCoordinator(
            model: model,
            animationDuration: { [weak animationDurationProvider] in
                animationDurationProvider?.currentDuration ?? 0
            },
            animate: { [weak animationDriver] frame, cornerRadius, duration, completion in
                guard let animationDriver else {
                    completion()
                    return
                }
                animationDriver.animate(
                    frame: frame,
                    cornerRadius: cornerRadius,
                    duration: duration,
                    completion: completion
                )
            },
            cancelAnimation: { [weak animationDriver] in
                animationDriver?.cancel()
            },
            performExpansionHaptic: { [weak haptics] in
                haptics?.performExpansionHaptic()
            }
        )
        let interactionCoordinator = NotchInteractionCoordinator(
            scheduleActivation: { delaySeconds, action in
                let workItem = DispatchWorkItem {
                    MainActor.assumeIsolated {
                        action()
                    }
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + delaySeconds,
                    execute: workItem
                )
                return { workItem.cancel() }
            },
            emitIntent: { [weak transitionCoordinator] intent in
                transitionCoordinator?.accept(intent, layout: resolvedLayout)
            }
        )

        self.panel = panel
        self.interactionCoordinator = interactionCoordinator
        self.transitionCoordinator = transitionCoordinator
        self.animationDurationProvider = animationDurationProvider
        self.pointerMonitor = NotchPointerMonitor()
        self.layout = resolvedLayout

        super.init()

        animationDurationProvider.onDurationChange = { [weak transitionCoordinator] _ in
            transitionCoordinator?.animationPolicyDidChange(layout: resolvedLayout)
        }
        configurePanel()
        configurePointerMonitoring()
    }

    public func show() {
        panel.orderFrontRegardless()
        interactionCoordinator.pointerMoved(
            to: NSEvent.mouseLocation,
            layout: layout,
            currentPresentation: transitionCoordinator.desiredPresentation,
            allowActivation: false
        )
    }

    func invalidate() {
        pointerMonitor.invalidate()
        interactionCoordinator.invalidate()
        transitionCoordinator.invalidate()
        animationDurationProvider.invalidate()
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
            currentPresentation: transitionCoordinator.desiredPresentation
        )
    }
}
