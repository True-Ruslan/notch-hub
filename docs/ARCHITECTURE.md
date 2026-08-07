# Architecture

## Goals

NotchHub is a native, local-first macOS productivity hub that uses the area around the MacBook camera housing as a compact launcher for focused tools.

The project prioritizes:

- native macOS behavior and low idle overhead;
- explicit module boundaries;
- deterministic, testable core logic;
- security-by-default with App Sandbox and Hardened Runtime;
- minimal permissions/entitlements;
- no telemetry and no direct network dependency unless a feature is explicitly reviewed to require one;
- graceful behavior on displays without a hardware notch;
- stable operation on the primary current target, macOS 26.6.

## Technology

- Swift 6
- SwiftUI for view composition
- AppKit for window/panel behavior and macOS integration
- Swift Package Manager for builds and tests
- GitHub Actions for CI, macOS 26 compatibility, security gates, and release packaging

Minimum deployment target: macOS 14.
Primary current physical acceptance target: macOS 26.6.

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

Hardware/interaction decisions are intentionally moved out of view callbacks. `NotchGeometry` and `NotchPointerPolicy` are deterministic logic that can be unit-tested without a physical MacBook notch.

The first hardware regression proved why this boundary matters: resizing an `NSPanel` from SwiftUI `onHover` created a feedback loop. The corrected architecture reads current pointer location at the AppKit boundary and delegates the state decision to the pure screen-space pointer policy.

## Window and pointer strategy

The UI is hosted in a borderless, non-activating `NSPanel`. The panel:

- floats above normal application windows;
- can join all Spaces;
- can appear as a fullscreen auxiliary window;
- does not place NotchHub in the Dock (`LSUIElement` + accessory activation policy).

The panel has `compact` and `expanded` states.

Pointer monitoring is intentionally narrow: the controller observes mouse movement/drag event classes and reads only `NSEvent.mouseLocation`. It does not monitor global key events and does not store pointer history/event data. Security policy/CI prohibit keyboard event masks in runtime sources.

## Notch geometry

On supported MacBook displays, the camera housing is inferred from:

- `NSScreen.safeAreaInsets.top`;
- `NSScreen.auxiliaryTopLeftArea`;
- `NSScreen.auxiliaryTopRightArea`.

If those values do not describe a notch, NotchHub falls back to a centered top panel. A dedicated polished notchless handler is an M1 product decision rather than an accidental fallback.

## Security architecture

The default distributed/test app is signed with:

- App Sandbox entitlement enabled;
- Hardened Runtime enabled;
- no dangerous runtime exception entitlements.

At M0 there are zero external Swift runtime dependencies, no subprocess/shell execution, no direct network/WebKit API, no dynamic plug-in loading, and no telemetry/licensing service. `scripts/security-audit.sh` makes these current invariants executable CI gates.

Future modules must keep sensitive access behind narrow adapters and explicit permission state machines. See root `SECURITY.md` for the authoritative security contract.

## Feature modules

Planned modules are isolated behind feature-specific services/adapters:

1. Shelf
2. Snippets
3. Calendar
4. Translator
5. Media
6. Settings / shortcuts / launch at login

### Shelf

Use sandbox-compatible user-selected/security-scoped file access. The app stores references/bookmarks necessary for the shelf, not broad filesystem authority. Shelf removal is semantically distinct from deleting the source file.

### Snippets

Store locally inside the sandbox container. Copy-to-clipboard is the safe baseline. Direct paste is a separate Accessibility/security decision and must retain a copy-only fallback.

### Calendar / Translator

Prefer Apple public frameworks and explicit permission/availability states. A denied permission or unavailable model/language is a normal product state, not an exceptional crash path.

### Yandex Music

Yandex Music is the primary media target. The media module will depend on a provider protocol so UI/state never depends directly on a private mechanism.

Provider preference order:

1. sandbox-compatible/public supported integration;
2. narrow app-specific integration that does not expand unrelated permissions;
3. isolated MediaRemote/private-API fallback for the personal build only after explicit security and macOS 26.6 compatibility review.

A media fallback may not disable Hardened Runtime/library validation, execute external code, introduce general keyboard monitoring, or silently add network/telemetry behavior.

## Product/UI references

Public products such as NotchNook can inform interaction research (gesture ergonomics, multi-monitor/notchless presentation, module density) but are not implementation dependencies. NotchHub does not copy proprietary code/assets or pixel-match private UI. See `docs/PRODUCT_REFERENCES.md`.

## Distribution architecture

There are two deliberately different artifact classes:

### PR/test artifact

- built automatically in CI;
- App Sandbox + Hardened Runtime enabled;
- ad-hoc signed;
- packaged as DMG and integrity-checked;
- expected to trigger normal Gatekeeper trust limitations because it is not Developer ID/notarized;
- used only for real-hardware development acceptance.

### Stable GitHub Release

- built from accepted `main`/matching `VERSION`;
- Developer ID Application signed with secure timestamp;
- DMG signed;
- submitted to Apple notarization using `notarytool`;
- notarization ticket stapled/validated;
- app Gatekeeper-assessed from the mounted DMG;
- SHA-256 checksum generated;
- published automatically to GitHub Releases only after all gates succeed.

Release credentials exist only as GitHub `release` environment secrets and must never enter source, logs, issues, chat, or artifacts. See `docs/RELEASING.md`.
