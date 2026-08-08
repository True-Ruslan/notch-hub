import SwiftUI

@MainActor
enum NotchHostingViewFactory {
    static func make(
        model: NotchPanelModel,
        layout: NotchLayout
    ) -> NSHostingView<NotchRootView> {
        let metrics = NotchVisualLayoutPolicy.metrics(
            hasHardwareNotch: layout.hasHardwareNotch,
            compactHeight: layout.compactFrame.height
        )
        let hostingView = NSHostingView(
            rootView: NotchRootView(model: model, visualMetrics: metrics)
        )
        hostingView.sizingOptions = []
        return hostingView
    }
}
