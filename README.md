# NotchHub

Native, local-first macOS productivity hub built around the MacBook notch.

NotchHub turns the area around the camera housing into a compact panel for everyday tools. Planned modules are file Shelf, Snippets, Calendar, Translator, and media controls with **Yandex Music** as the primary player.

## Status

Current development version: **0.1.0 (unreleased)**.

M0 engineering foundation is in progress. The app already has the native panel shell, deterministic notch geometry, stable screen-space pointer policy, automated tests, CI, and installable DMG packaging. Real-hardware hover acceptance for the latest fix is still pending; see the project state before merging or releasing.

Source-of-truth documents:

- [`docs/PROJECT_STATE.md`](docs/PROJECT_STATE.md) — exact current state and next step
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — milestones and exit criteria
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — architectural boundaries
- [`docs/TESTING.md`](docs/TESTING.md) — automated gates and manual acceptance IDs
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) — TDD, commits, versioning, documentation policy
- [`CHANGELOG.md`](CHANGELOG.md) — notable changes

## Requirements

- macOS 14+
- Xcode / Swift 6 toolchain for development

End users install a normal macOS `.dmg`; development tools are not required after installation.

## Development

```bash
swift build
swift test --parallel
```

Behavior changes and bug fixes follow RED → GREEN → REFACTOR. See `docs/DEVELOPMENT.md` before changing production behavior.

Build an ad-hoc signed application bundle:

```bash
./scripts/build-app.sh
open build/NotchHub.app
```

Build a DMG installer:

```bash
./scripts/build-dmg.sh
```

The resulting file is `build/NotchHub.dmg`. `VERSION` is stamped into the application bundle at packaging time.

## Architecture

The app is written in Swift 6 using SwiftUI for UI and AppKit for panel/window integration. Hardware-notch measurements and pointer-region decisions are isolated in deterministic policies so they can be unit-tested instead of being buried in view callbacks.

The media layer will be provider-based. Yandex Music is the primary compatibility target; any use of private macOS MediaRemote APIs will remain isolated behind an adapter and will not leak into the rest of the application.

## Distribution

CI produces an ad-hoc signed DMG suitable for personal testing. Developer ID signing and notarization are deferred until broader distribution or warning-free installation on other Macs is needed.

Release tags use `v<SemVer>`, for example `v0.1.0`, and must match the repository-root `VERSION` file.

## Privacy

The baseline app is local-only and makes no network requests. Future modules must document any additional permissions or network use explicitly.
