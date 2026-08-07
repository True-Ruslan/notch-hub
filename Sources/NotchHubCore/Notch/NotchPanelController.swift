import AppKit
import Combine
import SwiftUI

@MainActor
public final class NotchPanelController: NSObject {
    private let panel: NSPanel
    private let model: NotchPanelModel
    private var layout: NotchLayout
    private var cancellables = Set<AnyCancellable>()
    private var localPointerMonitor: Any?
    private var globalPointerMonitor: Any?

    public override init() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let geometry = ScreenGeometryInput(screen: screen)
        let resolvedLayout = NotchGeometry.layout(for: geometry)
        let model = NotchPanelModel()

        self.layout = resolvedLayout
        self.model = model
        self.panel = NSPanel(
            contentRect: resolvedLayout.compactFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init()
        configurePanel()
        bindModel()
        configurePointerMonitoring()
    }

    public func show() {
        panel.orderFrontRegardless()
        updatePresentation(for: NSEvent.mouseLocation)
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

        let rootView = NotchRootView(model: model)
        panel.contentView = NSHostingView(rootView: rootView)
    }

    private func bindModel() {
        model.$presentation
            .removeDuplicates()
            .sink { [weak self] presentation in
                self?.apply(presentation)
            }
            .store(in: &cancellables)
    }

    private func configurePointerMonitoring() {
        let mask: NSEvent.EventTypeMask = .mouseMoved

        localPointerMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            let pointer = NSEvent.mouseLocation
            Task { @MainActor [weak self] in
                self?.updatePresentation(for: pointer)
            }
            return event
        }

        globalPointerMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
            let pointer = NSEvent.mouseLocation
            Task { @MainActor [weak self] in
                self?.updatePresentation(for: pointer)
            }
        }
    }

    private func updatePresentation(for pointer: CGPoint) {
        let target = NotchPointerPolicy.presentation(
            current: model.presentation,
            pointer: pointer,
            layout: layout
        )
        model.setHovered(target == .expanded)
    }

    private func apply(_ presentation: NotchPresentation) {
        let targetFrame = presentation == .compact ? layout.compactFrame : layout.expandedFrame
        panel.setFrame(targetFrame, display: true, animate: true)
    }
}
