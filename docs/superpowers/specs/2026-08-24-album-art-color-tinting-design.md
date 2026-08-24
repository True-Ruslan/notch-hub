# M6.11 — Album-art color tinting

Status: **SPECIFICATION — IMPLEMENTATION FOLLOWS**.

## Motivation

The M6.8 competitive review of `TheBoredTeam/boring.notch` and NotchNook surfaced three UX ideas beyond the compact live equalizer: album-art color tinting, `matchedGeometryEffect` cross-state artwork morphing, and marquee text for overflowing titles. Marquee text shipped as M6.9; artwork morphing and color tinting remained explicitly deferred through M6.9 and M6.10.

Of the two remaining ideas, color tinting is the smaller and lower-risk one. `matchedGeometryEffect` cross-state morphing requires coordinating a shared animation namespace across three distinct view hierarchies (`compactMediaContent`/`peekMediaContent`/`expandedMediaContent`) and interacts with the existing gesture-driven transition system in ways that are hard to reason about statically — exactly the category of custom SwiftUI animation code that has twice now shipped real, hardware-only-visible bugs in this project (M6.8's `.repeatForever` freeze after a swipe gesture; M6.9's untested `GeometryReader` measurement path, acceptance explicitly waived). Color tinting, by contrast, touches one shared `.background` modifier and needs no cross-view animation coordination, so it is picked first.

NotchHub's panel background is currently flat `Color.black` in every presentation state (`mediaContent(_:)` in `Sources/NotchHubApp/MediaNotchRootView.swift`). Both competitors derive a subtle background tint from the current track's artwork instead, making the panel feel connected to what's playing rather than a fixed black surface with an image floating on top of it.

## Design

### Pure color math — `MediaArtworkTintCalculator`

`Sources/NotchHubMediaCore/MediaArtworkTintCalculator.swift`, a `SwiftUI`-free `enum` of pure static functions, following the existing `MediaMarqueeCalculator` pattern so it stays deterministically unit-testable with no image decoding involved:

```swift
public enum MediaArtworkTintCalculator {
    public static let maxSaturation: Double = 0.55
    public static let maxBrightness: Double = 0.34
    public static let minBrightness: Double = 0.05

    public struct Tint: Equatable, Sendable {
        public let hue: Double
        public let saturation: Double
        public let brightness: Double
    }

    /// Clamps a raw sampled artwork color into a subtle, legible panel-background
    /// tint. Input is standard HSB (each component conventionally 0...1, but the
    /// function defensively clamps out-of-range/non-finite input rather than
    /// trusting the caller).
    public static func tint(hue: Double, saturation: Double, brightness: Double) -> Tint
}
```

Clamping exists because raw sampled artwork color is unconstrained: a bright yellow album cover or a saturated red one must not produce a background so vivid or so bright that the existing white title/artist text (and the marquee/equalizer/seek-progress chrome drawn over it) becomes hard to read. `maxBrightness`/`minBrightness` keep the tint dark enough to still read as "the panel background," never "a colored card"; `maxSaturation` keeps it from looking like a color-picker swatch. Hue is passed through (clamped only defensively against non-finite/out-of-`0...1` input) since hue alone never affects legibility against a dark, desaturated backdrop.

Non-finite (`NaN`/`infinite`) input for any component falls back to that component's safe default (`hue: 0`, `saturation: 0`, `brightness: minBrightness`) rather than propagating garbage into a `Color` — sampling from malformed/degenerate artwork (e.g. a fully transparent or 1x1 image) must never crash or render an undefined color.

### Sampling raw color from artwork data — `MediaArtworkTintSampler`

`Sources/NotchHubMediaCore/MediaArtworkTintSampler.swift`. Artwork exists in the model only as `Data` (`ShippingMediaPresentation.artworkData`). Unlike `artwork(_:size:)`'s `NSImage`-based rendering, sampling does not need `AppKit`/`SwiftUI` at all — only `CoreGraphics`/`ImageIO`, which are lower-level system frameworks with no UI dependency. Keeping the sampler in `NotchHubMediaCore` (rather than pushing it to the `NotchHubApp` "edge" the way rendering is pushed) keeps it inside this project's only genuinely unit-tested boundary: `NotchHubApp` has no test target at all in `Package.swift` and its SwiftUI/AppKit-only files (e.g. `MediaMarqueeText.swift`) only ever get source-scanning policy tests from `NotchHubCoreTests`, never real behavioral tests. A real image-decoding-and-averaging algorithm deserves real behavioral tests, so it belongs where those exist.

1. Decode `Data` via `CGImageSourceCreateWithData` -> `CGImageSourceCreateImageAtIndex` (returns `nil` on any decode failure — malformed/truncated artwork is tolerated the same way `artwork(_:size:)` already tolerates it, by falling back rather than crashing).
2. Draw the `CGImage` into a single 1x1-pixel, 8-bit RGBA `CGContext`. This is the standard fast average-color technique: letting Core Graphics' own image interpolation do the downsampling is orders of magnitude cheaper than manually walking every source pixel, and its cost is independent of how large the source image is (bounded by the already-enforced 4 MiB artwork payload ceiling in `MediaRemoteWire.swift`).
3. Read the single resulting RGBA pixel, normalize each channel to `0...1`, and convert to HSB with a pure, private RGB->HSB conversion (standard piecewise-max/min formula; no `AppKit`/`NSColor` needed).
4. Pass through `MediaArtworkTintCalculator.tint(hue:saturation:brightness:)` and return the clamped `Tint`, or `nil` when `artworkData` is `nil` or fails to decode.

This is deterministically testable end-to-end without any SwiftUI/AppKit dependency and without real album artwork: a test can synthesize a solid-color image in memory via `CGImageDestination` (writing a tiny PNG), feed its `Data` through `MediaArtworkTintSampler.sample(artworkData:)`, and assert the resulting `Tint`'s hue is close to the known input color's hue (allowing for the calculator's brightness/saturation clamping).

### View wiring

In `Sources/NotchHubApp/MediaNotchRootView.swift`, `mediaContent(_:)`:

- Add `@State private var artworkTintColor: Color = .black`.
- `.onChange(of: presentation.artworkData, initial: true) { _, newData in artworkTintColor = MediaArtworkTintSampler.sample(artworkData: newData).map { Color(hue: $0.hue, saturation: $0.saturation, brightness: $0.brightness) } ?? .black }`, mirroring the existing `.onChange(of: presentation.sourceBundleIdentifier, initial: true)` pattern already on this view for another one-shot, artwork-adjacent side effect. The `Color(hue:saturation:brightness:)` construction is the only tint-related code that lives in `NotchHubApp`, and it is a trivial one-line SwiftUI call with no logic of its own to test.
- Replace `.background(Color.black)` with `.background(artworkTintColor)`.
- Add `.animation(.easeInOut(duration: 0.4), value: artworkTintColor)` so a track change crossfades the background instead of hard-cutting — purely declarative SwiftUI `Color` animation, not a new animation primitive class (no `PhaseAnimator`, no gesture interaction to conflict with).

This applies uniformly to Compact, Peek and Expanded, because `mediaContent(_:)` is the one shared background wrapper for all three (`MediaNotchRootView.swift:131`) — there is no separate per-state background to special-case, and a uniform tint across states is also what both reviewed competitors do.

## Invariant — no new runtime primitive

Sampling runs synchronously on the main actor, once per artwork change (gated by SwiftUI's `onChange` equality check on `Data`), exactly matching the cost profile the existing `artwork(_:size:)` decode already pays on every artwork change today. No `Timer`, `DispatchSourceTimer`, `CADisplayLink`, `Task.sleep`, or polling loop is introduced; `scripts/performance_policy.py`'s runtime audit needs no new entry in `performance/reviewed-runtime-timers.json`. The crossfade is a declarative `Color` animation, which Core Animation drives without app-owned per-frame code.

## Explicitly out of scope for this slice

- `matchedGeometryEffect` cross-state artwork morphing — remains deferred to its own slice.
- Any change to the artwork image itself (crop, filter, blur) — only the surrounding panel background is tinted.
- Per-pixel/dominant-cluster color extraction (k-means, saliency-weighted sampling, etc.) — a single fast average-color sample is sufficient for a "subtle backdrop tint" and keeps the implementation simple and cheap; if the average ever looks visually wrong for genuinely multi-toned artwork, that is a follow-up, not a blocker for this slice.
- Any new permission, network call, or persisted artwork/color cache — the tint is recomputed from the already-in-memory `artworkData` each time it changes and is not written to disk.

## Acceptance

Automated: canonical CI green; full Swift test suite green; new `MediaArtworkTintCalculatorTests` (pure, deterministic clamping/edge-case coverage) and `MediaArtworkTintSamplerTests` (synthetic solid-color image round-trip, both in `Tests/NotchHubMediaCoreTests/`) both green; `scripts/performance_policy.py audit Sources` green with no new timer exception — its blanket per-line scan already covers the new `NotchHubMediaCore` file the same as every other source file, so no source-scanning policy test is needed for this invariant the way `MediaMarqueeTextPolicyTests` needed one for an `NotchHubApp`-only file.

Physical, on exact `Mac16,8` in the current macOS `26.6` patch family, required before merge (per this project's standing policy that CI cannot honestly prove real visual/animation feel):

1. Playing a track with distinctly colorful artwork (e.g. a bright album cover) shows a visibly but subtly tinted panel background in Compact, Peek and Expanded — not a flat black panel, not an overpoweringly saturated/bright one.
2. Title, artist, seek-progress, equalizer, and marquee text all remain clearly legible against the tinted background across a few different artwork colors (at least one dark-cover track and one bright/saturated-cover track).
3. Changing tracks crossfades the background smoothly rather than hard-cutting or flashing.
4. A source with no artwork (or NotchHub's own generic no-media Peek) shows the existing plain black background, unchanged from today.
5. No visible jank/frame drop introduced to hover/gesture responsiveness when artwork changes.
6. Spot-check CPU with `ps` around a track change (the one new one-shot cost this slice adds) is reasonable — not a full P1 re-run.
