# Testing

## Policy

Automate every deterministic behavior that can be validated reliably. Manual acceptance is reserved for physical notch geometry, real pointer/trackpad feel, compositor continuity, haptic feel, macOS permission/trust surfaces, third-party integration and target-hardware resources.

A green pipeline is necessary but never substitutes for target-Mac acceptance. Manual success never substitutes for reproducible automated coverage.

## Required CI

Canonical protected-branch jobs:

- `macOS 26 compatibility`;
- `macOS UI regression`;
- `Build, test and package`.

CI covers warnings-as-errors builds, Swift tests, exact external-app XCUI, acceptance-traceability policy, release/security/performance/media policy, strict formatting/plist/shell checks, Sandbox/Hardened Runtime/signing/system-library verification, shipping media preflight, deterministic artifact sizes, active provenance-backed feature budget, performance-harness schema smoke and artifacts.

Do not weaken tests, security rules, production behavior or historical baselines merely to obtain green CI.

## Regression/UI automation foundation

PR #34 merged the native regression foundation as `bd9566f690d314ed40fd6f3723a319291ceb4a58`; post-merge main CI #1053 passed all three jobs.

The foundation includes exact SwiftPM-built app launch through XCUI, source provenance validation, compile-time-only fixtures, stable accessibility IDs, state-driven synchronization, diagnostics, and fail-closed machine-readable acceptance coverage.

## TDD rule

For production behavior and new acceptance infrastructure:

1. add a focused regression test;
2. preserve a RED run proving the intended missing behavior;
3. implement the minimum GREEN change;
4. run full CI/security/performance verification;
5. only then advance to another independent defect.

Race, stale-callback, boundary and teardown behavior must be tested deterministically without arbitrary sleeps where practical.

## M6.6 automated acceptance baseline

The physically accepted runtime source is `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3`.

Canonical CI #1241 / run `32075976405` passed:

- all three canonical jobs;
- 366 Swift tests / 80 suites;
- 11/11 native external-app XCUI tests;
- strict acceptance traceability;
- production transport/archive verification;
- release DMG, security, App Sandbox-only entitlement, Hardened Runtime, signing and shipping preflight;
- active cumulative size budget without widening;
- shared-runner performance smoke.

The horizontal regression stack includes:

- `MediaGestureInputNormalizerTests` for physical-axis normalization;
- `MediaGestureCoordinatorTests` for direction, threshold, hysteresis, haptic, momentum, diagonal arbitration, capability validation and vertical intent;
- `MediaGesturePhysicalPipelineTests` for raw AppKit X -> normalization -> follow-finger visual offset -> typed command across both macOS scroll-direction preference states.

Hover/Peek and interaction regressions cover exact 120 ms dwell, 140 ms exit grace, generic no-media Peek, stale activation rejection, local pointer exit, exact-top-edge inclusive containment, interactive exact endpoint settlement and lost-terminal safety.

Seek/source/lifecycle regressions cover capability gating, local preview and commit/cancel behavior, session identity invalidation, balanced cursor ownership, bounded public `NSWorkspace` source lookup, transport stop-before-queued-work races and stale callback rejection.

## M6.6 physical acceptance and merge

On 2026-08-18 Mac16,8/macOS 26.6, the complete requested physical matrix passed on exact source `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3` after CI #1241 was green.

Physical evidence includes:

- RIGHT -> Previous/back, follow-finger RIGHT, one supported arm haptic;
- LEFT -> Next, follow-finger LEFT, one supported arm haptic;
- media-on Hover Peek + haptic and stationary-pointer relaunch;
- no-media generic Hover Peek + haptic;
- prompt single click expansion while hover/media enrichment may overlap;
- exact-top-edge and center DOWN without twitch/self-collapse;
- expanded pointer-exit and physical UP exact Compact settlement;
- seek preview/commit/cancel, cursor restore and track/source identity cancellation;
- source icon and fallback rendering;
- Accessibility / Input Monitoring / Automation / Screen Recording all NONE;
- post-Quit helper cleanup confirmed by empty `pgrep -lf 'mediaremote-adapter\.pl' || true`.

Acceptance-record head `c9fbd0605b33a318bb4371ae0f2c928120356adf` passed CI #1243 3/3 GREEN without changing production code. PR #33 was then squash-merged as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`.

Post-merge main CI #1244 ultimately passed all three jobs on that exact source. Its first packaging attempt hit `hdiutil ... Resource temporarily unavailable` after successful tests/signing; only the failed job was rerun on unchanged source and passed. This is CI-runner evidence, not an application regression.

M6.6 is merged but not released.

## Acceptance traceability

Authoritative M6.6 ledgers:

- `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`;
- `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`;
- `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`.

Machine-readable coverage lives in `Tests/Acceptance/coverage.yml` plus `coverage-current.json`; `scripts/test_acceptance_coverage.py --mode strict` must remain green. Accepted IDs must cite concrete automated coverage, physical evidence, or both.

Physical source acceptance stays pinned to `8744b9e...`; documentation descendants and the later squash merge do not rewrite that exact target-Mac claim.

## P1 target resource evidence foundation

P1 is active in Draft PR #36.

The first slice intentionally changes no shipping runtime behavior. It adds a fail-closed development/release evidence boundary around existing resource measurements.

Canonical deterministic coverage includes `P1TargetResourceEvidencePolicyTests`, which launches `scripts/test_p1_target_resource_evidence.py` inside normal `swift test`. This prevents the Python evidence contract from silently falling outside the protected Swift gate.

TDD RED evidence:

- head `6b7e90ff17803ef2678ff518b84fe82c8a39e06f`;
- CI #1245;
- 367 tests / 81 suites executed;
- exactly one new issue: `ModuleNotFoundError: p1_target_resource_evidence` from the P1 policy test;
- existing suites remained green.

The GREEN implementation is `scripts/p1_target_resource_evidence.py`. Its contract validates:

- exact measured runtime source commit;
- one shared measurement-tool commit;
- exact Mac16,8/macOS 26.6 platform;
- exact idle/hover/stability timing, sample intervals and sample counts;
- attached-process measurement mode;
- finite non-negative CPU/RSS/wakeup values and valid thread counts;
- required long-run stability summary;
- closed manual-evidence methods/findings with no arbitrary free-form surface.

The normalized bundle omits timestamps/raw traces and does not invent target thresholds for energy or compositor behavior. An explicit manual anomaly sets `reviewRequired: true` and requires investigation.

Canonical target procedure is `docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md`.

## Performance boundary

`performance/baseline-v0.1.0.json` and historical feature budgets remain immutable evidence. The active cumulative envelope is `performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json`; merged M6.6 passed it without widening.

Shared-runner CPU/RSS magnitudes are compatibility evidence, not target-Mac acceptance. P1 uses the real Mac16,8/macOS 26.6 for CPU/RSS/threads/wakeups/energy/compositor review.

The canonical P1 path does not automatically run privileged collectors such as `sudo powermetrics` or `timerfires`, does not add app permissions, and does not commit raw Instruments traces. Numeric budgets are introduced only after repeatable real-hardware evidence supports them.
