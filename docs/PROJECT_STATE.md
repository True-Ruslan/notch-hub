# Project state

Last updated: 2026-08-12
Current published version: `0.1.0` (Personal Release)
Repository visibility: **Public**
Primary physical target: macOS `26.6` / `Mac16,8`
Protected branch: `main`

## Current state

**M6.5 Media-first UI is ACCEPTED AND MERGED, and M6.6 Task 0 transition hardening is ACCEPTED AND MERGED.** M6.5 PR #19 was squash-merged as `5305dbb87d7a2d0d1c7e4bc1eba156cfcafd4e86`; its exact physically tested application source remains `431d9fbaf1ff5ba98f2ceec09732acafe5f65794`, with all `NH-MEDIA-UI-001...011` gates passing.

The bounded collapse-layout edge from issue #20 was then reproduced under TDD, fixed on exact source `0d40391721ae934653a9c75fc981dd683121cf46`, physically accepted on the target Mac, and squash-merged via PR #22 as `f017addd2efc9aed5b60b1556205bdb8eab23e0e`. GREEN CI #776 / run `31567162859` passed 196 Swift tests / 39 suites and all policy/package/security gates; post-merge `main` CI #777 / run `31572634042` passed both required jobs.

The currently published `v0.1.0` release predates M1/P0.1/M6 and remains unchanged. Publishing the accumulated source work later requires a new version because existing tags/releases are immutable.

The active product slice remains M6.6: local media gestures, media-control haptics and draggable seek. The stable acceptance ledger is `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`; the implementation sequence is `docs/superpowers/plans/2026-08-12-media-gestures-haptics-seek.md`.

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
- M6.5 compact + expanded Media-first UI — accepted and merged via PR #19.
- M6.6 Task 0 collapse-layout retarget hardening — accepted and merged via PR #22.

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
- no polling/repeating timer/display link/synthetic input requirement;
- in-flight compact target retargeting when the bounded compact extension changes, with stale completion rejection and no duplicate haptic.

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
- compact owns zero persistent adapter processes;
- expanded owns exactly one expected adapter;
- stale/reversed transition completions cannot start media;
- normal termination leaves no orphan;
- no sensitive permission prompts;
- the immutable P0 baseline remains unchanged; M6.4 feature-size growth has its own reviewed budget.

Accepted direct same-session immutable `v0.1.0` vs M6.4 steady RSS evidence showed no material compact-memory regression. The independent 10-minute RSS/thread growth gate also passed. `PERFORMANCE.md` records the current evidence-driven interpretation of historical `ps rss` measurements.

### M6.5 — Media-first UI

**ACCEPTED AND MERGED — ALL `NH-MEDIA-UI-001...011` PASS.**

Integration:

- PR #19 squash merge `5305dbb87d7a2d0d1c7e4bc1eba156cfcafd4e86`;
- final PR head `db243614d9b50cc857150bef30027d5478f23d11`;
- final PR-head CI #771 — PASS;
- post-merge `main` CI #772 / run `31543163536` — PASS.

Frozen physical candidate:

- source `431d9fbaf1ff5ba98f2ceec09732acafe5f65794`;
- CI #763 / run `31539442148` — both required jobs PASS after retrying one external runner TLS failure on the exact source;
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

### M6.6 Task 0 — collapse-layout retarget hardening

**ACCEPTED AND MERGED — ISSUE #20 COMPLETED.**

TDD/integration evidence:

- RED source `785c48d8cc6831f4196cfa7c78843b826acb9a07`, CI #775 / run `31567022553`;
- exact GREEN/physical source `0d40391721ae934653a9c75fc981dd683121cf46`;
- GREEN CI #776 / run `31567162859` — both required jobs PASS, 196 Swift tests / 39 suites PASS;
- PR #22 squash merge `f017addd2efc9aed5b60b1556205bdb8eab23e0e`;
- post-merge `main` CI #777 / run `31572634042` — both required jobs PASS.

Accepted behavior:

- changed compact extension retargets an in-flight collapse through the existing transition coordinator;
- unchanged effective extension is a no-op;
- cancellation/generation rules keep stale transition completion harmless;
- media disappearance during collapse settles at exact ordinary hardware-notch compact width rather than empty retained wings;
- no snap/re-expand or second haptic;
- settled compact remains zero-adapter and normal Quit leaves no orphan;
- no media transport, entitlement, permission or direct panel-frame authority was widened.

### M6.6 remaining — gestures, haptics and seek

**CONTRACT FROZEN / IMPLEMENTATION NEXT.**

The approved Universal Media design is specialized into stable `NH-MEDIA-GESTURE-001...018` gates. Gesture recognition stays local to NotchHub; horizontal track switching uses a cancellation-safe `idle -> tracking -> armed -> committed | cancelled` state machine, commit-on-release and one haptic per armed transition. Momentum cannot arm/commit, diagonal movement is rejected, and seek is isolated from track/panel gestures.

Because compact retained media is intentionally not live-observed, direct compact swipes must not keep the persistent media runtime alive or blindly trust indefinitely stale capabilities. The frozen M6.6 implementation contract uses bounded current-system one-shot capability validation before compact arming and a bounded typed one-shot previous/next command on release. These calls reuse the existing fixed pinned media process boundary, never start persistent observation, and must be teardown-owned so compact returns to zero process ownership.

Authoritative contract: `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`.
Implementation plan: `docs/superpowers/plans/2026-08-12-media-gestures-haptics-seek.md`.

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

M6.6 gesture work must not add a global scroll observer. Any compact one-shot media operation is a bounded use of the same reviewed process boundary, not a second executable/trust boundary.

## Performance baseline

`performance/baseline-v0.1.0.json` remains immutable historical evidence. The accepted release artifact baseline is:

- executable `220,560 B`;
- app `223,555 B`;
- DMG `73,955 B`.

Intentional shipping feature growth is recorded through separately reviewed, provenance-backed feature budgets. Shared-runner CPU/RSS/thread magnitudes are not treated as target-Mac acceptance; runtime acceptance uses real-hardware evidence and the methodology in `PERFORMANCE.md`.

## Known limitations / technical debt

- media gestures/haptics/draggable seek are not implemented yet;
- compact retained media is intentionally not live-observed while compact because zero-persistent-adapter compact lifecycle is the accepted resource invariant;
- direct compact M6.6 controls therefore require the frozen bounded one-shot capability/command path before they can be accepted;
- current one-shot process calls need explicit lifecycle ownership/cancellation hardening before compact gesture use increases their frequency;
- Apple Music, Spotify and additional-player compatibility remain unverified;
- active-display migration/fullscreen/Spaces/screen-configuration/notchless/click-pin behavior remains later M1 work;
- the global `.mouseMoved` fallback remains pending the P1 local-tracking comparison;
- a more portable absolute memory-footprint metric and repeated-run variance characterization remain P1 research.

## Next optimal step

1. Execute the frozen M6.6 plan under strict TDD, beginning with explicit ownership/cancellation of every in-flight media one-shot process.
2. Implement the pure local `MediaGestureCoordinator` and stable threshold/hysteresis/momentum/capability tests before AppKit wiring.
3. Add local-only scroll delivery and route vertical panel gestures through existing transition authority.
4. Add bounded current-system compact capability validation + typed previous/next one-shot dispatch without persistent observation.
5. Wire expanded gestures/haptics and capability-gated draggable seek; preserve event-driven progress and zero-persistent-adapter compact steady state.
6. Produce an exact CI candidate, pass `NH-MEDIA-GESTURE-001...018` on the target Mac, then merge M6.6.
7. Run P1 whole-app performance/resource review including the deferred window-local pointer-tracking experiment and memory-metric evaluation.
