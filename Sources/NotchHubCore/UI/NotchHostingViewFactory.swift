import SwiftUI

@MainActor
enum NotchHostingViewFactory {
    static func make(model: NotchPanelModel) -> NSHostingView<NotchRootView> {
        NSHostingView(rootView: NotchRootView(model: model))
    }
}
