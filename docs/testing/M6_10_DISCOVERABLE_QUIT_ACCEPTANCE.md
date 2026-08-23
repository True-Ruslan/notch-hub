# M6.10 — Discoverable normal-quit path — Acceptance Evidence

Status: **ACCEPTED — 2026-08-23**

Authoritative design/invariants: `docs/superpowers/specs/2026-08-23-discoverable-quit-menu-design.md`.
Accepted merged source: PR #64, squash merge `b911746077092bfffd60d93cd8072c268cb1df94`. Physical acceptance executed on exact PR head `06d0c40274cea1fa5d25c37d4213a3efb8e08355`, canonical CI GREEN 3/3.

M6.7's physical acceptance found Force Quit was the only way to quit NotchHub, bypassing `applicationWillTerminate`'s existing media-runtime cleanup and leaving an orphaned `mediaremote-adapter.pl` process. PR #64 adds a minimal `NSStatusItem` with a "Quit NotchHub" menu action wired to the existing `#selector(NSApplication.terminate(_:))` cleanup path.

## Acceptance ledger

### `NH-APP-QUIT-001` — discoverable normal-quit path

Status: **PASS**

Physical acceptance on the product owner's own Mac — all items PASS:

1. Status item icon appears in the menu bar on launch — PASS.
2. Clicking it shows the "NotchHub" title and "Quit NotchHub" action — PASS.
3. Selecting "Quit NotchHub" quits the app — PASS.
4. Post-quit `pgrep -lf 'mediaremote-adapter\.pl'` empty — PASS (confirms `applicationWillTerminate`'s existing cleanup ran, unlike Force Quit).
5. No Dock icon appears at any point — PASS.
6. No new permission prompt appears — PASS.
7. Notch panel (Compact/Peek/Expanded, hover, gestures) unaffected — PASS.

## Automated coverage

- `NotchHubCoreTests.AppQuitMenuPolicyTests.statusItemHostsADiscoverableQuitAction` — asserts the status item, menu, and Quit action wired to `NSApplication.terminate` exist in source.
- `NotchHubCoreTests.AppQuitMenuPolicyTests.quitStillRunsExistingTerminationCleanup` — asserts the action targets `NSApp` and no duplicate termination path was introduced.
- `NotchHubCoreTests.AppQuitMenuPolicyTests.statusItemAddsNoNewEntitlementOrPermission` — asserts `Resources/NotchHub.entitlements` is unchanged (exactly `com.apple.security.app-sandbox`).
- `NotchHubCoreTests.AppQuitMenuPolicyTests.appRemainsAccessoryWithNoDockIconRegression` — asserts `LSUIElement`/`.accessory` are unchanged.
- Canonical CI (`Build, test and package`, `macOS 26 compatibility`, `macOS UI regression`) 3/3 GREEN on exact head `06d0c40274cea1fa5d25c37d4213a3efb8e08355`, including the release size gate against real evidence in `performance/m6-10-discoverable-quit-menu-size-budget.json`.

## Physical acceptance checklist

Full checklist definition: `docs/superpowers/specs/2026-08-23-discoverable-quit-menu-design.md`. All items PASS; results recorded above.
