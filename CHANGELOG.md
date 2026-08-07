# Changelog

All notable changes to NotchHub are documented here.

The project follows [Semantic Versioning](https://semver.org/). The version under active development is stored in [`VERSION`](VERSION). Until the first tagged release, changes remain under `Unreleased`.

## [Unreleased]

### Added

- Swift 6 / Swift Package Manager native macOS application foundation.
- AppKit `NSPanel` shell with hardware-notch geometry derived from public `NSScreen` APIs.
- Compact and expanded presentation states.
- Deterministic geometry, panel-state, and pointer-retention tests.
- TDD/commit/documentation policy and stable real-hardware acceptance scenario IDs.
- Strict Swift formatting, warnings-as-errors, coverage-instrumented tests, and dedicated macOS 26 CI compatibility validation.
- App Sandbox with a deliberately minimal entitlement set.
- Hardened Runtime signing for test and stable builds.
- Root `SECURITY.md` threat/security policy and executable `scripts/security-audit.sh` CI baseline.
- Security gates that keep M0 free of third-party Swift dependencies, runtime shell/subprocess execution, direct network/WebKit APIs, dynamic code loading, global keyboard monitoring, dangerous Hardened Runtime exceptions, persistence helpers, mutable GitHub Action references, and `pull_request_target`.
- GitHub Actions pinned to immutable full commit SHAs.
- Semantic `VERSION` stamping and CI build numbers.
- GitHub Release workflow for Developer ID signing, Apple notarization, stapling, Gatekeeper assessment, and SHA-256 checksum publication.
- Release/setup documentation and independent NotchNook product-reference notes.

### Fixed

- Prevented the hover resize feedback loop observed during the first real-hardware acceptance test. Pointer state is now resolved against stable compact/expanded screen-space regions instead of trusting SwiftUI `onHover` events generated while the panel itself is resizing.

### Testing

- Added a regression test that first failed on the bootstrap implementation and proves an expanded panel remains expanded while the pointer is still inside its expanded retention region.
- Verified the RED test failed for the expected behavior mismatch before the hover production fix was added.
- Added exact macOS 26.6 real-hardware acceptance IDs while keeping GitHub-hosted macOS 26 testing as an automated major-version compatibility layer.

### Security

- Stable releases are now fail-closed: they cannot publish unless Developer ID signing, Hardened Runtime, App Sandbox entitlements, Apple notarization/stapling, and Gatekeeper assessment all succeed.
- PR DMGs remain explicitly ad-hoc test artifacts and are not represented as trusted stable releases.

[Unreleased]: https://github.com/True-Ruslan/notch-hub/compare/v0.1.0...HEAD
