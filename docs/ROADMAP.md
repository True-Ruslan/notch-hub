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

The baseline remains immutable. Feature-specific size growth must be explicit and separately reviewed.

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

Status: **ACTIVE — M6.1/M6.2/M6.3 ACCEPTED; M6.4 CI-QUALIFIED, TARGET GATE PENDING**

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

Status: **CI-QUALIFIED — TARGET-MAC GATE PENDING**

Frozen shipping candidate:

- source `c19ce13c5321fce72464ddf0a5d9b1467f770db0`;
- CI #675 / run `31408757149` — PASS;
- artifact `NotchHub-shipping-media-candidate` / ID `9070996306`;
- Actions digest `sha256:c3b279153b8abf75ab77fa2f478888ae1fe9bad6bfdbf64665567bf713b8035d`;
- contained DMG SHA-256 `ccf8a503515d382c206c6211606ca6401ba33114863a30721e134c1a45af04b9`.

Completed:

- [x] link `NotchHubMediaCore` into `NotchHubApp`;
- [x] app-owned `ShippingMediaRuntime` lifecycle;
- [x] package exact pinned adapter/framework/license/provenance;
- [x] explicitly sign nested framework before top-level app;
- [x] retain Hardened Runtime and exact sandbox-only entitlement;
- [x] retain system-only executable dylib boundary;
- [x] keep probe/candidate/development tools out of shipping payload;
- [x] split candidate-only helpers into development-only `NotchHubMediaCandidateCore`;
- [x] reduce shipping executable from `354,880 B` to `312,816 B` through target isolation;
- [x] measure exact candidate sizes: executable `312,816 B`, app `615,022 B`, DMG `406,618 B`;
- [x] preserve immutable P0 baseline and add explicit reviewed M6.4 feature-size allowance;
- [x] pass additive size gate in CI #675;
- [x] add privacy-safe shipping preflight/resource/teardown collector;
- [x] add exact-DMG target-Mac runner with read-only mount and normal AppKit termination;
- [x] qualify deterministic gates `NH-MEDIA-SHIP-001...005` and `010`;
- [ ] `NH-MEDIA-SHIP-006` — target app owns exactly one expected adapter and terminates it cleanly;
- [ ] `NH-MEDIA-SHIP-007` — no Accessibility/Input Monitoring/Automation/Screen Recording prompts;
- [ ] `NH-MEDIA-SHIP-008` — 60-second target app+adapter resource evidence;
- [ ] `NH-MEDIA-SHIP-009` — approximately 10-minute target stability/no sustained growth/no orphan;
- [ ] final decision: `M6.4 ACCEPTED`.

Until the four target gates pass, PR #17 remains Draft and Media UI is not the next implementation step.

## Current approved priority order — 2026-08-11

1. Run the exact M6.4 frozen CI #675 shipping candidate through `docs/testing/SHIPPING_MEDIA_COMPOSITION_TARGET_MAC.md` on Mac16,8/macOS 26.6.
2. Record `NH-MEDIA-SHIP-006...009`; investigate any failure without silently widening permissions or performance budgets.
3. If the target gate passes, finalize M6.4 docs, exact-head CI/change review and merge PR #17.
4. Implement compact + expanded media-first UI as a separate slice.
5. Implement local-window gesture/haptic/seek state machines under TDD.
6. Run physical media/haptic acceptance on available sources.
7. Run P1 whole-app performance review, including the production media lifecycle cost and deferred local tracking experiment.
8. Optimize only from evidence, then resume remaining M1 display/Space hardening and later modules.

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
