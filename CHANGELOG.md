# Changelog

All notable changes to NotchHub are documented here.

The project follows [Semantic Versioning](https://semver.org/). The active version is stored in repository-root [`VERSION`](VERSION).

## [Unreleased]

The current published release remains `v0.1.0`; everything below is source work that has not yet been published as a new version.

### Added

- **Native macOS regression/UI automation foundation** in draft PR #34: a checked-in XCTest/XCUIAutomation project launches the exact SwiftPM-built `NotchHub.app` by URL without making Xcode the production build system.
- Compile-time-only `NOTCHHUB_UI_TESTING` composition for deterministic media and haptic external-boundary fixtures. Shipping Personal/Release builds are explicitly checked for fixture-marker leakage.
- Stable accessibility identifiers for externally meaningful notch/media surfaces and controls.
- Predicate-driven XCUI assertion helpers plus failure screenshot, accessibility hierarchy, `.xcresult`, and exact `NHSourceCommit` diagnostics.
- First real deterministic XCUI media journeys: application launch, stable compact smoke, real hover expansion, and typed Next / Previous / Play-Pause clicks through the UI.
- Machine-readable acceptance coverage manifest in `Tests/Acceptance/coverage.yml` and `scripts/test_acceptance_coverage.py` with temporary `audit` and fail-closed `strict` modes.
- Canonical CI job **`macOS UI regression`** on `macos-26`, alongside the existing `macOS 26 compatibility` and `Build, test and package` jobs.
- Separate provenance-backed `performance/regression-ui-automation-foundation-size-budget.json`; immutable P0 and historical feature budgets remain unchanged.
- Approved Legacy Regression Baseline Backfill plan that must link the accepted M1 and M6.1-M6.5 contracts to executable evidence before M6.6 repair work resumes.
- **M6.6 one-shot lifecycle ownership**, deterministic gesture engine, local gesture seam, bounded compact commands and interactive transition/visual-tracking prerequisites.
- **M6.6 gesture/Peek/haptic/seek acceptance contracts** with stable target-Mac gates.
- **M6.5 Media-first UI** with authoritative system Now Playing presentation, retained compact media context, capability-driven controls and event-driven progress.
- M6.4 shipping media composition and lazy expanded-only persistent media lifecycle.
- M6.3 concrete production system-media transport, M6.2 normalized state/controller boundary and M6.1 transport feasibility probe.
- P0 performance policy/baseline, M1 interaction/transition hardening, public-repository policy and Personal Release infrastructure.

### Changed

- **Testing is now an explicit product gate.** Further feature work is frozen until Foundation Plan 1 is finalized and Plan 2 completes legacy acceptance backfill under `strict` validation.
- Canonical PR CI now has three first-class jobs: `macOS 26 compatibility`, `macOS UI regression`, and `Build, test and package`. The temporary branch-only UI workflow used during bootstrap has been removed.
- UI automation synchronization is wait/state driven; arbitrary sleeps and automatic retries are rejected by policy.
- Exact application source provenance is checked before XCUI execution; diagnostics retain the tested source SHA.
- Acceptance audit currently discovers **70 stable `NH-*` IDs**. The seed manifest has **1 verified mapping** and reports **69 legacy mapping gaps** rather than silently treating historical manual acceptance as automated coverage.
- Foundation shipping growth uses its own cumulative feature-size envelope. Historical M6.4/M6.5/M6.6 budgets and immutable `v0.1.0` evidence are not rewritten.
- Draft PR #33 remains the M6.6 physical-acceptance branch and is intentionally untouched by the testing-foundation work. Its current frozen candidate is `423bc5d72a3676d01793f898ed2e8e79845bc8cd`; automated CI is green but target-Mac physical retest remains blocking.
- **M6.6 Task 1 one-shot lifecycle prerequisite is accepted and merged.** PR #24 was squash-merged as `957e2f085ebf1fae1b3f741a7f79dd6a45b599b6` after exact-head CI PASS.
- **M6.6 Task 0 collapse-layout retarget hardening is physically accepted and merged** via PR #22 as `f017addd2efc9aed5b60b1556205bdb8eab23e0e`.
- **M6.5 is physically accepted and merged.** All `NH-MEDIA-UI-001...011` target gates passed; M6.4/M6.3 accepted behavior remains unchanged.
- Apple Music, Spotify and additional-player compatibility remain explicitly unverified rather than assumed.

### Fixed

- UI-test haptic injection is compile-time isolated so shipping builds retain the direct `AppKitNotchHapticPerformer` path instead of carrying the injectable test seam.
- Acceptance size policy no longer assumes a historical M6.6 feature envelope must remain the active CI budget forever; historical budgets are immutable/provenanced while canonical CI points to the current reviewed cumulative envelope.
- UI-test exact-SHA configuration now initializes fail-closed without using instance state before Swift stored-property initialization.
- M6.6 Task 1 prevents in-flight one-shot media operations from escaping normal teardown.
- M6.6 Task 0 retargets an in-flight collapse when compact extension changes so stale layout completion cannot leave an invalid compact frame.
- M6.5/M6.4 media presentation and lifecycle fixes preserve zero persistent adapter ownership in settled compact and clean normal Quit.
- M6.3 process teardown is bounded rather than relying on unbounded waiting.
- M1 hardware-notch rendering, transition ownership, stale-completion handling, animation reversal, Reduce Motion and pointer hot-path behavior were corrected under RED -> GREEN coverage.

### Testing

- Foundation Task 8 exact candidate `7654775b3ae0416d115f8f2ca7118e947cf97e13` passed canonical CI run `31811958254` with **all three jobs SUCCESS**, including real XCUI execution, shipping fixture-leak verification, policy/security checks, Swift tests, signing/Sandbox/Hardened Runtime checks, size enforcement and performance smoke.
- Deterministic XCUI fixture verifies real hover expansion and real Next → Track B, Previous → Track A, and Play/Pause UI control paths using predicate waits rather than sleeps.
- `macOS UI regression` preserves `.xcresult` diagnostics and checks exact source SHA before launching the external application under test.
- Acceptance `audit` validates ledger discovery, manifest uniqueness/source/status/layer/test references and reports legacy debt. `strict` remains intentionally blocked until Plan 2 backfill is complete.
- Foundation size evidence is sourced from exact CI artifact provenance; only the reviewed cumulative allowance is active, while historical budgets remain self-validated.
- M6.6 frozen physical candidate `423bc5d72a3676d01793f898ed2e8e79845bc8cd` passed CI #962 / run `31685581542`; physical repair retest remains pending.
- M6.5 frozen physical candidate `431d9fbaf1ff5ba98f2ceec09732acafe5f65794` passed all `NH-MEDIA-UI-001...011` gates on `Mac16,8` / macOS 26.6.
- M6.4 `NH-MEDIA-SHIP-001...010` and M6.3 `NH-MEDIA-PROD-001...013` target matrices remain accepted.

### Security

- The UI automation foundation does **not** add Accessibility, Input Monitoring, Automation/Apple Events, Screen Recording, networking, telemetry, global scroll capture, `CGEventTap`, synthetic media keys, polling, repeating watchdog timers or display links.
- Fixture substitution is compile-time test-only and shipping artifacts are scanned for fixture markers.
- App Sandbox remains the only application entitlement and Hardened Runtime remains mandatory.
- The sole production process exception remains the fixed `/usr/bin/perl` Universal Media boundary with pinned resources and a closed typed command surface.
- Public PR CI remains read-only and secret-free; release authority stays isolated from untrusted PR execution.

## [0.1.0] - 2026-08-07

### Added

- Initial native macOS NotchHub application foundation using Swift 6, SwiftUI and AppKit.
- Hardware-notch geometry from public `NSScreen` APIs with compact/expanded states and AppKit-owned sizing.
- Deterministic screen-space pointer/retention policy and exact physical-notch compact width.
- App Sandbox and Hardened Runtime with minimal reviewed entitlements.
- Strict CI/security/release policy, DMG integrity verification and real-hardware acceptance.

### Fixed

- Prevented compact/expanded hover resize oscillation through deterministic screen-space policy.
- Real hardware notch widths no longer inherit the fallback minimum.
- Disabled `NSHostingView` window-sizing ownership so SwiftUI content cannot leave the actual `NSPanel` frame expanded.
- Corrected Personal Release note validation while keeping Gatekeeper/quarantine bypass instructions prohibited.

### Testing

- Corrected-build hardware retest on macOS 26.6: `NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, and `NH-HOVER-003` PASS.
- Immutable Personal Release `v0.1.0` was published from accepted `main` and passed downloaded-release acceptance `NH-PERSONAL-RELEASE-001`.

### Security

- App Sandbox and Hardened Runtime are mandatory for the Personal Release.
- No telemetry, runtime networking, sensitive input monitoring or bundled credentials.
- Personal Release is ad-hoc signed and intentionally not notarized; standard macOS first-launch trust flows are documented without weakening Gatekeeper.
