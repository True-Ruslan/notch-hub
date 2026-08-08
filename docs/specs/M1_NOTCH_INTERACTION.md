# M1 Notch interaction requirements

Status: **IMPLEMENTED IN PR #10 / HARDWARE ACCEPTANCE PENDING**
Primary target: MacBook with hardware notch, macOS 26.6

This document is the behavioral contract for delayed hover activation and trackpad haptic feedback in M1. The implementation must follow TDD and preserve the security/performance contracts of the project.

The deterministic implementation exists in PR #10. This status does **not** mark the interaction work accepted: the final dwell value and physical haptic/cross-display behavior remain subject to the real-hardware Definition of Done below.

## 1. Delayed hover activation

### Goal

Moving the pointer through the hardware-notch region on the way to another display must not immediately open NotchHub. Deliberate hover should still feel fast.

### Required behavior

- Entering the compact activation region starts a **single cancellable dwell**.
- The panel remains compact until the dwell threshold is reached.
- Leaving the activation region before the threshold cancels the pending activation immediately.
- A cancelled activation must never fire later because of a stale callback/race.
- Re-entering after cancellation starts a fresh dwell.
- Duplicate `mouseMoved` events while one dwell is pending must not create additional timers/tasks.
- No activation dwell is started while the panel is already expanded.
- Retention/collapse behavior remains independent from the activation dwell.

### Initial timing

The initial candidate is **120 ms**, with a tuning range around **100–150 ms** after real-hardware measurement. This is intentionally not a 2–5 ms delay: such a delay is too small to reliably distinguish deliberate hover from a normal cross-screen pointer transit.

The threshold must be represented by a named policy/configuration value, not scattered as a magic number.

### Performance requirements

- Event-driven only: no polling and no repeating timer.
- At most one pending activation task/timer may exist.
- Pending work is cancelled on pointer exit, state invalidation, or controller teardown.
- The implementation must not broaden input observation beyond what is already security-approved merely to implement the delay.
- Tests must use an injected clock/scheduler or equivalent deterministic abstraction; unit tests must not use arbitrary real sleeps.

## 2. Haptic feedback on successful expansion

### Goal

When a deliberate hover actually expands the panel, the Force Touch trackpad should provide a short tactile confirmation similar to native macOS interactions.

### API and safety boundary

Use the public AppKit haptics API through `NSHapticFeedbackManager.defaultPerformer`. The performer is requested when feedback is needed so macOS can respect the current input device, accessibility/user preferences, and hardware availability.

The initial candidate feedback pattern is the general-purpose AppKit haptic (`.generic`). Timing should be synchronized with the actual visual state transition; exact pattern/timing may be tuned only from real-hardware UX evidence.

Do not implement custom low-level trackpad drivers, private haptic APIs, synthetic input, Accessibility tricks, audio imitation, or background haptic loops.

### Required behavior

Haptic feedback is emitted **exactly once** when all conditions are true:

1. activation was initiated by the user's pointer entering/remaining in the compact notch activation region;
2. the dwell threshold completed without cancellation;
3. the state actually transitions `compact -> expanded`.

No haptic feedback is emitted for:

- a quick pointer transit that is cancelled before dwell completion;
- duplicate `mouseMoved` events;
- pointer movement/retention while already expanded;
- programmatic/setup/layout-driven presentation changes;
- screen reconfiguration by itself;
- collapse;
- stale callbacks after cancellation.

macOS may legitimately suppress physical feedback when the current device cannot provide it or when the user is not touching a compatible trackpad. The application must treat that as normal, not an error and not retry in a loop.

## 3. Test-first design

The production state machine should be separable from AppKit event delivery. Time and haptic output must be replaceable with deterministic test doubles.

Minimum RED-first automated scenarios:

1. `quickTransitBeforeThresholdDoesNotExpand`
   - pointer enters;
   - elapsed time remains below threshold;
   - pointer exits;
   - result: compact, zero haptic requests.

2. `deliberateHoverExpandsOnlyAfterThreshold`
   - immediately before threshold: compact;
   - at/after threshold: expanded.

3. `successfulHoverExpansionRequestsExactlyOneHaptic`
   - one completed user hover transition produces exactly one haptic request.

4. `duplicatePointerEventsDoNotDuplicatePendingActivationOrHaptic`
   - repeated movement inside the activation region still produces one transition and one haptic.

5. `cancelledActivationCannotFireFromStaleCallback`
   - exit/cancel followed by advancement past the old deadline remains compact with zero haptic.

6. `reentryStartsFreshDwell`
   - previous partial dwell does not count toward a later hover.

7. `expandedRetentionDoesNotRetriggerHaptic`
   - movement in the expanded retention region produces zero additional haptic requests.

8. `collapseThenNewDeliberateHoverCanHapticAgain`
   - a later independent user activation may produce one new haptic.

9. lifecycle/cancellation test
   - destroying/disabling the controller with pending dwell leaves no delayed transition or retained work.

PR #10 also covers programmatic-expansion haptic exclusion and explicit pointer-monitor registration/teardown lifecycle. Those are additional deterministic regressions, not replacements for the minimum scenarios above.

## 4. Implementation evidence — 2026-08-08

- RED CI #147 and #148 proved the interaction APIs were absent before production implementation; a test-only import defect discovered by #147 was corrected without introducing production code.
- RED CI #150 additionally proved the pointer-monitor lifecycle abstraction was absent before its implementation.
- The production scheduler uses one cancellable `DispatchWorkItem` through `DispatchQueue.main.asyncAfter`; there is no polling or repeating timer.
- The production haptic performer uses `NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)`.
- The current narrow local/global `.mouseMoved` observation has explicit ownership and idempotent teardown. It is intentionally retained until a separate target-Mac local-tracking experiment proves a reliable equal-or-better replacement.
- CI #157 passed correctness/security/policy/package checks but failed the unchanged executable-size budget by `356 B`; the budget was not widened.
- CI #158 passed all deterministic gates after footprint reduction with executable `251,856 B`, app `254,853 B`, and DMG `83,072 B`.

These CI results establish deterministic implementation readiness only. Shared-runner CPU/RSS/thread values are not accepted target-Mac performance evidence.

## 5. Real-hardware acceptance

Retain these stable acceptance IDs in `docs/TESTING.md`:

- `NH-HOVER-DELAY-001`: normal pointer transit through the notch toward another display finishes before the dwell threshold; panel stays compact and no haptic is felt.
- `NH-HOVER-DELAY-002`: deliberate hover opens the panel after a short, perceptible-but-fast delay; no visible flicker/oscillation.
- `NH-HAPTIC-001`: on a compatible Force Touch trackpad while physically touching it, a successful deliberate hover expansion produces one short tactile event synchronized with expansion.
- `NH-HAPTIC-002`: quick/cancelled hover, retention movement, and collapse produce no haptic.

Exact tactile feel and final dwell value are real-hardware UX decisions. Deterministic transition/count/cancellation behavior must be automated before manual tuning.

## 6. Definition of done

This interaction work is complete only when:

- RED-first deterministic tests cover the scenarios above;
- production implementation is event-driven and cancellation-safe;
- no security capability is broadened without an explicit policy change/review;
- performance audit shows no polling/repeating-timer regression;
- all existing notch/hover regression tests remain green;
- `NH-HOVER-DELAY-001/002` and `NH-HAPTIC-001/002` pass on the target MacBook/macOS 26.6;
- `CHANGELOG.md`, `PROJECT_STATE.md`, and relevant architecture/testing docs are updated with the accepted behavior and final tuned dwell value.

At the current PR #10 state, the deterministic implementation bullets are satisfied; the real-hardware bullets and final tuned dwell value remain pending and therefore this specification is **not yet fully accepted**.
