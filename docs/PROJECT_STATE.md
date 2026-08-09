# Project state

Last updated: 2026-08-09
Current version: `0.1.0` (Personal Release published and accepted)
Repository visibility: **Public**
Primary physical target: macOS `26.6`
Protected branch target: `main`
P0 merge commit: `a056aa74bad5d8e193eb4c76a76e6c910344bd09`
Public-readiness hardening merge: `23500e099a0f8b2738f1157c6ae3be71c89df6e1`
Current product state: M1 interaction/transition slice **ACCEPTED AND MERGED**; active slice M6.1 **Universal Media Bridge compatibility/security probe — IMPLEMENTED, PHYSICAL ACCEPTANCE IN PROGRESS**
Accepted interaction/transition slice: PR #10 `M1 delayed hover and haptic interaction core` — **ACCEPTED AND SQUASH-MERGED** as `094b494bd597643244e733baf5787a13b61fb4eb`
Approved Universal Media design: `docs/superpowers/specs/2026-08-09-universal-media-gestures-haptics-design.md`
Universal Media probe plan: `docs/superpowers/plans/2026-08-09-universal-media-bridge-probe.md`
Current probe PR: #13 `M6.1 Universal Media bridge compatibility probe` — **DRAFT, TRANSPORT DECISION PENDING**
Current exact physical candidate: source `cda05bb4ff367d2c4a5d9d438c3f555f3788d186`, CI #443 / run `31304052700`, artifact ID `9035397233`, digest `sha256:5cd10a0c6e9b61d8f060ca29ab8a84a7b1a1ba2408f2769b88ea86bf908be5c0`

## Product

NotchHub is a personal, native, local-first macOS productivity hub built around the MacBook notch. Planned modules are Shelf, Snippets, Calendar, Translator, and universal media controls that follow the system Now Playing source selected by macOS rather than targeting one music application. Yandex Music is one required real-world acceptance source alongside Apple Music, Spotify, browser media, and another independent player.

NotchNook is a public product/UI research reference only; NotchHub remains an independent implementation.

## Accepted foundation

### M0 — Engineering foundation

Status: **ACCEPTED AND MERGED**.

Accepted target-Mac evidence:

- `NH-OS26-001`: PASS;
- `NH-NOTCH-001`: PASS;
- `NH-HOVER-001`: PASS;
- `NH-HOVER-002`: PASS;
- `NH-HOVER-003`: PASS.

M0 includes the Swift 6 native shell, public notch geometry, deterministic pointer policy, AppKit-owned panel sizing, App Sandbox + Hardened Runtime, zero third-party Swift runtime dependencies, strict CI/security/package gates, and accepted real-hardware regression fixes.

### R0.1 — Personal Release

Status: **ACCEPTED**.

Immutable `v0.1.0` was published from accepted commit `8e913dcddfdec7d9aa920df8c37afb23b8c40884` and passed downloaded-release acceptance on the target MacBook/macOS 26.6. Personal Release remains ad-hoc signed, sandboxed, Hardened Runtime protected, checksum/provenance verified, and intentionally not notarized. Trusted Release remains an optional future tier.

### P0 — Performance Foundation

Status: **ACCEPTED AND MERGED**.

Accepted target-Mac baseline on macOS 26.6 / `Mac16,8`:

- `NH-PERF-IDLE-001`: CPU median/max `0.0% / 0.7%`, RSS median/max `33,648 / 33,808 KiB`, threads `4 / 4`;
- `NH-PERF-HOVER-001`: CPU median/max `5.95% / 22.3%`, RSS median/max `38,456 / 38,816 KiB`, threads `6 / 7`;
- `NH-PERF-STABILITY-001`: CPU median/max `0.0% / 6.8%`, RSS median/max `30,992 / 34,384 KiB`, threads `3 / 7`;
- 10-minute stability RSS delta `-3,712 KiB`, with no sustained memory/thread growth.

Accepted immutable `v0.1.0` artifact baseline:

- executable `220,560 B`;
- app aggregate `223,555 B`;
- DMG `73,955 B`.

Runtime CPU/RSS/thread limits remain target-Mac acceptance gates. Shared GitHub runners never substitute for physical resource evidence. Artifact byte sizes are deterministic and enforced in CI with the unchanged P0 budget: 15% relative allowance plus the accepted absolute ceilings.

### P0.1 — Public repository readiness

Status: **ACCEPTED**.

Public-source hardening is merged. Ordinary public pull-request CI remains read-only/unprivileged; Personal Release publication is isolated from untrusted PR execution; Trusted Release remains dormant without Apple credentials/environment.

## M1 — Interaction and transition hardening

Status: **ACCEPTED AND MERGED**.

Merge commit: `094b494bd597643244e733baf5787a13b61fb4eb`.
Authoritative requirements: `docs/specs/M1_NOTCH_INTERACTION.md`.

Accepted behavior includes:

- `120 ms` one-shot dwell with cancellation and stale-callback protection;
- exact compact activation geometry with inclusive 4 pt left/right/bottom and no top inset;
- exact top-edge physical activation acceptance;
- one public AppKit `.levelChange` haptic for successful deliberate expansion only;
- AppKit-owned `0.20 s` frame/corner transition with Reduce Motion support;
- no polling/repeating timer/display link/custom frame loop;
- one local and one narrow global `.mouseMoved` monitor with synchronous main-actor delivery;
- App Sandbox + Hardened Runtime boundary unchanged.

The narrow global `.mouseMoved` fallback remains accepted. Its `NSTrackingArea` / window-local experiment is deferred to P1 after the functional media slice so resource value is measured against the real application.

## M6.1 — Universal Media Bridge compatibility/security probe

Status: **IMPLEMENTED; DETERMINISTIC CI ACCEPTED; CURRENT TARGET-MAC ACCEPTANCE IN PROGRESS**.

PR: #13 `M6.1 Universal Media bridge compatibility probe`.
Physical procedure: `docs/testing/MEDIA_BRIDGE_PROBE.md`.
Evidence ledger: `docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md`.

### Implemented development-only boundary

- all probe code remains outside shipping `Sources/**`;
- fixed `/usr/bin/perl` process boundary, no shell string execution;
- pinned upstream `ungive/mediaremote-adapter` revision `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- repo-owned deterministic capability patch SHA-256 `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`;
- event-driven `stream --no-diff --micros`, no repeated `get` polling;
- typed toggle/next/previous/bounded-seek allowlist only;
- authoritative one-shot previous/next/seek capabilities with strict `supported|unsupported|unknown` semantics;
- no-session/indeterminate capability state fails safe to `unknown`;
- bounded stdout/stderr/protocol handling and fail-closed process lifecycle;
- privacy-safe report surface with no title/artist/album/artwork bytes/raw payload/listening history;
- observation schema v2 records only `observedSessionDisappearance` and `sourceSwitchCount` in addition to existing aggregate evidence;
- sandbox-only entitlement and Hardened Runtime remain mandatory;
- no Accessibility, Input Monitoring, Screen Recording, Automation, synthetic input, SIP weakening, or Gatekeeper weakening;
- shipping `NotchHub.app` remains probe-free and retains the accepted runtime/security boundary.

### Current deterministic candidate

Source `cda05bb4ff367d2c4a5d9d438c3f555f3788d186` passed CI #443 / run `31304052700` completely:

- **93/93 Swift tests PASS**;
- macOS 26 build and probe executable build with warnings as errors: PASS;
- pinned adapter patch/build: PASS;
- sandboxed/Hardened Runtime candidate verification: PASS;
- real one-shot `capabilities` invocation and exact tri-state schema validation: PASS;
- real one-second `observe` invocation and privacy-safe schema-v2 validation: PASS;
- signature-preserving ZIP round-trip and post-extraction provenance/entitlement verification: PASS;
- release/performance/media policy tests and source/security audit: PASS;
- shipping NotchHub DMG/signature/Sandbox/Hardened Runtime verification: PASS;
- unchanged P0 artifact-size budget: PASS;
- performance harness smoke: PASS;
- probe isolation from shipping `NotchHub.app`: PASS.

Exact artifact:

- artifact `MediaBridgeProbe-candidate`;
- artifact ID `9035397233`;
- digest `sha256:5cd10a0c6e9b61d8f060ca29ab8a84a7b1a1ba2408f2769b88ea86bf908be5c0`.

Hosted macOS 26 no-session capability evidence correctly returned:

```json
{"next":"unknown","previous":"unknown","seek":"unknown"}
```

### Target-Mac evidence so far

The previous exact candidate `231ada7baf83a3a1e9d2e38e35fc80a3f6d53758` produced strong first physical evidence on `Mac16,8` / macOS 26.6 build `25G72` with Yandex Music:

- source bundle identifier `ru.yandex.desktop.music` observed;
- 60-second event-driven observation produced 5 events;
- active session/playing state/artwork observed;
- clean teardown true;
- orphan process false;
- authoritative capability output: next/previous/seek all `supported`.

That run demonstrates the transport mechanism but is retained as historical evidence because the probe evidence schema was subsequently strengthened. Final acceptance must use current source `cda05bb4...`.

### Remaining physical gates

Highest-signal remaining checks on the current exact candidate:

1. no active system Now Playing source returns `unknown/unknown/unknown` on the target Mac;
2. Yandex Music rerun plus actual toggle/next/previous/seek behavior;
3. schema-v2 source-disappearance evidence (`observedSessionDisappearance=true`);
4. schema-v2 active-source-switch evidence (`sourceSwitchCount > 0`);
5. Apple Music, Spotify, browser media, and one additional independent Now Playing source;
6. explicit confirmation that no sensitive permission prompt appears;
7. target-Mac parent/perl CPU/RSS/thread measurements including a stability run.

PR #13 intentionally remains Draft. Do not record `ACCEPT_TRANSPORT` before these physical/resource gates are reviewed.

## Universal Media production design — APPROVED, PRODUCTION IMPLEMENTATION BLOCKED ON M6.1

The approved target is system-wide macOS Now Playing, not an application-specific integration. The production architecture remains:

- `SystemMediaBridge` as the only private compatibility boundary;
- player-agnostic `MediaProvider`;
- immutable `MediaSessionSnapshot`;
- `@MainActor MediaSessionController`;
- capabilities drive UI; unsupported/unknown commands are never fabricated;
- failure is fail-closed for media only;
- metadata/artwork are untrusted inputs and listening history is not persisted;
- event-driven updates only.

Production media implementation, media UI, gestures/haptics/seek, and later P1 whole-app performance work must not begin until M6.1 ends with `ACCEPT_TRANSPORT`.

## Security baseline

`SECURITY.md` remains authoritative. M1 shipping runtime adds no telemetry, analytics, networking, subprocess/shell, dynamic loading, private API, privileged helper, Accessibility/Input Monitoring permission, synthetic input, or broad input capture. Universal Media currently introduces private MediaRemote compatibility **only in the development probe**, not in shipping `Sources/**` or `NotchHub.app`.

A failed probe is rejected/redesigned rather than repaired by weakening Sandbox, Hardened Runtime, library validation, OS security, or adding broad permissions.

## Known limitations / technical debt

- target-Mac runtime ceilings still derive from one canonical run per scenario with conservative headroom;
- GitHub-hosted runner resource values are not representative of the target Mac;
- the narrow global `.mouseMoved` fallback remains pending the P1 `NSTrackingArea` / window-local comparison;
- production Universal Media transport is not yet accepted;
- current physical probe matrix/resource evidence is incomplete;
- active-display migration, Spaces/fullscreen, screen-configuration handling, notchless mode, click/pin policy, and optional trusted distribution remain later work.

## Next optimal step

1. Finish the current exact-candidate M6.1 physical matrix using `docs/testing/MEDIA_BRIDGE_PROBE.md`.
2. Record results in `docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md` without storing media metadata.
3. Run target-Mac probe parent/perl resource and stability measurements.
4. Decide exactly one of `ACCEPT_TRANSPORT`, `NEEDS_TRANSPORT_REDESIGN`, or `REJECT_TRANSPORT`.
5. Only after `ACCEPT_TRANSPORT`, create and execute the production `MediaProvider` / `MediaSessionController` / `SystemMediaBridge` TDD plan, followed by media UI and gesture/haptic/seek slices.
6. After the complete functional media slice passes hardware acceptance, run P1 whole-app resource measurements and the deferred `NSTrackingArea` experiment before deciding whether optimization is necessary.
