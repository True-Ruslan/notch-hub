# Roadmap

Primary real-hardware target: macOS `26.6` / `Mac16,8`.
Current published Personal Release: `v0.1.0`.

This roadmap separates **implemented**, **automated-tested**, **physically accepted**, **merged**, and **released** states. A green CI run does not substitute for target-Mac acceptance when physical UI, permissions, third-party integration or resource behavior is part of the contract.

## M0 — Engineering foundation

Status: **ACCEPTED AND MERGED**

Delivered Swift 6 native application structure, deterministic notch geometry, AppKit/SwiftUI ownership, App Sandbox + Hardened Runtime, strict CI/package/security policy, documentation foundations and real-hardware notch/hover acceptance.

## R0.1 — Personal Release foundation

Status: **ACCEPTED AND RELEASED**

Immutable `v0.1.0` is the current published Personal build. It is ad-hoc signed, sandboxed, Hardened Runtime protected, checksum/provenance verified and intentionally not notarized. Paid Apple Developer Program membership remains optional/deferred.

## P0 — Performance Foundation

Status: **ACCEPTED AND MERGED**

The immutable `v0.1.0` performance/artifact baseline remains historical evidence. Repeated target measurements later proved that absolute cross-session `ps rss` and isolated one-second CPU maxima are not portable enough to act alone as release gates. `PERFORMANCE.md` therefore uses same-session comparison for steady compact memory, direct long-run RSS/thread growth gates, CPU median plus contextual spike review, and deterministic artifact-size policy.

No immutable baseline file is rewritten to obtain later feature acceptance.

## P0.1 — Public repository readiness

Status: **ACCEPTED**

Public fork CI is read-only, secret-free and GitHub-hosted. Release authority remains isolated from untrusted PR execution.

## M1 — Notch interaction and transition foundation

Status: **PRIMARY INTERACTION SLICE ACCEPTED AND MERGED**

Accepted:

- 120 ms cancellable hover dwell;
- inclusive 4 pt left/right/bottom and 0 pt top activation protection;
- exactly one eligible `.levelChange` haptic;
- single `NotchPanelTransitionCoordinator` transition authority;
- public AppKit/Core Animation transition path;
- Reduce Motion exact endpoint behavior;
- explicit event-monitor/observer ownership;
- no per-event Swift concurrency allocation in the pointer hot path;
- no polling/repeating timer/display-link/sensitive input permission;
- M6.6 Task 0 later proved in-flight compact-layout retargeting through the same transition authority without duplicate haptic.

Deferred M1 hardening:

- active-display migration and multiple displays;
- fullscreen/Spaces;
- screen-configuration changes;
- notchless-screen mode;
- click/pin policy.

The global `.mouseMoved` fallback remains pending the measured P1 local-tracking experiment.

## M6 — Universal Media / System Now Playing

Product contract:

- follow the macOS system Now Playing source;
- remain player-agnostic;
- never fabricate capability support or metadata;
- keep media lifecycle bounded and resource-aware;
- no frequent media polling or always-running one-second timer;
- no listening-history persistence or production metadata logging;
- no Accessibility/Input Monitoring/synthetic media-key requirement;
- keep gestures local to NotchHub rather than adding global scroll capture.

### M6.1 — transport feasibility

Status: **ACCEPTED — `ACCEPT_TRANSPORT`**

The pinned external compatibility mechanism physically passed Sandbox/Hardened Runtime, authoritative capability, real command, source-switch/disappearance, permission, lifecycle and target-resource acceptance with Yandex Music/Yandex Browser.

### M6.2 — production media state/controller/bridge boundary

Status: **ACCEPTED AND MERGED**

Delivered normalized media domain/state, generation/revision ordering, player-agnostic provider/controller boundary, injected system transport, typed commands, stale callback rejection and bounded restart/fail-closed behavior.

### M6.3 — concrete production system transport

Status: **ACCEPTED AND MERGED**

Delivered the fixed `/usr/bin/perl` production process boundary, pinned adapter/framework provenance, event-driven stream, strict capability schema, bounded media payloads, fixed typed commands and clean teardown.

All `NH-MEDIA-PROD-001...013` target gates passed.

### M6.4 — shipping media composition

Status: **ACCEPTED AND MERGED**

PR #17 merge: `4ba603e1c3564d6cdf58169a7936f1954dee2ffd`.

Accepted shipping invariants:

- `NotchHubApp` links `NotchHubMediaCore` and exact pinned media assets;
- nested/top-level signatures, Sandbox-only entitlement and Hardened Runtime stay intact;
- runtime starts only after settled expansion;
- runtime stops/releases after settled compact;
- compact owns zero persistent adapter processes;
- expanded owns one expected adapter;
- stale/reversed transition completions cannot start media;
- normal termination leaves no orphan;
- no sensitive permission prompts;
- M6.4 shipping growth uses a separate feature-size budget over the immutable P0 baseline.

All `NH-MEDIA-SHIP-001...010` gates passed.

### M6.5 — compact + expanded Media-first UI

Status: **ACCEPTED AND MERGED — ALL `NH-MEDIA-UI-001...011` PASS**

Integration:

- PR #19 squash merge `5305dbb87d7a2d0d1c7e4bc1eba156cfcafd4e86`;
- final PR head `db243614d9b50cc857150bef30027d5478f23d11`;
- final PR-head CI #771 — PASS;
- post-merge `main` CI #772 / run `31543163536` — PASS.

Frozen physical candidate: `431d9fbaf1ff5ba98f2ceec09732acafe5f65794`.
Physical candidate CI: #763 / run `31539442148` — PASS on exact source after retrying one external runner TLS failure without weakening TLS/security policy.

Accepted:

- exact-notch cold/no-media compact with zero adapter;
- App-owned presentation projection from authoritative media state;
- expanded Media-first artwork/metadata/source UI;
- capability-driven previous/play-pause/next controls;
- trustworthy static/event-driven progress without periodic polling;
- missing metadata/capabilities remain absent/disabled rather than fabricated;
- media disappearance while expanded -> Home without collapse;
- normal collapse retains visual context while stopping runtime;
- 36 pt symmetric compact media wings around the unchanged physical notch;
- fresh expanded runtime replaces retained context;
- Yandex Music and Yandex Browser physical behavior PASS;
- zero adapter after compact settlement and no orphan after Quit;
- no Accessibility/Input Monitoring/Automation/Screen Recording prompts;
- explicit M6.5 provenance-backed size envelope without rewriting P0 or M6.4 budgets.

Authoritative evidence: `docs/testing/MEDIA_UI_ACCEPTANCE.md`.

### M6.6 — local media gestures, haptics and draggable seek

Status: **TASK 0 ACCEPTED AND MERGED / GESTURE CONTRACT FROZEN / IMPLEMENTATION NEXT**

#### Task 0 — collapse-layout retarget hardening

**ACCEPTED AND MERGED.** Issue #20 was reproduced under TDD and fixed without changing panel authority.

Evidence:

- RED source `785c48d8cc6831f4196cfa7c78843b826acb9a07`, CI #775 / run `31567022553`;
- exact GREEN/physical source `0d40391721ae934653a9c75fc981dd683121cf46`;
- GREEN CI #776 / run `31567162859` — 196 Swift tests / 39 suites PASS and both required jobs PASS;
- PR #22 squash merge `f017addd2efc9aed5b60b1556205bdb8eab23e0e`;
- post-merge `main` CI #777 / run `31572634042` — both required jobs PASS;
- focused target-Mac acceptance PASS, including media disappearance during in-flight collapse, exact no-media compact endpoint, no duplicate haptic, zero adapter after compact settlement and no orphan after Quit.

#### Gesture + haptic + seek contract

Stable `NH-MEDIA-GESTURE-001...018` acceptance IDs are frozen in `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md` and the TDD execution plan is `docs/superpowers/plans/2026-08-12-media-gestures-haptics-seek.md`.

The implementation must:

- use a pure deterministic `MediaGestureCoordinator` with commit-on-release;
- keep all scroll/gesture recognition local to the NotchHub-owned view/window;
- use the approved 28% / 70...120 pt horizontal threshold and 20 pt disarm hysteresis before hardware tuning;
- reject momentum and ambiguous diagonal movement;
- request one `.levelChange` haptic only when entering armed;
- preserve horizontal/vertical/seek interaction isolation;
- route compact-down / expanded-up through existing panel transition authority;
- make draggable seek actionable only with authoritative seek capability and valid timing;
- never fabricate successful seek/track changes before authoritative system state confirms them;
- preserve event-driven progress and zero persistent adapter in compact.

Because retained compact media is intentionally not live-observed, compact previous/next arming must use a bounded current-system one-shot capability validation rather than blindly trusting stale retained capability. Release while armed may send one bounded typed one-shot command. This reuses the existing fixed pinned `/usr/bin/perl` boundary and may not start persistent observation. One-shot process ownership/cancellation is the first TDD implementation task so normal Quit remains no-orphan even if an operation is in flight.

### P1 — whole-app performance/resource review

Status: **AFTER M6.6**

Planned:

- remeasure the real functional application rather than an isolated shell;
- compare existing global `.mouseMoved` fallback against a reliable window-local/`NSTrackingArea` design;
- adopt local tracking only if correctness and resource behavior are equal-or-better;
- evaluate a more portable absolute memory-footprint metric;
- characterize repeated-run variance before adding any new absolute cross-session memory ceiling;
- review wakeups/energy/compositor continuity in addition to CPU/RSS/threads.

## M2 — Shelf

Planned after the current media/performance priority sequence:

- drag files into/out of Shelf;
- sandbox-compatible user-selected/security-scoped access;
- removing a Shelf reference must never delete the source file;
- stale-reference handling and deterministic source-preservation tests.

## M3 — Snippets

Planned:

- sandbox-local store;
- groups/search/copy;
- privacy mode;
- direct paste only after a separate Accessibility/security decision, with copy-only fallback.

## M4 — Calendar

Planned:

- EventKit adapter;
- next-event UI;
- explicit permission denial/availability states;
- deterministic adapter tests plus minimal real-permission acceptance.

## M5 — Translator

Planned:

- Apple Translation framework where available;
- language handling/swap/copy;
- optional clipboard translation;
- no direct app-network translation without separate security review.

## M7 — Product shell

Planned:

- settings;
- narrowly scoped shortcuts;
- supported launch-at-login APIs;
- module ordering/enable-disable;
- accessibility/privacy/security settings.

## M8 — Trusted distribution and maintenance — optional

Only when Apple Developer Program membership becomes worthwhile:

- create/review the GitHub `release` environment;
- provision signing/notarization credentials as environment-scoped secrets;
- validate Developer ID/notarization/stapling/Gatekeeper on a new version;
- never replace an existing Personal Release tag/version.

## Current priority order — 2026-08-12

1. M6.6 Task 1: harden ownership/cancellation of in-flight media one-shot processes under RED -> GREEN tests.
2. Implement the deterministic `MediaGestureCoordinator` and local-only AppKit delivery seam under TDD.
3. Implement bounded compact capability validation + previous/next dispatch, then expanded gesture/haptic wiring.
4. Implement capability-gated draggable seek with seek/track/panel gesture isolation.
5. Freeze an exact CI candidate and run `NH-MEDIA-GESTURE-001...018` on the target Mac.
6. Merge accepted M6.6 and verify post-merge `main` CI.
7. Run P1 whole-app performance/resource review and local pointer-tracking experiment.
8. Resume the remaining product modules after the media/performance foundation is stable.
