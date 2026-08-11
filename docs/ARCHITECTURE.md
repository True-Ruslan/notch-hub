# Architecture

## Goals

NotchHub is a native, local-first macOS productivity hub built around the MacBook camera housing.

Architecture priorities:

- native macOS behavior;
- very low continuous overhead;
- deterministic/testable state boundaries;
- explicit ownership of window geometry and lifecycle;
- App Sandbox + Hardened Runtime;
- minimal entitlements/permissions;
- no telemetry/direct network dependency in the current product;
- event-driven behavior instead of periodic polling;
- graceful fallback on displays without a hardware notch;
- primary physical acceptance on macOS 26.6 / `Mac16,8`.

## Technology

- Swift 6
- SwiftUI for view composition
- AppKit for panel/window/system integration
- Core Animation for compositor-backed transition chrome
- Swift Package Manager
- Python standard-library policy/acceptance tooling
- GitHub Actions for CI, security, packaging and release gates

Minimum deployment target: macOS 14.

## Current package and dependency boundaries

```text
NotchHub product
  -> NotchHubApp                      # application composition root
      -> NotchHubCore                 # notch geometry/interaction/transition ownership
      -> NotchHubMediaCore            # normalized media state + shipping media runtime

NotchHubCore
  -X-> NotchHubMediaCore              # Core remains media-independent

MediaBridgeProbe                      # development-only M6.1 tool
  -> MediaBridgeProbeCore
  -> never bundled into NotchHub.app

ProductionMediaTransportCandidate     # development/acceptance-only tool
  -> never bundled into NotchHub.app
```

M6.4 is the point where `NotchHubApp` began linking `NotchHubMediaCore` and exact pinned production media resources. M6.5 adds the presentation layer through the App composition root without moving media concepts into `NotchHubCore`.

## Notch runtime ownership

```text
NotchHubApp.AppDelegate
  -> NotchPanelController
      -> ScreenGeometryInput / NotchGeometry
      -> NotchPointerMonitor
      -> NotchInteractionCoordinator
          -> NotchPointerPolicy
          -> one cancellable delayed activation work item
      -> NotchPanelTransitionCoordinator     # sole presentation/geometry transition authority
          -> NotchPanelModel                 # content presentation state
          -> AppKit animation boundary
          -> AppKit haptic performer
      -> injected SwiftUI content host

AppDelegate
  -> ShippingMediaPresentationModel          # App-owned UI projection survives runtime instance
  -> ShippingMediaRuntime                    # exists only for settled expanded media lifecycle
  -> MediaNotchRootView                      # App-level media-aware composition
```

Core rule: pointer input creates intent; one transition coordinator decides presentation; one AppKit boundary applies panel geometry/chrome. SwiftUI does not own the outer window frame.

## Notch geometry

Hardware notch geometry is derived from public `NSScreen` values:

- `safeAreaInsets.top`;
- `auxiliaryTopLeftArea`;
- `auxiliaryTopRightArea`.

Ordinary hardware compact uses the exact detected physical-notch width.

M6.5 adds a generic `NotchLayout.withCompactHorizontalExtension(_:)` input. When retained media context exists, the current compact target receives a symmetric 36 pt horizontal extension on both sides. The detected hardware notch width and expanded frame are unchanged.

This solves physical camera-housing occlusion without creating a second panel-frame owner. `NotchPanelTransitionCoordinator` still receives the current layout and remains the only presentation transition authority.

Displays without a hardware notch keep the existing centered fallback behavior; a polished notchless mode remains later M1 work.

## Pointer and hover strategy

The borderless non-activating `NSPanel` uses deterministic screen-space pointer policy rather than raw SwiftUI hover-driven resizing.

Accepted interaction flow:

1. `NotchPointerMonitor` delivers local/global `.mouseMoved` events only.
2. `NotchInteractionCoordinator` owns one cancellable 120 ms activation dwell and emits intent.
3. `NotchPanelTransitionCoordinator` accepts the intent with the current layout.
4. AppKit applies the frame/chrome transition.

Compact activation has inclusive 4 pt left/right/bottom protection and 0 pt top protection.

The pointer hot path creates no per-event `Task`. No keyboard/button/drag/scroll global monitor is used. The global `.mouseMoved` fallback remains a P1 optimization candidate and may be replaced only after a reliable local-tracking implementation proves equal-or-better correctness/resource behavior.

## Presentation transition state machine

`NotchPanelTransitionCoordinator` separates:

- desired presentation;
- transition phase (`compact`, `expanding`, `expanded`, `collapsing`);
- SwiftUI content presentation.

Every transition advances a generation. Cancellation/reversal invalidates the old generation; stale completions cannot settle state.

Expanded content remains staged through collapse and switches only when the matching compact completion wins. Reduce Motion retargeting uses the same authority and cannot create duplicate haptics.

## AppKit animation/chrome boundary

Normal transitions use:

- `NSAnimationContext` / `panel.animator().setFrame(...)`;
- `CABasicAnimation` for hosting-layer `cornerRadius`;
- `0.20 s` ease-in-out timing;
- compact/expanded radii `12 pt / 22 pt`.

Reduce Motion uses a zero-duration exact endpoint.

`NSHostingView.sizingOptions = []` prevents SwiftUI content sizing from owning `NSPanel` geometry. The layer-backed hosting view owns outer clipping; SwiftUI does not duplicate the outer contour.

No display link, custom interpolation loop, periodic timer or sleep-driven animation is used.

## Generic content-composition seam

M6.5 adds `NotchPanelContentFactory` and public `NotchHostingViewFactory.make(rootView:)`.

The seam may replace panel content only. It does **not** transfer ownership of:

- panel creation;
- screen geometry;
- pointer policy;
- transition state;
- frame mutation;
- outer clipping/chrome;
- haptic eligibility.

The default Core path still creates `NotchRootView`. `NotchHubApp` injects `MediaNotchRootView` for the shipping application.

## Universal Media domain and transport

### Normalized media state

`NotchHubMediaCore` owns player-agnostic types:

- `MediaSequence(generation, revision)` ordering;
- `MediaCapabilityState` (`supported / unsupported / unknown`);
- previous/next/seek capability set;
- paused/playing state;
- normalized source identity;
- optional title/artist/album/artwork/timing;
- closed semantic commands: toggle, previous, next, bounded seek;
- media subsystem state (`unavailable / idle / paused / playing`).

Missing values remain missing; the domain does not fabricate metadata/capabilities.

### Media provider/controller

`MediaProvider` is event-driven with explicit `start()` / `stop()` and one event handler.

`MediaSessionController` is the main-actor ordering/lifecycle authority:

- accepts only strictly newer sequence values;
- ignores stale/conflicting duplicates;
- capability-gates previous/next/seek;
- keeps command failure from mutating authoritative state;
- performs at most one controlled restart after unexpected provider failure;
- fails closed after a second failure;
- explicit stop ends that controller lifecycle.

### System media bridge and transport

`SystemMediaBridge` adapts normalized provider semantics to an injected `SystemMediaTransport`.

The accepted concrete transport is implemented by `MediaRemoteSystemTransport` / `MediaRemoteProcessClient` with one reviewed external process boundary:

```text
NotchHub process
  -> fixed /usr/bin/perl process
      -> pinned mediaremote-adapter.pl
      -> pinned MediaRemoteAdapter.framework
```

The application executable itself directly links only system libraries. Private framework resolution/loading happens in the owned compatibility process, not inside NotchHub.

Transport invariants:

- event-driven `stream --no-diff --micros`;
- fixed typed capabilities/toggle/previous/next/bounded-seek arguments;
- no arbitrary shell/executable/argument surface;
- bounded media payloads and stderr/stdout handling;
- explicit process teardown/wait/timeouts;
- stale callbacks rejected;
- no player-specific fallback policy;
- no network/telemetry/listening-history persistence.

## Shipping media lifecycle — M6.4

M6.4 deliberately avoids an always-on media adapter.

`AppDelegate` listens only to **settled** panel presentation:

- settled `.expanded` -> create/start one `ShippingMediaRuntime`;
- settled `.compact` -> stop/release runtime;
- stale/reversed transition completions cannot start media;
- application termination stops runtime before panel teardown.

Accepted physical behavior:

- compact owns zero adapter processes;
- expanded owns exactly one expected adapter;
- normal Quit leaves no orphan.

This presentation-scoped lifecycle remains mandatory in M6.5 and future media UI work.

## Media presentation architecture — M6.5

### App-owned projection model

`ShippingMediaPresentationModel` projects authoritative normalized media state into an immutable UI DTO containing only:

- playback state;
- optional normalized metadata/artwork;
- source display label;
- capability booleans;
- validated/clamped timing.

It does not own transport sequence ordering. `MediaSessionController` has already ordered provider events. This matters because the presentation model survives individual expanded-only runtime instances while each new runtime can restart its local sequence numbering.

### Runtime -> presentation wiring

`ShippingMediaRuntime` receives the App-owned presentation model.

On start it attaches a controller change handler that applies current authoritative state/snapshot.

On normal stop it clears `controller.changeHandler` **before** `controller.stop()` and releases the controller. This intentionally prevents terminal controller teardown state from erasing the last visual media context while keeping the adapter stopped.

If shipping media resources cannot be validated during expanded startup, the presentation model is cleared and the feature fails closed.

M6.5 UI click commands are only:

- toggle play/pause;
- previous;
- next.

They forward through `MediaSessionController` and existing typed transport. Draggable seek is deferred.

### Media-aware SwiftUI root

`MediaNotchRootView` is owned by `NotchHubApp`.

If no presentation exists, it reuses the existing Core `NotchRootView` rather than duplicating Home/Foundation UI.

If presentation exists:

- compact renders left artwork wing + unchanged hardware-notch center + right status wing;
- expanded renders supplied artwork/metadata/source and capability-driven controls;
- trustworthy timing renders a static `ProgressView`;
- missing metadata produces no fake/empty row;
- unsupported/unknown previous/next controls remain disabled.

When media disappears while expanded, presentation clears and the existing Home view becomes visible while the panel itself remains expanded.

## Resource-efficiency architecture

Runtime work is event-driven by default. Prefer OS notifications/callbacks and explicit user actions over periodic refresh.

Long-lived owners must have explicit teardown for observers, event monitors, processes, tasks/subscriptions and security-scoped resources. Collections/caches must remain bounded.

M6.5 adds no repeating timer, display link, polling loop, global scroll monitor or compact media observer. Compact retained media may therefore be visually stale until the next expansion; this is an intentional tradeoff preserving the accepted zero-adapter compact resource invariant.

Performance validation is split into:

1. deterministic CI invariants — source policy, state/lifecycle tests, package/signature/security/provenance and artifact-size checks;
2. target-Mac evidence — CPU/RSS/threads/stability, real UI/player behavior and later energy/wakeup/compositor measurements.

The immutable P0 baseline remains historical evidence. M6.4 and M6.5 intentional shipping growth uses separate provenance-backed feature budgets rather than rewriting it.

## Security architecture

The shipping application remains App Sandbox + Hardened Runtime with no dangerous exception entitlements.

Current authority includes no direct app networking, no telemetry, no bundled secrets, no Accessibility/Input Monitoring/Automation/Screen Recording permission, and no broad input capture beyond the existing `.mouseMoved` fallback.

The Universal Media external process is the sole reviewed runtime subprocess exception. Security details and fail-closed constraints are authoritative in root `SECURITY.md`.

## Planned module boundaries

Future modules remain isolated behind feature-specific services/adapters:

1. Shelf — sandbox-compatible user-selected/security-scoped file access.
2. Snippets — sandbox-local store; copy baseline; direct paste only after separate Accessibility decision.
3. Calendar — EventKit adapter with explicit permission states.
4. Translator — Apple Translation where available; no direct network translation without review.
5. Universal Media — next: local gestures/haptics/draggable seek, then P1 performance review.
6. Product shell — settings/shortcuts/launch-at-login.

## Current next architecture slice

After M6.5 integration, define the local media gesture/haptic/draggable-seek slice from the approved Universal Media design.

Constraints before implementation:

- no global scroll monitor;
- gesture state machine local to NotchHub;
- haptic eligibility owned deterministically, not emitted directly by raw gesture callbacks;
- seek only when authoritative capability is supported;
- bounded typed seek values;
- no periodic progress worker;
- preserve presentation-scoped runtime and single panel-transition authority;
- target-Mac acceptance before P1 optimization work.