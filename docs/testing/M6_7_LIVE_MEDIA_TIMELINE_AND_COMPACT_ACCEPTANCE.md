# M6.7 — live media timeline and live Compact display — Acceptance Evidence

Status: **PENDING — AUTOMATED EVIDENCE COMPLETE, PHYSICAL ACCEPTANCE REQUIRED**

Authoritative design/invariants: `docs/superpowers/specs/2026-08-22-live-media-timeline-and-compact-design.md`.

This slice explicitly reverses two prior accepted invariants ("expanded-only runtime / zero-adapter-in-compact" and the "no periodic worker" static-progress claim) and therefore explicitly supersedes the acceptance ids that asserted them. Those older ids remain valid historical evidence for the exact source they were measured against; the supersession relationships are recorded, not deleted or rewritten, in `Tests/Acceptance/supersessions.json`.

## Acceptance ledger

### `NH-MEDIA-LIVE-001` — shipping media runtime runs for the app's whole lifetime; Compact reflects live state

Status: **PENDING**

`ShippingMediaRuntime.start()` runs once at launch and `stop()` once at Quit, no longer gated by settled `.expanded`. Compact's existing artwork/play-pause icon is reactively bound to the now-continuously-live presentation model, so it reflects a track change, pause or play/pause toggle performed outside NotchHub without requiring re-expansion. Automated coverage proves the lifecycle wiring; physical acceptance on target hardware, including a fresh P1-style Idle/Hover/Stability resource measurement, is required before this id can move to accepted.

### `NH-MEDIA-LIVE-002` — bounded-lifecycle timeline ticker

Status: **PENDING**

One narrowly-scoped, reviewed `Timer.scheduledTimer` (`MediaTimelineTicker`) extrapolates displayed position between authoritative events at ~300ms, armed only while settled Peek/Expanded and actively playing, torn down on collapse/pause/session-loss/quit. `scripts/performance_policy.py`'s runtime audit gained a fail-closed, schema-validated reviewed-exception manifest (`performance/reviewed-runtime-timers.json`) scoped to exactly this `(file, rule)` pair. Automated coverage proves the bounded arm/disarm logic and extrapolation math with a fully dependency-injected clock/timer handle; physical acceptance that the timer visibly ticks in Peek/Expanded and is verifiably absent (no residual CPU) while Compact is required before this id can move to accepted.

## Automated coverage

- `NotchHubMediaCoreTests.MediaTimelineTickerTests` — bounded arm/disarm conditions, extrapolation + duration clamping, re-anchoring without drift, optimistic seek re-anchoring (all fully clock/timer-injected, no real `Timer`/run loop).
- `NotchHubCoreTests.MediaPeekSecurityPerformancePolicyTests.mediaRuntimeStartsOnceAtLaunchAndStopsOnlyAtQuit` — asserts the new always-on lifecycle wiring in `AppDelegate.swift`.
- `NotchHubCoreTests.MediaPeekSecurityPerformancePolicyTests.timelineTickerIsTheOnlyReviewedBoundedTimerAndNeverArmsInCompact` — asserts the ticker's bounded-lifecycle source markers and that `MediaNotchRootView.swift` itself remains timer-free.
- `NotchHubCoreTests.MediaSeekAppCompositionPolicyTests.appWiresSeekAndOptimisticallyReanchorsTheAlwaysActiveRuntimeTimeline` — asserts the optimistic-seek re-anchor wiring.
- `scripts.ShippingMediaIdleLifecycleTests.test_shipping_media_runtime_runs_for_the_apps_whole_lifetime` — Python source-policy assertion of the launch/terminate lifecycle.
- `scripts.test_performance_policy` (`RuntimePerformancePolicyTests`) — the reviewed-exception manifest is fail-closed and schema-validated, and suppresses exactly its own `(file, rule)` pair.

## Physical acceptance — required before this document's status may become ACCEPTED

See the checklist in `docs/superpowers/specs/2026-08-22-live-media-timeline-and-compact-design.md`.
