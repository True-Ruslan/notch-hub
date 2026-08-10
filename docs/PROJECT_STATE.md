# Project state

Last updated: 2026-08-10
Current version: `0.1.0` (Personal Release published and accepted)
Repository visibility: **Public**
Primary physical target: macOS `26.6`
Protected branch target: `main`

Key accepted integrations:

- P0 Performance Foundation: `a056aa74bad5d8e193eb4c76a76e6c910344bd09`;
- public-readiness hardening: `23500e099a0f8b2738f1157c6ae3be71c89df6e1`;
- M1 interaction/transition slice: `094b494bd597643244e733baf5787a13b61fb4eb`;
- Universal Media design: `403a557399abb2704f9ae02397b49229ca6cf1f9`;
- M6.1 Universal Media transport probe: `7d5210eb0363933d120334d29daf40956b53cb50`, final outcome **`ACCEPT_TRANSPORT`**;
- M6.2 production media state/controller/bridge boundary: `1ccea500570f9a5ca927739be58d7f7eaadd775a`.

Current product state: **M6.3 concrete production system media transport is implemented and CI-qualified in Draft PR #16, but target-Mac acceptance is still partial. The transport must not be composed into the shipping app until the remaining physical gates pass and the acceptance ledger records an explicit final decision.**

Approved Universal Media design: `docs/superpowers/specs/2026-08-09-universal-media-gestures-haptics-design.md`.
Accepted M6.1 evidence: `docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md`.
M6.2 implementation plan: `docs/superpowers/plans/2026-08-09-production-media-boundary.md`.
M6.3 implementation plan: `docs/superpowers/plans/2026-08-09-production-system-media-transport.md`.
M6.3 acceptance ledger: `docs/testing/PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`.
M6.3 target procedure: `docs/testing/PRODUCTION_MEDIA_TRANSPORT_TARGET_MAC.md`.

## Product

NotchHub is a personal, native, local-first macOS productivity hub built around the MacBook notch. Planned modules are Shelf, Snippets, Calendar, Translator, Universal Media, and later shell/settings capabilities.

Universal Media follows the system Now Playing source selected by macOS rather than targeting one music application. Yandex Music and Yandex Browser are physically verified transport sources for the accepted M6.1 compatibility probe. The M6.3 production transport has already physically observed Yandex Music; Yandex Browser production observation/source switching is still pending and must not be claimed until the current candidate passes that gate. Apple Music, Spotify, and another independent player remain future compatibility checks and must not be claimed as verified support until tested.

NotchNook and Boring Notch are independent product/engineering research references only; NotchHub remains an independent MIT implementation and does not copy proprietary or GPL-covered implementation code.

## Accepted foundation

### M0 — Engineering foundation

Status: **ACCEPTED AND MERGED**.

Accepted target-Mac gates include `NH-OS26-001`, `NH-NOTCH-001`, and `NH-HOVER-001/002/003`.

M0 established the Swift 6 native shell, public notch geometry, deterministic pointer policy, AppKit-owned panel sizing, App Sandbox + Hardened Runtime, strict CI/security/package gates, and real-hardware regression coverage.

### R0.1 — Personal Release

Status: **ACCEPTED**.

Immutable `v0.1.0` was published from source `8e913dcddfdec7d9aa920df8c37afb23b8c40884` and passed downloaded-release acceptance on the target MacBook/macOS 26.6. Personal Release remains ad-hoc signed, sandboxed, Hardened Runtime protected, checksum/provenance verified, and intentionally not notarized.

### P0 — Performance Foundation

Status: **ACCEPTED AND MERGED**.

Accepted target-Mac baseline on macOS 26.6 / `Mac16,8`:

- idle CPU median/max `0.0% / 0.7%`, RSS max `33,808 KiB`, threads max `4`;
- hover CPU median/max `5.95% / 22.3%`, RSS max `38,816 KiB`, threads max `7`;
- 10-minute stability CPU median/max `0.0% / 6.8%`, RSS max `34,384 KiB`, RSS drift `-3,712 KiB`, threads max `7`.

Immutable `v0.1.0` size baseline:

- executable `220,560 B`;
- app aggregate `223,555 B`;
- DMG `73,955 B`.

The unchanged shared-CI relative gates remain executable `253,644 B` and app `257,088 B`; absolute ceilings remain executable `266,240 B`, app `270,336 B`, and DMG `90,112 B`. Runtime CPU/RSS/thread acceptance remains target-Mac evidence, not hosted-runner thresholds.

### P0.1 — Public repository readiness

Status: **ACCEPTED**.

Public-fork CI remains read-only/unprivileged; release authority is isolated from untrusted PR execution; protected-branch and immutable-release boundaries remain in force.

## M1 — Interaction and transition hardening

Status: **INTERACTION/TRANSITION SLICE ACCEPTED AND MERGED; REMAINING DISPLAY/SPACE HARDENING DEFERRED BEHIND UNIVERSAL MEDIA + P1**.

Accepted behavior includes:

- one cancellable `120 ms` compact activation dwell;
- compact activation geometry 4 pt left/right/bottom and 0 pt top, with exact inclusive boundaries;
- deterministic stale-callback/cancellation/re-entry behavior;
- exactly one `.levelChange` haptic for eligible deliberate expansion;
- `NotchPanelTransitionCoordinator` as sole compact/expanded transition authority;
- `0.20 s` AppKit/Core Animation transition with Reduce Motion = zero duration;
- explicit pointer-monitor and accessibility-observer ownership;
- one local and one narrow global `.mouseMoved` fallback;
- no per-event Swift concurrency task allocation;
- no display link, polling loop, repeating timer, synthetic input, or sensitive permission expansion.

The global `.mouseMoved` fallback remains pending the P1 `NSTrackingArea` / window-local comparison after the complete functional media slice.

## M6.1 — Universal Media transport probe

Status: **ACCEPTED — `ACCEPT_TRANSPORT`**.

Merge: `7d5210eb0363933d120334d29daf40956b53cb50`.
Accepted exact physical candidate: `cda05bb4ff367d2c4a5d9d438c3f555f3788d186`, CI #443 / run `31304052700`, artifact ID `9035397233`, digest `sha256:5cd10a0c6e9b61d8f060ca29ab8a84a7b1a1ba2408f2769b88ea86bf908be5c0`.

Accepted target-Mac evidence on `Mac16,8`, macOS 26.6 build `25G72`:

- exact sandbox-only entitlement and Hardened Runtime;
- no Accessibility/Input Monitoring/Automation/Screen Recording prompt;
- no-session authoritative capabilities `unknown/unknown/unknown`;
- Yandex Music active capabilities `supported/supported/supported`;
- Yandex Browser system Now Playing session and authoritative capabilities;
- real play/pause, previous, next, and seek behavior;
- event-driven source switching and disappearance;
- clean teardown/no orphan process;
- deterministic fail-closed/no-restart-loop failure behavior;
- 60-second combined steady resource evidence around 25.4 MiB RSS / 4 threads with sampled CPU `0.0%`;
- corrected 10-minute combined RSS drift `-160 KiB`, ending threads unchanged at 4, adapter CPU max `0.1%`.

Deferred, not failed: Apple Music, Spotify, and one additional independent player are not available/used on the Personal Release target and remain `NOT TESTED / DEFERRED`.

## M6.2 — Production media state/controller/bridge boundary

Status: **ACCEPTED AND MERGED**.

PR #14 `M6.2 Production media state/controller boundary` was squash-merged into protected `main` as `1ccea500570f9a5ca927739be58d7f7eaadd775a`.
Implementation plan: `docs/superpowers/plans/2026-08-09-production-media-boundary.md`.
Accepted code head before documentation-only synchronization: `52d6d76b564c603cb21f0ec49bff4fa958c3aac7`.
Exact code CI: **#500 / run `31310130322` — both jobs PASS**.
Final PR head: `78b9c07d204777c775708de7cfa48e27128241f2`.
Final exact-head CI: **#505 / run `31310571146` — both jobs PASS**.
Swift suite: **117/117 PASS**.

### Implemented production module

M6.2 introduces independent Swift target `NotchHubMediaCore`, containing the production application-side media architecture:

- `MediaSequence` with lexicographic generation/revision ordering;
- normalized capability/playback/source/command/subsystem types;
- immutable `MediaSessionSnapshot` with optional metadata/artwork/timing fields and no fabricated defaults;
- player-agnostic `MediaProvider` with one event handler, explicit lifecycle, and typed async commands;
- `@MainActor MediaSessionController` owning freshness, deduplication, normalized state, capability gating, command forwarding, stale-callback rejection, and exactly one controlled restart;
- injected `SystemMediaTransport` protocol;
- `SystemMediaBridge` owning one transport callback, idempotent start, handler-before-stop teardown, stale-callback invalidation, typed event forwarding, and typed command forwarding.

The accepted M6.2 merge contains no concrete private transport implementation and remains isolated from `NotchHubApp`.

### Shipping isolation and size finding

During TDD, linking the dormant controller directly into `NotchHubCore` increased the shipping executable to roughly `288–291 KiB` and violated the unchanged P0 size gate. A controlled sync-vs-async command experiment changed **zero bytes**, proving Swift concurrency was not the cause. The growth came from making otherwise unused media state-machine code reachable from the shipping link graph.

The accepted architecture therefore keeps `NotchHubMediaCore` as a fully built/tested production target that is not yet a dependency of `NotchHubApp`.

Final exact-head CI #505 reconfirmed the unchanged shipping boundary:

- executable `250,320 B`;
- app `253,317 B`;
- executable segment `65,536 B`;
- DMG `84,678 B`;
- 117 Swift tests PASS;
- release/performance/media-policy/security audit PASS;
- App Sandbox effective entitlements remain exactly `com.apple.security.app-sandbox=true`;
- Hardened Runtime remains enabled;
- package/signature/performance-harness checks PASS.

No security/performance policy was weakened or modified to obtain this result.

## M6.3 — Concrete production system media transport

Status: **IMPLEMENTED / CI-QUALIFIED / TARGET-MAC ACCEPTANCE PARTIAL — DRAFT PR #16**.

PR: #16 `M6.3 Production system media transport`.
Branch: `agent/m6-3-production-system-media-transport`.
Current production code candidate is intentionally frozen at `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b` from CI #576 / run `31339015100`, artifact ID `9045247126`, digest `sha256:a6323c504021f21e7638b40e47bedd0b2c1a9fcfcf861724c139151ee8faa804`.
Pinned adapter: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`.
Capability patch SHA-256: `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`.

The current PR head is ahead of the frozen physical candidate only through acceptance-ledger/procedure/collector work. No production `Sources/NotchHubMediaCore/**`, candidate packaging/signing, adapter, patch, entitlement, or reviewed transport-security boundary changed after the frozen candidate.

### Implemented production transport

M6.3 adds:

- strict bounded `stream --no-diff --micros` wire decoding with full-snapshot semantics;
- defensive bounds for text, JSON, timing values, artwork and enum/capability state;
- exactly one reviewed Foundation `Process` boundary with executable fixed to `/usr/bin/perl` and closed arguments;
- no shell, arbitrary executable, arbitrary MediaRemote command ID, player-specific fallback or networking surface;
- authoritative `supported / unsupported / unknown` previous/next/seek semantics;
- `MediaRemoteSystemTransport` with monotonic generation/revision ordering, no-session invalidation, stale-artwork clearing, source-switch isolation and stale-capability completion rejection;
- typed toggle/previous/next/seek only;
- privacy-safe production candidate evidence with no title/artist/album/artwork/listening-history retention;
- development-only production candidate packaging under App Sandbox + Hardened Runtime;
- target-Mac acceptance tooling for preflight, source-cycle and parent+owned-adapter resource evidence;
- exact shipping isolation: `NotchHubApp` still does not link `NotchHubMediaCore`, and no adapter/candidate asset is inside `NotchHub.app`.

### Target-discovered production lifecycle defect

The superseded candidate from CI #558 exposed a real production teardown defect during the approximately 10-minute target run: finalization could remain in unbounded `Process.waitUntilExit()` after the sample window.

The frozen current candidate fixes that defect under RED -> GREEN coverage:

- graceful owned-process termination receives a fixed 1-second process-exit-event window;
- if graceful termination is not confirmed, the owned adapter is escalated to `SIGKILL`;
- forced termination receives a second fixed 1-second process-exit-event window;
- no polling/repeating timer is used for teardown waiting;
- unconfirmed exit becomes `.teardownFailure` and `lastTeardownClean = false`;
- candidate evidence derives `cleanTeardown` from the real process result;
- protocol-failure and one-shot-timeout cleanup share the same bounded policy;
- controller ownership remains exactly one controlled restart with no restart loop.

### Current candidate evidence

Already accepted on `Mac16,8` / macOS 26.6 for the frozen candidate:

- exact provenance, strict code-sign verification, App Sandbox-only effective entitlement and Hardened Runtime: PASS;
- active Yandex Music capabilities `previous/next/seek = supported/supported/supported`: PASS;
- Yandex Music session/artwork/playing-state observation: PASS;
- real session disappearance: PASS;
- clean teardown on the completed 120-second observation: PASS;
- `NH-MEDIA-PROD-012` 60-second resource gate: PASS;
- parent CPU median/max `0.0/0.0%`;
- adapter CPU median/max `0.0/0.1%`;
- combined RSS median/max upper bounds `26,416/32,192 KiB`;
- combined thread median/max upper bounds `4/9`;
- `cleanTeardown = true`;
- `orphanProcessDetected = false`.

Two target-acceptance collector defects were subsequently found and fixed without changing the frozen production candidate:

1. resource sampling now uses the proven numeric CPU/RSS/thread boundary rather than parsing a command column as metrics;
2. long-run completion now uses an absolute observer deadline plus bounded 60-second completion grace instead of a brittle fixed 20-second post-sampling watchdog.

The latest approximately 10-minute attempt before the second collector fix is **INVALID / RETRY REQUIRED**, not a transport/performance failure, because the superseded collector watchdog terminated the observer before final JSON was written.

### Remaining M6.3 physical gates

Before PR #16 may become Ready or merge, the frozen candidate still requires:

- `NH-MEDIA-PROD-002`: no-session target preflight proving fail-closed capabilities, expected normally as `unknown/unknown/unknown`;
- `NH-MEDIA-PROD-004`: Yandex Browser / YouTube production observation through the same transport;
- remaining `NH-MEDIA-PROD-005`: authoritative Yandex Music -> browser source switch with `sourceSwitchCount > 0`;
- remaining `NH-MEDIA-PROD-006`: separate no-session capability evidence;
- `NH-MEDIA-PROD-007`: actual toggle pause/resume, next, previous and seek behavior when capability is supported;
- `NH-MEDIA-PROD-011`: no Accessibility/Input Monitoring/Automation/Screen Recording prompts during the complete target cycle;
- `NH-MEDIA-PROD-013`: corrected approximately 10-minute stability retry with produced JSON, no sustained growth, truthful clean teardown and no orphan adapter process.

`NH-MEDIA-PROD-012` does not need to be repeated unless later production-candidate code changes invalidate the frozen candidate.

## Security baseline

`SECURITY.md` remains authoritative.

The current shipping `NotchHub.app` still adds no telemetry, analytics, networking, runtime subprocess/shell, dynamic loading, privileged helper, Accessibility/Input Monitoring permission, synthetic input, or broad input capture beyond the accepted narrow `.mouseMoved` fallback.

M6.3 introduces one narrowly reviewed production-code `Process` exception inside the isolated concrete media transport: fixed `/usr/bin/perl`, pinned adapter assets, closed arguments/typed commands, bounded I/O and explicit owned-process teardown. This exception is **not shipping yet** because `NotchHubMediaCore` remains outside the current `NotchHubApp` dependency graph and adapter assets are not packaged into `NotchHub.app`.

The production transport may not be accepted or composed by weakening App Sandbox, Hardened Runtime, library validation, Gatekeeper/SIP, broadening input capture, adding sensitive permissions, player-specific automation, arbitrary execution, polling or metadata/history persistence.

## Known limitations / technical debt

- target-Mac whole-app runtime ceilings still derive from one canonical accepted run per scenario with conservative headroom;
- hosted-runner CPU/RAM values are not representative of the target Mac;
- the narrow global `.mouseMoved` fallback remains pending the P1 local-tracking comparison;
- Apple Music, Spotify, and arbitrary independent-player compatibility are not physically verified;
- M6.3 concrete production transport is implemented but its target-Mac acceptance is not complete;
- Yandex Browser production observation/source switching is not yet accepted for M6.3;
- the current-candidate no-session and actual-command/permission gates remain pending;
- the corrected M6.3 10-minute stability run remains pending retry;
- `NotchHubMediaCore` is intentionally not composed into `NotchHubApp` yet;
- no production adapter assets are packaged into the shipping app yet;
- no media UI, progress presentation, gestures, haptics, or seek interaction is shipping yet;
- active-display migration, Spaces/fullscreen, screen-configuration handling, notchless mode, click/pin policy, and optional trusted distribution remain later work.

## Next optimal step

1. Complete the remaining M6.3 target-Mac gates on the exact frozen candidate `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`; do not manufacture evidence or substitute the already accepted M6.1 probe for production acceptance.
2. If all required gates pass, record the final explicit M6.3 acceptance decision, synchronize `CHANGELOG.md` / `ROADMAP.md` / PR state, run fresh exact-head CI, review, mark PR #16 Ready and squash-merge through protected `main`.
3. Only after accepted M6.3 is merged, start a **separate shipping-composition slice** that links `NotchHubMediaCore` and the pinned adapter assets into `NotchHub.app`, with fresh package/security/artifact-size and target-Mac runtime evidence. Do not silently hide or pre-approve the real shipping feature cost.
4. After the production transport/state path is reliable in the shipping composition, implement compact + expanded media-first UI.
5. Then implement local-window gesture/haptic/seek state machines under TDD.
6. Run target-Mac functional media/haptic acceptance on actually available sources, retaining unavailable compatibility as deferred.
7. After the complete functional media slice passes hardware acceptance, run P1 whole-app resource measurements and the deferred `NSTrackingArea` / window-local pointer experiment.
