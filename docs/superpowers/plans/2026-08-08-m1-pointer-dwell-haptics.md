# M1 Pointer Dwell and Haptics Implementation Plan

Date: 2026-08-08
Status: approved for implementation
Target: `True-Ruslan/notch-hub`
Primary hardware acceptance target: MacBook with hardware notch, macOS 26.6

## Goal

Implement the deterministic interaction core required by `docs/specs/M1_NOTCH_INTERACTION.md` without widening NotchHub's security surface or weakening the accepted P0 resource contract.

The first M1 slice must:

1. make pointer-activation timing deterministic and cancellation-safe;
2. add one public AppKit haptic request only for a completed user hover expansion;
3. make pointer-monitor lifecycle explicit;
4. retain the currently accepted narrow global `.mouseMoved` fallback until a window-local tracking replacement is proven on target hardware to preserve behavior and meet or beat the P0 resource baseline;
5. leave multi-display migration, Spaces/fullscreen policy, gesture design, and animation tuning for the next M1 slice after this interaction core passes hardware acceptance.

## Constraints

- TDD: RED -> GREEN -> REFACTOR for deterministic behavior.
- Initial dwell candidate: `120 ms`, represented by a named configuration value.
- Event-driven only: no polling, repeating timers, display links, sleep loops, or busy loops.
- At most one pending activation work item.
- Pointer exit, state invalidation, and lifecycle teardown cancel pending activation.
- Stale callbacks must be harmless even if a scheduler invokes a cancelled callback.
- Haptic output uses `NSHapticFeedbackManager.defaultPerformer` with `.generic` and `.now`.
- No haptic for quick transit, duplicate movement, expanded retention, collapse, programmatic state changes, or stale callbacks.
- No `CGEventTap`, Accessibility, Input Monitoring, private APIs, synthetic input, custom drivers, network access, or new entitlements.
- Existing `NH-HOVER-001/002/003` semantics remain intact.
- Global observation remains limited to `.mouseMoved` until a local replacement has real-hardware correctness and performance evidence.

## Design

### Pure interaction coordinator

Add a main-actor `NotchInteractionCoordinator` between AppKit pointer delivery and `NotchPanelModel`.

It owns:

- one optional pending dwell;
- a generation/token so stale callbacks cannot commit state;
- deterministic scheduler and haptic abstractions;
- compact activation / expanded retention decisions via the existing `NotchPointerPolicy`;
- lifecycle invalidation.

The coordinator does not know about `NSPanel`, `NSEvent`, `NSTrackingArea`, or the physical haptic implementation.

### Scheduler boundary

Define a narrow one-shot scheduler protocol and cancellable token. Production uses one `DispatchWorkItem` scheduled with `DispatchQueue.main.asyncAfter`; tests use a manual scheduler that advances deterministically without sleeps.

This is not a repeating timer and creates no idle periodic work.

### Haptic boundary

Define a narrow `NotchHapticPerforming` protocol. Production implementation calls:

```swift
NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
```

Tests use a counting fake.

### Pointer observation boundary

Keep the accepted local + global `NSEvent` `.mouseMoved` delivery for this slice, but give it explicit ownership/removal on controller invalidation. Do not broaden the event mask.

A later M1 tracking experiment may replace the global observer with `NSTrackingArea` only after:

- `NH-HOVER-001/002/003` remain PASS;
- `NH-HOVER-DELAY-001/002` remain PASS;
- cross-display transit remains reliable;
- `NH-PERF-HOVER-001` and relevant idle/stability evidence are equal or better than the accepted P0 baseline.

## RED -> GREEN sequence

### Task 1 — Interaction-policy RED tests

Add deterministic tests for:

1. quick transit cancels before threshold and emits zero haptic;
2. deliberate hover remains compact before threshold and expands at threshold;
3. successful hover expansion emits exactly one haptic;
4. duplicate pointer moves keep one pending activation and one haptic;
5. stale callback after cancellation cannot expand;
6. re-entry starts a fresh full dwell;
7. expanded retention produces no additional haptic;
8. collapse then a new deliberate hover may haptic once again;
9. invalidation cancels pending work and stale callbacks remain harmless.

Commit the RED tests before production implementation and let PR CI demonstrate the expected compile/test failure.

### Task 2 — Minimal interaction implementation

Add scheduler/haptic protocols, `NotchInteractionCoordinator`, and production one-shot scheduler. Run the full Swift suite and policy/security checks through CI.

### Task 3 — AppKit haptic integration

Add the public AppKit performer and wire `NotchPanelController` through the coordinator. The controller must no longer immediately expand from a compact pointer event.

### Task 4 — Explicit pointer monitor lifecycle

Remove local/global event monitors on invalidation and ensure pending dwell is cancelled. Keep the event mask exactly `.mouseMoved`.

### Task 5 — Documentation and acceptance state

Update `CHANGELOG.md`, `docs/PROJECT_STATE.md`, `docs/ROADMAP.md`, `docs/TESTING.md`, and architecture notes to record:

- deterministic M1 interaction core implementation;
- CI evidence;
- global `.mouseMoved` replacement remains intentionally pending target-Mac experiment;
- hardware gates `NH-HOVER-DELAY-001/002` and `NH-HAPTIC-001/002` remain pending until the exact candidate is exercised on macOS 26.6;
- final dwell remains a candidate until hardware tuning accepts it.

## Definition of done for this PR

- deterministic RED evidence exists in branch/CI history;
- all new interaction tests are GREEN;
- existing Swift/release/security/performance-policy tests remain GREEN;
- runtime performance audit reports no polling/repeating timer/sleep/display-link violation;
- App Sandbox/Hardened Runtime/entitlements remain unchanged;
- no new runtime dependency is added;
- PR exact-head CI is fully green;
- hardware acceptance items are clearly listed rather than inferred.

This PR does not claim M1 complete. It establishes the interaction core and produces a candidate suitable for the required target-Mac acceptance and subsequent local-tracking experiment.