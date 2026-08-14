# Roadmap

Primary real-hardware target: macOS `26.6` / `Mac16,8`.
Current published Personal Release: `v0.1.0`.

This roadmap separates **implemented**, **automated-tested**, **physically accepted**, **merged**, and **released** states. Green CI is necessary but does not substitute for target-Mac acceptance when physical UI, haptics, permissions, third-party integration or resource behavior is part of the contract.

## M0 — Engineering foundation

Status: **ACCEPTED AND MERGED**

Native Swift 6/AppKit/SwiftUI structure, deterministic notch geometry, sandbox/hardened-runtime policy, CI/package/security foundations and initial real-hardware notch behavior are established.

## R0.1 — Personal Release foundation

Status: **ACCEPTED AND RELEASED**

Immutable `v0.1.0` remains the current published Personal build. Developer ID/notarization is optional/deferred; existing release tags are never replaced.

## P0 — Performance Foundation

Status: **ACCEPTED AND MERGED**

The immutable `v0.1.0` artifact/performance baseline remains historical evidence. Later intentional feature growth uses separate provenance-backed budgets. Target resource acceptance follows `PERFORMANCE.md`; shared-runner magnitudes are not promoted into tight target-hardware gates.

## P0.1 — Public repository readiness

Status: **ACCEPTED**

Public PR CI is read-only and secret-free. Release authority remains isolated from untrusted PR execution.

## M1 — Notch interaction and transition foundation

Status: **PRIMARY INTERACTION SLICE PHYSICALLY ACCEPTED AND MERGED**

Accepted foundations include cancellable 120 ms hover dwell, exact physical-notch compact geometry, bounded activation protection, haptic eligibility, `NotchPanelTransitionCoordinator` as sole transition authority, Reduce Motion behavior, lifecycle-owned pointer observation and event-driven/no-polling operation.

Deferred M1 hardening remains important but does not jump the current testing/media gates:

- active-display migration and multi-monitor behavior;
- fullscreen/Spaces;
- screen-configuration changes;
- notchless-screen mode;
- click/pin policy.

The narrow global `.mouseMoved` fallback remains pending the measured P1 local-tracking comparison.

## M6 — Universal Media / System Now Playing

Permanent product/security contract:

- follow the macOS system Now Playing source;
- remain player-agnostic;
- never fabricate capability support or metadata;
- keep media lifecycle bounded and resource-aware;
- no frequent media polling, repeating progress timer or display link;
- no listening-history persistence or production metadata logging;
- no Accessibility/Input Monitoring/synthetic media-key requirement;
- gestures remain local to NotchHub rather than adding global scroll capture.

### M6.1 — transport feasibility

Status: **PHYSICALLY ACCEPTED — `ACCEPT_TRANSPORT`**

Pinned compatibility transport passed Sandbox/Hardened Runtime, real observation/commands, source-switch/disappearance, sensitive-permission, lifecycle and target-resource acceptance.

### M6.2 — production media state/controller/bridge boundary

Status: **ACCEPTED AND MERGED**

Normalized player-agnostic state, ordering, typed commands, stale callback handling and bounded lifecycle are established.

### M6.3 — concrete production system transport

Status: **PHYSICALLY ACCEPTED AND MERGED**

The fixed `/usr/bin/perl` process boundary with pinned adapter/framework resources, bounded event-driven stream and closed typed command surface is accepted. `NH-MEDIA-PROD-001...013` target gates passed.

### M6.4 — shipping media composition

Status: **PHYSICALLY ACCEPTED AND MERGED**

Shipping composition preserves App Sandbox + Hardened Runtime, starts persistent media only for settled expanded state, returns compact to zero persistent adapter ownership and leaves no normal-Quit orphan. `NH-MEDIA-SHIP-001...010` passed.

### M6.5 — compact + expanded Media-first UI

Status: **PHYSICALLY ACCEPTED AND MERGED**

All `NH-MEDIA-UI-001...011` gates passed on `Mac16,8` / macOS 26.6. Expanded media presentation, capability-driven controls, event-driven progress, retained compact media context and zero-adapter compact lifecycle are accepted.

### M6.6 — local media gestures, haptics, Hover Peek and draggable seek

Status: **PARTIAL PREREQUISITES MERGED / CONSOLIDATED PR #33 AUTOMATED-GREEN / PHYSICAL RETEST PENDING**

The consolidated draft PR #33 is implemented and automated-tested. Frozen current physical candidate:

- source `423bc5d72a3676d01793f898ed2e8e79845bc8cd`;
- CI #962 / run `31685581542` — required automation PASS;
- target: `Mac16,8` / macOS 26.6.

A previous physical candidate exposed pointer-exit/lost-terminal defects and an independently unproven hover/haptic symptom. The repaired candidate must pass the focused physical retest first and then the remaining gesture/Peek/seek/source-icon/lifecycle/permission matrix. Until that happens, PR #33 stays draft, unmerged and unreleased.

**M6.6 work remains frozen while the regression foundation/backfill gate below is completed.**

## T1 — Regression and UI Automation Foundation

Status: **PLAN 1 COMPLETE / AUTOMATED-TESTED / PR #34 STILL DRAFT**

Delivered:

- native XCTest + XCUIAutomation harness in a checked-in test-only Xcode project;
- exact SwiftPM-built external `NotchHub.app` launch by URL;
- compile-time-only deterministic media/haptic fixtures;
- shipping-artifact fixture leak rejection;
- stable accessibility identifiers;
- predicate-driven waits with no fixed sleeps or automatic retries;
- screenshot, hierarchy, `.xcresult` and exact source-SHA diagnostics;
- real XCUI hover and typed media-control journeys;
- acceptance coverage manifest + validator with `audit` and `strict` modes;
- canonical `macOS UI regression` job on `macos-26` inside `.github/workflows/ci.yml`;
- separate provenance-backed foundation size envelope; historical budgets remain immutable.

Task-9 exact verification source `5e9341b4d957a967ec82166e18e009455119fd0b` passed CI #1007 / run `31817097807` with `macOS 26 compatibility`, `macOS UI regression`, and `Build, test and package` all SUCCESS. Production-diff review found no accidental product-feature or shipping trust-boundary change.

Plan 1 completion does **not** unblock M6.6. PR #34 remains draft because the accepted historical baseline still needs strict machine-readable traceability.

## T2 — Legacy Regression Baseline Backfill

Status: **ACTIVE / BLOCKING FEATURE WORK**

Authoritative plan: `docs/superpowers/plans/2026-08-14-legacy-regression-baseline-backfill.md`.

Current acceptance audit discovers **70 stable `NH-*` IDs**. The seed manifest maps **1** verified ID; **69** legacy mappings remain explicit debt.

Plan 2 must:

- complete the machine-readable inventory for all stable accepted IDs;
- reuse existing valid deterministic tests rather than duplicating them;
- add missing unit/integration/XCUI coverage where accepted behavior is deterministically observable;
- reserve `physicalOnlyReason` only for genuinely physical properties such as exact hardware geometry/feel, real permission surfaces, third-party integration or target-hardware resources;
- preserve historical accepted semantics rather than tuning production behavior to fit tests;
- keep M6.6 pending/rejected IDs out of accepted legacy backfill;
- switch canonical CI from `audit` to fail-closed `strict` only when the backfill is complete.

Exit criterion: `python3 scripts/test_acceptance_coverage.py --mode strict` passes in canonical CI and PR review finds no unsupported acceptance claims or product-feature changes.

Only after T2 strict PASS may PR #34 become merge-ready. Post-merge `main` CI is required before M6.6 resumes.

## P1 — whole-app performance/resource review

Status: **AFTER M6.6 ACCEPTANCE AND MERGE**

Planned:

- remeasure the real functional application rather than an isolated shell;
- compare the existing global `.mouseMoved` fallback against reliable window-local/`NSTrackingArea` tracking;
- adopt local tracking only if correctness and resource behavior are equal-or-better;
- evaluate more portable memory-footprint metrics and repeated-run variance;
- review wakeups, energy and compositor continuity in addition to CPU/RSS/threads;
- include multi-monitor/active-display reality when revisiting pointer/display ownership.

## Later product milestones

- **M2 Shelf:** sandbox-compatible file references, drag in/out, source-preserving removal and stale-reference handling.
- **M3 Snippets:** sandbox-local store, groups/search/copy/privacy; direct paste requires separate Accessibility review.
- **M4 Calendar:** EventKit adapter, permission/denial states and deterministic adapter coverage.
- **M5 Translator:** Apple Translation where available; no direct app-network translation without separate security review.
- **M7 Product shell:** settings, narrowly scoped shortcuts, launch-at-login, module ordering and privacy/security settings.
- **M8 Trusted distribution — optional:** Developer ID/notarization only if Apple Developer Program membership becomes worthwhile; never replace an existing Personal Release.

## Current priority order — 2026-08-14

1. Execute T2 / Plan 2 Task 1: build the complete machine-readable acceptance inventory/report and classify every stable accepted ID by deterministic/integration/UI/physical-only evidence needs.
2. Backfill M1 deterministic mappings and user-level XCUI journeys, then M6.1-M6.5 in plan order, reusing valid existing tests first.
3. Complete the manifest for all stable accepted IDs and switch acceptance validation to `strict` only when the debt reaches zero with justified physical-only cases.
4. Require strict PASS, review PR #34, merge only after all gates are green, then verify post-merge `main` CI.
5. Rebase/resume draft PR #33 only after the foundation is merged. Obtain a fresh exact-head M6.6 candidate and run the focused target-Mac repair retest plus complete remaining physical matrix.
6. Only full M6.6 physical PASS may advance PR #33 to merge; verify post-merge `main` CI.
7. Run P1 whole-app resource/performance review, including local-pointer and multi-monitor concerns.
8. Resume remaining product modules after the testing/media/performance foundations are stable.
