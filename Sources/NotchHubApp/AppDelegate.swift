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
        panelController.show()

        let mediaRuntime = ShippingMediaRuntime()
        self.mediaRuntime = mediaRuntime
        mediaRuntime.start()
    }

    func applicationWillTerminate(_: Notification) {
        mediaRuntime?.stop()
        mediaRuntime = nil

        panelController?.invalidate()
        panelController = nil
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        false
    }
}
