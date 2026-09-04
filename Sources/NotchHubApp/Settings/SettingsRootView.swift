import AppKit
import NotchHubCore
import SwiftUI

@MainActor
struct SettingsRootView: View {
    @ObservedObject private var settingsStore: NotchHubSettingsStore
    @State private var launchAtLoginErrorMessage: String?

    init(settingsStore: NotchHubSettingsStore) {
        self.settingsStore = settingsStore
    }

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: launchAtLoginBinding)
                    .accessibilityIdentifier("settings.launchAtLogin")
                if let launchAtLoginErrorMessage {
                    Text(launchAtLoginErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("settings.launchAtLoginError")
                }
            }

            Section("Reduce Motion") {
                Picker("Reduce Motion", selection: reduceMotionBinding) {
                    Text("System").tag(NotchHubSettings.ReduceMotionOverride.system)
                    Text("Always On").tag(NotchHubSettings.ReduceMotionOverride.alwaysOn)
                    Text("Always Off").tag(NotchHubSettings.ReduceMotionOverride.alwaysOff)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityIdentifier("settings.reduceMotion")
                // Native AXSelected on an NSSegmentedControl's individual
                // segments is not reliably observable via XCUITest; expose
                // the selection explicitly instead, matching this
                // codebase's existing pattern for programmatically
                // verifiable UI state (e.g. MediaNotchRootView's
                // .accessibilityValue on the play/pause button).
                .accessibilityValue(settingsStore.settings.reduceMotionOverride.rawValue)
            }

            Section("Display") {
                Picker("Display", selection: displayOverrideBinding) {
                    Text("Automatic (hardware notch first)").tag(DisplayOverrideOption.automatic)
                    ForEach(connectedDisplays, id: \.uuid) { display in
                        Text(display.localizedName).tag(DisplayOverrideOption.specific(display.uuid))
                    }
                }
                .labelsHidden()
                .accessibilityIdentifier("settings.display")
            }

            Section("About") {
                Text("NotchHub \(appVersion)")
                    .accessibilityIdentifier("settings.about.version")
                if let releasesURL {
                    Button("View latest release on GitHub") {
                        NSWorkspace.shared.open(releasesURL)
                    }
                    .accessibilityIdentifier("settings.about.releaseLink")
                }
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "unknown"
    }

    /// Read from Info.plist rather than a Swift source literal: this project's
    /// security baseline (scripts/security-audit.sh) forbids any `https?://`
    /// pattern in Sources to keep the "no direct runtime network API" posture
    /// grep-auditable, so the release URL lives alongside the other
    /// provenance-only NH* Info.plist keys instead.
    private var releasesURL: URL? {
        (Bundle.main.infoDictionary?["NHReleasesURL"] as? String).flatMap(URL.init(string:))
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.settings.launchAtLoginEnabled },
            set: { newValue in
                do {
                    try LaunchAtLoginController.setEnabled(newValue)
                    launchAtLoginErrorMessage = nil
                    settingsStore.update { $0.launchAtLoginEnabled = newValue }
                } catch {
                    launchAtLoginErrorMessage = error.localizedDescription
                }
            }
        )
    }

    private var reduceMotionBinding: Binding<NotchHubSettings.ReduceMotionOverride> {
        Binding(
            get: { settingsStore.settings.reduceMotionOverride },
            set: { newValue in
                settingsStore.update { $0.reduceMotionOverride = newValue }
            }
        )
    }

    private enum DisplayOverrideOption: Hashable {
        case automatic
        case specific(String)
    }

    private var displayOverrideBinding: Binding<DisplayOverrideOption> {
        Binding(
            get: {
                switch settingsStore.settings.preferredDisplayOverride {
                case .automatic:
                    .automatic
                case .specific(let displayUUID):
                    .specific(displayUUID)
                }
            },
            set: { newValue in
                settingsStore.update {
                    switch newValue {
                    case .automatic:
                        $0.preferredDisplayOverride = .automatic
                    case .specific(let displayUUID):
                        $0.preferredDisplayOverride = .specific(displayUUID: displayUUID)
                    }
                }
            }
        )
    }

    private struct ConnectedDisplay {
        let uuid: String
        let localizedName: String
    }

    private var connectedDisplays: [ConnectedDisplay] {
        NSScreen.screens.compactMap { screen in
            guard let uuid = ScreenGeometryInput.stableDisplayUUID(for: screen) else {
                return nil
            }
            return ConnectedDisplay(uuid: uuid, localizedName: screen.localizedName)
        }
    }
}
