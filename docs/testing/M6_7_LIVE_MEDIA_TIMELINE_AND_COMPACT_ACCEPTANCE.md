# M6.7 — live media timeline and live Compact display — Acceptance Evidence

Status: **ACCEPTED — 2026-08-22**

Authoritative design/invariants: `docs/superpowers/specs/2026-08-22-live-media-timeline-and-compact-design.md`.
Accepted merged source: PR #58, squash merge `bd48037baff85d8eb3354fbf3792c5db016ff4a1`. Physical acceptance executed on exact head `3cee40c9650d50254f25e633a3e0e5163124df07` on `Mac16,8 / macOS 26.6.2`.

This slice explicitly reverses two prior accepted invariants ("expanded-only runtime / zero-adapter-in-compact" and the "no periodic worker" static-progress claim) and therefore explicitly supersedes the acceptance ids that asserted them. Those older ids remain valid historical evidence for the exact source they were measured against; the supersession relationships are recorded, not deleted or rewritten, in `Tests/Acceptance/supersessions.json`.

## Acceptance ledger

### `NH-MEDIA-LIVE-001` — shipping media runtime runs for the app's whole lifetime; Compact reflects live state

Status: **PASS**

`ShippingMediaRuntime.start()` runs once at launch and `stop()` once at Quit, no longer gated by settled `.expanded`. Compact's existing artwork/play-pause icon is reactively bound to the now-continuously-live presentation model, so it reflects a track change, pause or play/pause toggle performed outside NotchHub without requiring re-expansion.

Physical acceptance on `Mac16,8 / macOS 26.6.2`: collapsing to Compact then changing track/pausing directly in the source player (not through NotchHub) updated Compact's artwork/play-pause icon without re-expanding — PASS. Post-Quit `pgrep -lf 'mediaremote-adapter\.pl'` empty under normal quit — PASS. Fresh P1-style Idle/Hover/Stability resource bundle collected and reviewed (see below) — all direct gates PASS despite the adapter now running for the app's whole lifetime.

### `NH-MEDIA-LIVE-002` — bounded-lifecycle timeline ticker

Status: **PASS**

One narrowly-scoped, reviewed `Timer.scheduledTimer` (`MediaTimelineTicker`) extrapolates displayed position between authoritative events at ~300ms, armed only while settled Peek/Expanded and actively playing, torn down on collapse/pause/session-loss/quit. `scripts/performance_policy.py`'s runtime audit gained a fail-closed, schema-validated reviewed-exception manifest (`performance/reviewed-runtime-timers.json`) scoped to exactly this `(file, rule)` pair.

Physical acceptance on `Mac16,8 / macOS 26.6.2`: timeline visibly ticked in real time in both Peek and Expanded while playing; froze exactly on pause with no drift and resumed correctly — PASS. Collapsing to Compact stopped the ticker: `ps` CPU sampling across 5 samples while settled Compact showed `0.0%` CPU — PASS.

## Fresh P1-style resource bundle

Required because Idle no longer has a zero-adapter baseline once the runtime is always active. Collected on exact head `3cee40c9650d50254f25e633a3e0e5163124df07`, target `Mac16,8 / macOS 26.6.2`, using the existing `scripts/perf-baseline.py` harness (10s warmup + 60s @1s for Idle/Hover, 10s warmup + 600s @5s for Stability).

| Scenario | CPU median/max | RSS median/max (KiB) | Thread median/max |
|---|---|---|---|
| Idle | 0.0% / 2.4% | 73,648 / 73,776 | 4 / 5 |
| Hover | 0.0% / 18.0% | 71,832 / 72,128 | 3 / 5 |
| Stability | 0.0% / 0.0% | 64,160 / 71,648 | 3 / 7 |

Stability RSS: `71,648 -> 59,904` KiB (delta `-11,744`, a decrease). Stability threads: `3 -> 3` (delta `0`).

Direct gate review against the previously accepted P1 thresholds: Idle threadMax `<=6` -> `5` PASS. Hover CPU median `<=8.0%` -> `0.0%` PASS; Hover threadMax `<=9` -> `5` PASS. Stability RSS delta `<=+8192` -> `-11,744` PASS; Stability threadMax `<=9` -> `7` PASS; Stability thread end-minus-start `<=+2` -> `0` PASS. No unexplained sustained resource accumulation was observed. This bundle supersedes the prior "zero-adapter compact" Idle baseline recorded in `docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md`, which remains immutable historical evidence for the source it measured.

## Follow-up (non-blocking)

Physical acceptance also confirmed Force Quit (Activity Monitor) leaves an orphaned `mediaremote-adapter.pl` process, because SIGKILL bypasses `applicationWillTerminate` for any app with a child process — this is not a regression introduced by this change (a normal quit via the Apple Event equivalent of Cmd+Q tore down cleanly on a fresh launch). It surfaced a separate, pre-existing gap: NotchHub has no user-discoverable normal-quit path (no Dock icon, no Quit menu item, Cmd+Q is a no-op for this accessory-policy app). Tracked as a follow-up, not a blocker for this PR.

## Automated coverage

- `NotchHubMediaCoreTests.MediaTimelineTickerTests` — bounded arm/disarm conditions, extrapolation + duration clamping, re-anchoring without drift, optimistic seek re-anchoring (all fully clock/timer-injected, no real `Timer`/run loop).
- `NotchHubCoreTests.MediaPeekSecurityPerformancePolicyTests.mediaRuntimeStartsOnceAtLaunchAndStopsOnlyAtQuit` — asserts the new always-on lifecycle wiring in `AppDelegate.swift`.
- `NotchHubCoreTests.MediaPeekSecurityPerformancePolicyTests.timelineTickerIsTheOnlyReviewedBoundedTimerAndNeverArmsInCompact` — asserts the ticker's bounded-lifecycle source markers and that `MediaNotchRootView.swift` itself remains timer-free.
- `NotchHubCoreTests.MediaSeekAppCompositionPolicyTests.appWiresSeekAndOptimisticallyReanchorsTheAlwaysActiveRuntimeTimeline` — asserts the optimistic-seek re-anchor wiring.
- `scripts.ShippingMediaIdleLifecycleTests.test_shipping_media_runtime_runs_for_the_apps_whole_lifetime` — Python source-policy assertion of the launch/terminate lifecycle.
- `scripts.test_performance_policy` (`RuntimePerformancePolicyTests`) — the reviewed-exception manifest is fail-closed and schema-validated, and suppresses exactly its own `(file, rule)` pair.

## Physical acceptance checklist

Full checklist definition: `docs/superpowers/specs/2026-08-22-live-media-timeline-and-compact-design.md`. All items PASS; results recorded above and in the PR #58 acceptance comment.
