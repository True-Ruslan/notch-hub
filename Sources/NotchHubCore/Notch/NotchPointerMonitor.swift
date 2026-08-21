import AppKit
import CoreGraphics

@MainActor
final class NotchPointerMonitor {
    typealias Handler = @MainActor (CGPoint) -> Void
    typealias Registration = (@escaping Handler) -> Any?
    typealias Removal = (Any) -> Void

    private let addLocal: Registration
    private let addGlobal: Registration
    private let remove: Removal
    private var localMonitor: Any?
    private var globalEscapeMonitor: Any?
    private var eventHandler: Handler?
    private var isStarted = false

    init() {
        self.addLocal = { handler in
            NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { event in
                let pointer = NSEvent.mouseLocation
                MainActor.assumeIsolated {
                    handler(pointer)
                }
                return event
            }
        }
        self.addGlobal = { handler in
            NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { _ in
                let pointer = NSEvent.mouseLocation
                MainActor.assumeIsolated {
                    handler(pointer)
                }
            }
        }
        self.remove = { monitor in
            NSEvent.removeMonitor(monitor)
        }
    }

    init(
        addLocal: @escaping Registration,
        addGlobal: @escaping Registration,
        remove: @escaping Removal
    ) {
        self.addLocal = addLocal
        self.addGlobal = addGlobal
        self.remove = remove
    }

    func start(handler: @escaping Handler) {
        guard !isStarted else {
            return
        }

        isStarted = true
        eventHandler = handler
        localMonitor = addLocal { [weak self] pointer in
            self?.handleLocalPointer(pointer)
        }
    }

    func invalidate() {
        guard isStarted else {
            return
        }

        isStarted = false
        disarmGlobalEscapeMonitor()

        if let localMonitor {
            remove(localMonitor)
            self.localMonitor = nil
        }

        eventHandler = nil
    }

    private func handleLocalPointer(_ pointer: CGPoint) {
        guard isStarted else {
            return
        }

        armGlobalEscapeMonitorIfNeeded()
        eventHandler?(pointer)
    }

    private func armGlobalEscapeMonitorIfNeeded() {
        guard
            isStarted,
            globalEscapeMonitor == nil
        else {
            return
        }

        globalEscapeMonitor = addGlobal { [weak self] pointer in
            self?.handleGlobalEscape(pointer)
        }
    }

    private func handleGlobalEscape(_ pointer: CGPoint) {
        guard isStarted else {
            return
        }

        let handler = eventHandler
        disarmGlobalEscapeMonitor()
        handler?(pointer)
    }

    private func disarmGlobalEscapeMonitor() {
        guard let globalEscapeMonitor else {
            return
        }

        self.globalEscapeMonitor = nil
        remove(globalEscapeMonitor)
    }
}
