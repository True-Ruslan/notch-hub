# Fullscreen / Spaces hardening — Acceptance Evidence

Status: **ACCEPTED — 2026-09-03**

Authoritative design/invariants: `docs/superpowers/specs/2026-09-03-fullscreen-spaces-notchless-hardening-design.md`.
PR #77, physical acceptance executed on exact PR head, canonical CI GREEN 3/3. Squash-merged as `273126e54f93cd806eaf2be9fa5191f47092d416`.

M1's multi-monitor migration (PR #56) verified the notchless-display fallback but left fullscreen-app and Spaces-switch behavior deferred, as tracked in `PROJECT_STATE.md`/`ROADMAP.md` since. `NotchPanelController.configurePanel()` already implemented Apple's documented recipe for a utility panel that survives both (`.canJoinAllSpaces`, `.fullScreenAuxiliary`, `.stationary`, `.level = .statusBar`, `styleMask [.borderless, .nonactivatingPanel]`) — unchanged since M1 — but no automated test asserted it and neither scenario had ever been physically exercised. This slice added the regression lock and closed the physical-verification gap; no production defect was found.

## Acceptance ledger

### `NH-PANEL-SPACES-FULLSCREEN-001` — panel survives fullscreen apps and Spaces switches

Status: **PASS**

Physical acceptance on the product owner's own Mac, per the spec's Acceptance checklist — all items PASS:

1. Another app made fullscreen on the notch display: Compact stayed visible; hover-to-Peek and explicit-click-to-Expanded worked correctly over the fullscreen app — PASS.
2. Switching Spaces (including into/out of the fullscreen Space) while settled Compact did not lose, duplicate, or misposition the panel on any Space — PASS.
3. Switching Spaces while settled Peek and while settled Expanded left no stuck/stale surface — PASS.
4. Switching Spaces mid-interaction (in-flight hover dwell or interactive drag) did not crash, freeze, or leave the transition state machine inconsistent — PASS.
5. No new Accessibility/Input Monitoring/Automation/Screen Recording permission prompt appeared — PASS.
6. No visible jank/frame drop in ordinary hover/gesture responsiveness — PASS.
7. Clean post-Quit teardown, unaffected — PASS.

No real defect was found; the existing `configurePanel()` recipe already held under real fullscreen/Spaces conditions.

## Automated coverage

- `NotchHubCoreTests.NotchPanelSpacesFullscreenPolicyTests.panelJoinsAllSpacesAndRemainsAuxiliaryOverFullscreenApps` — constructs the real `NotchPanelController` and asserts the real `NSPanel.collectionBehavior` is exactly `[.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]`.
- `NotchHubCoreTests.NotchPanelSpacesFullscreenPolicyTests.panelStaysAtStatusBarLevelAndNeverHidesOnDeactivate` — asserts `panel.level == .statusBar` and `panel.hidesOnDeactivate == false`.
- `NotchHubCoreTests.NotchPanelSpacesFullscreenPolicyTests.panelStyleMaskIsBorderlessNonactivatingAndNeverAnOrdinaryActivatableWindow` — asserts `styleMask` contains `.borderless`/`.nonactivatingPanel` and excludes `.titled`/`.closable`/`.resizable`.
- Full Swift test suite: 453/453 tests, 93 suites GREEN (`scripts/swift-test-clt.sh`).
- `scripts/performance_policy.py audit Sources` — passes with no new `performance/reviewed-runtime-timers.json` entry needed (no new runtime primitive).
- Canonical CI (`Build, test and package`, `macOS 26 compatibility`, `macOS UI regression`) 3/3 GREEN.

## Physical acceptance checklist

Full checklist definition: `docs/superpowers/specs/2026-09-03-fullscreen-spaces-notchless-hardening-design.md`. All items PASS; results recorded above.
