# M6.9 — Media marquee text

Status: **SPECIFICATION — IMPLEMENTATION FOLLOWS**.

## Motivation

The M6.8 competitive review (`TheBoredTeam/boring.notch`, NotchNook) surfaced three UX ideas beyond the compact live equalizer that were deliberately deferred: album-art color tinting, `matchedGeometryEffect` cross-state artwork morphing, and marquee text for overflowing titles. Of these, marquee text is the smallest, lowest-risk and most directly corrective: Peek and Expanded currently hard-truncate title/artist/album with `.lineLimit(1)` + `.truncationMode(.tail)`, silently hiding real information whenever a track's metadata is longer than the available width. This is a real, bounded UX gap in the Universal Media core, and the user's stated priority is finishing the media experience to a high UI/UX standard before Settings (M7) or later modules.

Compact is unaffected: it has never rendered title/artist text (its right wing holds only artwork and `MediaCompactEqualizerView`, constrained by the physical notch width), so this slice is scoped to Peek and Expanded only.

## Design

A new pure calculator, `MediaMarqueeCalculator` (`Sources/NotchHubMediaCore/MediaMarqueeCalculator.swift`), decides whether a string overflows its available width and, if so, how long one scroll cycle should take at a fixed `pointsPerSecond` speed, given a fixed `gapPoints` separation between the two duplicated copies of the content used for a seamless "conveyor" loop. It has no SwiftUI dependency, so it is unit-tested directly and deterministically — the same separation of pure logic from view code the codebase already uses for `MediaTimelineTicker`'s extrapolation math.

A new view, `MediaMarqueeText` (`Sources/NotchHubApp/MediaMarqueeText.swift`), wraps a single line of text:

- It measures both its own available width and the text's true intrinsic (unclipped) width via `.background(GeometryReader { ... })` — a non-invasive technique that reads geometry without expanding the view's own layout footprint, so it never changes the height/width behavior of its parent `VStack`s in Peek/Expanded.
- When the text fits (the common case — most Yandex Music titles are short) or measurement hasn't completed yet, it renders exactly today's static `Text(text).lineLimit(1).truncationMode(.tail)` — byte-identical modifiers, so there is no visual or behavioral change for the common case.
- When the text genuinely overflows, it renders two copies of the text separated by `gapPoints`, clipped to the available width, and animates a continuous horizontal offset so the second copy visibly and seamlessly takes the first copy's place — a looping conveyor, not a pause-at-ends bounce.

## Invariant — animation is driven by SwiftUI `PhaseAnimator`, not a timer

The scroll offset is driven by a 2-phase `PhaseAnimator([.start, .end])` with `.linear(duration:)` timing, the same mechanism `MediaCompactEqualizerView` uses and for the same reason: a `.repeatForever`-based implicit animation was previously found to freeze when an ancestor `withAnimation` transaction (the horizontal next/previous swipe gesture) interrupted it; `PhaseAnimator` owns its own animation timeline and is immune to that class of interference. This introduces no `Timer`, `CADisplayLink`, `DispatchSourceTimer`, or `TimelineView` — `scripts/performance_policy.py`'s runtime audit passes with no new entry required in `performance/reviewed-runtime-timers.json` (confirmed by running the audit against the implementation).

## Reduced Motion

`MediaMarqueeText` reads `@Environment(\.accessibilityReduceMotion)` and short-circuits straight to the static truncated-text branch whenever it is `true`, regardless of overflow. This is the first use of the SwiftUI `accessibilityReduceMotion` environment key in the codebase; the existing precedent for treating reduce-motion as authoritative is `NotchPanelController`'s `NSWorkspace.accessibilityDisplayShouldReduceMotion` observation (a controller-level concern, not applicable here since this is a stateless leaf view).

## UI wiring

`MediaNotchRootView.swift` swaps all 5 title/artist/album `Text` call sites in `peekMediaContent` and `expandedMediaContent` for `MediaMarqueeText`, removing the external `.lineLimit`/`.truncationMode` modifiers (the component now owns that policy internally, in exactly one place):

1. Peek title, Peek artist.
2. Expanded title, Expanded artist, Expanded album.

Existing `.accessibilityIdentifier("media.title")` / `.accessibilityIdentifier("media.artist")` are preserved on the wrapping call, unchanged for UI-automation compatibility.

## Explicitly out of scope for this slice

- RTL/bidirectional scroll direction (stays LTR regardless of locale).
- A user-configurable scroll speed or on/off toggle (fixed constant this slice; no Settings UI exists yet — that is M7).
- A dedicated Dynamic Type / large-accessibility-font visual pass (the component still measures correctly at whatever font size it is given, just without a dedicated acceptance pass this slice).
- Album-art color tinting and `matchedGeometryEffect` cross-state artwork morphing (already deferred from M6.8; remain deferred).
- A maximum-cycle-duration cap for pathologically long strings beyond the existing minimum-duration floor — noted as a known limitation, to become a fast-follow only if physical acceptance finds it actually jarring.

## Acceptance

Automated: canonical CI green, full Swift test suite green (new `MediaMarqueeCalculatorTests` unit tests plus `MediaMarqueeTextPolicyTests` source-scanning assertions), `scripts/performance_policy.py audit Sources` green with no new exception needed.

Physical, on exact `Mac16,8` in the current macOS `26.6` patch family, required before merge — see `docs/testing/M6_9_MEDIA_MARQUEE_ACCEPTANCE.md`:

1. A long title/artist/album scrolls smoothly in Peek and in Expanded.
2. Short strings render static and unchanged from pre-slice behavior — no accidental animation, no layout shift.
3. Reduce Motion (toggled live in System Settings) freezes the marquee to static truncated text in both presentations.
4. With Reduce Motion off and media playing, Compact's equalizer `PhaseAnimator` and Peek/Expanded's marquee `PhaseAnimator` run concurrently without interfering, stalling, or freezing each other, including across a gesture-driven Compact/Peek/Expanded transition.
5. Idle CPU remains policy-compliant; the marquee's `PhaseAnimator` tears down cleanly when its view leaves the hierarchy (panel collapsed/hidden).
6. A very long single unbroken word scrolls without crashing, wrapping, or stalling.
