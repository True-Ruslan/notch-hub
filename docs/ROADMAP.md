# Roadmap

## M0 — Engineering foundation

Status: **ACCEPTED**
Version target: `v0.1.0`
Primary real-hardware target: macOS `26.6`

Completed:

- Swift 6 native application foundation;
- deterministic notch geometry and compact/expanded state;
- stable pointer activation/retention policy;
- exact hardware-notch width and AppKit-owned panel sizing;
- RED -> GREEN regression coverage for real-device defects;
- strict formatting + warnings-as-errors + macOS 26 CI;
- App Sandbox and Hardened Runtime;
- zero third-party Swift runtime dependencies;
- executable security baseline;
- immutable full-SHA GitHub Action references;
- DMG packaging/signature/entitlement/system-library/integrity verification;
- SemVer/CHANGELOG/project-state/testing/security documentation;
- macOS 26.6 real-hardware acceptance of required notch/hover behavior.

M0 code is merged into protected `main`.

## R0.1 — Personal Release foundation

Status: **ACCEPTED**
Target: `v0.1.0 — Personal build`

Completed:

- deterministic release-policy tests;
- manual-only Personal Release from exact protected `main`;
- App Sandbox/Hardened Runtime/ad-hoc signature/system-library/DMG gates;
- immutable release assets with SHA-256 and build provenance;
- separate dormant Trusted Release tier;
- downloaded `v0.1.0` acceptance on target MacBook/macOS 26.6.

Apple Developer Program membership is intentionally deferred and is not a blocker for current personal use.

## P0 — Performance Foundation

Status: **ACCEPTED AND MERGED**
Merge commit: `a056aa74bad5d8e193eb4c76a76e6c910344bd09`

Purpose: make CPU, RAM, threads, background work, artifact size, and lifecycle efficiency measurable release requirements before feature-heavy M1 work.

Accepted runtime evidence on target macOS 26.6 / `Mac16,8`:

- `NH-PERF-IDLE-001`: CPU median/max `0.0% / 0.7%`, RSS max `33,808 KiB`, threads max `4`;
- `NH-PERF-HOVER-001`: CPU median/max `5.95% / 22.3%`, RSS max `38,816 KiB`, threads max `7`;
- `NH-PERF-STABILITY-001`: CPU median/max `0.0% / 6.8%`, RSS max `34,384 KiB`, threads max `7`;
- 10-minute stability RSS `34,256 -> 30,544 KiB`, delta `-3,712 KiB`.

Accepted immutable size baseline:

- executable `220,560 B`;
- app aggregate `223,555 B`;
- DMG `73,955 B`.

Shared CI enforces deterministic artifact sizes with the accepted 15% relative allowance plus absolute ceilings. CPU/RSS/thread magnitude acceptance remains target-Mac only.

Detailed policy: `PERFORMANCE.md` and `performance/baseline-v0.1.0.json`.

## P0.1 — Public repository readiness

Status: **ACCEPTED**
Hardening merge: `23500e099a0f8b2738f1157c6ae3be71c89df6e1`

Public repository, ordinary fork PR CI, release authority, protected branch rules, and immutable release boundaries are accepted. Any future authority/credential/visibility change requires a fresh focused review.

## M1 — Notch Core hardening and interaction

Status: **IN PROGRESS — PR #10 DRAFT**

Interaction contract: `docs/specs/M1_NOTCH_INTERACTION.md`.
Initial dwell/haptic plan: `docs/superpowers/plans/2026-08-08-m1-pointer-dwell-haptics.md`.
Transition/animation hardening plan: `docs/superpowers/plans/2026-08-08-m1-transition-animation-hardening.md`.

### Interaction intent core — implemented, final hardware acceptance pending

- [x] short cancellable hover dwell before compact -> expanded activation;
- [x] named **120 ms candidate**;
- [x] **4 pt inward activation inset candidate** to reject edge grazing;
- [x] one one-shot cancellable `DispatchWorkItem`, no polling/repeating timer;
- [x] deterministic quick-transit, threshold, duplicate, stale-callback, re-entry, retention, setup, programmatic, and invalidation coverage;
- [x] exactly one public AppKit haptic request on eligible deliberate expansion;
- [x] current tactile candidate `.levelChange`;
- [x] no haptic for cancellation, duplicate movement, retention, collapse, setup/programmatic paths, stale callbacks, or transition-policy retarget;
- [x] explicit local/global `.mouseMoved` monitor ownership and teardown;
- [ ] accept/tune `120 ms`, `4 pt`, and `.levelChange` from exact final target-Mac evidence.

### Transition / animation hardening — deterministic implementation complete, hardware acceptance pending

- [x] separate pointer intents from presentation transition ownership;
- [x] one `NotchPanelTransitionCoordinator` as the sole transition authority;
- [x] explicit `compact / expanding / expanded / collapsing` lifecycle;
- [x] preserve expanded SwiftUI content until collapse animation completion;
- [x] generation-based stale-completion rejection;
- [x] expansion -> collapse and collapse -> expansion reversal semantics;
- [x] exactly-once expansion haptic authority across reversals;
- [x] programmatic transition path remains non-haptic;
- [x] public `NSAnimationContext` frame animation with a **0.20 s** standard-duration candidate;
- [x] public Core Animation corner-radius transition with matching `.easeInEaseOut` timing;
- [x] cancellation freezes current presentation-layer corner radius before removing the old animation;
- [x] Reduced Motion maps transition duration to zero and reaches the exact endpoint synchronously;
- [x] live Reduce Motion changes retarget in-flight desired presentation without a second haptic;
- [x] `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification` lifecycle owned explicitly by the panel controller;
- [x] selector-based accessibility observation avoids an unnecessary block observer token/runtime closure;
- [x] 10,000 reversal deterministic stress keeps only the latest generation authoritative;
- [x] 32 immediate AppKit endpoint cycles preserve frame/chrome invariants;
- [x] unchanged P0 artifact-size budget restored after multiple CI failures; budget was never widened;
- [ ] physically validate normal animation, reversal continuity, rapid churn, and Reduce Motion behavior on target MacBook/macOS 26.6;
- [ ] accept/tune the final 0.20 s duration only from physical evidence.

### Pointer-observation efficiency — hot path improved; local-tracking experiment still pending

- [x] retain exactly one local + one global `.mouseMoved` monitor with idempotent teardown;
- [x] remove per-event `Task { @MainActor ... }` allocation from live mouse-move delivery;
- [x] deliver AppKit monitor callbacks synchronously through `MainActor.assumeIsolated` on the documented main-thread callback boundary;
- [x] prove the no-per-event-Task property in deterministic regression coverage;
- [ ] measure and investigate `NSTrackingArea` / window-local tracking against accepted `NH-PERF-HOVER-001`;
- [ ] replace global `.mouseMoved` only if notch/cross-display correctness and target-Mac resource behavior are equal or better;
- [ ] retain the narrow global fallback if local tracking is less reliable or not measurably better;
- [ ] never adopt `CGEventTap`, Accessibility, Input Monitoring, or broader capture merely for hover convenience.

### Physical M1 acceptance gate for current slice

The final clean exact-head CI artifact must pass on target MacBook/macOS 26.6:

- [ ] `NH-NOTCH-001`;
- [ ] `NH-HOVER-001/002/003`;
- [ ] `NH-HOVER-DELAY-001/002`;
- [ ] `NH-HAPTIC-001/002`;
- [ ] `NH-VISUAL-001/002/003`;
- [ ] normal expansion/collapse is visibly smooth;
- [ ] expansion -> collapse reversal begins from the current visible state with no snap/flicker/stale endpoint;
- [ ] collapse -> expansion reversal behaves likewise;
- [ ] rapid hover/leave churn cannot leave a stale/stuck phase;
- [ ] Reduce Motion enabled before transition yields an immediate endpoint;
- [ ] Reduce Motion changed during an in-flight transition retargets immediately without duplicate haptic;
- [ ] startup with pointer already over the notch remains non-activating.

If the public AppKit animator visibly snaps on the target Mac, treat it as a hard failure and revisit architecture. Do not introduce a custom timer, display link, private API, or weaker acceptance rule.

### Remaining M1 product hardening after current acceptance

- [ ] measured pointer-observation experiment described above;
- [ ] multiple displays and active-screen migration;
- [ ] fullscreen/Space behavior;
- [ ] screen-configuration change handling;
- [ ] notchless-screen mode decision/prototype;
- [ ] click/pin interaction policy;
- [ ] gesture model (hover/click/scroll/swipe) designed independently while benchmarking public NotchNook behavior.

## M2 — Shelf

- drag files into/out of Shelf;
- sandbox-compatible user-selected/security-scoped access;
- source file is never deleted when removed from Shelf;
- stale-reference handling and optional cleanup;
- deterministic ownership/source-preservation/error tests.

## M3 — Snippets

- sandbox-local store;
- groups/search/copy;
- privacy mode;
- direct paste only after explicit Accessibility/security decision and with copy-only fallback;
- persistence/search/escaping/masking/denied-state tests.

## M4 — Calendar

- EventKit adapter;
- next-event UI;
- explicit permission denial/availability states;
- deterministic adapter tests + minimal real permission acceptance.

## M5 — Translator

- Apple Translation framework where available;
- language handling/swap/copy;
- optional clipboard translation;
- no direct app network translation without separate security review.

## M6 — Media / Yandex Music

- provider abstraction + deterministic fake-provider tests;
- Yandex Music desktop compatibility probe on macOS 26.6;
- metadata/artwork/play-pause/previous-next/timeline where available;
- prefer public/sandbox-compatible integration;
- isolated MediaRemote fallback only after security, compatibility, and performance review;
- never weaken Hardened Runtime/library validation or add broad input capture.

## M7 — Product shell

- settings;
- narrowly scoped shortcuts;
- launch-at-login through supported macOS APIs rather than custom agents/daemons;
- module ordering/enable-disable;
- accessibility/privacy/security settings.

## M8 — Trusted distribution and maintenance (optional)

- only if Apple Developer Program becomes worthwhile;
- create/review release environment before first Trusted Release use;
- provision Apple signing/notarization credentials only as environment-scoped secrets;
- validate Developer ID/notarization/stapling/Gatekeeper on a new version;
- never replace an existing Personal Release tag;
- authenticated update-channel design before self-update;
- recurring dependency/action/toolchain/security/performance review.
