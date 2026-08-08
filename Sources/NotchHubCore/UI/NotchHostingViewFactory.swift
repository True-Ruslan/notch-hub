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
                compactBackgroundOpacity: layout.compactBackgroundOpacity,
                expandedContentTopInset: layout.expandedContentTopInset
            )
        )
        hostingView.sizingOptions = []
        return hostingView
    }
}
