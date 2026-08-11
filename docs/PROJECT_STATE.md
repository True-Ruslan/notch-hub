# Project state

Last updated: 2026-08-12
Current published version: `0.1.0` (Personal Release)
Repository visibility: **Public**
Primary physical target: macOS `26.6` / `Mac16,8`
Protected branch: `main`

## Current state

**M6.5 Media-first UI is ACCEPTED on the primary target.** The exact physically tested application source is `431d9fbaf1ff5ba98f2ceec09732acafe5f65794` from PR #19. All `NH-MEDIA-UI-001...011` acceptance gates pass. Subsequent PR #19 commits are documentation-only acceptance/integration records and require fresh exact-head CI, but no repeat physical run.

PR #19 remains the integration vehicle until final documentation review/CI and squash merge. The currently published `v0.1.0` release predates M1/P0.1/M6 and remains unchanged; publishing the accumulated source work later requires a new version.

## Accepted foundations

- M0 Engineering Foundation — accepted and merged.
- R0.1 Personal Release `v0.1.0` — accepted and published.
- P0 Performance Foundation — accepted and merged; immutable baseline preserved.
- P0.1 Public Repository Readiness — accepted.
- M1 interaction/transition slice — accepted and merged.
- Universal Media product/security design — approved.
- M6.1 system Now Playing transport feasibility — accepted (`ACCEPT_TRANSPORT`).
- M6.2 normalized media state/controller/bridge boundary — accepted and merged.
- M6.3 concrete production system-media transport — accepted and merged.
- M6.4 shipping media composition/lazy lifecycle — accepted and merged.
- M6.5 compact + expanded Media-first UI — **accepted on target Mac; PR #19 merge pending**.

## Product

NotchHub is a personal native, local-first macOS productivity hub around the physical MacBook notch. Planned product areas include Shelf, Snippets, Calendar, Translator, Universal Media, and later product-shell/settings capabilities.

Universal Media follows the system Now Playing source selected by macOS rather than applying a private player-priority list. Yandex Music and Yandex Browser/Chromium are physically verified. Apple Music, Spotify and additional independent-player compatibility remain explicitly unverified rather than assumed.

## Accepted notch interaction baseline

Current accepted interaction architecture includes:

- public `NSScreen` notch geometry;
- AppKit-owned `NSPanel` sizing/chrome;
- exact hardware-notch ordinary compact geometry;
- cancellable `120 ms` hover dwell;
- inclusive 4 pt left/right/bottom and 0 pt top activation protection;
- one `.levelChange` haptic for an eligible deliberate expansion;
- `NotchPanelTransitionCoordinator` as sole compact/expanded transition authority;
- `0.20 s` AppKit/Core Animation transition;
- Reduce Motion -> zero-duration exact endpoint;
- one local + one narrow global `.mouseMoved` fallback with explicit lifecycle ownership;
- no per-event Swift concurrency allocation in the pointer hot path;
- no polling/repeating timer/display link/synthetic input requirement.

Remaining display/Space hardening stays deferred: active-display migration, fullscreen/Spaces, screen-configuration changes, notchless mode and click/pin policy.

## Universal Media state

### M6.1 — transport feasibility

**ACCEPTED.** The pinned external compatibility mechanism works under App Sandbox + Hardened Runtime with event-driven system Now Playing observation, authoritative capabilities, real typed commands, no sensitive permission prompts and clean teardown.

### M6.2 — production media boundary

**ACCEPTED AND MERGED.** `NotchHubMediaCore` owns normalized player-agnostic state, immutable snapshots, ordering, provider/controller/bridge lifecycle, capability gating and typed commands.

### M6.3 — concrete production transport

**ACCEPTED AND MERGED.** Production transport uses the exact reviewed `/usr/bin/perl` process boundary with pinned adapter/framework resources, bounded I/O/process lifecycle, strict capability schema and fixed typed commands.

Accepted target integration includes Yandex Music and Yandex Browser observation plus actual toggle/previous/next/seek behavior. No Accessibility/Input Monitoring/Automation/Screen Recording authority is required.

### M6.4 — shipping composition

**ACCEPTED AND MERGED via PR #17 (`4ba603e1c3564d6cdf58169a7936f1954dee2ffd`).**

Key accepted invariants:

- `NotchHubApp` links `NotchHubMediaCore` and ships exact pinned media resources;
- App Sandbox-only entitlement and Hardened Runtime remain mandatory;
- media runtime starts only after matching settled `.expanded`;
- media runtime stops/releases after matching settled `.compact`;
- compact owns zero adapter processes;
- expanded owns exactly one expected adapter;
- stale/reversed transition completions cannot start media;
- normal termination leaves no orphan;
- no sensitive permission prompts;
- the immutable P0 baseline remains unchanged; M6.4 feature-size growth has its own reviewed budget.

Accepted direct same-session immutable `v0.1.0` vs M6.4 steady RSS evidence showed no material compact-memory regression. The independent 10-minute RSS/thread growth gate also passed. `PERFORMANCE.md` records the current evidence-driven interpretation of historical `ps rss` measurements.

### M6.5 — Media-first UI

**ACCEPTED ON TARGET MAC — ALL `NH-MEDIA-UI-001...011` PASS.**

Frozen physical candidate:

- source `431d9fbaf1ff5ba98f2ceec09732acafe5f65794`;
- CI #763 / run `31539442148` — both required jobs PASS after retrying one external runner TLS failure on the same source;
- 194 Swift tests — PASS;
- shipping artifact ID `9120231721`;
- Actions digest `sha256:0d18a0c9ce5305b90808f0937531211094b85947ce96b2afd0a2c4020e4e7007`;
- contained DMG SHA-256 `3993330bf57ac86ead949215ba5370a0a33ec6b8f6a17f1d65baa30c41f5f6ad`;
- executable/app/DMG sizes `397,408 / 699,614 / 461,740 B`.

Accepted product behavior:

- cold/no-media compact stays exact-notch and owns zero adapter;
- active expanded session renders Media-first artwork/metadata/source;
- previous/play-pause/next UI is capability-driven and uses the accepted typed transport;
- trustworthy progress renders without periodic track polling;
- missing metadata/capability is never fabricated;
- media disappearance while expanded switches to Home without collapsing;
- normal collapse retains the last authoritative media visual while stopping/releasing runtime;
- retained compact uses symmetric 36 pt wings around the unchanged physical notch, artwork left and playback status right;
- fresh re-expansion replaces retained context with new authoritative events;
- Yandex Music and Yandex Browser physical scenarios pass;
- no Accessibility/Input Monitoring/Automation/Screen Recording prompts occur;
- compact and normal Quit leave no media adapter orphan.

M6.5 size growth is tracked by `performance/m6-5-media-first-ui-size-budget.json`. The immutable P0 baseline and M6.4 budget were not rewritten, and no runtime CPU/RSS/thread budget was widened.

Authoritative evidence: `docs/testing/MEDIA_UI_ACCEPTANCE.md`.

## Security baseline

`SECURITY.md` is authoritative. Current production-source invariants include:

- local-first/no telemetry;
- App Sandbox-only application entitlement;
- Hardened Runtime without dangerous exceptions;
- no direct application networking;
- no bundled secrets;
- no broad global input capture beyond the existing `.mouseMoved` fallback;
- exactly one reviewed media subprocess boundary fixed to `/usr/bin/perl`;
- pinned adapter/framework provenance and closed typed command surface;
- no direct private-framework loading inside the NotchHub process;
- no media listening-history persistence/logging;
- no sensitive permission expansion for Universal Media.

## Performance baseline

`performance/baseline-v0.1.0.json` remains immutable historical evidence. The accepted release artifact baseline is:

- executable `220,560 B`;
- app `223,555 B`;
- DMG `73,955 B`.

Intentional shipping feature growth is recorded through separately reviewed, provenance-backed feature budgets. Shared-runner CPU/RSS/thread magnitudes are not treated as target-Mac acceptance; runtime acceptance uses real-hardware evidence and the methodology in `PERFORMANCE.md`.

## Known limitations / technical debt

- media gestures/haptics/draggable seek are not implemented yet;
- compact retained media is intentionally not live-observed while compact because zero-adapter compact lifecycle is the accepted resource invariant;
- Apple Music, Spotify and additional-player compatibility remain unverified;
- active-display migration/fullscreen/Spaces/screen-configuration/notchless/click-pin behavior remains later M1 work;
- the global `.mouseMoved` fallback remains pending the P1 local-tracking comparison;
- a more portable absolute memory-footprint metric and repeated-run variance characterization remain P1 research.

## Next optimal step

After PR #19 integration:

1. Define the next Universal Media slice for **local media gestures, media-control haptics and draggable seek** from the already approved Universal Media design.
2. Establish stable `NH-MEDIA-GESTURE-*` acceptance IDs and a TDD implementation plan before production changes.
3. Keep gesture recognition local to the NotchHub window/panel; do not add a global scroll monitor or synthetic media keys.
4. Preserve the M6.4/M6.5 zero-adapter compact lifecycle and event-driven progress policy.
5. Physically accept the gesture/haptic/seek slice on the target Mac.
6. Then run P1 whole-app performance/resource review, including the deferred window-local pointer-tracking experiment and memory-metric evaluation.