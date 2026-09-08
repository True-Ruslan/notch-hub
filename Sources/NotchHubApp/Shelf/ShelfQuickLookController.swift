import AppKit
import NotchHubCore
import QuickLookUI

@MainActor
final class ShelfQuickLookController: NSObject, @MainActor QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    private let accessSession: ShelfPreviewAccessSession
    private var previewURL: URL?
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

        previewURL = url
        self.panel = panel
        panel.dataSource = self
        panel.delegate = self
        panel.currentPreviewItemIndex = 0
        panel.reloadData()

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        return true
    }

    func close() {
        let activePanel = panel
        previewURL = nil
        accessSession.end()
        activePanel?.dataSource = nil
        activePanel?.delegate = nil
        activePanel?.orderOut(nil)
        panel = nil
    }

    func numberOfPreviewItems(in _: QLPreviewPanel!) -> Int {
        previewURL == nil ? 0 : 1
    }

    func previewPanel(
        _: QLPreviewPanel!,
        previewItemAt index: Int
    ) -> (any QLPreviewItem)! {
        guard index == 0, let previewURL else {
            return nil
        }
        return previewURL as NSURL
    }

    func windowWillClose(_ notification: Notification) {
        guard let closingPanel = notification.object as? QLPreviewPanel,
            closingPanel === panel
        else {
            return
        }

        previewURL = nil
        accessSession.end()
        closingPanel.dataSource = nil
        closingPanel.delegate = nil
        panel = nil
    }
}
