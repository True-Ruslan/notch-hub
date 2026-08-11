import AppKit
import NotchHubCore
import NotchHubMediaCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: NotchPanelController?
    private var mediaRuntime: ShippingMediaRuntime?

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let panelController = NotchPanelController()
        self.panelController = panelController
        panelController.settledPresentationHandler = { [weak self] presentation in
            self?.updateMediaRuntime(for: presentation)
        }
        panelController.show()
    }

    func applicationWillTerminate(_: Notification) {
        panelController?.settledPresentationHandler = nil

        mediaRuntime?.stop()
        mediaRuntime = nil

        panelController?.invalidate()
        panelController = nil
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        false
    }

    private func updateMediaRuntime(for presentation: NotchPresentation) {
        switch presentation {
        case .expanded:
            guard mediaRuntime == nil else {
                return
            }

            let mediaRuntime = ShippingMediaRuntime()
            self.mediaRuntime = mediaRuntime
            mediaRuntime.start()

        case .compact:
            mediaRuntime?.stop()
            mediaRuntime = nil
        }
    }
}
