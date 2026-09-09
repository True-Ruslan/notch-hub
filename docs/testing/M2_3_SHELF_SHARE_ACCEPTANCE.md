# M2.3 Shelf Share / AirDrop — Automated Acceptance

Status: **IMPLEMENTED / PRODUCTION CI GREEN / FINAL DOCUMENTED-HEAD CI PENDING / NOT MERGED / NOT RELEASED**

Date: 2026-09-09  
PR: #92  
Feature branch: `feat/m2-3-shelf-share`  
Verified production candidate head: `17d66ababca2a25c3c4294bd169ecbc46f8d1d25`  
Canonical production CI: `34322638424` (CI #1484)

## Acceptance policy

NotchHub uses automation-first acceptance for bounded personal-use product slices unless a feature specification explicitly elevates a physical check to a required gate.

M2.3 therefore uses the project state sequence:

**implemented → automated-accepted → merged → released**

Current state while this document is being added:

- Implemented: **YES**
- Production candidate verified: **YES**
- Final documented-head automated acceptance: **PENDING**
- Merged: **NO**
- Released: **NO**

A successful CI run on `17d66ababca2a25c3c4294bd169ecbc46f8d1d25` proves the shipping implementation itself. Because this acceptance record and security documentation change the branch head, the PR is not marked automated-accepted until the complete required CI matrix also succeeds on that later exact documented head.

## Accepted implementation scope

M2.3 adds one bounded native Share action to each persisted Shelf item:

- one Share action per Shelf row;
- native macOS `NSSharingServicePicker` with the resolved file URL as the shared item;
- system-provided sharing services, including AirDrop when macOS offers it for that item;
- existing read-only security-scoped bookmark resolution and unavailable-item behavior are reused;
- exactly one sharing scope may be owned at a time;
- a prior picker/scope is closed before a replacement scope is acquired;
- scope is released on picker cancellation, successful share, failed share, controller close, replacement, and normal application termination;
- Swift 6.3 actor-isolation compatibility is maintained with separate picker/service delegate boundaries rather than `@preconcurrency` suppression;
- no custom AirDrop/network transport, network entitlement, persistence field, polling/timer loop, global input monitor, source-file mutation, multi-selection, or third-party runtime dependency is introduced.

## Architecture and lifecycle

`ShelfShareAccessSession` in `NotchHubCore` is the deterministic security-scope boundary. It owns at most one active URL, releases a previous scope before replacement, fails closed on acquisition failure, makes `end()` idempotent, and balances every successful start exactly once.

`ShelfShareController` in `NotchHubApp` owns the AppKit picker and scope session on the main actor. `ShelfSharePickerDelegate` is a narrow nonisolated proxy for `NSSharingServicePickerDelegate`; cancellation is forwarded to a main-actor closure. `ShelfShareServiceDelegate` owns the native share completion callbacks and forwards success/failure to main-actor cleanup.

`AppDelegate` owns the controller for application lifetime, injects it through `ShelfRoutingRootView` into `ShelfView`, and closes it during normal termination.

## TDD and debugging evidence

M2.3 was implemented through observable RED → GREEN stages:

1. the initial test-only head defined `ShelfShareAccessSessionTests` before production code and canonical CI produced the expected missing-symbol compile RED;
2. core lifecycle commit `b2e7e199dcf72c9071953bb6bbd6709a5c089620` implemented the minimum scope session and made the four lifecycle tests GREEN;
3. app-layer policy commit `294d5bd887985f813451c79e03e2648d1c18616d` defined the native picker, composition, cleanup and forbidden-authority contract before the AppKit implementation existed;
4. the initial AppKit implementation reached `bc19a6801feb823401648227f416ebaed4ba764d`; CI #1482 / run `34322386278` then failed both independent shipping/UI compile gates with a real Swift 6.3 actor-isolation diagnostic: the `@MainActor` controller could not directly satisfy nonisolated `NSSharingServicePickerDelegate` requirements;
5. the failure was treated as an architecture boundary issue rather than suppressed. Policy commit `c0424ea092c025c186dbbe2b84144e21558b67c6` explicitly requires separate delegates and forbids `@preconcurrency`;
6. production fix `17d66ababca2a25c3c4294bd169ecbc46f8d1d25` introduced the narrow nonisolated picker proxy while keeping AppKit/state ownership on `@MainActor`;
7. CI #1484 / run `34322638424` then passed all three required jobs, including the new lifecycle/share policy tests, external application XCUITest smoke, packaging, effective entitlement, feature-size, provenance and performance gates.

## Exact production CI evidence

GitHub Actions run: `34322638424` (CI #1484)  
Exact production head: `17d66ababca2a25c3c4294bd169ecbc46f8d1d25`

All three required jobs succeeded.

### macOS 26 compatibility — SUCCESS

- macOS 26.6.2 / Swift 6.3.3 canonical runner;
- warnings-as-errors shipping build;
- MediaBridgeProbe CLI build;
- complete Swift test suite;
- M2.3 lifecycle and share policy tests;
- archived MediaBridgeProbe candidate build/verification/upload;
- ProductionMediaTransportCandidate build/verification/upload.

M2.3-specific GREEN tests include:

- security scope remains held until explicit end;
- failed scope acquisition creates no owned scope;
- replacement releases the prior scope before the next start;
- `end()` is idempotent;
- Shelf exposes the single-item Share action;
- native sharing picker and cleanup lifecycle are wired;
- picker delegate uses a nonisolated proxy and no `@preconcurrency` escape hatch;
- cancellation/success/failure release the sharing scope;
- Share adds no custom network/polling/global-monitor/source-file mutation authority;
- `AppDelegate` owns, injects and terminates the Share controller.

### macOS UI regression — SUCCESS

- UI project and fixture-isolation policy;
- strict acceptance traceability;
- exact UI-test application build;
- shipping-artifact UI-fixture exclusion;
- external application XCUITest smoke;
- UI diagnostics upload.

The external UI suite intentionally does **not** select a real macOS sharing destination or AirDrop recipient. Doing so would create nondeterministic external/system side effects and depend on runner services/devices. Native Share integration is instead verified by real AppKit compilation plus deterministic lifecycle/source-policy tests. Existing external-app XCUI remains the regression gate for app routing and application behavior.

### Build, test and package — SUCCESS

- release policy tests;
- performance policy tests;
- media bridge policy tests;
- strict acceptance traceability;
- performance policy audit;
- source/script/security validation;
- warnings-as-errors debug and probe builds;
- coverage-instrumented tests;
- release DMG build;
- bundle, Hardened Runtime, App Sandbox and exact entitlement verification;
- shipping-media preflight/provenance;
- deterministic artifact-size collection;
- existing active feature-size budget enforcement;
- performance-harness compatibility smoke;
- performance metadata and DMG artifact uploads.

M2.3 required **no feature-size budget expansion**: the existing M2.1 Shelf envelope accepted the candidate.

## Security result

The shipping entitlement set remains exactly:

- `com.apple.security.app-sandbox = true`;
- `com.apple.security.files.user-selected.read-only = true`.

M2.3 adds no read-write/broad file authority, application network entitlement/client, Automation/Apple Events, Accessibility, Input Monitoring, Screen Recording, dynamic-code exception, source-file delete/move/rename/copy path, polling loop, filesystem scan, global input monitor or new third-party runtime dependency.

The only longer-lived authority introduced by M2.3 is one read-only security scope associated with an explicit native sharing operation. Its lifetime is bounded by picker/service callbacks plus replacement/controller/application cleanup.

## Optional physical diagnostics

Physical use is not a merge/release blocker under the current automation-first policy. Useful optional diagnostics on the primary Mac include:

- share a normal document through a local system sharing service;
- verify AirDrop appears when available on the machine;
- cancel the picker and open it again;
- share item A, then replace it with item B;
- attempt Share for an unavailable item and verify fail-closed presentation;
- Quit while a picker is active;
- exercise Shelf Share on another display;
- verify no new privacy prompt or idle background activity appears.

Any deterministic defect found later should first be reproduced by an automated regression test.

## Stacked dependency and merge/release status

PR #92 intentionally targets `feat/m2-2-quick-look` while M2.2 PR #91 is waiting for the prepared v0.6.0 M2.1 release to be published from exact protected `main`.

The latest published release is still v0.5.0. Therefore:

- PR #91 must not be merged before v0.6.0 is published from its prepared `main` release commit;
- PR #92 must not be merged while that dependency/order remains unresolved;
- after #91 is merged, #92 should be retargeted to `main` and reverified before merge if the merge base changes materially;
- M2.3 must not be described as released until a later versioned GitHub Release actually contains it.

## Final documented-head gate

This file records the production candidate evidence but does not predeclare automated acceptance of the new documentation head. The final state becomes **AUTOMATED-ACCEPTED** only after the complete required CI matrix succeeds on the exact branch head containing this acceptance record and the matching M2.3 security/design documentation.
