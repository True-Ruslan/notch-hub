import AppKit
import CoreGraphics

@MainActor
final class NotchPointerMonitor {
    typealias Handler = @MainActor (CGPoint) -> Void
    typealias Registration = (@escaping Handler) -> Any?
    typealias Removal = (Any) -> Void

    private let addLocal: Registration
    private let remove: Removal
    private var localMonitor: Any?
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
        self.remove = { monitor in
            NSEvent.removeMonitor(monitor)
        }
    }

    init(
        addLocal: @escaping Registration,
        remove: @escaping Removal
    ) {
        self.addLocal = addLocal
        self.remove = remove
    }

    func start(handler: @escaping Handler) {
        guard !isStarted else {
            return
        }

        isStarted = true
        localMonitor = addLocal(handler)
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
    }
}
