# Project state

Last updated: 2026-09-08

## Publication state

- `VERSION`: **0.5.0**
- Latest published Personal Release: **v0.5.0**
- M2.1 Shelf Foundation: **implemented / automated-accepted / merged / not yet released**
- M2.1 squash merge on `main`: `b0c1cf2f1054e754174099c31b1684f1742a11b2`

Do not infer release state from merged code or `VERSION`. GitHub tag/release state is authoritative for publication.

## Primary target and governance

- Product target: native macOS, primarily macOS 26.6.
- Important real scenario: multi-monitor / active-display changes.
- `main` is protected and product changes flow through pull requests with required CI.
- Canonical required jobs: `macOS 26 compatibility`, `macOS UI regression`, `Build, test and package`.
- No force-push/deletion workflow is part of normal development.

From 2026-09-08 the default lifecycle is:

**implemented → automated-accepted → merged → released**

NotchHub is personal-use. Physical/manual checks are optional diagnostics by default, not merge/release blockers, unless a future specification explicitly elevates one.

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
- no source-file mutation from Shelf Remove;
- security-scoped resource use is short-lived, balanced and fail-closed;
- development media probe/candidate binaries retain separately reviewed narrower policies.

See `SECURITY.md` for the complete policy.

## Current performance baseline

Performance and energy remain first-class requirements:

- event-driven behavior is preferred over polling/timers;
- unreviewed runtime timers are rejected by policy;
- deterministic shipping artifact sizes are collected in CI;
- the immutable baseline remains `performance/baseline-v0.1.0.json`;
- current active feature envelope is `performance/m2-1-shelf-foundation-size-budget.json`;
- older feature budgets remain immutable provenance evidence;
- CI runs the performance harness compatibility smoke for shipping candidates.

## M2.1 Shelf Foundation

PR #88 introduced the first shipping Shelf slice.

### User-visible behavior

- Expanded Home can open Shelf;
- active Expanded media exposes a Shelf action without modifying the media rendering internals;
- leaving Expanded resets the destination to Home;
- Compact/Peek preserve media-first behavior;
- files and folders can be selected through native `NSOpenPanel` with multi-select;
- local file-URL drag/drop is supported;
- persisted items can be Opened, Shown in Finder or removed from Shelf;
- Remove deletes only the Shelf reference, never the source item.

### Architecture

- `NotchDestinationModel` owns bounded Home/Shelf destination state;
- `ShelfRoutingRootView` composes Shelf routing around the existing media root instead of pushing Shelf state into media rendering internals;
- `ShelfStore` is a main-actor observable store for UI state/actions;
- `ShelfPersistenceRepository` is actor-backed and writes its JSON state atomically;
- `SecurityScopedShelfBookmarkCodec` owns creation/resolution/refresh of read-only security-scoped bookmarks;
- no recurring Shelf timer, filesystem scan, global input monitor or network client was introduced.

### Automated acceptance evidence

Final accepted PR head: `7f2a17cd39f15ec395560866c8d61e0c4cf9d5bf`  
CI run: `34267057068` (#1460)

All three required jobs succeeded on that exact head:

- macOS 26 compatibility;
- macOS UI regression, including external-app Shelf routing/reset smoke;
- Build, test and package, including security/signing/entitlement/DMG/provenance/size/performance gates.

The PR had no unresolved review threads at final verification and was squash-merged as `b0c1cf2f1054e754174099c31b1684f1742a11b2`.

Detailed evidence: `docs/testing/M2_1_SHELF_FOUNDATION_ACCEPTANCE.md`.

## Released product foundation

The latest published release remains v0.5.0 and includes the established engineering/performance/media/settings foundation. Historical acceptance/performance/release evidence is intentionally kept in:

- `docs/testing/`;
- `docs/superpowers/specs/` and `docs/superpowers/plans/`;
- `performance/`;
- `CHANGELOG.md`;
- GitHub Releases/tags and Actions artifacts.

This state file is intentionally concise and should describe the present, not duplicate the entire project history.

## Work in progress

Governance/state documentation is being synchronized with the automation-first policy after M2.1 merge.

No M2.1-containing version has been published yet. The next release step must keep `merged` and `released` distinct until the GitHub Release/tag exists.

## Next optimal product work

After the governance/release sync, design M2.2 as a bounded Shelf usability slice. The current candidates are native selection/multi-selection, Quick Look, Share services, keyboard-accessible actions and better unavailable-item presentation.

Do not implement all candidates by default. Select the smallest coherent native workflow, write RED tests/policy constraints first, then ship it behind the same security/performance/automation gates.
