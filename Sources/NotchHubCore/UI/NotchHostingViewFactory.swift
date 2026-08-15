import AppKit
import SwiftUI

public typealias NotchLocalScrollHandler = @MainActor (NSEvent) -> Void
public typealias NotchLocalPointerHandler = @MainActor (CGPoint) -> Void

@MainActor
protocol NotchLocalPointerTracking: AnyObject {
    var onNotchPointerEvent: NotchLocalPointerHandler? { get set }
}

@MainActor
private final class NotchLocalInputHostingView<Content: View>: NSHostingView<Content>, NotchLocalPointerTracking {
    private let onScrollWheel: NotchLocalScrollHandler?
    private var pointerTrackingArea: NSTrackingArea?
    var onNotchPointerEvent: NotchLocalPointerHandler?

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

    override func updateTrackingAreas() {
        if let pointerTrackingArea {
            removeTrackingArea(pointerTrackingArea)
        }

        super.updateTrackingAreas()

        let trackingArea = NSTrackingArea(
            rect: .zero,
            options: [
                .mouseEnteredAndExited,
                .mouseMoved,
                .activeAlways,
                .inVisibleRect,
            ],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        pointerTrackingArea = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        emitPointerEvent()
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        emitPointerEvent()
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        emitPointerEvent()
    }

    override func scrollWheel(with event: NSEvent) {
        if let onScrollWheel {
            onScrollWheel(event)
        } else {
            super.scrollWheel(with: event)
        }
    }

    private func emitPointerEvent() {
        onNotchPointerEvent?(NSEvent.mouseLocation)
    }
}

@MainActor
public enum NotchHostingViewFactory {
    public static func make<Content: View>(
        rootView: Content,
        onScrollWheel: NotchLocalScrollHandler? = nil
    ) -> NSHostingView<Content> {
        let hostingView = NotchLocalInputHostingView(
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
