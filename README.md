# NotchHub

Native, local-first macOS productivity hub built around the MacBook notch.

NotchHub turns the area around the camera housing into a compact panel for everyday tools. Planned modules are file Shelf, Snippets, Calendar, Translator, and media controls with **Yandex Music** as the primary player.

## Status

Current development version: **0.1.0 (unreleased)**.

**M0 engineering foundation is accepted on real hardware (target MacBook, macOS 26.6).** The native panel shell, exact hardware-notch geometry, stable screen-space pointer policy, App Sandbox/Hardened Runtime baseline, automated tests, CI, and installable DMG packaging are in place. Trusted `v0.1.0` publication is intentionally pending Apple Developer signing/notarization credentials.

Source-of-truth documents:

- [`docs/PROJECT_STATE.md`](docs/PROJECT_STATE.md) — exact current state and next step
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — milestones and exit criteria
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — architectural boundaries
- [`docs/TESTING.md`](docs/TESTING.md) — automated gates and manual acceptance IDs/history
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) — TDD, commits, versioning, documentation policy
- [`SECURITY.md`](SECURITY.md) — threat model, security invariants, and security-review contract
- [`docs/RELEASING.md`](docs/RELEASING.md) — Developer ID/notarized GitHub Release setup
- [`docs/PRODUCT_REFERENCES.md`](docs/PRODUCT_REFERENCES.md) — independent public product/UI research
- [`CHANGELOG.md`](CHANGELOG.md) — notable changes

## Requirements

- macOS 14+ deployment target
- primary current real-hardware target: macOS 26.6
- Xcode / Swift 6 toolchain for development

End users install a normal macOS `.dmg`; development tools are not required after installation.

## Development

```bash
swift build
swift test --parallel
./scripts/security-audit.sh
```

Behavior changes and bug fixes follow RED → GREEN → REFACTOR. See `docs/DEVELOPMENT.md` before changing production behavior.

Build an ad-hoc signed application bundle:

```bash
./scripts/build-app.sh
open build/NotchHub.app
```

Build a DMG test installer:

```bash
./scripts/build-dmg.sh
```

The result is `build/NotchHub.dmg`. Test builds are ad-hoc signed but still enable App Sandbox and Hardened Runtime so the security-sensitive packaging path is exercised continuously.

## Security model

The M0 runtime intentionally has:

- App Sandbox enabled;
- Hardened Runtime enabled without dangerous exceptions;
- zero third-party Swift runtime dependencies;
- no telemetry/analytics/licensing backend;
- no direct network/WebKit surface;
- no runtime subprocess/shell execution;
- no dynamic code/plugin loading;
- no global keyboard monitoring.

CI enforces this baseline. Future capabilities that require broader permissions or attack surface must change `SECURITY.md` and the executable security gate explicitly in the same reviewed PR.

## Architecture

The app is written in Swift 6 using SwiftUI for UI and AppKit for panel/window integration. Hardware-notch measurements, pointer-region decisions, and AppKit/SwiftUI sizing ownership are isolated so deterministic behavior can be regression-tested instead of being buried in view callbacks.

The media layer will be provider-based. Yandex Music is the primary compatibility target. A private MediaRemote fallback is allowed only after a focused security/compatibility review and may not weaken Hardened Runtime/library validation.

## Distribution

PR CI produces a sandboxed/Hardened Runtime ad-hoc DMG for testing. **Stable builds are published through GitHub Releases**, not chat attachments.

The prepared Release workflow is fail-closed and requires Developer ID signing plus Apple notarization/stapling before it will publish `NotchHub.dmg` and its SHA-256 checksum. One-time Apple credentials must be configured directly in the GitHub `release` environment; see `docs/RELEASING.md` and never send signing keys/certificates through chat.

Release tags use `v<SemVer>`, for example `v0.1.0`, and must match the repository-root `VERSION` file.

## Privacy

The baseline app is local-only and makes no direct network requests. Future modules must document any additional permission, external process, private API, or network use explicitly before implementation.
