# Project state

Last updated: 2026-08-09
Current version: `0.1.0` (Personal Release published and accepted)
Repository visibility: **Public**
Primary physical target: macOS `26.6`
Protected branch target: `main`
P0 merge commit: `a056aa74bad5d8e193eb4c76a76e6c910344bd09`
Public-readiness hardening merge: `23500e099a0f8b2738f1157c6ae3be71c89df6e1`
Current product state: M1 interaction/transition slice **ACCEPTED AND MERGED**; M6.1 Universal Media transport probe **ACCEPTED (`ACCEPT_TRANSPORT`)**; next active slice is the production Universal Media state/controller/bridge boundary
Accepted interaction/transition slice: PR #10 `M1 delayed hover and haptic interaction core` — **ACCEPTED AND SQUASH-MERGED** as `094b494bd597643244e733baf5787a13b61fb4eb`
Approved Universal Media design: `docs/superpowers/specs/2026-08-09-universal-media-gestures-haptics-design.md`
Universal Media probe plan: `docs/superpowers/plans/2026-08-09-universal-media-bridge-probe.md`
Current probe PR: #13 `M6.1 Universal Media bridge compatibility probe` — **PHYSICAL/RESOURCE ACCEPTANCE COMPLETE; `ACCEPT_TRANSPORT` RECORDED**
Accepted exact physical candidate: source `cda05bb4ff367d2c4a5d9d438c3f555f3788d186`, CI #443 / run `31304052700`, artifact ID `9035397233`, digest `sha256:5cd10a0c6e9b61d8f060ca29ab8a84a7b1a1ba2408f2769b88ea86bf908be5c0`

## Product

NotchHub is a personal, native, local-first macOS productivity hub built around the MacBook notch. Planned modules are Shelf, Snippets, Calendar, Translator, and universal media controls that follow the system Now Playing source selected by macOS rather than targeting one music application.

The accepted M6.1 transport has been physically verified with Yandex Music and Yandex Browser on the actual Personal Release target. Apple Music, Spotify, and another independent player remain future compatibility checks rather than claims of already verified support.

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
Initial dwell/haptic plan: `docs/superpowers/plans/2026-08-08-m1-pointer-dwell-haptics.md`.
Transition/animation hardening plan: `docs/superpowers/plans/2026-08-08-m1-transition-animation-hardening.md`.

Accepted behavior and architecture:

- `NotchInteractionCoordinator` owns pointer-intent timing/cancellation, not geometry, rendering, animation, or haptic output;
- one cancellable one-shot compact -> expanded dwell, accepted at `120 ms`;
- compact activation uses **4 pt inward depth on left, right and bottom only**, with **no top inset**;
- exact boundaries are inclusive, including the physical top/maxY edge, using explicit directional comparisons rather than `CGRect.contains`;
- quick transit cancels before dwell and produces no haptic; re-entry requires a fresh full dwell;
- duplicate pointer events keep one pending activation and one semantic intent;
- setup/current-pointer synchronization is non-activating;
- generation validation makes cancelled/stale callbacks harmless;
- `NotchPanelTransitionCoordinator` is the single authority for compact/expanding/expanded/collapsing presentation state;
- expanded content is retained until matching collapse completion;
- animation reversal cannot be won by stale completion;
- public AppKit `.levelChange` haptic fires exactly once for successful deliberate user expansion and never for programmatic/cancelled/stale/collapse paths;
- window animation uses `NSAnimationContext` + `panel.animator().setFrame(...)` and `CABasicAnimation` for corner radius;
- accepted standard transition duration is `0.20 s`, with Reduce Motion resolving to immediate endpoint application;
- cancellation freezes presentation-layer corner radius before removing animation to prevent jumps;
- no display link, frame timer, polling loop, custom interpolation loop, or private animation API;
- black hardware-notch compact surface and continuous `12 pt` compact / `22 pt` expanded radii remain accepted;
- one local and one narrow global `.mouseMoved` monitor are explicitly owned/idempotently removed;
- event-monitor callbacks use synchronous main-actor delivery rather than allocating a Task per mouse event;
- App Sandbox + Hardened Runtime boundary remains unchanged.

Broad M1 target-hardware acceptance used CI #319 source `f6de06f5d045fc9375b3b31b0a7feb97a13cebe4`; all interaction/visual/animation/reversal/haptic/startup/Reduce Motion scenarios passed except a requested exact-top-edge refinement. The corrective exact-boundary TDD culminated in source `6d4c13739216503ec97fe3e71eada0fc9b32f298`, CI #332 / run `31260116337`, artifact ID `9022551570`, which passed the exact top-edge and cross-display transit checks. Final pre-merge head `7e04acd46414f39cf3d910b8c310deb22f9b9b9e` passed CI #338 and PR #10 was squash-merged.

The narrow global `.mouseMoved` fallback remains accepted. Its `NSTrackingArea` / window-local experiment is deferred to P1 after the functional media slice so resource value is measured against the real application.

## M6.1 — Universal Media Bridge compatibility/security probe

Status: **ACCEPTED — `ACCEPT_TRANSPORT`**.

PR: #13 `M6.1 Universal Media bridge compatibility probe`.
Physical procedure: `docs/testing/MEDIA_BRIDGE_PROBE.md`.
Evidence ledger: `docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md`.

### Accepted development-only boundary

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

### Deterministic candidate and CI

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

### Accepted target-Mac evidence

On `Mac16,8`, macOS 26.6 build `25G72`:

- sandbox-only entitlement verified exactly;
- local Hardened Runtime verified (`adhoc,runtime`);
- no Accessibility/Input Monitoring/Automation/Screen Recording prompt appeared;
- no active media session returns `unknown/unknown/unknown` capabilities;
- Yandex Music returns authoritative `supported/supported/supported` and publishes session/artwork/playing state;
- Yandex Browser publishes an independently observed system Now Playing session and authoritative capabilities;
- actual Yandex play/pause, previous, next, and seek-to-42s behavior passed;
- source switching and source disappearance were observed through the continuous event stream;
- clean teardown/no orphan behavior passed repeatedly;
- deterministic failure tests prove nonzero-exit fail-closed behavior, protocol failure termination, bounded timeout handling, and no restart loop;
- `NH-MEDIA-BRIDGE-004` Apple Music, `005` Spotify, and `007` another independent player are **NOT TESTED / DEFERRED**, because those sources are not available/used on the Personal Release target and are not required to prove the transport architecture.

Accepted resource evidence:

- 60-second parent: CPU median/max `0.0% / 0.0%`, RSS `5,680 KiB`, threads `2`;
- 60-second adapter: CPU median/max `0.0% / 0.0%`, RSS `20,288 KiB`, threads `2`;
- 10-minute parent: CPU median/max `0.0% / 0.0%`, RSS median/max `5,664 / 7,328 KiB`, RSS drift `-128 KiB`, threads start/end/max `2 / 2 / 2`;
- 10-minute adapter: CPU median/max `0.0% / 0.1%`, RSS median/max `20,368 / 24,480 KiB`, RSS drift `-32 KiB`, threads start/end/max `2 / 2 / 6`;
- combined RSS drift `-160 KiB`; ending combined thread count unchanged at `4`;
- 640-second observer completed with `cleanTeardown=true`, no orphan process, and shell verification `PROBE_TEARDOWN=PASS` / `PERL_TEARDOWN=PASS`.

### Decision

`ACCEPT_TRANSPORT` is recorded because the system-wide transport works under the required sandbox/Hardened Runtime boundary, provides authoritative capability information, functions across the two real system Now Playing publishers available on the target Mac, fails closed without restart loops, and shows no sustained CPU/RSS/thread accumulation.

This acceptance authorizes the production architecture plan. It does not authorize copying the development probe wholesale into shipping code or claiming compatibility with deferred sources that were not physically tested.

## Universal Media production design — APPROVED, M6.1 GATE CLEARED

The approved target is system-wide macOS Now Playing, not an application-specific integration. The production architecture remains:

- `SystemMediaBridge` as the only private compatibility boundary;
- player-agnostic `MediaProvider`;
- immutable `MediaSessionSnapshot`;
- `@MainActor MediaSessionController`;
- capabilities drive UI; unsupported/unknown commands are never fabricated;
- failure is fail-closed for media only;
- metadata/artwork are untrusted inputs and listening history is not persisted;
- event-driven updates only.

The M6.1 transport gate is now cleared. The next implementation work is to create the production TDD plan and build the narrow production media state/controller/bridge boundary while preserving the accepted security, lifecycle, privacy, and resource constraints.

## Security baseline

`SECURITY.md` remains authoritative. M1 shipping runtime adds no telemetry, analytics, networking, subprocess/shell, dynamic loading, private API, privileged helper, Accessibility/Input Monitoring permission, synthetic input, or broad input capture. Universal Media private MediaRemote compatibility remains constrained to the accepted isolated design boundary; production integration must be separately reviewed and tested before it enters shipping `Sources/**`.

Any production bridge regression is rejected/redesigned rather than repaired by weakening Sandbox, Hardened Runtime, library validation, OS security, or adding broad permissions.

## Known limitations / technical debt

- target-Mac runtime ceilings still derive from one canonical whole-app run per scenario with conservative headroom;
- GitHub-hosted runner resource values are not representative of the target Mac;
- the narrow global `.mouseMoved` fallback remains pending the P1 `NSTrackingArea` / window-local comparison;
- Apple Music, Spotify, and arbitrary independent-player compatibility are not physically verified yet and must not be claimed as accepted support;
- production Universal Media code has not yet been implemented; only the transport mechanism and boundary feasibility are accepted;
- active-display migration, Spaces/fullscreen, screen-configuration handling, notchless mode, click/pin policy, and optional trusted distribution remain later work.

## Next optimal step

1. Write the production Universal Media TDD implementation plan for `MediaProvider`, immutable `MediaSessionSnapshot`, `@MainActor MediaSessionController`, and isolated `SystemMediaBridge` using the accepted M6.1 constraints.
2. Implement deterministic fake-provider/state/controller tests first, then the smallest production bridge boundary without broadening permissions, polling, logging, or dependency surface.
3. Add compact + expanded media-first UI only after the production state/controller boundary is reliable.
4. Implement local-window gesture/haptic/seek state machines under TDD.
5. Run target-Mac media acceptance on the sources actually available, recording deferred compatibility honestly.
6. After the complete functional media slice passes hardware acceptance, run P1 whole-app resource measurements and the deferred `NSTrackingArea` experiment before deciding whether optimization is necessary.
