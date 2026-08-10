# Project state

Last updated: 2026-08-10
Current version: `0.1.0` (Personal Release published and accepted)
Repository visibility: **Public**
Primary physical target: macOS `26.6` / `Mac16,8`
Protected branch target: `main`

## Current product state

**M6.3 concrete production system media transport is ACCEPTED on the target Mac. The next engineering slice is shipping composition: intentionally link the accepted media core/transport and pinned adapter resources into `NotchHub.app`, then collect fresh shipping security, artifact-size, and target-Mac runtime evidence before Media UI work.**

Accepted foundations/integrations:

- M0 Engineering Foundation — accepted;
- R0.1 Personal Release `v0.1.0` — accepted;
- P0 Performance Foundation — accepted and merged as `a056aa74bad5d8e193eb4c76a76e6c910344bd09`;
- P0.1 Public Repository Readiness — accepted;
- M1 interaction/transition slice — accepted and merged as `094b494bd597643244e733baf5787a13b61fb4eb`;
- Universal Media design — `403a557399abb2704f9ae02397b49229ca6cf1f9`;
- M6.1 transport probe — accepted/merged as `7d5210eb0363933d120334d29daf40956b53cb50`, final outcome `ACCEPT_TRANSPORT`;
- M6.2 production media state/controller/bridge boundary — accepted/merged as `1ccea500570f9a5ca927739be58d7f7eaadd775a`;
- M6.3 concrete production transport — **accepted on frozen candidate `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`**.

Authoritative M6.3 evidence: `docs/testing/PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`.

## Product

NotchHub is a personal native local-first macOS productivity hub built around the MacBook notch. Planned modules include Shelf, Snippets, Calendar, Translator, Universal Media, and later shell/settings capabilities.

Universal Media follows the system Now Playing source selected by macOS rather than targeting one player. Yandex Music and Yandex Browser are physically verified through the accepted production transport. Apple Music, Spotify, and additional independent-player compatibility remain explicitly unverified until physically tested.

NotchNook and Boring Notch are independent product/engineering references only. NotchHub remains an independent MIT implementation; GPL-covered implementation code is not copied.

## Accepted engineering baseline

### M0 / M1 interaction foundation

Accepted behavior includes:

- Swift 6 native shell;
- public notch geometry and AppKit-owned panel sizing;
- one cancellable `120 ms` hover dwell;
- compact activation geometry 4 pt left/right/bottom and 0 pt top with inclusive boundaries;
- one public `.levelChange` haptic for eligible deliberate expansion;
- `NotchPanelTransitionCoordinator` as sole compact/expanded transition authority;
- `0.20 s` AppKit/Core Animation transition with Reduce Motion = zero duration;
- one local + one narrow global `.mouseMoved` fallback with explicit lifecycle ownership;
- no per-event `Task` allocation in the live pointer hot path;
- no display link, polling loop, repeating timer, synthetic input, Accessibility or Input Monitoring requirement for notch interaction.

Remaining M1 display/Space hardening stays deferred behind the functional media slice and P1 performance review.

### R0.1 Personal Release

Immutable `v0.1.0` is accepted for personal use. It is ad-hoc signed, sandboxed, Hardened Runtime protected, checksum/provenance verified and intentionally not notarized. Paid Apple Developer Program membership is not required for the current personal-use tier.

### P0 Performance Foundation

Accepted target-Mac baseline:

- idle CPU median/max `0.0% / 0.7%`, RSS max `33,808 KiB`, threads max `4`;
- hover CPU median/max `5.95% / 22.3%`, RSS max `38,816 KiB`, threads max `7`;
- 10-minute stability CPU median/max `0.0% / 6.8%`, RSS max `34,384 KiB`, RSS drift `-3,712 KiB`, threads max `7`.

Immutable `v0.1.0` artifact baseline:

- executable `220,560 B`;
- app aggregate `223,555 B`;
- DMG `73,955 B`.

Shared CI keeps deterministic relative/absolute artifact-size gates. CPU/RSS/thread magnitude acceptance remains target-Mac evidence rather than hosted-runner thresholds.

## Universal Media

### M6.1 — transport feasibility

Status: **ACCEPTED — `ACCEPT_TRANSPORT`**.

The compatibility probe physically established on macOS 26.6:

- App Sandbox + Hardened Runtime compatibility;
- no Accessibility/Input Monitoring/Automation/Screen Recording prompts;
- authoritative no-session and active capabilities;
- Yandex Music and Yandex Browser system Now Playing observation;
- real toggle/previous/next/seek behavior;
- source switching/disappearance;
- clean teardown/no orphan;
- bounded fail-closed failure lifecycle;
- low steady resource use and stable 10-minute behavior.

### M6.2 — production state/controller/bridge boundary

Status: **ACCEPTED AND MERGED**.

Independent `NotchHubMediaCore` provides:

- normalized media domain types and immutable `MediaSessionSnapshot`;
- `MediaSequence` generation/revision ordering;
- player-agnostic `MediaProvider`;
- `@MainActor MediaSessionController` freshness, dedup, capability gating and one-restart/no-loop behavior;
- injected `SystemMediaTransport`;
- `SystemMediaBridge` callback ownership, teardown and typed command forwarding.

The media core is still intentionally outside the shipping `NotchHubApp` link graph. Linking dormant media core during M6.2 exceeded the unchanged P0 size gate, so real shipping feature cost must be measured only when composition is intentionally introduced.

### M6.3 — concrete production system transport

Status: **ACCEPTED**.

Accepted exact candidate:

- source: `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`;
- CI #576 / run `31339015100` — PASS;
- artifact ID `9045247126`;
- digest `sha256:a6323c504021f21e7638b40e47bedd0b2c1a9fcfcf861724c139151ee8faa804`;
- pinned adapter `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- capability patch SHA-256 `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`.

Accepted implementation properties:

- strict bounded event-stream wire decoding and full-snapshot semantics;
- authoritative tri-state capabilities;
- `MediaRemoteSystemTransport` source/session freshness and stale-capability rejection;
- one reviewed Foundation `Process()` boundary fixed to `/usr/bin/perl`;
- closed typed toggle/previous/next/seek command surface;
- bounded graceful/forced owned-process teardown with no polling/repeating timer;
- privacy-safe evidence and no listening-history persistence;
- no player-specific fallback, networking or sensitive permission expansion;
- shipping isolation retained.

Target-Mac acceptance on `Mac16,8` / macOS 26.6 passes all stable IDs `NH-MEDIA-PROD-001` through `NH-MEDIA-PROD-013`:

- no-session capabilities `unknown/unknown/unknown`;
- Yandex Music production observation and `supported/supported/supported` active capabilities;
- Yandex Browser production observation;
- authoritative Yandex Music -> Yandex Browser source switch with `sourceSwitchCount = 1` and later disappearance;
- real toggle pause/resume, next, previous and seek 42s — all PASS;
- Accessibility, Input Monitoring, Automation and Screen Recording prompts — NONE;
- clean teardown and no orphan process;
- 60-second steady combined CPU median/max upper bound `0.0/0.1%`, RSS median/max upper bounds `26,416/32,192 KiB`, thread median/max upper bounds `4/9`;
- corrected 10-minute run: 120 samples, combined CPU median/max upper bounds `0.0/7.5%`, RSS `35,168 -> 26,160 KiB` (`-9,008 KiB`), threads `11 -> 4`, clean teardown, no orphan.

A superseded candidate exposed an unbounded `waitUntilExit()` teardown defect. M6.3 fixed it with bounded process-exit-event waits and SIGKILL escalation for the owned adapter. Physical 10-minute regression evidence confirms the fix.

Acceptance collector sampling/watchdog defects found during target testing were also corrected under tests without changing the frozen production candidate.

## Security baseline

`SECURITY.md` remains authoritative.

Current shipping `NotchHub.app` still adds no telemetry, analytics, networking, runtime subprocess, dynamic loading, privileged helper, sensitive input permission, or synthetic input surface beyond the previously accepted narrow pointer fallback.

M6.3 authorizes one narrowly reviewed production-code process boundary inside isolated `NotchHubMediaCore`; it is not shipping yet. Any shipping composition must retain App Sandbox, Hardened Runtime/library validation, the fixed `/usr/bin/perl` executable, pinned adapter provenance, closed typed commands, bounded I/O, explicit teardown and no sensitive permission prompts.

## Known limitations / technical debt

- `NotchHubMediaCore` is not yet linked into `NotchHubApp`;
- adapter/framework assets are not yet packaged into the shipping app;
- the real post-composition shipping size/security/runtime cost is not yet accepted;
- no compact/expanded media UI, progress rendering or gesture/haptic/seek interaction ships yet;
- Apple Music, Spotify and additional-player compatibility are not physically verified;
- the global `.mouseMoved` fallback remains pending the P1 `NSTrackingArea` / window-local comparison;
- active-display migration, fullscreen/Spaces, screen-configuration handling, notchless mode and click/pin policy remain later work;
- target-Mac whole-app runtime ceilings still derive from the accepted canonical baseline and will be revisited after functional media integration.

## Next optimal step

1. Start a **separate shipping-composition slice** that links `NotchHubMediaCore` and the pinned adapter/framework resources into `NotchHub.app`.
2. Preserve the accepted security boundary and collect fresh package/signature/entitlement/artifact-size evidence; do not silently widen P0 budgets.
3. Run target-Mac whole-app runtime evidence for the composed transport lifecycle before considering the path reliable.
4. After composition is accepted, implement compact + expanded media-first UI.
5. Then implement local-window gesture/haptic/seek state machines under TDD and run physical media/haptic acceptance.
6. After the complete functional media slice, perform P1 whole-app resource review and the deferred `NSTrackingArea` / window-local pointer experiment.
