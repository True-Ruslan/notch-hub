import AppKit
import Combine
import Dispatch
import SwiftUI

public typealias NotchPanelContentFactory =
    @MainActor (NotchPanelModel, NotchPanelLayoutModel) -> NSView

@MainActor
private final class NotchHoverPeekRequestRelay {
    var handler: (@MainActor @Sendable (NotchHoverPeekRequest) -> Void)?

    func emit(_ request: NotchHoverPeekRequest) {
        handler?(request)
    }
}

@MainActor
public final class NotchPanelController: NSObject {
    let panel: NSPanel
    private let interactionCoordinator: NotchInteractionCoordinator
    private let transitionCoordinator: NotchPanelTransitionCoordinator
    private let pointerMonitor: NotchPointerMonitor
    private let layoutModel: NotchPanelLayoutModel
    private let hoverPeekRequestRelay: NotchHoverPeekRequestRelay
    private var reduceMotionEnabled: Bool
    private let settingsStore: NotchHubSettingsStore?
    private var settingsSubscription: AnyCancellable?

    public var settledPresentationHandler: (@MainActor @Sendable (NotchPresentation) -> Void)? {
        didSet {
            transitionCoordinator.settledPresentationHandler = settledPresentationHandler
        }
    }

    public var hoverPeekRequestHandler: (@MainActor @Sendable (NotchHoverPeekRequest) -> Void)? {
        get {
            hoverPeekRequestRelay.handler
        }
        set {
            hoverPeekRequestRelay.handler = newValue
        }
    }

    public override convenience init() {
        self.init { model, layoutModel in
            NotchHostingViewFactory.make(model: model, layoutModel: layoutModel)
        }
    }

    public convenience init(
        contentFactory: @escaping NotchPanelContentFactory,
        settingsStore: NotchHubSettingsStore? = nil
    ) {
        let haptics = AppKitNotchHapticPerformer()
        self.init(
            contentFactory: contentFactory,
            performExpansionHaptic: {
                haptics.performExpansionHaptic()
            },
            settingsStore: settingsStore,
            internalInitialization: ()
        )
    }

    #if NOTCHHUB_UI_TESTING
        public convenience init(
            contentFactory: @escaping NotchPanelContentFactory,
            performExpansionHaptic: @escaping @MainActor () -> Void,
            settingsStore: NotchHubSettingsStore? = nil
        ) {
            self.init(
                contentFactory: contentFactory,
                performExpansionHaptic: performExpansionHaptic,
                settingsStore: settingsStore,
                internalInitialization: ()
            )
        }
    #endif

    private init(
        contentFactory: @escaping NotchPanelContentFactory,
        performExpansionHaptic: @escaping @MainActor () -> Void,
        settingsStore: NotchHubSettingsStore?,
        internalInitialization _: Void
    ) {
        let manualDisplayOverride =
            settingsStore?.settings.preferredDisplayOverride ?? .automatic
        guard
            let resolvedLayout = Self.preferredBaseLayout(manualOverride: manualDisplayOverride)
        else {
            preconditionFailure("NotchHub requires at least one available screen")
        }

        let layoutModel = NotchPanelLayoutModel(baseLayout: resolvedLayout)
        let model = NotchPanelModel()
        let panel = NSPanel(
            contentRect: resolvedLayout.compactFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        let hostingView = contentFactory(model, layoutModel)
        panel.contentView = hostingView

        let workspace = NSWorkspace.shared
        let initialReduceMotion = effectiveReduceMotion(
            systemValue: workspace.accessibilityDisplayShouldReduceMotion,
            override: settingsStore?.settings.reduceMotionOverride ?? .system
        )
        let transitionCoordinator = NotchPanelTransitionCoordinator(
            model: model,
            animationDuration: { [weak settingsStore] in
                notchAnimationDuration(
                    reduceMotion: effectiveReduceMotion(
                        systemValue: workspace.accessibilityDisplayShouldReduceMotion,
                        override: settingsStore?.settings.reduceMotionOverride ?? .system
                    )
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
            performExpansionHaptic: performExpansionHaptic,
            applyInteractivePresentation: { frame, cornerRadius in
                applyInteractiveNotchPanelPresentation(
                    panel: panel,
                    chromeView: hostingView,
                    frame: frame,
                    cornerRadius: cornerRadius
                )
            },
            applySettledPresentation: { frame, cornerRadius in
                applySettledNotchPanelPresentation(
                    panel: panel,
                    chromeView: hostingView,
                    frame: frame,
                    cornerRadius: cornerRadius
                )
            }
        )
        let hoverPeekRequestRelay = NotchHoverPeekRequestRelay()
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
            emitHoverPeekRequest: { request in
                hoverPeekRequestRelay.emit(request)
            },
            emitIntent: { intent in
                transitionCoordinator.accept(intent, layout: layoutModel.currentLayout)
            }
        )

        self.panel = panel
        self.interactionCoordinator = interactionCoordinator
        self.transitionCoordinator = transitionCoordinator
        self.pointerMonitor = NotchPointerMonitor()
        self.layoutModel = layoutModel
        self.hoverPeekRequestRelay = hoverPeekRequestRelay
        self.reduceMotionEnabled = initialReduceMotion
        self.settingsStore = settingsStore

        super.init()

        configureAccessibilityObservation()
        configureSettingsObservation()
        configureDisplayObservation()
        configurePanel()
        configureLocalPointerTracking(hostingView)
        configurePointerMonitoring()
        scheduleColdLaunchTopologyRecheck()
    }

    /// `preferredBaseLayout()` above already ran synchronously during this
    /// very initializer. On some cold launches `NSScreen.screens`' auxiliary
    /// safe-area rects (used to detect the physical hardware notch) are not
    /// yet populated at that point, producing a wrong-centered/wrong-width
    /// base layout that would otherwise only self-correct once AppKit
    /// happens to post a later `didChangeScreenParametersNotification` —
    /// visibly, since by then real content may already be showing. Re-check
    /// once on the very next run loop turn, reusing the same tested
    /// migration path `displayParametersDidChange(_:)` already uses, whose
    /// correction is an instant, non-animated settle rather than a visible
    /// snap. A single one-shot dispatch, not a repeating timer/poll.
    private func scheduleColdLaunchTopologyRecheck() {
        DispatchQueue.main.async { [weak self] in
            self?.migrateToPreferredDisplayIfNeeded()
        }
    }

    public func show() {
        panel.orderFrontRegardless()
        interactionCoordinator.pointerMoved(
            to: NSEvent.mouseLocation,
            layout: layoutModel.currentLayout,
            currentPresentation: transitionCoordinator.desiredPresentation
        )
    }

    public func setCompactHorizontalExtension(_ extensionWidth: CGFloat) {
        guard layoutModel.setCompactHorizontalExtension(extensionWidth) else {
            return
        }

        transitionCoordinator.animationPolicyDidChange(layout: layoutModel.currentLayout)
    }

    public func resolveHoverPeekRequest(
        _ request: NotchHoverPeekRequest,
        mediaAvailable: Bool
    ) {
        let accepted = interactionCoordinator.resolveHoverPeekRequest(
            request,
            mediaAvailable: mediaAvailable,
            layout: layoutModel.currentLayout,
            currentPresentation: transitionCoordinator.desiredPresentation
        )
        guard accepted else {
            return
        }

        transitionCoordinator.requestPeek(layout: layoutModel.currentLayout)
    }

    public func setPeekInteractionHeld(_ held: Bool) {
        interactionCoordinator.setPeekInteractionHeld(
            held,
            layout: layoutModel.currentLayout,
            currentPresentation: transitionCoordinator.desiredPresentation
        )
    }

    public func requestExpansion() {
        interactionCoordinator.cancelPendingActivationForInteractiveTransition()
        transitionCoordinator.requestProgrammaticExpansion(layout: layoutModel.currentLayout)
    }

    public func requestCollapse() {
        interactionCoordinator.cancelPendingActivationForInteractiveTransition()
        transitionCoordinator.requestProgrammaticCollapse(layout: layoutModel.currentLayout)
    }

    public func cancelPendingHoverActivation() {
        interactionCoordinator.cancelPendingActivationForInteractiveTransition()
    }

    @discardableResult
    public func beginInteractiveExpansion() -> Bool {
        let didBegin = transitionCoordinator.beginInteractiveTransition(
            from: .compact,
            layout: layoutModel.currentLayout
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
            layout: layoutModel.currentLayout
        )
        if didBegin {
            interactionCoordinator.cancelPendingActivationForInteractiveTransition()
        }
        return didBegin
    }

    public func updateInteractiveTransition(
        verticalDistance: CGFloat,
        pointer: CGPoint
    ) {
        transitionCoordinator.updateInteractiveTransition(
            verticalDistance: verticalDistance,
            layout: layoutModel.currentLayout
        )
        collapseInteractiveTransitionIfPointerExited(pointer)
    }

    public func finishInteractiveTransition(commit: Bool) {
        transitionCoordinator.finishInteractiveTransition(
            commit: commit,
            layout: layoutModel.currentLayout
        )
    }

    public func invalidate() {
        settledPresentationHandler = nil
        hoverPeekRequestHandler = nil
        settingsSubscription = nil
        removeDisplayObserver()
        removeLocalPointerTracking()
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

    @objc private func accessibilityDisplayOptionsDidChange(_: Notification) {
        applyEffectiveReduceMotionIfChanged()
    }

    private func removeAccessibilityObserver() {
        let workspace = NSWorkspace.shared
        workspace.notificationCenter.removeObserver(
            self,
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: workspace
        )
    }

    private func configureSettingsObservation() {
        guard let settingsStore else {
            return
        }
        settingsSubscription = settingsStore.$settings.sink { [weak self] _ in
            self?.applyEffectiveReduceMotionIfChanged()
            self?.migrateToPreferredDisplayIfNeeded()
        }
    }

    private func applyEffectiveReduceMotionIfChanged() {
        let reduceMotion = effectiveReduceMotion(
            systemValue: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
            override: settingsStore?.settings.reduceMotionOverride ?? .system
        )
        guard reduceMotion != reduceMotionEnabled else {
            return
        }

        reduceMotionEnabled = reduceMotion
        transitionCoordinator.animationPolicyDidChange(layout: layoutModel.currentLayout)
    }

    private func configureDisplayObservation() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayParametersDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: NSApplication.shared
        )
    }

    @objc private func displayParametersDidChange(_: Notification) {
        migrateToPreferredDisplayIfNeeded()
    }

    private func removeDisplayObserver() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didChangeScreenParametersNotification,
            object: NSApplication.shared
        )
    }

    private func migrateToPreferredDisplayIfNeeded() {
        let manualDisplayOverride =
            settingsStore?.settings.preferredDisplayOverride ?? .automatic
        guard
            let newBaseLayout = Self.preferredBaseLayout(manualOverride: manualDisplayOverride),
            newBaseLayout != layoutModel.baseLayout
        else {
            return
        }

        let newEffectiveLayout = layoutModel.effectiveLayout(
            replacingBaseLayout: newBaseLayout
        )

        interactionCoordinator.resetPointerStateForDisplayMigration()
        pointerMonitor.resetInteractionEscapeMonitoring()
        transitionCoordinator.displayLayoutDidChange(newEffectiveLayout)
        _ = layoutModel.updateBaseLayout(newBaseLayout)
    }

    private static func preferredBaseLayout(
        manualOverride: NotchHubSettings.PreferredDisplayOverride = .automatic
    ) -> NotchLayout? {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            return nil
        }

        let fallbackIndex = NSScreen.main.flatMap { mainScreen in
            screens.firstIndex(where: { $0 === mainScreen })
        }
        let screenInputs = screens.map { ScreenGeometryInput(screen: $0) }
        guard
            let selectedIndex = NotchScreenSelection.preferredIndex(
                in: screenInputs,
                fallbackIndex: fallbackIndex,
                manualOverride: manualOverride
            ),
            screenInputs.indices.contains(selectedIndex)
        else {
            return nil
        }

        return NotchGeometry.layout(for: screenInputs[selectedIndex])
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

    private func configureLocalPointerTracking(_ hostingView: NSView) {
        guard let trackingView = hostingView as? any NotchLocalPointerTracking else {
            return
        }

        trackingView.onNotchPointerEvent = { [weak self] pointer in
            self?.pointerMonitor.handleTrackedPointer(pointer)
        }
    }

    private func removeLocalPointerTracking() {
        guard let trackingView = panel.contentView as? any NotchLocalPointerTracking else {
            return
        }

        trackingView.onNotchPointerEvent = nil
    }

    private func configurePointerMonitoring() {
        pointerMonitor.start(
            shouldRetainGlobalMonitoring: { [weak self] pointer in
                self?.shouldRetainGlobalPointerMonitoring(for: pointer) ?? false
            },
            handler: { [weak self] pointer in
                self?.updateInteraction(for: pointer)
            }
        )
    }

    private func shouldRetainGlobalPointerMonitoring(for pointer: CGPoint) -> Bool {
        if transitionCoordinator.isInteractiveTransitionActive {
            return NotchPointerPolicy.containsInteractivePointer(pointer, in: panel.frame)
        }

        return NotchPointerPolicy.presentation(
            current: transitionCoordinator.desiredPresentation,
            pointer: pointer,
            layout: layoutModel.currentLayout
        ) != .compact
    }

    private func updateInteraction(for pointer: CGPoint) {
        if transitionCoordinator.isInteractiveTransitionActive {
            collapseInteractiveTransitionIfPointerExited(pointer)
            return
        }

        interactionCoordinator.pointerMoved(
            to: pointer,
            layout: layoutModel.currentLayout,
            currentPresentation: transitionCoordinator.desiredPresentation
        )
    }

    private func collapseInteractiveTransitionIfPointerExited(_ pointer: CGPoint) {
        guard
            transitionCoordinator.isInteractiveTransitionActive,
            !NotchPointerPolicy.containsInteractivePointer(pointer, in: panel.frame)
        else {
            return
        }

        interactionCoordinator.cancelPendingActivationForInteractiveTransition()
        transitionCoordinator.accept(.pointerExitCollapse, layout: layoutModel.currentLayout)
    }
}
