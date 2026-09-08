# M2.2 Shelf Quick Look — Design

Date: 2026-09-08  
Status: implemented and automated-accepted on PR #91; merge/release pending

## Goal

Add the smallest high-value native Shelf usability increment after M2.1: single-item Quick Look preview with no expansion of file authority, persistence schema, background work or media architecture.

## Product behavior

Each persisted Shelf row gains one **Preview** action.

On explicit Preview:

1. resolve the existing read-only security-scoped bookmark through `ShelfStore`;
2. acquire security-scoped access for that resolved URL;
3. present the URL through native macOS `QLPreviewPanel`;
4. retain the scope only while that preview is owned;
5. release it when the panel closes, the preview is replaced, the controller closes, or the app terminates.

If bookmark resolution or scope acquisition fails, the action fails closed and the item uses the existing unavailable-state presentation.

If a preview is already active, it is fully closed and its scope released **before** attempting a replacement. Therefore a failed replacement cannot leave old Quick Look content visible after the old scope has ended.

## Scope

Included:

- native `QLPreviewPanel`;
- one active item at a time;
- app-lifetime Quick Look controller;
- deterministic scope lifecycle abstraction in Core;
- Preview accessibility action/identifier;
- failure-state reuse through existing Shelf unavailable handling;
- termination cleanup;
- automated policy/lifecycle/regression coverage.

Deferred:

- Share sheet / AirDrop (M2.3 candidate);
- Shelf multi-selection;
- Quick Look navigation across multiple Shelf items;
- keyboard shortcut/spacebar preview;
- copy/move/rename/delete;
- text/URL snippets (M3);
- any global keyboard/input monitor.

## Security constraints

Shipping entitlements remain unchanged from M2.1:

- `com.apple.security.app-sandbox = true`;
- `com.apple.security.files.user-selected.read-only = true`.

M2.2 must not introduce:

- read-write or broad filesystem entitlement;
- network entitlement/client;
- Automation/Apple Events;
- Accessibility/Input Monitoring/Screen Recording;
- dynamic-code exceptions;
- source-file delete/move/rename/copy authority;
- unbounded raw path persistence.

The only intentionally longer-lived file scope is the one associated with an explicitly visible Quick Look preview; it remains bounded by native panel lifecycle and is balanced on every controller exit path.

## Architecture

### Core lifecycle boundary

`ShelfPreviewAccessSession` owns at most one active URL. It depends on `ShelfSecurityScopeControlling` so start/stop balance is behaviorally unit-testable without requiring a real sandbox resource.

Rules:

- `begin(url:)` first releases any previously owned scope;
- failed start leaves no active scope;
- `end()` is idempotent;
- each successful start is balanced exactly once.

### AppKit Quick Look boundary

`ShelfQuickLookController` is app-owned and `@MainActor` because it mutates AppKit panel state.

`QLPreviewPanelDataSource` callbacks are supplied by a separate `ShelfQuickLookDataSource`. It is intentionally non-actor-isolated and protects its single optional URL with `NSLock`, satisfying Objective-C callback isolation under both the project's supported Swift toolchains and current macOS 26 CI.

The controller:

- owns no polling/timer/task loop;
- keeps a weak reference to the system Quick Look panel;
- installs/removes its own dataSource/delegate only while active;
- activates the app and orders the native panel front only from explicit Preview;
- clears data source/delegate and releases scope on close/window close/replacement/app termination.

### Composition

`AppDelegate` owns the controller for app lifetime. `ShelfRoutingRootView` injects it into `ShelfView`. `ShelfView` resolves the existing bookmark and calls the controller; it does not create a second persistence or file-access abstraction.

No changes are made to `MediaNotchRootView`, `NotchPanelTransitionCoordinator`, media transport, Shelf persistence schema or entitlements.

## Performance constraints

- zero recurring work while Shelf/Quick Look is idle;
- no timer, polling loop, filesystem scan, background observation or global monitor;
- one native panel and one bounded single-URL data source while active;
- security scope and UI state discarded on close;
- existing feature-size budget must continue to pass unless a real measured candidate proves a new budget necessary.

## Testing strategy

RED → GREEN layers:

1. unit tests for balanced security-scope session;
2. source-policy tests for native Quick Look wiring, Preview action and forbidden authorities;
3. canonical Swift/macOS build compatibility;
4. explicit regression for replacement failure after review identifies any stale-panel lifecycle hazard;
5. complete required CI matrix on the exact production head;
6. final complete CI on the documented PR head before merge.

Automation is the acceptance gate under the current personal-use governance policy. Physical testing remains optional diagnostics unless a future spec changes that policy.

## Clean-room boundary

Competitive products may inform observable workflow goals only. NotchHub's Quick Look implementation is independently designed from Apple platform APIs and existing NotchHub architecture. No third-party GPL implementation code, tests, type structure or internal algorithm is copied into the MIT project.
