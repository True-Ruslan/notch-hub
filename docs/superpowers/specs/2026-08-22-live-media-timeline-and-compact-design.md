# M6.7 — live media timeline and live Compact display

Status: **SPECIFICATION — IMPLEMENTATION FOLLOWS**.

## Motivation

Universal Media currently has two accepted, deliberate limitations, both documented as intentional in `docs/ARCHITECTURE.md` and `docs/superpowers/specs/2026-08-11-media-first-ui-design.md`:

1. The progress bar in Peek/Expanded renders a *static* value that only refreshes when the system emits a new Now Playing event (track change, play/pause, external seek). It does not visibly tick while the user watches it.
2. Compact shows only the last snapshot retained from the previous Expanded session (artwork + play/pause icon). Because the shipping media runtime is torn down whenever the panel is not Expanded, Compact cannot reflect a track change, a pause, or a play/pause toggle performed elsewhere while the panel stays Compact.

Both limitations were accepted tradeoffs to keep the "zero-adapter compact" and "no repeating timer anywhere" resource invariants that P1 measured and validated. The product owner has now explicitly decided to trade some of that idle-resource headroom for a materially better music experience, on the condition that both changes remain bounded, are written up before implementation, and are re-validated through a fresh physical P1-style resource pass before merge. This document records the two invariant reversals and their bounded replacement invariants.

Next/Previous and Seek command dispatch were separately audited and found to already be latency-free (direct, unthrottled dispatch on every path); no change is required there.

## Invariant 1 — the shipping media runtime is always active while the app runs

**Previous invariant:** the runtime (and its adapter subprocess) starts only when the panel settles to `.expanded` and stops on any other settled presentation (`docs/ARCHITECTURE.md` "M6.4 deliberately avoids an always-on media adapter").

**New invariant:** `ShippingMediaRuntime.start()` is called exactly once, in `AppDelegate.applicationDidFinishLaunching`, and `stop()` is called exactly once, in `applicationWillTerminate`. The runtime's lifecycle is no longer coupled to `NotchPresentation`. `ShippingMediaPresentationModel.presentation` therefore reflects the live, authoritative Now Playing state continuously, including while the panel is Compact — Compact's existing `@Published`-bound SwiftUI content (artwork + play/pause icon) becomes live for free, with no new UI code, because it is already reactively bound to `presentation`.

Rationale for choosing "always on" over a cheaper detection scheme: the only way to *discover* that something started playing without the adapter already running is a genuinely different, lower-level mechanism (registering directly for the private `MediaRemote` Darwin notification in-process instead of through the sandboxed subprocess boundary). That is a larger, riskier architectural change touching the project's existing private-API isolation boundary and was explicitly rejected in favor of the simpler, honest "always on while the app runs" model, accepting its resource cost.

What does **not** change:
- No new permission, entitlement, or App Sandbox exception.
- No polling loop is added inside the transport; the adapter subprocess remains a pure event-driven `stream` listener (see Invariant 2 for the one narrowly-scoped exception to "no repeating timer").
- Normal Quit still leaves no adapter process running (`pgrep -lf 'mediaremote-adapter\.pl'` empty post-Quit remains a hard acceptance gate).
- `MediaPeekSession` / `ShippingMediaPeekProbe`'s bounded one-shot probing needed one correction, found by automated UI regression: `MediaPeekSession.handleSettledPeek()` now skips starting the probe entirely when `presentationModel.presentation` is already non-nil. Previously the probe was safe to run unconditionally because, pre-M6.7, Compact/Peek never had a live authoritative presentation to protect; with the runtime always active, an unconditional probe could settle after the runtime had already published good data and its `.noSession` branch would call `clearAuthoritativePresentation()`, wiping the live state (observed concretely as hover-then-click sequences erasing title/artist/artwork right before Expanded rendered). The probe remains exactly as before for its real purpose: enriching a genuinely empty presentation.

Required re-validation: P1's Idle/Hover/Stability physical acceptance must be re-run on the same exact target hardware, because the Idle scenario's baseline now includes a persistently running adapter subprocess. This is expected to raise Idle CPU/RSS/thread numbers versus the currently accepted P1 bundle; the new numbers become the accepted baseline going forward, replacing (not averaging with) the prior "zero-adapter compact" Idle evidence.

## Invariant 2 — one narrowly-scoped, reviewed, bounded-lifecycle timer for timeline extrapolation

**Previous invariant:** no `Timer`, `DispatchSourceTimer`, or display link anywhere in `Sources/`, enforced by `scripts/performance_policy.py audit Sources` with a hard, exception-free regex scan.

**New invariant:** exactly one bounded-lifecycle `Timer.scheduledTimer` is introduced, in a new, single-purpose type `MediaTimelineTicker` (`Sources/NotchHubMediaCore/MediaTimelineTicker.swift`). It exists solely to extrapolate the displayed playback position between authoritative system events, at a fixed ~300 ms cadence, so the progress bar visibly advances while the user is looking at it.

Bounded lifecycle, precisely:
- The timer is armed only when **both** conditions hold: (a) the settled panel presentation is `.peek` or `.expanded` (never `.compact`), and (b) the current authoritative presentation reports `playbackState == .playing` with a known `positionSeconds`/`durationSeconds` pair.
- The timer is torn down immediately when either condition stops holding: panel collapses to Compact, playback pauses, the session becomes unavailable, or the app quits.
- The timer never runs while the panel is Compact or Idle — the "no polling in idle" resource invariant that P1 measured is unaffected.
- The ticker does not perform I/O, does not dispatch any media command, and does not call into the adapter; it only recomputes a displayed number from an already-known anchor (`positionSeconds` + wall-clock elapsed since that snapshot was received), clamped to `durationSeconds`.
- On every new authoritative snapshot (including right after a locally committed seek, applied optimistically before the system round-trip confirms it) the ticker re-anchors from the fresh value, so the tick never accumulates drift across snapshots.

Because `scripts/performance_policy.py`'s audit had no exception mechanism at all, this document also authorizes and requires extending it with a narrow, schema-validated, fail-closed reviewed-exception manifest (`performance/reviewed-runtime-timers.json`) that suppresses exactly the `(file, rule)` pair introduced here and nothing else. Any other file or rule match remains a hard CI failure. The manifest and the policy-script change are covered by their own Python unit tests in the same PR, per `PERFORMANCE.md`'s requirement that a reviewed runtime-timer exception carry "an explicit reviewed performance justification, bounded lifecycle, tests, and documentation in the same PR."

## UI wiring

- `MediaNotchRootView`'s `seekProgress` reads `timelineDriver.displayedPositionSeconds ?? presentation.positionSeconds` instead of the raw authoritative `positionSeconds`, in both `peekMediaContent` and `expandedMediaContent`. Live drag-preview (`seekPreviewSeconds`) continues to take priority over both.
- `MediaTimelineTicker` lives in `NotchHubMediaCore` (not `NotchHubApp`), so the existing `MediaAppCompositionPolicyTests` assertion that `MediaNotchRootView.swift` itself contains no `Timer(` stays true unmodified — the timer is not in the view layer.
- Compact requires no new SwiftUI code: its existing `compactMediaContent` already renders from the live `@Published` `presentation`.

## Explicitly out of scope for this slice

- A user-facing multi-player source picker (already separately deferred).
- Apple Music/Spotify/other player compatibility verification (already separately tracked, unverified).
- Any change to Next/Previous/Seek command dispatch — already latency-free, confirmed by code audit, no change needed.
- Removing or refactoring `MediaPeekSession`/`ShippingMediaPeekProbe`.

## Acceptance

Automated: canonical CI green, full Swift test suite green, `scripts/performance_policy.py audit Sources` green (with exactly the one documented, tested exception), `test_feature_size_budget.py` green against a new `performance/m6-7-live-media-timeline-and-compact-size-budget.json`.

Physical, on exact `Mac16,8` in the current macOS `26.6` patch family, required before merge:

1. Timeline visibly ticks in real time while Peek is open and media is playing; stops ticking (freezes, does not drift) when paused; resumes correctly on resume.
2. Timeline visibly ticks in real time while Expanded is open and media is playing.
3. Compact reflects a track change, a pause, and a play/pause toggle performed from **outside** NotchHub (e.g. from the source player itself) without requiring the panel to be re-expanded.
4. Collapsing to Compact stops the timeline timer (no residual CPU from the ticker while Compact — spot-checked via Activity Monitor sampling, not just code inspection).
5. Post-Quit `pgrep -lf 'mediaremote-adapter\.pl' || true` remains empty.
6. A fresh P1-style Idle/Hover/Stability measurement bundle is collected and recorded, superseding the prior "zero-adapter compact" bundle as the accepted baseline.
