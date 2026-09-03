# Next slice — `matchedGeometryEffect` cross-state artwork morphing

Status: **SPECIFICATION — IMPLEMENTATION FOLLOWS**.

## Motivation

The M6.8 competitive review of `TheBoredTeam/boring.notch` and NotchNook surfaced three UX ideas: the compact live equalizer (shipped M6.8), marquee text (shipped M6.9), and album-art color tinting (shipped M6.11). `matchedGeometryEffect` cross-state artwork morphing was deliberately deferred through all three because it requires coordinating a shared SwiftUI animation namespace across three distinct view hierarchies (`compactMediaContent`/`peekMediaContent`/`expandedMediaContent` in `Sources/NotchHubApp/MediaNotchRootView.swift`) and interacts with the existing gesture-driven transition system — exactly the category of custom SwiftUI animation code that has twice already shipped real, hardware-only-visible bugs in this project (M6.8's `.repeatForever` freeze after a swipe gesture; M6.9's untested `GeometryReader` measurement path, acceptance explicitly waived). It is now the only remaining deferred idea from that review, so it is the next bounded slice.

Today, `mediaContent(_:)` switches its entire body with a plain `switch panelModel.contentPresentation` (`MediaNotchRootView.swift:125`). Each case's `artwork(_:size:)` call is an independent view instance with no shared identity, so when the panel transitions between Compact (24pt), Peek (40pt) and Expanded (92pt) artwork, SwiftUI cross-fades old-out/new-in rather than visually resizing/repositioning the same image — the artwork appears to "pop" between sizes rather than morph.

## Design

### Shared namespace and effect wiring

In `MediaNotchRootView`, add `@Namespace private var artworkNamespace`. Apply `.matchedGeometryEffect(id: "media.artwork", in: artworkNamespace)` to the artwork image in all three call sites that currently call `artwork(_:size:)`/`artworkWithSourceBadge(_:size:)` (compact, peek, expanded). The same stable id across all three cases is what tells SwiftUI these are "the same view" across the state switch, letting it interpolate frame/position instead of cross-fading.

`artwork(_:size:)` stays a single shared function (no duplication); the `.matchedGeometryEffect` modifier is added at its single definition site (`MediaNotchRootView.swift:451`) rather than at each of the three call sites, since every call site already routes through it.

### Driving the animation explicitly, synced to the panel's own resize

The SwiftUI content view and the actual `NSPanel` frame are two separate animated systems: `NotchPanelTransitionCoordinator`/`animateNotchPanel` resize the AppKit window frame directly (not through SwiftUI), using `notchAnimationDuration(reduceMotion:)` (`NotchAnimationDurationProvider.swift`, currently `0.20`s, `0` under Reduce Motion). The existing `switch panelModel.contentPresentation` has no `withAnimation` of its own today — SwiftUI only animates the state switch already implicitly through the one `.animation(.easeInOut(duration: 0.12), value: mediaModel.presentation?.sessionIdentity)` modifier on `sessionIdentity`, which is unrelated to `contentPresentation` and far shorter.

For the artwork morph to look correct it must run for the same duration as the actual panel resize, not some independent SwiftUI default. `notchStandardAnimationDuration`/`notchAnimationDuration(reduceMotion:)` are currently `internal` to `NotchHubCore`; this slice makes both `public` (pure visibility change, no behavior change, no new API surface beyond what `NotchHubApp` already needs) so `MediaNotchRootView` can wrap the presentation switch in:

```swift
.animation(
    notchAnimationDuration(reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion) == 0
        ? nil
        : .easeInOut(duration: notchAnimationDuration(reduceMotion: false)),
    value: panelModel.contentPresentation
)
```

placed alongside the existing `.animation(... value: sessionIdentity)` modifier in `mediaContent(_:)`, not replacing it — both key off different, independent triggers. Reduce Motion continues to disable the effect entirely (`nil` animation), matching how `notchAnimationDuration` already zeroes the AppKit side; the morph never plays for users who have Reduce Motion enabled, it simply pops as it does today.

### Interaction with the gesture-driven transition system

`MediaGestureVisualModel.horizontalOffset` (applied via `.offset(x:)` on the whole `mediaContent` in `MediaNotchRootView.swift:135`) drives the physical LEFT/RIGHT next/previous swipe visuals, and interactive DOWN/UP drag expansion is owned by `NotchPanelTransitionCoordinator`/`MediaGestureSession`, entirely outside SwiftUI's animation system (it drives the AppKit panel frame per-pointer-sample, not through a SwiftUI `Animation`). `panelModel.contentPresentation` itself only changes at the *end* of a committed transition (`setContentPresentation`), not per-frame during an interactive drag — so `matchedGeometryEffect` only activates once, at the moment a transition is committed to its new endpoint, and does not have to interpolate through interactive dragging.

This is the deferred risk this spec exists to manage explicitly rather than discover physically: an interactive expansion that is *cancelled* mid-drag never calls `setContentPresentation` with a new value (the interaction contract already guarantees cancellation returns to the exact prior state), so the matched-geometry animation and the gesture-visual offset never fire in the same instant by construction. If physical testing finds a case where they visibly race, the fix is scoping the `.animation` modifier's `value:` more narrowly (e.g. also keying off gesture-active state) — not adding a new state machine.

## Explicitly out of scope for this slice

- Morphing any element other than the artwork image (title/artist/album text, play/pause glyph, equalizer, source badge) — those already cross-fade acceptably via the existing `.transition(.opacity)`/`sessionIdentity` animation and are not part of this idea.
- Any change to `artwork(_:size:)`'s image-selection/fallback logic, or to the M6.11 tinting background — both are unrelated and untouched.
- A new pure/testable calculator module — unlike M6.9/M6.11, this slice has no non-SwiftUI math to extract; `matchedGeometryEffect` and `.animation(value:)` are both framework primitives applied declaratively, not new algorithmic code.

## Invariant — no new runtime primitive

No `Timer`, `DispatchSourceTimer`, `CADisplayLink`, `Task.sleep`, or polling loop is introduced. The morph is a declarative `matchedGeometryEffect` plus one `.animation(value:)` modifier; `scripts/performance_policy.py`'s runtime audit needs no new entry in `performance/reviewed-runtime-timers.json`.

## Acceptance

Automated: canonical CI green; full Swift test suite green. This slice has no new pure/unit-testable logic (see Explicitly out of scope), so automated coverage is limited to the existing regression/UI automation suite continuing to pass against the new modifiers (accessibility identifiers on `artwork(_:size:)` and the three surfaces are unchanged) and `scripts/performance_policy.py audit Sources` staying green with no new timer exception.

Physical, on exact `Mac16,8` in the current macOS `26.6` patch family, required before merge (this exact class of custom SwiftUI animation code has a direct precedent — twice — for hiding bugs only physical testing caught):

1. Compact -> Peek and Peek -> Expanded (and their reverses) via explicit tap/click show the artwork visually resizing/repositioning smoothly between its three sizes/positions, not popping or cross-fading.
2. Interactive DOWN-drag expansion and UP-drag collapse remain visually correct — no artwork flicker, duplicate frame, or mispositioned intermediate state — including a drag that is cancelled mid-gesture (returns cleanly to the prior state with no stray morph).
3. Rapid repeated transitions (5-10x compact<->peek<->expanded in quick succession) show no jitter, stuck frame, or accumulating visual drift.
4. Physical LEFT/RIGHT swipe (next/previous) during Peek/Expanded remains visually correct and independent of the morph — the gesture-visual horizontal offset and the artwork morph do not visibly fight each other.
5. Track changes (new artwork) while settled in one state continue to cross-fade via the existing M6.11 tinting/artwork behavior, unaffected by this slice.
6. Reduce Motion enabled: transitions pop between states exactly as they did before this slice (no morph animation), matching the existing zero-duration AppKit panel resize under Reduce Motion.
7. No visible jank/frame drop introduced to hover/gesture responsiveness.
8. Clean post-Quit teardown, unaffected (this slice touches no lifecycle code).
