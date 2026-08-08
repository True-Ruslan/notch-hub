import AppKit
import Dispatch
import SwiftUI

@MainActor
public final class NotchPanelController: NSObject {
    private let panel: NSPanel
    private let interactionCoordinator: NotchInteractionCoordinator
    private let transitionCoordinator: NotchPanelTransitionCoordinator
    private let pointerMonitor: NotchPointerMonitor
    private let layout: NotchLayout
    private var reduceMotionEnabled: Bool

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

        let workspace = NSWorkspace.shared
        let initialReduceMotion = workspace.accessibilityDisplayShouldReduceMotion
        let haptics = AppKitNotchHapticPerformer()
        let transitionCoordinator = NotchPanelTransitionCoordinator(
            model: model,
            animationDuration: {
                notchAnimationDuration(
                    reduceMotion: workspace.accessibilityDisplayShouldReduceMotion
                )
            },
            animate: { frame, cornerRadius, duration, completion in
                animateNotchPanel(
                    panel: panel,
                    chromeView: hostingView,
                    frame: frame,
                    cornerRadius: cornerRadius,
                    duration: duration,
                    completion: completion
                )
            },
            cancelAnimation: {
                cancelNotchPanelAnimation(chromeView: hostingView)
            },
            performExpansionHaptic: {
                haptics.performExpansionHaptic()
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
            emitIntent: { intent in
                transitionCoordinator.accept(intent, layout: resolvedLayout)
            }
        )

        self.panel = panel
        self.interactionCoordinator = interactionCoordinator
        self.transitionCoordinator = transitionCoordinator
        self.pointerMonitor = NotchPointerMonitor()
        self.layout = resolvedLayout
        self.reduceMotionEnabled = initialReduceMotion

        super.init()

        configureAccessibilityObservation()
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
        removeAccessibilityObserver()
    }

    private func configureAccessibilityObservation() {
        let workspace = NSWorkspace.shared
        workspace.notificationCenter.addObserver(
            self,
            selector: #selector(accessibilityDisplayOptionsDidChange(_:)),
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: workspace
        )
    }

    @objc private func accessibilityDisplayOptionsDidChange(_ notification: Notification) {
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        guard reduceMotion != reduceMotionEnabled else {
            return
        }

        reduceMotionEnabled = reduceMotion
        transitionCoordinator.animationPolicyDidChange(layout: layout)
    }

    private func removeAccessibilityObserver() {
        let workspace = NSWorkspace.shared
        workspace.notificationCenter.removeObserver(
            self,
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: workspace
        )
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
