# NotchHub

Native, local-first macOS productivity hub built around the MacBook notch.

NotchHub turns the area around the camera housing into a compact panel for everyday tools. The planned first modules are file Shelf, Snippets, Calendar, Translator, and media controls with **Yandex Music** as the primary player.

## Status

Early engineering foundation. The current bootstrap implements the native panel shell, deterministic notch geometry, automated tests, and DMG packaging.

See:

- [`docs/PROJECT_STATE.md`](docs/PROJECT_STATE.md)
- [`docs/ROADMAP.md`](docs/ROADMAP.md)
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)

## Requirements

- macOS 14+
- Xcode / Swift 6 toolchain for development

The final personal-use build is distributed as a normal macOS `.dmg`; development tools are not required after installation.

## Development

```bash
swift build
swift test --parallel
```

Build an ad-hoc signed application bundle:

```bash
./scripts/build-app.sh
open build/NotchHub.app
```

Build a DMG installer:

```bash
./scripts/build-dmg.sh
```

The resulting file is `build/NotchHub.dmg`.

## Architecture

The app is written in Swift 6 using SwiftUI for UI and AppKit for panel/window integration. Hardware-notch measurements are derived from public `NSScreen` safe-area APIs and isolated behind pure geometry logic so they can be unit-tested.

The media layer will be provider-based. Yandex Music is the primary compatibility target; any use of private macOS MediaRemote APIs will remain isolated behind an adapter and will not leak into the rest of the application.

## Distribution

CI produces an ad-hoc signed DMG suitable for personal testing. Developer ID signing and notarization will be added later if we decide to distribute the app more broadly or want a warning-free first launch on other Macs.

## Privacy

The baseline app is local-only and makes no network requests. Future modules must document any additional permissions or network use explicitly.
