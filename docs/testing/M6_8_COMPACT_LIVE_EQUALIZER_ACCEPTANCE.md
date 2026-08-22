# M6.8 — Compact live equalizer — Acceptance Evidence

Status: **ACCEPTED — 2026-08-22**

Authoritative design/invariants: `docs/superpowers/specs/2026-08-22-compact-live-equalizer-design.md`.
Accepted merged source: PR #60, squash merge `4cbb01d7d5f57f26c40162c8149faf27691c2e06`. Physical acceptance executed on exact head `a6691e4d1ba89a2d10bb3bc86188f05c8475b653` on `Mac16,8 / macOS 26.6.2`.

Competitive-review-driven: replaces Compact's static play/pause glyph with a small animated equalizer, borrowing a UX detail found in both `TheBoredTeam/boring.notch` and NotchNook.

## Acceptance ledger

### `NH-MEDIA-LIVE-003` — compact live equalizer

Status: **PASS**

`MediaCompactEqualizerView` replaces the static SF Symbol in Compact's right wing with 3 animated bars, driven by SwiftUI's `PhaseAnimator` (not a timer primitive), armed only while `playbackState == .playing`, settling to a flat static pose on pause.

Physical acceptance on `Mac16,8 / macOS 26.6.2`: bars visibly and smoothly animate out of phase while playing; settle to a static flat pose on pause and restart correctly on resume; `ps` CPU sampling across 5 samples while settled Compact with media playing showed `0.0%`; no jank introduced to existing hover-for-Peek/click-for-Expanded interaction — all PASS.

**Real bug found and fixed during acceptance:** the initial implementation used `.animation(...repeatForever...)`, which froze mid-animation after the horizontal next/previous swipe gesture — the swipe's own `withAnimation` transaction interrupted the bars' implicit repeating loop, only recovering after expand+collapse force-recreated the view. Fixed by switching to `PhaseAnimator`, which owns its own animation timeline and is not vulnerable to an ancestor's unrelated explicit animation transaction. Re-verified: repeated next/previous swipes no longer freeze the equalizer.

## Automated coverage

- `NotchHubCoreTests.MediaCompactEqualizerPolicyTests.equalizerAnimationIsDeclarativeAndArmedOnlyWhilePlaying` — asserts no `Timer`/`CADisplayLink`/`DispatchSourceTimer` in the view's source and that the repeating animation is gated by `isPlaying`.
- `NotchHubCoreTests.MediaCompactEqualizerPolicyTests.compactMediaContentUsesTheEqualizerInsteadOfAStaticGlyph` — asserts `MediaNotchRootView.compactMediaContent` wires in the new view instead of the old static glyph.

## Physical acceptance checklist

Full checklist definition: `docs/superpowers/specs/2026-08-22-compact-live-equalizer-design.md`. All items PASS; results recorded above and in the PR #60 acceptance comment.
