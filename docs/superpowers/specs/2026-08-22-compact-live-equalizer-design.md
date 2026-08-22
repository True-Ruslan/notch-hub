# M6.8 — Compact live equalizer

Status: **SPECIFICATION — IMPLEMENTATION FOLLOWS**.

## Motivation

Competitive review of `TheBoredTeam/boring.notch` (open source, uses the same `MediaRemoteAdapter`) and NotchNook (closed source, reviewed via MacStories/HowToGeek/Digital Trends) found one concrete, low-risk UX improvement worth borrowing into Compact: both replace a static play/pause glyph with a small animated equalizer/spectrum on the side of the notch that visibly pulses while something is playing. NotchHub's current Compact right wing (`MediaNotchRootView.compactMediaContent`) renders a single static SF Symbol (`"waveform"` or `"pause.fill"`) that never animates — it reads as inert even while music is actively playing.

This is scoped narrowly to that one visual element. Other ideas surfaced by the same review (album-art color tinting, `matchedGeometryEffect` cross-state morphing, marquee text for long titles) are explicitly deferred to separate slices.

## Design

A new `MediaCompactEqualizerView` (`Sources/NotchHubApp/MediaCompactEqualizerView.swift`) renders 3 vertical `Capsule` bars in the existing 36x32pt right-wing frame, replacing the static `Image(systemName:)` in `compactMediaContent`. Each bar has a distinct fixed animation duration (not randomized, for determinism) so the bars visibly drift out of phase rather than pulsing in lockstep, evoking a real audio equalizer without needing FFT/audio-tap analysis of the actual signal (no microphone/audio-capture entitlement, no new permission).

## Invariant — animation is driven by SwiftUI/Core Animation implicit animation, not a timer

The bars animate via `.animation(.easeInOut(duration:).repeatForever(autoreverses: true), value:)`, an implicit, declarative Core-Animation-backed loop — not `Timer.scheduledTimer`, not `CADisplayLink`, not a `DispatchSourceTimer`, and not app code invoked on a Swift Concurrency timer. `scripts/performance_policy.py`'s runtime audit already forbids exactly those primitives; this view introduces none of them, so no reviewed-exception entry is needed.

Bounded lifecycle: the repeating animation is armed only while `presentation.playbackState == .playing`. On pause, the bars animate back to a flat/paused pose via one non-repeating transition and stay static — no animation runs while paused or while nothing is playing. Since this view only exists inside `compactMediaContent`, it is never instantiated while Peek or Expanded are showing, and disappears (stopping any in-flight animation) the moment `presentation` becomes `nil` (SwiftUI tears down the view along with its animation state).

## UI wiring

`compactMediaContent` in `MediaNotchRootView.swift` replaces its `Image(systemName: presentation.playbackState == .playing ? "waveform" : "pause.fill")` with `MediaCompactEqualizerView(isPlaying: presentation.playbackState == .playing)`, keeping the same 36x32pt frame and the same accepted "zero adapter observation, only a projection of the already-live presentation" boundary — this view reads only the already-published `playbackState`, it does not itself observe the media transport.

## Explicitly out of scope for this slice

- Real audio-signal-driven visualizer amplitude (would need audio tap/FFT — a much larger, more invasive change; the competitors' spectrum views are also not truly audio-reactive in the strict sense, they animate on a fixed pattern while `isPlaying`).
- Color tinting from album artwork.
- `matchedGeometryEffect` cross-state artwork morphing.
- Marquee text for overflowing titles.
- Any change to Peek/Expanded's play/pause icon (they keep the existing static icon; only Compact's wing changes).

## Acceptance

Automated: canonical CI green, full Swift test suite green, `scripts/performance_policy.py audit Sources` green with no new exception needed, new policy test asserting the view's source contains no `Timer`/`CADisplayLink`/`DispatchSourceTimer` and that the repeating animation is conditioned on `playbackState == .playing`.

Physical, on exact `Mac16,8` in the current macOS `26.6` patch family, required before merge:

1. While media plays and the panel is Compact, the equalizer visibly and smoothly animates (bars out of phase, not synchronized).
2. On pause, the bars settle to a static flat pose without residual motion.
3. On resume, animation restarts correctly.
4. No visible jank/frame drops introduced to Compact's existing hover/interaction responsiveness.
5. Spot-check CPU while settled Compact with media actively playing (the one new scenario this slice adds versus M6.7's Compact-while-paused/idle baseline) remains reasonable — not a full P1 re-run, but a sanity `ps` sample.
