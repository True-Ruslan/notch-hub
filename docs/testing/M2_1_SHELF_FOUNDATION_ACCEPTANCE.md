# M2.1 Shelf Foundation — Automated Acceptance

Status: **AUTOMATED-ACCEPTED / MERGED — RELEASE PENDING**

Date: 2026-09-08  
PR: #88  
Feature branch: `feat/m2-1-shelf-foundation`  
Final accepted PR head: `7f2a17cd39f15ec395560866c8d61e0c4cf9d5bf`  
Squash merge on `main`: `b0c1cf2f1054e754174099c31b1684f1742a11b2`

## Acceptance policy

The product owner explicitly chose automation-first acceptance because NotchHub is personal-use only. Physical acceptance is not a merge/release blocker unless a future specification explicitly makes a particular physical check mandatory.

M2.1 therefore uses the project state sequence:

**implemented → automated-accepted → merged → released**

Current state:

- Implemented: **YES**
- Automated-accepted: **YES**
- Merged: **YES**
- Released: **NO**

## Accepted scope

M2.1 adds a first-party file/folder Shelf with:

- Home ↔ Shelf routing in Expanded;
- a Shelf entry point while active media is expanded;
- collapse/reset back to Home semantics;
- native `NSOpenPanel` file/folder multi-selection;
- local SwiftUI file-URL drag/drop;
- persistent security-scoped bookmarks;
- duplicate suppression;
- stale bookmark refresh;
- Open and Show in Finder actions;
- Remove-reference semantics that never delete or move the source file;
- actor-backed atomic persistence;
- no polling, global input monitors or network access.

Compact/Peek media-first behavior remains outside Shelf routing.

## Security contract

Shipping entitlements are exactly:

- `com.apple.security.app-sandbox = true`;
- `com.apple.security.files.user-selected.read-only = true`.

M2.1 does **not** add read-write file access, network entitlements, Automation/Apple Events, Accessibility, Input Monitoring, Screen Recording, dynamic-code exceptions or source-file mutation.

Security-scoped access is short-lived and fail-closed:

- Open/Reveal does not execute if scope acquisition fails;
- stale bookmark refresh obtains and balances a temporary security scope;
- stored bookmarks are resolved with security scope;
- Remove only removes the persisted Shelf reference.

MediaBridgeProbe and ProductionMediaTransportCandidate keep their separately reviewed narrower entitlement policies.

## TDD evidence

The implementation was developed in RED → GREEN layers:

1. missing Shelf contracts produced compile RED;
2. compile skeletons exposed behavioral persistence/store RED;
3. the core Shelf implementation turned those tests GREEN;
4. missing Shelf UI/routing produced isolated UI-policy RED;
5. Shelf UI/routing implementation turned that layer GREEN;
6. entitlement/security policy tests preceded shipping entitlement expansion;
7. security-scope hardening tests reproduced fail-open/stale-refresh defects before the final fix;
8. a provenance-backed M2.1 size budget was introduced only after the previous M7 envelope correctly rejected the larger feature candidate.

## Final exact-head CI evidence

GitHub Actions run: `34267057068` (CI #1460)  
Exact head: `7f2a17cd39f15ec395560866c8d61e0c4cf9d5bf`

All required jobs succeeded:

### macOS 26 compatibility — SUCCESS

- warnings-as-errors build;
- MediaBridgeProbe CLI build;
- Swift test suite;
- MediaBridgeProbe candidate build/archive verification;
- ProductionMediaTransportCandidate build/archive verification.

### macOS UI regression — SUCCESS

- UI project/fixture isolation policies;
- strict acceptance traceability;
- exact UI-test application build;
- shipping-artifact fixture-marker exclusion;
- external application XCUITest smoke, including Shelf routing/reset paths.

### Build, test and package — SUCCESS

- release/performance/media policy tests;
- strict acceptance traceability;
- performance-policy audit;
- strict formatter/plist/shell/security validation;
- coverage-instrumented Swift tests;
- release DMG build;
- bundle/codesign/Hardened Runtime verification;
- exact shipping entitlement verification;
- shipping-media preflight/provenance;
- deterministic artifact sizes;
- active M2.1 feature-size budget;
- performance harness compatibility smoke;
- artifact uploads.

At final PR verification there were no unresolved review threads and no submitted review defects, and GitHub reported the PR mergeable.

## Size-budget evidence

Active budget: `performance/m2-1-shelf-foundation-size-budget.json`

Evidence candidate:

- source commit: `892f33027e5c2deceede1b1ad5a97cb1b7272fc3`;
- workflow run: `34265655415`;
- artifact ID: `10071918570`;
- app: `1,181,524` bytes;
- DMG: `728,679` bytes;
- executable: `879,216` bytes.

The immutable baseline remains unchanged and earlier feature budgets, including M7, remain historical provenance evidence.

## Physical/manual checks

No physical check is required to keep M2.1 merged or to release it under the current personal-use policy. Manual use can still reveal subjective or hardware-specific defects; deterministic defects found later should become regression tests.

## Release status

M2.1 is merged but not yet represented by a published version/tag. Release state must be updated only after GitHub Release/tag evidence exists.
