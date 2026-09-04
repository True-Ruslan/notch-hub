# M7 — Settings shell (first bounded slice) — Acceptance Evidence

Status: **ACCEPTED — 2026-09-04**

Authoritative design/invariants: `docs/superpowers/specs/2026-09-04-m7-settings-shell-design.md`.
PR #81, physical acceptance executed on exact PR head, canonical CI GREEN 3/3. Squash-merged as `165cd9e925ae14b41e01a3adef3390116437ce47`.

First scoped version of M7 "Product shell". Four controls per product-owner scoping: Launch at Login (`SMAppService.mainApp`), Reduce Motion override (System/Always On/Always Off), manual display override (replacing automatic hardware-notch-first selection), and About (version + release link). Entry point: a new "Settings…" item in the existing menu-bar status item (M6.10), opening one ordinary titled/closable `NSWindow` — not another notch-style `NSPanel`. First persisted state in the app (`NotchHubSettings`/`NotchHubSettingsStore`, one `Codable` value in one `UserDefaults.standard` key). No new entitlement.

This PR also touched `NotchPanelController` — the accepted/physically-tested core panel-transition/display-migration authority from M1/M6.6/M6.11 — for the first time since its last physical acceptance, to wire the Reduce Motion override and the manual display override through the existing `animationPolicyDidChange`/`preferredBaseLayout()`/`migrateToPreferredDisplayIfNeeded()` paths.

## Acceptance ledger

### `NH-M7-SETTINGS-001` — Settings shell (Launch at Login, Reduce Motion override, display override, About)

Status: **PASS**

Physical acceptance on the product owner's own Mac, per the spec's Acceptance checklist — all items PASS:

1. "Settings…" opens a normal, focusable window from the menu bar; closing it does not quit the app — PASS.
2. Toggling Launch at Login actually registers/unregisters the app in System Settings → General → Login Items — PASS.
3. Reduce Motion override (`Always On`/`Always Off`/`System`) behaves as specified against live Accessibility state — PASS.
4. Display override moves the panel to the pinned display; disconnecting/reconnecting falls back to the existing automatic hardware-notch-first behavior without a crash or stuck panel — PASS.
5. About shows the correct version and the release link opens the GitHub Releases page in the default browser — PASS.
6. No new Accessibility/Input Monitoring/Automation/Screen Recording permission prompt appeared — PASS.
7. Normal notch panel interaction (hover/gesture/media) is entirely unaffected when Settings is closed — PASS.
8. Clean post-Quit teardown, unaffected — PASS.

No real defect was found; `NotchPanelController`'s existing accepted transition/migration paths correctly carried the new settings-driven inputs.

## Automated coverage

- `NotchHubCoreTests.NotchHubSettingsTests` — `Codable` round-trip for every `ReduceMotionOverride`/`PreferredDisplayOverride` case, `default` values.
- `NotchHubCoreTests.NotchHubSettingsStoreTests` — `UserDefaults` persistence round-trip via isolated suites, corrupt-persisted-data falls back to `.default` rather than crashing.
- `NotchHubCoreTests.EffectiveReduceMotionTests` — all override/system-value combinations of the pure `effectiveReduceMotion(systemValue:override:)`.
- `NotchHubCoreTests.NotchScreenSelectionTests` — extended with manual-override cases: pinned-and-connected wins; pinned-but-disconnected falls back to the existing automatic M1 policy; `.automatic` behaves exactly as before.
- `NotchHubCoreTests.SettingsMenuPolicyTests` — source-scanning lock (mirrors `AppQuitMenuPolicyTests`' pattern for `NotchHubApp`-only AppKit code with no test-target seam) on the "Settings…" menu item, its position above "Quit NotchHub", the ordinary-window (not notch-panel) construction, and no new entitlement.
- `LaunchAtLoginControllerTests` intentionally absent: `SMAppService` is a real system side effect this project's honesty standard does not fabricate a unit test for — covered by physical acceptance item 2 above only, matching this project's established precedent for other physical-only production media transport observations recorded in `docs/testing/PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`.
- Full Swift test suite: 469/469 tests, 97 suites GREEN (`scripts/swift-test-clt.sh`).
- Python size-budget/performance unit tests: 52/52 GREEN, including the new `test_repository_m7_settings_shell_budget_is_provenanced_tight_and_self_validating`.
- `scripts/performance_policy.py audit Sources` — passes with no new `performance/reviewed-runtime-timers.json` entry needed.
- `scripts/security-audit.sh` — passes; the About release link is read from a new `NHReleasesURL` `Info.plist` key rather than a Swift source literal, since the security baseline forbids any `https?://` pattern in `Sources`.
- Canonical CI (`Build, test and package`, `macOS 26 compatibility`, `macOS UI regression`) 3/3 GREEN, including the new `performance/m7-settings-shell-size-budget.json` release size gate derived from this PR's own measured CI candidate.

## Physical acceptance checklist

Full checklist definition: `docs/superpowers/specs/2026-09-04-m7-settings-shell-design.md`. All items PASS; results recorded above.
