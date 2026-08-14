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

A previous physical candidate exposed pointer-exit/lost-terminal defects and an independently unproven hover/haptic symptom. The repaired candidate must be rebased/resumed after the testing foundation merges, pass the merged regression suite on a fresh exact head, then pass the focused physical retest and remaining gesture/Peek/seek/source-icon/lifecycle/permission matrix. Until that happens, PR #33 stays draft, unmerged and unreleased.

**M6.6 work remains frozen until PR #34 is merged and post-merge `main` CI is green.**

## T1 — Regression and UI Automation Foundation

Status: **IMPLEMENTED / AUTOMATED-VERIFIED / PR #34 FINAL HEAD VERIFICATION PENDING**

Delivered:

- native XCTest + XCUIAutomation harness in a checked-in test-only Xcode project;
- exact SwiftPM-built external `NotchHub.app` launch by URL;
- compile-time-only deterministic media/haptic fixtures;
- shipping-artifact fixture leak rejection;
- stable accessibility identifiers;
- predicate-driven waits with no fixed sleeps or automatic retries;
- screenshot, hierarchy, `.xcresult` and exact source-SHA diagnostics;
- real XCUI hover/pointer/media-control journeys;
- canonical `macOS UI regression` job on `macos-26` inside `.github/workflows/ci.yml`;
- separate provenance-backed foundation size envelope; historical budgets remain immutable.

The foundation does **not** declare M6.6 accepted and does not widen production permissions, networking, global input, subprocess or polling authority.

## T2 — Legacy Regression Baseline Backfill

Status: **IMPLEMENTED / STRICT GREEN ON PRE-DOC CANDIDATE / MERGE PENDING**

Authoritative plan: `docs/superpowers/plans/2026-08-14-legacy-regression-baseline-backfill.md`.

The accepted baseline is now completely represented by the machine-readable acceptance inventory:

- exact strict output: `discovered=90 mapped=90 unmapped=0 missingAutomation=30`;
- accepted deterministic M1 and M6.1-M6.5 behavior reuses concrete existing unit/integration/policy/shipping evidence where valid and adds XCUI evidence where the user-observable path is the reliable layer;
- genuinely physical cases retain narrow explicit reasons;
- pending/deferred M6.6 and deferred M1 IDs remain pending/deferred rather than being promoted for test-count optics;
- canonical CI runs `--mode strict` in both `macOS UI regression` and `Build, test and package`.

The acceptance status parser was also hardened under RED -> GREEN so ordinary lowercase behavioral terms such as `failed` cannot falsely convert a pending ID into a rejected acceptance result.

### Pre-documentation verification

Exact source `1e9ec7ac322ab4580f4f867e39457db915cfcb77`, CI #1051 / run `31847082833`:

- all three canonical jobs — SUCCESS;
- 250 Swift tests — PASS;
- strict acceptance traceability — 90/90 mapped, zero unmapped;
- security/signing/Sandbox/Hardened Runtime/shipping preflight/size/performance-smoke gates — PASS;
- `macOS UI regression` — three independent successful executions on the exact same source.

This completes implementation/backfill evidence, but PR #34 is not yet merged. A fresh docs-synchronized exact-head CI and final review remain mandatory before merge.

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

## Current priority order — 2026-08-15

1. Require a fresh canonical CI PASS on the documentation-synchronized exact head of PR #34.
2. Perform final change review: acceptance claims, production diff, security/trust boundaries, performance policy, fixture isolation and required checks must remain clean.
3. Mark PR #34 ready and merge through normal protected-branch rules only after the final exact-head checks are green; then require post-merge `main` CI.
4. Rebase/resume draft PR #33 only after the foundation is merged. Run the new regression suite against a fresh M6.6 head before target-Mac testing.
5. Run the focused physical repair retest and then the complete remaining M6.6 acceptance matrix. Only full physical PASS may advance PR #33 to merge; verify post-merge `main` CI.
6. Run P1 whole-app resource/performance review, including local-pointer and multi-monitor concerns.
7. Resume remaining product modules only after the testing/media/performance foundations are stable.
