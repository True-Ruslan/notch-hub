# Changelog

All notable changes to NotchHub are documented here.

The project follows [Semantic Versioning](https://semver.org/). The active version is stored in repository-root [`VERSION`](VERSION).

## [Unreleased]

### Added

- Root `PERFORMANCE.md` defining event-driven runtime/resource invariants, target-Mac measurement methodology, stable performance acceptance IDs, accepted runtime baseline values, and evidence-based target-Mac budget rules.
- Canonical machine-readable `performance/baseline-v0.1.0.json` containing immutable-release provenance, macOS 26.6 runtime measurements, exact release artifact sizes, target-Mac resource ceilings, and deterministic size budgets.
- Standard-library `scripts/performance_policy.py` plus unit tests for unreviewed polling/timer/sleep/display-link detection, strict process-metric parsing/aggregation, configuration validation, stability evidence, Darwin thread-row parsing, deterministic runtime budget comparison, and fail-closed release-size budget enforcement.
- Development-only `scripts/perf-baseline.py` for CPU/RSS/thread sampling with explicit measured-app/tooling provenance and no user-content/pointer/clipboard telemetry.
- Deterministic `NH-PERF-STATE-001` Swift coverage exercising exactly 100,000 pointer/presentation policy decisions without wall-clock thresholds.
- CI performance-policy enforcement, release-candidate size metadata, canonical size-regression gate, harness compatibility/schema smoke, and explicit proof that measurement tooling is not bundled into `NotchHub.app`.

### Changed

- Downloaded immutable Personal Release `v0.1.0` completed `NH-PERSONAL-RELEASE-001` on the target MacBook/macOS 26.6; R0.1 is accepted.
- Performance Foundation P0 has complete accepted evidence and is at its final PR #5 review/merge gate before becoming merged project state.
- Accepted target-Mac runtime baselines for idle, hover, and 10-minute stability against immutable `v0.1.0`; idle/stability median CPU is `0.0%`, stability RSS decreased by `3,712 KiB`, and no sustained memory/thread growth was detected.
- Accepted exact `v0.1.0` artifact sizes: executable `220,560 B`, app `223,555 B`, DMG `73,955 B`.
- Defined conservative initial CPU/RSS/thread target-Mac acceptance ceilings from the measured baseline while keeping noisy shared-runner resource values out of CI thresholds.
- Added deterministic shared-CI size limits: 15% relative regression allowance from the accepted baseline plus independent absolute ceilings derived at 120% and rounded upward to 4 KiB boundaries.
- Documented approved M1 delayed-hover activation and public AppKit haptic requirements, including event-driven/no-polling constraints and stable hardware acceptance IDs.

## [0.1.0] - 2026-08-07

### Added

- Swift 6 / Swift Package Manager native macOS application foundation.
- AppKit `NSPanel` shell with hardware-notch geometry derived from public `NSScreen` APIs.
- Compact and expanded presentation states.
- Deterministic geometry, panel-state, pointer-retention, exact-notch-width, and hosting-view-sizing tests.
- TDD/commit/documentation policy and stable real-hardware acceptance IDs.
- Strict Swift formatting, warnings-as-errors, coverage-instrumented tests, and dedicated macOS 26 compatibility validation.
- App Sandbox with a deliberately minimal entitlement set.
- Hardened Runtime signing for test and Personal Release builds.
- Root `SECURITY.md` threat/security policy and executable `scripts/security-audit.sh` CI baseline.
- Security gates keeping the baseline free of third-party Swift runtime dependencies, runtime shell/subprocess execution, direct network/WebKit APIs, dynamic code loading, broad global input monitoring, dangerous Hardened Runtime exceptions, persistence helpers, mutable GitHub Action references, and `pull_request_target`.
- GitHub Actions pinned to immutable full-SHA references.
- Semantic `VERSION` stamping and CI build numbers.
- Versioned Personal Release notes under `docs/releases/` with explicit ad-hoc/not-notarized trust labeling.
- Standard-library `scripts/release_policy.py` and unit tests for strict SemVer/tag rules, release-note trust warnings, unsafe Gatekeeper-bypass text, release-workflow boundaries, and provenance metadata.
- Manual immutable **Personal Release** workflow that repeats complete quality/security/package gates, verifies ad-hoc signature + Hardened Runtime + exact Sandbox entitlements, and publishes DMG + SHA-256 + build provenance without paid Apple credentials.
- Separate optional **Trusted Release** workflow retaining Developer ID, Apple notarization/stapling, and Gatekeeper verification for future new versions.
- Release workflows refuse to overwrite existing tags/releases; legacy ambiguous `release.yml` and `--clobber` behavior were removed.
- Approved Personal Release and Performance Foundation design/implementation plans under `docs/superpowers/`.
- Release/setup documentation and independent NotchNook product-reference notes.

### Fixed

- Prevented hover resize feedback that caused compact/expanded oscillation on real hardware. Pointer state is resolved through deterministic screen-space policy instead of raw SwiftUI `onHover` resize feedback.
- Real hardware notch widths are no longer inflated to the 180 pt fallback minimum; fallback is used only when no hardware notch is detected.
- Disabled `NSHostingView` window-sizing ownership so compact content cannot leave the actual `NSPanel` frame expanded.
- Corrected Personal Release note validation so the safe warning `Do not disable Gatekeeper` is allowed while actual Gatekeeper/quarantine bypass instructions remain prohibited.

### Testing

- RED-first regression proved an expanded panel remains expanded while the pointer stays within expanded retention bounds.
- Added macOS 26.6 real-hardware acceptance IDs while retaining GitHub-hosted macOS 26 as an automated compatibility layer.
- RED `c518326` reproduced both second-cycle real-hardware defects: compact width `180` vs expected `176`, and hosting sizing options `7` vs empty.
- GREEN `3bb1bbb` fixed both and raised the Swift suite to **10/10 PASS**.
- Final corrected-build hardware retest on macOS 26.6: `NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, and `NH-HOVER-003` all **PASS**.
- **M0 engineering foundation accepted and merged.**
- Personal Release infrastructure developed with explicit RED→GREEN evidence for missing policy helper, versioned notes, workflow contract, Trusted/Personal tier separation, and executable trust-boundary validation.
- Immutable Personal Release `v0.1.0` was published from accepted protected `main` and later passed downloaded-release acceptance `NH-PERSONAL-RELEASE-001` on the target MacBook/macOS 26.6.

### Security

- App Sandbox and Hardened Runtime remain mandatory for Personal Release despite lack of Apple Developer identity/notarization.
- Personal Release is explicitly identified as ad-hoc/not notarized and never claims Apple trust.
- Safe first-launch documentation uses only standard Finder / System Settings → Privacy & Security → Open Anyway flow; Gatekeeper disabling/quarantine-stripping instructions are prohibited by policy tests.
- Personal Release contains no Apple Developer/notary secrets and cannot use the future Trusted Release environment.
- Release assets/tags are immutable; existing versions are never replaced with `--clobber` or upload-overwrite flows.
- Future Trusted Release remains fail-closed behind Developer ID/notarization and cannot overwrite an already published Personal version.

[Unreleased]: https://github.com/True-Ruslan/notch-hub/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/True-Ruslan/notch-hub/releases/tag/v0.1.0
