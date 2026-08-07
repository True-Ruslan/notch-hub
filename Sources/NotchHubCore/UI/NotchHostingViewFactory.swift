import SwiftUI

@MainActor
enum NotchHostingViewFactory {
    static func make(model: NotchPanelModel) -> NSHostingView<NotchRootView> {
        let hostingView = NSHostingView(rootView: NotchRootView(model: model))
        hostingView.sizingOptions = []
        return hostingView
    }
}
