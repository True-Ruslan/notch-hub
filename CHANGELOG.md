# Changelog

All notable changes to NotchHub are documented here.

The project follows [Semantic Versioning](https://semver.org/). The version under active development is stored in [`VERSION`](VERSION). Until the first tagged release, changes remain under `Unreleased`.

## [Unreleased]

### Added

- Swift 6 / Swift Package Manager native macOS application foundation.
- AppKit `NSPanel` shell with hardware-notch geometry derived from public `NSScreen` APIs.
- Compact and expanded presentation states.
- Deterministic geometry, panel-state, and pointer-retention tests.
- CI that builds, tests, packages, verifies, and uploads an ad-hoc signed DMG.
- Tag-driven GitHub Release workflow.
- Project architecture, roadmap, state, development, and testing documentation.
- `VERSION` as the single source for the application semantic version during packaging.

### Fixed

- Prevented the hover resize feedback loop observed during the first real-hardware acceptance test. Pointer state is now resolved against stable compact/expanded screen-space regions instead of trusting SwiftUI `onHover` events generated while the panel itself is resizing.

### Testing

- Added a regression test that first failed on the bootstrap implementation and proves an expanded panel remains expanded while the pointer is still inside its expanded retention region.

[Unreleased]: https://github.com/True-Ruslan/notch-hub/compare/v0.1.0...HEAD
