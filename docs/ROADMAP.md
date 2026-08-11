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

Runtime ceilings remain immutable unless a separately reviewed evidence-backed performance decision explicitly changes them. Feature-specific artifact growth must be explicit and separately reviewed.

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

Status: **ACTIVE — M6.1/M6.2/M6.3 ACCEPTED; M6.4 PERFORMANCE INVESTIGATION ACTIVE**

Product contract:

- follow the system Now Playing source selected by macOS;
- player-agnostic behavior without per-player capability fabrication;
- explicit `supported / unsupported / unknown` capabilities;
- compact artwork/status and expanded media-first presentation later;
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

Status: **ACCEPTED**

Frozen candidate:

- source `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`;
- CI #576 / run `31339015100`;
- artifact ID `9045247126`;
- digest `sha256:a6323c504021f21e7638b40e47bedd0b2c1a9fcfcf861724c139151ee8faa804`.

All `NH-MEDIA-PROD-001...013` target gates pass, including Yandex Music/Yandex Browser, real toggle/next/previous/seek, no sensitive permission prompts, bounded teardown, 60-second resources and corrected 10-minute stability.

### M6.4 — shipping media composition

Status: **TARGET-MAC LIFECYCLE/PERMISSIONS PASS — COMPACT RSS BLOCKED**

Current frozen shipping candidate:

- source `fdbe987d8f22768b2a75406c8f1e721fa1da2845`;
- CI #693 / run `31472420797` — PASS;
- artifact `NotchHub-shipping-media-candidate` / ID `9093958828`;
- Actions digest `sha256:f055bc87d1f2c8cafe0d3b57d9cf6cdf82d7a712bf85acf3317232679a9689b9`;
- contained DMG SHA-256 `6371e8695e30f06697d37d2d018e043674e8b27a44022e3d8e846d0e1dad01fd`;
- sizes `313,648 B / 615,854 B / 408,480 B` executable/app/DMG.

Completed:

- [x] link `NotchHubMediaCore` into `NotchHubApp`;
- [x] package exact pinned adapter/framework/license/provenance;
- [x] sign nested framework before top-level app;
- [x] retain Hardened Runtime and exact sandbox-only entitlement;
- [x] retain system-only executable dylib boundary;
- [x] keep probe/candidate/development tools out of shipping payload;
- [x] isolate candidate-only helpers from the shipping graph;
- [x] preserve immutable P0 artifact baseline and enforce explicit M6.4 additive size allowance;
- [x] add privacy-safe shipping target collectors/runners;
- [x] fix target-discovered always-on media lifecycle under RED -> GREEN coverage;
- [x] compact launch owns zero media adapter processes;
- [x] media runtime starts only after matching settled `.expanded` and stops/releases after settled `.compact`;
- [x] stale/reversed transitions cannot start media;
- [x] `NH-MEDIA-SHIP-001...007` — PASS, including current-candidate signatures, permissions, zero-adapter compact state, one-adapter expanded state, clean termination and no orphan;
- [x] `NH-MEDIA-SHIP-010` — PASS explicit artifact-size impact;
- [ ] `NH-MEDIA-SHIP-008` — BLOCKED: compact steady RSS max `66,160 KiB` > P0 idle ceiling `43,008 KiB`; CPU max `2.4%` > `2.0%`;
- [ ] `NH-MEDIA-SHIP-009` — BLOCKED on absolute RSS: 10-minute RSS max `60,320 KiB` > `45,056 KiB`; drift `+2,672 KiB` and threads `3 -> 3` otherwise pass;
- [ ] final decision: `M6.4 ACCEPTED`.

Expanded active feature evidence is recorded separately: combined RSS median/max `96,624 / 104,832 KiB`, CPU median/max `0.0 / 0.8%`, threads median/max `5 / 10`, clean teardown. No active runtime ceiling is invented from one run.

#### Current M6.4 diagnostic

The lazy lifecycle removed the always-on adapter from compact background, but parent RSS remains approximately `59–66 MiB`.

Next comparator is the exact final M6.3 shell-only shipping app where `NotchHubApp` still depends only on `NotchHubCore`:

- source `30de94c0cb6ea17dc21bd366404937db2bc73783`;
- CI #594 / run `31389611697`;
- artifact `NotchHub-dmg` / ID `9063213178`;
- Actions digest `sha256:9ab40b4101a013e11570fa013f49d2a42a3c5198251210a337b2985fc64e2a0d`;
- contained DMG SHA-256 `b1da6681ce49da3c34b3720c39caa32c3fc4508e0abf7d209b63b46f78713fb7`.

`run-shell-only-target-diagnostic.sh` exact-pins that candidate and applies the same parent-only 60-second and 10-minute sampler.

Decision rule:

- if shell-only is also approximately `59–66 MiB`, trace a pre-M6.4 shell/interaction regression;
- if shell-only returns near P0 while M6.4 remains approximately `59–66 MiB`, redesign M6.4 media isolation before acceptance.

PR #17 remains Draft until `NH-MEDIA-SHIP-008/009` pass.

## Current approved priority order — 2026-08-11

1. Run the exact M6.3 shell-only comparator through `scripts/run-shell-only-target-diagnostic.sh` on Mac16,8/macOS 26.6.
2. Compare shell-only parent steady/stability RSS with the current M6.4 compact evidence and immutable P0 ceilings.
3. If the regression predates M6.4, bisect/diagnose shell/interaction evolution before changing media architecture.
4. If static M6.4 linkage is responsible, design a deeper lazy isolation boundary and implement it under TDD without widening runtime budgets.
5. Re-freeze and repeat relevant target gates after any production change.
6. Finalize M6.4 docs, exact-head CI/change review, mark PR #17 Ready and merge only after all stable gates pass.
7. Implement compact + expanded media-first UI as a separate slice.
8. Implement local-window gesture/haptic/seek state machines under TDD.
9. Run P1 whole-app performance review, including the deferred local tracking experiment.
10. Resume remaining M1 display/Space hardening and later modules.

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
