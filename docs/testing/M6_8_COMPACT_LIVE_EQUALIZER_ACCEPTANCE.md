# M6.8 — Compact live equalizer — Acceptance Evidence

Status: **PENDING — AUTOMATED EVIDENCE COMPLETE, PHYSICAL ACCEPTANCE REQUIRED**

Authoritative design/invariants: `docs/superpowers/specs/2026-08-22-compact-live-equalizer-design.md`.

Competitive-review-driven: replaces Compact's static play/pause glyph with a small animated equalizer, borrowing a UX detail found in both `TheBoredTeam/boring.notch` and NotchNook.

## Acceptance ledger

### `NH-MEDIA-LIVE-003` — compact live equalizer

Status: **PENDING**

`MediaCompactEqualizerView` replaces the static SF Symbol in Compact's right wing with 3 animated bars, driven by declarative SwiftUI `repeatForever` animation (not a timer primitive), armed only while `playbackState == .playing`, settling to a flat static pose on pause. Automated coverage proves the source contains no timer primitive and that the animation is conditioned on `isPlaying`; physical acceptance on target hardware is required before this id can move to accepted.

## Automated coverage

- `NotchHubCoreTests.MediaCompactEqualizerPolicyTests.equalizerAnimationIsDeclarativeAndArmedOnlyWhilePlaying` — asserts no `Timer`/`CADisplayLink`/`DispatchSourceTimer` in the view's source and that the repeating animation is gated by `isPlaying`.
- `NotchHubCoreTests.MediaCompactEqualizerPolicyTests.compactMediaContentUsesTheEqualizerInsteadOfAStaticGlyph` — asserts `MediaNotchRootView.compactMediaContent` wires in the new view instead of the old static glyph.

## Physical acceptance checklist

See `docs/superpowers/specs/2026-08-22-compact-live-equalizer-design.md`.
