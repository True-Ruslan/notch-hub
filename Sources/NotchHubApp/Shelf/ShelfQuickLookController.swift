import AppKit
import NotchHubCore
import QuickLookUI

@MainActor
final class ShelfQuickLookController: NSObject, QLPreviewPanelDelegate {
    private let accessSession: ShelfPreviewAccessSession
    private let dataSource = ShelfQuickLookDataSource()
    private weak var panel: QLPreviewPanel?

    init(accessSession: ShelfPreviewAccessSession = ShelfPreviewAccessSession()) {
        self.accessSession = accessSession
        super.init()
    }

    @discardableResult
    func present(url: URL) -> Bool {
        guard accessSession.begin(url: url) else {
            return false
        }
        guard let panel = QLPreviewPanel.shared() else {
            accessSession.end()
            return false
        }

        dataSource.setPreviewURL(url)
        self.panel = panel
        panel.dataSource = dataSource
        panel.delegate = self
        panel.currentPreviewItemIndex = 0
        panel.reloadData()

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        return true
    }

    func close() {
        let activePanel = panel
        dataSource.setPreviewURL(nil)
        accessSession.end()
        activePanel?.dataSource = nil
        activePanel?.delegate = nil
        activePanel?.orderOut(nil)
        panel = nil
    }

    func windowWillClose(_ notification: Notification) {
        guard let closingPanel = notification.object as? QLPreviewPanel,
            closingPanel === panel
        else {
            return
        }

        dataSource.setPreviewURL(nil)
        accessSession.end()
        closingPanel.dataSource = nil
        closingPanel.delegate = nil
        panel = nil
    }
}

private final class ShelfQuickLookDataSource: NSObject, QLPreviewPanelDataSource {
    private let lock = NSLock()
    private var previewURL: NSURL?

    func setPreviewURL(_ url: URL?) {
        lock.lock()
        defer { lock.unlock() }
        previewURL = url.map { $0 as NSURL }
    }

    func numberOfPreviewItems(in _: QLPreviewPanel!) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return previewURL == nil ? 0 : 1
    }

    func previewPanel(
        _: QLPreviewPanel!,
        previewItemAt index: Int
    ) -> (any QLPreviewItem)! {
        lock.lock()
        defer { lock.unlock() }
        guard index == 0 else {
            return nil
        }
        return previewURL
    }
}
