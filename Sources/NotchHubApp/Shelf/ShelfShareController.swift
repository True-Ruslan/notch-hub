import AppKit
import NotchHubCore

@MainActor
final class ShelfShareController: NSObject {
    private let accessSession: ShelfShareAccessSession
    private var picker: NSSharingServicePicker?

    private lazy var sharingServiceDelegate = ShelfShareServiceDelegate(
        onSuccess: { [weak self] in
            self?.close()
        },
        onFailure: { [weak self] in
            self?.close()
        }
    )

    private lazy var pickerDelegate = ShelfSharePickerDelegate(
        serviceDelegate: sharingServiceDelegate,
        onCancellation: { [weak self] in
            self?.close()
        }
    )

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
        picker.delegate = pickerDelegate

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

    private func sharingAnchorView() -> NSView? {
        NSApp.windows
            .first { window in
                window.isVisible && window.styleMask.contains(.nonactivatingPanel)
            }?
            .contentView
    }
}

private final class ShelfSharePickerDelegate: NSObject, NSSharingServicePickerDelegate {
    private let serviceDelegate: ShelfShareServiceDelegate
    private let onCancellation: @MainActor @Sendable () -> Void

    init(
        serviceDelegate: ShelfShareServiceDelegate,
        onCancellation: @escaping @MainActor @Sendable () -> Void
    ) {
        self.serviceDelegate = serviceDelegate
        self.onCancellation = onCancellation
        super.init()
    }

    func sharingServicePicker(
        _: NSSharingServicePicker,
        didChoose service: NSSharingService?
    ) {
        if service == nil {
            let onCancellation = onCancellation
            Task { @MainActor in
                onCancellation()
            }
        }
    }

    func sharingServicePicker(
        _: NSSharingServicePicker,
        delegateFor sharingService: NSSharingService
    ) -> (any NSSharingServiceDelegate)? {
        serviceDelegate
    }
}

private final class ShelfShareServiceDelegate: NSObject, NSSharingServiceDelegate {
    private let onSuccess: @MainActor @Sendable () -> Void
    private let onFailure: @MainActor @Sendable () -> Void

    init(
        onSuccess: @escaping @MainActor @Sendable () -> Void,
        onFailure: @escaping @MainActor @Sendable () -> Void
    ) {
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        super.init()
    }

    @MainActor
    func sharingService(
        _: NSSharingService,
        didShareItems _: [Any]
    ) {
        onSuccess()
    }

    @MainActor
    func sharingService(
        _: NSSharingService,
        didFailToShareItems _: [Any],
        error _: any Error
    ) {
        onFailure()
    }
}
