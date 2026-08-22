# Active-display / multi-monitor migration design

Date: 2026-08-21
Status: approved implementation contract
Tracking: issue #55
Primary physical target: `Mac16,8 / macOS 26.6.x`
Base: post-P1 accepted `main` (`55c79b4750bf95aee4fa96ac3682b23cd0689bdc`)

## Goal

Make the existing notch panel react correctly to live display-topology changes without polling, private display APIs, new permissions or a second panel-geometry authority.

The accepted launch policy already prefers an available hardware-notch display over `NSScreen.main`, then falls back to the first available screen. This slice extends that exact policy from launch-time selection to event-driven runtime migration when displays are connected, disconnected or dynamically reconfigured.

This is correctness hardening after accepted P1. It is not a new resource-optimization project and it must not weaken the accepted P1 wakeup, pointer-monitor, security or presentation-lifecycle boundaries.

## Platform guidance

The implementation follows public AppKit behavior documented by Apple:

- `NSScreen.screens` represents the currently available screens and should not be cached because screens may be added, removed or dynamically reconfigured.
- `NotificationCenter.default` posts `NSApplication.didChangeScreenParametersNotification` when the attached display configuration changes.
- `NSScreen.main` is the screen containing the keyboard-focused window and is not necessarily the primary/menu-bar display.

References:

- https://developer.apple.com/documentation/appkit/nsscreen/screens
- https://developer.apple.com/documentation/appkit/nsapplication/didchangescreenparametersnotification
- https://developer.apple.com/documentation/appkit/nsscreen/main

No CoreGraphics display callback/private display API is needed for this slice. AppKit already exposes the lifecycle event and the geometry inputs NotchHub uses.

## Existing constraints that remain authoritative

- `NotchPanelTransitionCoordinator` is the sole presentation/geometry transition authority.
- Hardware-notch geometry is derived only from public `NSScreen` safe-area/auxiliary-area values.
- Settled compact and Peek own zero persistent media adapter; settled Expanded owns the presentation-scoped runtime.
- The global `.mouseMoved` monitor is not persistent in idle; it exists only as a bounded escape fallback during active interaction.
- No polling loop, repeating timer, display link, event tap, synthetic input, telemetry or new entitlement.
- App Sandbox + Hardened Runtime remain unchanged.
- Stale animation completions must never settle or move a newer presentation generation.
- Physical endpoint frame/corner reconciliation happens before settled logical publication.

## Domain split

### 1. Fresh topology resolution

`NotchPanelController` reads a fresh `NSScreen.screens` array only when it needs to resolve topology:

1. read the current screen array;
2. derive `ScreenGeometryInput` values;
3. locate current `NSScreen.main` inside that same array as the fallback index;
4. call the existing `NotchScreenSelection.preferredIndex` policy;
5. derive a new base `NotchLayout` with `NotchGeometry.layout`.

The array is not stored as controller state.

If no valid selection can be resolved during a transient notification, keep the last valid layout and do nothing. Do not guess an index or crash the panel.

### 2. One observable layout authority

Replace the private immutable `NotchPanelLayoutState` with one Core-owned `NotchPanelLayoutModel`.

It owns:

- the current base display layout;
- the existing compact horizontal media extension;
- one published effective `currentLayout` derived from those two inputs.

Both AppKit panel geometry and SwiftUI layout-dependent presentation read this same effective layout.

This is required because live migration can change more than the panel origin: hardware-notch width, compact height and expanded-content top inset can change when moving between hardware-notch and notchless displays. Repositioning the `NSPanel` alone would leave SwiftUI content stale.

The model remains a geometry value owner only. It does not own screen observation, transitions, media state or pointer policy.

### 3. Event-driven screen observation

`NotchPanelController` installs one selector-based observer on `NotificationCenter.default` for `NSApplication.didChangeScreenParametersNotification`.

The callback is synchronous on the main actor and performs one topology resolution. It must not allocate a `Task`, schedule a debounce timer or start recurring work.

Duplicate notifications that resolve to an unchanged base layout are no-ops.

Observer removal is explicit and idempotent during `invalidate()`.

### 4. Migration transition semantics

Add an explicit display-layout migration operation to `NotchPanelTransitionCoordinator`. It is different from Reduce Motion / compact-extension policy retargeting because a display topology change can invalidate the physical screen endpoint itself.

On an effective layout migration:

1. advance the transition generation;
2. cancel/freeze any active animation through the existing AppKit cancellation boundary;
3. choose a deterministic migration target;
4. synchronously apply the exact destination frame/corner through the existing settled physical boundary;
5. only after physical reconciliation update logical model/phase;
6. publish a settled presentation only when migration actually completed a previously unsettled non-interactive transition.

No haptic is emitted for migration.

#### Stable endpoint

If phase is already stable (`compact`, `peek`, `expanded`), preserve that presentation and move it synchronously to the corresponding endpoint on the new layout. Do not re-fire the settled-presentation callback because its media lifecycle is already established.

#### Accepted non-interactive transition in flight

If an accepted animated transition is already targeting Compact, Peek or Expanded, preserve `desiredPresentation` and settle immediately to that endpoint on the new layout. The now-completed settlement publishes exactly once so App-owned lifecycle work (for example expanded media runtime start) cannot be lost.

Any completion from the old display generation is stale and ignored.

#### Uncommitted interactive gesture in flight

A topology change must never auto-commit an unfinished gesture.

- `.interactiveExpanding` cancels back to Compact.
- `.interactiveCollapsing` cancels back to Expanded.

The coordinator restores both `desiredPresentation` and stable phase to that origin after first applying the exact new-layout physical endpoint. Because the origin was already the previously settled presentation, do not emit a duplicate settled callback.

### 5. Pointer interaction boundary

Before applying a topology migration, `NotchPanelController`:

- cancels any pending hover activation;
- disarms only the bounded global escape monitor for the old interaction region while keeping the normal local monitor installed.

This prevents an old display region from keeping global escape observation alive after migration and protects the accepted P1 wakeup behavior.

The topology callback does not synthesize a pointer move or auto-open the panel. The next genuine local/global pointer event is evaluated against the new layout.

### 6. SwiftUI layout propagation

`NotchPanelContentFactory` receives the shared `NotchPanelLayoutModel` instead of a one-time `NotchLayout` value.

`NotchRootView` and `MediaNotchRootView` observe that model and derive layout-dependent values from `currentLayout`, including:

- hardware-notch center spacer width;
- compact background policy;
- expanded content top inset.

This keeps view composition synchronized without recreating the hosting view, losing local tracking ownership, or introducing a second screen observer.

## Explicitly rejected approaches

- polling `NSScreen.screens`;
- repeating timers/debounce timers for topology changes;
- caching the `NSScreen.screens` array;
- using `NSScreen.main` as the product invariant;
- moving the panel directly from `AppDelegate` or SwiftUI;
- calling `panel.setFrame` from controller migration code outside the existing transition/settled presentation boundary;
- using private display APIs merely to detect topology changes;
- replacing the hosting view on migration, which risks losing local pointer/scroll ownership and SwiftUI interaction state;
- allowing old animation completions to move the panel after a topology change;
- keeping the bounded global escape monitor armed against the old display region.

## Deterministic TDD contract

The first RED commit must prove missing behavior without production edits.

Minimum automated cases:

1. layout model updates the effective layout when base display layout changes;
2. layout model preserves the existing compact horizontal extension across base-layout migration;
3. duplicate base-layout update is a no-op;
4. stable Compact migration applies the exact new Compact frame/corner synchronously and does not publish duplicate settlement;
5. stable Peek migration applies exact Peek endpoint;
6. stable Expanded migration applies exact Expanded endpoint;
7. an in-flight non-interactive expansion is cancelled, settles Expanded on the new layout and rejects the stale old completion;
8. an in-flight collapse settles Compact on the new layout and rejects the stale old completion;
9. interactive expansion migration cancels to Compact rather than auto-committing Expanded;
10. interactive collapse migration cancels to Expanded rather than auto-committing Compact;
11. display migration emits no haptic;
12. controller source registers `NSApplication.didChangeScreenParametersNotification` on `NotificationCenter.default` and removes it on invalidation;
13. controller source re-reads `NSScreen.screens` inside topology resolution and does not retain a cached screen array;
14. topology migration remains routed through `NotchPanelTransitionCoordinator` and the existing settled AppKit presentation primitive;
15. old global escape observation is explicitly disarmed for migration without invalidating the local pointer monitor;
16. App/Core views observe the shared layout model rather than retaining one-time hardware-notch/inset values;
17. security/performance source policy remains free of polling/repeating timer/display-link/private-display additions.

## Physical acceptance matrix

Any shipping implementation remains unaccepted until an exact CI-produced candidate passes on `Mac16,8 / macOS 26.6.x` with an external monitor.

Required physical checks:

- launch with external monitor attached still binds to the hardware-notch display;
- external monitor connect while Compact -> correct hardware-notch/fallback endpoint, no flash/stuck surface;
- external monitor disconnect while Compact -> correct endpoint;
- topology/reconfiguration while Peek -> exact Peek geometry or deterministic collapse only if a real subsequent pointer event requests it;
- topology/reconfiguration while Expanded -> exact Expanded geometry, controls remain usable;
- topology change during expansion/collapse -> one deterministic new endpoint, no stale snap-back;
- topology change during uncommitted vertical gesture -> returns to gesture origin, never auto-commits;
- representative reversal/rapid-exit cycles around topology changes -> no black/stuck panel, frame/corner/flicker anomaly none;
- media compact hardware-notch spacer remains correct after hardware-notch ↔ notchless migration where physically testable;
- normal Quit leaves no owned media adapter;
- Accessibility / Input Monitoring / Automation / Screen Recording remain NONE;
- stationary idle and unrelated pointer motion on the external display do not show a persistent global-pointer wakeup amplification attributable to NotchHub.

## Exit criteria

This slice reaches `implemented -> automated-tested` only after focused RED evidence is preserved and canonical CI is fully green on the exact production head.

It reaches `physically accepted` only after the complete target-Mac matrix above passes on that exact shipping runtime (or an exact runtime-identical tree with explicit provenance).

Only then may it be merged. Release remains a separate versioned Personal Release decision; `v0.1.0` is not modified.
