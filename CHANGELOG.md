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
- `docs/PUBLIC_READINESS.md` recording repository-history audit, public-fork CI boundary, and mandatory post-visibility checks.
- Deterministic public pull-request CI validation rejecting write authority, repository secrets, self-hosted runners, privileged triggers, OIDC/write permissions, and persisted checkout credentials.
- M1 `NotchInteractionCoordinator` with deterministic injected-scheduler coverage for quick transit cancellation, threshold activation, stale-callback rejection, re-entry, duplicate movement, expanded retention, setup-state exclusion, and lifecycle invalidation.
- One-shot cancellable main-queue dwell scheduling with accepted `120 ms` dwell and no polling/repeating timer.
- Public AppKit expansion haptic through `NSHapticFeedbackManager.defaultPerformer`; the accepted target-Mac tactile behavior is one `.levelChange` request per eligible deliberate expansion.
- Explicit pointer-monitor ownership/lifecycle tests proving exactly one local and one global `.mouseMoved` registration and idempotent teardown.
- Stable M1 hardware acceptance IDs `NH-VISUAL-001/002/003` for visible rounded compact chrome, expanded-control visibility, and rounded panel chrome across repeated open/collapse cycles.
- `NotchPanelTransitionCoordinator` as the single compact/expanded transition authority with explicit `compact`, `expanding`, `expanded`, and `collapsing` lifecycle phases.
- Deterministic transition coverage for content staging, duplicate requests, programmatic no-haptic expansion, invalidation, expansion/collapse reversals, stale animation completions, Reduce Motion retargeting, and exactly-once haptic authority.
- A 10,000-reversal transition stress test proving only the latest generation can settle state without retained transition history.
- Public AppKit/Core Animation transition output: `NSAnimationContext` for panel frame and `CABasicAnimation` for corner radius, sharing an accepted `0.20 s` / ease-in-out policy.
- Reduce Motion policy using public `NSWorkspace.accessibilityDisplayShouldReduceMotion` and `accessibilityDisplayOptionsDidChangeNotification`, with zero-duration exact endpoints and in-flight retargeting.
- M1 transition/animation hardening implementation plan under `docs/superpowers/plans/2026-08-08-m1-transition-animation-hardening.md`.
- Stable `NH-HOVER-TOP-001` hardware gate for deliberate built-in-display activation while the pointer is held against the exact top screen edge over the notch.
- Exact compact activation boundary tests for `maxY` and the accepted 4 pt left/right boundaries, preventing nearby interior points from being mistaken for hardware-edge coverage.

### Changed

- Downloaded immutable Personal Release `v0.1.0` completed `NH-PERSONAL-RELEASE-001` on the target MacBook/macOS 26.6; R0.1 is accepted.
- Performance Foundation P0 was accepted and squash-merged to `main` as `a056aa74bad5d8e193eb4c76a76e6c910344bd09` after exact-head CI and final review.
- Accepted target-Mac runtime baselines for idle, hover, and 10-minute stability against immutable `v0.1.0`; idle/stability median CPU is `0.0%`, stability RSS decreased by `3,712 KiB`, and no sustained memory/thread growth was detected.
- Accepted exact `v0.1.0` artifact sizes: executable `220,560 B`, app `223,555 B`, DMG `73,955 B`.
- Defined conservative initial CPU/RSS/thread target-Mac acceptance ceilings from the measured baseline while keeping noisy shared-runner resource values out of CI thresholds.
- Added deterministic shared-CI size limits: 15% relative regression allowance from the accepted baseline plus independent absolute ceilings derived at 120% and rounded upward to 4 KiB boundaries.
- Prepared repository policy/documentation for public source visibility while keeping runtime entitlements unchanged.
- M1 compact-to-expanded pointer activation routes through one cancellable dwell instead of expanding immediately; collapse/retention remains governed by deterministic screen-space pointer policy.
- Initial panel `show()` pointer synchronization is explicitly non-activating, preventing unintended dwell/haptic merely because the pointer already overlaps the notch when NotchHub launches.
- Compact activation geometry is asymmetric: **4 pt inward on left/right/bottom, 0 pt on top**. Accepted compact boundaries are explicit and inclusive, including `pointer.y == compactFrame.maxY`; compact activation no longer inherits `CGRect.contains` maximum-edge exclusion.
- Cross-display quick transit remains protected by the accepted 120 ms cancellable dwell rather than by a top dead band.
- The haptic changed from `.generic` to the now physically accepted `.levelChange`; exactly one feedback request remains the invariant.
- Hardware-notch compact rendering is **opaque black**. Transparency is no longer used as a contour workaround; visible compact chrome and rounded clipping are separate invariants.
- Outer panel clipping has one owner at the AppKit hosting-view boundary; the layer uses continuous `12 pt` compact / `22 pt` expanded radii and the hosting view follows panel width and height.
- Pointer intents no longer own presentation state/haptic output. `NotchInteractionCoordinator` emits intent to `NotchPanelTransitionCoordinator`, which is now the sole presentation-transition authority.
- SwiftUI content presentation is intentionally staged separately from the desired window endpoint: expanded controls remain rendered during collapse until the matching animation completion.
- Panel frame transitions are system-animated through `NSAnimationContext`; corner radius follows a matching Core Animation transition. No custom frame timer/display link/interpolation loop was added.
- Transition cancellation freezes the current presentation-layer corner radius into the model layer before removing the old animation, so reversal starts from the current visible radius rather than an obsolete target.
- Reduce Motion maps the animation duration to zero and can retarget an in-flight transition to the same desired endpoint without a second haptic.
- Accessibility display-option observation is owned by the existing `NotchPanelController` through selector-based `NotificationCenter` registration, eliminating a separate block-observer token/closure lifecycle.
- Live AppKit `.mouseMoved` callbacks no longer allocate `Task { @MainActor ... }` for every event. They deliver synchronously through `MainActor.assumeIsolated` on the documented main-thread event-monitor boundary while retaining the same one-local/one-global `.mouseMoved` scope.
- The narrow global `.mouseMoved` fallback remains intentionally retained until a measured `NSTrackingArea` / window-local experiment proves equal-or-better target-Mac correctness and resource behavior.

### Fixed

- Restored the intended visible black compact panel on hardware-notch displays after a transparency workaround left only the white compact indicator floating over wallpaper.
- Expanded primary controls receive an explicit hardware-notch safe top inset and no longer depend on presentation state disappearing before the backing window reaches its endpoint.
- Repeated compact/expanded resizing no longer relies on SwiftUI `clipShape` for the actual outer panel chrome; AppKit owns the backing-view mask.
- Stale expansion/collapse completion can no longer overwrite a newer reversed transition because only the current generation may settle state.
- Collapse no longer switches SwiftUI content to compact before the matching visual transition completes.
- Animation reversal no longer discards the current visible corner radius before beginning the opposite transition.
- Reduce Motion changes during an active transition no longer require waiting for the obsolete animation path and do not duplicate haptic feedback.
- Removed avoidable per-mouse-event Swift concurrency task allocation from the pointer-monitor hot path.
- Removed the top 4 pt compact activation dead band while retaining the accepted side/bottom accidental-grazing protection.
- Fixed exact top-edge activation after hardware showed that `CGRect.contains` rejected `compactFrame.maxY`; compact hit-testing now uses explicit inclusive directional boundaries instead of half-open maximum-edge semantics.

### Testing

- Target-Mac M1 hardware feedback exposed visual regressions despite the original delayed-hover/haptic checks otherwise passing; the earlier candidate was therefore not accepted.
- RED CI #172 established the hardware-notch visual contract before implementation.
- CI #177, #181, and #187 rejected successive visual implementations that exceeded the existing P0 size budget; the budget was never widened and the implementation was simplified instead.
- CI #188 passed the complete pipeline with the revised visual architecture at executable `251,856 B`, app `254,853 B`, and DMG `83,143 B`.
- RED CI #189 reproduced edge-grazing activation; GREEN CI #191 passed the revised 4 pt activation policy.
- RED CI #196 established the repeated panel-chrome contract; GREEN CI #199 passed 29/29 tests including 32 repeated AppKit mask/radius cycles.
- RED CI #204 required an opaque hardware-notch compact surface; GREEN CI #205 restored opacity and passed the unchanged size budget at executable `248,768 B`, app `251,765 B`, DMG `82,075 B`.
- RED CI #225 established the intent-only interaction contract before coordinator separation.
- RED CI #231 established the transition lifecycle/driver contract before production implementation.
- RED CI #273 established Reduce Motion policy behavior before implementation.
- RED CI #279 established the public AppKit animation boundary before production implementation.
- RED CI #283 rejected competing presentation ownership in `NotchPanelController` before live composition migrated to one transition authority.
- RED CI #292 established that cancellation must freeze the current visible corner radius before removing Core Animation output.
- CI #295 passed functional/security/package checks but failed the unchanged P0 artifact budget; no hardware candidate was issued and the budget was not widened.
- RED CI #305 established selector-based accessibility-observer ownership before the block observer/token implementation was replaced.
- CI #308 passed all deterministic behavior/security/package checks and brought executable/app under budget, while DMG still failed the unchanged size allowance.
- RED CI #309 added the no-per-event-Task pointer hot-path invariant and failed only that new contract while all prior 48 Swift tests remained green.
- GREEN CI #310 on source `12c5ff26dc409dd0391f3b296866c2be9515ce7e` passed **49/49 Swift tests**, macOS 26 compatibility, release/public policy, runtime performance audit, security baseline, warnings-as-errors, Sandbox/Hardened Runtime/signature/DMG verification, performance-harness smoke, artifact uploads, and the unchanged P0 size budget.
- Clean exact-head CI #319 on `f6de06f5d045fc9375b3b31b0a7feb97a13cebe4` produced the target-Mac candidate. Physical acceptance passed `NH-NOTCH-001`, `NH-HOVER-001/002/003`, `NH-HOVER-DELAY-001/002`, `NH-HAPTIC-001/002`, `NH-VISUAL-001/002/003`, `NH-ANIM-001/002/003/004`, `NH-MOTION-001/002`, startup non-activation, and accepted 120 ms / `.levelChange` / 0.20 s tuning.
- That accepted cycle requested one geometry refinement: no top activation inset while keeping 4 pt left/right/bottom.
- RED `f4d19fc7e508fe11a35aae6fb56f80e0fa7ec13e` / CI #320 established the initial asymmetric geometry; GREEN `c7c10033d223197309eafeba63e67b30ae29ba33` / CI #321 passed **52/52 Swift tests** and all automated gates.
- Clean exact-head `969a7c52203adf7e3dd8bb5f198a6895b2fb7f7a` / CI #325 passed all automated gates, but target-Mac `NH-HOVER-TOP-001` **FAILED**: holding the cursor at the exact top screen edge did not open the panel.
- The #325 failure exposed that the prior test used `compactFrame.maxY - 1`, not the exact edge, while production delegated to `CGRect.contains`, which excludes maximum X/Y edges. The automated evidence was therefore insufficient for the physical scenario it claimed to cover.
- Corrective RED `3d0d40b5426cb8a8fe0bd19393688a68247637b0` / CI #326 used exact `y == compactFrame.maxY` and exact 4 pt left/right boundaries; **54 tests ran and only the three new exact-boundary expectations failed**.
- Corrective GREEN `9022ab55221070b4899853fffd3dc6709384ab1b` / CI #327 replaced compact `CGRect.contains` with explicit inclusive directional comparisons and passed **54/54 Swift tests**, macOS 26 compatibility, all release/security/performance/package/signature/Sandbox/Hardened Runtime/DMG gates, and the unchanged P0 size budget.
- CI #327 sizes: executable `250,320 B`, app `253,317 B`, DMG `84,679 B`.
- Only targeted physical checks `NH-HOVER-TOP-001` and `NH-HOVER-DELAY-001` remain after the corrective exact-head documentation build; the already accepted broad visual/animation/motion matrix need not be repeated unless a regression appears.

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
- Corrected Personal Release note validation so the safe warning `Do not disable Gatekeeper` is allowed while actual Gatekeeper/quarantine-stripping instructions remain prohibited.

### Testing

- RED-first regression proved an expanded panel remains expanded while the pointer stays within expanded retention bounds.
- Added macOS 26.6 real-hardware acceptance IDs while retaining GitHub-hosted macOS 26 as an automated compatibility layer.
- RED `c518326` reproduced both second-cycle real-hardware defects: compact width `180` vs expected `176`, and hosting sizing options `7` vs empty.
- GREEN `3bb1bbb` fixed both and raised the Swift suite to **10/10 PASS**.
- Final corrected-build hardware retest on macOS 26.6: `NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, and `NH-HOVER-003` all **PASS**.
- **M0 engineering foundation accepted and merged.**
- Personal Release infrastructure developed with explicit RED->GREEN evidence for missing policy helper, versioned notes, workflow contract, Trusted/Personal tier separation, and executable trust-boundary validation.
- Immutable Personal Release `v0.1.0` was published from accepted protected `main` and later passed downloaded-release acceptance `NH-PERSONAL-RELEASE-001` on the target MacBook/macOS 26.6.

### Security

- App Sandbox and Hardened Runtime remain mandatory for Personal Release despite lack of Apple Developer identity/notarization.
- Personal Release is explicitly identified as ad-hoc/not notarized and never claims Apple trust.
- Safe first-launch documentation uses only standard Finder / System Settings -> Privacy & Security -> Open Anyway flow; Gatekeeper disabling/quarantine-stripping instructions are prohibited by policy tests.
- Personal Release contains no Apple Developer/notary secrets and cannot use the future Trusted Release environment.
- Release assets/tags are immutable; existing versions are never replaced with `--clobber` or upload-overwrite flows.
- Future Trusted Release remains fail-closed behind Developer ID/notarization and cannot overwrite an already published Personal version.

[Unreleased]: https://github.com/True-Ruslan/notch-hub/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/True-Ruslan/notch-hub/releases/tag/v0.1.0
