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
- MIT `LICENSE` for public source distribution.
- `docs/PUBLIC_READINESS.md` recording the repository-history audit, public-fork CI boundary, and mandatory post-visibility checks.
- Deterministic public pull-request CI validation that rejects write authority, repository secrets, self-hosted runners, privileged triggers, OIDC/write permissions, and persisted checkout credentials.
- M1 `NotchInteractionCoordinator` with deterministic injected-scheduler coverage for quick transit cancellation, threshold activation, stale-callback rejection, re-entry, duplicate movement, expanded retention, repeated independent activations, programmatic/setup-state exclusion, and lifecycle invalidation.
- One-shot cancellable main-queue dwell scheduling with a named initial `120 ms` candidate and no polling/repeating timer.
- Public AppKit expansion haptic through `NSHapticFeedbackManager.defaultPerformer`, isolated behind a deterministic test seam.
- Explicit pointer-monitor ownership/lifecycle tests proving exactly one local and one global `.mouseMoved` registration and idempotent teardown.
- Stable M1 hardware acceptance IDs `NH-VISUAL-001/002/003` for visible rounded compact chrome, expanded-control visibility, and rounded panel chrome across repeated open/collapse cycles.

### Changed

- Downloaded immutable Personal Release `v0.1.0` completed `NH-PERSONAL-RELEASE-001` on the target MacBook/macOS 26.6; R0.1 is accepted.
- Performance Foundation P0 was accepted and squash-merged to `main` as `a056aa74bad5d8e193eb4c76a76e6c910344bd09` after exact-head CI and final review.
- Accepted target-Mac runtime baselines for idle, hover, and 10-minute stability against immutable `v0.1.0`; idle/stability median CPU is `0.0%`, stability RSS decreased by `3,712 KiB`, and no sustained memory/thread growth was detected.
- Accepted exact `v0.1.0` artifact sizes: executable `220,560 B`, app `223,555 B`, DMG `73,955 B`.
- Defined conservative initial CPU/RSS/thread target-Mac acceptance ceilings from the measured baseline while keeping noisy shared-runner resource values out of CI thresholds.
- Added deterministic shared-CI size limits: 15% relative regression allowance from the accepted baseline plus independent absolute ceilings derived at 120% and rounded upward to 4 KiB boundaries.
- Documented approved M1 delayed-hover activation and public AppKit haptic requirements, including event-driven/no-polling constraints and stable hardware acceptance IDs.
- Prepared repository policy/documentation for public source visibility while keeping runtime `Sources/` and application entitlements unchanged.
- M1 compact-to-expanded pointer activation now routes through one cancellable dwell instead of expanding immediately; collapse/retention remains governed by the accepted deterministic screen-space pointer policy.
- Pointer event monitors now have explicit lifecycle ownership and removal on controller invalidation. The narrow global `.mouseMoved` fallback is intentionally retained until a target-Mac `NSTrackingArea`/window-local experiment proves equal-or-better correctness and resource behavior.
- Initial panel `show()` pointer synchronization is explicitly non-activating, preventing an unintended dwell/haptic merely because the pointer already overlaps the notch when NotchHub launches.
- Compact activation now uses a **4 pt inward inset** candidate instead of extending beyond the physical notch edge, requiring slightly more deliberate pointer depth while leaving expanded retention unchanged.
- The single public AppKit expansion haptic candidate changed from `.generic` to `.levelChange` after target-Mac feedback requested a slightly more noticeable tactile response; exactly one feedback request remains the invariant.
- Panel-frame presentation changes are synchronized immediately with presentation state in the revised interaction candidate; polished frame animation and Reduced Motion behavior remain a later dedicated M1 hardening step.
- Outer panel clipping now has one owner at the AppKit hosting-view boundary rather than competing SwiftUI/AppKit owners; the layer mask uses continuous `12 pt` compact / `22 pt` expanded radii and is reasserted on every presentation transition while the hosting view follows panel width and height.
- Hardware-notch compact rendering is again **opaque black**. Transparency is no longer used as a contour workaround; visible compact chrome and rounded clipping are separate invariants.
- PR #10 CI initially caught an executable-size regression of `254,000 B` against the unchanged 15% P0 budget; implementation metadata was reduced rather than widening the budget. CI #158 then passed at executable `251,856 B`, app `254,853 B`, and DMG `83,072 B`.
- Independent review caught the setup-time activation path; RED CI #165 reproduced it and GREEN CI #167 passed **25/25 Swift tests** plus all security/performance/package gates with executable `251,872 B`, app `254,869 B`, and DMG `83,036 B`.

### Fixed

- Restored the intended visible black compact panel on hardware-notch displays after a transparency workaround left only the white compact indicator floating over wallpaper. The black surface is now clipped by the AppKit-owned rounded mask instead of being removed.
- Expanded primary controls now receive an explicit hardware-notch safe top inset and no longer depend on an independently animated AppKit frame, addressing the hardware symptom where a large black panel appeared while controls were hidden under the notch until pointer exit/collapse.
- Repeated compact/expanded resizing no longer relies on SwiftUI `clipShape` to preserve the actual outer panel chrome. AppKit now masks the backing hosting view on every transition, addressing the hardware regression where initially rounded expanded corners became square after several openings.

### Testing

- Target-Mac M1 hardware feedback exposed visual regressions despite the original delayed-hover/haptic checks otherwise passing; the candidate was therefore not accepted.
- RED CI #172 established the hardware-notch visual contract before implementation.
- CI #177, #181, and #187 rejected successive visual implementations that exceeded the existing P0 size budget; the budget was never widened and the implementation was simplified instead.
- CI #188 passed the complete pipeline with the revised visual architecture at executable `251,856 B`, app `254,853 B`, and DMG `83,143 B`.
- RED CI #189 reproduced edge-grazing activation at only 2 pt inside the compact physical boundary.
- GREEN CI #191 on `ab782262c16163742bb115671f7908255fc08e4a` passed **27/27 Swift tests** and all release/security/performance/package gates with executable `251,856 B`, app `254,853 B`, and DMG `83,117 B`.
- A second target-Mac visual cycle showed that expanded corners could start rounded and become square after repeated open/collapse transitions; this is retained as `NH-VISUAL-003`.
- RED commit `8088df8df655183d3fbe1a0cff54d23dfc936034` / CI #196 failed exactly because the new AppKit presentation-mask boundary did not yet exist.
- GREEN source head `446a976591a43a856a2683337cb4df1ada10cc8a` / CI #199 passed **29/29 Swift tests**, including hosting-view width/height tracking and **32 repeated expanded -> compact layer-mask cycles**, plus all release/security/performance/package gates and the unchanged size budget.
- A subsequent target-Mac retest reported that only the white compact point remained. Root-cause tracing found `compactBackgroundOpacity == 0` specifically for hardware-notch layouts.
- RED commit `1bb2d1481f31557868651bab6b59745e44ed827b` / CI #204 required an opaque hardware-notch compact surface and failed exactly with actual opacity `0.0` versus expected `1.0`.
- GREEN source head `29627f5f145d5e60ef1873d988cf4c51b91f097f` / CI #205 restored compact opacity `1` and passed **29/29 Swift tests**, macOS 26 compatibility, all release/security/performance/package gates, and the unchanged size budget. Candidate sizes: executable `248,768 B`, app `251,765 B`, DMG `82,075 B`.
- Revised target-Mac acceptance remains pending for `NH-NOTCH-001`, `NH-HOVER-001/002/003`, `NH-HOVER-DELAY-001/002`, `NH-HAPTIC-001/002`, and `NH-VISUAL-001/002/003`; deterministic backing-layer checks do not substitute for physical pixel validation.

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
