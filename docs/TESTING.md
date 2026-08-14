# Testing

## Goal

Automate every deterministic behavior that can be validated reliably. Manual acceptance is reserved for physical notch geometry, real pointer/trackpad feel, compositor/window-animation continuity, physical haptic feel, exact macOS trust/permission surfaces, third-party player integration, and target-hardware resource measurements.

A green pipeline is necessary but is not proof of real-device UX or target-Mac efficiency. Manual success likewise never replaces deterministic automated coverage that can reasonably exist.

## Required CI gates

The canonical `.github/workflows/ci.yml` owns all untrusted pull-request execution. Required checks are:

- `macOS 26 compatibility`;
- `macOS UI regression`;
- `Build, test and package`.

The UI job is intentionally part of the same canonical workflow rather than a second PR-triggered workflow. Checkout is read-only and no secrets or privileged write authority are required.

Current CI validates:

1. Swift package structure, warnings-as-errors compilation and complete Swift tests on macOS 26.
2. Release, security, media-probe and performance policy.
3. Production media probe/candidate build, archive round-trip and provenance.
4. App/DMG packaging, signing, Hardened Runtime, exact App Sandbox entitlement and system-library-only application linkage.
5. Shipping media preflight and deterministic artifact-size enforcement against immutable P0 baseline plus the current reviewed feature envelope.
6. Native XCTest/XCUIAutomation project policy and compile-time fixture isolation.
7. Exact SwiftPM-built UI-test app creation with `NOTCHHUB_UI_TESTING` only for that build.
8. Shipping-artifact leak verification proving fixture/test-only markers are absent.
9. Acceptance coverage audit over stable `NH-*` ledgers.
10. Real external-app XCUI journeys on `macos-26`, preserving `.xcresult` and diagnostics.
11. Exact UI app source provenance: `NHSourceCommit` must match the PR-head/source SHA before the test app is launched.

Do not lower assertions, delete useful tests, weaken security/release/performance policy, widen accepted budgets, or weaken production behavior merely to make CI green.

## Testing pyramid

### Deterministic unit / policy

Use Swift Testing or Python policy tests for state machines, geometry, lifecycle, stale-callback handling, schemas, source-policy/security invariants, performance policies and artifact contracts.

### Integration / shipping

Use exact production transports and packaged artifacts where the OS/process boundary matters. Validate provenance, teardown, signing, entitlements and the fixed reviewed `/usr/bin/perl` media boundary.

### Native UI / E2E

The production build system remains SwiftPM. `NotchHubUITests.xcodeproj` contains only a minimal non-production test host and the UI-test bundle. Tests launch the exact SwiftPM-built `NotchHub.app` with `XCUIApplication(url:)`.

Current deterministic UI coverage proves on `macos-26`:

- exact external app launch/terminate;
- stable compact accessibility surface;
- deterministic media fixture expands through the real hover path;
- expanded fixture exposes media title/artist/source;
- real XCUI `Next` changes Track A -> Track B;
- real XCUI `Previous` returns Track B -> Track A;
- real XCUI Play/Pause toggles the visible accessibility state;
- failures preserve exact source SHA, screenshot, accessibility hierarchy and `.xcresult`.

UI synchronization uses `NSPredicate`, `XCTNSPredicateExpectation` and `XCTWaiter`. Fixed sleeps and automatic retries are rejected by policy.

## Fixture / shipping separation

UI fixtures replace only nondeterministic external media/haptic boundaries and exist only under `#if NOTCHHUB_UI_TESTING`.

The deterministic media fixture is local and bounded: fixed tracks/state, no network, subprocess, file I/O, polling, repeating timer or display link. Shipping composition remains the default when the compiler condition is absent.

Normal Personal/Release artifacts are verified to contain no fixture marker or UI-test diagnostic marker. UI automation must not add Accessibility, Input Monitoring, Automation, Screen Recording, event taps, global scroll capture, synthetic media keys or any broader input authority.

## Accessibility contract

Stable identifiers currently used by XCUIAutomation include:

- `notch.surface.compact`;
- `notch.surface.expanded`;
- `media.artwork`;
- `media.title`;
- `media.artist`;
- `media.playPause`;
- `media.previous`;
- `media.next`;
- `media.source`.

These are testability/accessibility seams, not an alternate state-control API.

## Acceptance traceability

`Tests/Acceptance/coverage.yml` is the machine-readable mapping layer. `scripts/test_acceptance_coverage.py` discovers stable `NH-*` IDs from `docs/testing/*.md` and validates ID uniqueness, canonical source, ledger-derived status, evidence layer and referenced test symbols.

Two modes exist:

- `--mode audit`: invalid mappings fail, but legacy unmapped contracts remain visible debt;
- `--mode strict`: every discovered stable acceptance contract must be mapped.

At the Regression/UI Automation Foundation checkpoint the validator discovers **70** stable acceptance IDs. **1** verified mapping is present and **69** remain legacy backfill debt. This is deliberate: audit is green without fabricating coverage, while strict remains blocked until `docs/superpowers/plans/2026-08-14-legacy-regression-baseline-backfill.md` is completed.

The seed mapping is `NH-MEDIA-BRIDGE-015` -> `MediaBridgeProbeCoreTests.ProbeProcessTests.nonzeroExitTransitionsToFailedWithoutAutomaticLoop`.

## Physical-only boundary

Physical target acceptance remains authoritative where automation cannot establish equivalence, including:

- exact physical-notch visual geometry and compositor continuity;
- real trackpad gesture/haptic feel;
- target-Mac permission/trust prompts;
- real third-party player behavior;
- target-hardware CPU/RSS/thread/wakeup/energy measurements;
- display/Spaces behavior requiring actual multi-display/fullscreen hardware context.

Detailed physical evidence remains in the acceptance ledgers under `docs/testing/`. In particular:

- M6.1: `MEDIA_BRIDGE_PROBE_ACCEPTANCE.md`;
- M6.3: `PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`;
- M6.4: `SHIPPING_MEDIA_COMPOSITION_ACCEPTANCE.md`;
- M6.5: `MEDIA_UI_ACCEPTANCE.md`;
- M6.6 gesture contract: `MEDIA_GESTURE_ACCEPTANCE.md`;
- M6.6 interactive contract: `INTERACTIVE_NOTCH_ACCEPTANCE.md`;
- M6.6 Hover Peek contract: `MEDIA_PEEK_ACCEPTANCE.md`.

## Performance boundary

`PERFORMANCE.md` and `performance/baseline-v0.1.0.json` are authoritative. The immutable `v0.1.0` artifact baseline remains executable `220,560 B`, app `223,555 B`, DMG `73,955 B`.

Intentional shipping growth uses separate provenance-backed cumulative envelopes; historical budgets are not rewritten. The Regression/UI Automation Foundation has its own reviewed envelope because the compressed DMG exceeded the prior M6.6 envelope while executable/app remained within it. Shared GitHub runners validate deterministic performance policy/schema/package behavior; target runtime magnitudes remain real-hardware evidence.

## Current M6.6 boundary

PR #33 remains draft and physically unaccepted. Its exact frozen physical candidate is `423bc5d72a3676d01793f898ed2e8e79845bc8cd` with CI run `31685581542` green, but target-Mac retest remains mandatory.

The testing foundation does not repair M6.6 behavior and does not convert automated UI evidence into physical acceptance. Product feature work remains frozen until the regression baseline backfill is completed and the appropriate M6.6 physical gates pass.
