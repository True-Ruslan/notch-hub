# M2.2 Shelf Quick Look — Automated Acceptance

Status: **IMPLEMENTED / AUTOMATED-ACCEPTED / NOT MERGED / NOT RELEASED**

Date: 2026-09-08  
PR: #91  
Feature branch: `feat/m2-2-quick-look`  
Accepted production head: `6488e1f84cfad08c0fc557db4c811ae87c069dce`  
Canonical CI: `34284632091` (CI #1473)

## Acceptance policy

NotchHub uses automation-first acceptance for bounded personal-use product slices unless a feature specification explicitly elevates a physical check to a required gate.

M2.2 therefore uses the project state sequence:

**implemented → automated-accepted → merged → released**

Current state:

- Implemented: **YES**
- Automated-accepted: **YES**
- Merged: **NO**
- Released: **NO**

## Accepted scope

M2.2 adds one bounded native Quick Look action to each persisted Shelf item:

- one Preview action per Shelf row;
- native macOS `QLPreviewPanel` / QuickLookUI;
- existing bookmark resolution and unavailable-item handling are reused;
- read-only security-scoped access begins only from the explicit Preview action;
- scope remains owned while the preview is active;
- scope is released when the panel closes, when a replacement preview begins, when the controller closes, or when the application terminates;
- a failed replacement closes the old preview before attempting the new scope, so stale content is never left visible after its security scope has been released;
- no new entitlement, persistence field, network path, timer/polling loop, global input monitor, source-file mutation, multi-selection or Share/AirDrop authority is introduced.

M2.3 native Share/AirDrop remains a separate future slice.

## Architecture and lifecycle

`ShelfPreviewAccessSession` in `NotchHubCore` is the deterministic security-scope lifecycle boundary. It owns at most one active URL and balances every successful start with one stop.

`ShelfQuickLookController` in `NotchHubApp` owns AppKit/QuickLookUI integration. It remains `@MainActor`; the `QLPreviewPanelDataSource` implementation is a separate lock-protected non-actor object so Objective-C data-source callbacks remain compatible with both Swift 6.1-era and Swift 6.3.3 actor-isolation checking.

`AppDelegate` owns the controller for application lifetime and closes it during normal termination. `ShelfRoutingRootView` injects that owner into `ShelfView`; the view resolves the existing security-scoped bookmark and forwards only the explicit preview URL.

## TDD evidence

M2.2 was implemented through observable RED → GREEN stages:

1. test-only head `f45a2ee60bec39d873dbd78a4bde6b2f847402e5` failed compilation because `ShelfSecurityScopeControlling` / `ShelfPreviewAccessSession` did not exist;
2. core lifecycle commit `aba074bc8a9496cf9823fc716523f1e44bcf0a8d` made all four preview access-session tests GREEN, while CI #1468 still failed exactly the five expected app-layer Quick Look policy assertions;
3. initial app-layer wiring exposed a real Swift actor-isolation incompatibility in canonical macOS 26 / Swift 6.3.3 compilation;
4. compatibility commit `d47e3beff1ffd5f71ad2baa2af42da76a9d95627` separated the Quick Look data source from the main-actor controller and passed the macOS 26 compatibility job;
5. code review found a replacement edge case: starting a second preview first ended the old scope, so a failed new scope could leave the old panel visible without its access scope;
6. test-only commit `9fdc78f49f3e7776563642a2934ac2912f0cab1a` reproduced that condition as one isolated RED issue: 497 tests / 105 suites with exactly the new regression failing;
7. production fix `6488e1f84cfad08c0fc557db4c811ae87c069dce` closes/clears the old preview before acquiring the replacement scope, turning all 497 tests GREEN.

## Exact-head CI evidence

GitHub Actions run: `34284632091` (CI #1473)  
Exact production head: `6488e1f84cfad08c0fc557db4c811ae87c069dce`

All three required jobs succeeded.

### macOS 26 compatibility — SUCCESS

- warnings-as-errors shipping build;
- MediaBridgeProbe CLI build;
- all 497 Swift tests, including the replacement fail-closed regression;
- archived MediaBridgeProbe candidate build/verification/upload;
- ProductionMediaTransportCandidate build/verification/upload.

### macOS UI regression — SUCCESS

- UI project and fixture-isolation policies;
- strict acceptance traceability;
- exact UI-test application build;
- shipping-artifact UI-fixture exclusion;
- external application XCUITest smoke.

### Build, test and package — SUCCESS

- release/performance/media policy tests;
- strict acceptance traceability;
- performance-policy audit;
- source/script/security validation;
- warnings-as-errors debug build;
- coverage-instrumented tests;
- release DMG build;
- bundle, Hardened Runtime, App Sandbox and entitlement verification;
- shipping-media preflight/provenance;
- deterministic artifact-size collection;
- existing M2.1 active feature-size budget enforcement;
- performance-harness compatibility smoke;
- performance metadata and DMG artifact uploads.

M2.2 required **no size-budget expansion**: the existing M2.1 feature envelope accepted the final Quick Look candidate.

## Security result

The shipping entitlement set remains exactly:

- `com.apple.security.app-sandbox = true`;
- `com.apple.security.files.user-selected.read-only = true`.

Quick Look adds no read-write file access, network entitlement, Automation/Apple Events, Accessibility, Input Monitoring, Screen Recording, dynamic-code exception or source-file mutation path.

A security scope is held longer than Open/Reveal only for the explicit duration of an active native preview. That lifetime is bounded by the Quick Look panel/controller and is closed fail-safe on replacement and application termination.

## Optional physical diagnostics

Physical use is not a merge/release blocker under the current automation-first policy, but the following are useful diagnostics on the primary Mac:

- preview a normal document/image/PDF from Shelf;
- close Quick Look and reopen it;
- preview item A then item B;
- preview item A, make item B unavailable, then attempt B and verify A is not left stale on screen;
- Quit while Quick Look is open;
- exercise Shelf/Quick Look on another display;
- verify no new privacy prompt or background activity appears.

Any deterministic defect found later should be converted into a regression test before its fix.

## Merge/release status

This document records automated acceptance only. PR #91 must not be described as merged until GitHub merge evidence exists, and M2.2 must not be described as released until a later published tag/GitHub Release contains it.
