# Roadmap

Primary real-hardware target: macOS `26.6` / `Mac16,8`.
Current Personal Release: `v0.1.0`.

## M0 — Engineering foundation

Status: **ACCEPTED AND MERGED**

Completed:

- Swift 6 native application foundation;
- deterministic notch geometry and compact/expanded state;
- public AppKit/SwiftUI composition;
- App Sandbox + Hardened Runtime;
- strict warnings-as-errors CI and packaging verification;
- immutable full-SHA GitHub Actions;
- SemVer/CHANGELOG/project-state/testing/security documentation;
- real-hardware notch/hover acceptance.

## R0.1 — Personal Release foundation

Status: **ACCEPTED**

Completed:

- immutable `v0.1.0` Personal Release;
- ad-hoc signing, Sandbox, Hardened Runtime, checksum/provenance verification;
- downloaded-release target-Mac acceptance;
- separate dormant Trusted Release tier.

Paid Apple Developer Program membership remains optional and deferred.

## P0 — Performance Foundation

Status: **ACCEPTED AND MERGED**

Merge: `a056aa74bad5d8e193eb4c76a76e6c910344bd09`.

Accepted target baseline:

- idle CPU median/max `0.0% / 0.7%`, RSS max `33,808 KiB`, threads max `4`;
- hover CPU median/max `5.95% / 22.3%`, RSS max `38,816 KiB`, threads max `7`;
- 10-minute stability CPU median/max `0.0% / 6.8%`, RSS max `34,384 KiB`, RSS drift `-3,712 KiB`, threads max `7`.

Accepted immutable artifact baseline:

- executable `220,560 B`;
- app `223,555 B`;
- DMG `73,955 B`.

Shared CI enforces deterministic artifact-size budgets; CPU/RSS/thread magnitude remains target-Mac evidence.

## P0.1 — Public repository readiness

Status: **ACCEPTED**

Public fork CI remains read-only/unprivileged; release authority and immutable-release boundaries remain isolated.

## M1 — Notch Core hardening and interaction

Status: **INTERACTION/TRANSITION SLICE ACCEPTED; REMAINING DISPLAY/SPACE HARDENING DEFERRED BEHIND UNIVERSAL MEDIA + P1**

Accepted:

- 120 ms cancellable compact activation dwell;
- 4 pt left/right/bottom and 0 pt top activation geometry with inclusive boundaries;
- exactly one `.levelChange` haptic for eligible deliberate expansion;
- `NotchPanelTransitionCoordinator` as sole transition authority;
- `0.20 s` AppKit/Core Animation transition;
- Reduce Motion zero-duration endpoint behavior;
- reversal/stale-completion generation safety;
- explicit pointer/accessibility observer ownership;
- one local + one narrow global `.mouseMoved` fallback;
- no per-mouse-event Swift concurrency task allocation;
- no polling/repeating timer/display link/sensitive input permission.

Deferred to P1 after functional media integration:

- measured `NSTrackingArea` / window-local tracking comparison;
- replace the global fallback only if correctness and resource behavior are equal-or-better.

Remaining later M1 work:

- multiple displays and active-screen migration;
- fullscreen/Spaces;
- screen-configuration changes;
- notchless-screen mode;
- click/pin policy.

## M6 — Universal Media / System Now Playing

Status: **ACTIVE PRODUCT SLICE — M6.1 ACCEPTED; M6.2 ACCEPTED; M6.3 ACCEPTED; SHIPPING COMPOSITION NEXT**

Product contract:

- follow the system Now Playing source selected by macOS;
- player-agnostic behavior, without per-player fallbacks used to manufacture capabilities;
- capability-driven controls with explicit `supported / unsupported / unknown`;
- compact artwork/status and expanded media-first presentation;
- local NotchHub gestures only; no global scroll-wheel monitor;
- no frequent media polling or always-running one-second timer;
- no listening-history persistence or production metadata logging;
- no Accessibility/Input Monitoring/synthetic media-key requirement.

### M6.1 — transport feasibility

Status: **ACCEPTED — `ACCEPT_TRANSPORT`**

Merge: `7d5210eb0363933d120334d29daf40956b53cb50`.

Physically accepted:

- App Sandbox + Hardened Runtime;
- no sensitive permission prompts;
- authoritative no-session/active capabilities;
- Yandex Music and Yandex Browser observation;
- actual toggle/previous/next/seek behavior;
- source switching/disappearance;
- clean teardown/no orphan;
- stable 60-second and 10-minute resource behavior.

### M6.2 — production media state/controller/bridge boundary

Status: **ACCEPTED AND MERGED**

Merge: `1ccea500570f9a5ca927739be58d7f7eaadd775a`.

Completed:

- normalized media domain and immutable snapshots;
- generation/revision freshness ordering;
- player-agnostic provider contract;
- `@MainActor MediaSessionController` dedup/capability/restart behavior;
- injected `SystemMediaTransport`;
- isolated `SystemMediaBridge` callback/teardown/typed-command boundary;
- deterministic coverage for stale callbacks, unsupported commands and one-restart/no-loop behavior;
- shipping isolation because linking dormant media code exceeded the unchanged P0 artifact-size gate.

### M6.3 — concrete production system transport

Status: **ACCEPTED**

Accepted frozen candidate:

- source `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`;
- CI #576 / run `31339015100`;
- artifact ID `9045247126`;
- digest `sha256:a6323c504021f21e7638b40e47bedd0b2c1a9fcfcf861724c139151ee8faa804`;
- adapter `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- patch SHA-256 `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`.

Completed and accepted:

- [x] bounded production `stream --no-diff --micros` wire decoder;
- [x] one fixed `/usr/bin/perl` process boundary with closed arguments;
- [x] typed toggle/previous/next/seek only;
- [x] authoritative tri-state capabilities;
- [x] source/session monotonic sequencing and stale capability rejection;
- [x] full-snapshot replacement and stale-artwork protection;
- [x] bounded graceful/forced owned-process teardown without polling;
- [x] target Sandbox + Hardened Runtime;
- [x] no-session `unknown/unknown/unknown` capability state;
- [x] Yandex Music production observation;
- [x] Yandex Browser production observation;
- [x] Yandex Music -> Yandex Browser source switch (`sourceSwitchCount = 1`) and disappearance;
- [x] actual toggle pause/resume, next, previous and seek 42s;
- [x] no Accessibility/Input Monitoring/Automation/Screen Recording prompts;
- [x] 60-second steady resource acceptance;
- [x] corrected 10-minute stability/teardown acceptance;
- [x] clean teardown and no orphan process;
- [x] final M6.3 decision: **ACCEPTED**.

Target 10-minute evidence: combined CPU median/max upper bounds `0.0/7.5%`, RSS `35,168 -> 26,160 KiB` (`-9,008 KiB`), threads `11 -> 4`, clean teardown, no orphan.

A superseded candidate exposed an unbounded `waitUntilExit()` defect; the accepted candidate fixes it with bounded exit-event waits and owned-child SIGKILL escalation. Collector sampling/watchdog defects found during target testing were corrected under deterministic tests without changing the frozen production candidate.

## Current approved priority order — 2026-08-10

1. Start a **separate M6 shipping-composition slice**:
   - add `NotchHubMediaCore` to the shipping app dependency graph;
   - package only the pinned adapter/framework assets required by the accepted transport;
   - keep the fixed `/usr/bin/perl`/typed-command/security boundary;
   - collect fresh package/signature/entitlement/artifact-size evidence;
   - do not silently widen P0 budgets;
   - collect fresh target-Mac whole-app runtime evidence for idle/active/teardown lifecycle.
2. Implement compact + expanded media-first UI only after composed state transport is reliable.
3. Implement local-window gesture/haptic/seek state machines under TDD.
4. Run target-Mac media/haptic acceptance on actually available sources.
5. Run **P1 whole-app performance review**, including production bridge lifecycle cost and the deferred local tracking experiment.
6. Optimize only from evidence, then resume remaining M1 display/Space hardening and later modules.

## M2 — Shelf

Planned:

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

## M8 — Trusted distribution and maintenance (optional)

Only when Apple Developer Program becomes worthwhile:

- create/review release environment;
- provision signing/notarization credentials as scoped secrets;
- validate Developer ID/notarization/stapling/Gatekeeper on a new version;
- never replace an existing Personal Release tag;
- design authenticated updates before self-update;
- maintain recurring dependency/action/toolchain/security/performance review.
