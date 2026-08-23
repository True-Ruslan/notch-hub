# Project state

Last updated: 2026-08-23
Published version: `0.1.0` Personal Release
Primary physical target: Mac16,8 / macOS 26.6.x
Current physical environment: Mac16,8 / macOS 26.6.2
Branch governance: `main` is intended to be protected; GitHub currently reports it unprotected and issue #42 tracks restoration
Accepted P1 measured runtime: `11dad43364a969f4d5f8c1a92e1281b5b41c8a74`
Accepted P1 measurement/evidence tooling: `fc7562b0799faa4dd80e8c47263354a8bd16bd6a`
Accepted M1 active-display migration runtime: `c7d2bdb9cae744d439d240f22acd14140bacedd3`
Accepted M6.7 live media timeline/Compact runtime: `bd48037baff85d8eb3354fbf3792c5db016ff4a1`
Accepted M6.8 compact live equalizer runtime: `4cbb01d7d5f57f26c40162c8149faf27691c2e06`
M6.9 media marquee text merged runtime: `704bfbcdb1bd81774e8fc2d6a7d9f60a6672d703` (physical acceptance explicitly waived by product owner; see docs/testing/M6_9_MEDIA_MARQUEE_ACCEPTANCE.md)
Accepted M6.10 discoverable normal-quit path runtime: `b911746077092bfffd60d93cd8072c268cb1df94`
Active development: M6.10 merged and accepted; next bounded slice not yet selected

## Product state

NotchHub is a native, local-first macOS productivity hub built around the physical MacBook notch. Security, privacy, performance, energy use and deterministic interaction behavior remain first-class constraints. Runtime work remains event-driven unless measured evidence justifies otherwise.

Published state remains immutable `v0.1.0`. M6.6, its hardware-notch screen-selection correction, the compositor settlement repair and the bounded pointer-monitor correction are accepted/merged source work but remain unreleased.

P1 whole-app target-Mac resource acceptance is complete on exact `Mac16,8 / macOS 26.6.2`. The accepted evidence does not justify speculative runtime optimization.

M1 event-driven active-display/multi-monitor migration is implemented, automated-tested (392 Swift tests, CI #1344 3/3 GREEN) and physically accepted on exact `Mac16,8 / macOS 26.6.2` with an external monitor connected, then merged via PR #56 as `c7d2bdb9cae744d439d240f22acd14140bacedd3`.

M6.7 live media timeline and live Compact display is implemented, automated-tested and physically accepted on exact `Mac16,8 / macOS 26.6.2`, including a fresh P1-style Idle/Hover/Stability resource bundle superseding the prior zero-adapter-compact Idle baseline, then merged via PR #58 as `bd48037baff85d8eb3354fbf3792c5db016ff4a1`. The next product module may now proceed, while issue #42 still tracks restoration of intended `main` branch governance.

## Merged foundations

- M0 Engineering Foundation — accepted/merged.
- R0.1 Personal Release `v0.1.0` — accepted/released.
- P0 Performance Foundation — accepted/merged; immutable baseline preserved.
- P0.1 Public repository readiness — accepted.
- M1 primary interaction/transition foundation — accepted/merged; active-display/fullscreen/Spaces/notchless/broader multi-monitor hardening remains deferred.
- M6.1 transport feasibility — accepted.
- M6.2 normalized media boundary — accepted/merged.
- M6.3 production system transport — accepted/merged.
- M6.4 shipping media composition/lazy lifecycle — accepted/merged.
- M6.5 Media-first UI — accepted/merged.
- Regression/UI Automation Foundation — merged via PR #34 as `bd9566f690d314ed40fd6f3723a319291ceb4a58`.
- M6.6 gestures/haptics/interactive notch/seek/Hover Peek — accepted/merged via PR #33 as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`.
- M6.6 hardware-notch screen-selection correction — physically accepted/tested/merged via PR #40 as `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`.
- P1 target resource measurement foundation — implemented/tested/merged via PR #36 as `5cd9a2a47d87a433155f53b3aa0510000f2fce85`.
- P1 macOS 26.6 patch-family evidence correction — TDD-tested/merged via PR #44 as `99a75dbe0664120a572bd8229d4fe461790ee07b`.
- P1 locale-stable process sampler — TDD-tested/merged via PR #47 as `28965561f81c71ea58a352301fbe08554c644044`.
- P1 manual compositor fallback/evidence contract — tested/merged via PR #49 as accepted tooling `fc7562b0799faa4dd80e8c47263354a8bd16bd6a`.
- P1 compositor endpoint settlement repair — physically accepted/tested/merged via PR #51 as `1f56c3e5da8a46509a3472a52da12a1abfb16a8c`.
- P1 bounded pointer monitoring / rapid-exit repair — TDD-tested, physically accepted and merged via PR #53 as accepted measured runtime `11dad43364a969f4d5f8c1a92e1281b5b41c8a74`.
- P1 whole-app target-Mac resource review — accepted on Mac16,8/macOS 26.6.2; issue #38 closed completed.
- M1 event-driven active-display/multi-monitor migration — implemented/automated-tested/physically accepted/merged via PR #56 as `c7d2bdb9cae744d439d240f22acd14140bacedd3`; issue #55 closed completed.
- M6.7 live media timeline and live Compact display — implemented/automated-tested/physically accepted/merged via PR #58 as `bd48037baff85d8eb3354fbf3792c5db016ff4a1`, superseding the "zero-adapter compact" and "no periodic worker" invariants it deliberately reverses.
- M6.8 compact live equalizer — implemented/automated-tested/physically accepted/merged via PR #60 as `4cbb01d7d5f57f26c40162c8149faf27691c2e06`; competitive-review-driven (boring.notch/NotchNook).

## M6.6 original acceptance and merge provenance

Original full M6.6 physical acceptance remains pinned to exact runtime source:

`8744b9e6239fa28a6d1094f6f4e7669e4ada25b3`

Canonical source evidence:

- CI #1241 / run `32075976405` — 3/3 GREEN;
- 366 Swift tests / 80 suites GREEN;
- external exact-app native XCUI 11/11 GREEN;
- complete target Mac16,8/macOS 26.6 physical matrix PASS;
- Accessibility / Input Monitoring / Automation / Screen Recording NONE;
- post-Quit `pgrep -lf 'mediaremote-adapter\.pl' || true` empty.

Acceptance-record head `c9fbd0605b33a318bb4371ae0f2c928120356adf` passed CI #1243 3/3 GREEN without production changes. PR #33 was squash-merged with expected-head protection as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`; post-merge CI #1244 ultimately passed 3/3 GREEN on that exact source.

## Corrective runtime provenance after M6.6

The later multi-monitor and P1 physical checks found three real runtime defects and each remains separately traceable:

1. **Hardware-notch initial screen selection** — PR #40. Exact physical repair source `46f069e57997eab060c79c3d9e279da944d6e263`; final PR head `b19801be1201a43572f5ea6574d32edfc9174dc5`; squash merge `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`; final head and merge share Git tree `f1884e9727d3d5794fb0122e86d9d0b85c3d9d21`.
2. **Compositor endpoint settlement** — PR #51. RED `7e06d24d0b89f4c413c180882ec9d628384e9bce`; physically accepted GREEN head `329b867595b6ffe127fa3552f51bef8412865f37`; squash merge `1f56c3e5da8a46509a3472a52da12a1abfb16a8c`; accepted head and merge share Git tree `8aebcc6db915b77e30c51b1d4fc45e4c3b895bb1`.
3. **Broad global pointer wakeups plus rapid-exit loss** — PR #53. Early candidates were correctly rejected by target-Mac testing. Final head `bddd0503d972c652752a0e1463f3495685accc83` physically passed rapid exit 30/30, compositor 10/10, reversal recovery, hardware-notch binding and wakeup A/B. Squash merge `11dad43364a969f4d5f8c1a92e1281b5b41c8a74` shares the same Git tree `8f0a7fee0b02599520a5776133f51c1215da7d98` as the accepted head.

The accepted pointer-monitor design keeps system-wide mouse observation absent in ordinary idle and bounds the global escape monitor to an active local/tracking interaction. It retains the monitor while global samples remain inside the current interactive region and tears it down after the actual outside sample is delivered to the existing state machine. No polling, timer, display link, event tap or new permission was introduced.

## Accepted interaction contract

- stable `compact <-> peek <-> expanded` under one transition authority;
- hover dwell exactly 120 ms; Peek exit grace exactly 140 ms;
- generic Peek works without usable media; optional media enrichment begins only after authoritative Peek settlement;
- the shipping media runtime runs for the app's whole lifetime (M6.7 reversal of the prior "settled expanded only" scoping), so Compact reflects live Now Playing state without re-expanding;
- explicit click remains one stable SwiftUI tap path;
- physical DOWN expands; physical UP collapses; exact top-screen/panel `maxY` remains inside the interaction region;
- expanded pointer exit returns non-haptically to exact compact;
- physical LEFT -> `next`, RIGHT -> `previous`, independent of macOS scroll-direction preference;
- horizontal visuals follow the physical finger direction;
- seek, source identity and cursor isolation remain bounded/event-driven;
- bounded Peek cancellation is nonblocking for the UI actor and stale/late transport work fails closed;
- initial panel binding prefers the available hardware-notch display over `NSScreen.main`, with `NSScreen.main` then first-screen fallback when no hardware notch is present;
- current-generation transition settlement reconciles exact physical frame/corner before logical settled presentation is published;
- rapid pointer exit during an interaction is recovered through bounded escape observation without persistent system-wide mouse monitoring;
- normal Quit leaves no owned media adapter process.

## M1 active-display/multi-monitor migration — accepted

PR #56 implements event-driven display-topology migration: observing `NSApplication.didChangeScreenParametersNotification`, resolving `NSScreen.screens` fresh on topology changes while preserving hardware-notch-first selection and the accepted `NSScreen.main`/first-screen fallback, migrating stable Compact/Peek/Expanded endpoints to the newly resolved display through one shared `NotchPanelLayoutModel`, retargeting in-flight programmatic and interactive transitions by generation, and resetting the bounded pointer-escape monitor across migration. No new dependency, permission, entitlement, networking, timer, display link or persistent global input monitoring was added.

Automated verification: exact candidate `dd945dc3ca009f8d9429ad044d50a01a2ea1bb62`; CI #1344 / run `32527603794` 3/3 GREEN; full coverage-instrumented Swift suite passed 392 tests; formatting, acceptance-traceability, source performance policy, security baseline, warnings-as-errors builds, shipping-media preflight, codesign, Hardened Runtime, exact sandbox-only entitlement, DMG verification and the active `performance/m1-active-display-migration-size-budget.json` size gate all passed.

Physical acceptance on exact `Mac16,8 / macOS 26.6.2` with the built-in hardware-notch display plus an external monitor (2560x1440) connected — **11/11 PASS**:

1. Compact connect/disconnect/reconfigure — PASS.
2. Peek connect/disconnect/reconfigure — PASS.
3. Expanded connect/disconnect/reconfigure with media continuity — PASS.
4. Disconnect/reconfigure during programmatic Compact -> Expanded — PASS, no frozen intermediate state.
5. Disconnect/reconfigure during programmatic Expanded -> Compact — PASS.
6. Disconnect/reconfigure during partial interactive expansion — PASS, cancels cleanly to Compact, no unintended haptic/commit.
7. Disconnect/reconfigure during partial interactive collapse — PASS, cancels cleanly to Expanded.
8. No-notch fallback — PASS.
9. Repeated migration cycles (5-10x) — PASS, no jitter, duplicate observers or accumulating lag.
10. Post-migration pointer/hover behavior — PASS, hover scoped to the current hardware-notch screen only, rapid pointer exit correctly collapses Peek.
11. No new macOS permission prompts across the run — PASS.

Post-Quit `pgrep -lf 'mediaremote-adapter\.pl' || true` empty; clean shutdown confirmed. Squash merge `c7d2bdb9cae744d439d240f22acd14140bacedd3`; issue #55 closed.

M1 therefore reached: **implemented -> automated-tested -> physically accepted -> merged -> accepted**. Published release is still `v0.1.0`; this acceptance is not a release claim.

## M6.7 live media timeline and live Compact display — accepted

PR #58 deliberately reverses two prior accepted invariants: the shipping media runtime (`ShippingMediaRuntime`) now starts once at launch and stops once at Quit instead of being scoped to settled `.expanded`, so Compact's artwork/play-pause icon stays live; and one narrowly-scoped, reviewed `Timer.scheduledTimer` (`MediaTimelineTicker`) extrapolates displayed position at ~300ms while settled Peek/Expanded and actively playing, torn down on collapse/pause/session-loss/quit. `scripts/performance_policy.py`'s runtime audit gained a fail-closed, schema-validated reviewed-exception manifest (`performance/reviewed-runtime-timers.json`) scoped to exactly this one `(file, rule)` pair rather than weakening the blanket scan. Along the way, a real pre-existing hazard was found and fixed: `MediaPeekSession`'s one-shot peek probe could clobber an already-live authoritative presentation on hover, now guarded by skipping the probe when live data already exists.

Physical acceptance on exact `Mac16,8 / macOS 26.6.2` — **7/7 PASS**: live-ticking timeline in Peek and Expanded; correct freeze/resume on pause/play; Compact reflecting a track/pause change made outside NotchHub without re-expanding; verified `0.0%` CPU while settled Compact (ticker torn down); clean post-Quit process teardown under a normal quit; and a fresh P1-style Idle/Hover/Stability resource bundle with all direct gates passing against the previously accepted thresholds despite the adapter now running continuously (Idle threadMax `5<=6`; Hover CPU median `0.0%<=8.0%`, threadMax `5<=9`; Stability RSS delta `-11,744<=+8192`, threadMax `7<=9`, thread delta `0<=+2`).

Squash merge `bd48037baff85d8eb3354fbf3792c5db016ff4a1`. Full evidence: `docs/testing/M6_7_LIVE_MEDIA_TIMELINE_AND_COMPACT_ACCEPTANCE.md`. This bundle supersedes the prior "zero-adapter compact" Idle baseline in `docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md`, which remains immutable historical evidence for the source it measured. M6.7 therefore reached: **implemented -> automated-tested -> physically accepted -> merged -> accepted**. Published release is still `v0.1.0`; this acceptance is not a release claim.

## M6.8 compact live equalizer — accepted

Competitive review of `TheBoredTeam/boring.notch` (open source, same `MediaRemoteAdapter`) and NotchNook found one concrete, low-risk UX improvement worth borrowing: both replace a static play/pause glyph in Compact with a small animated equalizer/spectrum. PR #60 replaces `MediaNotchRootView.compactMediaContent`'s static SF Symbol with `MediaCompactEqualizerView`, 3 bars animated via SwiftUI's `PhaseAnimator`, armed only while `playbackState == .playing`, settling to a flat static pose on pause. No timer primitive, no new `performance/reviewed-runtime-timers.json` entry needed.

Physical acceptance on exact `Mac16,8 / macOS 26.6.2` — all items PASS: bars visibly animate out of phase while playing; settle flat on pause and restart on resume; `0.0%` CPU while settled Compact with media playing; no interaction jank; clean post-Quit teardown. Acceptance also found and fixed a real bug: the first implementation used `.animation(...repeatForever...)`, which froze after the horizontal next/previous swipe gesture (an ancestor `withAnimation` transaction interrupting the implicit repeating loop) — fixed by switching to `PhaseAnimator`, which owns its own animation timeline and is immune to that class of interference.

Squash merge `4cbb01d7d5f57f26c40162c8149faf27691c2e06`. Full evidence: `docs/testing/M6_8_COMPACT_LIVE_EQUALIZER_ACCEPTANCE.md`. M6.8 therefore reached: **implemented -> automated-tested -> physically accepted -> merged -> accepted**. Published release is still `v0.1.0`; this acceptance is not a release claim.

## Security and resource invariants

- App Sandbox-only entitlement and Hardened Runtime remain mandatory.
- No Accessibility, Input Monitoring, Automation, Screen Recording, networking, telemetry, history persistence or arbitrary command authority is added.
- Universal Media retains the reviewed fixed `/usr/bin/perl` + pinned adapter/framework boundary.
- The shipping media adapter now runs for the app's whole lifetime (M6.7); normal Quit still leaves no owned adapter process.
- Gesture/Peek/transition/screen-selection/pointer hot paths remain free of polling, display link, event tap, per-event subprocess creation or production logging. Exactly one bounded-lifecycle repeating timer exists in the whole codebase (`MediaTimelineTicker`), armed only while settled Peek/Expanded and actively playing, and is the sole entry in `performance/reviewed-runtime-timers.json`.
- Global `.mouseMoved` observation is no longer persistently armed in idle; the final bounded escape monitor is active only during an actual NotchHub interaction and tears down after outside escape delivery.
- UI fixtures and diagnostics remain compile-time test-only.

## Performance state — P1 accepted

`performance/baseline-v0.1.0.json` and all historical feature budgets remain immutable provenance records. The active cumulative size envelope remains `performance/m6-6-hardware-notch-screen-selection-size-budget.json`; historical budgets remain evidence rather than rewritten baselines.

Shared-runner CPU/RSS values remain compatibility evidence only. Canonical runtime resource acceptance belongs to exact `Mac16,8` hardware in the macOS `26.6` patch family, with the exact observed patch version preserved consistently across a bundle.

The final accepted P1 bundle uses:

- runtime `11dad43364a969f4d5f8c1a92e1281b5b41c8a74`;
- tooling `fc7562b0799faa4dd80e8c47263354a8bd16bd6a`;
- target `Mac16,8 / macOS 26.6.2`;
- exact coherent Idle/Hover/Stability/manual provenance with `reviewRequired=false`.

Final reviewed evidence:

- **Idle** — CPU median/max `0.0/0.0%`; RSS median/max `58,432/58,496 KiB`; threads median/max `3/6`. Idle direct thread gate `<=6` PASS.
- **Hover** — CPU median/max `6.8/32.3%`; RSS median/max `75,936/76,784 KiB`; threads median/max `6/6`. CPU median steady-state target `<=8.0%` PASS; thread gate `<=9` PASS. The one-second CPU max remains diagnostic rather than a standalone portable gate.
- **Stability** — CPU median/max `0.0/0.0%`; RSS start/end `58,816 -> 54,848 KiB`, delta `-3,968 KiB`; thread start/end `3 -> 3`, thread max `5`, delta `0`. RSS growth, thread max and thread-delta gates PASS.
- **Idle Wake Ups** — Activity Monitor, 60 s, `0.0/s`; explicitly reviewed with no anomaly.
- **Energy** — Activity Monitor Energy fallback, 60 s, `no-anomaly-observed`; observed Energy Impact `0.0`, App Nap `No`, Preventing Sleep `No`. The displayed 12-hour value `0.29` is retained only as historical diagnostic context, not a 60-second threshold.
- **Compositor** — `manual-visual-compositor`, exactly 10 cycles, `no-anomaly-observed`; reversal recovery PASS; freeze/stuck panel not observed; frame/corner/flicker anomalies none.

The normalized closed-schema bundle validated successfully and all direct gates passed. Earlier 26.6.1, pre-settlement and pre-pointer-fix measurements remain immutable diagnostic history and are not mixed into the accepted bundle.

P1 therefore reached:

**implemented -> tested -> physically accepted -> merged runtime measured -> accepted**.

Published release is still `v0.1.0`; P1 acceptance is not a release claim.

## M6.9 media marquee text — merged, physical acceptance explicitly waived

PR #62 added `MediaMarqueeCalculator` (pure overflow/timing math, `Sources/NotchHubMediaCore/`) and `MediaMarqueeText` (SwiftUI view, `Sources/NotchHubApp/`), wired into all 5 title/artist/album sites in Peek/Expanded (`MediaNotchRootView.swift`); Compact is unaffected. Overflowing text scrolls in a continuous conveyor loop via SwiftUI's `PhaseAnimator` (same mechanism as M6.8's equalizer, no timer primitive); short text renders exactly as before; `accessibilityReduceMotion` disables scrolling unconditionally. Design/invariants: `docs/superpowers/specs/2026-08-22-media-marquee-text-design.md`.

Canonical CI was GREEN 3/3 before merge, including the release size gate against real evidence in `performance/m6-9-media-marquee-text-size-budget.json`. Squash-merged as `704bfbcdb1bd81774e8fc2d6a7d9f60a6672d703`. Unlike every prior milestone, the product owner was directly asked whether to physically test first, merge with the gate waived, or leave the PR open, and explicitly chose to waive physical acceptance and merge immediately. This is recorded honestly (not as a passed check) in `docs/testing/M6_9_MEDIA_MARQUEE_ACCEPTANCE.md`, including the specific residual risk: this exact class of custom `PhaseAnimator`/`GeometryReader` SwiftUI code has a direct precedent (M6.8) for hiding bugs only physical testing caught.

## M6.10 discoverable normal-quit path — accepted

PR #64 adds a minimal `NSStatusItem` to `AppDelegate` (stock SF Symbol icon, no custom asset) with a static menu: a disabled "NotchHub" title and a "Quit NotchHub" action wired to `#selector(NSApplication.terminate(_:))`. This fixes a real defect physical acceptance found during M6.7: Force Quit was the only way to quit, and its SIGKILL bypasses `applicationWillTerminate`'s existing, already-tested media-runtime cleanup, leaving an orphaned `mediaremote-adapter.pl` process. No new entitlement, permission, or timer — `Resources/NotchHub.entitlements` unchanged, activation policy stays `.accessory`. Design/invariants: `docs/superpowers/specs/2026-08-23-discoverable-quit-menu-design.md`.

Canonical CI GREEN 3/3 on first try (the stale-active-budget-reference issue found during M6.9 was fixed proactively this time). Squash-merged as `b911746077092bfffd60d93cd8072c268cb1df94`. Physical acceptance performed by the product owner on their own Mac — all 7 checklist items PASS, including confirming `pgrep -lf 'mediaremote-adapter\.pl'` is empty after quitting via the menu. Full evidence: `docs/testing/M6_10_DISCOVERABLE_QUIT_ACCEPTANCE.md`. M6.10 therefore reached: **implemented -> automated-tested -> physically accepted -> merged -> accepted**. Published release is still `v0.1.0`; this acceptance is not a release claim.

## Next optimal step

1. Select and specify the next bounded product-hardening slice with a written spec + RED tests before implementation — candidates: album-art color tinting or `matchedGeometryEffect` cross-state artwork morphing (both now unblocked by completed P1 performance evidence), or remaining fullscreen/Spaces/notchless hardening — before starting Settings (M7), per current product priority.
2. Keep issue #42 visible: restore intended `main` branch governance when repository capabilities permit; do not treat an unprotected default branch as the desired steady state.
3. Prefer genuine target-Mac physical acceptance for shipping changes whose behavior CI cannot honestly prove; when the product owner explicitly waives it, record that decision and the residual risk honestly rather than fabricating a passed check.
4. Do not introduce speculative CPU/RSS/wakeup optimizations unless new evidence establishes a material regression.
5. Keep `v0.1.0` immutable until an explicit Personal Release decision is made.

See:

- `docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md`;
- `docs/superpowers/plans/2026-08-18-p1-target-mac-resource-audit.md`;
- `docs/superpowers/specs/2026-08-21-active-display-multi-monitor-migration-design.md`;
- `docs/superpowers/specs/2026-08-22-live-media-timeline-and-compact-design.md`;
- `docs/superpowers/specs/2026-08-22-compact-live-equalizer-design.md`;
- `docs/testing/M6_7_LIVE_MEDIA_TIMELINE_AND_COMPACT_ACCEPTANCE.md`;
- `docs/testing/M6_8_COMPACT_LIVE_EQUALIZER_ACCEPTANCE.md`;
- closed issue #38 for the complete P1 evidence/acceptance trail;
- closed issue #55 for the M1 display-migration acceptance trail;
- issue #42 for repository branch-protection restoration.
