import AppKit
import SwiftUI

public typealias NotchLocalScrollHandler = @MainActor (NSEvent) -> Void

@MainActor
private final class NotchLocalScrollHostingView<Content: View>: NSHostingView<Content> {
    private let onScrollWheel: NotchLocalScrollHandler

    required init(rootView: Content) {
        fatalError("Use init(rootView:onScrollWheel:) for local gesture input")
    }

    init(
        rootView: Content,
        onScrollWheel: @escaping NotchLocalScrollHandler
    ) {
        self.onScrollWheel = onScrollWheel
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func scrollWheel(with event: NSEvent) {
        onScrollWheel(event)
    }
}

@MainActor
public enum NotchHostingViewFactory {
    public static func make<Content: View>(
        rootView: Content,
        onScrollWheel: NotchLocalScrollHandler? = nil
    ) -> NSHostingView<Content> {
        let hostingView: NSHostingView<Content>
        if let onScrollWheel {
            hostingView = NotchLocalScrollHostingView(
                rootView: rootView,
                onScrollWheel: onScrollWheel
            )
        } else {
            hostingView = NSHostingView(rootView: rootView)
        }

        hostingView.sizingOptions = []
        hostingView.autoresizingMask = [.width, .height]
        hostingView.wantsLayer = true
        hostingView.layer?.masksToBounds = true
        hostingView.layer?.cornerCurve = .continuous
        hostingView.layer?.cornerRadius = 12
        return hostingView
    }

    static func make(
        model: NotchPanelModel,
        layout: NotchLayout
    ) -> NSHostingView<NotchRootView> {
        make(
            rootView: NotchRootView(
                model: model,
                compactBackgroundOpacity: layout.compactBackgroundOpacity,
                expandedContentTopInset: layout.expandedContentTopInset
            )
        )
    }
}
