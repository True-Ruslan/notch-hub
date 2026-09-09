# M2.3 Shelf Share / AirDrop — Design

Date: 2026-09-09  
Status: implemented candidate; production CI green, final documented-head acceptance pending

## Goal

Add the smallest high-value sharing increment to Shelf: one explicit native Share action per persisted item, using macOS sharing services (including AirDrop when the system offers it) without adding custom networking, broader file authority, persistence fields, polling, or global input monitoring.

## Product behavior

Each Shelf row gains one **Share** action.

On explicit Share:

1. resolve the existing read-only security-scoped bookmark through `ShelfStore`;
2. acquire security-scoped access for the resolved URL;
3. present that file URL with native `NSSharingServicePicker`;
4. let macOS expose the applicable system sharing services for that item;
5. keep the read-only scope only while NotchHub owns the active sharing operation;
6. release the scope on picker cancellation, sharing success, sharing failure, replacement, controller close, or application termination.

If bookmark resolution, anchor discovery, or scope acquisition fails, the action fails closed and reuses Shelf's existing unavailable-item presentation.

If another Share operation is already active, it is closed and its scope released **before** the next scope is acquired. A failed replacement therefore cannot leave an old sharing operation holding authority after replacement begins.

## Scope

Included:

- one Share action per persisted Shelf item;
- native `NSSharingServicePicker`;
- system-provided sharing services, including AirDrop when available for the selected file;
- one active item at a time;
- deterministic security-scope lifecycle abstraction in Core;
- AppKit controller owned for application lifetime;
- cancellation/success/failure/replacement/termination cleanup;
- Swift 6.3-safe delegate isolation boundary;
- accessibility label/identifier for the Share action;
- automated policy, lifecycle, compile, packaging, entitlement, size and regression coverage.

Deferred:

- Shelf multi-selection and multi-item sharing;
- custom AirDrop discovery/transport;
- custom network client or peer protocol;
- share history/favorites;
- drag-to-share shortcuts;
- copy/move/rename/delete;
- text/URL snippets (M3);
- global keyboard/input monitors.

## Security constraints

Shipping entitlements remain exactly:

- `com.apple.security.app-sandbox = true`;
- `com.apple.security.files.user-selected.read-only = true`.

M2.3 must not introduce:

- read-write or broad filesystem entitlement;
- network entitlement or custom network client;
- Automation/Apple Events;
- Accessibility/Input Monitoring/Screen Recording;
- dynamic-code exceptions;
- source-file delete/move/rename/copy authority;
- raw path persistence;
- timer/polling/filesystem scan;
- third-party runtime dependency.

The sharing security scope is longer-lived than Open/Reveal only because the native sharing service may consume the file asynchronously. It remains explicit, single-item, read-only, and bounded by the app-owned sharing lifecycle.

## Architecture

### Core lifecycle boundary

`ShelfShareAccessSession` owns at most one active URL and depends on `ShelfSecurityScopeControlling`.

Rules:

- `begin(url:)` releases any previous scope first;
- failed start leaves no active scope;
- `end()` is idempotent;
- every successful start is balanced exactly once.

### AppKit sharing boundary

`ShelfShareController` remains `@MainActor` and owns the active `NSSharingServicePicker` plus `ShelfShareAccessSession`.

Swift 6.3 actor-isolation checking exposed that `NSSharingServicePickerDelegate` requirements are nonisolated while sharing completion callbacks can be main-actor isolated. M2.3 therefore uses separate delegate boundaries rather than weakening concurrency checking:

- `ShelfSharePickerDelegate` is a narrow non-actor proxy implementing `NSSharingServicePickerDelegate`;
- cancellation is marshalled to a `@MainActor @Sendable` closure;
- `ShelfShareServiceDelegate` implements `NSSharingServiceDelegate` and forwards success/failure through main-actor closures;
- `@preconcurrency` is intentionally not used as an escape hatch.

The controller owns no timer, worker loop, network client, filesystem scan, global monitor, or source-file mutation path.

### Composition

`AppDelegate` owns `ShelfShareController` for application lifetime and closes it on normal termination. `ShelfRoutingRootView` injects it into `ShelfView`. `ShelfView` only resolves the existing bookmark and forwards the explicit item URL.

M2.3 does not modify media transport, Shelf persistence schema, Quick Look ownership, notch transition internals, or entitlements.

## Performance constraints

- zero recurring work while Share is idle;
- no custom AirDrop/network discovery;
- one bounded native picker/controller while active;
- no polling, timer, filesystem watcher, background task loop, or global input monitor;
- existing M2.1 feature-size envelope remains the active budget unless measured CI evidence proves otherwise.

## Testing strategy

RED → GREEN evidence is required across these layers:

1. compile RED for the initially absent `ShelfShareAccessSession` contract;
2. unit GREEN for balanced scope ownership, fail-closed acquisition, replacement ordering and idempotent end;
3. source-policy RED for Share UI, native picker, lifecycle cleanup, app composition and forbidden authority;
4. initial AppKit implementation compiled against canonical macOS 26 / Swift 6.3.3;
5. compiler-detected actor-isolation failure is fixed with the narrow nonisolated picker proxy, not suppressed;
6. all Swift tests and warnings-as-errors builds pass;
7. external application XCUITest smoke remains green for existing application behavior;
8. release/security/package/effective-entitlement/size/performance gates pass;
9. final exact documented-head CI passes before the PR can become automated-accepted.

CI deliberately does **not** select a system sharing destination or AirDrop recipient: doing so would create nondeterministic external side effects and depend on runner services/devices. The native sharing boundary is instead verified through compile-time AppKit integration, deterministic lifecycle tests and exact source-policy constraints.

Automation is the merge acceptance gate under the current personal-use policy. Physical use remains optional diagnostics unless a later specification explicitly changes that policy.

## Clean-room boundary

Competitive products may inform observable workflow goals only. M2.3 is independently designed from macOS platform APIs and existing NotchHub architecture. No third-party implementation code, tests, internal type structure, or algorithm is copied into this MIT project.
