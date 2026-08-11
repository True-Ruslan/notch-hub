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

Immutable `v0.1.0` is accepted for personal use with ad-hoc signing, Sandbox, Hardened Runtime and checksum/provenance verification. Paid Apple Developer Program membership remains optional/deferred.

## P0 — Performance Foundation

Status: **ACCEPTED AND MERGED; RUNTIME-MEMORY METRIC CLASSIFICATION CORRECTED FROM REPEATED EVIDENCE**

Merge: `a056aa74bad5d8e193eb4c76a76e6c910344bd09`.

Accepted historical target observation:

- idle CPU median/max `0.0% / 0.7%`, RSS max `33,808 KiB`, threads max `4`;
- hover CPU median/max `5.95% / 22.3%`, RSS max `38,816 KiB`, threads max `7`;
- 10-minute stability CPU median/max `0.0% / 6.8%`, RSS max `34,384 KiB`, RSS drift `-3,712 KiB`, threads max `7`.

Accepted immutable artifact baseline:

- executable `220,560 B`;
- app `223,555 B`;
- DMG `73,955 B`.

The baseline file remains immutable. Repeated same-target measurements proved that absolute cross-session `ps rss` and isolated one-second CPU maxima from the single P0 run are not portable standalone release gates: the exact immutable `v0.1.0` binary itself remeasured around `60–67 MiB` RSS and up to `6.7%` one-second CPU max while retaining `0.0%` median CPU.

`PERFORMANCE.md` now uses exact same-session immutable-baseline comparison for steady compact memory, retains 10-minute RSS/thread growth gates and direct thread gates, and keeps the original P0 numbers as historical calibration. No baseline JSON or production runtime budget was rewritten to obtain M6.4 acceptance.

Future P1 performance work should evaluate a more portable absolute memory-footprint metric and characterize repeated-run variance before defining another cross-session absolute memory ceiling.

## P0.1 — Public repository readiness

Status: **ACCEPTED**

Public fork CI remains read-only/unprivileged; release authority and immutable-release boundaries remain isolated.

## M1 — Notch Core hardening and interaction

Status: **INTERACTION/TRANSITION SLICE ACCEPTED; PERSISTENT P0→M1 RSS REGRESSION DISPROVEN**

Accepted:

- 120 ms cancellable compact activation dwell;
- 4 pt left/right/bottom and 0 pt top activation geometry with inclusive boundaries;
- exactly one `.levelChange` haptic for eligible deliberate expansion;
- `NotchPanelTransitionCoordinator` as sole transition authority;
- `0.20 s` AppKit/Core Animation transition;
- Reduce Motion zero-duration endpoint behavior;
- explicit pointer/accessibility observer ownership;
- one local + one narrow global `.mouseMoved` fallback;
- no per-mouse-event Swift concurrency task allocation;
- no polling/repeating timer/display link/sensitive input permission.

Same-session current-target A/B:

- immutable `v0.1.0`: RSS median/max `60,144/63,376 KiB`;
- accepted M1 #319: RSS median/max `59,552/69,680 KiB`;
- median delta M1-baseline `-592 KiB`.

Do not bisect M1 for the historical RSS discrepancy unless new direct evidence contradicts this result.

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

Status: **ACTIVE — M6.1/M6.2/M6.3/M6.4 ACCEPTED AND MERGED; NEXT: MEDIA-FIRST UI**

Product contract:

- follow the system Now Playing source selected by macOS;
- player-agnostic behavior without per-player capability fabrication;
- explicit `supported / unsupported / unknown` capabilities;
- compact artwork/status and expanded media-first presentation;
- local NotchHub gestures only;
- no frequent media polling or always-running one-second timer;
- no listening-history persistence or production metadata logging;
- no Accessibility/Input Monitoring/synthetic media-key requirement.

### M6.1 — transport feasibility

Status: **ACCEPTED — `ACCEPT_TRANSPORT`**

Merge: `7d5210eb0363933d120334d29daf40956b53cb50`.

Physically accepted Sandbox/Hardened Runtime, no sensitive permissions, authoritative capabilities, Yandex Music/Yandex Browser observation and commands, source switching/disappearance, clean teardown/no orphan, and stable target resources.

### M6.2 — production media state/controller/bridge boundary

Status: **ACCEPTED AND MERGED**

Merge: `1ccea500570f9a5ca927739be58d7f7eaadd775a`.

Completed normalized media state, generation/revision freshness, player-agnostic provider, deterministic controller, injected transport, isolated bridge, typed command forwarding, stale callback rejection and one-restart/no-loop behavior.

### M6.3 — concrete production system transport

Status: **ACCEPTED AND MERGED**

Frozen candidate:

- source `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`;
- CI #576 / run `31339015100`;
- artifact ID `9045247126`;
- digest `sha256:a6323c504021f21e7638b40e47bedd0b2c1a9fcfcf861724c139151ee8faa804`.

All `NH-MEDIA-PROD-001...013` target gates pass, including Yandex Music/Yandex Browser, real toggle/previous/next/seek, no sensitive permission prompts, bounded teardown, 60-second resources and corrected 10-minute stability.

Historical shell-only comparator from final M6.3 head `30de94c...` reproduces the current compact RSS class despite `NotchHubApp` still linking only `NotchHubCore`, disproving M6.4 static media linkage as the source of the historical absolute-RSS discrepancy.

### M6.4 — shipping media composition

Status: **ACCEPTED AND MERGED — ALL `NH-MEDIA-SHIP-001...010` PASS**

Merge:

- PR #17 squash commit `4ba603e1c3564d6cdf58169a7936f1954dee2ffd`;
- final PR-head CI #732 / run `31524951736` — PASS;
- post-merge `main` CI #733 / run `31525413454` — PASS.

Accepted frozen shipping candidate:

- source `fdbe987d8f22768b2a75406c8f1e721fa1da2845`;
- CI #693 / run `31472420797` — PASS;
- artifact `NotchHub-shipping-media-candidate` / ID `9093958828`;
- Actions digest `sha256:f055bc87d1f2c8cafe0d3b57d9cf6cdf82d7a712bf85acf3317232679a9689b9`;
- contained DMG SHA-256 `6371e8695e30f06697d37d2d018e043674e8b27a44022e3d8e846d0e1dad01fd`.

Completed:

- [x] link `NotchHubMediaCore` into `NotchHubApp`;
- [x] package exact pinned adapter/framework/license/provenance;
- [x] explicitly sign nested framework before top-level app;
- [x] retain Hardened Runtime and exact sandbox-only entitlement;
- [x] retain system-only executable dylib boundary;
- [x] keep probe/candidate/development tools out of shipping payload;
- [x] split candidate-only helpers from shipping media graph;
- [x] preserve immutable P0 baseline and explicit reviewed M6.4 feature-size allowance;
- [x] scope media runtime to settled expanded presentation rather than application lifetime;
- [x] prove adapter absence throughout compact steady/stability;
- [x] prove exactly one adapter after settled expansion;
- [x] prove normal parent/adapter teardown with no orphan;
- [x] confirm no Accessibility/Input Monitoring/Automation/Screen Recording prompts;
- [x] record expanded active feature cost separately;
- [x] disprove M6.4 static linkage as the source of the historical compact RSS discrepancy via exact M6.3 shell-only comparison;
- [x] disprove persistent P0→M1 RSS regression via exact same-session immutable-baseline A/B;
- [x] run direct same-session `v0.1.0 ↔ frozen M6.4` steady comparator;
- [x] resolve `NH-MEDIA-SHIP-008/009` under corrected evidence-backed runtime-memory methodology;
- [x] final decision: `M6.4 ACCEPTED`;
- [x] final exact-head CI/review, squash merge and post-merge `main` CI.

Accepted physical evidence:

- compact steady CPU median/max `0.0/2.4%`, RSS median/max `59,792/66,160 KiB`, threads max `4`, adapter absent;
- 10-minute stability CPU median/max `0.0/3.3%`, RSS median/max `59,024/60,320 KiB`, RSS drift `+2,672 KiB`, threads `3 -> 3`, adapter absent;
- expanded active combined CPU median/max `0.0/0.8%`, RSS median/max `96,624/104,832 KiB`, threads median/max `5/10`, clean teardown;
- direct same-session immutable `v0.1.0` vs M6.4 steady RSS median/max: baseline `61,504/67,104 KiB`, candidate `62,256/65,232 KiB`;
- direct delta: `+752 KiB` median and `-1,872 KiB` max; candidate CPU `0.0/0.0%` vs baseline `0.0/6.7%`; threads identical `3/4`;
- baseline repeated same-day median variation `1,360 KiB`, larger than the M6.4 median delta.

The direct A/B shows no material steady compact-memory regression, while the independent 10-minute growth/thread gate passes. No runtime budget is widened.

Comparator/tooling evidence:

- shell-only comparator: RED #705 -> GREEN #709;
- P0 vs M1 comparator: RED #712 -> GREEN policy #714, exact-head #718 PASS;
- direct P0 vs M6.4 comparator: RED #720 -> GREEN #721 PASS.

## Current approved priority order — 2026-08-11

1. Define and implement the compact + expanded media-first UI as the next Universal Media slice, preserving the accepted presentation-scoped media lifecycle and security boundary.
2. Establish explicit UI acceptance IDs before production changes; cover media-state-to-view-state mapping and transition behavior under TDD.
3. Keep local-window gesture/haptic/seek state machines as a separate later slice after basic media UI is accepted.
4. Run physical media UI acceptance on the target Mac.
5. Run P1 whole-app performance review and deferred local tracking experiment.
6. During P1, evaluate a more portable memory-footprint metric and repeated-run variance before introducing another absolute cross-session memory ceiling.

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
