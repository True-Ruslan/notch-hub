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
- Swift Package Manager for builds and tests
- Python standard-library policy tooling for deterministic release/performance development checks
- GitHub Actions for CI, macOS 26 compatibility, security gates, packaging, and release publication

Minimum deployment target: macOS 14.
Primary physical acceptance target: macOS 26.6.

## Runtime structure

```text
NotchHubApp
  -> AppDelegate
      -> NotchPanelController          # thin AppKit/event wiring
          -> ScreenGeometryInput       # NSScreen adapter
          -> NotchGeometry             # pure geometry policy
          -> NotchPointerPolicy        # pure activation/retention policy
          -> NotchPanelModel           # explicit presentation state
          -> NotchRootView             # SwiftUI rendering only
```

Hardware/interaction decisions are intentionally moved out of view callbacks. `NotchGeometry` and `NotchPointerPolicy` are deterministic and unit-testable without a physical MacBook notch.

The first hardware regression proved why this boundary matters: resizing an `NSPanel` directly from raw SwiftUI `onHover` feedback created an oscillation loop. The corrected controller reads pointer location at the AppKit boundary and delegates the state decision to pure screen-space policy. `NSHostingView.sizingOptions = []` keeps actual window geometry owned by AppKit rather than SwiftUI content sizing.

## Window and pointer strategy

The UI is hosted in a borderless, non-activating `NSPanel`. It floats above normal windows, can join Spaces, can be a fullscreen auxiliary window, and does not place NotchHub in the Dock (`LSUIElement` + accessory activation policy).

The panel has explicit `compact` and `expanded` states. Current global observation is deliberately restricted to `mouseMoved`, with no persisted pointer history and no keyboard/button/scroll/drag monitoring.

Performance Foundation measures the real cost of that global movement observer before M1. M1 will prefer a reliable `NSTrackingArea`/window-local design only if it preserves all accepted hover semantics and measurably improves or matches the resource/input-observation profile. Correctness is not traded away merely to remove the global monitor.

## Resource-efficiency architecture

Runtime work is event-driven by default. Prefer AppKit/Foundation notifications, tracking areas, permission callbacks, and explicit user actions over periodic refresh loops.

The runtime architecture must not introduce polling, repeating timers, display links, or sleep-driven refresh merely to keep state fresh. A primitive that is genuinely necessary must have a narrow owner, documented cadence/need, deterministic lifecycle tests where possible, and an explicit performance-policy review.

Long-lived adapters must expose lifecycle ownership explicitly:

- event monitors/observers are removed when their owner is torn down;
- tasks/subscriptions are cancellable;
- security-scoped resources are balanced;
- future caches/collections are bounded;
- future media/calendar adapters prefer change notifications over fixed polling.

Performance validation is split deliberately:

1. **deterministic CI invariants** — source-policy scanner, state/lifecycle tests, parser/aggregation correctness, development-tool isolation, reproducible artifact-size checks;
2. **target-Mac runtime evidence** — CPU, RSS, thread count, stability, and future wakeup/energy measurements on macOS 26.6.

Shared runner CPU/RAM values are never used as tight release thresholds. See root `PERFORMANCE.md`.

`scripts/perf-baseline.py` and `scripts/performance_policy.py` are repository development/release tools, not application runtime components. Packaging/security checks must keep them outside `NotchHub.app`; performance measurement is not telemetry.

## Notch geometry

On supported MacBook displays, the camera housing is inferred from:

- `NSScreen.safeAreaInsets.top`;
- `NSScreen.auxiliaryTopLeftArea`;
- `NSScreen.auxiliaryTopRightArea`.

Real hardware uses the exact detected notch width. A centered fallback width is used only when no hardware notch is detected. A polished notchless mode remains an M1 product decision.

## Security architecture

The current app is App Sandbox + Hardened Runtime with no dangerous exception entitlements. M0 has zero external Swift runtime dependencies, no runtime subprocess/shell execution, no direct network/WebKit API, no dynamic plug-in loading, and no telemetry/licensing service. `scripts/security-audit.sh` makes these invariants executable CI gates.

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

Use sandbox-compatible user-selected/security-scoped file access. Store only references/bookmarks needed for the Shelf; removing an item from Shelf is distinct from deleting its source file.

### Snippets

Store locally inside the sandbox container. Copy-to-clipboard is the safe baseline. Direct paste is a separate Accessibility/security decision and must retain a copy-only fallback.

### Calendar / Translator

Prefer public Apple frameworks and explicit permission/availability states. A denied permission or unavailable model/language is a normal product state, not a crash path.

### Yandex Music

Yandex Music is the primary media target. The media UI depends on a provider protocol rather than a private mechanism directly.

Provider preference order:

1. sandbox-compatible/public supported integration;
2. narrow app-specific integration that does not expand unrelated permissions;
3. isolated MediaRemote/private-API fallback for the personal build only after explicit security, compatibility, and resource-cost review.

A media fallback may not disable Hardened Runtime/library validation, execute external code, introduce general input monitoring, or silently add network/telemetry behavior.

## Product/UI references

Public products such as NotchNook inform interaction research (gesture ergonomics, multi-monitor/notchless presentation, module density) but are not implementation dependencies. NotchHub does not copy proprietary code/assets or pixel-match private UI. See `docs/PRODUCT_REFERENCES.md`.

## Distribution architecture

There are three deliberately distinct artifact classes.

### CI test artifact

- automatic on PR/main CI;
- App Sandbox + Hardened Runtime;
- ad-hoc signed;
- DMG integrity checked;
- unversioned development artifact;
- may trigger normal Gatekeeper trust warnings.

### Personal Release — current default

- manually dispatched from the exact protected `main` commit;
- strict `VERSION`/versioned-notes policy;
- repeats format, security, warnings-as-errors, full tests, packaging, signature, entitlement, system-library, and DMG checks;
- explicitly verifies `Signature=adhoc` + Hardened Runtime + exact Sandbox entitlement;
- generates SHA-256 and machine-readable build provenance;
- publishes `NotchHub.dmg`, `NotchHub.dmg.sha256`, and `build-metadata.json` through an immutable `v<SemVer>` GitHub Release;
- release title/notes explicitly say `Personal build` / not notarized;
- cannot overwrite an existing tag/release;
- requires no Apple credentials and never disables Gatekeeper.

### Trusted Release — optional future tier

- manual future-only path behind GitHub `release` environment;
- Developer ID Application signing;
- Apple notarization + stapling;
- Gatekeeper assessment;
- checksum publication;
- cannot overwrite a Personal Release or any existing version.

The annual Apple Developer Program dependency is intentionally deferred while NotchHub remains personal-use software. See `docs/RELEASING.md`.

## Policy tooling

`scripts/release_policy.py` is intentionally small and standard-library-only. Unit tests cover strict SemVer/tag rules, trust-label requirements, unsafe Gatekeeper-bypass text, immutable workflow boundaries, and provenance metadata validation.

`scripts/performance_policy.py` is likewise standard-library-only and owns deterministic runtime source-policy scanning, process-sample parsing/aggregation, and reproducible budget comparisons. GitHub Actions orchestrates these tested policies rather than embedding policy logic as untestable shell text.
