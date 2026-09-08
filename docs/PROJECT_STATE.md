# Project state

Last updated: 2026-09-08

## Publication state

- Checked-in `VERSION`: **0.6.0**.
- Latest published Personal Release: **v0.5.0**.
- v0.6.0 release preparation: **merged to `main` via PR #90**, but **not yet published** as a GitHub tag/release.
- M2.1 Shelf Foundation: **implemented / automated-accepted / merged / not yet released**.
- M2.2 Shelf Quick Look: **implemented / automated-accepted on PR #91 / not merged / not released**.

Do not infer release state from merged code or `VERSION`. GitHub tag/release state is authoritative for publication.

## Primary target and governance

- Product target: native macOS, primarily macOS 26.6.
- Important real scenario: multi-monitor / active-display changes.
- `main` is protected and product changes flow through pull requests with required CI.
- Canonical required jobs: `macOS 26 compatibility`, `macOS UI regression`, `Build, test and package`.
- No force-push/deletion workflow is part of normal development.

From 2026-09-08 the default lifecycle is:

**implemented → automated-accepted → merged → released**

NotchHub is personal-use. Physical/manual checks are optional diagnostics by default, not merge/release blockers, unless a feature specification explicitly elevates one.

## Current security baseline

Shipping NotchHub uses App Sandbox + Hardened Runtime with the exact reviewed entitlement set:

- `com.apple.security.app-sandbox = true`;
- `com.apple.security.files.user-selected.read-only = true`.

The read-only user-selected entitlement exists solely for explicit Shelf file/folder selection and persistent security-scoped bookmarks.

Current security invariants:

- no broad read-write file entitlement;
- no network entitlement;
- no telemetry;
- no Automation/Apple Events entitlement;
- no Accessibility/Input Monitoring/Screen Recording requirement;
- no dynamic-code exceptions;
- no source-file mutation from Shelf actions;
- security-scoped resource use is explicit, balanced and fail-closed;
- Quick Look may hold one read-only security scope only for the lifetime of an explicitly active native preview;
- development media probe/candidate binaries retain separately reviewed narrower policies.

See `SECURITY.md` for the complete policy.

## Current performance baseline

Performance and energy remain first-class requirements:

- event-driven behavior is preferred over polling/timers;
- unreviewed runtime timers are rejected by policy;
- deterministic shipping artifact sizes are collected in CI;
- the immutable baseline remains `performance/baseline-v0.1.0.json`;
- current active feature envelope remains `performance/m2-1-shelf-foundation-size-budget.json`;
- M2.2 Quick Look fits inside that existing envelope and required no budget expansion;
- older feature budgets remain immutable provenance evidence;
- CI runs the performance harness compatibility smoke for shipping candidates.

## M2.1 Shelf Foundation

PR #88 introduced the first shipping Shelf slice and was squash-merged as `b0c1cf2f1054e754174099c31b1684f1742a11b2`.

Implemented behavior includes:

- Expanded Home ↔ Shelf routing;
- Shelf access while media is active in Expanded;
- collapse/reset back to Home semantics;
- native file/folder multi-select picker;
- local file-URL drag/drop;
- persistent read-only security-scoped bookmarks;
- duplicate suppression and stale bookmark refresh;
- Open / Show in Finder / Remove-reference;
- actor-backed atomic persistence;
- exact least-privilege shipping entitlement set;
- external-app XCUI routing/reset coverage;
- provenance-backed size/performance gates.

Final automated acceptance: CI #1460 / run `34267057068` on exact PR head `7f2a17cd39f15ec395560866c8d61e0c4cf9d5bf`.

Detailed evidence: `docs/testing/M2_1_SHELF_FOUNDATION_ACCEPTANCE.md`.

## v0.6.0 release preparation

PR #90 prepared the first Personal Release containing M2.1:

- checked-in version bumped to `0.6.0`;
- checked-in `CFBundleShortVersionString` synchronized;
- `docs/releases/v0.6.0.md` added;
- no runtime/security/persistence/media behavior changed in the release-prep PR.

PR #90 was automated-accepted and squash-merged as `cc023e4720ae733770a8e9fe7926c514d0ab3fdf`.

Publication is still pending because no `v0.6.0` GitHub Release/tag exists yet. The latest published release therefore remains `v0.5.0`.

## M2.2 Shelf Quick Look

PR #91 adds the next bounded Shelf usability slice.

### User-visible behavior

- each persisted Shelf item has a Preview action;
- Preview uses native macOS `QLPreviewPanel`;
- existing bookmark resolution/unavailable-state handling is reused;
- only one preview is owned at a time;
- replacing a preview closes the prior preview before acquiring the next file scope;
- failed replacement therefore fails closed instead of leaving stale content visible without its security scope.

### Architecture/security

- `ShelfPreviewAccessSession` is the testable Core security-scope lifecycle boundary;
- `ShelfQuickLookController` is the app-owned main-actor AppKit/QuickLookUI boundary;
- its Objective-C data-source callbacks are isolated in a separate lock-protected `ShelfQuickLookDataSource` for Swift 6 actor-isolation compatibility;
- `AppDelegate` owns/tears down the controller;
- no new entitlement, persistence schema, network path, timer/polling loop, global monitor or source-file mutation was added.

### Automated acceptance evidence

Accepted production head: `6488e1f84cfad08c0fc557db4c811ae87c069dce`  
CI run: `34284632091` (#1473)

All three required jobs succeeded on that exact production head:

- macOS 26 compatibility, including all **497 Swift tests**;
- macOS UI regression, including external-app XCUITest smoke;
- Build, test and package, including security/signing/entitlement/DMG/provenance/size/performance gates.

The existing M2.1 feature-size budget accepted M2.2; no size-envelope expansion was needed.

Detailed evidence: `docs/testing/M2_2_SHELF_QUICK_LOOK_ACCEPTANCE.md`.

## Work in progress

M2.2 documentation/final PR verification is being completed on PR #91. It must remain distinct from merge and release state until GitHub evidence exists.

Separately, `v0.6.0` publication is still pending from exact protected `main` through the existing manual Personal Release workflow.

## Next optimal product work

After PR #91 is merged, the next bounded Shelf slice should be **M2.3 native Share/AirDrop** rather than broadening into multi-selection, clipboard/snippet ownership or file mutation.

Constraints remain:

- native macOS APIs first;
- no source-file mutation;
- no new broad entitlement;
- no polling/global input monitoring;
- no Shelf clipboard ownership (text/URL snippets belong to M3);
- preserve media-first Compact/Peek semantics and single panel-transition authority.
