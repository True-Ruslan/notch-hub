# Architecture

## Goals

NotchHub is a native, local-first macOS productivity hub that uses the area around the MacBook camera housing as a compact launcher for focused tools.

The project prioritizes:

- native macOS behavior and very low continuous overhead;
- explicit module boundaries;
- deterministic, testable core logic;
- security-by-default with App Sandbox and Hardened Runtime;
- minimal permissions/entitlements;
- no telemetry and no direct network dependency unless a feature is explicitly reviewed to require one;
- graceful behavior on displays without a hardware notch;
- stable operation on the primary target, macOS 26.6.

## Technology

- Swift 6
- SwiftUI for view composition
- AppKit for window/panel behavior and macOS integration
- Core Animation only for system/compositor-backed visual transitions
- Swift Package Manager for builds and tests
- Python standard-library policy tooling for deterministic release/performance development checks
- GitHub Actions for CI, macOS 26 compatibility, security gates, packaging, and release publication

Minimum deployment target: macOS 14.
Primary physical acceptance target: macOS 26.6.

## Package and shipping boundaries

The package deliberately separates code that is already part of the current Personal Release from production media architecture that is implemented and tested but not yet composed into the app:

```text
NotchHub product
  -> NotchHubApp
      -> NotchHubCore

NotchHubMediaCore                    # production media domain/controller boundary
  -> no dependency from NotchHubApp yet
  -> built and tested by CI

MediaBridgeProbe                     # development-only M6.1 acceptance tool
  -> MediaBridgeProbeCore
  -> never bundled into NotchHub.app
```

`NotchHubMediaCore` is intentionally a separate Swift target. M6.2 proved that placing an otherwise dormant media controller directly in `NotchHubCore` caused the shipping executable to exceed the unchanged P0 relative size budget even before media was composed into the app. Moving the production media boundary into its own target restored the shipping payload exactly to the accepted pre-M6.2 values while retaining full build/test coverage.

This isolation is not a claim that production media will have zero cost. The concrete transport/composition slice must explicitly link the media module into the shipping application, measure the real feature cost, and pass a fresh security/performance/package review rather than hiding that cost in an inactive build.

## Current Notch runtime structure

```text
NotchHubApp
  -> AppDelegate
      -> NotchPanelController                 # thin AppKit/event composition root
          -> ScreenGeometryInput              # NSScreen adapter
          -> NotchGeometry                    # pure geometry policy
          -> NotchPointerMonitor              # lifecycle-owned local/global mouseMoved delivery
          -> NotchInteractionCoordinator      # dwell/cancellation; emits interaction intents only
              -> NotchPointerPolicy           # pure activation/retention policy
              -> one-shot DispatchWorkItem    # injected in tests; no polling/repeating timer
          -> NotchPanelTransitionCoordinator  # sole presentation-transition authority
              -> NotchPanelModel              # SwiftUI content presentation only
              -> animateNotchPanel(...)        # NSAnimationContext + Core Animation boundary
              -> cancelNotchPanelAnimation(...)
              -> AppKitNotchHapticPerformer   # one public AppKit feedback request when eligible
          -> NotchRootView                    # SwiftUI rendering only
```

Hardware/interaction decisions are intentionally kept out of SwiftUI hover callbacks. `NotchGeometry`, `NotchPointerPolicy`, the interaction coordinator, and the transition coordinator expose deterministic state decisions that unit tests can drive without a physical notch.

The original hardware regression demonstrated why ownership matters: resizing an `NSPanel` directly from raw SwiftUI `onHover` feedback created an oscillation loop. M1 therefore separates three concerns explicitly:

1. pointer/time input produces an intent;
2. one transition coordinator decides lifecycle/content/haptic semantics;
3. a narrow AppKit animation boundary applies the requested frame/chrome transition.

`NSHostingView.sizingOptions = []` keeps actual window geometry owned by AppKit rather than SwiftUI content sizing.

## Window and pointer strategy

The UI is hosted in a borderless, non-activating `NSPanel`. It floats above normal windows, can join Spaces, can be a fullscreen auxiliary window, and does not place NotchHub in the Dock (`LSUIElement` + accessory activation policy).

Global observation remains deliberately restricted to `.mouseMoved`, with no persisted pointer history and no keyboard/button/scroll/drag monitoring.

`NotchPointerMonitor` owns exactly one local and one global `.mouseMoved` token, installs them at most once, and removes them idempotently. Its production AppKit callbacks are delivered on the main thread and are bridged synchronously through `MainActor.assumeIsolated`; the runtime no longer creates a `Task` for each mouse-move event. This is a hot-path allocation reduction, not an expansion of input authority.

The global observer remains a candidate for removal because P0 measured materially higher active-hover CPU than untouched idle. A reliable `NSTrackingArea` / window-local design is preferred only if target-Mac evidence proves accepted hover semantics, cross-display transit, and resource behavior remain equal or better. That comparison is deliberately scheduled inside P1 after the functional Universal Media slice so optimization is measured against the real application. `CGEventTap`, Accessibility, Input Monitoring, or broader event capture are not acceptable substitutes.

## Delayed hover intent architecture

Compact -> expanded pointer activation first passes through `NotchInteractionCoordinator`.

The interaction coordinator owns exactly one optional pending activation and a monotonically changing generation. Its rules are:

- pointer entry into the compact activation region schedules one dwell if none is pending;
- duplicate movement does not schedule additional work;
- exit before completion cancels immediately;
- cancellation invalidates the generation so a stale callback cannot emit a later intent;
- re-entry receives a fresh generation and full dwell;
- expanded retention/collapse bypasses activation dwell;
- setup/current-pointer synchronization is non-activating;
- invalidation cancels pending work.

The accepted timing is `120 ms`; compact activation uses 4 pt inward protection on left/right/bottom and no top inset, with exact accepted boundaries treated inclusively. Production timing is one cancellable `DispatchWorkItem` scheduled with `DispatchQueue.main.asyncAfter`. There is no repeating `Timer`, polling loop, sleep-driven refresh, or periodic idle work.

The interaction coordinator does **not** mutate the model, animate the panel, or perform haptics. It emits a small interaction intent to the transition coordinator. This prevents multiple owners from independently committing presentation state.

## Presentation transition state machine

`NotchPanelTransitionCoordinator` is the sole authority for presentation transitions.

It separates:

- **desired presentation**: where the interaction currently wants the panel to end;
- **transition phase**: `compact`, `expanding`, `expanded`, or `collapsing`;
- **content presentation**: what SwiftUI is currently allowed to render.

Expanded SwiftUI content remains staged while collapse is animating and switches to compact only when the matching collapse completion wins. Every started transition advances a generation. Cancellation/reversal invalidates the previous generation, and only the current generation may settle state.

Reversal follows this rule:

1. cancel the current AppKit/Core Animation output;
2. invalidate its generation;
3. preserve the current visible chrome state where the system exposes it;
4. start the new desired transition;
5. ignore any later stale completion from the previous generation.

Tests drive stale callbacks deliberately, including a 10,000-reversal stress sequence.

## AppKit animation boundary

NotchHub deliberately uses system animation facilities rather than a custom frame loop.

For a normal transition:

- `NSAnimationContext` animates `NSPanel` frame changes through `panel.animator().setFrame(...)`;
- a `CABasicAnimation` animates `cornerRadius` on the existing layer-backed hosting view;
- both use the accepted `0.20 s` duration and `.easeInEaseOut` timing;
- the model-layer corner radius is set to the target while the presentation layer supplies the current visible starting radius.

On cancellation, `cancelNotchPanelAnimation` reads the current presentation-layer radius, writes that visible value back to the model layer with implicit actions disabled, and only then removes the old corner animation.

For Reduced Motion or any zero-duration policy, the exact frame/radius endpoint is applied synchronously and completion runs once without installing a visible animation.

The runtime does not use `CADisplayLink`, `CVDisplayLink`, repeating timers, sleeps, custom interpolation loops, private window APIs, or synthetic input for transition animation.

## Reduced Motion

The standard animation duration policy is:

- normal motion: `0.20 s`;
- Reduce Motion: `0 s`.

`NotchPanelController` observes `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification` through the selector-based `NotificationCenter` API. It caches only the current boolean to suppress duplicate notifications. On an actual value change, the controller asks `NotchPanelTransitionCoordinator` to retarget the currently desired presentation.

If Reduce Motion becomes enabled during an in-flight transition, the transition is cancelled/restarted to the same desired endpoint using zero duration. This policy retarget must not emit a second haptic. Observer teardown is explicit during controller invalidation.

This is a public display accessibility preference and does not require Accessibility permission, Input Monitoring, or an additional entitlement.

## Haptic architecture

The transition coordinator, not the pointer monitor or view, decides haptic eligibility.

Exactly one feedback request may occur when a deliberate user dwell creates a real compact -> expanded transition. The accepted hardware feedback is:

```swift
NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
```

No haptic is requested for quick/cancelled transit, duplicate pointer events, retention, collapse, startup synchronization, programmatic expansion, stale callbacks/completions, or animation-policy retargeting. Reversal cannot create a second feedback request simply because the current visual transition changes direction.

## Visual ownership

Outer panel clipping has one owner: the AppKit hosting-view layer.

- compact hardware-notch surface is opaque black;
- `masksToBounds = true` remains required;
- corner curve is continuous;
- compact radius is `12 pt`;
- expanded radius is `22 pt`;
- the hosting view autoresizes in both width and height;
- SwiftUI does not independently own the outer clipping contour.

## Universal Media production core — M6.2

M6.1 accepted the system Now Playing transport mechanism. M6.2 establishes the production application-side boundary before any concrete private transport is shipped.

Current structure:

```text
future concrete system transport
  -> SystemMediaTransport             # injected typed transport protocol; implementation not yet present
      -> SystemMediaBridge             # player-agnostic provider adapter / callback owner
          -> MediaProvider             # NotchHub semantic provider contract
              -> MediaSessionController # @MainActor ordering/lifecycle/capability authority
                  -> MediaSessionSnapshot

NotchHubApp
  -X-> NotchHubMediaCore               # deliberately not composed/linked yet
```

### Normalized domain

`NotchHubMediaCore` contains immutable normalized media values:

- `MediaSequence(generation, revision)` is the sole ordering primitive and compares generation first, then revision;
- `MediaCapabilityState` is exactly `supported / unsupported / unknown`;
- `MediaCommandCapabilities` carries previous/next/seek independently;
- `MediaPlaybackState` is `paused / playing`;
- `MediaSourceIdentity` stores normalized source identity without player-specific policy;
- `MediaSessionSnapshot` carries normalized optional metadata/artwork/timing/capability state and fabricates no defaults;
- `MediaCommand` is a closed semantic surface: toggle, previous, next, bounded seek;
- `MediaSubsystemState` is `unavailable / idle / paused / playing`.

The snapshot is intentionally not made broadly `Equatable`. Ordering/deduplication authority is `MediaSequence`; full metadata/artwork equality is neither required by the product contract nor used to infer freshness.

### MediaProvider

`MediaProvider` is an event-driven `@MainActor` protocol with exactly one event handler, explicit `start()` / `stop()`, and typed asynchronous command dispatch. It exposes only normalized provider events: ready, session, no-session, failed, stopped.

No source-specific strings, private command IDs, arbitrary command passthrough, polling, persistence, or UI concepts cross this boundary.

### MediaSessionController

`MediaSessionController` owns media state, not Notch presentation state. Its deterministic rules are:

- start is idempotent and owns one active provider handler;
- `.ready` without a session becomes `.idle`;
- only strictly newer `MediaSequence` values are accepted;
- same-sequence duplicates/conflicts and older events are ignored;
- a newer generation supersedes any revision in an older generation;
- newer no-session clears media state only;
- playback state maps authoritatively to paused/playing;
- previous/next/seek are sent only when their capability is `.supported`;
- invalid seek values and unknown/unsupported capabilities fail closed locally;
- command failure does not mutate the authoritative snapshot;
- the first unexpected provider failure clears media state and performs exactly one controlled stop/start restart;
- stale callbacks from the old generation are ignored;
- a second unexpected failure becomes terminal unavailable for that controller lifecycle and cannot create a restart loop;
- explicit stop is terminal for that controller lifecycle.

The controller uses no polling/repeating timer and does not log or persist media metadata.

### SystemMediaBridge

`SystemMediaBridge` is implemented over an injected `SystemMediaTransport` protocol. In M6.2 it contains **no MediaRemote/private API/process/dynamic-loading implementation**.

Its responsibilities are deliberately narrow:

- repeated start is idempotent;
- one start owns one transport callback;
- stop invalidates the callback generation and clears the transport handler before transport teardown;
- stale transport callbacks cannot surface after stop/restart;
- normalized transport events are forwarded into the provider contract;
- typed commands are forwarded only while the bridge is started;
- the bridge contains no UI, gesture, panel, source-priority, logging, persistence, or player-specific policy.

The next security-sensitive slice is to implement the concrete system transport behind this injected boundary using the accepted M6.1 evidence. That future change is the first point at which `NotchHubMediaCore` may be composed into the shipping app, and it requires a fresh security/size/runtime review.

## Resource-efficiency architecture

Runtime work is event-driven by default. Prefer AppKit/Foundation notifications, transport callbacks, tracking areas, permission callbacks, and explicit user actions over periodic refresh loops.

Long-lived adapters must expose lifecycle ownership explicitly:

- event monitors/observers are removed when their owner is torn down;
- tasks/subscriptions are cancellable;
- security-scoped resources are balanced;
- caches/collections are bounded;
- media/calendar adapters prefer change notifications over fixed polling.

Performance validation is split deliberately:

1. **deterministic CI invariants** — source-policy scanner, state/lifecycle tests, parser/aggregation correctness, release-size checks, development-tool isolation;
2. **target-Mac runtime evidence** — CPU, RSS, thread count, stability, wakeup/energy measurements, compositor continuity, and real interaction feel on macOS 26.6.

M6.2 retains the unchanged shipping payload while the media core remains uncomposed: CI #500 on code head `52d6d76b564c603cb21f0ec49bff4fa958c3aac7` passed 117 Swift tests and produced executable/app payloads `250,320 B / 253,317 B`, matching the accepted pre-M6.2 shipping payload exactly. The size budget was not widened.

Shared runner CPU/RAM values are never used as tight release thresholds. See root `PERFORMANCE.md`.

## Notch geometry

On supported MacBook displays, the camera housing is inferred from public `NSScreen` APIs:

- `NSScreen.safeAreaInsets.top`;
- `NSScreen.auxiliaryTopLeftArea`;
- `NSScreen.auxiliaryTopRightArea`.

Real hardware uses the exact detected notch width. A centered fallback width is used only when no hardware notch is detected. A polished notchless mode remains an M1 product decision.

## Security architecture

The shipping app remains App Sandbox + Hardened Runtime with no dangerous exception entitlements. The accepted baseline has no telemetry/licensing service, direct networking, privileged helper, runtime shell/subprocess execution, dynamic plug-in loading, or sensitive input permissions. `scripts/security-audit.sh` and performance policy make these invariants executable CI gates.

M6.1 proved a development-only MediaRemote-compatible transport can satisfy the required target-Mac boundary. M6.2 does **not** move that mechanism into the shipping app. `NotchHubMediaCore` currently contains only normalized domain types, deterministic state/lifecycle logic, provider/transport protocols, and the injected bridge adapter. CI #500 passed the existing security/performance policies without any policy weakening or entitlement change.

A concrete private system transport remains a separately reviewed exception. It must stay behind the accepted bridge boundary, preserve App Sandbox + Hardened Runtime, avoid Accessibility/Input Monitoring/Automation/synthetic input, remain event-driven, and pass new package/security/resource evidence before composition into `NotchHubApp`.

Future modules keep sensitive access behind narrow adapters and explicit permission state machines. See root `SECURITY.md`.

## Feature-module boundaries

Planned modules remain isolated behind feature-specific services/adapters:

1. Shelf
2. Snippets
3. Calendar
4. Translator
5. Universal Media
6. Settings / shortcuts / launch at login

### Shelf

Use sandbox-compatible user-selected/security-scoped file access. Removing a Shelf reference is distinct from deleting its source file.

### Snippets

Store locally inside the sandbox container. Copy-to-clipboard is the safe baseline. Direct paste is a separate Accessibility/security decision and must retain a copy-only fallback.

### Calendar / Translator

Prefer public Apple frameworks and explicit permission/availability states. A denied permission or unavailable model/language is a normal product state, not a crash path.

### Universal Media / System Now Playing

The media milestone follows the system Now Playing source chosen by macOS. Yandex Music and Yandex Browser are physically verified transport sources. Apple Music, Spotify, and another independent player remain deferred compatibility checks and must not be claimed as verified until tested.

Only the isolated media boundary may know the concrete system transport. UI, gesture code, and product state cannot branch on Spotify/Yandex/Apple Music or import private APIs.

The capability contract remains fail-closed:

- unsupported or unknown previous/next/seek actions are not guessed or emulated;
- no Accessibility/Input Monitoring or synthetic media keys are used to manufacture missing support;
- multiple active players follow macOS system source priority;
- transport failure invalidates media state only and leaves Notch Core operational;
- listening history and normal production track metadata are not persisted/logged;
- artwork/metadata are untrusted inputs with bounded validation at the concrete transport boundary;
- current-track state is event-driven rather than refreshed with a permanent one-second timer.

The approved future gesture layer is local to NotchHub's own window. Horizontal swipes control previous/next in compact and expanded media states; vertical gestures retain expand/collapse semantics; seek owns the progress interaction; no global `.scrollWheel` monitor is introduced. Horizontal commands commit on release after an armed threshold, use hysteresis, and request one public `.levelChange` haptic per semantic armed transition rather than every raw event.

Authoritative design: `docs/superpowers/specs/2026-08-09-universal-media-gestures-haptics-design.md`.
Accepted transport evidence: `docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md`.
M6.2 implementation plan: `docs/superpowers/plans/2026-08-09-production-media-boundary.md`.

## Distribution architecture

### CI test artifact

- automatic on PR/main CI;
- App Sandbox + Hardened Runtime;
- ad-hoc signed;
- DMG integrity checked;
- development artifact; may trigger normal Gatekeeper trust warnings.

### Personal Release — current default

- manually dispatched from exact protected `main`;
- strict version/release-note policy;
- repeats quality/security/package gates;
- ad-hoc signature + Hardened Runtime + exact Sandbox entitlement;
- SHA-256 + machine-readable provenance;
- immutable GitHub Release assets;
- no Apple credentials and no Gatekeeper weakening.

### Trusted Release — optional future tier

- future manual path behind a reviewed release environment;
- Developer ID Application signing;
- Apple notarization + stapling;
- Gatekeeper assessment;
- cannot overwrite an existing Personal version.

The annual Apple Developer Program dependency remains intentionally deferred while NotchHub is personal-use software. See `docs/RELEASING.md`.

## Policy tooling

`scripts/release_policy.py` owns deterministic release/distribution rules.

`scripts/performance_policy.py` owns deterministic runtime source-policy scanning, process-sample parsing/aggregation, and reproducible budget comparisons. GitHub Actions orchestrates tested policy rather than embedding it as untestable shell logic.
