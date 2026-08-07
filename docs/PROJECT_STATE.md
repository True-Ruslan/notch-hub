# Project state

Last updated: 2026-08-07
Current development version: `0.1.0` (unreleased)
Integration PR: #1 `Bootstrap native macOS foundation`
Primary real-hardware target: macOS `26.6`

## Product

NotchHub is a personal, native, local-first macOS productivity hub built around the MacBook notch. Planned modules are Shelf, Snippets, Calendar, Translator, and media controls with Yandex Music as the primary player.

NotchNook is tracked only as a public product/UI reference. NotchHub is an independent implementation; see `docs/PRODUCT_REFERENCES.md`.

## Current milestone

**M0 — Engineering foundation: ACCEPTED on real hardware.**

The corrected sandboxed/Hardened Runtime build was retested on the target MacBook running macOS 26.6. All mandatory M0 notch/hover acceptance scenarios now pass. PR #1 is ready for final CI and squash merge.

## Latest automated validation

CI run #20 for documentation head based on production fix `3bb1bbb` passed the complete pipeline:

- GitHub `macos-26` compatibility: PASS;
- observed runner: macOS 26.5.2, Xcode 26.6, Swift 6.3.3;
- warnings-as-errors build: PASS;
- full unit/regression suite: **10/10 PASS**;
- strict Swift format: PASS;
- `scripts/security-audit.sh`: PASS;
- coverage-instrumented test run: **10/10 PASS**;
- release-mode app/DMG build: PASS;
- code-signature verification: PASS;
- Hardened Runtime verification: PASS;
- effective App Sandbox entitlement verification: PASS;
- M0 system-dylib-only inspection: PASS;
- DMG integrity (`hdiutil verify`): PASS;
- GitHub Actions artifact upload: PASS.

GitHub-hosted macOS 26 CI is a near-target automated layer; the exact macOS 26.6 physical-notch behavior is covered by the hardware acceptance below.

## Implemented in M0

### Runtime foundation

- Swift 6 / Swift Package Manager project layout
- macOS 14 minimum deployment target
- SwiftUI + AppKit application shell
- accessory/background-style app without Dock icon
- borderless non-activating `NSPanel`
- hardware-notch geometry derived from public `NSScreen` APIs
- exact detected hardware-notch width for compact mode; 180 pt is fallback-only for displays without a notch
- compact/expanded presentation state
- deterministic screen-space pointer activation/retention policy
- `NSHostingView.sizingOptions = []` so `NotchPanelController` remains the sole owner of window geometry
- global observation restricted to `mouseMoved`; no keyboard, button, drag, scroll, or modifier monitoring

### Tests and CI

- deterministic tests for geometry, state, pointer retention, exact notch width, and AppKit/SwiftUI sizing ownership
- RED → GREEN TDD policy with actual failing regression runs preserved in PR history
- strict formatting and warnings-as-errors
- test coverage instrumentation
- macOS 26 compatibility job
- app/DMG packaging and bundle/signature/entitlement/library/integrity checks
- stable real-hardware acceptance IDs in `docs/TESTING.md`

### Security baseline

- App Sandbox enabled with a minimal entitlement set
- Hardened Runtime enabled for test and stable builds
- zero third-party Swift runtime dependencies at M0
- no telemetry, analytics, ads, licensing backend, or direct network access
- no runtime shell/subprocess execution
- no dynamic code/plugin loading
- no global keyboard monitoring
- GitHub Actions pinned to immutable full commit SHAs
- executable `scripts/security-audit.sh` fail-closed baseline
- release path requires Developer ID signing, notarization, stapling, Gatekeeper assessment, and checksum before publication

### Versioning and distribution

- Semantic Versioning via repository-root `VERSION`
- `CHANGELOG.md`
- CI-produced ad-hoc DMG artifacts for development testing
- GitHub Release workflow prepared for trusted signed/notarized releases

## Real-hardware acceptance history — 2026-08-07

### Cycle 1 — bootstrap build

- `NH-BOOT-001`: PASS enough to run the application.
- `NH-HOVER-001`: FAIL — compact/expanded oscillation during hover.
- RED commit `eb4fb4d`: regression test failed for the expected reason.
- GREEN commit `eff9bde`: pointer authority moved from raw SwiftUI `onHover` events to deterministic screen-space policy.

### Cycle 2 — sandbox/Hardened Runtime build

Target MacBook, macOS 26.6:

- `NH-OS26-001`: PASS.
- `NH-NOTCH-001`: FAIL — compact panel a few pixels wider than hardware notch.
- `NH-HOVER-001`: PASS.
- `NH-HOVER-002`: PASS.
- `NH-HOVER-003`: FAIL — compact content appeared while the black `NSPanel` shell remained expanded.
- `NH-SANDBOX-001`: earlier report was interpreted as PASS by matrix order; the source message duplicated the `NH-HOVER-003` label, so that ambiguity remains documented rather than rewritten as an explicit user label.

RED commit `c518326` added both regressions before production changes. macOS 26 CI then failed exactly two tests: width `180` vs expected `176`, and hosting sizing options raw value `7` vs expected empty.

GREEN commit `3bb1bbb` fixed both defects. CI run #19 passed 10/10 tests and all security/package gates.

### Cycle 3 — corrected build, final M0 retest

Target MacBook, macOS 26.6:

- `NH-NOTCH-001`: **PASS**.
- `NH-HOVER-001`: **PASS**.
- `NH-HOVER-002`: **PASS**.
- `NH-HOVER-003`: **PASS**.

**M0 acceptance result: PASS.** No mandatory M0 physical-notch blocker remains.

## Release trust prerequisite

The repository-side stable release workflow is ready, but `v0.1.0` must not be published as a trusted stable release until Apple signing/notarization credentials are configured in the GitHub `release` environment.

Required secrets are documented in `docs/RELEASING.md` and must be configured directly in GitHub, never sent through chat:

- Developer ID Application `.p12` + export password
- App Store Connect notarization `.p8` key + key ID + issuer ID

An Apple Developer Program membership is required for Developer ID distribution.

## Known limitations / next milestone

M0 is accepted. Remaining work belongs to M1 or later:

- active-display migration and display-change handling
- fullscreen/Spaces behavior
- animation and interaction tuning
- final product UI instead of the foundation preview
- feature modules are not yet implemented
- Yandex Music integration is planned, not implemented
- trusted Developer ID/notarized release waits for Apple credentials

## Next optimal step

1. Final CI on this acceptance-state commit must be green.
2. Mark PR #1 Ready and squash-merge it into protected `main`.
3. Configure the GitHub `release` environment according to `docs/RELEASING.md`.
4. Publish trusted `v0.1.0` through the Release workflow.
5. Run `NH-GATEKEEPER-001` once against the normally downloaded stable release.
6. Start M1 — Notch Core hardening: display migration, Spaces/fullscreen, reduced-motion/animation behavior, and refined interaction/UI architecture.
