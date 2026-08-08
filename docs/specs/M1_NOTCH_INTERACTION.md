# M1 Notch interaction requirements

Status: **CURRENT INTERACTION / TRANSITION SLICE HARDWARE ACCEPTED**
Primary target: MacBook with hardware notch, macOS 26.6

This document is the behavioral contract for delayed hover activation, transition animation, trackpad haptic feedback, accessibility motion policy, and notch-adjacent visual behavior in M1. The implementation must follow TDD and preserve the security/performance contracts of the project.

## 1. Delayed hover activation

### Goal

Moving the pointer through the hardware-notch region on the way to another display must not immediately open NotchHub. Deliberate hover should still feel fast. On the built-in display, a deliberate pointer pushed all the way to the exact top screen edge over the notch must remain able to activate the panel.

### Required behavior

- Entering the compact activation region starts a **single cancellable dwell**.
- The accepted dwell is **120 ms**.
- The compact activation region is asymmetric by design:
  - **4 pt inward inset on the left**;
  - **4 pt inward inset on the right**;
  - **4 pt inward inset on the bottom**;
  - **0 pt inset on the top**.
- Boundary semantics are explicit and inclusive for accepted compact edges:
  - `pointer.x >= compactFrame.minX + 4`;
  - `pointer.x <= compactFrame.maxX - 4`;
  - `pointer.y >= compactFrame.minY + 4`;
  - `pointer.y <= compactFrame.maxY`.
- The exact top edge `pointer.y == compactFrame.maxY` is intentionally eligible. Compact activation must not delegate this contract to `CGRect.contains`, whose maximum-edge semantics do not match the product requirement.
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
11. pointer exactly 4 pt inside the bottom edge is accepted;
12. pointer at the **exact top screen edge** (`y == compactFrame.maxY`) at notch center is accepted with no top inset;
13. pointer only 2 pt inside the left edge remains rejected at the exact top edge;
14. pointer exactly 4 pt inside the left edge is accepted at the exact top edge;
15. pointer only 2 pt inside the right edge remains rejected at the exact top edge;
16. pointer exactly 4 pt inside the right edge is accepted at the exact top edge;
17. transition phase settles only on matching completion;
18. collapse retains expanded content until matching completion;
19. stale expansion completion cannot win after collapse reversal;
20. stale collapse completion cannot win after expansion reversal;
21. duplicate desired expansion does not duplicate transition/haptic;
22. programmatic expansion remains non-haptic;
23. transition invalidation makes later completion harmless;
24. Reduce Motion duration resolves to zero;
25. normal duration resolves to 0.20 s;
26. in-flight Reduce Motion retarget does not create second haptic;
27. 10,000 reversal stress keeps only latest generation authoritative;
28. zero-duration AppKit path applies exact endpoint synchronously once;
29. animated path installs system corner animation and does not complete synchronously;
30. at least 32 immediate endpoint cycles retain AppKit chrome/frame invariants;
31. cancellation freezes visible presentation-layer radius before removing animation;
32. controller source has no competing presentation `setFrame` path;
33. Reduce Motion observation uses selector ownership without a block observer token;
34. pointer-monitor live path has no per-event `Task` allocation;
35. pointer monitor still registers/removes exactly one local + one global `.mouseMoved` monitor;
36. hardware-notch compact surface remains opaque and AppKit-owned clipping remains continuous.

A test named for a physical edge must use that exact coordinate. `maxY - 1` is an interior-point test and cannot stand in for the top screen edge.

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
- RED `f4d19fc7e508fe11a35aae6fb56f80e0fa7ec13e` / CI #320 established asymmetric activation geometry;
- GREEN `c7c10033d223197309eafeba63e67b30ae29ba33` / CI #321 passed **52/52 Swift tests**;
- clean exact-head `969a7c52203adf7e3dd8bb5f198a6895b2fb7f7a` / CI #325 passed every automated gate, but its target-Mac `NH-HOVER-TOP-001` **FAILED** because the test had modeled `maxY - 1` instead of exact `maxY`;
- RED `3d0d40b5426cb8a8fe0bd19393688a68247637b0` / CI #326 corrected the test model and failed only three new exact-boundary expectations out of 54 tests;
- GREEN `9022ab55221070b4899853fffd3dc6709384ab1b` / CI #327 replaced compact `CGRect.contains` with explicit inclusive directional bounds and passed **54/54 Swift tests** plus all release/security/performance/package/signature/Sandbox/Hardened Runtime/DMG gates and the unchanged P0 size budget;
- clean exact-head CI #332 on `6d4c13739216503ec97fe3e71eada0fc9b32f298` passed both jobs and produced artifact `9022551570`, which then passed the two remaining target-Mac gates `NH-HOVER-TOP-001` and `NH-HOVER-DELAY-001`.

CI #332 deterministic sizes:

- executable `250,320 B`;
- app `253,317 B`;
- DMG `84,689 B`.

Shared-runner CPU/RSS/thread values are compatibility/schema evidence only, never target-Mac performance acceptance.

## 10. Real-hardware acceptance

Broad target-Mac acceptance on exact candidate `f6de06f5d045fc9375b3b31b0a7feb97a13cebe4` / CI #319:

- `NH-NOTCH-001`: **PASS**.
- `NH-HOVER-001/002/003`: **PASS**.
- `NH-HOVER-DELAY-002`: **PASS**; 120 ms accepted.
- `NH-HAPTIC-001/002`: **PASS**; `.levelChange` accepted.
- `NH-VISUAL-001/002/003`: **PASS**.
- `NH-ANIM-001/002/003/004`: **PASS**.
- `NH-MOTION-001/002`: **PASS**.
- startup while pointer already overlaps the notch: **PASS**.
- physical tuning accepted: 120 ms dwell, 0.20 s animation, `.levelChange`, 4 pt side/bottom protection.

Post-acceptance top-edge history:

- `NH-HOVER-TOP-001` on CI #325 artifact: **FAIL** — exact physical top edge did not activate;
- the failure invalidated the previous nearby-point automation as evidence for this exact boundary;
- corrective CI #326/#327 tests and implements exact inclusive `maxY` semantics;
- exact corrected CI #332 artifact `9022551570`: `NH-HOVER-TOP-001` **PASS**;
- the same artifact: `NH-HOVER-DELAY-001` **PASS**, proving quick cross-display transit remains protected.

Final accepted compact activation geometry is therefore **inclusive 4 pt left/right/bottom and inclusive 0 pt top**, with accepted `120 ms` dwell, `.levelChange` haptic, and `0.20 s` system animation.

## 11. Definition of done

The current interaction/animation slice is complete when:

- deterministic RED-first suite remains green;
- exact clean head passes all release/security/performance/package gates;
- unchanged P0 size budget passes;
- runtime remains event-driven and cancellation-safe;
- no permissions/entitlements/input surface are broadened;
- broad physical acceptance remains recorded as PASS;
- corrected exact-edge `NH-HOVER-TOP-001` passes on target hardware;
- `NH-HOVER-DELAY-001` remains PASS on that same candidate;
- final accepted geometry is recorded as **inclusive 4 pt left/right/bottom, inclusive 0 pt top**, with 120 ms dwell, `.levelChange`, and 0.20 s animation.

All physical requirements above are now satisfied on the exact CI #332 artifact. Acceptance-record changes after that source are documentation-only; one final exact-head CI is required before PR integration, with no further physical retest unless production source changes.
