# M6.9 — Media marquee text — Acceptance Evidence

Status: **MERGED — PHYSICAL ACCEPTANCE DEFERRED (EXPLICITLY WAIVED BY PRODUCT OWNER, NOT TESTED)**

Authoritative design/invariants: `docs/superpowers/specs/2026-08-22-media-marquee-text-design.md`.
Merged source: PR #62, squash merge `704bfbcdb1bd81774e8fc2d6a7d9f60a6672d703`.

Peek and Expanded title/artist/album previously hard-truncated overflowing text; this slice adds a pure `MediaMarqueeCalculator` and a `MediaMarqueeText` view that scrolls overflowing content in a continuous conveyor loop via SwiftUI's `PhaseAnimator`, matching the design spec.

## Why this record differs from prior acceptance records

Every prior milestone in this repository (M6.6 through M6.8, P1, M1) was merged only after a human physically ran the checklist on exact target hardware (`Mac16,8`/macOS `26.6.x`), because this project's own stated policy is that CI cannot honestly prove real notch geometry, animation feel, or resource behavior. That policy was not met here: no physical run of the checklist below was performed, on this hardware or any other, before merge.

The product owner explicitly instructed merging PR #62 without physical acceptance, after being asked directly whether to (a) personally run the checklist first, (b) merge now and waive the physical gate, or (c) leave the PR open and start other work in parallel — and chose (b). This is recorded here verbatim rather than silently treated as equivalent to a passed physical run, so this document is not mistaken for genuine hardware evidence in the future. Nothing below should be read as "PASS" — it is an explicit, informed decision to accept the residual risk instead.

## Acceptance ledger

### `NH-MEDIA-MARQUEE-001` — media marquee text — DEFERRED (physical acceptance NOT TESTED)

Status: **DEFERRED** — physical acceptance explicitly waived by product owner, NOT TESTED on real hardware

Automated coverage below is genuine and passed on canonical CI. The physical checklist items are listed as originally specified, each marked **NOT PERFORMED**, not PASS:

1. Long title/artist/album scrolls smoothly in Peek and in Expanded — **NOT PERFORMED**.
2. Short strings render static and unchanged from pre-slice behavior — **NOT PERFORMED**.
3. Reduce Motion (toggled live in System Settings) freezes the marquee to static truncated text — **NOT PERFORMED**.
4. Compact's equalizer `PhaseAnimator` and Peek/Expanded's marquee `PhaseAnimator` run concurrently without interfering, including across gesture-driven transitions — **NOT PERFORMED**.
5. Idle CPU remains policy-compliant; the marquee's `PhaseAnimator` tears down cleanly when its view leaves the hierarchy — **NOT PERFORMED**.
6. A very long single unbroken word scrolls without crashing, wrapping, or stalling — **NOT PERFORMED**.

## Known residual risk

This exact class of code — a custom `PhaseAnimator`-driven SwiftUI animation interacting with the app's gesture system — has a direct precedent for hiding real bugs that only a physical run surfaced: M6.8's compact equalizer shipped with a `.repeatForever` animation that silently froze after a swipe gesture, caught only during physical acceptance, never by CI. `MediaMarqueeText` was not written with `.repeatForever` (it uses the same `PhaseAnimator` pattern M6.8's fix adopted), but its `GeometryReader`-based width measurement is new, untested-by-hardware code with no equivalent precedent in this codebase. If a similar issue exists (for example: measurement not settling correctly on first render, the conveyor loop stuttering, or interaction with the swipe gesture), it will currently ship to any future release undetected.

**Recommended follow-up, at the user's convenience, not blocking further work:** run the checklist above once during ordinary use with a genuinely long track title (e.g. via Yandex Music). If a problem is found, file it against this record rather than treating M6.9 as having passed a check it did not undergo.

## Automated coverage

- `NotchHubMediaCoreTests.MediaMarqueeCalculatorTests` — pure, deterministic unit tests of overflow detection and cycle-duration math. Genuinely executed and GREEN on canonical CI.
- `NotchHubCoreTests.MediaMarqueeTextPolicyTests` — source-scanning assertions (uses `PhaseAnimator`, not `Timer`/`.repeatForever`/`TimelineView`; checks `accessibilityReduceMotion`; preserves the static fallback's `.lineLimit(1)`/`.truncationMode(.tail)`; all 5 call sites converted). Genuinely executed and GREEN on canonical CI.
- Canonical CI (`Build, test and package`, `macOS 26 compatibility`, `macOS UI regression`) 3/3 GREEN on exact head `4dbea149d14c7007ecebd86905323f38f3d9b596`, including the full Swift test suite and the release size gate against real evidence in `performance/m6-9-media-marquee-text-size-budget.json`.

## Physical acceptance checklist

Full checklist definition: `docs/superpowers/specs/2026-08-22-media-marquee-text-design.md`. See "Known residual risk" above — none of these items were run.
