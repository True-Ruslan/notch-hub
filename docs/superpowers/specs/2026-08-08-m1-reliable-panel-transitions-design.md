# M1 Reliable Panel Transitions — Design

Status: **DESIGN DECISIONS APPROVED; WRITTEN SPEC AWAITING FINAL USER REVIEW**  
Date: 2026-08-08  
Scope: Notch Core interaction/presentation hardening for PR #10

## 1. Context

The first M1 implementation established delayed hover activation, haptic feedback, explicit pointer-monitor lifecycle, AppKit-owned clipping, compact opacity, and target-Mac geometry fixes. Real hardware testing then exposed an architectural weakness: individual end-state invariants could be correct while the transition between those states regressed.

Observed failures included:

- expanded controls becoming hidden or appearing at the wrong point in the lifecycle;
- rounded chrome degrading to square after repeated cycles;
- a compact surface becoming transparent while fixing physical-notch corner leakage;
- smooth opening being lost after moving from `setFrame(..., animate: true)` to an immediate frame change.

The root problem is not one missing animation flag. Presentation ownership is split across model state, SwiftUI content, AppKit window geometry, and AppKit/Core Animation clipping. Tests currently prove many final states but do not make the whole `compact -> expanded -> compact` transition an explicit, deterministic contract.

M1 must therefore treat transition lifecycle, interruption, cancellation, accessibility behavior, and repeated-cycle stability as first-class correctness properties.

## 2. Goals

1. Restore the smooth opening/closing character of the original accepted M0 behavior without reintroducing the previously observed content/frame desynchronization.
2. Make one component the authority for transition lifecycle.
3. Make rapid hover/leave/re-entry behavior deterministic and reversible.
4. Preserve the accepted delayed-hover and haptic semantics.
5. Preserve opaque black compact chrome and stable rounded clipping on real hardware.
6. Follow public Apple AppKit/Core Animation/accessibility APIs and macOS interaction conventions.
7. Keep the runtime event-driven: no polling, repeating timers, custom frame loops, or display links.
8. Expand automated coverage from end states to transition sequencing, interruption, stale completion, accessibility policy, and repeated-cycle stability.
9. Preserve the existing security, privacy, entitlement, dependency, and P0 performance boundaries.

## 3. Non-goals

This redesign does **not** implement Shelf, Snippets, Calendar, Translate, Yandex Music, multi-monitor migration policy, Spaces/fullscreen policy, gestures, pinning, or final visual product polish.

It also does not introduce:

- private notch APIs;
- `CGEventTap`;
- Accessibility or Input Monitoring permission requirements;
- synthetic input;
- custom haptic drivers;
- `Timer`-driven animation;
- polling or repeating scheduling;
- display-link animation loops;
- third-party runtime dependencies.

## 4. Apple-native platform contract

NotchHub must be native in implementation as well as appearance.

### 4.1 Notch geometry

Hardware-notch geometry continues to come only from public `NSScreen` APIs:

- `safeAreaInsets`;
- `auxiliaryTopLeftArea`;
- `auxiliaryTopRightArea`.

No model-identifier notch tables or private APIs are allowed.

Apple references:

- https://developer.apple.com/documentation/appkit/nsscreen/safeareainsets
- https://developer.apple.com/documentation/appkit/nsscreen/auxiliarytopleftarea
- https://developer.apple.com/documentation/appkit/nsscreen/auxiliarytoprightarea

### 4.2 Window animation

The production animation driver must use the normal AppKit animation stack, with `NSAnimationContext` and animatable AppKit properties / animator proxies where applicable. The system compositor owns interpolation and frame production; NotchHub owns only state, target geometry, cancellation/reversal intent, and completion validation.

The initial motion candidate should match the former accepted feel: approximately **0.20 s** with a normal ease-in-out timing curve. The exact duration remains a target-Mac tuning value, not a magic correctness constant.

Apple references:

- https://developer.apple.com/documentation/appkit/nsanimationcontext
- https://developer.apple.com/documentation/appkit/nsanimationcontext/timingfunction
- https://developer.apple.com/documentation/appkit/nsanimationcontext/completionhandler

A critical implementation fact is that an `NSAnimationContext` completion handler may run after animations have completed **or been cancelled**. Therefore completion invocation itself is never proof that its transition is still authoritative.

### 4.3 Reduce Motion

`NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` is an input to animation policy. Changes must be observed through `NSWorkspace` accessibility display option notifications, using the workspace notification center required by AppKit.

When Reduce Motion is active, the same state machine and sequencing rules remain in force, but the geometry transition uses an immediate or materially reduced-motion driver. There must not be a second behavioral architecture for accessibility mode.

Apple references:

- https://developer.apple.com/documentation/appkit/nsworkspace/accessibilitydisplayshouldreducemotion
- https://developer.apple.com/documentation/appkit/nsworkspace/accessibilitydisplayoptionsdidchangenotification

### 4.4 Reduce Transparency

The current black opaque surface already avoids a transparency dependency. Future material/blur work must honor `accessibilityDisplayShouldReduceTransparency`; this redesign must not make reliable presentation depend on transparency effects.

Reference:

- https://developer.apple.com/documentation/appkit/nsworkspace/accessibilitydisplayshouldreducetransparency

### 4.5 Haptic

Haptic feedback stays on the public AppKit boundary through `NSHapticFeedbackManager.defaultPerformer`. The default performer must be requested when feedback is needed rather than permanently captured as an assumed device, because AppKit chooses it using the current input device, accessibility settings, and user preferences.

The current `.levelChange` pattern remains the physical-feel candidate until target-Mac acceptance. A successful deliberate expansion requests exactly one feedback event. Cancelled transit, retention, collapse, programmatic/setup transitions, stale completions, and duplicate events request none.

The production performer should use an AppKit synchronization time such as `.default` so the system can align feedback with the next visual update instead of creating an application-managed timing loop.

Apple references:

- https://developer.apple.com/documentation/appkit/nshapticfeedbackmanager/defaultperformer
- https://developer.apple.com/documentation/appkit/nshapticfeedbackmanager/performancetime

## 5. Architecture

### 5.1 Single transition authority

Introduce a dedicated `NotchPanelTransitionCoordinator` as the only owner of panel transition lifecycle.

It owns:

- current transition phase;
- desired presentation;
- transition generation/token;
- animation policy;
- sequencing of content preparation, AppKit mask/chrome, panel geometry, haptic emission, and final content settlement;
- validation of animation completions;
- transition invalidation on teardown.

It does **not** own pointer detection, notch geometry calculation, SwiftUI module content, or low-level AppKit animation mechanics.

### 5.2 Bounded collaborators

The design separates responsibilities into small units:

- `NotchInteractionCoordinator`: decides user intent, including dwell/cancellation and whether an expansion intent is haptic-eligible. It does not directly animate the window or emit transition haptics.
- `NotchInteractionIntent` (conceptual contract): carries desired presentation and cause/eligibility metadata such as deliberate hover versus pointer exit or programmatic synchronization. The implementation may choose a different concrete name, but this information must cross the boundary explicitly rather than being inferred later from mutable state.
- `NotchPanelTransitionCoordinator`: converts interaction intent into a safe transition lifecycle and is the sole authority that may emit the transition haptic after accepting an eligible expansion.
- `NotchPanelAnimationDriver`: thin AppKit boundary that starts/cancels/re-targets system window/chrome animations and reports completion.
- `NotchAnimationPolicy`: derives duration/timing/reduced-motion behavior from system accessibility state.
- `NotchPanelChrome`: applies outer layer masking/radius under transition-coordinator direction; it is not an independent presentation authority.
- `NotchPanelController`: composition/orchestration of AppKit objects only; it must no longer contain independent presentation logic.
- `NotchPanelModel` / SwiftUI view state: exposes the content mode required by the transition coordinator rather than directly commanding window geometry.

The goal is that changing one collaborator's internals does not silently create a second presentation owner.

## 6. State model

Stable states:

- `compact`
- `expanded`

Transition phases:

- `expanding`
- `collapsing`

The coordinator also tracks `desiredPresentation` independently from phase.

This distinction is mandatory. During an in-flight animation, incoming pointer events update desired intent; they do not pretend the window has already reached an endpoint.

Conceptually:

```text
compact --intent expand--> expanding --valid completion--> expanded
expanded --intent compact--> collapsing --valid completion--> compact

expanding --intent compact--> collapsing
collapsing --intent expand--> expanding
```

Every new transition/reversal increments a monotonically increasing generation.

## 7. Transition sequencing

### 7.1 Expansion

For a successful deliberate expansion:

1. Dwell has completed and the interaction layer emits an expansion intent marked haptic-eligible.
2. Transition coordinator accepts the intent, establishes desired presentation = expanded, and invalidates any older transition generation.
3. Phase becomes `expanding`.
4. Expanded content is prepared before growth, but the AppKit window/chrome remains the clipping authority so controls cannot escape the current visible panel bounds.
5. The frame target and chrome target are submitted as one coordinated system transition. Corner shape must not jump independently before or after window geometry.
6. The animation driver starts the public AppKit transition toward `expandedFrame` using the current animation policy.
7. The transition coordinator requests exactly one haptic for this accepted deliberate expansion through the public AppKit performer, using system visual synchronization rather than an application timing loop.
8. Completion validates both generation and desired presentation.
9. Only a valid completion settles phase/content as `expanded`.

An invalid/stale completion performs no mutation.

### 7.2 Collapse

For collapse:

1. Desired presentation becomes compact.
2. Coordinator invalidates any older transition generation.
3. Phase becomes `collapsing`.
4. Expanded content remains installed while the window shrinks; it must not disappear at transition start.
5. Frame and chrome changes participate in one coordinated system transition so corner shape and window size cannot visibly disagree.
6. The AppKit clipping boundary naturally hides content as visible bounds shrink.
7. Animation driver targets `compactFrame`.
8. Completion validates generation and desired presentation.
9. Only a valid completion switches final content to compact and settles phase = `compact`.

This sequencing prevents the observed class of bug where content changes immediately while panel geometry is still in another state.

## 8. Interruption and reversal semantics

Rapid pointer changes are normal input, not an error case.

### 8.1 Leave during expansion

If desired presentation changes to compact while phase is `expanding`:

- the expansion generation becomes stale;
- a collapse transition starts without snapping through a nominal endpoint;
- the visible panel and its chrome must reverse smoothly from current on-screen progress;
- the old expansion completion is harmless even if AppKit later invokes it;
- no second haptic is emitted.

### 8.2 Re-enter during collapse

If a new haptic-eligible deliberate expansion intent arrives while phase is `collapsing`:

- collapse generation becomes stale;
- expansion is re-targeted from the current visible state;
- old collapse completion is ignored;
- exactly one haptic may be emitted for this newly accepted deliberate expansion intent, never because a stale completion fired.

### 8.3 AppKit feasibility gate

The implementation must demonstrate that the chosen AppKit animator path can re-target/reverse both geometry and chrome without a visible snap on the target Mac. Nominal `NSWindow.frame` values must not be treated as proof of current on-screen animation progress if AppKit has already committed a target value internally.

If the selected AppKit API cannot provide reliable smooth reversal, implementation must stop and return to design rather than hide the issue with timers, manual frame stepping, or relaxed acceptance criteria.

This is a hard reliability gate.

## 9. Chrome and content ownership

### 9.1 Outer shape

The real AppKit hosting/window boundary remains the single owner of the outer clipping mask.

Required invariants:

- layer-backed hosting surface;
- `masksToBounds = true`;
- continuous corner curve;
- compact radius candidate `12 pt`;
- expanded radius candidate `22 pt`;
- radius participates in the same system transition lifecycle as frame geometry rather than jumping as an unrelated state update;
- mask/radius explicitly valid in every transition phase and after repeated cycles;
- no competing SwiftUI outer `clipShape` authority.

The exact public AppKit/Core Animation mechanism for synchronizing radius with frame is an implementation detail subject to the reversal feasibility gate. It must not require a manual per-frame loop.

### 9.2 Background

Compact hardware-notch mode is opaque black. The white indicator appears on black, not directly on wallpaper.

Fixing corner leakage must never be done by making the whole compact surface transparent again.

### 9.3 Expanded controls

Expanded content must start below physical notch occlusion. The current candidate remains `compactFrame.height + 12 pt` on hardware-notch screens and `20 pt` on no-notch fallback screens until further product tuning.

Controls must be visible during active expanded hover, not only after pointer exit.

## 10. Lifecycle and teardown

All transition/UI mutation remains on `@MainActor`.

On controller invalidation/application termination:

- pending dwell is cancelled;
- pointer monitors are removed;
- current animation generation is invalidated;
- active animation driver work is cancelled or made harmless;
- any later completion callback sees a stale generation and performs no state/content/chrome mutation;
- no haptic is generated by teardown.

Repeated start/invalidate remains idempotent.

## 11. Performance and energy contract

The transition redesign must remain event-driven.

Forbidden for production transition logic:

- polling;
- repeating `Timer`;
- `CADisplayLink`/`CVDisplayLink` animation loops;
- sleep loops;
- manual per-frame geometry or corner-radius updates;
- retained pointer/animation history that grows with use.

System AppKit/Core Animation performs interpolation.

Existing P0 executable/app/DMG budgets are not widened merely to fit the redesign. Runtime CPU/RSS/thread/wakeup behavior on the target Mac must be no worse than the accepted boundaries without explicit evidence and review.

The local/global `.mouseMoved` tracking question remains a separate measured M1 follow-up; this redesign must not broaden event masks or permissions.

## 12. Security and privacy contract

This change must preserve:

- App Sandbox;
- Hardened Runtime;
- exact existing entitlement boundary;
- system-library-only runtime linkage;
- zero third-party runtime dependencies;
- no network/process/plugin surface;
- no pointer history persistence;
- no Accessibility/Input Monitoring permission request;
- no private APIs or synthetic input.

Animation reliability is not a justification for expanding the attack surface.

## 13. Testing strategy

The previous test strategy was insufficient because it concentrated on endpoint correctness. M1 now requires four explicit layers.

### 13.1 Pure transition state-machine tests

Deterministically cover at minimum:

- `compact -> expanding -> expanded`;
- `expanded -> collapsing -> compact`;
- leave during expansion;
- re-enter during collapse;
- multiple rapid reversals;
- duplicate desired-state updates;
- haptic-eligible versus non-haptic interaction intents;
- stale expansion completion;
- stale collapse completion;
- invalidation during expansion;
- invalidation during collapse;
- no completion may mutate state after invalidation.

No wall-clock sleeps are allowed in these tests.

### 13.2 Fake animation-driver and output tests

The fake animation driver records transition commands and exposes completion manually. Fake chrome/content/haptic outputs record exact order without invoking hardware.

Tests must prove exact operation order for:

- interaction intent acceptance;
- content preparation;
- phase change;
- coordinated chrome/frame target preparation;
- geometry animation request;
- exactly-once haptic request for eligible expansion;
- valid completion settlement;
- collapse content retention until completion;
- reversal and generation replacement;
- deliberate completion of stale transitions with zero effect;
- Reduce Motion immediate/reduced driver behavior.

### 13.3 Real AppKit boundary tests

Use real AppKit objects on CI where feasible to prove:

- hosting view follows panel bounds in width and height;
- compact black background policy remains opaque;
- mask/radius remains enabled in compact, expanding, expanded, and collapsing phases;
- repeated transitions do not lose `masksToBounds` or endpoint corner radii;
- at least 32 deterministic presentation cycles remain stable;
- controller invalidation leaves no transition authority active.

These tests validate AppKit object state and transaction setup, not subjective animation smoothness.

### 13.4 Target-Mac acceptance

Only hardware/visual facts that CI cannot honestly prove remain manual:

- perceived smoothness and absence of stutter;
- no flash/snap during normal opening/closing;
- no visible corner-radius jump relative to frame motion;
- no snap during reversal;
- real physical-notch alignment/shape;
- actual haptic feel on compatible trackpad;
- cross-display transit behavior;
- 20+ real open/collapse cycles with stable chrome.

Manual acceptance is evidence, not a substitute for deterministic tests.

## 14. Stable acceptance matrix

| ID | Requirement | Automated evidence | Target-Mac evidence |
| --- | --- | --- | --- |
| `NH-TRANSITION-001` | Normal expansion follows `compact -> expanding -> expanded` and settles only after valid completion | State machine + fake driver | Smooth opening, no flash |
| `NH-TRANSITION-002` | Normal collapse preserves expanded content until completion | State machine + operation-order test | Smooth closing, no early content disappearance |
| `NH-TRANSITION-003` | Leave during expansion reverses without stale completion winning | Generation/reversal tests | No visible snap |
| `NH-TRANSITION-004` | Re-enter during collapse reverses without stale completion winning | Generation/reversal tests | No visible snap |
| `NH-TRANSITION-005` | Rapid repeated intent changes converge to latest desired state without oscillation | Stress/state-machine tests | No flicker/oscillation |
| `NH-TRANSITION-006` | Reduce Motion preserves state semantics with reduced/immediate movement | Policy + fake-driver tests | Matches system preference |
| `NH-TRANSITION-007` | Frame geometry and corner chrome evolve as one transition lifecycle | Transaction/order tests | No radius jump or geometry/chrome mismatch |
| `NH-VISUAL-001` | Compact surface is black and rounded; indicator is not directly on wallpaper | Background/chrome tests | Physical-notch visual PASS |
| `NH-VISUAL-002` | Expanded controls stay below notch and visible during active hover | Geometry/content-order tests | Real layout PASS |
| `NH-VISUAL-003` | Rounded chrome survives repeated cycles | 32-cycle AppKit regression | At least 20 real cycles PASS |
| `NH-HOVER-DELAY-001` | Fast transit does not expand | Existing deterministic dwell test | Cross-display transit PASS |
| `NH-HOVER-DELAY-002` | Deliberate dwell expands | Existing deterministic dwell test | 120 ms candidate feels correct |
| `NH-HAPTIC-001` | Exactly one public AppKit haptic for accepted deliberate expansion | Intent + fake performer count/order | Physical feedback PASS |
| `NH-HAPTIC-002` | No haptic on cancel/retention/collapse/setup/stale paths | Negative-path tests | Physical negative-path PASS |

Existing `NH-NOTCH-001` and `NH-HOVER-001/002/003` remain regression gates and must continue to pass.

## 15. Reliability rule for future stateful UI

The project adopts this engineering invariant:

> A stateful UI change is not GREEN merely because its endpoint states are correct. Transition, interruption, cancellation, stale-callback behavior, repeated-cycle stability, accessibility policy, and teardown must be tested when they are part of the observable behavior.

Hardware regressions follow a second invariant:

> Every reproducible hardware regression receives a stable acceptance ID and the closest honest automated regression test before production code is changed.

These rules exist specifically to prevent the pattern "fix A, silently break B".

## 16. Implementation boundary and sequence

After this written spec is explicitly approved, implementation planning should decompose the work into RED-first increments:

1. transition state model and deterministic coordinator contract;
2. explicit interaction-intent/haptic-eligibility boundary;
3. fake animation driver and stale-completion/reversal tests;
4. accessibility animation policy and notification lifecycle;
5. production AppKit animation driver feasibility/reversal proof;
6. coordinated AppKit frame + chrome transition integration;
7. controller migration so it no longer independently owns presentation transitions;
8. real AppKit repeated-cycle tests;
9. full security/performance/package CI;
10. target-Mac acceptance of transition/visual/haptic gates;
11. only after acceptance, PR #10 may become merge-ready.

The implementation must return to design review if the chosen public AppKit animation mechanism cannot meet smooth interruption/reversal without custom frame loops or broadened system permissions.
