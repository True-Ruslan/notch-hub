# Architecture

## Goals

NotchHub is a native, local-first macOS productivity hub that uses the area around the MacBook camera housing as a compact launcher for focused tools.

The project prioritizes:

- native macOS behavior and low idle overhead;
- explicit module boundaries;
- deterministic, testable core logic;
- minimal permissions;
- no network dependency unless a feature explicitly requires one;
- graceful behavior on displays without a hardware notch.

## Technology

- Swift 6
- SwiftUI for view composition
- AppKit for window/panel behavior and macOS integration
- Swift Package Manager for builds and tests
- GitHub Actions for CI and release packaging

Minimum supported OS: macOS 14.

## Runtime structure

```text
NotchHubApp
  -> AppDelegate
      -> NotchPanelController
          -> ScreenGeometryInput
          -> NotchGeometry
          -> NotchPanelModel
          -> NotchRootView
```

`NotchGeometry` is intentionally pure logic. Hardware-specific measurements are adapted from `NSScreen` into `ScreenGeometryInput`, which allows the geometry to be unit-tested without a physical MacBook notch.

## Window strategy

The UI is hosted in a borderless, non-activating `NSPanel`. The panel:

- floats above normal application windows;
- can join all Spaces;
- can appear as a fullscreen auxiliary window;
- does not place NotchHub in the Dock (`LSUIElement` + accessory activation policy).

The panel has two initial states: `compact` and `expanded`.

## Notch geometry

On supported MacBook displays, the camera housing is inferred from:

- `NSScreen.safeAreaInsets.top`;
- `NSScreen.auxiliaryTopLeftArea`;
- `NSScreen.auxiliaryTopRightArea`.

If those values do not describe a notch, NotchHub falls back to a centered top panel so that external displays remain usable.

## Feature modules

Planned modules are isolated behind feature-specific services:

1. Shelf
2. Snippets
3. Calendar
4. Translator
5. Media
6. Settings / hotkeys / launch at login

Media is intentionally last among the first productivity modules because universal third-party Now Playing access is less stable than the public APIs used by the other modules.

### Yandex Music

Yandex Music is the primary media target. The future media module will use an adapter protocol so the UI does not depend directly on any private macOS mechanism. A public/supported provider is preferred where possible; a MediaRemote-based provider may be used as an isolated fallback for personal builds after compatibility tests.

## Distribution

The repository can build an ad-hoc signed `.app` and package it into `NotchHub.dmg`. This is suitable for personal testing.

Developer ID signing and Apple notarization are a later release-hardening milestone and require Apple Developer credentials that must never be committed to the repository.
