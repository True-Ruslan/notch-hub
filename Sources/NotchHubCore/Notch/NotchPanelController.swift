import AppKit
import Dispatch
import SwiftUI

public typealias NotchPanelContentFactory = @MainActor (NotchPanelModel, NotchLayout) -> NSView

private final class NotchPanelLayoutState {
    let baseLayout: NotchLayout
    var compactHorizontalExtension: CGFloat = 0

    init(baseLayout: NotchLayout) {
        self.baseLayout = baseLayout
    }

    var currentLayout: NotchLayout {
        baseLayout.withCompactHorizontalExtension(compactHorizontalExtension)
    }
}

@MainActor
public final class NotchPanelController: NSObject {
    private let panel: NSPanel
    private let interactionCoordinator: NotchInteractionCoordinator
    private let transitionCoordinator: NotchPanelTransitionCoordinator
    private let pointerMonitor: NotchPointerMonitor
    private let layoutState: NotchPanelLayoutState
    private var reduceMotionEnabled: Bool

    public var settledPresentationHandler: (@MainActor @Sendable (NotchPresentation) -> Void)? {
        didSet {
            transitionCoordinator.settledPresentationHandler = settledPresentationHandler
        }
    }

    public override convenience init() {
        self.init { model, layout in
            NotchHostingViewFactory.make(model: model, layout: layout)
        }
    }

    public init(contentFactory: @escaping NotchPanelContentFactory) {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let resolvedLayout = NotchGeometry.layout(
            for: ScreenGeometryInput(screen: screen)
        )
        let layoutState = NotchPanelLayoutState(baseLayout: resolvedLayout)
        let model = NotchPanelModel()
        let panel = NSPanel(
            contentRect: resolvedLayout.compactFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        let hostingView = contentFactory(model, resolvedLayout)
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
            },
            applyInteractivePresentation: { frame, cornerRadius in
                applyInteractiveNotchPanelPresentation(
                    panel: panel,
                    chromeView: hostingView,
                    frame: frame,
                    cornerRadius: cornerRadius
                )
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
                transitionCoordinator.accept(intent, layout: layoutState.currentLayout)
            }
        )

        self.panel = panel
        self.interactionCoordinator = interactionCoordinator
        self.transitionCoordinator = transitionCoordinator
        self.pointerMonitor = NotchPointerMonitor()
        self.layoutState = layoutState
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
            layout: layoutState.currentLayout,
            currentPresentation: transitionCoordinator.desiredPresentation,
            allowActivation: false
        )
    }

    public func setCompactHorizontalExtension(_ extensionWidth: CGFloat) {
        let boundedExtension = max(0, extensionWidth)
        guard boundedExtension != layoutState.compactHorizontalExtension else {
            return
        }

        layoutState.compactHorizontalExtension = boundedExtension
        transitionCoordinator.animationPolicyDidChange(layout: layoutState.currentLayout)
    }

    public func requestExpansion() {
        transitionCoordinator.requestProgrammaticExpansion(layout: layoutState.currentLayout)
    }

    public func requestCollapse() {
        transitionCoordinator.requestProgrammaticCollapse(layout: layoutState.currentLayout)
    }

    public func cancelPendingHoverActivation() {
        interactionCoordinator.cancelPendingActivationForInteractiveTransition()
    }

    @discardableResult
    public func beginInteractiveExpansion() -> Bool {
        let didBegin = transitionCoordinator.beginInteractiveTransition(
            from: .compact,
            layout: layoutState.currentLayout
        )
        if didBegin {
            interactionCoordinator.cancelPendingActivationForInteractiveTransition()
        }
        return didBegin
    }

    @discardableResult
    public func beginInteractiveCollapse() -> Bool {
        let didBegin = transitionCoordinator.beginInteractiveTransition(
            from: .expanded,
            layout: layoutState.currentLayout
        )
        if didBegin {
            interactionCoordinator.cancelPendingActivationForInteractiveTransition()
        }
        return didBegin
    }

    public func updateInteractiveTransition(verticalDistance: CGFloat) {
        transitionCoordinator.updateInteractiveTransition(
            verticalDistance: verticalDistance,
            layout: layoutState.currentLayout
        )
    }

    public func finishInteractiveTransition(commit: Bool) {
        transitionCoordinator.finishInteractiveTransition(
            commit: commit,
            layout: layoutState.currentLayout
        )
    }

    public func invalidate() {
        settledPresentationHandler = nil
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
        transitionCoordinator.animationPolicyDidChange(layout: layoutState.currentLayout)
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
            layout: layoutState.currentLayout,
            currentPresentation: transitionCoordinator.desiredPresentation
        )
    }
}
