import AppKit
import CoreGraphics

@MainActor
protocol NotchEventMonitorBackend: AnyObject {
    func addLocalMouseMoved(
        handler: @escaping @MainActor (CGPoint) -> Void
    ) -> Any?

    func addGlobalMouseMoved(
        handler: @escaping @MainActor (CGPoint) -> Void
    ) -> Any?

    func removeMonitor(_ monitor: Any)
}

@MainActor
final class NotchPointerMonitor {
    private let backend: any NotchEventMonitorBackend
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var isStarted = false

    convenience init() {
        self.init(backend: AppKitNotchEventMonitorBackend())
    }

    init(backend: any NotchEventMonitorBackend) {
        self.backend = backend
    }

    func start(handler: @escaping @MainActor (CGPoint) -> Void) {
        guard !isStarted else {
            return
        }

        isStarted = true
        localMonitor = backend.addLocalMouseMoved(handler: handler)
        globalMonitor = backend.addGlobalMouseMoved(handler: handler)
    }

    func invalidate() {
        guard isStarted else {
            return
        }

        isStarted = false

        if let localMonitor {
            backend.removeMonitor(localMonitor)
            self.localMonitor = nil
        }

        if let globalMonitor {
            backend.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }
}

@MainActor
private final class AppKitNotchEventMonitorBackend: NotchEventMonitorBackend {
    func addLocalMouseMoved(
        handler: @escaping @MainActor (CGPoint) -> Void
    ) -> Any? {
        NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { event in
            let pointer = NSEvent.mouseLocation
            Task { @MainActor in
                handler(pointer)
            }
            return event
        }
    }

    func addGlobalMouseMoved(
        handler: @escaping @MainActor (CGPoint) -> Void
    ) -> Any? {
        NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { _ in
            let pointer = NSEvent.mouseLocation
            Task { @MainActor in
                handler(pointer)
            }
        }
    }

    func removeMonitor(_ monitor: Any) {
        NSEvent.removeMonitor(monitor)
    }
}
