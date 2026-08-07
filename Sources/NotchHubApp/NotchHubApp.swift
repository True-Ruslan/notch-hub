import SwiftUI
import NotchHubCore

@main
struct NotchHubApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            Text("NotchHub settings will be added in a later milestone.")
                .padding(24)
        }
    }
}
