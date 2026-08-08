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

## Runtime structure

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

The global observer is still a candidate for removal because P0 measured materially higher active-hover CPU than untouched idle. A reliable `NSTrackingArea` / window-local design is preferred only if target-Mac evidence proves accepted hover semantics, cross-display transit, and resource behavior remain equal or better. Correctness is not traded away merely to remove the global monitor; `CGEventTap`, Accessibility, Input Monitoring, or broader event capture are not acceptable substitutes.

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

The current timing candidate is `120 ms`; compact activation also uses a `4 pt` inward inset candidate. Production timing is one cancellable `DispatchWorkItem` scheduled with `DispatchQueue.main.asyncAfter`. There is no repeating `Timer`, polling loop, sleep-driven refresh, or periodic idle work.

The interaction coordinator does **not** mutate the model, animate the panel, or perform haptics. It emits a small interaction intent to the transition coordinator. This prevents multiple owners from independently committing presentation state.

## Presentation transition state machine

`NotchPanelTransitionCoordinator` is the sole authority for presentation transitions.

It separates:

- **desired presentation**: where the interaction currently wants the panel to end;
- **transition phase**: `compact`, `expanding`, `expanded`, or `collapsing`;
- **content presentation**: what SwiftUI is currently allowed to render.

The separation is deliberate. Expanded SwiftUI content remains staged while collapse is animating and switches to compact only when the matching collapse completion wins. This prevents controls from disappearing before the backing window has visually reached the compact endpoint.

Every started transition advances a generation. Cancellation/reversal invalidates the previous generation. A completion may settle state only when its generation is still current, so an old expansion/collapse callback cannot overwrite a newer desired state.

Reversal therefore follows this rule:

1. cancel the current AppKit/Core Animation output;
2. invalidate its generation;
3. preserve the current visible chrome state where the system exposes it;
4. start the new desired transition;
5. ignore any later stale completion from the previous generation.

Tests drive stale callbacks deliberately, including a 10,000-reversal stress sequence, so cancellation correctness is not inferred merely from a cooperative fake driver.

## AppKit animation boundary

NotchHub deliberately uses system animation facilities rather than a custom frame loop.

For a normal transition:

- `NSAnimationContext` animates `NSPanel` frame changes through `panel.animator().setFrame(...)`;
- a `CABasicAnimation` animates `cornerRadius` on the existing layer-backed hosting view;
- both use the same standard-duration candidate (`0.20 s`) and `.easeInEaseOut` timing;
- the model-layer corner radius is set to the target while the presentation layer supplies the current visible starting radius.

On cancellation, `cancelNotchPanelAnimation` reads the current presentation-layer radius, writes that visible value back to the model layer with implicit actions disabled, and only then removes the old corner animation. This prevents the rounded chrome from jumping to an obsolete target before a reversal begins.

For Reduced Motion or any zero-duration policy, the exact frame/radius endpoint is applied synchronously and completion runs once without installing a visible animation.

The runtime does not use `CADisplayLink`, `CVDisplayLink`, repeating timers, sleeps, custom interpolation loops, private window APIs, or synthetic input for transition animation.

## Reduced Motion

The standard animation duration policy is intentionally tiny and deterministic:

- normal motion: `0.20 s` candidate;
- Reduce Motion: `0 s`.

`NotchPanelController` observes `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification` through the selector-based `NotificationCenter` API. It caches only the current boolean to suppress duplicate notifications. On an actual value change, the controller asks `NotchPanelTransitionCoordinator` to retarget the currently desired presentation.

If Reduce Motion becomes enabled during an in-flight transition, the transition is cancelled/restarted to the same desired endpoint using zero duration. This policy retarget must not emit a second haptic. Observer teardown is explicit during controller invalidation.

This is a public display accessibility preference and does not require Accessibility permission, Input Monitoring, or an additional entitlement.

## Haptic architecture

The transition coordinator, not the pointer monitor or view, decides haptic eligibility.

Exactly one feedback request may occur when a deliberate user dwell creates a real compact -> expanded transition. The current hardware candidate is:

```swift
NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
```

No haptic is requested for quick/cancelled transit, duplicate pointer events, retention, collapse, startup synchronization, programmatic expansion, stale callbacks/completions, or animation-policy retargeting. Reversal cannot create a second feedback request simply because the current visual transition changes direction.

macOS may legitimately vary or suppress physical feedback depending on device/touch state/settings. Physical tactile feel remains a target-Mac acceptance concern.

## Visual ownership

Outer panel clipping has one owner: the AppKit hosting-view layer.

- compact hardware-notch surface is opaque black;
- `masksToBounds = true` remains required;
- corner curve is continuous;
- compact radius is `12 pt`;
- expanded radius is `22 pt`;
- the hosting view autoresizes in both width and height;
- SwiftUI does not independently own the outer clipping contour.

This division was introduced after real-hardware cycles showed square-corner degradation and a separate transparent-compact regression. Visibility and clipping are now independent invariants.

## Resource-efficiency architecture

Runtime work is event-driven by default. Prefer AppKit/Foundation notifications, tracking areas, permission callbacks, and explicit user actions over periodic refresh loops.

The runtime architecture must not introduce polling, repeating timers, display links, or sleep-driven refresh merely to keep state fresh. A primitive that is genuinely necessary must have a narrow owner, documented need, deterministic lifecycle tests where possible, and explicit performance review.

Long-lived adapters must expose lifecycle ownership explicitly:

- event monitors/observers are removed when their owner is torn down;
- tasks/subscriptions are cancellable;
- security-scoped resources are balanced;
- future caches/collections are bounded;
- future media/calendar adapters prefer change notifications over fixed polling.

Performance validation is split deliberately:

1. **deterministic CI invariants** — source-policy scanner, state/lifecycle tests, parser/aggregation correctness, no-per-event pointer task, release-size checks, development-tool isolation;
2. **target-Mac runtime evidence** — CPU, RSS, thread count, stability, wakeup/energy measurements, compositor continuity, and real pointer feel on macOS 26.6.

Shared runner CPU/RAM values are never used as tight release thresholds. See root `PERFORMANCE.md`.

`scripts/perf-baseline.py` and `scripts/performance_policy.py` are repository development/release tools, not runtime components. Packaging/security checks keep them outside `NotchHub.app`; performance measurement is not telemetry.

## Notch geometry

On supported MacBook displays, the camera housing is inferred from public `NSScreen` APIs:

- `NSScreen.safeAreaInsets.top`;
- `NSScreen.auxiliaryTopLeftArea`;
- `NSScreen.auxiliaryTopRightArea`.

Real hardware uses the exact detected notch width. A centered fallback width is used only when no hardware notch is detected. A polished notchless mode remains an M1 product decision.

## Security architecture

The current app is App Sandbox + Hardened Runtime with no dangerous exception entitlements. M0 has zero external Swift runtime dependencies, no runtime subprocess/shell execution, no direct network/WebKit API, no dynamic plug-in loading, and no telemetry/licensing service. `scripts/security-audit.sh` makes these invariants executable CI gates.

M1 interaction/animation work adds internal state machines, public AppKit/Core Animation calls, and public accessibility-display preference observation only. It adds no entitlement, process/network surface, sensitive permission, private API, dynamic loading, synthetic input, or broader global input monitoring.

Future modules keep sensitive access behind narrow adapters and explicit permission state machines. See root `SECURITY.md`.

## Feature-module boundaries

Planned modules are isolated behind feature-specific services/adapters:

1. Shelf
2. Snippets
3. Calendar
4. Translator
5. Media
6. Settings / shortcuts / launch at login

### Shelf

Use sandbox-compatible user-selected/security-scoped file access. Removing a Shelf reference is distinct from deleting its source file.

### Snippets

Store locally inside the sandbox container. Copy-to-clipboard is the safe baseline. Direct paste is a separate Accessibility/security decision and must retain a copy-only fallback.

### Calendar / Translator

Prefer public Apple frameworks and explicit permission/availability states. A denied permission or unavailable model/language is a normal product state, not a crash path.

### Yandex Music

Yandex Music is the primary media target. Media UI depends on a provider boundary rather than a private mechanism directly.

Provider preference order:

1. sandbox-compatible/public supported integration;
2. narrow app-specific integration that does not expand unrelated permissions;
3. isolated MediaRemote/private-API fallback for the personal build only after explicit security, compatibility, and resource-cost review.

A media fallback may not disable Hardened Runtime/library validation, execute external code, introduce general input monitoring, or silently add network/telemetry behavior.

## Product/UI references

Public products such as NotchNook inform interaction research but are not implementation dependencies. NotchHub does not copy proprietary code/assets or pixel-match private UI. See `docs/PRODUCT_REFERENCES.md`.

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

`scripts/release_policy.py` is standard-library-only and owns deterministic release/distribution rules.

`scripts/performance_policy.py` is likewise standard-library-only and owns deterministic runtime source-policy scanning, process-sample parsing/aggregation, and reproducible budget comparisons. GitHub Actions orchestrates tested policy rather than embedding it as untestable shell logic.
