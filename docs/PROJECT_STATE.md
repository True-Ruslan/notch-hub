# Project state

Last updated: 2026-08-08
Current version: `0.1.0` (Personal Release published and accepted)
Repository visibility: **Public**
Primary physical target: macOS `26.6`
Protected branch target: `main`
P0 merge commit: `a056aa74bad5d8e193eb4c76a76e6c910344bd09`
Public-readiness hardening merge: `23500e099a0f8b2738f1157c6ae3be71c89df6e1`
Current product milestone: M1 `Notch Core hardening and interaction` — **IN PROGRESS**
Active implementation PR: #10 `M1 delayed hover and haptic interaction core` — **DRAFT / DO NOT MERGE BEFORE HARDWARE ACCEPTANCE**

## Product

NotchHub is a personal, native, local-first macOS productivity hub built around the MacBook notch. Planned modules are Shelf, Snippets, Calendar, Translator, and media controls with Yandex Music as the primary player.

NotchNook is a public product/UI research reference only; NotchHub remains an independent implementation.

## Accepted foundation

### M0 — Engineering foundation

Status: **ACCEPTED AND MERGED**.

Accepted target-Mac evidence:

- `NH-OS26-001`: PASS;
- `NH-NOTCH-001`: PASS;
- `NH-HOVER-001`: PASS;
- `NH-HOVER-002`: PASS;
- `NH-HOVER-003`: PASS.

M0 includes the Swift 6 native shell, public notch geometry, deterministic pointer policy, AppKit-owned panel sizing, App Sandbox + Hardened Runtime, zero third-party Swift runtime dependencies, strict CI/security/package gates, and accepted real-hardware regression fixes.

### R0.1 — Personal Release

Status: **ACCEPTED**.

Immutable `v0.1.0` was published from accepted commit `8e913dcddfdec7d9aa920df8c37afb23b8c40884` and passed downloaded-release acceptance on the target MacBook/macOS 26.6. Personal Release remains ad-hoc signed, sandboxed, Hardened Runtime protected, checksum/provenance verified, and intentionally not notarized. Trusted Release remains an optional future tier.

### P0 — Performance Foundation

Status: **ACCEPTED AND MERGED**.

Accepted target-Mac baseline on macOS 26.6 / `Mac16,8`:

- `NH-PERF-IDLE-001`: CPU median/max `0.0% / 0.7%`, RSS median/max `33,648 / 33,808 KiB`, threads `4 / 4`;
- `NH-PERF-HOVER-001`: CPU median/max `5.95% / 22.3%`, RSS median/max `38,456 / 38,816 KiB`, threads `6 / 7`;
- `NH-PERF-STABILITY-001`: CPU median/max `0.0% / 6.8%`, RSS median/max `30,992 / 34,384 KiB`, threads `3 / 7`;
- 10-minute stability RSS delta `-3,712 KiB`, with no sustained memory/thread growth.

Accepted immutable `v0.1.0` artifact baseline:

- executable `220,560 B`;
- app aggregate `223,555 B`;
- DMG `73,955 B`.

Runtime CPU/RSS/thread limits remain target-Mac acceptance gates. Shared GitHub runners never substitute for physical resource evidence. Artifact byte sizes are deterministic and enforced in CI with the unchanged P0 budget: 15% relative allowance plus the accepted absolute ceilings.

### P0.1 — Public repository readiness

Status: **ACCEPTED**.

Public-source hardening is merged. Ordinary public pull-request CI remains read-only/unprivileged; Personal Release publication is isolated from untrusted PR execution; Trusted Release remains dormant without Apple credentials/environment.

## M1 interaction and transition hardening

Status: **DETERMINISTIC IMPLEMENTATION GREEN; CLEAN EXACT-HEAD CI + TARGET-MAC ACCEPTANCE NEXT**.

Authoritative requirements: `docs/specs/M1_NOTCH_INTERACTION.md`.
Initial dwell/haptic plan: `docs/superpowers/plans/2026-08-08-m1-pointer-dwell-haptics.md`.
Transition/animation hardening plan: `docs/superpowers/plans/2026-08-08-m1-transition-animation-hardening.md`.

### Interaction intent layer

`NotchInteractionCoordinator` now owns only pointer-intent timing/cancellation. It does not own panel geometry, presentation animation, content rendering, or haptic output.

Implemented invariants:

- one cancellable one-shot compact -> expanded dwell, current candidate `120 ms`;
- current compact activation inset candidate `4 pt`;
- duplicate movement cannot create duplicate pending activation;
- leaving before threshold cancels immediately;
- generation validation makes cancelled/stale callbacks harmless;
- re-entry starts a fresh full dwell;
- expanded retention/collapse is independent from activation dwell;
- setup/current-pointer synchronization is non-activating;
- one `DispatchWorkItem` via `DispatchQueue.main.asyncAfter`; no polling or repeating timer.

### Single transition authority

`NotchPanelTransitionCoordinator` is now the sole owner of compact/expanded presentation transitions.

It owns:

- explicit `compact`, `expanding`, `expanded`, and `collapsing` lifecycle phases;
- desired presentation independent from currently staged SwiftUI content;
- expanded content retention during collapse until the matching animation completes;
- cancellation/reversal through generation validation so stale completions cannot win;
- exactly-once haptic eligibility for a deliberate user expansion;
- programmatic expansion without haptic;
- animation-policy retarget while a transition is in flight without a second haptic.

`NotchPanelController` no longer has a competing direct presentation `setFrame` path. `NotchPanelModel` represents content presentation only.

### AppKit animation and visual ownership

Panel animation uses public system APIs only:

- `NSAnimationContext` + `panel.animator().setFrame(...)` for the window frame;
- `CABasicAnimation(keyPath: "cornerRadius")` for backing-layer corner radius;
- shared `.easeInEaseOut` timing;
- standard duration candidate `0.20 s`;
- Reduced Motion resolves duration to `0`, applying the exact endpoint synchronously;
- cancellation freezes the current Core Animation presentation-layer corner radius into the model layer before removing the animation, preventing a radius jump during reversal;
- no display link, frame timer, polling loop, custom interpolation loop, or private animation API.

Outer clipping remains AppKit-owned. The hardware-notch compact surface is opaque black; continuous corner radii remain `12 pt` compact / `22 pt` expanded; the hosting view follows panel width and height while `sizingOptions == []` keeps window geometry AppKit-owned.

### Reduce Motion

`NotchPanelController`, already an `NSObject`, observes `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification` through the selector-based `NotificationCenter` API.

The controller caches the current boolean only to suppress duplicate policy updates. On an actual value change it asks the transition coordinator to retarget the current desired presentation. Teardown removes the observer explicitly.

This replaced a block-observer/token object after size attribution showed unnecessary runtime metadata/closure cost. No accessibility permission or entitlement is requested; this is a public display accessibility preference exposed by AppKit.

### Pointer event hot path

The current narrow input boundary remains exactly one local and one global `.mouseMoved` monitor with explicit ownership and idempotent removal.

The monitor no longer allocates `Task { @MainActor ... }` for every mouse-move event. AppKit event-monitor callbacks are delivered on the main thread, so delivery now uses `MainActor.assumeIsolated` synchronously. This removes avoidable hot-path task allocation without broadening the observed event mask or permissions.

The global `.mouseMoved` fallback remains intentionally in place until the separate `NSTrackingArea` / window-local experiment proves equal-or-better target-Mac correctness and resource behavior.

### Haptic policy

The current physical-feedback candidate is one public AppKit `.levelChange` request for a successful deliberate compact -> expanded activation.

No haptic is requested for quick/cancelled transit, duplicate pointer movement, retention, collapse, startup synchronization, programmatic expansion, stale completion, or Reduce Motion retargeting. Reversal does not create a second haptic merely because an in-flight transition changes direction.

### TDD and CI evidence for transition hardening

Key RED -> GREEN evidence:

- CI #225: RED for the absent interaction-intent contract before coordinator separation;
- CI #231: RED for the absent transition lifecycle/driver contract;
- CI #273: RED for Reduce Motion policy support;
- CI #279: RED for the AppKit animation boundary;
- CI #283: RED for the single transition-authority controller composition;
- CI #292: RED for freezing visible corner radius before cancellation;
- CI #295: functional tests/security/package were green but the unchanged P0 size gate correctly rejected the larger implementation; no hardware candidate was issued;
- CI #305: RED for selector-based accessibility observation before implementation;
- CI #308: all deterministic behavior/security/package checks passed, executable/app were under budget, but DMG size still failed the unchanged P0 budget;
- CI #309: RED for the new no-per-event-Task pointer hot-path invariant; all previous 48 Swift tests remained green;
- CI #310 on source `12c5ff26dc409dd0391f3b296866c2be9515ce7e`: **49/49 Swift tests PASS**, all release/security/performance/package gates PASS, and the unchanged P0 size budget PASS.

CI #310 deterministic candidate sizes:

- executable `250,000 B`;
- app `252,997 B`;
- DMG `84,422 B`.

The temporary binary-size diagnostic instrumentation used during attribution was removed immediately after the budget returned green. A fresh exact-head CI after documentation/cleanup is required before physical testing.

Shared-runner CPU/RSS/thread smoke remains schema/compatibility evidence only and is not target-Mac runtime acceptance data.

## Required target-Mac acceptance

PR #10 remains Draft and must not be merged until the final clean exact-head CI artifact is tested on the target MacBook/macOS 26.6.

Required checks:

- `NH-NOTCH-001` — compact alignment/width still matches the physical notch;
- `NH-HOVER-001` — deliberate hover expands exactly once, without oscillation;
- `NH-HOVER-002` — movement within expanded retention stays expanded;
- `NH-HOVER-003` — leaving retention collapses exactly once and stays compact;
- `NH-HOVER-DELAY-001` — normal cross-display transit stays compact/no haptic;
- `NH-HOVER-DELAY-002` — deliberate hover opens reliably with the `120 ms` + `4 pt` candidates;
- `NH-HAPTIC-001` — successful deliberate expansion produces one acceptable `.levelChange` tactile event;
- `NH-HAPTIC-002` — cancelled transit, retention and collapse remain physically silent;
- `NH-VISUAL-001` — compact black rounded panel remains visible and aligned, with no square leakage;
- `NH-VISUAL-002` — expanded controls stay visible below the physical notch during active hover;
- `NH-VISUAL-003` — at least 20 normal open/collapse cycles retain rounded chrome;
- expansion -> collapse reversal during the 0.20 s transition starts from the current visible state with no snap/flicker/stale endpoint and no extra haptic;
- collapse -> expansion reversal behaves likewise;
- rapid hover/leave churn never leaves the panel stuck in a stale phase;
- Reduce Motion enabled before a transition produces an immediate endpoint;
- switching Reduce Motion during an in-flight transition immediately retargets to the desired endpoint without a second haptic or stale completion;
- launching while the cursor already overlaps the notch does not activate or haptic solely from startup synchronization.

If the public AppKit frame animator visibly snaps or flickers on real hardware, this is a hard acceptance failure. The fallback is architectural redesign, not a custom timer/display-link loop, private API, or weakened test.

The `120 ms` dwell, `4 pt` activation inset, `.levelChange` haptic, and `0.20 s` standard animation duration remain candidates until this physical cycle is accepted.

## Security baseline

`SECURITY.md` remains authoritative. M1 adds no runtime entitlement, telemetry, analytics, networking, subprocess/shell, dynamic loading, private API, privileged helper, Accessibility/Input Monitoring permission, synthetic input, or broader global input capture. Global observation remains exactly `.mouseMoved`; pointer coordinates/history are not persisted.

## Known limitations / technical debt

- target-Mac runtime ceilings still derive from one canonical run per scenario with conservative headroom;
- the narrow global `.mouseMoved` fallback remains and must be evaluated separately against `NSTrackingArea` / window-local tracking;
- GitHub-hosted runner resource values are not representative of the target Mac;
- physical compositor/window-animation continuity and tactile feel cannot be declared by headless CI;
- active-display migration, Spaces/fullscreen, screen-configuration handling, notchless mode, click/pin policy, gestures, product modules, and optional trusted distribution remain later work.

## Next optimal step

1. Finish documentation/diagnostic cleanup and require a new clean exact-head CI PASS with the unchanged P0 size budget.
2. Use only that CI artifact for the target-Mac transition/interaction acceptance matrix above.
3. Record exact PASS/FAIL results and final accepted/tuned constants. If a constant changes, add/update deterministic coverage first and rerun only the necessary physical scenarios on the new exact artifact.
4. After this interaction/animation slice is accepted, run the measured `NSTrackingArea` / window-local pointer experiment against accepted `NH-PERF-HOVER-001` before deciding whether the global `.mouseMoved` fallback can be removed.
5. Continue M1 with active-display migration, Spaces/fullscreen, screen-configuration changes, click/pin, and gestures.
