# Project state

Last updated: 2026-08-07

## Product

NotchHub is a personal native macOS productivity hub built around the MacBook notch. The intended first modules are Shelf, Snippets, Calendar, Translator, and media controls with Yandex Music as the primary player.

## Current milestone

M0 - Engineering foundation.

## Implemented in the bootstrap branch

- Swift 6 / Swift Package Manager project layout
- macOS 14 minimum deployment target
- SwiftUI + AppKit application shell
- accessory/background-style app without a Dock icon
- borderless non-activating `NSPanel`
- hardware-notch geometry derived from public `NSScreen` APIs
- fallback geometry for non-notch displays
- compact/expanded hover state
- unit tests for geometry and state transitions
- CI for build, tests, `.app`, and `.dmg`
- tag-driven GitHub Release workflow
- architecture and roadmap documentation

## Known limitations

- panel is initially attached to `NSScreen.main`; active-display migration is not implemented yet;
- hover collapse is immediate and needs hysteresis/delay tuning;
- UI is a structural preview rather than final product design;
- no feature modules are wired yet;
- release artifacts are ad-hoc signed, not Developer ID signed/notarized;
- Yandex Music integration is planned but not implemented in M0.

## Quality policy

Automation should cover deterministic behavior before manual acceptance. Manual testing is reserved for behavior that depends on physical notch geometry, pointer feel, OS-level permissions, third-party media integration, and final visual quality.

## Next optimal step

Finish M0 by making CI green and installing the generated DMG on real hardware. Then start M1 with delayed collapse, active-screen migration, display-change handling, and a small real-hardware acceptance matrix.
