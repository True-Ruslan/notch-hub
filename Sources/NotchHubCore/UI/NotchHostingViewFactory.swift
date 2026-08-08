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
        hostingView.autoresizingMask = [.width, .height]
        hostingView.wantsLayer = true
        hostingView.layer?.masksToBounds = true
        hostingView.layer?.cornerCurve = .continuous
        hostingView.layer?.cornerRadius = 12
        return hostingView
    }
}
