import SwiftUI

@MainActor
enum NotchHostingViewFactory {
    static func make(
        model: NotchPanelModel,
        layout: NotchLayout
    ) -> NSHostingView<NotchRootView> {
        let hostingView = NSHostingView(
            rootView: NotchRootView(
                model: model,
                hasHardwareNotch: layout.hasHardwareNotch,
                compactHeight: layout.compactFrame.height
            )
        )
        hostingView.sizingOptions = []
        return hostingView
    }
}
