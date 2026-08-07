import AppKit
import Combine
import SwiftUI

@MainActor
public final class NotchPanelController: NSObject {
    private let panel: NSPanel
    private let model: NotchPanelModel
    private var layout: NotchLayout
    private var cancellables = Set<AnyCancellable>()

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
    }

    public func show() {
        panel.orderFrontRegardless()
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

    private func apply(_ presentation: NotchPresentation) {
        let targetFrame = presentation == .compact ? layout.compactFrame : layout.expandedFrame
        panel.setFrame(targetFrame, display: true, animate: true)
    }
}
