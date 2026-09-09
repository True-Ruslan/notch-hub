import AppKit
import NotchHubCore

@MainActor
final class ShelfShareController: NSObject, NSSharingServicePickerDelegate, NSSharingServiceDelegate {
    private let accessSession: ShelfShareAccessSession
    private var picker: NSSharingServicePicker?

    init(accessSession: ShelfShareAccessSession = ShelfShareAccessSession()) {
        self.accessSession = accessSession
        super.init()
    }

    @discardableResult
    func present(url: URL) -> Bool {
        if picker != nil {
            close()
        }

        guard let anchorView = sharingAnchorView() else {
            return false
        }
        guard accessSession.begin(url: url) else {
            return false
        }

        let picker = NSSharingServicePicker(items: [url as NSURL])
        self.picker = picker
        picker.delegate = self

        NSApp.activate(ignoringOtherApps: true)
        picker.show(relativeTo: anchorView.bounds, of: anchorView, preferredEdge: .minY)
        return true
    }

    func close() {
        let activePicker = picker
        picker = nil
        activePicker?.delegate = nil
        activePicker?.close()
        accessSession.end()
    }

    func sharingServicePicker(
        _: NSSharingServicePicker,
        didChoose service: NSSharingService?
    ) {
        if service == nil {
            close()
        }
    }

    func sharingServicePicker(
        _: NSSharingServicePicker,
        delegateFor sharingService: NSSharingService
    ) -> (any NSSharingServiceDelegate)? {
        self
    }

    func sharingService(
        _: NSSharingService,
        didShareItems _: [Any]
    ) {
        close()
    }

    func sharingService(
        _: NSSharingService,
        didFailToShareItems _: [Any],
        error _: any Error
    ) {
        close()
    }

    private func sharingAnchorView() -> NSView? {
        NSApp.windows
            .first { window in
                window.isVisible && window.styleMask.contains(.nonactivatingPanel)
            }?
            .contentView
    }
}
