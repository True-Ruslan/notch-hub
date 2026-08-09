# Project state

Last updated: 2026-08-09
Current version: `0.1.0` (Personal Release published and accepted)
Repository visibility: **Public**
Primary physical target: macOS `26.6`
Protected branch target: `main`

Key accepted integrations:

- P0 Performance Foundation: `a056aa74bad5d8e193eb4c76a76e6c910344bd09`;
- public-readiness hardening: `23500e099a0f8b2738f1157c6ae3be71c89df6e1`;
- M1 interaction/transition slice: `094b494bd597643244e733baf5787a13b61fb4eb`;
- Universal Media design: `403a557399abb2704f9ae02397b49229ca6cf1f9`;
- M6.1 Universal Media transport probe: `7d5210eb0363933d120334d29daf40956b53cb50`, final outcome **`ACCEPT_TRANSPORT`**.

Current product state: **M6.2 production Universal Media state/controller/bridge boundary implemented and deterministically accepted; concrete system transport integration is the next active sub-slice.**

Approved Universal Media design: `docs/superpowers/specs/2026-08-09-universal-media-gestures-haptics-design.md`.
Accepted M6.1 evidence: `docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md`.
M6.2 implementation plan: `docs/superpowers/plans/2026-08-09-production-media-boundary.md`.

## Product

NotchHub is a personal, native, local-first macOS productivity hub built around the MacBook notch. Planned modules are Shelf, Snippets, Calendar, Translator, Universal Media, and later shell/settings capabilities.

Universal Media follows the system Now Playing source selected by macOS rather than targeting one music application. Yandex Music and Yandex Browser are physically verified transport sources on the Personal Release target. Apple Music, Spotify, and another independent player remain future compatibility checks and must not be claimed as verified support until tested.

NotchNook is a public product/UI research reference only; NotchHub remains an independent implementation.

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

Status: **IMPLEMENTED; DETERMINISTIC CI ACCEPTED; READY FOR INTEGRATION**.

Draft PR: #14 `M6.2 Production media state/controller boundary`.
Implementation plan: `docs/superpowers/plans/2026-08-09-production-media-boundary.md`.
Accepted code head before documentation-only synchronization: `52d6d76b564c603cb21f0ec49bff4fa958c3aac7`.
Exact code CI: **#500 / run `31310130322` — both jobs PASS**.
Swift suite: **117/117 PASS**.

### Implemented production module

M6.2 introduces independent Swift target `NotchHubMediaCore`, containing only the production application-side media architecture:

- `MediaSequence` with lexicographic generation/revision ordering;
- normalized capability/playback/source/command/subsystem types;
- immutable `MediaSessionSnapshot` with optional metadata/artwork/timing fields and no fabricated defaults;
- player-agnostic `MediaProvider` with one event handler, explicit lifecycle, and typed async commands;
- `@MainActor MediaSessionController` owning freshness, deduplication, normalized state, capability gating, command forwarding, stale-callback rejection, and exactly one controlled restart;
- injected `SystemMediaTransport` protocol;
- `SystemMediaBridge` owning one transport callback, idempotent start, handler-before-stop teardown, stale-callback invalidation, typed event forwarding, and typed command forwarding.

The implementation contains no concrete MediaRemote/private API/process/dynamic-loading code, no player-specific adapters, no UI, no gestures/haptics, no persistence/logging, no networking, no polling/repeating timers, and no entitlement changes.

### Controller contract proven by tests

Deterministic coverage proves:

- start is idempotent;
- ready/no-session/playback state mapping;
- strictly newer sequence ordering;
- newer generation supersedes older generation;
- stale and same-sequence conflicting events are ignored;
- duplicate state does not publish twice;
- unknown/unsupported previous/next/seek fail closed without provider calls;
- invalid seek fails closed;
- supported semantic commands use only the typed provider channel;
- command failure does not mutate authoritative state;
- first unexpected failure performs exactly one controlled restart;
- stale callbacks from the previous provider generation are ignored;
- second failure locks the controller unavailable with no restart loop;
- explicit stop is terminal for that controller lifecycle.

`SystemMediaBridge` tests additionally prove one callback owner, event forwarding, typed-command forwarding only while started, teardown ordering, and stale transport-handler rejection after stop/restart.

### Shipping isolation and size finding

During TDD, linking the dormant controller directly into `NotchHubCore` increased the shipping executable to roughly `288–291 KiB` and violated the unchanged P0 size gate. A controlled sync-vs-async command experiment changed **zero bytes**, proving Swift concurrency was not the cause. The growth came from making otherwise unused media state-machine code reachable from the shipping link graph.

The accepted architecture therefore keeps `NotchHubMediaCore` as a fully built/tested production target that is not yet a dependency of `NotchHubApp`.

Exact CI #500 proves this restores the shipping payload without weakening budgets:

- executable `250,320 B` — exactly the accepted pre-M6.2 payload;
- app `253,317 B` — exactly the accepted pre-M6.2 payload;
- executable segment `65,536 B` — restored to the pre-M6.2 value;
- DMG `84,661 B`;
- 117 Swift tests PASS;
- release/performance/media-policy/security audit PASS;
- App Sandbox + Hardened Runtime/signature/package verification PASS.

No security/performance policy was weakened or modified to obtain this result.

This isolation is temporary by design: when a concrete system transport and app composition are implemented, the media module will intentionally enter the shipping link graph and its real feature cost must be reviewed with fresh size/runtime/security evidence.

## Security baseline

`SECURITY.md` remains authoritative.

Current shipping `NotchHub.app` still adds no telemetry, analytics, networking, runtime subprocess/shell, dynamic loading, privileged helper, Accessibility/Input Monitoring permission, synthetic input, or broad input capture beyond the accepted narrow `.mouseMoved` fallback.

M6.1 private transport compatibility remains development evidence only. M6.2 production code contains abstractions/state machines but no private transport implementation. The next concrete system transport must remain behind the accepted boundary and may not be made to work by weakening Sandbox, Hardened Runtime, library validation, Gatekeeper/SIP, or adding sensitive permissions.

## Known limitations / technical debt

- target-Mac whole-app runtime ceilings still derive from one canonical accepted run per scenario with conservative headroom;
- hosted-runner CPU/RAM values are not representative of the target Mac;
- the narrow global `.mouseMoved` fallback remains pending the P1 local-tracking comparison;
- Apple Music, Spotify, and arbitrary independent-player compatibility are not physically verified;
- the concrete production system media transport is not implemented yet;
- `NotchHubMediaCore` is intentionally not composed into `NotchHubApp` yet;
- no media UI, progress presentation, gestures, haptics, or seek interaction is shipping yet;
- active-display migration, Spaces/fullscreen, screen-configuration handling, notchless mode, click/pin policy, and optional trusted distribution remain later work.

## Next optimal step

1. Design and implement the concrete production `SystemMediaTransport` behind the accepted `SystemMediaBridge` boundary using strict TDD and the M6.1 compatibility evidence.
2. Keep the concrete transport isolated: no arbitrary command surface, polling, metadata logging/persistence, network access, sensitive permissions, or security weakening.
3. Compose `NotchHubMediaCore` into `NotchHubApp` only as part of that reviewed transport slice and explicitly measure the resulting shipping size/security/runtime cost.
4. After the production transport/state path is reliable, implement compact + expanded media-first UI.
5. Then implement local-window gesture/haptic/seek state machines under TDD.
6. Run target-Mac functional media acceptance on actually available sources, retaining unavailable compatibility as deferred.
7. After the complete functional media slice passes hardware acceptance, run P1 whole-app resource measurements and the deferred `NSTrackingArea` experiment.
