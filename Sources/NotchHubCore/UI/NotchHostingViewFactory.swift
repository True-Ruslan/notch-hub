import AppKit
import SwiftUI

public typealias NotchLocalScrollHandler = @MainActor (NSEvent) -> Void

@MainActor
private final class NotchLocalScrollHostingView<Content: View>: NSHostingView<Content> {
    private let onScrollWheel: NotchLocalScrollHandler?

    required init(rootView: Content) {
        self.onScrollWheel = nil
        super.init(rootView: rootView)
    }

    init(
        rootView: Content,
        onScrollWheel: NotchLocalScrollHandler?
    ) {
        self.onScrollWheel = onScrollWheel
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func scrollWheel(with event: NSEvent) {
        guard let onScrollWheel else {
            super.scrollWheel(with: event)
            return
        }

        onScrollWheel(event)
    }
}

@MainActor
public enum NotchHostingViewFactory {
    public static func make<Content: View>(
        rootView: Content,
        onScrollWheel: NotchLocalScrollHandler? = nil
    ) -> NSHostingView<Content> {
        let hostingView = NotchLocalScrollHostingView(
            rootView: rootView,
            onScrollWheel: onScrollWheel
        )
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
