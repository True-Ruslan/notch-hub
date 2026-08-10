# Changelog

All notable changes to NotchHub are documented here.

The project follows [Semantic Versioning](https://semver.org/). The active version is stored in repository-root [`VERSION`](VERSION).

## [Unreleased]

### Added

- M6.4 shipping composition linking the accepted `NotchHubMediaCore` into `NotchHubApp`, with application-owned `ShippingMediaRuntime` start/stop and exact pinned adapter/framework/license/provenance resources inside the real shipping bundle.
- Development-only `NotchHubMediaCandidateCore` target separating production-transport candidate helpers from the shipping media graph; this reduced the composed shipping executable from `354,880 B` to `312,816 B` without changing the accepted transport semantics.
- Explicit M6.4 additive feature-size policy over the unchanged immutable P0 baseline, with strict schema/provenance validation and exact real `perf-size.json` envelope handling.
- Privacy-safe `scripts/shipping_media_acceptance.py` for shipping preflight, parent+owned-adapter 60-second/10-minute resource sampling, and bounded normal-termination/no-orphan evidence.
- Exact-candidate `scripts/run-shipping-media-target-acceptance.sh` pinning the frozen M6.4 DMG SHA-256, mounting it read-only, running preflight/resources, requesting normal termination through public `NSRunningApplication.terminate()`, and producing only privacy-safe acceptance JSON.
- `docs/testing/SHIPPING_MEDIA_COMPOSITION_ACCEPTANCE.md` and `docs/testing/SHIPPING_MEDIA_COMPOSITION_TARGET_MAC.md` defining stable `NH-MEDIA-SHIP-001...010` gates and the physical target procedure.
- M6.3 concrete production `MediaRemoteSystemTransport` with strict bounded `stream --no-diff --micros` decoding, full-snapshot replacement, authoritative tri-state capabilities, monotonic source/session ordering, stale-capability rejection, and typed toggle/previous/next/seek forwarding.
- One narrowly reviewed production Foundation `Process()` boundary fixed to `/usr/bin/perl`, with pinned MediaRemote adapter provenance, closed arguments, bounded I/O, bounded graceful/forced teardown, and executable security-audit enforcement preventing `Process()` from spreading elsewhere in `Sources/**`.
- Development-only `ProductionMediaTransportCandidate` plus target-Mac preflight/source-cycle/resource collector and acceptance ledger for exact Sandbox/Hardened Runtime, source switching, command behavior, permission, teardown, and 60-second/10-minute resource evidence.
- M6.2 production `NotchHubMediaCore` target with normalized system-media domain types, player-agnostic `MediaProvider`, deterministic `@MainActor MediaSessionController`, injected `SystemMediaTransport`, and isolated `SystemMediaBridge` boundary.
- Deterministic M6.2 tests for generation/revision ordering, stale/same-sequence rejection, deduplication, playback-state mapping, capability fail-closed behavior, invalid seek rejection, typed command forwarding, command-failure state preservation, one controlled restart, second-failure lockout, explicit stop, bridge callback ownership, teardown ordering, and stale transport-handler rejection.
- `docs/superpowers/plans/2026-08-09-production-media-boundary.md` defining the production media state/controller/bridge implementation sequence after M6.1 `ACCEPT_TRANSPORT`.
- Development-only M6.1 Universal Media Bridge compatibility/security probe with a fixed `/usr/bin/perl` process boundary, pinned MediaRemote adapter revision, repo-owned authoritative-capability patch, typed toggle/next/previous/bounded-seek allowlist, event-driven observation, privacy-safe evidence, and strict shipping isolation.
- `docs/testing/MEDIA_BRIDGE_PROBE.md` and `docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md` defining the target-Mac compatibility/security/resource procedure and the final `ACCEPT_TRANSPORT` evidence ledger.
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

- **M6.4 shipping composition is CI-qualified but not yet accepted**: the frozen physical candidate is source `c19ce13c5321fce72464ddf0a5d9b1467f770db0`, CI #675 / run `31408757149`, artifact ID `9070996306`, Actions digest `sha256:c3b279153b8abf75ab77fa2f478888ae1fe9bad6bfdbf64665567bf713b8035d`, and contained DMG SHA-256 `ccf8a503515d382c206c6211606ca6401ba33114863a30721e134c1a45af04b9`. Target lifecycle/resource/permission gates remain pending.
- The real shipping app now intentionally owns the accepted production media lifecycle and pinned resources while retaining App Sandbox-only entitlements, Hardened Runtime, system-only executable dylibs, the fixed `/usr/bin/perl` process boundary, typed commands, bounded teardown, and no sensitive permission/network/player-specific fallback expansion.
- M6.4 exact frozen artifact sizes are executable `312,816 B`, physical app payload `615,022 B`, and DMG `406,618 B`. The original P0 baseline is not rewritten; the feature cost is enforced through a separate reviewed additive allowance of `65,536 B / 360,448 B / 327,680 B` for executable/app/DMG.
- **M6.3 concrete production system transport is accepted** on frozen source `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b` after the complete target-Mac gate on `Mac16,8` / macOS 26.6. Yandex Music and Yandex Browser are verified through the same production transport; no-session capability state, authoritative source switching/disappearance, actual toggle/previous/next/seek behavior, no-sensitive-permission posture, clean teardown, and steady/stability resource behavior all pass.
- M6.3 acceptance does not silently compose media into the shipping app. `NotchHubApp` still does not link `NotchHubMediaCore`, and pinned adapter/framework resources are not yet shipped; composition is the next separate reviewed slice with fresh security/package/size/runtime evidence.
- M6.2 keeps the production media core in an independent Swift target that is fully built/tested but deliberately not linked into `NotchHubApp` until the concrete system transport/composition slice. This preserves honest feature-cost accounting and keeps dormant media code out of the current Personal Release.
- Linking the dormant M6.2 controller directly into `NotchHubCore` was rejected by the unchanged P0 size gate; a controlled sync-vs-async command-dispatch experiment changed zero bytes, while target isolation restored the shipping executable/app exactly to `250,320 B / 253,317 B` without widening budgets or weakening policy.
- M6.1 Universal Media transport feasibility is accepted with final outcome **`ACCEPT_TRANSPORT`** after target-Mac security, capability, real-command, source-switch/disappearance, lifecycle, 60-second resource, and corrected 10-minute stability evidence. Production Universal Media state/controller/bridge work is now unblocked under the approved isolated boundary.
- Apple Music, Spotify, and one additional independent player are explicitly `NOT TESTED / DEFERRED` for the Personal Release acceptance cycle because those sources are not available/used on the target Mac; they are not treated as failures and compatibility is not claimed until physically tested.
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

- M6.4 feature-size policy now accepts only the exact real artifact-size envelope (`schemaVersion`, `sourceCommit`, and the three size metrics) while remaining fail-closed for unknown fields; an earlier checker incorrectly rejected valid CI metadata keys.
- M6.4 production candidate helpers no longer inflate the shipping link graph; candidate-only reporting/invocation code is isolated into a development-only target.
- M6.3 production teardown no longer blocks indefinitely in `Process.waitUntilExit()`: graceful termination gets a bounded exit-event window, then the owned adapter is force-terminated if necessary and must confirm exit within a second bounded window.
- M6.3 target resource collection now uses the proven numeric CPU/RSS/thread sampling boundary instead of mixing command text into process metrics.
- M6.3 long-run acceptance now uses an absolute observer deadline plus bounded completion grace instead of the superseded fixed 20-second post-sampling watchdog.
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

- M6.4 frozen deterministic shipping candidate `c19ce13c5321fce72464ddf0a5d9b1467f770db0` passed complete CI #675 / run `31408757149`, including warnings-as-errors, full Swift suite/coverage, release/performance/media/security policy, nested/top-level signing, Sandbox/Hardened Runtime, shipping preflight, additive size gate, hosted performance smoke, and artifact publication.
- CI #675 published `NotchHub-shipping-media-candidate` artifact ID `9070996306`, Actions digest `sha256:c3b279153b8abf75ab77fa2f478888ae1fe9bad6bfdbf64665567bf713b8035d`; contained DMG SHA-256 `ccf8a503515d382c206c6211606ca6401ba33114863a30721e134c1a45af04b9`.
- M6.4 target-runner TDD RED CI #676 failed only because the exact target runner did not yet exist. Subsequent runner implementation uses the frozen DMG hash, read-only mount, existing privacy-safe collector, public AppKit normal termination, and rejects AppleScript/System Events/`kill -9`/`pkill` acceptance paths.
- M6.3 frozen candidate `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b` passed CI #576 / run `31339015100`; artifact ID `9045247126`, digest `sha256:a6323c504021f21e7638b40e47bedd0b2c1a9fcfcf861724c139151ee8faa804`.
- Target-Mac M6.3 acceptance on `Mac16,8` / macOS 26.6 passed all `NH-MEDIA-PROD-001...013` gates: sandbox-only + Hardened Runtime; no-session `unknown/unknown/unknown`; Yandex Music; Yandex Browser; source switch count `1` and disappearance; actual toggle pause/resume, next, previous, seek 42s; no Accessibility/Input Monitoring/Automation/Screen Recording prompts; clean teardown/no orphan.
- M6.3 60-second steady evidence passed with parent CPU median/max `0.0/0.0%`, adapter `0.0/0.1%`, combined RSS median/max upper bounds `26,416/32,192 KiB`, combined thread median/max upper bounds `4/9`, clean teardown and no orphan.
- M6.3 corrected 10-minute evidence passed with 120 samples: combined CPU median/max upper bounds `0.0/7.5%`, RSS `35,168 -> 26,160 KiB` (`-9,008 KiB`), threads `11 -> 4`, `cleanTeardown = true`, `orphanProcessDetected = false`.
- M6.3 lifecycle and acceptance-tool defects were developed under explicit RED -> GREEN evidence; collector-only fixes did not modify the frozen production candidate.
- M6.2 strict RED -> GREEN history covers missing domain types, provider contract, controller state machine, and `SystemMediaBridge` boundary before each implementation was added.
- M6.2 exact code head `52d6d76b564c603cb21f0ec49bff4fa958c3aac7` passed CI #500 with **117/117 Swift tests**, macOS 26 warnings-as-errors builds, probe verification, release/performance/media-policy tests, strict formatting/security audit, Sandbox/Hardened Runtime/package verification, performance harness smoke, and unchanged P0 size gates.
- CI #500 produced shipping executable/app payloads exactly `250,320 B / 253,317 B`, executable segment `65,536 B`, and DMG `84,661 B`; `NotchHubApp` depends only on `NotchHubCore`, while `NotchHubMediaCore` remains independently built/tested.
- M6.1 exact candidate `cda05bb4ff367d2c4a5d9d438c3f555f3788d186` passed CI #443 with **93/93 Swift tests**, sandbox/Hardened Runtime packaging, real no-session capabilities, schema-v2 observation, signature/provenance round-trip, shipping-isolation, release/security/performance gates, and unchanged P0 artifact-size budget.
- Target-Mac M6.1 acceptance on `Mac16,8` / macOS 26.6 passed sandbox-only + Hardened Runtime, no sensitive permission prompts, authoritative no-session/active capabilities, Yandex Music and Yandex Browser observation, actual toggle/previous/next/seek, source switching/disappearance, clean teardown, and deterministic no-restart-loop failure lifecycle.
- M6.1 resource acceptance passed: synchronized 60-second parent/adapter measurements sampled `0.0%` CPU with ~25.4 MiB combined steady RSS and 4 threads; corrected 10-minute stability recorded parent RSS drift `-128 KiB`, adapter drift `-32 KiB`, combined drift `-160 KiB`, ending threads unchanged at 4, adapter CPU max `0.1%`, and final `PROBE_TEARDOWN=PASS` / `PERL_TEARDOWN=PASS`.
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
