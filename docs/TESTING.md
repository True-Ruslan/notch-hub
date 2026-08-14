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
9. **Fail-closed strict acceptance traceability** over every stable `NH-*` ledger entry in both the UI job and the normal build/package job.
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
- real hover-dwell expansion through the AppKit/SwiftUI pointer path;
- pointer-exit return to stable compact;
- repeated hover/exit cycles do not leave a stale surface;
- deterministic media fixture exposes authoritative title/artist/source state;
- real XCUI `Next` changes Track A -> Track B;
- real XCUI `Previous` returns Track B -> Track A;
- real XCUI Play/Pause toggles the visible accessibility state;
- unsupported fixture capabilities remain disabled and do not mutate track state;
- failures preserve exact source SHA, screenshot, accessibility hierarchy and `.xcresult`.

UI synchronization uses `NSPredicate`, `XCTNSPredicateExpectation` and `XCTWaiter`. Fixed sleeps and automatic retries are rejected by policy.

## Fixture / shipping separation

UI fixtures replace only nondeterministic external media/haptic boundaries and exist only under `#if NOTCHHUB_UI_TESTING`.

The deterministic media fixture is local and bounded: fixed tracks/state, no network, subprocess, file I/O, polling, repeating timer or display link. Shipping composition remains the default when the compiler condition is absent.

Normal Personal/Release artifacts are verified to contain no fixture marker or UI-test diagnostic marker. UI automation must not add Accessibility, Input Monitoring, Automation, Screen Recording, event taps, global scroll capture, synthetic media keys or any broader input authority.

## Accessibility contract

Stable identifiers used by XCUIAutomation include externally meaningful notch/media surfaces and controls such as:

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

Two validator modes remain available:

- `--mode audit` is a development diagnostic that permits unmapped contracts while still rejecting invalid entries;
- `--mode strict` is the canonical CI gate and requires every discovered stable acceptance contract to be mapped.

The Legacy Regression Baseline Backfill has completed the strict inventory on the PR #34 branch. Exact pre-documentation candidate `1e9ec7ac322ab4580f4f867e39457db915cfcb77` reports:

```text
Acceptance coverage strict passed: discovered=90 mapped=90 unmapped=0 missingAutomation=30
```

Interpretation:

- `mapped=90 / unmapped=0` means the entire discovered acceptance inventory has an explicit status/evidence record;
- accepted deterministic M1 and M6.1-M6.5 contracts cite executable unit/integration/UI/policy/shipping evidence;
- genuinely physical properties may include a `physical` layer only with a concrete `physicalOnlyReason`;
- pending/deferred contracts remain pending/deferred and are not converted into accepted behavior merely to satisfy automation;
- `missingAutomation=30` is not unmapped debt: it includes pending/deferred or genuinely physical cases that do not currently carry an automated evidence layer.

The status parser also distinguishes explicit acceptance tokens from ordinary behavioral prose: lowercase wording such as a `failed` capability no longer reclassifies a pending ledger entry as rejected. Explicit per-ID `PASS`/`FAIL`/`DEFERRED` and document-level `Status:` remain authoritative.

Canonical CI runs strict traceability in **both** `macOS UI regression` and `Build, test and package`, so losing or corrupting the mapping fails closed even if one testing layer is skipped by a future workflow mistake.

## Regression-foundation verification checkpoint

On exact source `1e9ec7ac322ab4580f4f867e39457db915cfcb77`, CI #1051 / run `31847082833` passed:

- all three required jobs;
- strict `90/90` acceptance mapping;
- 250 Swift tests;
- source/security policy and Sandbox/Hardened Runtime/signing checks;
- shipping fixture-leak exclusion and shipping media preflight;
- foundation feature-size gate and performance smoke;
- one canonical `macOS UI regression` execution plus two additional independent UI executions on the exact same source, for **3/3 successful XCUI runs**.

This evidence validates the pre-documentation candidate. A fresh exact-head CI after documentation synchronization is still required before PR #34 merge readiness.

## Physical-only boundary

Physical target acceptance remains authoritative where automation cannot establish equivalence, including:

- exact physical-notch visual geometry and compositor continuity;
- real trackpad gesture/haptic feel;
- target-Mac permission/trust prompts;
- real third-party player behavior;
- target-hardware CPU/RSS/thread/wakeup/energy measurements;
- display/Spaces behavior requiring actual multi-display/fullscreen hardware context.

Detailed physical evidence remains in the acceptance ledgers under `docs/testing/`. In particular:

- M1: `NOTCH_INTERACTION_ACCEPTANCE.md`;
- M6.1: `MEDIA_BRIDGE_PROBE_ACCEPTANCE.md`;
- M6.3: `PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`;
- M6.4: `SHIPPING_MEDIA_COMPOSITION_ACCEPTANCE.md`;
- M6.5: `MEDIA_UI_ACCEPTANCE.md`;
- M6.6 gesture contract: `MEDIA_GESTURE_ACCEPTANCE.md`;
- M6.6 interactive contract: `INTERACTIVE_NOTCH_ACCEPTANCE.md`;
- M6.6 Hover Peek contract: `MEDIA_PEEK_ACCEPTANCE.md`.

## Performance boundary

`PERFORMANCE.md` and `performance/baseline-v0.1.0.json` are authoritative. The immutable `v0.1.0` artifact baseline remains executable `220,560 B`, app `223,555 B`, DMG `73,955 B`.

Intentional shipping growth uses separate provenance-backed cumulative envelopes; historical budgets are not rewritten. The Regression/UI Automation Foundation has its own reviewed envelope. Shared GitHub runners validate deterministic performance policy/schema/package behavior; target runtime magnitudes remain real-hardware evidence.

## Current M6.6 boundary

PR #33 remains draft and physically unaccepted. Its frozen physical candidate is `423bc5d72a3676d01793f898ed2e8e79845bc8cd` with automated CI green, but target-Mac retest remains mandatory.

The testing foundation does not repair M6.6 behavior and does not convert automated UI evidence into physical acceptance. Product feature work remains frozen until PR #34 is merged and post-merge `main` CI passes; #33 must then be rebased/resumed and revalidated against the merged regression foundation before physical acceptance continues.
