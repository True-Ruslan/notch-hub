# Project state

Last updated: 2026-08-07
Current development version: `0.1.0` (unreleased)
Active PR: #1 `Bootstrap native macOS foundation`
Active branch: `agent/bootstrap-macos-foundation`
Primary real-hardware target: macOS `26.6`

## Product

NotchHub is a personal native macOS productivity hub built around the MacBook notch. Planned first modules are Shelf, Snippets, Calendar, Translator, and media controls with Yandex Music as the primary player.

NotchNook is tracked as a public product/UI reference only. NotchHub remains an independent local-first implementation; see `docs/PRODUCT_REFERENCES.md`.

## Current milestone

M0 — Engineering foundation.

Status: in progress. **All deterministic automated M0 gates are green after the second real-hardware feedback cycle.** The target MacBook/macOS 26.6 accepted launch and stable hover retention, while exposing two additional visual/window-sizing defects. Both defects now have RED-first regression coverage and a GREEN production fix. A narrow physical retest of the corrected DMG remains before M0 can be accepted and PR #1 merged.

## Latest automated validation

GitHub Actions CI run #19 for commit `3bb1bbb` passed the complete pipeline:

- GitHub `macos-26` compatibility job: PASS;
- runner observed: macOS 26.5.2, Xcode 26.6, Swift 6.3.3;
- macOS 26 build with warnings-as-errors: PASS;
- macOS 26 full unit/regression suite: **10/10 PASS**;
- strict Swift format: PASS;
- `scripts/security-audit.sh`: PASS;
- macOS 15 packaging-runner build with warnings-as-errors: PASS;
- full test suite with coverage instrumentation: **10/10 PASS**;
- release-mode app/DMG build: PASS;
- code signature verification: PASS;
- Hardened Runtime (`runtime` CodeDirectory flag): PASS;
- effective signed App Sandbox entitlement (`com.apple.security.app-sandbox=true`): PASS;
- effective entitlement set contains only the expected M0 sandbox entitlement: PASS;
- linked runtime libraries restricted to system locations: PASS;
- DMG integrity (`hdiutil verify`): PASS;
- GitHub Actions artifact upload: PASS.

The GitHub runner is deliberately only a near-target automated compatibility layer. Exact macOS 26.6 + physical-notch behavior remains a real-device acceptance check.

## Implemented

### Runtime foundation

- Swift 6 / Swift Package Manager project layout
- macOS 14 minimum deployment target
- SwiftUI + AppKit application shell
- accessory/background-style app without a Dock icon
- borderless non-activating `NSPanel`
- hardware-notch geometry derived from public `NSScreen` APIs
- compact width uses the exact detected physical notch width; the 180 pt minimum is now fallback-only for displays without a hardware notch
- fallback geometry for non-notch displays
- compact/expanded panel state
- screen-space pointer activation/retention policy with hysteresis between compact and expanded regions
- `NSHostingView` sizing ownership disabled (`sizingOptions = []`) so AppKit panel geometry remains authoritative and SwiftUI content cannot retain an expanded window minimum after collapse
- M0 global pointer observation reduced to `mouseMoved` only; no button, drag, scroll, modifier, or keyboard event classes are monitored

### Tests and CI

- unit tests for geometry, panel state, pointer retention, exact hardware-notch compact width, and hosting-view sizing ownership
- TDD policy with recorded RED → GREEN evidence for regressions
- strict project-level Swift formatting gate
- compiler warnings treated as errors in CI
- test execution with coverage instrumentation
- dedicated GitHub-hosted `macos-26` compatibility build/test before the protected `Build, test and package` gate can pass
- release packaging, bundle/signature/entitlement/dynamic-library/DMG-integrity verification
- stable manual acceptance IDs in `docs/TESTING.md`

### Security baseline

- App Sandbox enabled with a minimal entitlement set
- Hardened Runtime enabled even for ad-hoc PR builds
- zero third-party Swift runtime dependencies at M0
- repository security policy in `SECURITY.md`
- executable `scripts/security-audit.sh` gate that rejects silent addition of runtime shell/subprocess execution, direct network/WebKit APIs, dynamic code loading, keyboard/button/drag/scroll global-event classes, dangerous Hardened Runtime exceptions, persistence helpers, credential-like material, mutable GitHub Action references, and `pull_request_target`
- GitHub Actions pinned to immutable full commit SHAs
- code signing avoids `--deep` during signing; recursive `--deep --strict` remains verification-only
- release workflow accepts a tag only when it points to the current protected `main`
- no telemetry, analytics, licensing client, or direct network requests in the baseline app

### Versioning and distribution

- Semantic Versioning with repository-root `VERSION`
- `CHANGELOG.md`
- CI-built ad-hoc signed DMG for testing
- stable GitHub Release workflow prepared for Developer ID signing, Apple notarization, stapling, Gatekeeper verification, and SHA-256 checksum publication
- manual `Actions → Release → Run workflow` flow can create the `v<version>` tag/release directly from accepted `main`

## Real-hardware acceptance history — 2026-08-07

### Cycle 1 — bootstrap build

- `NH-BOOT-001`: PASS enough to reach and operate the running panel.
- `NH-HOVER-001`: FAIL — repeated compact/expanded oscillation while hovering.
- Root cause: SwiftUI `onHover` directly controlled presentation while the resulting presentation change resized/animated the same `NSPanel`, creating a feedback path through transient hover exits.
- TDD RED commit: `eb4fb4d` (`test: reproduce hover retention regression`). CI failed exactly on `expandedPointerInsideExpandedRetentionRegionStaysExpanded` with `.compact` instead of `.expanded`.
- GREEN fix commit: `eff9bde` (`fix: stabilize notch hover retention`). Automated regression validation: PASS.

### Cycle 2 — sandbox/Hardened Runtime build

User-tested on the target MacBook running macOS 26.6:

- `NH-OS26-001`: **PASS**.
- `NH-NOTCH-001`: **FAIL (minor visual mismatch)** — compact panel appeared a few pixels wider than the physical notch.
- `NH-HOVER-001`: **PASS** — one expansion, no oscillation while hovering.
- `NH-HOVER-002`: **PASS** — panel remained expanded while moving inside it.
- `NH-HOVER-003`: **FAIL** — after leaving, SwiftUI content switched to compact (single dot) but the black `NSPanel` frame remained at expanded size; screenshot evidence supplied.
- `NH-SANDBOX-001`: **reported as PASS by matrix order**. The user message accidentally repeated the label `NH-HOVER-003` on its final PASS line; this is recorded transparently rather than silently rewriting the report.

Root causes and TDD evidence for cycle 2:

- Compact-width defect: `minimumCompactWidth=180` was incorrectly applied with `max(180, hardwareNotchWidth)`, inflating real hardware notches narrower than 180 pt.
- Collapse-window defect: `NSHostingView` kept its default `.standardBounds` sizing policy. When used as an `NSWindow.contentView`, SwiftUI can propagate content min/max sizing to the window, conflicting with `NotchPanelController` frame ownership during expanded → compact transitions.
- RED commit: `c518326` (`test: reproduce compact sizing regressions`). macOS 26 CI built successfully and then failed exactly two tests: hardware compact width was `180` instead of expected `176`, and hosting sizing options were `rawValue 7` instead of empty.
- GREEN commit: `3bb1bbb` (`fix: restore compact panel sizing`). Hardware notches now use their exact detected width, non-notch displays retain the 180 pt fallback, and `NSHostingView.sizingOptions` is empty so the controller is the sole window-size authority.
- GREEN validation: CI run #19 passed **10/10 tests** plus the complete security/signing/sandbox/DMG pipeline.
- Corrected-DMG physical retest: **PENDING**.

See `docs/TESTING.md` for stable acceptance scenario IDs and the test/manual boundary.

## Release trust prerequisites still external

The repository-side workflow is prepared, but trusted stable releases require one-time Apple credentials that must be configured by the repository owner directly in the GitHub `release` environment. Never send them through chat.

Required environment secrets are documented in `docs/RELEASING.md`:

- Developer ID Application `.p12` as base64 + its export password
- App Store Connect notarization `.p8` key + key ID + issuer ID

An Apple Developer Program membership is required to obtain Developer ID signing credentials.

## Known limitations

- the cycle-2 compact-width and expanded-shell fixes need one final physical retest on macOS 26.6;
- panel is initially attached to `NSScreen.main`; active-display migration is not implemented yet;
- final expansion/collapse timing and animation feel have not been tuned on real hardware;
- UI is a structural preview rather than final product design;
- no feature modules are wired yet;
- stable Developer ID/notarized release cannot be executed until Apple release secrets are configured;
- Yandex Music integration is planned but not implemented in M0;
- Spaces/fullscreen and multi-display behavior are not yet accepted;
- GitHub `macos-26` CI currently runs macOS 26.5.2 with Xcode 26.6, not the exact physical macOS 26.6 hardware/UI environment; exact 26.6 acceptance remains a real-device check.

## Quality and security policy

- TDD is the default for behavior changes and regressions: RED must be observed before GREEN.
- Automate every deterministic behavior that can be tested honestly; do not manufacture tests or coverage numbers for non-deterministic physical UX.
- Deterministic production decisions belong in pure/testable code; AppKit/SwiftUI wiring stays thin.
- CI may not be weakened to hide a product defect or security warning.
- Manual testing is reserved for unavoidable physical/OS/permission/third-party behavior and is tracked by stable scenario IDs.
- Security-sensitive capability, entitlement, permission, dependency, event-observation scope, or release-chain changes require documentation in the same PR.
- Notable changes update `CHANGELOG.md`.
- Architectural/product/test/security decisions update the relevant docs in the same PR.

## Next optimal step

1. Download the newest `NotchHub-dmg` artifact from PR #1 → CI run #19 (commit `3bb1bbb`).
2. On the target MacBook/macOS 26.6 rerun only the behavior affected by the fixes: `NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, and `NH-HOVER-003`.
3. If those four pass, record M0 as accepted, mark PR #1 ready, and squash-merge.
4. Configure the GitHub `release` environment with Apple credentials per `docs/RELEASING.md`.
5. Run the Release workflow to publish signed/notarized `v0.1.0` on GitHub Releases.
6. Run `NH-GATEKEEPER-001` once against the normally downloaded stable release.
7. Start M1 with display-change handling, active-screen migration, fullscreen/Spaces behavior, animation tuning, and expanded UI/gesture design based on independent product research.
