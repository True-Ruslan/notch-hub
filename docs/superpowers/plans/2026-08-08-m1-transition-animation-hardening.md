# M1 Transition and Animation Hardening Plan

Date: 2026-08-08
Milestone: M1 — Notch Core hardening and interaction
PR: #10 `M1 delayed hover and haptic interaction core`
Primary hardware target: MacBook / macOS 26.6
Status: deterministic implementation complete; clean exact-head CI and physical acceptance pending

## Goal

Replace endpoint-only compact/expanded presentation with one explicit, cancellation-safe transition lifecycle that remains smooth under reversal, respects Reduce Motion, preserves exactly-once haptic semantics, and stays within the accepted P0 security/performance/artifact budgets.

This plan extends the earlier delayed-hover/haptic plan. It does not weaken that plan's dwell, haptic, security, or target-Mac acceptance requirements.

## Non-negotiable constraints

- TDD for every deterministic behavior change.
- One presentation-transition authority.
- No polling, repeating timers, display links, sleep loops, or custom per-frame interpolation.
- Public AppKit/Core Animation only.
- No new entitlement or sensitive permission.
- No `CGEventTap`, Accessibility/Input Monitoring, synthetic input, or broader global input mask.
- No third-party runtime dependency.
- App Sandbox + Hardened Runtime remain mandatory.
- Existing P0 size budget is not widened merely to accommodate implementation overhead.
- Shared-runner CPU/RSS values do not substitute for target-Mac measurements.
- Hardware/compositor smoothness is not declared from headless CI.

## Target architecture

```text
pointer event
  -> NotchInteractionCoordinator
       emits intent only
  -> NotchPanelTransitionCoordinator
       owns desired presentation + phase + generation + haptic eligibility
  -> AppKit transition output
       NSAnimationContext for panel frame
       CABasicAnimation for corner radius
  -> NotchPanelModel
       content presentation only
```

Transition phases:

- `compact`
- `expanding`
- `expanded`
- `collapsing`

## Task 1 — Separate interaction intent from presentation authority

### RED

Add deterministic tests requiring:

- an interaction-intent type;
- current presentation supplied as input rather than owned by interaction coordinator;
- deliberate dwell emits one expansion intent;
- pointer exit emits collapse intent;
- setup synchronization emits no activation intent.

Expected RED: production interaction API does not yet expose the intent-only contract.

### GREEN

Refactor `NotchInteractionCoordinator` so it owns only dwell/cancellation/generation and emits compact transition intent.

Do not add animation logic or haptic output to this layer.

### Verification

- quick transit remains silent;
- duplicate movement keeps one pending dwell;
- stale callback remains harmless;
- re-entry receives a fresh dwell;
- startup/current-pointer synchronization stays non-activating.

## Task 2 — Introduce the transition lifecycle coordinator

### RED

Add tests for:

- `expanding` and `collapsing` phases;
- expansion settles only after matching completion;
- collapse keeps expanded content until matching completion;
- stale expansion completion cannot win after collapse reversal;
- stale collapse completion cannot win after expansion reversal;
- duplicate desired expansion does not duplicate transition/haptic;
- programmatic expansion remains non-haptic;
- invalidation cancels output and makes later completion harmless.

### GREEN

Implement `NotchPanelTransitionCoordinator` with:

- desired presentation;
- current phase;
- generation counter;
- content-presentation staging;
- injected animation/cancel/haptic functions.

Exactly one generation is authoritative. Do not retain transition history.

### Stress verification

Drive at least 10,000 alternating reversal requests with a fake animation boundary that may still invoke cancelled completions. Only the latest generation may settle state.

## Task 3 — Add Reduce Motion policy

### RED

Require deterministic policy behavior:

- normal motion -> `0.20 s` candidate;
- Reduce Motion -> `0 s`;
- duplicate accessibility notifications do not retarget;
- actual policy change retargets an in-flight desired transition;
- policy retarget never requests a second haptic;
- observer teardown is idempotent.

### GREEN

Use public `NSWorkspace.accessibilityDisplayShouldReduceMotion` and `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification`.

Prefer the leanest lifecycle ownership that remains explicit. The final implementation uses selector-based observation owned by `NotchPanelController`, avoiding a separate block observer token.

No Accessibility permission or entitlement is required or allowed for this preference.

## Task 4 — Add public AppKit/Core Animation output

### RED

Require:

- zero-duration transition reaches exact frame/radius endpoint synchronously once;
- positive-duration transition installs a system corner animation and does not synchronously complete;
- standard timing is `.easeInEaseOut`;
- repeated immediate endpoint cycles preserve backing-layer clipping/radii;
- cancellation must freeze current visible presentation-layer radius before removing old animation.

### GREEN

Use:

- `NSAnimationContext` + `panel.animator().setFrame(...)` for frame;
- `CABasicAnimation(keyPath: "cornerRadius")` for radius;
- shared duration/timing;
- model-layer target with presentation-layer start value;
- zero-duration exact endpoint for Reduce Motion.

On cancellation:

1. read visible `layer.presentation()?.cornerRadius` when available;
2. set that value on the model layer with implicit actions disabled;
3. remove old corner animation;
4. let the transition coordinator invalidate the stale generation and start the new endpoint.

No custom animation loop.

## Task 5 — Compose one live transition authority

### RED

Add architecture-regression tests that reject:

- direct presentation `panel.setFrame` ownership in `NotchPanelController`;
- old hosting-factory presentation mutation;
- weak/lost transition outputs;
- competing transition ownership.

### GREEN

Wire live flow:

```text
NotchPointerMonitor
 -> NotchInteractionCoordinator
 -> NotchPanelTransitionCoordinator
 -> animate/cancel/haptic outputs
```

`NotchPanelModel` remains content-only.

## Task 6 — Enforce performance/artifact constraints

The unchanged P0 size budget is an acceptance test, not a target to edit.

If size fails:

1. confirm behavior/security tests first;
2. attribute runtime cost before refactoring;
3. remove unnecessary runtime metadata/object/closure boundaries rather than weakening requirements;
4. keep deterministic tests unchanged unless the test itself encodes an invalid platform assumption;
5. rerun exact size gate.

Implemented size reductions include:

- lean closure/function animation ports instead of protocol-heavy runtime abstractions;
- selector-based accessibility observation instead of block observer token ownership;
- lean one-shot scheduler seam;
- lean pointer-monitor test seam;
- no `Task { @MainActor ... }` allocation for every `.mouseMoved` callback.

Temporary binary-size diagnostics must be removed before final candidate CI.

## Task 7 — Pointer hot-path allocation regression

### RED

Source-level regression requires the production `NotchPointerMonitor` to contain no per-event `Task { @MainActor ... }` and to use the main-thread AppKit event-monitor boundary synchronously.

### GREEN

Use `MainActor.assumeIsolated` inside local/global AppKit mouse-move callbacks. Preserve exactly the same `.mouseMoved` registrations, lifecycle ownership, and permissions.

This is not the future `NSTrackingArea` migration. That remains a separate measured experiment after this interaction/animation slice is accepted.

## Task 8 — Documentation and clean exact-head verification

Before hardware testing:

- remove temporary diagnostics;
- update `CHANGELOG.md`;
- update `docs/PROJECT_STATE.md`;
- update `docs/ROADMAP.md`;
- update `docs/ARCHITECTURE.md`;
- update `docs/TESTING.md` where practical;
- update `docs/specs/M1_NOTCH_INTERACTION.md`;
- keep PR #10 Draft;
- run a fresh exact-head CI after the final repository commit;
- require macOS 26 build/test, full Swift tests, release/public policy, security, runtime performance audit, packaging/signature/Sandbox/Hardened Runtime/DMG verification, performance harness smoke, artifact upload, and unchanged size budget all PASS.

Only the artifact from that final exact-head run may be used for physical acceptance.

## Hardware feasibility gate

On target MacBook/macOS 26.6 test the exact final artifact:

1. normal deliberate expansion: visibly smooth, exactly one `.levelChange` haptic;
2. normal collapse: visibly smooth, no haptic;
3. at least 20 open/collapse cycles: rounded chrome remains stable;
4. expansion -> collapse reversal during animation: starts from current visible state, no snap/flicker/stale endpoint/extra haptic;
5. collapse -> expansion reversal: same requirements;
6. rapid hover/leave churn: no stuck phase;
7. Reduce Motion enabled before transition: immediate exact endpoint;
8. toggle Reduce Motion during an in-flight transition: immediate desired endpoint, no second haptic/flicker;
9. startup with pointer already over notch: no setup-only activation/haptic;
10. normal cross-display transit: no accidental opening/haptic;
11. rerun `NH-NOTCH-001`, `NH-HOVER-001/002/003`, `NH-HOVER-DELAY-001/002`, `NH-HAPTIC-001/002`, and `NH-VISUAL-001/002/003`.

If the public AppKit animator visibly snaps/flickers under reversal on the real Mac, record FAIL. Do not add a timer/display-link/private API workaround. Revisit the architecture.

## Acceptance boundary

The slice is accepted only when:

- deterministic TDD suite is green;
- clean exact-head CI is fully green;
- P0 artifact budget is unchanged and green;
- no security/input/permission expansion occurred;
- hardware feasibility gate passes;
- accepted/tuned dwell, inset, haptic pattern, and animation duration are recorded.

Until then PR #10 remains Draft and unmerged.
