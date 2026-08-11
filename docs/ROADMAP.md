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

Status: **ACCEPTED AND MERGED; CROSS-SESSION ABSOLUTE-RSS METHODOLOGY CORRECTION PENDING**

Merge: `a056aa74bad5d8e193eb4c76a76e6c910344bd09`.

Accepted historical target observation:

- idle CPU median/max `0.0% / 0.7%`, RSS max `33,808 KiB`, threads max `4`;
- hover CPU median/max `5.95% / 22.3%`, RSS max `38,816 KiB`, threads max `7`;
- 10-minute stability CPU median/max `0.0% / 6.8%`, RSS max `34,384 KiB`, RSS drift `-3,712 KiB`, threads max `7`.

Accepted immutable artifact baseline:

- executable `220,560 B`;
- app `223,555 B`;
- DMG `73,955 B`.

The baseline remains immutable. Current same-session target evidence shows that the exact immutable `v0.1.0` binary itself now measures steady RSS median/max `60,144/63,376 KiB`, while M1 #319 measures `59,552/69,680 KiB`. A persistent P0→M1 memory regression is disproven. The original single-run absolute `ps rss` ceilings therefore remain historical evidence but are not proven portable across target sessions.

The final M6.4 decision uses a direct same-session immutable-baseline comparator plus 10-minute growth/leak evidence. Future performance work should introduce a better single-number memory-impact metric such as physical footprint without weakening security or removing leak/growth checks.

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

Status: **ACTIVE — M6.1/M6.2/M6.3 ACCEPTED; M6.4 FINAL SAME-SESSION RSS COMPARATOR PENDING**

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

Historical shell-only comparator from final exact M6.3 head `30de94c...` reproduces elevated compact RSS despite `NotchHubApp` still linking only `NotchHubCore`: steady RSS median/max `58,656/62,624 KiB`; stability `56,384/60,400 KiB`. This disproves M6.4 static media linkage as the primary source of the absolute shell RSS discrepancy.

### M6.4 — shipping media composition

Status: **TARGET LIFECYCLE/PERMISSIONS PASS — FINAL DIRECT IMMUTABLE-BASELINE RSS A/B PENDING**

Frozen shipping candidate:

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
- [x] disprove M6.4 static linkage as the source of the remaining compact RSS discrepancy via exact M6.3 shell-only comparison;
- [x] disprove persistent P0→M1 RSS regression via exact same-session immutable-baseline A/B;
- [ ] run direct same-session `v0.1.0 ↔ frozen M6.4` steady comparator;
- [ ] `NH-MEDIA-SHIP-008` — decide under corrected evidence-backed RSS methodology;
- [ ] `NH-MEDIA-SHIP-009` — finalize RSS classification; stability drift/thread behavior already passes;
- [ ] final decision: `M6.4 ACCEPTED`.

Current physical compact evidence:

- steady CPU median/max `0.0/2.4%`, RSS median/max `59,792/66,160 KiB`, threads max `4`;
- 10-minute stability CPU median/max `0.0/3.3%`, RSS median/max `59,024/60,320 KiB`, RSS drift `+2,672 KiB`, threads `3 -> 3`.

Historical/current comparator evidence:

- M6.3 shell-only steady RSS median/max `58,656/62,624 KiB`, stability `56,384/60,400 KiB`;
- exact current `v0.1.0` steady RSS median/max `60,144/63,376 KiB`;
- exact M1 #319 steady RSS median/max `59,552/69,680 KiB`.

No runtime budget is widened. `scripts/run-m6-4-rss-ab.sh` exact-pins immutable `v0.1.0` and the frozen M6.4 candidate and uses one shared measurement path. CI #721 / run `31522174412` passes the complete pipeline for the new comparator tooling. PR #17 remains Draft pending that one physical A/B.

## Current approved priority order — 2026-08-11

1. Run exact same-session `v0.1.0 ↔ frozen M6.4` steady A/B with `scripts/run-m6-4-rss-ab.sh`.
2. If M6.4 is materially worse in same-session median/steady behavior, continue root-cause investigation without changing budgets.
3. If M6.4 is equal-or-better in same-session median/steady behavior, combine that with the already-passing 10-minute drift/thread evidence and correct `PERFORMANCE.md` so historical absolute `ps rss` observations remain immutable evidence but are no longer treated as a portable cross-session release gate.
4. Resolve `NH-MEDIA-SHIP-008/009`, synchronize acceptance/state/roadmap/changelog, run exact-head CI and final change review.
5. Mark PR #17 ready and squash-merge only after all M6.4 gates are honestly accepted.
6. Implement compact + expanded media-first UI as a separate slice.
7. Implement local-window gesture/haptic/seek state machines under TDD.
8. Run physical media/haptic acceptance, then P1 whole-app performance review and deferred local tracking experiment, including evaluation of a physical-footprint memory metric for future baselines.

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
