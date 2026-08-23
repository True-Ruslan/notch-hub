# M6.10 — Discoverable normal-quit path

Status: **SPECIFICATION — IMPLEMENTATION FOLLOWS**.

## Motivation

M6.7's physical acceptance found that NotchHub has no user-reachable way to quit besides Force Quit: `LSUIElement=true` (`Resources/Info.plist`) plus `NSApp.setActivationPolicy(.accessory)` (`Sources/NotchHubApp/AppDelegate.swift`) mean there is no Dock icon, no app menu bar, and Cmd+Q is a no-op. Force Quit sends SIGKILL, which bypasses `applicationWillTerminate` entirely — the method that already correctly tears down `mediaPeekSession`, `mediaGestureSession`, `mediaTimelineTicker`, and stops the shipping media runtime (which in turn stops the `mediaremote-adapter.pl` helper process). The practical effect is a real defect: quitting via Force Quit leaves an orphaned adapter process, while the app's own graceful-termination code — already tested and accepted — is never reached.

This is a foundational "strong core" gap, not cosmetic polish, so it is prioritized ahead of further Compact/Peek visual work.

## Design

`AppDelegate` gains a minimal `NSStatusItem`, installed in `applicationDidFinishLaunching` via a new `installStatusItem()` method:

- A template `NSImage(systemSymbolName: "rectangle.topthird.inset.filled", ...)` — a stock SF Symbol, since the project ships no custom app icon/asset catalog at all today and introducing one is out of scope for this slice.
- A static `NSMenu`: a disabled "NotchHub" title item, a separator, and one actionable "Quit NotchHub" item (`keyEquivalent: "q"`, target `NSApp`, action `#selector(NSApplication.terminate(_:))`).

Selecting "Quit NotchHub" calls `NSApp.terminate(_:)`, which routes through the *existing, already-tested* `applicationWillTerminate` — this slice adds no new termination/cleanup logic, only a discoverable way to trigger the logic that already exists and already passed physical acceptance for its cleanup behavior in earlier milestones.

`statusItem` is torn down (set to `nil`) at the start of `applicationWillTerminate`, matching the explicit-symmetry teardown style already used for `panelController`/`mediaPeekSession`/`mediaGestureSession` in the same method, even though a status item does not strictly require explicit teardown before process exit.

## Invariant — no new permission, entitlement, or runtime primitive

`NSStatusItem` requires no additional entitlement under App Sandbox; `Resources/NotchHub.entitlements` remains exactly `{"com.apple.security.app-sandbox": true}` with no new key. No Accessibility, Input Monitoring, Automation, or Screen Recording permission is touched. The menu is fully static and event-driven (click-to-open); no timer, polling, or observation is introduced, so `performance/reviewed-runtime-timers.json` needs no new entry. Activation policy remains `.accessory` and `LSUIElement` remains `true` — this feature must never cause a Dock icon to appear.

## Explicitly out of scope for this slice

- A custom app icon/asset catalog for the status item (uses a stock SF Symbol instead).
- A "Settings…" menu item — M7 (the Settings module) does not exist yet. This slice only makes a future addition architecturally easy by establishing the menu bar entry point.
- A global Cmd+Q hotkey reachable without opening the status item's menu (would require a global event monitor — new complexity not justified by this bounded fix; the menu's own `keyEquivalent` already works while that menu is open).
- Any change to the existing termination/cleanup logic itself.

## Acceptance

Automated: canonical CI green, full Swift test suite green (new `AppQuitMenuPolicyTests` source-scanning assertions: status item + menu + Quit action wired to `NSApplication.terminate`, no new entitlement, activation policy/`LSUIElement` unchanged), `scripts/performance_policy.py audit Sources` green with no new exception needed.

Physical, on exact `Mac16,8` in the current macOS `26.6` patch family — see `docs/testing/M6_10_DISCOVERABLE_QUIT_ACCEPTANCE.md`:

1. A status item icon appears in the menu bar on launch.
2. Clicking it shows the "NotchHub" title and "Quit NotchHub" action.
3. Selecting "Quit NotchHub" quits the app.
4. After quitting via the menu, `pgrep -lf 'mediaremote-adapter\.pl'` is empty — proving the existing cleanup path ran, unlike Force Quit.
5. No Dock icon appears at any point.
6. No new permission prompt appears.
7. The notch panel (Compact/Peek/Expanded) is visually and functionally unaffected.
