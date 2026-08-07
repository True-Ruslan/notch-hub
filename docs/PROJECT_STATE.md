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

Status: in progress. **All deterministic automated M0 gates are green.** The first real-hardware hover regression has RED-first automated coverage and a production fix. The remaining blocker before accepting M0/merging PR #1 is a physical retest of the latest sandboxed/Hardened Runtime DMG on the target MacBook running macOS 26.6.

## Latest automated validation

The latest code/tooling state passed the complete CI pipeline before this documentation-only state update:

- GitHub `macos-26` compatibility job: PASS;
- runner observed: macOS 26.5.2, Xcode 26.6, Swift 6.3.3;
- macOS 26 build with warnings-as-errors: PASS;
- macOS 26 full unit/regression suite: PASS;
- strict Swift format: PASS;
- `scripts/security-audit.sh`: PASS;
- macOS 15 packaging-runner build with warnings-as-errors: PASS;
- full test suite with coverage instrumentation: **8/8 PASS**;
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
- fallback geometry for non-notch displays
- compact/expanded panel state
- screen-space pointer activation/retention policy with hysteresis between compact and expanded regions
- M0 global pointer observation reduced to `mouseMoved` only; no button, drag, scroll, modifier, or keyboard event classes are monitored

### Tests and CI

- unit tests for geometry, panel state, and pointer retention
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

## First real-hardware acceptance — 2026-08-07

The first CI-produced DMG launched on the target MacBook, but hover behavior exposed a blocking M0 regression.

- `NH-BOOT-001`: PASS enough to reach and operate the running panel.
- `NH-HOVER-001`: FAIL on bootstrap build — repeated compact/expanded oscillation while hovering.
- Root cause confirmed in code: SwiftUI `onHover` directly controlled presentation while the resulting presentation change resized/animated the same `NSPanel`, creating a feedback path through transient hover exits.
- TDD RED commit: `eb4fb4d` (`test: reproduce hover retention regression`). CI failed exactly on `expandedPointerInsideExpandedRetentionRegionStaysExpanded` with `.compact` instead of `.expanded`.
- GREEN fix commit: `eff9bde` (`fix: stabilize notch hover retention`). Automated regression validation is now PASS.
- Latest build additionally enables App Sandbox/Hardened Runtime and limits global event observation to `mouseMoved` only.
- Latest fixed/security-hardened DMG physical retest: **PENDING**.

See `docs/TESTING.md` for stable acceptance scenario IDs and the test/manual boundary.

## Release trust prerequisites still external

The repository-side workflow is prepared, but trusted stable releases require one-time Apple credentials that must be configured by the repository owner directly in the GitHub `release` environment. Never send them through chat.

Required environment secrets are documented in `docs/RELEASING.md`:

- Developer ID Application `.p12` as base64 + its export password
- App Store Connect notarization `.p8` key + key ID + issuer ID

An Apple Developer Program membership is required to obtain Developer ID signing credentials.

## Known limitations

- latest sandbox + Hardened Runtime build has not yet been validated on the target MacBook;
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

1. Download the newest `NotchHub-dmg` artifact from PR #1 → latest successful CI run in GitHub Actions.
2. On the target MacBook/macOS 26.6 run `NH-OS26-001`, `NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, `NH-HOVER-003`, and `NH-SANDBOX-001`.
3. Record the physical results. If required M0 checks pass, mark PR #1 ready and merge by squash.
4. Configure the GitHub `release` environment with Apple credentials per `docs/RELEASING.md`.
5. Run the Release workflow to publish signed/notarized `v0.1.0` on GitHub Releases.
6. Run `NH-GATEKEEPER-001` once against the normally downloaded stable release.
7. Start M1 with display-change handling, active-screen migration, fullscreen/Spaces behavior, animation tuning, and expanded UI/gesture design based on independent product research.
