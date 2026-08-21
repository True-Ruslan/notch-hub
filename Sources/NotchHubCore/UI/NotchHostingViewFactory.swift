import AppKit
import SwiftUI

public typealias NotchLocalScrollHandler = @MainActor (NSEvent) -> Void
public typealias NotchLocalPointerHandler = @MainActor (CGPoint) -> Void

@MainActor
protocol NotchLocalPointerTracking: AnyObject {
    var onNotchPointerEvent: NotchLocalPointerHandler? { get set }
}

@MainActor
private class NotchLocalPointerHostingView<Content: View>: NSHostingView<Content>, NotchLocalPointerTracking {
    private var pointerTrackingArea: NSTrackingArea?
    var onNotchPointerEvent: NotchLocalPointerHandler?

    required init(rootView: Content) {
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
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
                .inVisibleRect
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

    private func emitPointerEvent() {
        onNotchPointerEvent?(NSEvent.mouseLocation)
    }
}

@MainActor
private final class NotchLocalScrollHostingView<Content: View>: NotchLocalPointerHostingView<Content> {
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
            hostingView = NotchLocalPointerHostingView(rootView: rootView)
        }

        #if NOTCHHUB_UI_TESTING
            hostingView.setAccessibilityElement(true)
            hostingView.setAccessibilityRole(.group)
            hostingView.setAccessibilityIdentifier("notch.surface.hitTarget")
        #endif

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
        layoutModel: NotchPanelLayoutModel
    ) -> NSHostingView<NotchRootView> {
        make(
            rootView: NotchRootView(
                model: model,
                layoutModel: layoutModel
            )
        )
    }
}
