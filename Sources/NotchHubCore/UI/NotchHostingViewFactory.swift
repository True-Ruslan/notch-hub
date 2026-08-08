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
        applyPresentation(.compact, to: hostingView)
        return hostingView
    }

    static func applyPresentation(_ presentation: NotchPresentation, to view: NSView) {
        view.wantsLayer = true
        view.layer?.masksToBounds = true
        view.layer?.cornerCurve = .continuous
        view.layer?.cornerRadius = presentation == .compact ? 12 : 22
    }
}
