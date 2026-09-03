# M7 — Settings (first bounded product-shell slice)

Status: **SPECIFICATION — IMPLEMENTATION FOLLOWS**.

## Motivation

M7 ("Product shell") is the first named module after the media/performance foundation with no prior scoping. Every NotchHub behavior today is either hardcoded or derived live from the OS (Reduce Motion, hardware-notch detection) with zero persisted user choice anywhere in the app — `UserDefaults` is not used by any source file today. This slice gives the product a first, deliberately small Settings surface, scoped to four concrete controls the product owner selected as the bounded first version:

1. **Launch at Login.**
2. **Reduce Motion override** — an in-app choice independent of the system Accessibility setting.
3. **Compact extension / positioning** — manual display selection overriding the automatic hardware-notch-first policy.
4. **About** — version, release link, license.

Entry point: a new "Settings…" item in the existing menu-bar status item (`AppDelegate.installStatusItem()`, M6.10), above the existing "Quit NotchHub" item.

## Design

### New invariant: first persisted state in the app

This is the first slice to introduce `UserDefaults` persistence. It stays deliberately narrow and auditable:

```swift
// Sources/NotchHubCore/Settings/NotchHubSettings.swift
public struct NotchHubSettings: Equatable, Sendable {
    public var launchAtLoginEnabled: Bool
    public var reduceMotionOverride: ReduceMotionOverride
    public var preferredDisplayOverride: PreferredDisplayOverride

    public enum ReduceMotionOverride: String, Equatable, Sendable, CaseIterable {
        case system      // follow NSWorkspace.accessibilityDisplayShouldReduceMotion (default)
        case alwaysOn
        case alwaysOff
    }

    public enum PreferredDisplayOverride: Equatable, Sendable {
        case automatic                    // existing hardware-notch-first policy (default)
        case specific(displayUUID: String) // pin to one display by its stable CGDirectDisplayID-derived UUID
    }
}
```

`NotchHubSettingsStore` (`Sources/NotchHubCore/Settings/NotchHubSettingsStore.swift`) is a small `@MainActor` `ObservableObject` wrapping exactly one `UserDefaults` suite (the standard `UserDefaults.standard` — no new App Group, no new entitlement) behind a typed `@Published var settings: NotchHubSettings`, encoding/decoding via `Codable` into one single JSON-encoded key (`"ru.trueruslan.notchhub.settings.v1"`) rather than scattering primitive keys — this keeps the persisted shape versioned and gives forward migration a single seam. Decode failure (corrupt/missing data, a future schema change) falls back to `NotchHubSettings.default` rather than crashing — matches this project's established fail-safe-not-fail-crash posture (e.g. `MediaArtworkTintSampler` returning `nil` on bad artwork data).

No new entitlement: `UserDefaults.standard` is already permitted under `com.apple.security.app-sandbox` alone.

### Entry point — menu bar

`AppDelegate.installStatusItem()` gains one new item between the disabled "NotchHub" title and the existing separator/"Quit NotchHub":

```swift
let settingsItem = NSMenuItem(
    title: "Settings…",
    action: #selector(openSettings),
    keyEquivalent: ","
)
settingsItem.target = self
menu.insertItem(settingsItem, at: 1)
menu.insertItem(.separator(), at: 2)
```

`openSettings()` lazily creates one `NSWindow` (standard titled/closable/miniaturizable, **not** another borderless notch-style panel — Settings is an ordinary window, matching every other macOS app's Settings window) hosting a SwiftUI `SettingsRootView` via `NSHostingView`, and calls `NSApp.activate(ignoringOtherApps: true)` before `window.makeKeyAndOrderFront(nil)` — required because `NSApp.activationPolicy` is `.accessory` (no Dock icon), so the window would otherwise not reliably come to the front of other apps. The window is retained on the `AppDelegate` (`private var settingsWindow: NSWindow?`) and closing it does not quit the app (`applicationShouldTerminateAfterLastWindowClosed` already returns `false`, unchanged).

### Setting 1 — Launch at Login

`Sources/NotchHubCore/Settings/LaunchAtLoginController.swift` wraps `SMAppService.mainApp` (`ServiceManagement`, available since macOS 13, no separate login-item helper bundle needed for the modern main-app registration API, no new entitlement):

```swift
@MainActor
public enum LaunchAtLoginController {
    public static func isEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }

    public static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
```

The Settings toggle calls `setEnabled` and, on a thrown error (e.g. the user declines in System Settings, or the API is otherwise unavailable), reverts the toggle and surfaces the error inline in the Settings window rather than silently pretending it succeeded — `NotchHubSettings.launchAtLoginEnabled` therefore mirrors the *last successfully applied* state, not merely the last requested one, so restarting the app cannot resurrect a stale, silently-failed toggle.

### Setting 2 — Reduce Motion override

Every current read of `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` (`NotchPanelController.swift:93,98,309`; `MediaNotchRootView.swift:111`) becomes a read through one new pure function:

```swift
// Sources/NotchHubCore/Settings/EffectiveReduceMotion.swift
public func effectiveReduceMotion(
    systemValue: Bool,
    override: NotchHubSettings.ReduceMotionOverride
) -> Bool {
    switch override {
    case .system: systemValue
    case .alwaysOn: true
    case .alwaysOff: false
    }
}
```

Each of the four call sites keeps reading the live system value from `NSWorkspace` (so the app still reacts to a live system Accessibility change when the override is `.system`, exactly as today) and passes both into `effectiveReduceMotion`. `NotchPanelController` and `MediaNotchRootView` each already hold (or gain) a reference to `NotchHubSettingsStore` for the current `reduceMotionOverride` value, injected through their existing initializers the same way other collaborators already are (`AppComposition`/`AppDelegate` wiring) — no new global/singleton beyond the already-injected `NotchHubSettingsStore` itself.

### Setting 3 — Compact extension / positioning (manual display override)

`NotchPanelController.preferredBaseLayout()` (`Sources/NotchHubCore/Notch/NotchPanelController.swift:~360`) currently always calls `NotchScreenSelection.preferredIndex(in:fallbackIndex:)`, which is the accepted hardware-notch-first-then-`NSScreen.main`-then-first-screen policy (M1). This slice adds one new, narrower policy entry point:

```swift
enum NotchScreenSelection {
    static func preferredIndex(
        in screens: [ScreenGeometryInput],
        fallbackIndex: Int?,
        manualOverride: NotchHubSettings.PreferredDisplayOverride
    ) -> Int? {
        if case .specific(let displayUUID) = manualOverride,
            let manualIndex = screens.firstIndex(where: { $0.displayUUID == displayUUID })
        {
            return manualIndex
        }
        // .automatic, or the pinned display is no longer connected: fall through
        // to the existing accepted M1 policy unchanged.
        return preferredIndex(in: screens, fallbackIndex: fallbackIndex)
    }
}
```

`ScreenGeometryInput` gains one new `displayUUID: String` field, populated from `NSScreen.deviceDescription[.init("NSScreenNumber")]`'s `CGDirectDisplayID` via `CGDisplayCreateUUIDFromDisplayID` — the standard, stable, public way to identify a physical display across reconnects/reboots (unlike an array index, which changes with topology). A manual override pinned to a since-disconnected display **silently falls back to `.automatic`'s existing behavior** rather than failing closed to no screen at all — matches M1's existing "if no valid selection can be resolved, keep the last valid layout and do nothing" fail-safe philosophy, extended to "an unresolvable override behaves as if unset."

The Settings UI presents the currently connected `NSScreen`s by their `localizedName` for the user to pick from, plus an explicit "Automatic (hardware notch first)" option — it does not expose raw `CGDirectDisplayID` numbers.

This setting change routes through the *existing* event-driven topology-resolution path (`preferredBaseLayout()`, invoked at construction and on `didChangeScreenParametersNotification`) — changing the setting itself triggers one immediate re-resolution call the same way a real topology change already does, through the same migration transition semantics M1 established. No new polling, timer, or second topology-observation mechanism.

### Setting 4 — About

A static SwiftUI section reading `Bundle.main.infoDictionary["CFBundleShortVersionString"]` (currently `0.1.0` in `Resources/Info.plist` — **a separate, pre-existing drift from the `VERSION` file's `0.4.0` this slice does not silently paper over**; see Explicitly out of scope) and linking to the GitHub Releases page via `NSWorkspace.shared.open(_:)`. `scripts/security-audit.sh` forbids any `https?://` pattern anywhere in `Sources/**/*.swift` to keep this project's "no direct runtime network API" posture grep-auditable, so the URL string itself cannot live as a Swift literal; it is added as a new `NHReleasesURL` key in `Resources/Info.plist` (alongside the existing provenance-only `NHSourceCommit`/`NHAdapterCommit`/`NHAdapterPatchSHA256` keys) and read via `Bundle.main.infoDictionary` at runtime, exactly like `CFBundleShortVersionString` above. No new entitlement (the app already has no outbound network entitlement and this is a user-initiated `open` handoff to the system default browser, not an in-app network call — matches the existing pattern of the M6.10 Quit menu action being the only other menu-bar-triggered system call).

### SwiftUI shell structure

`Sources/NotchHubApp/Settings/SettingsRootView.swift` — a plain `TabView` or simple `Form`-based single-page layout (no need for multiple tabs at four settings) with four sections: Launch at Login (toggle), Reduce Motion (segmented picker: System / Always On / Always Off), Display (picker: Automatic / one entry per connected `NSScreen`), About (static text + link button). This is ordinary `NSWindow`-hosted SwiftUI, not the custom notch-panel `NSPanel` machinery — no `matchedGeometryEffect`, no gesture system, no interaction with `NotchPanelTransitionCoordinator` at all.

## Explicitly out of scope for this slice

- Fixing the pre-existing `Resources/Info.plist` `CFBundleShortVersionString` (`0.1.0`) vs. `VERSION` (`0.4.0`) drift — real and worth fixing, but unrelated to Settings and deserves its own small, separately-reviewed PR rather than being buried inside this one; flagging it here so it isn't lost.
- Any additional settings beyond the four selected (no compact-width numeric tuning, no theme/color customization, no keyboard shortcuts configuration).
- Multi-window/tabbed Settings UI polish beyond a single readable page — four controls do not need System Settings-style sidebar navigation.
- Persisting or exposing settings via any inter-process/URL-scheme/CLI surface — `UserDefaults.standard`, in-process only.
- A dedicated Settings XCUI automation harness beyond what's covered below — this is a first slice; UI-level automated coverage of the new window is deferred if it would require disproportionate new automation-only infrastructure (this project already has `NOTCHHUB_UI_TESTING`-gated compile-time fixtures for the notch panel; the same class of fixture is reused if directly applicable, not a new automation subsystem).

## Invariant — no new runtime primitive, no new network/permission surface

No `Timer`/`CADisplayLink`/polling loop. No new entitlement (`SMAppService.mainApp` and `UserDefaults.standard` both work under App Sandbox alone; `NSWorkspace.shared.open(_:)` for the About link is a user-initiated handoff, not a direct network API). No new Accessibility/Input Monitoring/Automation/Screen Recording permission. `scripts/performance_policy.py audit Sources` must stay green with no new timer exception.

## Acceptance

Automated: canonical CI green; full Swift test suite green.

- `NotchHubSettingsTests` (pure `Codable` round-trip, decode-failure-falls-back-to-default, `Equatable` conformance) in `Tests/NotchHubCoreTests/`.
- `EffectiveReduceMotionTests` (pure function, all 3x2 override/system-value combinations) in `Tests/NotchHubCoreTests/`.
- `NotchScreenSelectionTests` extended with manual-override cases: pinned-and-connected wins over automatic; pinned-but-disconnected falls back to existing automatic policy unchanged; `.automatic` behaves exactly as today (regression coverage for the existing M1 cases).
- `LaunchAtLoginControllerTests` — to the extent `SMAppService` is mockable/testable in a headless unit-test environment; if it genuinely cannot be exercised without a real registered login item (likely, since it is a real system side effect), this becomes a `physicalOnlyReason`-documented gap in the acceptance ledger rather than a fabricated test, matching this project's existing honesty standard (e.g. `NH-MEDIA-PROD-003` in `Tests/Acceptance/coverage.yml`).
- A source-scanning policy test locking the menu bar wiring (`Settings…` item present, wired to a handler, positioned above the existing Quit item) — mirrors `AppQuitMenuPolicyTests`' existing pattern for `NotchHubApp`-only AppKit code with no test target-level behavioral seam.

Physical, on exact `Mac16,8` in the current macOS `26.6` patch family, required before merge (this slice touches real system APIs — login items, Accessibility, real displays — that cannot be honestly proven by CI):

1. "Settings…" opens a normal, focusable window from the menu bar; closing it does not quit the app.
2. Toggling Launch at Login actually registers/unregisters the app in **System Settings → General → Login Items**; a denied/failed registration reverts the toggle and shows an inline error rather than silently claiming success.
3. Reduce Motion override: `Always On` visibly disables notch panel/artwork-morph animation regardless of the system Accessibility setting; `Always Off` keeps animation regardless of system Accessibility; `System` matches live system Accessibility toggling exactly as before this slice.
4. Display override: pinning a specific connected display moves the panel there on the next resolution (immediately on setting change, and again on relaunch); disconnecting the pinned display and reconnecting/topology-changing falls back to the existing automatic hardware-notch-first behavior without a crash or stuck panel.
5. About shows the correct version and the release link opens the GitHub Releases page in the default browser.
6. No new Accessibility/Input Monitoring/Automation/Screen Recording permission prompt appears from any of the above.
7. Normal notch panel interaction (hover/gesture/media) is entirely unaffected when Settings is closed.
8. Clean post-Quit teardown, unaffected — closing the Settings window and quitting via the existing menu path both leave no owned media adapter process.
