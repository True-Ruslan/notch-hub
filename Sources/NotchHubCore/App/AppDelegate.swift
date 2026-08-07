import AppKit

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: NotchPanelController?

    public override init() {
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let controller = NotchPanelController()
        panelController = controller
        controller.show()
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
