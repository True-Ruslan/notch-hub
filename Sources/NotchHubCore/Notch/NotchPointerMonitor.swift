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
    private var globalMonitor: Any?
    private var isStarted = false

    init() {
        self.addLocal = { handler in
            NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { event in
                let pointer = NSEvent.mouseLocation
                Task { @MainActor in
                    handler(pointer)
                }
                return event
            }
        }
        self.addGlobal = { handler in
            NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { _ in
                let pointer = NSEvent.mouseLocation
                Task { @MainActor in
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
        localMonitor = addLocal(handler)
        globalMonitor = addGlobal(handler)
    }

    func invalidate() {
        guard isStarted else {
            return
        }

        isStarted = false

        if let localMonitor {
            remove(localMonitor)
            self.localMonitor = nil
        }

        if let globalMonitor {
            remove(globalMonitor)
            self.globalMonitor = nil
        }
    }
}
