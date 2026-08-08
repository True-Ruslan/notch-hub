# M1 Notch interaction requirements

Status: **CORE HARDWARE ACCEPTED / TOP-EDGE REFINEMENT TARGETED RETEST PENDING**
Primary target: MacBook with hardware notch, macOS 26.6

This document is the behavioral contract for delayed hover activation, transition animation, trackpad haptic feedback, accessibility motion policy, and notch-adjacent visual behavior in M1. The implementation must follow TDD and preserve the security/performance contracts of the project.

## 1. Delayed hover activation

### Goal

Moving the pointer through the hardware-notch region on the way to another display must not immediately open NotchHub. Deliberate hover should still feel fast. On the built-in display, a deliberate pointer pushed all the way to the top screen edge over the notch must remain able to activate the panel.

### Required behavior

- Entering the compact activation region starts a **single cancellable dwell**.
- The accepted dwell is **120 ms**.
- The compact activation region is asymmetric by design:
  - **4 pt inward inset on the left**;
  - **4 pt inward inset on the right**;
  - **4 pt inward inset on the bottom**;
  - **0 pt inset on the top**.
- The top edge is intentionally unrestricted so a pointer held against the physical top screen boundary over the notch can activate NotchHub on a single-display workflow.
- The side/bottom inset still rejects accidental edge grazing.
- Cross-display transit remains protected by the cancellable 120 ms dwell rather than by removing the topmost activation band.
- The panel remains compact until the dwell threshold is reached.
- Leaving before threshold cancels immediately.
- A cancelled activation must never fire later from a stale callback.
- Re-entry starts a fresh full dwell.
- Duplicate `mouseMoved` events cannot create additional pending work.
- No activation dwell starts while the desired presentation is already expanded.
- Setup/current-pointer synchronization is non-activating; launch with the pointer already overlapping the notch must not schedule activation by itself.
- Retention/collapse behavior remains independent from activation dwell.

### Performance requirements

- Event-driven only: no polling and no repeating timer.
- At most one pending activation work item exists.
- Production scheduling uses one cancellable `DispatchWorkItem` through `DispatchQueue.main.asyncAfter`.
- Pending work is cancelled on pointer exit or invalidation.
- Unit tests use an injected deterministic scheduler and do not sleep.
- Input observation must not be broadened to implement the delay.

## 2. Interaction intent and transition ownership

Pointer intent and visual presentation are separate concerns.

`NotchInteractionCoordinator` may emit only interaction intent. It must not directly mutate SwiftUI presentation, call `NSPanel.setFrame`, animate chrome, or perform haptic output.

`NotchPanelTransitionCoordinator` is the single presentation-transition authority.

Required lifecycle phases:

- `compact`;
- `expanding`;
- `expanded`;
- `collapsing`.

Required transition behavior:

- desired presentation is independent from current animation phase;
- expanded SwiftUI content remains visible throughout collapse and switches to compact only after the matching collapse completion;
- every transition receives a new generation;
- cancellation/reversal invalidates the previous generation;
- stale completion can never settle a later state;
- expansion -> collapse and collapse -> expansion reversal are supported;
- duplicate requests for an already desired endpoint do not create duplicate transitions;
- invalidation cancels active output and makes later stale completion harmless;
- programmatic expansion is supported without haptic eligibility.

A bounded deterministic stress test must exercise at least 10,000 reversal requests while proving that only the latest generation remains authoritative and production code does not retain transition history.

## 3. Haptic feedback

### API boundary

Use only public AppKit haptics through `NSHapticFeedbackManager.defaultPerformer`.

Accepted tactile behavior: **one `.levelChange` request** per successful deliberate expansion. Do not simulate strength with repeated/double feedback.

### Exactly-once rule

Haptic feedback is eligible only when all are true:

1. an actual user mouse-move event initiated/maintained a deliberate compact hover;
2. dwell completed without cancellation;
3. the transition authority accepts a real compact -> expanded transition.

No haptic for:

- quick/cancelled transit;
- duplicate pointer movement;
- expanded retention;
- collapse;
- startup synchronization;
- programmatic expansion;
- stale dwell callbacks or stale animation completions;
- transition reversal by itself;
- Reduce Motion policy retargeting.

A reversal must not create an additional tactile hit merely because the current animation direction changes.

## 4. System animation contract

### Goal

Expansion/collapse should feel continuous without introducing a custom continuously running animation system or background work.

Accepted standard duration: **0.20 s**.
Accepted timing curve: **ease-in-out**.

### Required implementation boundary

- Window frame uses public `NSAnimationContext` / `panel.animator().setFrame(...)`.
- Backing-view corner radius uses public Core Animation `CABasicAnimation`.
- Frame and corner animation use the same duration/timing policy.
- No `CADisplayLink`, `CVDisplayLink`, repeating `Timer`, sleep loop, manual per-frame interpolation, private window API, or synthetic input.

### Reversal requirements

When an animation is cancelled/reversed:

- read the current visible corner radius from the presentation layer when available;
- commit that visible value to the model layer with implicit actions disabled;
- only then remove the old radius animation;
- invalidate the previous transition generation;
- start the new transition toward the new desired endpoint;
- ignore any later stale completion.

Physical acceptance requires both expansion -> collapse and collapse -> expansion reversal to begin from the current visible state without snap, flicker, stale endpoint, or duplicate haptic.

Headless CI can verify lifecycle/generation/model-layer contracts but cannot honestly certify compositor pixel continuity.

## 5. Reduced Motion

Public AppKit accessibility display preference is authoritative:

- normal motion duration: `0.20 s`;
- `accessibilityDisplayShouldReduceMotion == true`: duration `0`.

`NotchPanelController` observes `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification` through a selector-based observer on `NSWorkspace.notificationCenter`.

Required behavior:

- duplicate notifications that do not change the actual boolean do nothing;
- actual change retargets the currently desired presentation;
- enabling Reduce Motion during an in-flight transition reaches the desired endpoint immediately;
- this retarget produces no second haptic;
- observer teardown is explicit and idempotent at controller invalidation;
- no Accessibility permission, Input Monitoring permission, or extra entitlement is introduced.

## 6. Pointer-monitor hot path

The current approved fallback remains exactly:

- one local `.mouseMoved` monitor;
- one global `.mouseMoved` monitor;
- explicit token ownership;
- idempotent start/removal;
- no keyboard/button/drag/scroll/modifier monitoring;
- no persisted pointer history.

AppKit event-monitor callbacks run on the main thread. Production delivery must not allocate `Task { @MainActor ... }` for every mouse-move event; it uses synchronous `MainActor.assumeIsolated` delivery instead.

This optimization does not decide the future pointer-observation architecture. Replacing the global monitor with `NSTrackingArea` / window-local tracking remains a separate measured experiment and is accepted only if physical notch/cross-display correctness and target-Mac resource behavior are equal or better.

## 7. Physical notch visual contract

Required behavior on hardware-notch displays:

- compact mode is **opaque black**, not transparent;
- white indicator appears on the visible black compact panel, not directly over wallpaper;
- the black surface is clipped by the AppKit hosting-view layer;
- compact outer radius `12 pt`, expanded radius `22 pt`, continuous corner curve;
- expanded controls remain visible while the pointer intentionally holds the panel open;
- expanded interactive content begins below physical-notch occlusion with the accepted safe spacing;
- hardware-notch expanded content inset is `compactFrame.height + 12 pt`;
- no-notch fallback remains opaque with its normal 20 pt content inset;
- outer clipping has exactly one owner at the AppKit hosting-view boundary;
- the hosting view remains layer-backed, masked, and follows panel width/height;
- repeated compact <-> expanded cycles preserve rounded chrome indefinitely.

The former hardware-notch opacity `0` workaround is explicitly rejected. Visibility and rounded clipping are independent invariants.

## 8. Automated test contract

Minimum deterministic scenarios include:

1. quick transit before dwell -> no intent/haptic;
2. deliberate hover -> one eligible expansion intent at threshold;
3. duplicate movement -> one pending activation;
4. cancelled activation -> stale callback harmless;
5. re-entry -> fresh dwell;
6. expanded retention -> no new intent/haptic;
7. pointer exit -> non-haptic collapse intent;
8. setup synchronization -> no activation/haptic;
9. invalidation -> pending activation cancelled;
10. pointer only 2 pt inside the **bottom** edge is rejected;
11. pointer 4 pt inside the bottom edge is accepted;
12. pointer 1 pt below the **top screen edge** at the center of the notch is accepted with no top inset;
13. pointer only 2 pt inside the left edge remains rejected even at the top edge;
14. pointer only 2 pt inside the right edge remains rejected even at the top edge;
15. transition phase settles only on matching completion;
16. collapse retains expanded content until matching completion;
17. stale expansion completion cannot win after collapse reversal;
18. stale collapse completion cannot win after expansion reversal;
19. duplicate desired expansion does not duplicate transition/haptic;
20. programmatic expansion remains non-haptic;
21. transition invalidation makes later completion harmless;
22. Reduce Motion duration resolves to zero;
23. normal duration resolves to 0.20 s;
24. in-flight Reduce Motion retarget does not create second haptic;
25. 10,000 reversal stress keeps only latest generation authoritative;
26. zero-duration AppKit path applies exact endpoint synchronously once;
27. animated path installs system corner animation and does not complete synchronously;
28. at least 32 immediate endpoint cycles retain AppKit chrome/frame invariants;
29. cancellation freezes visible presentation-layer radius before removing animation;
30. controller source has no competing presentation `setFrame` path;
31. Reduce Motion observation uses selector ownership without a block observer token;
32. pointer-monitor live path has no per-event `Task` allocation;
33. pointer monitor still registers/removes exactly one local + one global `.mouseMoved` monitor;
34. hardware-notch compact surface remains opaque and AppKit-owned clipping remains continuous.

## 9. TDD / CI evidence — 2026-08-08

Core delayed-hover/visual evidence from earlier PR #10 work remains preserved, including RED #147/#148/#150, size rejection #157, setup-synchronization RED #165, visual policy regressions #172/#189/#196/#204, and corresponding GREEN builds.

Transition-animation hardening evidence:

- CI #225: RED before the intent-only coordinator contract existed;
- CI #231: RED before transition lifecycle/driver seams existed;
- CI #273: RED before Reduce Motion duration policy existed;
- CI #279: RED before the public AppKit animation boundary existed;
- CI #283: RED while `NotchPanelController` still owned a competing direct presentation path;
- CI #292: RED before cancellation froze the presentation-layer corner radius;
- CI #295: all functional tests/security/package checks passed but the unchanged P0 size budget failed, so no hardware candidate was issued;
- size was reduced through architecture simplification, not by widening the budget or weakening tests;
- CI #305: RED before selector-based accessibility observation replaced the block-observer/token boundary;
- CI #308: functional/security/package checks passed; executable/app returned under budget, but DMG still failed the unchanged budget;
- CI #309: RED specifically for the remaining per-mouse-event `Task` hot path while all previous 48 Swift tests passed;
- CI #310 on `12c5ff26dc409dd0391f3b296866c2be9515ce7e`: GREEN with **49/49 Swift tests**, macOS 26 compatibility, release/security/performance/package/signature/Sandbox/Hardened Runtime/DMG checks, performance harness smoke, and the unchanged P0 artifact-size budget;
- clean exact-head CI #319 on `f6de06f5d045fc9375b3b31b0a7feb97a13cebe4` produced the hardware candidate subsequently accepted for all broad interaction/visual/animation/motion checks;
- RED commit `f4d19fc7e508fe11a35aae6fb56f80e0fa7ec13e` / CI #320 added asymmetric activation-edge coverage and failed only the new top-edge activation expectation while all 51 other Swift tests stayed green;
- GREEN source `c7c10033d223197309eafeba63e67b30ae29ba33` / CI #321 passed **52/52 Swift tests** and all release/security/performance/package gates with the unchanged P0 budget.

CI #321 sizes:

- executable `250,000 B`;
- app `252,997 B`;
- DMG `84,468 B`.

Shared-runner CPU/RSS/thread values are compatibility/schema evidence only, never target-Mac performance acceptance.

## 10. Real-hardware acceptance

Broad target-Mac acceptance on exact candidate `f6de06f5d045fc9375b3b31b0a7feb97a13cebe4` / CI #319:

- `NH-NOTCH-001`: **PASS**.
- `NH-HOVER-001/002/003`: **PASS**.
- `NH-HOVER-DELAY-001`: **PASS** for quick cross-display transit.
- `NH-HOVER-DELAY-002`: **PASS**; 120 ms accepted.
- `NH-HAPTIC-001/002`: **PASS**; `.levelChange` accepted.
- `NH-VISUAL-001/002/003`: **PASS**.
- `NH-ANIM-001/002/003/004`: **PASS**.
- `NH-MOTION-001/002`: **PASS**.
- startup while pointer already overlaps the notch: **PASS**.
- physical tuning accepted: 120 ms dwell, 0.20 s animation, `.levelChange`, 4 pt protection on the edges where protection is desired.

The only post-acceptance product refinement is asymmetric top-edge activation. New stable physical gate:

- `NH-HOVER-TOP-001`: on the built-in display, deliberately push/hold the pointer against the top screen edge over the notch. It must remain eligible and open once after 120 ms with one haptic and no oscillation. Left/right/bottom still use 4 pt inward protection.

Because removing the top inset restores a 4 pt-high activation band, `NH-HOVER-DELAY-001` must be rerun once on the new exact artifact to confirm quick cross-display transit remains compact/no haptic. No other broad hardware checks need repeating unless either targeted scenario fails.

## 11. Definition of done

This interaction/animation slice is complete only when:

- deterministic RED-first suite remains green;
- exact clean head passes all release/security/performance/package gates;
- unchanged P0 size budget passes;
- runtime remains event-driven and cancellation-safe;
- no permissions/entitlements/input surface are broadened;
- broad physical acceptance remains recorded as PASS;
- new `NH-HOVER-TOP-001` passes on the exact asymmetric-inset candidate;
- `NH-HOVER-DELAY-001` remains PASS on that same candidate;
- final accepted geometry is recorded as **4 pt left/right/bottom, 0 pt top**, with 120 ms dwell, `.levelChange`, and 0.20 s animation.

Until the two targeted physical checks pass, PR #10 remains Draft and unmerged.
