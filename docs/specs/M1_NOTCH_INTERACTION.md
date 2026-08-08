# M1 Notch interaction requirements

Status: **DETERMINISTIC IMPLEMENTATION COMPLETE / CLEAN EXACT-HEAD CI AND HARDWARE ACCEPTANCE PENDING**
Primary target: MacBook with hardware notch, macOS 26.6

This document is the behavioral contract for delayed hover activation, transition animation, trackpad haptic feedback, accessibility motion policy, and notch-adjacent visual behavior in M1. The implementation must follow TDD and preserve the security/performance contracts of the project.

## 1. Delayed hover activation

### Goal

Moving the pointer through the hardware-notch region on the way to another display must not immediately open NotchHub. Deliberate hover should still feel fast.

### Required behavior

- Entering the compact activation region starts a **single cancellable dwell**.
- The activation region is slightly inset from the physical notch bounding box so grazing the edge is not deliberate intent.
- Current inset candidate: **4 pt** on each edge.
- Current dwell candidate: **120 ms**.
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

Current tactile candidate: **one `.levelChange` request** per successful deliberate expansion. Do not simulate strength with repeated/double feedback.

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

Current standard-duration candidate: **0.20 s**.
Current timing curve: **ease-in-out**.

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

- normal motion duration: `0.20 s` candidate;
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
- current hardware-notch expanded content inset is `compactFrame.height + 12 pt`;
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
10. 2 pt edge depth rejected, 4 pt candidate accepted;
11. transition phase settles only on matching completion;
12. collapse retains expanded content until matching completion;
13. stale expansion completion cannot win after collapse reversal;
14. stale collapse completion cannot win after expansion reversal;
15. duplicate desired expansion does not duplicate transition/haptic;
16. programmatic expansion remains non-haptic;
17. transition invalidation makes later completion harmless;
18. Reduce Motion duration resolves to zero;
19. normal duration resolves to 0.20 s;
20. in-flight Reduce Motion retarget does not create second haptic;
21. 10,000 reversal stress keeps only latest generation authoritative;
22. zero-duration AppKit path applies exact endpoint synchronously once;
23. animated path installs system corner animation and does not complete synchronously;
24. at least 32 immediate endpoint cycles retain AppKit chrome/frame invariants;
25. cancellation freezes visible presentation-layer radius before removing animation;
26. controller source has no competing presentation `setFrame` path;
27. Reduce Motion observation uses selector ownership without a block observer token;
28. pointer-monitor live path has no per-event `Task` allocation;
29. pointer monitor still registers/removes exactly one local + one global `.mouseMoved` monitor;
30. hardware-notch compact surface remains opaque and AppKit-owned clipping remains continuous.

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
- CI #310 on `12c5ff26dc409dd0391f3b296866c2be9515ce7e`: GREEN with **49/49 Swift tests**, macOS 26 compatibility, release/security/performance/package/signature/Sandbox/Hardened Runtime/DMG checks, performance harness smoke, and the unchanged P0 artifact-size budget.

CI #310 sizes:

- executable `250,000 B`;
- app `252,997 B`;
- DMG `84,422 B`.

Temporary release-symbol diagnostics used only to attribute size were removed afterward. A fresh clean exact-head CI after documentation is required before hardware acceptance.

Shared-runner CPU/RSS/thread values are compatibility/schema evidence only, never target-Mac performance acceptance.

## 10. Real-hardware acceptance

Stable existing IDs:

- `NH-NOTCH-001`: compact center/width match physical notch.
- `NH-HOVER-001`: deliberate hover expands once without oscillation.
- `NH-HOVER-002`: movement inside expanded retention remains expanded.
- `NH-HOVER-003`: leaving retention collapses once and stays compact.
- `NH-HOVER-DELAY-001`: normal cross-display transit stays compact with zero haptic.
- `NH-HOVER-DELAY-002`: deliberate hover opens once after accepted dwell/depth threshold.
- `NH-HAPTIC-001`: eligible expansion produces exactly one acceptable physical haptic.
- `NH-HAPTIC-002`: cancelled transit/retention/collapse remain physically silent.
- `NH-VISUAL-001`: compact black rounded panel is visible/aligned with no square leakage.
- `NH-VISUAL-002`: expanded primary controls remain visible below the notch while held open.
- `NH-VISUAL-003`: at least 20 physical open/collapse cycles retain rounded chrome.

Additional animation/accessibility checks for this hardening slice:

- normal expansion is visibly smooth;
- normal collapse is visibly smooth;
- expansion -> collapse reversal starts at the current visible state with no snap/flicker/stale endpoint and no extra haptic;
- collapse -> expansion reversal behaves likewise;
- repeated rapid hover/leave does not leave the panel stuck;
- Reduce Motion enabled before a transition produces an immediate endpoint;
- switching Reduce Motion during an in-flight transition immediately reaches the desired endpoint without duplicate haptic/flicker;
- startup with cursor already over the notch remains non-activating.

If public AppKit window animation visibly snaps on physical hardware, this is a hard failure. Do not replace the failed behavior with a timer/display link/private API merely to satisfy the test matrix.

## 11. Definition of done

This interaction/animation slice is complete only when:

- deterministic RED-first suite remains green;
- exact clean head passes all release/security/performance/package gates;
- unchanged P0 size budget passes;
- runtime remains event-driven and cancellation-safe;
- no permissions/entitlements/input surface are broadened;
- physical acceptance above passes on target MacBook/macOS 26.6;
- final accepted/tuned `120 ms`, `4 pt`, `.levelChange`, and `0.20 s` candidates are recorded in project state/testing/changelog.

Until then PR #10 remains Draft and unmerged.
