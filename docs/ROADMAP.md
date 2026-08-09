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

Purpose: make CPU, RAM, threads, background work, artifact size, and lifecycle efficiency measurable release requirements before feature-heavy work.

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

Status: **IN PROGRESS — INTERACTION/TRANSITION SLICE ACCEPTED AND MERGED; REMAINING HARDENING DEFERRED BEHIND UNIVERSAL MEDIA + P1**
Interaction/transition merge: `094b494bd597643244e733baf5787a13b61fb4eb` (PR #10)

Interaction contract: `docs/specs/M1_NOTCH_INTERACTION.md`.
Initial dwell/haptic plan: `docs/superpowers/plans/2026-08-08-m1-pointer-dwell-haptics.md`.
Transition/animation hardening plan: `docs/superpowers/plans/2026-08-08-m1-transition-animation-hardening.md`.

### Interaction intent core — implemented, hardware accepted and merged

- [x] short cancellable hover dwell before compact -> expanded activation;
- [x] **120 ms dwell accepted** on target Mac;
- [x] asymmetric compact activation geometry: **4 pt left/right/bottom, 0 pt top**;
- [x] exact accepted compact boundaries are inclusive, including `pointer.y == compactFrame.maxY`;
- [x] compact hit-test no longer relies on `CGRect.contains` maximum-edge semantics;
- [x] one one-shot cancellable `DispatchWorkItem`, no polling/repeating timer;
- [x] deterministic quick-transit, threshold, duplicate, stale-callback, re-entry, retention, setup, programmatic, invalidation, and exact-edge coverage;
- [x] exactly one public AppKit haptic request on eligible deliberate expansion;
- [x] `.levelChange` tactile feedback accepted on target Mac;
- [x] no haptic for cancellation, duplicate movement, retention, collapse, setup/programmatic paths, stale callbacks, or transition-policy retarget;
- [x] explicit local/global `.mouseMoved` monitor ownership and teardown;
- [x] corrected `NH-HOVER-TOP-001` passed on exact CI #332 artifact;
- [x] `NH-HOVER-DELAY-001` quick cross-display transit reconfirmed on the same exact artifact;
- [x] final exact-head CI #338 passed all deterministic/security/performance/package gates;
- [x] PR #10 squash-merged into protected `main` as `094b494bd597643244e733baf5787a13b61fb4eb`.

### Transition / animation hardening — implemented, hardware accepted and merged

- [x] separate pointer intents from presentation transition ownership;
- [x] one `NotchPanelTransitionCoordinator` as the sole transition authority;
- [x] explicit `compact / expanding / expanded / collapsing` lifecycle;
- [x] preserve expanded SwiftUI content until collapse animation completion;
- [x] generation-based stale-completion rejection;
- [x] expansion -> collapse and collapse -> expansion reversal semantics;
- [x] exactly-once expansion haptic authority across reversals;
- [x] programmatic transition path remains non-haptic;
- [x] public `NSAnimationContext` frame animation with **0.20 s accepted duration**;
- [x] public Core Animation corner-radius transition with matching `.easeInEaseOut` timing;
- [x] cancellation freezes current presentation-layer corner radius before removing the old animation;
- [x] Reduced Motion maps transition duration to zero and reaches the exact endpoint synchronously;
- [x] live Reduce Motion changes retarget in-flight desired presentation without a second haptic;
- [x] `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification` lifecycle owned explicitly by the panel controller;
- [x] selector-based accessibility observation avoids an unnecessary block observer token/runtime closure;
- [x] 10,000 reversal deterministic stress keeps only the latest generation authoritative;
- [x] 32 immediate AppKit endpoint cycles preserve frame/chrome invariants;
- [x] unchanged P0 artifact-size budget restored after multiple CI failures; budget was never widened;
- [x] physical normal animation, both reversal directions, rapid churn, and Reduce Motion accepted on target MacBook/macOS 26.6.

### Pointer-observation efficiency — DEFERRED TO P1 WHOLE-APP REVIEW

Current accepted fallback:

- [x] exactly one local + one global `.mouseMoved` monitor with idempotent teardown;
- [x] no per-event `Task { @MainActor ... }` allocation from live mouse-move delivery;
- [x] AppKit monitor callbacks delivered synchronously through `MainActor.assumeIsolated` on the documented main-thread boundary;
- [x] deterministic coverage for the no-per-event-Task invariant.

P1 experiment after functional media integration:

- [ ] design a measurement protocol for `NSTrackingArea` / window-local tracking against accepted `NH-PERF-HOVER-001` and the physical cross-display/notch matrix;
- [ ] implement the alternative behind a narrow replaceable boundary using TDD;
- [ ] measure target-Mac CPU/RSS/threads and hover/transit correctness against the current global-monitor fallback in the real post-media application;
- [ ] replace global `.mouseMoved` only if local tracking is equal-or-better in correctness and resource behavior;
- [ ] retain the narrow global fallback if local tracking is less reliable or not measurably better;
- [ ] never adopt `CGEventTap`, Accessibility, Input Monitoring, or broader capture merely for hover convenience.

### Remaining M1 product hardening after Universal Media / P1

- [ ] multiple displays and active-screen migration;
- [ ] fullscreen/Space behavior;
- [ ] screen-configuration change handling;
- [ ] notchless-screen mode decision/prototype;
- [ ] click/pin interaction policy;
- [ ] reconcile future gesture surfaces with the accepted Universal Media gesture engine rather than adding competing gesture ownership.

## Current approved priority order — 2026-08-09

M6.1 transport feasibility is accepted and M6.2 establishes the deterministic production application-side media boundary. The next security-sensitive step is the concrete system transport and composition, not UI.

1. **Concrete production `SystemMediaTransport` + composition** behind the accepted M6.2 boundary, under strict TDD/security review and fresh shipping size/runtime evidence.
2. Compact + expanded media-first UI only after the concrete production state path is reliable.
3. Local-window gesture + haptic engine and seek interaction.
4. Target-Mac media/haptic acceptance on actually available sources; defer unavailable compatibility honestly.
5. **P1 whole-app performance review**, including production bridge lifecycle cost and the deferred `NSTrackingArea` / window-local pointer experiment.
6. Evidence-driven optimization if required, then resume remaining M1 display/Space hardening and later product modules.

Approved design: `docs/superpowers/specs/2026-08-09-universal-media-gestures-haptics-design.md`.
Accepted probe evidence: `docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md`.
M6.2 plan: `docs/superpowers/plans/2026-08-09-production-media-boundary.md`.

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

## M6 — Universal Media / System Now Playing

Status: **ACTIVE PRODUCT SLICE — M6.1 TRANSPORT ACCEPTED; M6.2 PRODUCTION CORE BOUNDARY IMPLEMENTED; CONCRETE TRANSPORT NEXT**

Product contract:

- follow the media session macOS itself treats as system Now Playing;
- support players automatically when they publish a system session; Yandex Music and Yandex Browser are physically verified now, while Apple Music/Spotify/other-player compatibility remains deferred until those sources are actually available for testing;
- do not add per-player adapters merely to manufacture missing capabilities;
- compact media state: artwork left + lightweight playback/status indicator right;
- expanded active-media state is media-first while preserving access to future NotchHub modules;
- multiple simultaneous media apps follow macOS source priority rather than NotchHub inventing one;
- capability-driven controls: unsupported/unknown actions are not faked;
- horizontal next/previous swipes work in compact and expanded states, locally over NotchHub only;
- compact swipe down expands, expanded swipe up collapses, progress drag seeks only when supported;
- horizontal command is commit-on-release with cancellation, hysteresis, and one `.levelChange` haptic per armed transition;
- no gesture-based volume control in the first media milestone;
- no global `.scrollWheel` monitor;
- no frequent media-state polling or always-running one-second timer.

Architecture/security:

- independent production target `NotchHubMediaCore` owns normalized media domain/controller/bridge code;
- player-agnostic `MediaProvider` + immutable `MediaSessionSnapshot` + `@MainActor MediaSessionController`;
- injected `SystemMediaTransport` sits behind isolated `SystemMediaBridge`;
- M6.2 does not yet contain the concrete MediaRemote/private transport and is not linked into `NotchHubApp`;
- the M6.1 sandbox/Hardened Runtime compatibility probe accepted the transport with final outcome `ACCEPT_TRANSPORT`;
- bridge/controller failure is media-only and fail-closed; Notch Core remains operational;
- no Accessibility/Input Monitoring/synthetic media keys;
- no listening-history persistence or production metadata logging;
- private compatibility must never justify disabling Sandbox/Hardened Runtime/library validation;
- concrete transport/runtime dependency decisions remain a separate reviewed implementation slice.

M6.1 accepted target-Mac evidence on `Mac16,8` / macOS 26.6 includes:

- sandbox-only entitlement + Hardened Runtime;
- no sensitive permission prompts;
- authoritative no-session `unknown/unknown/unknown` capability state;
- authoritative active capabilities on Yandex Music and Yandex Browser;
- event-driven Yandex Music and browser session/artwork/state observation;
- actual toggle/previous/next/seek behavior;
- source switching and disappearance;
- clean teardown/no orphan process;
- deterministic fail-closed/no-restart-loop failure lifecycle;
- 60-second parent/adapter sampled CPU `0.0%` with ~25.4 MiB combined steady RSS;
- corrected 10-minute stability with combined RSS drift `-160 KiB`, unchanged ending 4 threads, adapter CPU max `0.1%`, and clean final teardown.

M6.2 deterministic acceptance on code head `52d6d76b564c603cb21f0ec49bff4fa958c3aac7`, CI #500:

- **117/117 Swift tests PASS**;
- normalized domain/provider/controller ordering/dedup/capability/lifecycle tests PASS;
- isolated `SystemMediaBridge` callback ownership/forwarding/teardown/stale-handler tests PASS;
- release/security/performance/media-policy checks PASS without policy weakening;
- App Sandbox + Hardened Runtime/package/signature checks PASS;
- dormant media core is not linked into `NotchHubApp`;
- shipping executable/app remain exactly `250,320 B / 253,317 B` under the unchanged P0 budget.

Acceptance sequence:

- [x] product/architecture/gesture/security/performance design approved;
- [x] M6.1 probe plan/evidence recorded;
- [x] sandbox/Hardened Runtime transport compatibility/security probe;
- [x] authoritative capability surface proven;
- [x] target-Mac transport commands/source-switch/disappearance/permission/lifecycle acceptance;
- [x] target-Mac parent/adapter resource/stability acceptance;
- [x] final M6.1 outcome: **`ACCEPT_TRANSPORT`**;
- [x] production normalized media domain + provider contract;
- [x] deterministic `MediaSessionController` ordering/dedup/capability/restart behavior;
- [x] isolated injected `SystemMediaBridge` boundary;
- [x] dormant production media module separated from current shipping link graph without widening size/security policy;
- [ ] concrete production `SystemMediaTransport` implementation using accepted M6.1 evidence;
- [ ] compose the production media module into `NotchHubApp` with fresh package/security/size/runtime evidence;
- [ ] compact/expanded media UI;
- [ ] gesture/haptic/seek state machines under TDD;
- [ ] target-Mac functional media acceptance;
- [ ] P1 whole-app resource review;
- [ ] accept/optimize production implementation based on evidence.

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
