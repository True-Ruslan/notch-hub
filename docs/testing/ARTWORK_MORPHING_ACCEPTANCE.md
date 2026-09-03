# Artwork morphing — matchedGeometryEffect across Compact/Peek/Expanded — Acceptance Evidence

Status: **ACCEPTED — 2026-09-03**

Authoritative design/invariants: `docs/superpowers/specs/2026-09-03-artwork-morphing-design.md`.
PR #75, physical acceptance executed on exact PR head `58b2cb9e3d6b30a1d2e874559b3c8754d10372e1`, canonical CI GREEN 3/3.

The last of the three ideas the M6.8 competitive review deferred (equalizer shipped M6.8, marquee text M6.9, album-art tinting M6.11). A shared `@Namespace` + `matchedGeometryEffect(id: "media.artwork")` on the single `artwork(_:size:)` definition site lets SwiftUI interpolate the artwork's frame/position across Compact/Peek/Expanded instead of cross-fading a size "pop". The morph is driven by an explicit `.animation(value: panelModel.contentPresentation)` synced to the AppKit panel's own resize duration (`notchAnimationDuration`, made `public` in `NotchHubCore` for this reuse) and disabled under Reduce Motion.

## Acceptance ledger

### `NH-MEDIA-ARTWORK-MORPH-001` — cross-state artwork morphing

Status: **PASS**

Physical acceptance on the product owner's own Mac, per the spec's Acceptance checklist — all items PASS:

1. Compact -> Peek and Peek -> Expanded (and reverses) via explicit tap/click show the artwork visually resizing/repositioning smoothly, not popping or cross-fading — PASS.
2. Interactive DOWN-drag expansion and UP-drag collapse remain visually correct, including a drag cancelled mid-gesture — PASS.
3. Rapid repeated transitions (5-10x compact<->peek<->expanded) show no jitter, stuck frame, or accumulating drift — PASS.
4. Physical LEFT/RIGHT swipe (next/previous) during Peek/Expanded remains visually correct and independent of the morph — PASS.
5. Track changes continue to cross-fade via the existing M6.11 tinting/artwork behavior, unaffected — PASS.
6. Reduce Motion enabled: transitions pop between states exactly as before this slice — PASS.
7. No visible jank/frame drop introduced to hover/gesture responsiveness — PASS.
8. Clean post-Quit teardown, unaffected — PASS.

## Automated coverage

- `NotchHubCoreTests.ArtworkMorphingPolicyTests.mediaNotchRootViewSharesOneMatchedGeometryNamespaceForArtwork` — asserts a single shared `@Namespace` and exactly one `matchedGeometryEffect(id: "media.artwork", ...)` call site.
- `NotchHubCoreTests.ArtworkMorphingPolicyTests.mediaNotchRootViewAnimatesContentPresentationSwitchWithoutNewTimerPrimitive` — asserts the explicit `.animation(value: panelModel.contentPresentation)` wiring and that no new timer/display-link/polling primitive was introduced.
- `NotchHubCoreTests.ArtworkMorphingPolicyTests.notchAnimationDurationProviderIsPublicForCrossModuleReuse` — asserts `notchStandardAnimationDuration`/`notchAnimationDuration` are `public`, keeping the SwiftUI morph duration and the AppKit panel resize duration a single source of truth.
- Full Swift test suite: 450/450 tests, 92 suites GREEN (`scripts/swift-test-clt.sh`).
- `scripts/performance_policy.py audit Sources` — passes with no new `performance/reviewed-runtime-timers.json` entry needed.
- Canonical CI (`Build, test and package`, `macOS 26 compatibility`, `macOS UI regression`) 3/3 GREEN on exact head `58b2cb9e3d6b30a1d2e874559b3c8754d10372e1`.

## Physical acceptance checklist

Full checklist definition: `docs/superpowers/specs/2026-09-03-artwork-morphing-design.md`. All items PASS; results recorded above.
